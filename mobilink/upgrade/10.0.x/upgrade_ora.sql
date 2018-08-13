
--
-- Upgrade the MobiLink Server system tables and stored procedures in
-- an Oracle consolidated database.
--


alter session set nls_length_semantics='BYTE'
/

create package MLSetup as
    id		int;
end MLSetup;
/
begin
    MLSetup.id := 1;
end;
/

--
-- Create temporary tables.
--
create table ml_user_temp (
    user_id		    integer	    not null,
    name		    varchar( 128 )  not null,
    hashed_password	    raw( 32 )	    null )
/

create table ml_database_temp (
    rid		    	    integer	    not null,
    remote_id		    varchar( 128 )  not null,
    description		    varchar( 128 )  null )
/

create table ml_subscription_temp (
    rid			    integer	    not null,
    subscription_id	    varchar( 128 )  default '<unknown>' not null,
    user_id		    integer	    not null,
    progress		    numeric( 20 )   default 0 not null,
    publication_name	    varchar( 128 )  default '<unknown>' not null,
    last_upload_time	    date	    default TO_DATE('1900-01-01 00:00:00','YYYY-MM-DD HH24:MI:SS') not null,
    last_download_time	    date	    default TO_DATE('1900-01-01 00:00:00','YYYY-MM-DD HH24:MI:SS') not null )
/

--
-- Store the old information into the temporary tables.
--
insert into ml_user_temp ( user_id, name, hashed_password )
    select user_id, name, hashed_password from ml_user
/

insert into ml_database_temp ( rid, remote_id, description )
    select rid, remote_id, description from ml_database
/

insert into ml_subscription_temp ( rid, subscription_id, user_id,
				    progress, publication_name,
				    last_upload_time, last_download_time )
    select rid, subscription_id, user_id, progress,
	   publication_name, last_upload_time, last_download_time
	from ml_subscription
/

--
-- Drop the old ml_user, ml_database and ml_subscription tables.
--
drop table ml_subscription
/

drop table ml_database
/

drop table ml_user
/

--
-- Add new tables for user authentication using LDAP servers
--
create table ml_ldap_server (
    ldsrv_id		integer			not null,
    ldsrv_name		varchar2( 128 )		not null unique,
    search_url		varchar2( 1024 )	not null,
    access_dn		varchar2( 1024 )	not null,
    access_dn_pwd	varchar2( 256 )		not null,
    auth_url		varchar2( 1024 )	not null,
    num_retries		smallint		default 3,
    timeout		integer			default 10,
    start_tls		smallint		default 0,
    primary key ( ldsrv_id ) ) 
/

create sequence ml_ldap_server_sequence start with 1 increment by 1 nomaxvalue
/

create trigger ml_ldap_server_trigger before insert on ml_ldap_server for each row
begin
    select ml_ldap_server_sequence.nextval into :new.ldsrv_id from dual;
end;
/

create table ml_trusted_certificates_file (
    file_name		varchar2( 1024 ) not null ) 
/

create table ml_user_auth_policy (
    policy_id			integer		not null,
    policy_name			varchar2( 128 )	not null unique,
    primary_ldsrv_id		integer		not null,
    secondary_ldsrv_id		integer		null,
    ldap_auto_failback_period	integer		default 900,
    ldap_failover_to_std	smallint	default 1,
    foreign key( primary_ldsrv_id ) references ml_ldap_server( ldsrv_id ),
    foreign key( secondary_ldsrv_id ) references ml_ldap_server( ldsrv_id ),
    primary key( policy_id ) ) 
/

create sequence ml_auth_policy_sequence start with 1 increment by 1 nomaxvalue
/

create trigger ml_auth_policy_trigger before insert on ml_user_auth_policy for each row
begin
    select ml_auth_policy_sequence.nextval into :new.policy_id from dual;
end;
/

--
-- Restructure the ml_user table.
--
create table ml_user (
    user_id		integer			not null,
    name		varchar2( 128 )		not null unique,
    hashed_password	raw(32)			null,
    policy_id		integer			null,
    user_dn		varchar2( 1024 )	null,
    foreign key( policy_id ) references ml_user_auth_policy( policy_id ),
    primary key( user_id ) ) 
/

insert into ml_user ( user_id, name, hashed_password )
    select user_id, name, hashed_password
	from ml_user_temp
/
    
declare id int;
begin
    begin
	select max( user_id ) into id from ml_user;
	exception
	    when NO_DATA_FOUND then
		id := NULL;
    end;
    if id is null then
	MLSetup.id := 1;
    else
	MLSetup.id := id + 1;
    end if;
end;
/

begin
    execute immediate '
	create sequence ml_user_sequence start with '
	|| MLSetup.id ||
	' increment by 1 nomaxvalue ';
end;
/

create trigger ml_user_trigger before insert on ml_user for each row
begin
    select ml_user_sequence.nextval into :new.user_id from dual;
end;
/

--
-- Create and populate the ml_database table.
--
create table ml_database (
    rid			integer		not null,
    remote_id		varchar2( 128 )	not null unique,
    script_ldt		timestamp	default TO_TIMESTAMP('1900-01-01 00:00:00','YYYY-MM-DD HH24:MI:SSXFF') not null,
    seq_id		raw(16)		null,
    seq_uploaded	integer		default 0 not null,
    sync_key		varchar2( 40 )	null,
    description		varchar2( 128 )	null,
    primary key( rid )
)
/

insert into ml_database ( rid, remote_id, description )
    select rid, remote_id, description
	from ml_database_temp
/

declare id int;
begin
    begin
	select max( rid ) into id from ml_database;
	exception
	    when NO_DATA_FOUND then
		id := NULL;
    end;
    if id is null then
	MLSetup.id := 1;
    else
	MLSetup.id := id + 1;
    end if;
end;
/

begin
    execute immediate '
	create sequence ml_database_sequence start with '
	|| MLSetup.id ||
	' increment by 1 nomaxvalue ';
end;
/

create trigger ml_database_trigger before insert on ml_database for each row
begin
    select ml_database_sequence.nextval into :new.rid from dual;
end;
/

--
-- Restructure the ml_subscription table.
--
create table ml_subscription (
    rid		    	integer		not null,
    subscription_id	varchar2( 128 ) default '<unknown>' not null,
    user_id		integer		not null,
    progress	    	numeric( 20 )	default 0 not null,
    publication_name    varchar2( 128 )	default '<unknown>' not null,
    last_upload_time    timestamp default TO_TIMESTAMP('1900-01-01 00:00:00','YYYY-MM-DD HH24:MI:SSXFF') not null,
    last_download_time  timestamp default TO_TIMESTAMP('1900-01-01 00:00:00','YYYY-MM-DD HH24:MI:SSXFF') not null,
    primary key( rid, subscription_id ),
    constraint ml_db_database foreign key( rid ) references ml_database,
    constraint ml_us_user foreign key( user_id ) references ml_user
)
/

insert into ml_subscription ( rid, subscription_id, user_id,
			      progress, publication_name,
			      last_upload_time, last_download_time )
    select rid, subscription_id, user_id, progress,
	   publication_name, last_upload_time, last_download_time
    from ml_subscription_temp
/

--
-- Add new SIS properties
--
exec ml_add_property( 'SIS', 'BESHTTP(BES_HTTP)', 'enable', 'yes' );
exec ml_add_property( 'SIS', 'BESHTTP(BES_HTTP)', 'bes', 'localhost' );
exec ml_add_property( 'SIS', 'BESHTTP(BES_HTTP)', 'port', '8080' );
exec ml_add_property( 'SIS', 'BESHTTP(BES_HTTP)', 'client_port', '4400' );
/

--
-- Replace the ml_add_user stored procedure
--
drop procedure ml_add_user
/

create procedure ml_add_user (
    p_user		in varchar2,
    p_password		in raw,
    p_policy_name	in varchar2 ) 
as
    v_user_id	integer;
    v_policy_id	integer;
    v_error	integer;
    v_msg	varchar2( 1024 );
begin
    if p_user is not null then
	v_error := 0;
	if p_policy_name is not null then
	    begin
		select policy_id into v_policy_id from ml_user_auth_policy
		    where policy_name = p_policy_name;
		exception
		    when NO_DATA_FOUND then
			v_policy_id := NULL;
	    end;
	    if v_policy_id is null then
		raise_application_error( -20000,
		    'Unable to find the user authentication policy: "' || p_policy_name || '".' );
		v_error := 1;
	    end if;
	else 
	    v_policy_id := null;
	end if;
	if v_error = 0 then
	    begin
		select user_id into v_user_id from ml_user where name = p_user;
		exception
		    when NO_DATA_FOUND then
			v_user_id := NULL;
	    end;
	    if v_user_id is null then
		insert into ml_user ( name, hashed_password, policy_id )
		    values ( p_user, p_password, v_policy_id );
	    else
		update ml_user set hashed_password = p_password,
				    policy_id = v_policy_id
		    where user_id = v_user_id;
	    end if;
	end if;
    end if;
end;
/

--
-- Replace the ml_set_sis_sync stored procedure
--
drop procedure ml_set_sis_sync_state
/

create procedure ml_set_sis_sync_state(
    p_remote_id		in	varchar2,
    p_subscription_id	in	varchar2,
    p_publication_name	in	varchar2,
    p_user_name		in	varchar2,
    p_last_upload	in	timestamp,
    p_last_download	in	timestamp  )
as
    r			varchar2( 128 );
    sid			varchar2( 128 );
    lut			timestamp;
begin
    if p_subscription_id is null then
	sid := 's:' || p_subscription_id;
    else
	sid := p_subscription_id;
    end if;
    
    if p_last_upload is null then
	begin
	    select last_upload into lut from ml_sis_sync_state
		where remote_id = p_remote_id
		and subscription_id = sid;
	exception
	    when NO_DATA_FOUND then
		lut := NULL;
	end;
	if lut is null then
	    lut := TO_TIMESTAMP('1900-01-01 00:00:00','YYYY-MM-DD HH24:MI:SSXFF');
	end if;
    else
	lut := p_last_upload;
    end if;

    begin
	select remote_id into r from ml_sis_sync_state 
	    where remote_id = p_remote_id
	    and subscription_id = sid;
    exception
	when NO_DATA_FOUND then
	    r := NULL;
    end;
    if r is null then
	insert into ml_sis_sync_state( remote_id, subscription_id, publication_name, user_name, last_upload, last_download )
	    values( p_remote_id, sid, p_publication_name, p_user_name, lut, p_last_download );
    else
	update ml_sis_sync_state
	    set publication_name = p_publication_name,
		user_name = p_user_name,
		last_upload = lut,
		last_download = p_last_download
	    where remote_id = p_remote_id
		and subscription_id = sid;
    end if;
end;
/

--
-- Add new objects to support deploying synchronization models from Sybase Central
--

create table ml_model_schema (
    schema_type		varchar2( 32 )	 not null,
    schema_owner	varchar2( 128 )  not null,
    table_name		varchar2( 128 )  not null,
    object_name		varchar2( 128 )  not null,
    drop_stmt		varchar2( 2000 ) not null,
    checksum		varchar2( 64 )   not null,
    db_checksum		varchar2( 64 )   null,
    locked		integer		 not null,
    primary key( schema_type, schema_owner, table_name, object_name ) ) 
/

create table ml_model_schema_use (
    version_id		integer		not null,
    schema_type		varchar2( 32 )   not null,
    schema_owner	varchar2( 128 )  not null,
    table_name		varchar2( 128 )  not null,
    object_name		varchar2( 128 )  not null,
    checksum		varchar2( 64 )   not null,
    primary key( version_id, schema_type, schema_owner, table_name, object_name ) ) 
/

create procedure ml_model_begin_check(
    p_version		in varchar2 )
as
    v_version_id		integer;
begin
    begin
	select version_id into v_version_id from ml_script_version 
	    where name = p_version;
    exception
	when NO_DATA_FOUND then v_version_id := null;
    end;

    -- If this same script version was previously installed, 
    -- clean-up any meta-data associated with it.
    delete from ml_model_schema_use where version_id = v_version_id;
end;
/

create procedure ml_model_begin_install(
    p_version		in varchar2 )
as
    v_version_id		integer;
begin
    begin
	select version_id into v_version_id from ml_script_version 
	    where name = p_version;
    exception
	when NO_DATA_FOUND then v_version_id := null;
    end;

    -- If this same script version was previously installed, 
    -- clean-up any meta-data associated with it.
    delete from ml_column where version_id = v_version_id;
    delete from ml_connection_script where version_id = v_version_id;
    delete from ml_table_script where version_id = v_version_id;
    delete from ml_model_schema_use where version_id = v_version_id;
    delete from ml_script_version where version_id = v_version_id;
end;
/

create function ml_model_get_catalog_checksum(
    p_schema_type	in varchar2,
    p_schema_owner	in varchar2,
    p_table_name	in varchar2,
    p_object_name	in varchar2 )
    return varchar2
as
begin
    return null;
end;
/

create procedure ml_model_register_schema (
    p_schema_type	in varchar2,
    p_schema_owner	in varchar2,
    p_table_name	in varchar2,
    p_object_name	in varchar2,
    p_drop_stmt		in varchar2,
    p_checksum		in varchar2,
    p_locked		in integer )
as
    v_drop_stmt		varchar2(2000);
    v_checksum		varchar2(64);
    v_db_checksum	varchar2(64);
    v_locked		integer;
begin
    if p_drop_stmt is null then
	select drop_stmt into v_drop_stmt from ml_model_schema 
	    where schema_type = p_schema_type and schema_owner = p_schema_owner
		and table_name = p_table_name and object_name = p_object_name;
    else
	v_drop_stmt := p_drop_stmt;
    end if;

    if p_checksum is null then
	select checksum into v_checksum from ml_model_schema 
	    where schema_type = p_schema_type and schema_owner = p_schema_owner
		and table_name = p_table_name and object_name = p_object_name;
    else
	v_checksum := p_checksum;
    end if;

    if p_locked is null then
	select locked into v_locked from ml_model_schema 
	    where schema_type = p_schema_type and schema_owner = p_schema_owner
		and table_name = p_table_name and object_name = p_object_name;
    else
	v_locked := p_locked;
    end if;

    v_db_checksum := ml_model_get_catalog_checksum( p_schema_type, p_schema_owner, p_table_name, p_object_name );

    begin
	insert into ml_model_schema
	    ( schema_type, schema_owner, table_name, object_name, drop_stmt, checksum, locked )
	    values( p_schema_type, p_schema_owner, p_table_name, p_object_name, v_drop_stmt, v_checksum, v_locked );
    exception 
	when DUP_VAL_ON_INDEX	then
	    update ml_model_schema set drop_stmt = v_drop_stmt, checksum = v_checksum, locked = v_locked
	    where schema_type = p_schema_type and schema_owner = p_schema_owner
		and table_name = p_table_name and object_name = p_object_name;
    end;	
end;
/

create procedure ml_model_deregister_schema (
    p_schema_type	in varchar2,
    p_schema_owner	in varchar2,
    p_table_name	in varchar2,
    p_object_name	in varchar2 )
as    
begin
    if p_schema_type = 'TABLE' then
	delete from ml_model_schema 
	    where schema_type = p_schema_type 
		and schema_owner = p_schema_owner 
		and table_name = p_table_name;
    else
	delete from ml_model_schema 
	    where schema_type = p_schema_type 
		and schema_owner = p_schema_owner 
		and table_name = p_table_name
		and object_name = p_object_name;
    end if;	    
end;
/

create procedure ml_model_register_schema_use (
    p_version		in varchar2,
    p_schema_type	in varchar2,
    p_schema_owner	in varchar2,
    p_table_name	in varchar2,
    p_object_name	in varchar2,
    p_checksum		in varchar2 )
as
    v_version_id	integer;
begin
    begin
	select version_id into v_version_id from ml_script_version 
	    where name = p_version;
    exception
	when NO_DATA_FOUND then
	    select max( version_id )+1 into v_version_id from ml_script_version;
	    if v_version_id is null then
		v_version_id := 1;
	    end if;
	    insert into ml_script_version ( version_id, name )
		    values ( v_version_id, p_version );
    end;

    begin
	insert into ml_model_schema_use
	    ( version_id, schema_type, schema_owner, table_name, object_name, checksum )
	    values( v_version_id, p_schema_type, p_schema_owner, p_table_name, p_object_name, p_checksum );
    exception 
	when DUP_VAL_ON_INDEX	then
	update ml_model_schema_use set checksum = p_checksum
	    where version_id = v_version_id and schema_type = p_schema_type
		and schema_owner = p_schema_owner and table_name = p_table_name
		and object_name = p_object_name;
    end;
end;
/

create procedure ml_model_mark_schema_verified (
    p_version		in varchar2,
    p_schema_type	in varchar2,
    p_schema_owner	in varchar2,
    p_table_name	in varchar2,
    p_object_name	in varchar2 )
as
    v_checksum		varchar2( 64 );
    v_version_id	integer;
    v_locked		integer;
begin
    select version_id into v_version_id from ml_script_version 
	where name = p_version;

    begin
	select checksum into v_checksum from ml_model_schema
	    where schema_type = p_schema_type and schema_owner = p_schema_owner 
		and table_name = p_table_name and object_name = p_object_name;
    exception
	when NO_DATA_FOUND then
	    select checksum into v_checksum from ml_model_schema_use 
		where version_id = v_version_id and schema_type = p_schema_type
		    and schema_owner = p_schema_owner and table_name = p_table_name
		    and object_name = p_object_name;
	    if p_schema_type = 'COLUMN' then
		v_locked := 1;
	    else
		v_locked := 0;
	    end if;
		    
	    ml_model_register_schema( p_schema_type, p_schema_owner, p_table_name, p_object_name, 
		'-- Not dropped during uninstall', v_checksum, v_locked );
	    return;
    end;

    update ml_model_schema_use set checksum = 'IGNORE'
	where version_id = v_version_id and schema_type = p_schema_type and schema_owner = p_schema_owner
	    and table_name = p_table_name and object_name = p_object_name;
end;
/

create function ml_model_check_catalog(
    p_schema_type	in varchar2,
    p_schema_owner	in varchar2,
    p_table_name	in varchar2,
    p_object_name	in varchar2 ) 
    return varchar2
as
    v_checksum		varchar2(64);
    v_orig_db_checksum	varchar2(64);
    v_db_checksum	varchar2(64);
    v_count		integer;
begin    
    -- Return values
    -- 'UNUSED' - The requested schema isn't referenced by any ML meta-data
    -- 'MISSING' - The requested schema is not installed.
    -- 'MISMATCH' - The current schema doesn't match the ML meta-data
    -- 'UNVERIFIED' - A full schema comparison wasn't done, 
    --                generally we assume the schema is correct in this case
    -- 'INSTALLED' - The required schema is correctly installed.
    v_count := 0;
    if p_schema_type = 'TABLE' then
	select count(*) into v_count from ALL_TABLES where OWNER = p_schema_owner and TABLE_NAME = p_table_name;
    elsif p_schema_type = 'TRIGGER' then
	select count(*) into v_count from ALL_TRIGGERS where OWNER = p_schema_owner 
	    and TABLE_NAME = p_table_name and TRIGGER_NAME = p_object_name;
    elsif p_schema_type = 'INDEX' then
	select count(*) into v_count from ALL_INDEXES where OWNER = p_schema_owner 
	    and TABLE_NAME = p_table_name and INDEX_NAME = p_object_name;
    elsif p_schema_type = 'COLUMN' then
	select count(*) into v_count from ALL_TAB_COLUMNS where OWNER = p_schema_owner 
	    and TABLE_NAME = p_table_name and COLUMN_NAME = p_object_name;
    elsif p_schema_type = 'PROCEDURE' then
	select count(*) into v_count from ALL_PROCEDURES where OWNER = p_schema_owner 
	    and PROCEDURE_NAME = p_object_name;
    end if;

    if v_count != 0 then 
	-- The schema exists
	v_db_checksum := ml_model_get_catalog_checksum( p_schema_type, p_schema_owner, p_table_name, p_object_name );

	begin
	    select s.checksum, s.db_checksum into v_checksum, v_orig_db_checksum from ml_model_schema s
	    where s.schema_type = p_schema_type and s.schema_owner = p_schema_owner 
		and s.table_name = p_table_name and s.object_name = p_object_name;
	exception
	    when NO_DATA_FOUND then
		v_checksum := null;
		v_orig_db_checksum := null;
	end;

	if v_checksum is null then return 'UNUSED'; end if;
	if v_orig_db_checksum is null or v_db_checksum is null then return 'UNVERIFIED'; end if;
	if v_orig_db_checksum = v_db_checksum then return 'INSTALLED'; end if;
	return 'MISMATCH';
    end if;
	   
    -- The schema does not exist
    return 'MISSING';
end;
/

create function ml_model_check_schema (
    p_version		in varchar2,
    p_schema_type	in varchar2,
    p_schema_owner	in varchar2,
    p_table_name	in varchar2,
    p_object_name	in varchar2 )
    return varchar2
as
    v_db_status		varchar2(32);
    v_status		varchar2(32);
    v_count		integer;
begin
    -- Return values
    -- 'UNUSED' - The requested schema isn't needed for this version.
    -- 'MISSING' - The required schema is not installed.
    -- 'MISMATCH' - The current schema doesn't match what is needed and must be replaced.
    -- 'UNVERIFIED' - The existing schema must be manually checked to see if it matches what is needed.
    -- 'INSTALLED' - The required schema is correctly installed.

    begin
	select case when s.checksum is null then 'MISSING' else
		case when u.checksum = 'IGNORE' or u.checksum = s.checksum then 'INSTALLED' else 'MISMATCH' end
	    end into v_status
	from ml_model_schema_use u
	    join ml_script_version v on v.version_id = u.version_id 
	    left outer join ml_model_schema s 
		on s.schema_type = u.schema_type and s.schema_owner = u.schema_owner 
		    and s.table_name = u.table_name and s.object_name = u.object_name
	where v.name = p_version and u.schema_type = p_schema_type and u.schema_owner = p_schema_owner	
	    and u.table_name = p_table_name and u.object_name = p_object_name;
    exception
	when NO_DATA_FOUND then
	    v_status := 'UNUSED';
    end;

    v_db_status := ml_model_check_catalog( p_schema_type, p_schema_owner, p_table_name, p_object_name );
    if v_db_status = 'MISSING' then return 'MISSING'; end if;
    if v_status = 'UNUSED' or v_status = 'MISMATCH' then return v_status; end if;
    if v_status = 'MISSING' then return 'UNVERIFIED'; end if;

    -- v_status = 'INSTALLED'
    if v_db_status = 'MISMATCH' then return 'MISMATCH'; end if;

    -- If v_db_status = 'UNVERIFIED' we are optimistic and assume it is correct
    return 'INSTALLED';
end;
/

create function ml_model_get_schema_action (
    p_version		in varchar2,
    p_schema_type	in varchar2,
    p_schema_owner	in varchar2,
    p_table_name	in varchar2,
    p_object_name	in varchar2,
    p_upd_mode		in varchar2 )
    return varchar2
as
    v_status		varchar2(32);
    v_locked		integer;
begin
    select ml_model_check_schema( p_version, p_schema_type, p_schema_owner, p_table_name, p_object_name ) into v_status from dual;
    if v_status = 'MISSING' then 
	return 'CREATE';
    elsif v_status = 'UNUSED' or v_status = 'INSTALLED' or p_upd_mode != 'OVERWRITE' or p_schema_type = 'COLUMN' then
	    -- Preserve the existing schema
	    -- Note, 'REPLACE' won't work for columns because the column is likely 
	    --     in an index and the drop will fail.  If the status is 'MISMATCH' 
	    --     then the column will need to be manually altered in the database.
	    return 'SKIP';
    end if;
    
    v_status := ml_model_check_catalog( p_schema_type, p_schema_owner, p_table_name, p_object_name );
    if v_status = 'MISMATCH' then
	-- The schema was modified since ML was deployed, we are careful not to destroy any schema
	-- that was not created by ML
	return 'SKIP';
    end if;

    begin
	select locked into v_locked
	    from ml_model_schema
	    where schema_type = p_schema_type and schema_owner = p_schema_owner and table_name = p_table_name 
		and object_name = p_object_name and locked != 0;
    exception
	when NO_DATA_FOUND then
	-- The schema is not locked
	-- The existing schema doesn't match what is needed so replace it.
	return 'REPLACE';
    end;

    -- The schema is marked as locked, preserve it.
    return 'SKIP';
end;
/

create procedure ml_model_check_all_schema(
    p_crsr	in out sys_refcursor )
as    
begin
    open p_crsr for select 
	case when s.schema_owner is null then u.schema_owner else s.schema_owner end schema_owner, 
	case when s.table_name is null then u.table_name else s.table_name end table_name, 
	case when s.schema_type is null then u.schema_type else s.schema_type end schema_type, 
	case when s.object_name is null then u.object_name else s.object_name end object_name, 
	s.locked, 
	ver.name used_by,
	ml_model_check_schema( ver.name, 
	    case when s.schema_type is null then u.schema_type else s.schema_type end, 
	    case when s.schema_owner is null then u.schema_owner else s.schema_owner end, 
	    case when s.table_name is null then u.table_name else s.table_name end, 
	    case when s.object_name is null then u.object_name else s.object_name end ) status,
	case when ver.name is null then null else ml_model_get_schema_action( ver.name, u.schema_type, u.schema_owner, u.table_name, u.object_name, 'OVERWRITE' ) end overwrite_action,
	case when ver.name is null then null else ml_model_get_schema_action( ver.name, u.schema_type, u.schema_owner, u.table_name, u.object_name, 'PRESERVE_EXISTING_SCHEMA' ) end preserve_action
    from ml_model_schema s 
	full outer join ml_model_schema_use u on
	    u.schema_type = s.schema_type and u.schema_owner = s.schema_owner
	    and u.table_name = s.table_name and u.object_name = s.object_name
	left outer join ml_script_version ver on
	    u.version_id = ver.version_id
    order by schema_owner, table_name, schema_type, object_name, used_by;
end;
/

create procedure ml_model_check_version_schema(
    p_version		in varchar2,
    p_crsr	in out sys_refcursor )
as
begin
    open p_crsr for select u.schema_owner, u.table_name, u.schema_type, u.object_name, s.locked,
	ml_model_check_schema( ver.name, u.schema_type, u.schema_owner, u.table_name, u.object_name ) status,
	ml_model_get_schema_action( ver.name, u.schema_type, u.schema_owner, u.table_name, u.object_name, 'OVERWRITE' ) overwrite_action,
	ml_model_get_schema_action( ver.name, u.schema_type, u.schema_owner, u.table_name, u.object_name, 'PRESERVE_EXISTING_SCHEMA' ) preserve_action
    from ml_model_schema_use u join ml_script_version ver on u.version_id = ver.version_id
	left outer join ml_model_schema s on
	    u.schema_type = s.schema_type and u.schema_owner = s.schema_owner
	    and u.table_name = s.table_name and u.object_name = s.object_name
    where ver.name = p_version
    order by u.schema_owner, u.table_name, u.schema_type, u.object_name;
end;
/

create procedure ml_model_drop_unused_schema
as
    v_status	     varchar2(32);
    v_schema_type    varchar2(32);
    v_schema_owner   varchar2(128);
    v_object_name    varchar2(128);
    v_table_name     varchar2(128);
    v_drop_stmt	     varchar2(2000);
    cursor drop_crsr is
	select s.schema_type, s.schema_owner, s.table_name, s.object_name, s.drop_stmt 
	from ml_model_schema s 
	    left outer join ml_model_schema_use u 
	    on u.schema_type = s.schema_type and u.schema_owner = s.schema_owner 
		and u.table_name = s.table_name and u.object_name = s.object_name
	where u.object_name is null and s.locked = 0 and s.drop_stmt not like '--%'
	    order by ( case s.schema_type
		when 'INDEX' then 1
		when 'TRIGGER' then 2
		when 'PROCEDURE' then 3
		when 'COLUMN' then 4
		when 'TABLE' then 5
		else 6
		end );
begin
    open drop_crsr;
    loop
	fetch drop_crsr into v_schema_type, v_schema_owner, v_table_name, v_object_name, v_drop_stmt;
	exit when drop_crsr%NOTFOUND;

	v_status := ml_model_check_catalog( v_schema_type, v_schema_owner, v_table_name, v_object_name );
	-- We don't drop any schema modified since ML was deployed.
	if v_status != 'MISMATCH' and v_status != 'MISSING' then
	    execute immediate v_drop_stmt;
	end if;
	ml_model_deregister_schema( v_schema_type, v_schema_owner, v_table_name, v_object_name );
    end loop;
    close drop_crsr;
end;
/

create procedure ml_model_drop(
    p_version	    in varchar2 )
as
    v_version_id    integer;
begin
    select version_id into v_version_id from ml_script_version 
	where name = p_version;

    delete from ml_model_schema_use where version_id = v_version_id;
    delete from ml_column where version_id = v_version_id;
    delete from ml_connection_script where version_id = v_version_id;
    delete from ml_table_script where version_id = v_version_id;
    delete from ml_script_version where version_id = v_version_id;
    ml_model_drop_unused_schema();
end;
/

commit
/

--
-- QAnywhere Upgrades
--
exec ml_add_property( 'SIS', 'Notifier(QAnyNotifier_client)', 'gui', null );
exec ml_add_property( 'SIS', 'Notifier(QAnyNotifier_client)', 'enable', null );
exec ml_add_property( 'SIS', 'Notifier(QAnyNotifier_client)', 'poll_every', null );
exec ml_add_property( 'SIS', 'Notifier(QAnyNotifier_client)', 'request_cursor', null );
exec ml_add_property( 'SIS', 'Notifier(QAnyNotifier_client)', 'request_delete', null );
/

drop procedure ml_qa_add_message
/
drop procedure ml_qa_add_delivery
/
drop trigger ml_qa_delivery_trigger
/
drop procedure ml_qa_upsert_global_prop
/
drop procedure ml_qa_stage_status_from_client
/
drop procedure ml_qa_staged_status_for_client
/
drop procedure ml_qa_handle_error
/
drop function ml_qa_get_agent_prop
/
drop function ml_qa_get_agent_network_prop
/
drop function ml_qa_get_agent_object_prop
/
drop function ml_qa_get_message_prop
/

drop view ml_qa_messages
/

drop table ml_qa_global_props
/
drop table ml_qa_status_history
/
drop table ml_qa_repository_props
/
drop table ml_qa_delivery
/
drop table ml_qa_repository
/
drop table ml_qa_notifications
/
drop table ml_qa_repository_staging
/
drop table ml_qa_status_staging
/
drop table ml_qa_clients
/

--
-- Drop the temporary tables.
--
drop table ml_subscription_temp
/

drop table ml_database_temp
/

drop table ml_user_temp
/

--
-- Add the ml_primary_server table
--
create table ml_primary_server (
    server_id		integer		not null,
    name		varchar2( 128 )	not null unique,
    connection_info	varchar2( 2048 ) not null,
    instance_key	raw( 32 )	not null,
    start_time		timestamp default SYSTIMESTAMP,
    primary key( server_id ) )
/

create sequence ml_primary_server_sequence start with 1 increment by 1 nomaxvalue
/

create trigger ml_primary_server_trigger
    before insert on ml_primary_server for each row
begin
    select ml_primary_server_sequence.nextval into :new.server_id from dual;
end;
/

--
-- Add SQL Batch tables and related procedures
--
create table ml_passthrough_script (
    script_id			integer		not null,
    script_name			varchar2( 128 )	not null,
    flags			varchar2( 256 )	null,
    affected_pubs		clob		null,
    script			clob		not null,
    description 		varchar2( 2000 ) null,
    primary key( script_id ) )
/
create sequence ml_pt_sql_sequence start with 1 increment by 1 nomaxvalue
/
create trigger ml_pt_sql_trigger before insert on ml_passthrough_script for each row
begin
    select ml_pt_sql_sequence.nextval into :new.script_id from dual;
end;
/

create table ml_passthrough (
    remote_id		varchar2( 128 )	not null,
    run_order		integer		not null,
    script_id		integer		not null,
    last_modified	timestamp default SYSTIMESTAMP,
    primary key( remote_id, run_order ),
    constraint ml_passthrough_rid foreign key( remote_id ) references ml_database( remote_id ),
    constraint ml_passthrough_sid foreign key( script_id ) references ml_passthrough_script( script_id ) )
/

create table ml_passthrough_status (
    status_id		integer		not null,
    remote_id		varchar2( 128 )	not null,
    run_order		integer		not null,
    script_id		integer		not null,
    script_status	char( 1 )	not null,
    error_code		integer		null,
    error_text		clob		null,
    remote_run_time	timestamp	not null,
    primary key( status_id ),
    unique( remote_id, run_order, remote_run_time ),
    constraint ml_passthrough_statis_rid foreign key( remote_id ) references ml_database( remote_id ) )
/

create sequence ml_pt_status_sequence start with 1 increment by 1 nomaxvalue
/

create trigger ml_pt_status_trigger before insert on ml_passthrough_status for each row
begin
    if :new.status_id is null then
	select ml_pt_status_sequence.nextval into :new.status_id from dual;
    end if;
end;
/

create table ml_passthrough_repair (
    failed_script_id		integer		not null,
    error_code			integer		not null,
    new_script_id		integer		null,
    action			char( 1 )	not null,
    primary key( failed_script_id, error_code ),
    constraint ml_passthrough_repair_fid foreign key( failed_script_id ) references ml_passthrough_script( script_id ) )
/

create trigger ml_passthrough_trigger before update on ml_passthrough
    for each row
begin
    if :new.last_modified = :old.last_modified then
	:new.last_modified := SYSTIMESTAMP ;
    end if;
end;
/

create procedure ml_add_passthrough_script(
    p_script_name		in varchar2,
    p_flags			in varchar2,
    p_affected_pubs		in clob,
    p_script			in clob,
    p_description		in varchar2 )
as
    v_count		integer;
    v_substr		varchar2(256 );
    v_start		integer;
    v_end		integer;
    v_error		integer;
    v_done		integer;
begin
    if p_script_name is not null and p_script is not null then
	v_error := 0;
	if p_flags is not null then
	    v_start := 1;
	    v_done := 0;
	    loop
		v_end := instr( p_flags, ';', v_start, 1 );
		if v_end = 0 then
		    v_end := length( p_flags ) + 1;
		    v_done := 1;
		end if;
		v_substr := substr( p_flags, v_start, v_end - v_start ); 
		if v_substr is not null then
		    if v_substr not in ('manual', 'exclusive', 'schema_diff' ) then
			raise_application_error( -20000, 'Invalid flag: "' || v_substr || '".' );
			v_error := 1;
			exit;
		    end if;
		end if;
		exit when v_done = 1;
		v_start := v_end + 1;
	    end loop;
	end if;
	if v_error = 0 then
	    begin
		select count(*) into v_count from ml_passthrough_script where script_name = p_script_name;
	    exception
		when NO_DATA_FOUND then
		    v_count := 0;
	    end;
	    if v_count <= 0 then
		insert into ml_passthrough_script( script_name, flags, affected_pubs,
				      script, description )
		    values( p_script_name, p_flags, p_affected_pubs,
			    p_script, p_description );
	    else 
		raise_application_error( -20000,
		    'The script name: "' || p_script_name || '" already exists in the ml_passthrough_script table.  Please choose another script name.' );
	    end if;
	end if;
    else
	raise_application_error( -20000,
	    'Neither passthrough script name nor script content can be null.' );
    end if;
end;
/

create procedure ml_delete_passthrough_script(
    p_script_name		in varchar2 )
as
    v_script_id integer;
    v_cnt1 integer;
    v_cnt2 integer;
begin
    begin
	select script_id into v_script_id from ml_passthrough_script where script_name = p_script_name;
    exception
	when NO_DATA_FOUND then
	    v_script_id := NULL;
    end;
    if v_script_id is not null then
	begin
	    select count(*) into v_cnt1 from ml_passthrough
		where script_id = v_script_id;
	exception
	    when NO_DATA_FOUND then
		v_cnt1 := 0;
	end;
	begin
	    select count(*) into v_cnt2 from ml_passthrough_repair
			    where failed_script_id = v_script_id or
				  new_script_id = v_script_id;
	exception
	    when NO_DATA_FOUND then
		v_cnt2 := 0;
	end;
	if v_cnt1 = 0 and v_cnt2 = 0 then
	    delete from ml_passthrough_script where script_id = v_script_id;
	end if;
    end if;
end;
/

create procedure ml_add_passthrough(
    p_remote_id		in varchar2,
    p_script_name	in varchar2,
    p_run_order		in integer )
as
    v_rid	varchar2( 128 );
    v_name	varchar2( 128 );
    v_order	integer;
    v_count	integer;
    v_script_id	integer;
    cursor	rid_crsr is
		select remote_id from ml_database;
begin
    begin
    select script_id into v_script_id from ml_passthrough_script
	    where script_name = p_script_name;
    exception
	when NO_DATA_FOUND then
	    v_script_id := NULL;
    end;
    if v_script_id is not null then
	if p_run_order is not null and p_run_order < 0 then
	    raise_application_error( -20000,
		'A negative value for run_order is not allowed' );
	else
	    if p_remote_id is null then
		if p_run_order is null then
		    select nvl( max( run_order ) + 10, 10 ) into v_order
			from ml_passthrough;
		else
		    v_order := p_run_order;
		end if;
		open rid_crsr;
		loop
		    fetch rid_crsr into v_rid;
		    exit when rid_crsr%NOTFOUND;
		    insert into ml_passthrough( remote_id, run_order, script_id )
			    values( v_rid, v_order, v_script_id );
		end loop;
		close rid_crsr;
	    else
		if p_run_order is null then
		    select nvl( max( run_order ) + 10, 10 ) into v_order
			from ml_passthrough where remote_id = p_remote_id;
		    insert into ml_passthrough( remote_id, run_order, script_id )
			values( p_remote_id, v_order, v_script_id );
		else 
		    select count(*) into v_count from ml_passthrough
			where remote_id = p_remote_id and run_order = p_run_order;
		    if v_count > 0 then
			update ml_passthrough set script_id = v_script_id,
			    last_modified = SYSTIMESTAMP 
			    where remote_id = p_remote_id and run_order = p_run_order;
		    else
			insert into ml_passthrough( remote_id, run_order, script_id )
			    values( p_remote_id, p_run_order, v_script_id );
		    end if;
		end if;
	    end if;
	end if;
    else
	raise_application_error( -20000,
	    'Passthrough script name: "' || p_script_name ||
		'" does not exist in the ml_passthrough_script table.' );
    end if;
end;
/

create procedure ml_delete_passthrough(
    p_remote_id		in varchar2,
    p_script_name	in varchar2,
    p_run_order		in integer )
as
begin
    if p_remote_id is null then
	if p_run_order is null then
	    delete from ml_passthrough
		where script_id in
		    (select script_id from ml_passthrough_script where script_name = p_script_name);
	else
	    delete from ml_passthrough
		where run_order = p_run_order and script_id in
		    (select script_id from ml_passthrough_script where script_name = p_script_name);
	end if;
    else 
	if p_run_order is null then
	    delete from ml_passthrough
		where remote_id = p_remote_id and script_id in
		    (select script_id from ml_passthrough_script where script_name = p_script_name);
	else
	    delete from ml_passthrough
		where remote_id = p_remote_id and run_order = p_run_order and script_id in
		    (select script_id from ml_passthrough_script where script_name = p_script_name);
	end if;
    end if;
end;
/

create procedure ml_add_passthrough_repair(
    p_failed_script_name	in varchar2,
    p_error_code		in integer,
    p_new_script_name		in varchar2,
    p_action			in char )
as
    v_failed_script_id integer;
    v_new_script_id integer;
    v_count integer;
    v_name varchar2( 128 );
begin
    begin
	select script_id into v_failed_script_id from ml_passthrough_script
	    where script_name = p_failed_script_name;
    exception
	when NO_DATA_FOUND then
	    v_failed_script_id := NULL;
    end;
    if v_failed_script_id is not null then
	if p_action in ( 'R', 'S', 'P', 'H', 'r', 's', 'p', 'h' ) then
	    if p_action in ( 'R', 'r' ) and p_new_script_name is null then
		raise_application_error( -20000,
		    'The new_script_name cannot be null for action "' || p_action || '".' );
	    elsif p_action in ( 'S', 'P', 'H', 's', 'p', 'h' ) and p_new_script_name is not null then
		raise_application_error( -20000,
		    'The new_script_name should be null for action "' || p_action || '".' );
	    else
		begin
		    select count(*) into v_count from ml_passthrough_script
			where script_name = p_new_script_name;
		exception
		    when NO_DATA_FOUND then
			v_count := 0;
		end;
		if p_new_script_name is null or v_count > 0 then
		    begin
			select script_id into v_new_script_id from ml_passthrough_script
			    where script_name = p_new_script_name;
		    exception
			when NO_DATA_FOUND then
			    v_new_script_id := NULL;
		    end;
		    begin
			select count(*) into v_count from ml_passthrough_repair
				   where failed_script_id = v_failed_script_id and
					 error_code = p_error_code;
		    exception
			when NO_DATA_FOUND then
			    v_count := 0;
		    end;
		    if v_count > 0 then
			update ml_passthrough_repair
			    set new_script_id = v_new_script_id, action = p_action
			    where failed_script_id = v_failed_script_id and
				 error_code = p_error_code;
		    else 
			insert into ml_passthrough_repair
			    (failed_script_id, error_code, new_script_id, action)
			    values( v_failed_script_id, p_error_code,
				    v_new_script_id, p_action );
		    end if;
		else
		    raise_application_error( -20000,
			'Invalid new_script_name: "' || p_new_script_name || '".' );
		end if;
	    end if;
	else
	    raise_application_error( -20000,
		'Invalid action: "' || p_action || '".' );
	end if;
    else
	raise_application_error( -20000,
	    'Invalid failed_script_name: "' || p_failed_script_name || '".' );
    end if;
end;
/

create procedure ml_delete_passthrough_repair(
    p_failed_script_name	in varchar2,
    p_error_code		in integer )
as
begin
    if p_error_code is null then
	delete from ml_passthrough_repair
	    where failed_script_id =
		(select script_id from ml_passthrough_script where script_name = p_failed_script_name);
    else
	delete from ml_passthrough_repair
	    where failed_script_id =
		(select script_id from ml_passthrough_script where script_name = p_failed_script_name) and
		error_code = p_error_code;
    end if;
end;
/

--
-- Add the ml_columns view
--
create view ml_columns as
select ml_script_version.name version,
       ml_table.name table_name,
       ml_column.name column_name,
       ml_column.type data_type,
       ml_column.idx column_order
from ml_script_version,
     ml_table,
     ml_column
where ml_column.version_id = ml_script_version.version_id
and ml_column.table_id = ml_table.table_id
/

create trigger ml_column_trigger after insert or update or delete on ml_column
    for each row
begin
    update ml_scripts_modified set last_modified = SYSTIMESTAMP ;
end;
/

drop procedure ml_delete_user
/

drop procedure ml_delete_sync_state
/

drop procedure ml_delete_sync_state_before
/

create procedure ml_delete_remote_id(
    p_remote_id		varchar2 )
as
    v_rid		integer;
begin 
    select rid into v_rid from ml_database where remote_id = p_remote_id;
    if v_rid is not null then
	delete from ml_subscription where rid = v_rid;
	delete from ml_passthrough_status where remote_id = p_remote_id;
	delete from ml_passthrough where remote_id = p_remote_id;
	delete from ml_database where rid = v_rid;
    end if;
end;
/

create procedure ml_delete_user_state(
     p_user_name	in varchar2 )
as
    v_uid		integer;
    v_rid		integer;
    v_rid_cnt		integer;
    v_remote_id		varchar( 128 );
    cursor		crsr is select distinct rid
			    from ml_subscription
			    where user_id = v_uid;
begin
    if p_user_name is null then
	v_uid := NULL;
    else
	begin
	    select user_id into v_uid from ml_user
		where name = p_user_name;
	exception
	    when NO_DATA_FOUND then
		v_uid := NULL;
	end;
    end if;
    if v_uid is not null then
	open crsr;
	loop
	    fetch crsr into v_rid;
	    exit when crsr%NOTFOUND;
	    delete from ml_subscription
		where user_id = v_uid and rid = v_rid;
	    select count(*) into v_rid_cnt from ml_subscription
		where rid = v_rid;
	    if v_rid_cnt = 0 then
		select remote_id into v_remote_id
		    from ml_database where rid = v_rid;
		ml_delete_remote_id( v_remote_id );
	    end if;
	end loop;
	close crsr;
    end if;
end;
/

create procedure ml_delete_user(
    p_user		varchar2 )
as
begin
    ml_delete_user_state( p_user );
    delete from ml_user where name = p_user;
end;
/

create procedure ml_delete_sync_state(
    p_user_name	in	varchar2,
    p_remote_id	in	varchar2 ) 
as
    v_uid		integer;
    v_rid		integer;
    v_rid_cnt		integer;
    cursor		crsr is select rid
			    from ml_subscription
			    where user_id = v_uid;
begin
    if p_user_name is null then
	v_uid := NULL;
    else
	begin
	    select user_id into v_uid from ml_user
		where name = p_user_name;
	exception
	    when NO_DATA_FOUND then
		v_uid := NULL;
	end;
    end if;
    if p_remote_id is null then
	v_rid := NULL;
    else
	begin
	    select rid into v_rid from ml_database
		where remote_id = p_remote_id;
	exception
	    when NO_DATA_FOUND then
		v_rid := NULL;
	end;
    end if;
    if p_user_name is not null and p_remote_id is not null then
	delete from ml_passthrough_status where remote_id = p_remote_id;
	delete from ml_passthrough where remote_id = p_remote_id;
	if v_uid is not null and v_rid is not null then
	    delete from ml_subscription
		where user_id = v_uid and rid = v_rid;
	end if;
	select count(*) into v_rid_cnt from ml_subscription where rid = v_rid;
	if v_rid_cnt = 0 then
	    ml_delete_remote_id( p_remote_id );
	end if;
    elsif p_user_name is not null then
	ml_delete_user_state( p_user_name );
    elsif p_remote_id is not null then
	ml_delete_remote_id( p_remote_id );
    end if;
end;
/

create procedure ml_delete_sync_state_before(
    p_ts in		timestamp )
as
    v_rid		integer;
    v_rid_cnt		integer;
    v_remote_id		varchar( 128 );
    cursor		crsr is select distinct rid from ml_subscription
			    where last_upload_time < p_ts and
				  last_download_time < p_ts;
begin
    if p_ts is not null then
	open crsr;
	loop
	    fetch crsr into v_rid;
	    exit when crsr%NOTFOUND;
	    delete from ml_subscription
			where rid = v_rid and
			      last_upload_time < p_ts and
			      last_download_time < p_ts;
	    select count(*) into v_rid_cnt from ml_subscription
		where rid = v_rid;
	    if v_rid_cnt = 0 then
		select remote_id into v_remote_id from ml_database where rid = v_rid;
		ml_delete_remote_id( v_remote_id );
	    end if;
	end loop;
	close crsr;
    end if;
end;
/

create or replace procedure ml_share_all_scripts( 
    p_version		in varchar2,
    p_other_version	in varchar2 )
as    
    v_version_id	integer;
    v_other_version_id	integer;
begin
    begin
	select version_id into v_version_id from ml_script_version
			       where name = p_version;
    exception			       
	when NO_DATA_FOUND then
		v_version_id := NULL;
    end;
    select version_id into v_other_version_id from ml_script_version 
		where name = p_other_version;

    if v_version_id is null then
	-- Insert to the ml_script_version
	select max( version_id )+1 into v_version_id from ml_script_version;
	if v_version_id is null then
	    v_version_id := 1;
	end if;
	insert into ml_script_version ( version_id, name )
		values ( v_version_id, p_version );
    end if;

    insert into ml_table_script( version_id, table_id, event, script_id )
	select v_version_id, table_id, event, script_id from ml_table_script 
	    where version_id = v_other_version_id;
    
    insert into ml_connection_script( version_id, event, script_id )
	select v_version_id, event, script_id from ml_connection_script 
	    where version_id = v_other_version_id;
end;
/

create or replace procedure ml_add_missing_dnld_scripts(
    p_script_version	in varchar2 )
as
    v_version_id	integer;
    v_table_id		integer;
    v_count		integer;
    v_count_1		integer;
    v_count_2		integer;
    v_table_name	varchar2(128);
    v_tid		integer;
    v_first		integer;
    cursor		crsr is
	    select t.table_id from ml_table_script t, ml_script_version v
		where t.version_id = v.version_id and
		      v.name = p_script_version order by 1;
begin
    begin
	select version_id into v_version_id from ml_script_version
	    where name = p_script_version;
    exception
	when NO_DATA_FOUND then
	    v_version_id := null;
    end;
    if v_version_id is not null then
	v_first := 1;
	open crsr;
	loop
	    fetch crsr into v_table_id;
	    exit when crsr%NOTFOUND;
	    if v_first = 1 or v_table_id <> v_tid then
		select count(*) into v_count_1 from ml_table_script
		    where version_id = v_version_id and
			table_id = v_table_id and
			event = 'download_cursor';
		select count(*) into v_count_2 from ml_table_script
		    where version_id = v_version_id and
			table_id = v_table_id and
			event = 'download_delete_cursor';
		if v_count_1 = 0 or v_count_2 = 0 then
		    select name into v_table_name from ml_table where table_id = v_table_id;
		    if v_count_1 = 0 then
			    ml_add_table_script( p_script_version, v_table_name,
				'download_cursor', '--{ml_ignore}' );
		    end if;
		    if v_count_2 = 0 then
			    ml_add_table_script( p_script_version, v_table_name,
				'download_delete_cursor', '--{ml_ignore}' );
		    end if;
		end if;
		v_first := 0;
		v_tid := v_table_id;
	    end if;
	end loop;
	close crsr;
    end if;
end;
/

--
-- Add a stored procedure for retrieving locking/blocking information
--
-- Create a stored procedure to get the connections
-- that are currently blocking the connections given
-- by p_sids for more than p_block_time seconds

-- This stored procedure needs to have select
-- permission on gv_$lock and gv_$session

create or replace procedure ml_get_blocked_info(
    p_sids		in varchar2,
    p_block_time	in integer,
    p_crsr		in out sys_refcursor )
as
    v_sql		varchar2(2100);
begin
    v_sql := 'select l2.sid, l1.sid, l2.ctime, 1, o.owner || ''.'' || o.object_name' ||
	' from gv$lock l1, gv$lock l2, dba_objects o, gv$session s' ||
	' where l1.id1 = l2.id1 and l1.id2 = l2.id2 and s.sid = l2.sid and o.object_id = s.row_wait_obj# and l1.block = 1 and l2.request > 0 and l2.sid in (' || p_sids ||
	' ) and l2.ctime > ' || p_block_time ||
	' order by 1';

    open p_crsr for v_sql;
end;
/

--
-- Add new stored procedures for user authentication using LDAP servers
--
create procedure ml_add_ldap_server ( 
    p_ldsrv_name	in varchar2,
    p_search_url    	in varchar2,
    p_access_dn    	in varchar2,
    p_access_dn_pwd	in varchar2,
    p_auth_url		in varchar2,
    p_conn_retries	in smallint,
    p_conn_timeout	in smallint,
    p_start_tls		in smallint ) 
as
    v_sh_url	varchar2( 1024 );
    v_as_dn	varchar2( 1024 );
    v_as_pwd	varchar2( 256 );
    v_au_url	varchar2( 1024 );
    v_timeout	smallint;
    v_retries	smallint;
    v_tls	smallint;
    v_count	integer;
    v_ldsrv_id	integer;
begin
    if p_ldsrv_name is not null then
	if p_search_url is null and
	    p_access_dn is null and
	    p_access_dn_pwd is null and
	    p_auth_url is null and
	    p_conn_timeout is null and
	    p_conn_retries is null and
	    p_start_tls is null then
	    
	    -- delete the server if it is not used
	    select count(*) into v_count
		from ml_ldap_server s, ml_user_auth_policy p
		where ( s.ldsrv_id = p.primary_ldsrv_id or
			s.ldsrv_id = p.secondary_ldsrv_id ) and
			s.ldsrv_name = p_ldsrv_name;
	    if v_count = 0 then
		delete from ml_ldap_server where ldsrv_name = p_ldsrv_name; 
	    end if;
	else
	    begin
		select ldsrv_id into v_ldsrv_id from ml_ldap_server
		    where ldsrv_name = p_ldsrv_name;
	    exception
		when NO_DATA_FOUND then
		    v_ldsrv_id := NULL;
	    end;
	    if v_ldsrv_id is null then
		-- add a new ldap server
		if p_conn_timeout is null then
		    v_timeout := 10;
		else
		    v_timeout := p_conn_timeout;
		end if;
		if p_conn_retries is null then
		    v_retries := 3;
		else
		    v_retries := p_conn_retries;
		end if;
		if p_start_tls is null then
		    v_tls := 0;
		else
		    v_tls := p_start_tls;
		end if;
		
		insert into ml_ldap_server ( ldsrv_name, search_url,
			access_dn, access_dn_pwd, auth_url,
			timeout, num_retries, start_tls )
		    values( p_ldsrv_name, p_search_url,
			    p_access_dn, p_access_dn_pwd,
			    p_auth_url, v_timeout, v_retries, v_tls );
	    else
		-- update the ldap server info
		select search_url, access_dn, access_dn_pwd,
			auth_url, timeout, num_retries, start_tls
			into
			v_sh_url, v_as_dn, v_as_pwd,
			v_au_url, v_timeout, v_retries, v_tls
		    from ml_ldap_server where ldsrv_name = p_ldsrv_name;
		    
		if p_search_url is not null then
		    v_sh_url := p_search_url;
		end if;
		if p_access_dn is not null then
		    v_as_dn := p_access_dn;
		end if;
		if p_access_dn_pwd is not null then
		    v_as_pwd := p_access_dn_pwd;
		end if;
		if p_auth_url is not null then
		    v_au_url := p_auth_url;
		end if;
		if p_conn_timeout is not null then
		    v_timeout := p_conn_timeout;
		end if;
		if p_conn_retries is not null then
		    v_retries := p_conn_retries;
		end if;
		if p_start_tls is not null then
		    v_tls := p_start_tls;
		end if;
		    
		update ml_ldap_server set
			search_url = v_sh_url,
			access_dn = v_as_dn,
			access_dn_pwd = v_as_pwd,
			auth_url = v_au_url,
			timeout = v_timeout,
			num_retries = v_retries,
			start_tls = v_tls
		where ldsrv_name = p_ldsrv_name;
	    end if;
	end if;
    end if;
end;
/

create procedure ml_add_certificates_file (
    p_file_name		in varchar2 )
as
begin
    if p_file_name is not null then
	delete from ml_trusted_certificates_file;
	insert into ml_trusted_certificates_file
	    ( file_name ) values( p_file_name );
    end if;
end;
/

create procedure ml_add_user_auth_policy (
    p_policy_name		in varchar2,
    p_primary_ldsrv_name	in varchar2,
    p_secondary_ldsrv_name	in varchar2,
    p_ldap_auto_failback_period	in integer,
    p_ldap_failover_to_std	in integer )
as
    v_pldsrv_id	integer;
    v_sldsrv_id	integer;
    v_pid	integer;
    v_sid	integer;
    v_period	integer;
    v_failover	integer;
    v_error	integer;
    v_count	integer;
begin
    if p_policy_name is not null then
	if p_primary_ldsrv_name is null and 
	    p_secondary_ldsrv_name is null and 
	    p_ldap_auto_failback_period is null and 
	    p_ldap_failover_to_std is null then
	    
	    -- delete the policy name if not used
	    select count(*) into v_count
		from ml_user u, ml_user_auth_policy p
		where u.policy_id = p.policy_id and
		      p.policy_name = p_policy_name;
	    if v_count = 0 then
		delete from ml_user_auth_policy
		    where policy_name = p_policy_name;
	    end if;
	elsif p_primary_ldsrv_name is null then
	   -- error
	   raise_application_error( -20000, 
		       'The primary LDAP server cannot be NULL.' );
	else
	    v_error := 0;
	    if p_primary_ldsrv_name is not null then
		begin
		    select ldsrv_id into v_pldsrv_id
			from ml_ldap_server
			where ldsrv_name = p_primary_ldsrv_name;
		    exception
			when NO_DATA_FOUND then
			    v_pldsrv_id := NULL;
		end;
		if v_pldsrv_id is null then
		    v_error := 1;
		    raise_application_error( -20000, 
			'Primary LDAP server "' || p_primary_ldsrv_name || '" is not defined.' );
		end if;
	    else
		v_pldsrv_id := null;
	    end if;
	    if p_secondary_ldsrv_name is not null then
		begin
		    select ldsrv_id into v_sldsrv_id
			from ml_ldap_server
			where ldsrv_name = p_secondary_ldsrv_name;
		exception
		    when NO_DATA_FOUND then
			v_sldsrv_id := NULL;
		end;
		if v_sldsrv_id is null then
		    v_error := 1;
		    raise_application_error( -20000,
			'Secondary LDAP server "' || p_secondary_ldsrv_name || '" is not defined.' );
		end if;
	    else
		v_sldsrv_id := null;
	    end if;
	    if v_error = 0 then
		select count(*) into v_count from ml_user_auth_policy
		    where policy_name = p_policy_name;
		if v_count = 0 then
		    if p_ldap_auto_failback_period is null then
			v_period := 900;
		    else
			v_period := p_ldap_auto_failback_period;
		    end if;
		    if p_ldap_failover_to_std is null then
			v_failover := 1;
		    else
			v_failover := p_ldap_failover_to_std;
		    end if;
		    
		    -- add a new user auth policy
		    insert into ml_user_auth_policy
			( policy_name, primary_ldsrv_id, secondary_ldsrv_id,
			  ldap_auto_failback_period, ldap_failover_to_std )
			values( p_policy_name, v_pldsrv_id, v_sldsrv_id,
				v_period, v_failover );
		else
		    select primary_ldsrv_id, secondary_ldsrv_id,
			    ldap_auto_failback_period, ldap_failover_to_std
			    into
			    v_pid, v_sid, v_period, v_failover
			from ml_user_auth_policy where policy_name = p_policy_name;
    
		    if v_pldsrv_id is not null then
			v_pid := v_pldsrv_id;
		    end if;
		    if v_sldsrv_id is not null then
			v_sid := v_sldsrv_id;
		    end if;
		    if p_ldap_auto_failback_period is not null then
			v_period := p_ldap_auto_failback_period;
		    end if;
		    if p_ldap_failover_to_std is not null then
			v_failover := p_ldap_failover_to_std;
		    end if;

		    -- update the user auth policy
		    update ml_user_auth_policy set
				primary_ldsrv_id = v_pid,
				secondary_ldsrv_id = v_sid,
				ldap_auto_failback_period = v_period,
				ldap_failover_to_std = v_failover
			where policy_name = p_policy_name;
		end if;
	    end if;
	end if;
    end if;
end;
/

--
-- Recreate the ml_reset_sync_state stored procedure
--
drop procedure ml_reset_sync_state
/

create procedure ml_reset_sync_state(
    p_user_name	in	varchar2,
    p_remote_id	in	varchar2 ) 
as
    v_uid	integer;
    v_rid	integer;
begin
    if p_user_name is null then
	v_uid := NULL;
    else
	begin
	    select user_id into v_uid from ml_user
		where name = p_user_name;
	exception
	    when NO_DATA_FOUND then
		v_uid := NULL;
	end;
    end if;
    if p_remote_id is null then
	v_rid := NULL;
    else
	begin
	    select rid into v_rid from ml_database
		where remote_id = p_remote_id;
	exception
	    when NO_DATA_FOUND then
		v_rid := NULL;
	end;
    end if;
    
    if p_user_name is not null and p_remote_id is not null then
	if v_uid is not null and v_rid is not null then
	    update ml_subscription
		set progress = 0,
		    last_upload_time   = TO_TIMESTAMP('1900-01-01 00:00:00','YYYY-MM-DD HH24:MI:SSXFF'),
		    last_download_time = TO_TIMESTAMP('1900-01-01 00:00:00','YYYY-MM-DD HH24:MI:SSXFF')
		where user_id = v_uid and rid = v_rid;
	end if;
    elsif p_user_name is not null then
	if v_uid is not null then
	    update ml_subscription
		set progress = 0,
		    last_upload_time   = TO_TIMESTAMP('1900-01-01 00:00:00','YYYY-MM-DD HH24:MI:SSXFF'),
		    last_download_time = TO_TIMESTAMP('1900-01-01 00:00:00','YYYY-MM-DD HH24:MI:SSXFF')
		where user_id = v_uid;
	end if;
    elsif p_remote_id is not null then
	if v_rid is not null then
	    update ml_subscription
		set progress = 0,
		    last_upload_time   = TO_TIMESTAMP('1900-01-01 00:00:00','YYYY-MM-DD HH24:MI:SSXFF'),
		    last_download_time = TO_TIMESTAMP('1900-01-01 00:00:00','YYYY-MM-DD HH24:MI:SSXFF')
		where rid = v_rid;
	end if;
    end if;
    update ml_database
	set sync_key = NULL,
	    seq_id = NULL,
	    seq_uploaded = 0,
	    script_ldt = TO_TIMESTAMP('1900-01-01 00:00:00','YYYY-MM-DD HH24:MI:SSXFF')
	where remote_id = p_remote_id;
end;
/


---------------------------------------------------
--   Schema for ML Remote administration
---------------------------------------------------

create table ml_ra_schema_name (
    schema_name                     varchar2( 128 ) not null,
    remote_type                    varchar2(1) not null,
    last_modified                  timestamp not null,
    description		           varchar2( 2048 ) null,
    primary key (schema_name) 
)
/


create table ml_ra_agent (
    aid                            integer not null,
    agent_id                       varchar2( 128 ) not null unique,
    taskdb_rid                     integer null,
    primary key( aid ),
    constraint ml_ra_agent_rid foreign key( taskdb_rid ) references ml_database ( rid )
)
/

create unique index tdb_rid on ml_ra_agent( taskdb_rid ) 
/

create sequence ml_ra_agent_sequence start with 1 increment by 1 nomaxvalue
/

create trigger ml_ra_agent_trigger before insert on ml_ra_agent for each row
begin
    select ml_ra_agent_sequence.nextval into :new.aid from dual;
end;
/


create table ml_ra_task (
    task_id                        number( 20 ) not null,
    task_name                      varchar2( 128 ) not null unique,
    schema_name		           varchar2( 128 ) null,
    max_running_time               integer null,
    max_number_of_attempts         integer null,
    delay_between_attempts         integer null,
    flags                          number( 20 ) not null,
    cond                           clob null,
    remote_event                   clob null,
    random_delay_interval	   integer default 0 not null,
    primary key( task_id ), 
    constraint ml_ra_task_class foreign key( schema_name ) references ml_ra_schema_name( schema_name )
)
/

create sequence ml_ra_task_sequence start with 1 increment by 1 nomaxvalue
/

create trigger ml_ra_task_trigger before insert on ml_ra_task for each row
begin
    select ml_ra_task_sequence.nextval into :new.task_id from dual;
end;
/


create table ml_ra_deployed_task (
    task_instance_id               number( 20 ) not null,
    aid                            integer not null,
    task_id                        number( 20 ) not null,
    assignment_time                timestamp default systimestamp not null,
    state                          varchar2( 4 ) default 'P' not null,
    previous_exec_count            number( 20 ) default 0 not null,
    previous_error_count           number( 20 ) default 0 not null,
    previous_attempt_count         number( 20 ) default 0 not null,
    reported_exec_count            number( 20 ) default 0 not null,
    reported_error_count           number( 20 ) default 0 not null,
    reported_attempt_count         number( 20 ) default 0 not null,
    last_modified                  timestamp not null,
    unique( aid, task_id ),
    primary key( task_instance_id ), 
    constraint ml_ra_deployed_aid foreign key( aid ) references ml_ra_agent( aid ),
    constraint ml_ra_deployed_tid foreign key( task_id ) references ml_ra_task( task_id )
)
/

create index dt_tid_idx on ml_ra_deployed_task( task_id )
/

create sequence ml_ra_deployed_task_sequence start with 1 increment by 1 nomaxvalue
/

create trigger ml_ra_deployed_task_trigger before insert on ml_ra_deployed_task for each row
begin
    select ml_ra_deployed_task_sequence.nextval into :new.task_instance_id from dual;
end;
/


create table ml_ra_task_command (
    task_id                        number( 20 ) not null,
    command_number                 integer not null,
    flags                          number( 20 ) default 0 not null,
    action_type                    varchar2( 4 ) not null,
    action_parm                    clob null, -- different than other platforms because "" is null
    primary key( task_id, command_number ),
    constraint ml_ra_task_comm_tid foreign key( task_id ) references ml_ra_task( task_id )
)
/


create table ml_ra_event (
    event_id                       number( 20 ) not null,
    event_class                    varchar2( 4 ) not null,
    event_type                     varchar2( 8 ) not null,
    aid				   integer null,
    task_id		           number( 20 ) null,
    command_number                 integer null,
    run_number                     number( 20 ) null,
    duration                       integer null,
    event_time                     timestamp not null,
    event_received                 timestamp default systimestamp not null,
    result_code                    number( 20 ) null,
    result_text                    clob null,
    primary key (event_id) 
)
/

create index ev_tn_idx on ml_ra_event( task_id )
/

create index ev_time_idx on ml_ra_event( event_received )
/

create index ev_agent_idx on ml_ra_event( aid )
/

create sequence ml_ra_event_sequence start with 1 increment by 1 nomaxvalue
/

create trigger ml_ra_event_trigger before insert on ml_ra_event for each row
begin
    select ml_ra_event_sequence.nextval into :new.event_id from dual;
end;
/


create table ml_ra_event_staging (
    taskdb_rid			   integer not null,
    remote_event_id                number( 20 ) not null,
    event_class                    varchar2( 4 ) not null,
    event_type                     varchar2( 8 ) not null,
    task_instance_id               number( 20 ) null,
    command_number                 integer null,
    run_number                     number( 20 ) null,
    duration                       integer null,
    event_time                     timestamp not null,
    result_code                    number( 20 ) null,
    result_text                    clob null,
    primary key( taskdb_rid, remote_event_id ) 
)
/


create index evs_type_idx on ml_ra_event_staging( event_type )
/


create table ml_ra_notify (
    agent_poll_key                 varchar2( 128 ) not null,
    task_instance_id               number( 20 ) not null,
    last_modified                  timestamp not null,
    primary key( agent_poll_key, task_instance_id ),
    constraint ml_ra_notify_pkey foreign key( agent_poll_key ) references ml_ra_agent( agent_id )
)
/


create table ml_ra_task_property (
    task_id                        number( 20 ) not null,
    property_name                  varchar2( 128 ) not null,
    last_modified                  timestamp not null,
    property_value                 clob null,
    primary key( property_name, task_id ), 
    constraint ml_ra_task_prop_tid foreign key( task_id ) references ml_ra_task( task_id )
)
/


create table ml_ra_task_command_property (
    task_id                        number( 20 ) not null,
    command_number                 integer not null,
    property_name                  varchar2( 128 ) not null,
    property_value                 varchar2( 2048 ) null,
    last_modified                  timestamp not null,
    primary key( task_id, command_number, property_name ), 
    constraint ml_ra_task_comm_prop_tid foreign key( task_id, command_number ) references ml_ra_task_command( task_id, command_number )
)
/


create table ml_ra_managed_remote (
    mrid			   integer not null,
    remote_id			   varchar2(128) null,
    aid                            integer not null,
    schema_name		           varchar2( 128 ) not null,
    conn_str		           varchar2( 2048 ) not null,
    last_modified                  timestamp not null,
    unique( aid, schema_name ),
    primary key( mrid ),
    constraint ml_ra_managed_aid foreign key( aid ) references ml_ra_agent( aid ),
    constraint ml_ra_managed_class foreign key( schema_name ) references ml_ra_schema_name( schema_name )
)
/

create sequence ml_ra_mr_sequence start with 1 increment by 1 nomaxvalue
/

create trigger ml_ra_mr_trigger before insert on ml_ra_managed_remote for each row
begin
    select ml_ra_mr_sequence.nextval into :new.mrid from dual;
end;
/



create table ml_ra_agent_property (
    aid                            integer not null,
    property_name                  varchar2( 128 ) not null,
    property_value                 varchar2( 2048 ) null,
    last_modified                  timestamp not null,
    primary key( aid, property_name ),
    constraint ml_ra_agent_prop_aid foreign key( aid ) references ml_ra_agent( aid )
)
/


create table ml_ra_agent_staging (
    taskdb_rid			   integer not null,
    property_name                  varchar2( 128 ) not null,
    property_value                 varchar2( 2048 ) null,
    primary key( taskdb_rid, property_name ) 
)
/


-----------------------------------------------------------------
-- Stored procedures for Tasks
-----------------------------------------------------------------

-- Assign a remote task to a specific agent.

create procedure ml_ra_assign_task(
    p_agent_id		in varchar2,  
    p_task_name		in varchar2 )
as
    v_task_id		number( 20 );
    v_task_instance_id	number( 20 );
    v_old_state		varchar( 4 );
    v_aid		integer;
    v_rid		integer;
begin
    begin
	select task_id into v_task_id
	    from ml_ra_task where task_name = p_task_name;
    exception
	when NO_DATA_FOUND then
	    v_task_id := null;
    end;
    if v_task_id is null then
	raise_application_error( -20101, 'bad_task_name' );
	return;
    end if;

    begin
	select aid into v_aid from ml_ra_agent where agent_id = p_agent_id;
    exception
	when NO_DATA_FOUND then
	    v_aid := null;
    end;
    if v_aid is null then 
	raise_application_error( -20102, 'bad_agent_id' );
	return;
    end if;

    begin
	select state, task_instance_id into v_old_state, v_task_instance_id
	    from ml_ra_deployed_task where task_id = v_task_id and aid = v_aid;
    exception
	when NO_DATA_FOUND then
	    v_old_state := null;
	    v_task_instance_id := null;
    end;
    if v_task_instance_id is null then
	insert into ml_ra_deployed_task( aid, task_id, last_modified ) 
	    values ( v_aid, v_task_id, systimestamp );
    elsif v_old_state != 'A' and v_old_state != 'P' then
	-- Re-activate the task
	update ml_ra_deployed_task 
	    set state = 'P',
	    previous_exec_count = reported_exec_count + previous_exec_count,
	    previous_error_count = reported_error_count + previous_error_count,
	    previous_attempt_count = reported_attempt_count + previous_attempt_count,
	    reported_exec_count = 0,
	    reported_error_count = 0,
	    reported_attempt_count = 0,
	    last_modified = systimestamp
	where task_instance_id = v_task_instance_id;
    end if;
    -- if the task is already active then do nothing 
end;
/


create procedure ml_ra_int_cancel_notification(
    p_agent_id		in varchar2,
    p_task_instance_id	in number,
    p_request_time	in timestamp ) 
as
begin
    delete from ml_ra_notify
	where agent_poll_key = p_agent_id
	    and task_instance_id = p_task_instance_id
	    and last_modified <= p_request_time;
end;
/


create procedure ml_ra_cancel_notification(
    p_agent_id	in varchar2,
    p_task_name	in varchar2 )
as
    v_task_instance_id	number( 20 );
    v_ts		timestamp;
begin
    select task_instance_id into v_task_instance_id
	from ml_ra_agent
	    join ml_ra_deployed_task on ml_ra_deployed_task.aid = ml_ra_agent.aid
	    join ml_ra_task on ml_ra_deployed_task.task_id = ml_ra_task.task_id
	where agent_id = p_agent_id 
	    and task_name = p_task_name;

    v_ts := systimestamp;
    ml_ra_int_cancel_notification( p_agent_id, v_task_instance_id, v_ts );
end;
/


create procedure ml_ra_cancel_task_instance(
    p_agent_id	in varchar2, 
    p_task_name	in varchar2 )
as
    v_task_id	number( 20 );
    v_aid	integer;
begin
    begin
	select task_id into v_task_id
	    from ml_ra_task where task_name = p_task_name;
    exception
	when NO_DATA_FOUND then
	    v_task_id := null;
    end;
    begin
	select ml_ra_agent.aid into v_aid
	    from ml_ra_agent where agent_id = p_agent_id;
    exception
	when NO_DATA_FOUND then
	    v_aid := 0;
    end;
    update ml_ra_deployed_task set state = 'CP', last_modified = systimestamp
	where aid = v_aid and task_id = v_task_id 
	    and ( state = 'A' or state = 'P' );
    if SQL%ROWCOUNT = 0 then
	raise_application_error( -20101, 'bad task instance' );
	return;
    end if;
    ml_ra_cancel_notification( p_agent_id, p_task_name );
end;
/


-- If error is raised then caller must rollback

create procedure ml_ra_delete_task(
    p_task_name	in varchar2 )
as
    v_task_id	number( 20 );
begin
    begin
	select task_id into v_task_id from ml_ra_task
	    where task_name = p_task_name;
    exception
	when NO_DATA_FOUND then
	    v_task_id := null;
    end;
    if v_task_id is null then
	raise_application_error( -20101, 'bad task name' );
	return;
    end if;

    -- Only delete inactive instances, operation
    -- will fail if active instances exist.
    delete from ml_ra_deployed_task where task_id = v_task_id 
	and ( state != 'A' and state != 'P' and state != 'CP' );
    delete from ml_ra_task_command_property where task_id = v_task_id;
    delete from ml_ra_task_command where task_id = v_task_id;
    delete from ml_ra_task_property where task_id = v_task_id;
    delete from ml_ra_task where task_id = v_task_id;
end;
/


-- result contains a row for each deployed instance of every task

create procedure ml_ra_get_task_status(
    p_agent_id	in varchar2,
    p_task_name	in varchar2,
    p_crsr	in out sys_refcursor )
as
begin
    open p_crsr for
    select agent_id,
	mr.remote_id,
	t.task_name,
	t.task_id,
	dt.state,
	dt.reported_exec_count + dt.previous_exec_count,
	dt.reported_error_count + dt.previous_error_count,
	dt.reported_attempt_count + dt.previous_attempt_count,
	dt.last_modified,
	( select max( event_time ) from ml_ra_event 
	    where ml_ra_event.task_id = t.task_id),
	dt.assignment_time
    from ml_ra_task t 
	join ml_ra_deployed_task dt on t.task_id = dt.task_id
	join ml_ra_agent a on a.aid = dt.aid
	left outer join ml_ra_managed_remote mr on mr.schema_name = t.schema_name
	    and mr.aid = a.aid
    where
	( p_agent_id is null or a.agent_id = p_agent_id )
	and ( p_task_name is null or t.task_name = p_task_name )
    order by agent_id, t.task_name;
end;
/


create procedure ml_ra_notify_agent_sync(
    p_agent_id	in varchar2 )
as
    v_cnt	integer;
    v_aid	integer;
begin
    begin
	select aid into v_aid from ml_ra_agent where agent_id = p_agent_id;
    exception
	when NO_DATA_FOUND then
	    return;
    end;
    begin
	select count(*) into v_cnt from ml_ra_notify
	    where agent_poll_key = p_agent_id and task_instance_id = -1;
    exception
	when NO_DATA_FOUND then
	    v_cnt := 0;
    end;
    if v_cnt > 0 then	
	update ml_ra_notify set last_modified = systimestamp
	    where agent_poll_key = p_agent_id and task_instance_id = -1;
    else
	insert into ml_ra_notify( agent_poll_key, task_instance_id,
				  last_modified )
	    values( p_agent_id, -1, systimestamp );
    end if;
end;
/


create procedure ml_ra_notify_task(
    p_agent_id		in varchar2, 
    p_task_name		in varchar2 )
as
    v_cnt		integer;
    v_task_instance_id	number( 20 );
begin
    begin
	select task_instance_id into v_task_instance_id
	    from ml_ra_agent
		join ml_ra_deployed_task on ml_ra_deployed_task.aid = ml_ra_agent.aid
		join ml_ra_task on ml_ra_deployed_task.task_id = ml_ra_task.task_id
	    where agent_id = p_agent_id 
		and task_name = p_task_name;
    exception
	when NO_DATA_FOUND then
	    v_task_instance_id := 0;
    end;
    begin
	select count(*) into v_cnt from ml_ra_notify
	    where agent_poll_key = p_agent_id and
		task_instance_id = v_task_instance_id;
    exception
	when NO_DATA_FOUND then
	    v_cnt := 0;
    end;
    if v_cnt > 0 then
	update ml_ra_notify set last_modified = systimestamp
	    where agent_poll_key = p_agent_id and
		task_instance_id = v_task_instance_id;
    else
	insert into ml_ra_notify( agent_poll_key, task_instance_id,
				  last_modified )
	    values( p_agent_id, v_task_instance_id, systimestamp ); 
    end if;
end;
/


create procedure ml_ra_get_latest_event_id(
    p_event_id	in out number )
as
begin
    select max( event_id ) into p_event_id from ml_ra_event;
end;
/


create procedure ml_ra_get_agent_events(
    p_start_at_event_id		in number, 
    p_max_events_to_fetch	in number,
    p_crsr			in out sys_refcursor )
as
begin
    open p_crsr for
    select * from ( select
	event_id, 
	event_class, 
	event_type,
	ml_ra_agent.agent_id, 
	mr.remote_id,
	t.task_name,
	command_number,
	run_number,
	duration,
	event_time, 
	event_received,
	result_code, 
	result_text
    from ml_ra_event e
	left outer join ml_ra_agent on ml_ra_agent.aid = e.aid
	left outer join ml_ra_task t on t.task_id = e.task_id 
	left outer join ml_ra_managed_remote mr on 
	    mr.schema_name = t.schema_name and mr.aid = ml_ra_agent.aid
    where
	event_id >= p_start_at_event_id
    order by event_id ) where rownum <= p_max_events_to_fetch;
end;
/


create procedure ml_ra_get_task_results( 
    p_agent_id		in varchar2, 
    p_task_name		in varchar2,
    p_run_number	integer,
    p_crsr		in out sys_refcursor )
as
    v_run_number	integer;
    v_aid		integer;
    v_remote_id		varchar2(128);
    v_task_id		number(20);
begin

    begin
	select aid into v_aid from ml_ra_agent where agent_id = p_agent_id;
	select task_id, remote_id into v_task_id, v_remote_id from ml_ra_task t
	    left outer join ml_ra_managed_remote mr 
		on mr.schema_name = t.schema_name and mr.aid = v_aid
	    where task_name = p_task_name;
    exception
	when NO_DATA_FOUND then
	    v_aid := null;
	    v_task_id := null;
	    v_remote_id := null;
    end;

    if p_run_number is null then
	-- get the latest run
	begin
	    select max( run_number ) into v_run_number from ml_ra_event
		where ml_ra_event.aid = v_aid and
		    ml_ra_event.task_id = v_task_id;
	exception
	    when NO_DATA_FOUND then
		v_run_number := 0;
	end;
    else
	v_run_number := p_run_number;
    end if;

    open p_crsr for
    select 
	event_id, 
	event_class, 
	event_type,
	p_agent_id, 
	v_remote_id,
	p_task_name,
	command_number,
	run_number,
	duration,
	event_time, 
	event_received,
	result_code, 
	result_text
    from ml_ra_event e
    where e.aid = v_aid and
	e.task_id = v_task_id and
	e.run_number = v_run_number
    order by event_id;
end;
/



-- Maintenance functions ----------------------------------

create procedure ml_ra_get_agent_ids(
    p_crsr	in out sys_refcursor )
as
begin
    open p_crsr for
    select agent_id, 
	( select max( last_download_time ) from ml_subscription mlsb
	    where mlsb.rid = ml_ra_agent.taskdb_rid ), 
	( select max( last_upload_time ) from ml_subscription mlsb
	    where mlsb.rid = ml_ra_agent.taskdb_rid ), 
	( select count(*) from ml_ra_deployed_task
	    where ml_ra_deployed_task.aid = ml_ra_agent.aid
	      and (state = 'A' or state = 'P' or state = 'CP') ),
	remote_id,
	property_value
    from ml_ra_agent left outer join ml_database on ml_database.rid = taskdb_rid
	left outer join ml_ra_agent_property
	on ml_ra_agent.aid = ml_ra_agent_property.aid
	    and property_name = 'ml_ra_description'
    order by agent_id;
end;
/


create procedure ml_ra_get_remote_ids(
    p_crsr	in out sys_refcursor )
as
begin
    open p_crsr for
    select ml_database.remote_id,
	schema_name,
	agent.agent_id,
	conn_str,
	( select max( last_download_time ) from ml_subscription mlsb where mlsb.rid = ml_database.rid ), 
	( select max( last_upload_time ) from ml_subscription mlsb where mlsb.rid = ml_database.rid ), 
	description
    from ml_database 
	left outer join ml_ra_managed_remote on ml_database.remote_id = ml_ra_managed_remote.remote_id
	left outer join ml_ra_agent agent on agent.aid = ml_ra_managed_remote.aid
	left outer join ml_ra_agent_staging s on s.taskdb_rid = ml_database.rid and property_name = 'agent_id'
    where property_value is null
    order by ml_database.remote_id;
end;
/


create procedure ml_ra_set_agent_property(
    p_agent_id		in varchar2,
    p_property_name	in varchar2,
    p_property_value	in varchar2 )
as
    v_cnt		    integer;
    v_aid		    integer;
    v_server_interval	    integer;
    v_old_agent_interval    integer;
    v_new_agent_interval    integer;
    v_autoset		    varchar2(3);
begin
    begin
	select aid into v_aid from ml_ra_agent where agent_id = p_agent_id;
    exception
	when NO_DATA_FOUND then
	    v_aid := null;
    end;

    if p_property_name = 'lwp_freq' then
	begin
	    select property_value into v_autoset from ml_property where 
		component_name = 'SIRT'
		and property_set_name = 'RTNotifier(RTNotifier1)'
		and property_name = 'autoset_poll_every';
	exception
	    when NO_DATA_FOUND then
		v_autoset := null;
	end;

	if v_autoset = 'yes' then
	    begin
		select cast( cast( property_value as varchar(20) ) as integer ) into v_server_interval from ml_property where 
		    component_name = 'SIRT'
		    and property_set_name = 'RTNotifier(RTNotifier1)'
		    and property_name = 'poll_every';
	    exception
		when NO_DATA_FOUND then
		    v_server_interval := 2147483647;
	    end;
	    begin
		select property_value into v_old_agent_interval from ml_ra_agent_property where
		    aid = v_aid
		    and property_name = 'lwp_freq';
	    exception
		when NO_DATA_FOUND then
		    v_old_agent_interval := 2147483647;
	    end;

	    v_new_agent_interval := p_property_value;
	    if v_new_agent_interval < v_server_interval then
		ml_add_property( 'SIRT', 'RTNotifier(RTNotifier1)', 'poll_every', p_property_value );
	    elsif v_new_agent_interval > v_server_interval then
		if v_new_agent_interval > v_old_agent_interval and v_old_agent_interval <= v_server_interval then
		    -- This agents interval is increasing, check if server interval should increase too
		    begin
			select property_value into v_old_agent_interval from ml_ra_agent_property 
			    where property_name = 'lwp_freq'
			    and cast(property_value as integer) <= v_old_agent_interval
			    and aid != v_aid;
		    exception
			when TOO_MANY_ROWS then
			    -- no-op
			    v_cnt := 0;
			when NO_DATA_FOUND then
			    -- Need to compute the new server interval
			    begin
				select min( cast( property_value as integer ) ) into v_server_interval from ml_ra_agent_property 
				    where property_name = 'lwp_freq' and aid != v_aid;
			    exception
				when NO_DATA_FOUND then
				    v_server_interval := null;
			    end;
			    if v_server_interval is null then 
				v_server_interval := v_new_agent_interval;
			    end if;
			    ml_add_property( 'SIRT', 'RTNotifier(RTNotifier1)', 'poll_every', cast( v_server_interval as varchar ) );
		    end;
		end if;
	    end if;
	end if;
    end if;	

    begin
	select count(*) into v_cnt from ml_ra_agent_property
	    where aid = v_aid and property_name = p_property_name;
    exception
	when NO_DATA_FOUND then
	    v_cnt := 0;
    end;
    if v_cnt > 0 then
	update ml_ra_agent_property
	    set property_value = p_property_value,
		last_modified = systimestamp
	    where aid = v_aid and property_name = p_property_name;
    else
	insert into ml_ra_agent_property( aid, property_name,
					  property_value, last_modified )
	    values( v_aid, p_property_name, p_property_value, systimestamp );
    end if;
end;
/


-- If error is raised then caller must rollback

create procedure ml_ra_clone_agent_properties(
    p_dst_agent_id	in varchar2,
    p_src_agent_id	in varchar2 )
as
    v_dst_aid	integer;
    v_src_aid	integer;
begin
    begin
	select aid into v_dst_aid from ml_ra_agent
	    where agent_id = p_dst_agent_id;
    exception
	when NO_DATA_FOUND then
	    v_dst_aid := null;
    end;
    begin
	select aid into v_src_aid from ml_ra_agent
	    where agent_id = p_src_agent_id;
    exception
	when NO_DATA_FOUND then
	    v_src_aid := null;
    end;
    if v_src_aid is null then
	raise_application_error( -20101, 'bad src' );
	return;
    end if;

    delete from ml_ra_agent_property
	where aid = v_dst_aid
	    and property_name != 'agent_id'
	    and property_name not like 'ml+_ra+_%' escape '+';

    insert into ml_ra_agent_property( aid, property_name, property_value, last_modified )
	select v_dst_aid, src.property_name, src.property_value, systimestamp 
	from ml_ra_agent_property src 
	where src.aid = v_src_aid 
	    and property_name != 'agent_id' 
	    and property_name not like 'ml+_ra+_%' escape '+';
end;
/


create procedure ml_ra_get_agent_properties(
    p_agent_id	in varchar2,
    p_crsr	in out sys_refcursor )
as
    v_aid	integer;
begin
    begin
	select aid into v_aid from ml_ra_agent where agent_id = p_agent_id;
    exception
	when NO_DATA_FOUND then
	    v_aid := null;
    end;
    
    open p_crsr for
	select property_name, property_value, last_modified
	from ml_ra_agent_property 
	where aid = v_aid
	    and property_name != 'agent_id'
	    and property_name not like 'ml+_ra+_%' escape '+'
	order by property_name;
end;
/


-- If error is raised then caller must rollback

create procedure ml_ra_add_agent_id(
    p_agent_id	in varchar2 )
as
    v_aid	 integer;
begin
    insert into ml_ra_agent( agent_id ) values ( p_agent_id );
    select ml_ra_agent_sequence.currval into v_aid from dual;

    insert into ml_ra_event( event_class, event_type, aid, event_time ) 
	values( 'I', 'ANEW', v_aid, systimestamp );
    ml_ra_set_agent_property( p_agent_id, 'agent_id', p_agent_id );
    ml_ra_set_agent_property( p_agent_id, 'max_taskdb_sync_interval', '86400' );
    ml_ra_set_agent_property( p_agent_id, 'lwp_freq', '900' );
    ml_ra_set_agent_property( p_agent_id, 'agent_id_status', 'OK' );
end;
/


-- If error is raised then caller must rollback

create procedure ml_ra_manage_remote_db(
    p_agent_id		in varchar2, 
    p_schema_name	in varchar2,
    p_conn_str		in varchar2 )
as
    v_aid	 integer;
    v_ldt	 timestamp;
begin
    begin

    select aid, last_download_time into v_aid, v_ldt from 
	ml_ra_agent left outer join ml_subscription on taskdb_rid = rid
    where agent_id = p_agent_id;

    exception
	when NO_DATA_FOUND then
	    v_aid := null;
    end;
    insert into ml_ra_managed_remote(aid, remote_id, schema_name, conn_str, last_modified ) 
	values( v_aid, null, p_schema_name, p_conn_str, systimestamp );

    update ml_ra_deployed_task dt set state = 'A' 
	where aid = v_aid and state = 'P' and last_modified < v_ldt
	    and exists( select * from ml_ra_task t where t.task_id = dt.task_id and t.schema_name = p_schema_name );
end;
/


-- If error is raised then caller must rollback

create procedure ml_ra_unmanage_remote_db(
    p_agent_id in varchar2,
    p_schema_name in varchar2 )
as
    v_aid		integer;
    v_has_tasks		integer;
begin
    begin
	select aid into v_aid from ml_ra_agent where agent_id = p_agent_id;
    exception
	when NO_DATA_FOUND then
	    v_aid := null;
    end;

    begin
	select count(*) into v_has_tasks from ml_ra_deployed_task dt
	    join ml_ra_task t on dt.task_id = t.task_id
	    where dt.aid = v_aid and t.schema_name = p_schema_name
		and (state = 'A' or state = 'P' or state = 'CP' );
    exception
	when NO_DATA_FOUND then
	    v_has_tasks := 0;
    end;
    if v_has_tasks > 0 then
	raise_application_error( -20101, 'has active tasks' );
	return;
    end if;

    delete from ml_ra_deployed_task
	where aid = v_aid and state != 'A' and state != 'P' and state != 'CP'
	    and exists( select * from ml_ra_task where ml_ra_task.task_id = ml_ra_deployed_task.task_id
		and ml_ra_task.schema_name = p_schema_name );
    delete from ml_ra_managed_remote where aid = v_aid and schema_name = p_schema_name;
end;
/


-- If error is raised then caller must rollback

create procedure ml_ra_delete_agent_id(
    p_agent_id		varchar2 )
as
    v_aid		integer;
    v_taskdb_rid	integer;
    v_taskdb_remote_id	varchar2( 128 );
    cursor		taskdb_crsr is
	select taskdb_rid, ml_database.rid remote_id from ml_ra_agent_staging
	    join ml_database on ml_database.rid = taskdb_rid
	    where property_name = 'agent_id' and property_value = p_agent_id;
begin
    begin
	select aid, taskdb_rid into v_aid, v_taskdb_rid
	    from ml_ra_agent where agent_id = p_agent_id;
    exception
	when NO_DATA_FOUND then
	    v_aid := null;
	    v_taskdb_rid := null;
    end;
    if v_aid is null then
	raise_application_error( -20101, 'bad agent id' );
	return;
    end if;

    ml_ra_set_agent_property( p_agent_id, 'lwp_freq', '2147483647' );

    -- Delete all dependent rows
    delete from ml_ra_agent_property where aid = v_aid;
    delete from ml_ra_deployed_task where aid = v_aid;
    delete from ml_ra_notify where agent_poll_key = p_agent_id;
    delete from ml_ra_managed_remote where aid = v_aid;

    -- Delete the agent
    delete from ml_ra_agent where aid = v_aid;

    -- Clean up any taskdbs that were associated with this agent_id
    open taskdb_crsr;
    loop
	fetch taskdb_crsr into v_taskdb_rid, v_taskdb_remote_id;
	exit when taskdb_crsr%NOTFOUND;
	delete from ml_ra_agent_staging where taskdb_rid = v_taskdb_rid;
	delete from ml_ra_event_staging where taskdb_rid = v_taskdb_rid;
	ml_delete_remote_id( v_taskdb_remote_id );
    end loop;
    close taskdb_crsr;
end;
/


create procedure ml_ra_int_move_events(
    p_aid		in integer, 
    p_taskdb_rid	in integer )
as
begin
    -- Copy events into ml_ra_event from staging table
    insert into ml_ra_event( event_class, event_type, aid, task_id,
			     command_number, run_number, duration, event_time,
			     event_received, result_code, result_text )
	select event_class, event_type, p_aid, dt.task_id,
	       command_number, run_number, duration, event_time,
	       systimestamp, result_code, result_text
	    from ml_ra_event_staging es
		left outer join ml_ra_deployed_task dt on dt.task_instance_id = es.task_instance_id
	    where es.taskdb_rid = p_taskdb_rid
	    order by remote_event_id;

    -- Clean up staged values
    delete from ml_ra_event_staging where taskdb_rid = p_taskdb_rid;
end;
/


create procedure ml_ra_delete_events_before(
    p_delete_rows_older_than	timestamp )
as
begin
    delete from ml_ra_event where event_received <= p_delete_rows_older_than;
end;
/


create procedure ml_ra_get_orphan_taskdbs(
    p_crsr	in out sys_refcursor )
as
begin
    open p_crsr for
    select remote_id, property_value,
	( select max( last_upload_time ) from ml_subscription mlsb
	    where mlsb.rid = ml_database.rid ) 
    from ml_database 
	left outer join ml_ra_agent agent on agent.taskdb_rid = rid
	left outer join ml_ra_agent_staging s on s.taskdb_rid = rid
	    and property_name = 'agent_id'
    where property_value is not null and agent_id is null
    order by remote_id;
end;
/


-- If error is raised then caller must rollback

create procedure ml_ra_reassign_taskdb(
    p_taskdb_remote_id	in varchar2,
    p_new_agent_id	in varchar2 )
as
    v_other_taskdb_rid	integer;
    v_taskdb_rid	integer;
    v_other_agent_aid	integer;
    v_old_agent_id	varchar2( 128 );
    v_new_aid		integer;
begin
    begin
	select rid into v_taskdb_rid from ml_database
	    where remote_id = p_taskdb_remote_id;
    exception
	when NO_DATA_FOUND then
	    v_taskdb_rid := null;
    end;
    if v_taskdb_rid is null then
	raise_application_error( -20101, 'bad remote' );
	return;
    end if;

    begin
	select property_value into v_old_agent_id from ml_ra_agent_staging
	    where taskdb_rid = v_taskdb_rid and
	    property_name = 'agent_id';
    exception
	when NO_DATA_FOUND then
	    v_old_agent_id := null;
    end;
    if v_old_agent_id is null then
	raise_application_error( -20101, 'bad remote' );
	return;
    end if;

    begin
	select count(*) into v_other_taskdb_rid from ml_ra_agent
	    where agent_id = p_new_agent_id;
    exception
	when NO_DATA_FOUND then
	    v_other_taskdb_rid := 0;
    end;
    if v_other_taskdb_rid = 0 then
	ml_ra_add_agent_id( p_new_agent_id );
    end if;
    -- if v_other_taskdb_rid is not null then it becomes a new orphan taskdb

    -- If the taskdb isn't already orphaned then break the link with its original agent_id
    update ml_ra_agent set taskdb_rid = null where taskdb_rid = v_taskdb_rid;

    update ml_ra_agent_staging set property_value = p_new_agent_id
	where taskdb_rid = v_taskdb_rid
	    and property_name = 'agent_id';

    -- Preserve any events that have been uploaded
    -- Note, no task state is updated here, these
    -- events are stale and may no longer apply.
    select aid into v_new_aid from ml_ra_agent where agent_id = p_new_agent_id;
    ml_ra_int_move_events( v_new_aid, v_taskdb_rid );

    -- The next time the agent syncs it will receive its new agent_id
    ml_ra_notify_agent_sync( v_old_agent_id );
end;
/


-----------------------------------------------------------------
-- Synchronization scripts for the remote agent's task database
-- Note, there is no authenticate user script here, this will need
-- to be provided by the user.
-----------------------------------------------------------------

create procedure ml_ra_ss_end_upload( 
    p_taskdb_remote_id		in varchar2 )
as
    v_taskdb_rid		integer;
    v_consdb_taskdb_rid		integer;
    v_consdb_taskdb_remote_id	varchar2( 128 );
    v_agent_id			varchar2( 128 );
    v_provided_id		varchar2( 128 );
    v_old_machine_name		varchar2( 128 );
    v_new_machine_name		varchar2( 128 );
    v_aid			integer;
    v_used			varchar2( 128 );
    v_name			varchar2( 128 );
    v_value			varchar( 2048 );
    v_old_value			varchar( 2048 );
    v_cnt			integer;
    v_schema_name		varchar2( 128 );

    v_task_instance_id		number( 20 );
    v_result_code		number( 20 );
    v_event_type		varchar2( 8 );
    cursor	 		event_crsr is
	    select event_type, result_code, substr( result_text, 1, 2048 ), task_instance_id
		from ml_ra_event_staging
		where taskdb_rid = v_taskdb_rid
		 order by remote_event_id;
    cursor			as_crsr is
	    select property_name, property_value
		from ml_ra_agent_staging
		where taskdb_rid = v_taskdb_rid and
		    property_name not like 'ml+_ra+_%' escape '+';
begin
    begin
	select rid, agent_id, aid into v_taskdb_rid, v_agent_id, v_aid
	    from ml_database left outer join ml_ra_agent on taskdb_rid = rid 
	    where remote_id = p_taskdb_remote_id;
    exception
	when NO_DATA_FOUND then
	    v_taskdb_rid := null;
	    v_agent_id := null;
	    v_aid := null;
    end;
    if v_agent_id is null then 
	-- This taskdb isn't linked to an agent_id in the consolidated yet
	delete from ml_ra_agent_staging where taskdb_rid = v_taskdb_rid and property_name = 'agent_id_status';
	begin
	    select property_value into v_provided_id from ml_ra_agent_staging 
		where taskdb_rid = v_taskdb_rid and
		    property_name = 'agent_id';
	exception
	    when NO_DATA_FOUND then
		v_provided_id := null;
	end;
	if v_provided_id is null then
	    -- Agent failed to provide an agent_id
	    insert into ml_ra_agent_staging( taskdb_rid,
		    property_name, property_value )
		    values( v_taskdb_rid, 'agent_id_status', 'RESET' );
	    return;
	end if;
	    
	begin
	    select taskdb_rid, aid into v_consdb_taskdb_rid, v_aid
		from ml_ra_agent where agent_id = v_provided_id;
	exception
	    when NO_DATA_FOUND then
		v_consdb_taskdb_rid := null;
		v_aid := null;
	end;
	if v_consdb_taskdb_rid is not null then
	    -- We have 2 remote task databases using the same agent_id.
	    -- Attempt to determine if its a reset of an agent or 2 separate 
	    -- agents conflicting with each other.
	    begin
		select remote_id into v_consdb_taskdb_remote_id 
		    from ml_database where rid = v_consdb_taskdb_rid;
	    exception
		when NO_DATA_FOUND then
		    v_consdb_taskdb_remote_id := null;
	    end;
	    v_old_machine_name := substr( v_consdb_taskdb_remote_id, 7,
				    length(v_consdb_taskdb_remote_id) - 43 );
	    v_new_machine_name := substr( p_taskdb_remote_id, 7,
				    length(p_taskdb_remote_id) - 43 );
	    if v_old_machine_name != v_new_machine_name then
		-- There are 2 agents with conflicting agent_ids
		-- This taskdb will not be allowed to download tasks.
		insert into ml_ra_event( event_class, event_type, aid,
					 event_time, result_text ) 
		    values( 'E', 'ADUP', v_aid, systimestamp,
			    p_taskdb_remote_id );
		insert into ml_ra_agent_staging( taskdb_rid,
			property_name, property_value )
			values( v_taskdb_rid, 'agent_id_status', 'DUP' );
		return;
	    end if; -- Otherwise, we allow replacement of the taskdb
	end if;	    

	v_agent_id := v_provided_id;
	if v_aid is null then
	    -- We have a new agent_id
	    ml_ra_add_agent_id( v_agent_id );
	    begin
		select aid into v_aid from ml_ra_agent where agent_id = v_agent_id;
	    exception
		when NO_DATA_FOUND then
		    v_aid := null;
	    end;
	end if;

	begin
	    select property_value into v_used from ml_ra_agent_staging 
		where taskdb_rid = v_taskdb_rid and
		    property_name = 'ml_ra_used';
	exception
	    when NO_DATA_FOUND then
		v_used := null;
	end;
	if v_used is not null then
	    -- We can only establish a mapping between new taskdb_remote_ids and agent_ids
	    insert into ml_ra_agent_staging( taskdb_rid,
		    property_name, property_value )
		    values( v_taskdb_rid, 'agent_id_status', 'RESET' );
	    -- Preserve any events that may have been uploaded
	    -- Note, no task state is updated here, these
	    -- events could be stale and may no longer apply.
	    ml_ra_int_move_events( v_aid, v_taskdb_rid );
	    return;
	else
	    insert into ml_ra_agent_staging( taskdb_rid, property_name,
					     property_value )
		values( v_taskdb_rid, 'ml_ra_used', '1' );
	end if;

	-- Store the link between this agent_id and remote_id
	update ml_ra_agent set taskdb_rid = v_taskdb_rid
	    where agent_id = v_agent_id;

	begin
	    select property_value into v_used from ml_ra_agent_property
		where aid = v_aid and property_name = 'ml_ra_used';
	exception
	    when NO_DATA_FOUND then
		v_used := null;
	end;
	if v_used is null then
	    -- This is the first taskdb for an agent
	    insert into ml_ra_event( event_class, event_type, aid,
				     event_time ) 
		values( 'I', 'AFIRST', v_aid, systimestamp );
	    insert into ml_ra_agent_property( aid, property_name,
					      property_value, last_modified )
		values( v_aid, 'ml_ra_used', '1', systimestamp );
	else
	    -- A new taskdb is taking over
	    insert into ml_ra_event( event_class, event_type, aid,
				     event_time, result_text ) 
		values( 'I', 'ARESET', v_aid, systimestamp,
			v_consdb_taskdb_remote_id );

	    update ml_ra_deployed_task
		set state = ( case state 
			when 'A' then 'P'
			when 'CP' then 'C'
			else state end ),
		    previous_exec_count = reported_exec_count + previous_exec_count,
		    previous_error_count = reported_error_count + previous_error_count,
		    previous_attempt_count = reported_attempt_count + previous_attempt_count,
		    reported_exec_count = 0,
		    reported_error_count = 0,
		    reported_attempt_count = 0,
		    last_modified = systimestamp
		where aid = v_aid;
	end if;
    end if;

    -- Update the status of deployed tasks
    open event_crsr;
    loop
	fetch event_crsr into v_event_type, v_result_code, v_value, v_task_instance_id;
	exit when event_crsr%NOTFOUND;
	if v_event_type like 'TI%' or v_event_type like 'TF%' then 
	    update ml_ra_deployed_task dt 
		set reported_exec_count = 
			( case when v_event_type = 'TIE' then
			    v_result_code else reported_exec_count end ),
		    reported_error_count = 
			( case when v_event_type = 'TIF' then
			    v_result_code else reported_error_count end ),
		    reported_attempt_count = 
			( case when v_event_type = 'TIA' then
			    v_result_code else reported_attempt_count end ),
		    state = 
			( case when v_event_type like('TF%') then
			    substr( v_event_type, 3 )
			  else 
			    state
			  end )
		where dt.task_instance_id = v_task_instance_id;
	    end if;

	    -- Store any updated remote_ids
	    if v_event_type = 'TRID' then
		select t.schema_name into v_schema_name from ml_ra_deployed_task dt
		    join ml_ra_task t on t.task_id = dt.task_id
		    where dt.task_instance_id = v_task_instance_id;
		update ml_ra_managed_remote set remote_id = v_value
		    where aid = v_aid and schema_name = v_schema_name;
	    end if;

	    -- Update remote schema names
	    if v_event_type = 'CR' and v_value like 'CHSN:%' then
		select substr( v_value, 6, length( v_value ) - 5 ) into v_value from dual;
		select t.schema_name into v_schema_name from ml_ra_deployed_task dt
		    join ml_ra_task t on t.task_id = dt.task_id
		    where dt.task_instance_id = v_task_instance_id;
		update ml_ra_managed_remote set schema_name = v_value
		    where aid = v_aid and schema_name = v_schema_name
			and exists( select * from ml_ra_schema_name where schema_name = v_value );

		-- Old tasks go back to pending after schema name change
		update ml_ra_deployed_task dt set state = 'P' 
		    where dt.aid = v_aid and state = 'A'
			and exists( select * from ml_ra_task t left outer join ml_ra_managed_remote mr
				on t.schema_name = mr.schema_name and mr.aid = v_aid
				where t.task_id = dt.task_id
				    and t.schema_name is not null 
				    and mr.schema_name is null );
	    end if;

    end loop;
    close event_crsr;

    -- TI status rows are not true events
    delete from ml_ra_event_staging
    	where taskdb_rid = v_taskdb_rid and event_type like 'TI%';

    -- Process SIRT ack
    delete from ml_ra_notify
	where exists( select * from ml_ra_event_staging 
	    where taskdb_rid = v_taskdb_rid and event_type like 'TS%'
	    and ml_ra_notify.task_instance_id = ml_ra_event_staging.task_instance_id 
	    and last_modified <= event_time );

    delete from ml_ra_notify where agent_poll_key = v_agent_id and task_instance_id != -1 
	and not exists(	select * from ml_ra_deployed_task where
	    ml_ra_deployed_task.task_instance_id = ml_ra_notify.task_instance_id );

    -- Get properties from the agent
    open as_crsr;
    loop
	v_cnt := null;
	fetch as_crsr into v_name, v_value;
	exit when as_crsr%NOTFOUND;
	begin
	    select property_value into v_old_value from ml_ra_agent_property
		where aid = v_aid and property_name = v_name;
	exception
	    when NO_DATA_FOUND then
		v_cnt := 0;
	end;
	if v_cnt = 0 then
	    insert into ml_ra_agent_property( aid, property_name,
					      property_value, last_modified )
		values( v_aid, v_name, v_value, systimestamp );
	else
	    if (v_old_value is null and v_value is not null ) 
		    or (v_old_value is not null and v_value is null )
		    or (v_old_value != v_value) then
		update ml_ra_agent_property set property_value = v_value, last_modified = systimestamp
		    where aid = v_aid and property_name = v_name;
	    end if;
	end if;
    end loop;
    close as_crsr;

    delete from ml_ra_agent_staging where taskdb_rid = v_taskdb_rid 
	and property_name not like 'ml+_ra+_%' escape '+'
	and property_name != 'agent_id';
    ml_ra_int_move_events( v_aid, v_taskdb_rid );
end;
/

create procedure ml_ra_ss_upload_prop(
    p_taskdb_remote_id varchar2, 
    p_property_name varchar2, 
    p_property_value varchar2 )
as    
    v_taskdb_rid integer;
    v_cnt integer;
begin

    begin
	select rid into v_taskdb_rid from ml_database where remote_id = p_taskdb_remote_id;
    exception
	when NO_DATA_FOUND then
	    v_taskdb_rid := null;
    end;

    begin
	select count(*) into v_cnt from ml_ra_agent_staging 
	    where taskdb_rid = v_taskdb_rid and property_name = p_property_name; 
    exception
	when NO_DATA_FOUND then
	    v_cnt := 0;
    end;

    if v_cnt > 0 then 
	update ml_ra_agent_staging set property_value = p_property_value
	    where taskdb_rid = v_taskdb_rid and property_name = p_property_name;
    else
	insert into ml_ra_agent_staging( taskdb_rid, property_name, property_value )
	    values( v_taskdb_rid, p_property_name, p_property_value );
    end if;
end;
/


create procedure ml_ra_ss_upload_event(
    p_taskdb_remote_id	in varchar2, 
    p_remote_event_id	number, 
    p_event_class	varchar2, 
    p_event_type	varchar2, 
    p_task_instance_id	number, 
    p_command_number	integer, 
    p_run_number	number, 
    p_duration		integer,
    p_event_time	timestamp,
    p_result_code	number, 
    p_result_text	clob )
as
    v_taskdb_rid        integer;
    v_cnt		integer;
begin
    select rid into v_taskdb_rid from ml_database where remote_id = p_taskdb_remote_id;
    begin
	insert into ml_ra_event_staging( taskdb_rid, remote_event_id, 
		event_class, event_type, task_instance_id,
		command_number, run_number, duration, event_time,
		result_code, result_text )
	    values ( v_taskdb_rid, p_remote_event_id, p_event_class,
		p_event_type, p_task_instance_id, p_command_number,
		p_run_number, p_duration, p_event_time, p_result_code,
		p_result_text );
	exception
	    when OTHERS then
		-- no-op, ignore duplicates
		v_cnt := 0;
    end;
end;
/


create procedure ml_ra_ss_download_ack(
    p_taskdb_remote_id	in varchar2, 
    p_ldt		in timestamp )
as
    v_aid		integer;
    v_agent_id		varchar2( 128 );
    v_task_instance_id	number( 20 );
    cursor	 	task_ack is
	select dt.task_instance_id from ml_ra_deployed_task dt
	    join ml_ra_task t on t.task_id = dt.task_id
	    left outer join ml_ra_managed_remote mr
		on t.schema_name = mr.schema_name and mr.aid = v_aid
	where dt.aid = v_aid
	    and dt.state = 'P' and dt.last_modified < p_ldt
	    and ( t.schema_name is null or mr.schema_name is not null ); 
begin
    begin
	select aid, agent_id into v_aid, v_agent_id from ml_ra_agent
	    join ml_database on taskdb_rid = rid
	    where remote_id = p_taskdb_remote_id;
    exception
	when NO_DATA_FOUND then
	    return;
    end;

    open task_ack;
    loop
	fetch task_ack into v_task_instance_id;
	exit when task_ack%NOTFOUND;
	update ml_ra_deployed_task set state = 'A' where task_instance_id = v_task_instance_id;
    end loop;
    close task_ack;
   
    delete from ml_ra_notify
	where agent_poll_key = v_agent_id
	    and task_instance_id = -1 
	    and last_modified <= p_ldt;
end;
/


-- Default file transfer scripts for upload and download

create procedure ml_ra_ss_agent_auth_file_xfer(
    p_requested_direction	in varchar2,
    p_auth_code			in out INTEGER,
    p_ml_user			in varchar2,
    p_remote_key		in varchar2,
    p_fsize			in number,
    p_filename			in out varchar2,
    p_sub_dir			in out varchar2 )  
as
    v_offset		integer;
    v_cmd_num		integer;
    v_tiid		number( 20 );
    v_tid		number( 20 );
    v_aid		integer;
    v_task_state	varchar2( 4 );
    v_max_size		number( 20 );
    v_direction		varchar2(1);
    v_server_sub_dir	varchar2( 128 );
    v_server_filename	varchar2( 128 );
    v_agent_id		varchar2( 128 );
begin
    -- By convention file transfer commands will send up the remote key with...
    -- task_instance_id command_number
    -- eg 1 5	-- task_instance_id=1 command_number=5
    v_offset := instr( p_remote_key, ' ', 1, 1 );
    if v_offset = 0 then
	p_auth_code := 2000;
	return;
    end if;

    v_tiid := substr( p_remote_key, 0, v_offset );
    v_cmd_num := substr( p_remote_key, v_offset + 1, length( p_remote_key ) - v_offset );
    if v_tiid is null or v_tiid < 1 or v_cmd_num is null or v_cmd_num < 0 then
	p_auth_code := 2000;
	return;
    end if;

    -- fetch properties of the task
    begin
	select task_id, aid, state into v_tid, v_aid, v_task_state
	    from ml_ra_deployed_task where task_instance_id = v_tiid;
    exception
	when NO_DATA_FOUND then
	    v_tid := null;
	    v_aid := null;
	    v_task_state := null;
    end;
    -- Disallow transfer if the task is no longer active
    if v_task_state is null or (v_task_state != 'A' and v_task_state != 'P') then
	p_auth_code := 2001;
	return;
    end if;

    -- Make sure the file isn't too big
    begin
	select property_value into v_max_size from ml_ra_task_command_property
	    where task_id = v_tid and
		command_number = v_cmd_num and
		property_name = 'mlft_max_file_size';
    exception
	when NO_DATA_FOUND then
	    v_max_size := 0;
    end;
    if v_max_size > 0 and p_fsize > v_max_size then
	p_auth_code := 2002;
	return;
    end if;

    -- Make sure the direction is correct
    begin
	select property_value into v_direction from ml_ra_task_command_property
	    where task_id = v_tid and
		command_number = v_cmd_num and
		property_name = 'mlft_transfer_direction';
    exception
	when NO_DATA_FOUND then
	    v_direction := null;
    end;
    if v_direction != p_requested_direction then
	p_auth_code := 2003;
	return;
    end if;

    -- set the filename output parameter
    begin
	select property_value into v_server_filename from ml_ra_task_command_property
	    where task_id = v_tid and
		command_number = v_cmd_num and
		property_name = 'mlft_server_filename';
    exception
	when NO_DATA_FOUND then
	    v_server_filename := null;
    end;
    if v_server_filename is not null then
	begin
	    select agent_id into v_agent_id from ml_ra_agent where aid = v_aid;
	exception
	    when NO_DATA_FOUND then
		v_agent_id := null;
	end;
	p_filename := replace(
	    replace( v_server_filename, '{ml_username}', p_ml_user ),
	    '{agent_id}', v_agent_id );
    end if;
			
    -- set the sub_dir output parameter
    begin
	select property_value into v_server_sub_dir from ml_ra_task_command_property
	    where task_id = v_tid and
		command_number = v_cmd_num and
		property_name = 'mlft_server_sub_dir';
    exception
	when NO_DATA_FOUND then
	    v_server_sub_dir := null;
    end;
    if v_server_sub_dir is null then
	p_sub_dir := '';
    else
	begin
	    select agent_id into v_agent_id from ml_ra_agent where aid = v_aid;
	exception
	    when NO_DATA_FOUND then
		v_agent_id := null;
	end;
	p_sub_dir := replace(
	    replace( v_server_sub_dir, '{ml_username}', p_ml_user ),
	    '{agent_id}', v_agent_id );
    end if;

    -- Everything is ok, allow the file transfer
    p_auth_code := 1000;
end;
/


commit
/


begin
    ml_add_connection_script( 'ml_ra_agent_12', 'end_upload', 
	'{call ml_ra_ss_end_upload( {ml s.remote_id} )}' );
end;
/

begin
    ml_add_table_script( 'ml_ra_agent_12', 'ml_ra_agent_adminprop', 'upload_insert',
	'{call ml_ra_ss_upload_prop( {ml s.remote_id}, {ml r.name}, {ml r.value} )}' );
end;
/

begin
    ml_add_table_script( 'ml_ra_agent_12', 'ml_ra_agent_adminprop', 'upload_update', 
	'{call ml_ra_ss_upload_prop( {ml s.remote_id}, {ml r.name}, {ml r.value} )}' );
end;
/

begin
    ml_add_table_script( 'ml_ra_agent_12', 'ml_ra_agent_adminprop', 'download_cursor',
	'select property_name, property_value from ml_ra_agent_staging s 
		join ml_database d on d.rid = s.taskdb_rid
		left outer join ml_ra_agent a on a.taskdb_rid = d.rid
	    where d.remote_id = {ml s.remote_id}
		and a.aid is null
		and property_name not like ''ml+_ra+_%'' escape ''+''
	union			
	select property_name, property_value from ml_ra_agent_property p
		join ml_ra_agent a on a.aid = p.aid
		join ml_database d on d.rid = a.taskdb_rid
	    where d.remote_id = {ml s.remote_id}
		and property_name not like ''ml+_ra+_%'' escape ''+'' 
		and last_modified >= {ml s.last_table_download}' );
end;
/


begin
    ml_add_table_script( 'ml_ra_agent_12', 'ml_ra_agent_adminprop', 'download_delete_cursor', 
	'--{ml_ignore}' );
end;
/


begin
    ml_add_connection_script( 'ml_ra_agent_12', 'nonblocking_download_ack', 
	'{call ml_ra_ss_download_ack( {ml s.remote_id}, {ml s.last_download} )}' );
end;
/


begin
    ml_add_table_script( 'ml_ra_agent_12', 'ml_ra_agent_task', 'download_cursor', 
	'select task_instance_id, task_name, ml_ra_task.schema_name,
	    max_number_of_attempts, delay_between_attempts,
	    max_running_time, ml_ra_task.flags,
	    case dt.state 
		when ''P'' then ''A''
		when ''CP'' then ''C''
	    end,
	    cond, remote_event
	from ml_database task_db
	    join ml_ra_agent on ml_ra_agent.taskdb_rid = task_db.rid
	    join ml_ra_deployed_task dt on dt.aid = ml_ra_agent.aid
	    join ml_ra_task on dt.task_id = ml_ra_task.task_id
	where task_db.remote_id = {ml s.remote_id}
	    and ( dt.state = ''CP'' or dt.state = ''P'' )' );
end;
/


begin
    ml_add_table_script( 'ml_ra_agent_12', 'ml_ra_agent_task', 'download_delete_cursor', 
	'--{ml_ignore}' );
end;
/


begin
    ml_add_table_script( 'ml_ra_agent_12', 'ml_ra_agent_command', 'download_cursor',
	'select task_instance_id, command_number, ml_ra_task_command.flags,
	    action_type, action_parm
	from ml_database task_db
	    join ml_ra_agent on ml_ra_agent.taskdb_rid = task_db.rid
	    join ml_ra_deployed_task dt on dt.aid = ml_ra_agent.aid
	    join ml_ra_task on dt.task_id = ml_ra_task.task_id
	    join ml_ra_task_command on dt.task_id = ml_ra_task_command.task_id
	where task_db.remote_id = {ml s.remote_id}
	    and dt.state = ''P''' );
end;
/

begin
    ml_add_table_script( 'ml_ra_agent_12', 'ml_ra_agent_command', 'download_delete_cursor', 
	'--{ml_ignore}' );
end;
/


begin
    ml_add_table_script( 'ml_ra_agent_12', 'ml_ra_agent_remote_db', 'download_cursor', 
	'select ml_ra_schema_name.schema_name, ml_ra_managed_remote.remote_id, conn_str, remote_type 
	from ml_database taskdb
	    join ml_ra_agent on ml_ra_agent.taskdb_rid = taskdb.rid
	    join ml_ra_managed_remote on ml_ra_managed_remote.aid = ml_ra_agent.aid
	    join ml_ra_schema_name on ml_ra_schema_name.schema_name = ml_ra_managed_remote.schema_name
	where taskdb.remote_id = {ml s.remote_id}
	    and ml_ra_managed_remote.last_modified >= {ml s.last_table_download}' );
end;
/

begin
    ml_add_table_script( 'ml_ra_agent_12', 'ml_ra_agent_remote_db', 'download_delete_cursor', 
	'--{ml_ignore}' );
end;
/


begin
    ml_add_table_script( 'ml_ra_agent_12', 'ml_ra_agent_remote_db', 'upload_insert', 
	'--{ml_ignore}' );
end;
/

begin
    ml_add_table_script( 'ml_ra_agent_12', 'ml_ra_agent_remote_db', 'upload_update', 
	'--{ml_ignore}' );
end;
/

begin
    ml_add_table_script( 'ml_ra_agent_12', 'ml_ra_agent_remote_db', 'upload_delete', 
	'--{ml_ignore}' );
end;
/



begin
    ml_add_table_script( 'ml_ra_agent_12', 'ml_ra_agent_status', 'upload_insert', 
	'{call ml_ra_ss_upload_event( 
	{ml s.remote_id}, {ml r.id}, {ml r.class}, {ml r.status}, 
	{ml r.task_instance_id}, {ml r.command_number}, {ml r.exec_count}, 
	{ml r.duration}, {ml r.status_time}, {ml r.status_code}, {ml r.text} )}' );
end;
/

begin
    ml_add_table_script( 'ml_ra_agent_12', 'ml_ra_agent_status', 'upload_update', 
	'{call ml_ra_ss_upload_event( 
	{ml s.remote_id}, {ml r.id}, {ml r.class}, {ml r.status}, 
	{ml r.task_instance_id}, {ml r.command_number}, {ml r.exec_count}, 
	{ml r.duration}, {ml r.status_time}, {ml r.status_code}, {ml r.text} )}' );
end;
/

begin
    ml_add_table_script( 'ml_ra_agent_12', 'ml_ra_agent_status', 'download_cursor', 
	'--{ml_ignore}' );
end;
/

begin
    ml_add_table_script( 'ml_ra_agent_12', 'ml_ra_agent_status', 'download_delete_cursor', 
	'--{ml_ignore}' );
end;
/


begin
    ml_add_connection_script( 'ml_ra_agent_12', 'authenticate_file_upload', 
	'{ call ml_ra_ss_agent_auth_file_xfer( ''U'', {ml s.file_authentication_code}, {ml s.username}, {ml s.remote_key}, {ml s.file_size}, {ml s.filename}, {ml s.subdir} ) }' );
end;
/

begin
    ml_add_connection_script( 'ml_ra_agent_12', 'authenticate_file_transfer', 
	'{ call ml_ra_ss_agent_auth_file_xfer( ''D'', {ml s.file_authentication_code}, {ml s.username}, {ml s.remote_key}, 0, {ml s.filename}, {ml s.subdir} ) }' );
end;
/

commit
/

execute ml_add_property( 'SIRT', 'RTNotifier(RTNotifier1)', 'request_cursor', 'select agent_poll_key,task_instance_id,last_modified from ml_ra_notify order by agent_poll_key' )
/

-- RT Notifier doesn't begin polling until an agent is created
execute ml_add_property( 'SIRT', 'RTNotifier(RTNotifier1)', 'poll_every', '2147483647' )
/


-- Set to 'no' to disable auto setting 'poll_every', then manually set 'poll_every'
execute ml_add_property( 'SIRT', 'RTNotifier(RTNotifier1)', 'autoset_poll_every', 'yes' )
/


execute ml_add_property( 'SIRT', 'RTNotifier(RTNotifier1)', 'enable', 'yes' )
/


-- Check for updates to started notifiers every minute
execute ml_add_property( 'SIRT', 'Global', 'update_poll_every', '60' )
/


-- Updated Script for 12.0.1
begin
    ml_share_all_scripts( 'ml_ra_agent_12_1', 'ml_ra_agent_12' );
end;
/

begin
    ml_add_table_script( 'ml_ra_agent_12_1', 'ml_ra_agent_task', 'download_cursor', 
	'select task_instance_id, task_name, ml_ra_task.schema_name,
	    max_number_of_attempts, delay_between_attempts,
	    max_running_time, ml_ra_task.flags,
	    case dt.state 
		when ''P'' then ''A''
		when ''CP'' then ''C''
	    end,
	    cond, remote_event, random_delay_interval
	from ml_database task_db
	    join ml_ra_agent on ml_ra_agent.taskdb_rid = task_db.rid
	    join ml_ra_deployed_task dt on dt.aid = ml_ra_agent.aid
	    join ml_ra_task on dt.task_id = ml_ra_task.task_id
	where task_db.remote_id = {ml s.remote_id}
	    and ( dt.state = ''CP'' or dt.state = ''P'' )' );
end;
/

drop package MLSetup
/

commit
/
quit
/
