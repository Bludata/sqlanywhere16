
--
-- Upgrade the MobiLink Server system tables and stored procedures in
-- an Oracle consolidated database.
--


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
-- Alter the ml_user table to add two new columns
--
alter table ml_user add policy_id integer null
    references ml_user_auth_policy( policy_id )
/ 

alter table ml_user add user_dn varchar2( 1024 ) null
/ 

--
-- Alter the ml_database table to add two new columns
--
alter table ml_database add seq_id raw(16) null
/

alter table ml_database add seq_uploaded integer default 0 not null
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
-- Recreate the ml_add_user stored procedure
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

commit
/

--
-- Changes for ML Remote administration
--

alter table ml_ra_task add random_delay_interval integer default 0 not null
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

--
-- Remove QAnywhere objects
--
exec ml_add_property( 'SIS', 'Notifier(QAnyNotifier_client)', 'gui', null );
exec ml_add_property( 'SIS', 'Notifier(QAnyNotifier_client)', 'enable', null );
exec ml_add_property( 'SIS', 'Notifier(QAnyNotifier_client)', 'poll_every', null );
exec ml_add_property( 'SIS', 'Notifier(QAnyNotifier_client)', 'request_cursor', null );
exec ml_add_property( 'SIS', 'Notifier(QAnyNotifier_client)', 'request_delete', null );
/

exec ml_add_property( 'SIS', 'Notifier(QAnyLWNotifier_client)', 'gui', null );
exec ml_add_property( 'SIS', 'Notifier(QAnyLWNotifier_client)', 'enable', null );
exec ml_add_property( 'SIS', 'Notifier(QAnyLWNotifier_client)', 'poll_every', null );
exec ml_add_property( 'SIS', 'Notifier(QAnyLWNotifier_client)', 'request_cursor', null );
/


exec ml_add_connection_script( 'ml_qa_3', 'handle_error', null );
exec ml_add_java_connection_script( 'ml_qa_3', 'begin_publication', null );
exec ml_add_java_connection_script( 'ml_qa_3', 'nonblocking_download_ack', null );
exec ml_add_java_connection_script( 'ml_qa_3', 'prepare_for_download', null );
exec ml_add_java_connection_script( 'ml_qa_3', 'begin_download', null );
exec ml_add_java_connection_script( 'ml_qa_3', 'modify_next_last_download_timestamp', null );
/

exec ml_add_table_script( 'ml_qa_3', 'ml_qa_repository_client', 'upload_insert', null );
exec ml_add_table_script( 'ml_qa_3', 'ml_qa_repository_client', 'download_delete_cursor', null );
exec ml_add_table_script( 'ml_qa_3', 'ml_qa_repository_client', 'download_cursor', null );
exec ml_add_table_script( 'ml_qa_3', 'ml_qa_delivery_client', 'upload_insert', null );
exec ml_add_table_script( 'ml_qa_3', 'ml_qa_delivery_client', 'upload_update', null );
exec ml_add_table_script( 'ml_qa_3', 'ml_qa_delivery_client', 'download_delete_cursor', null );
exec ml_add_table_script( 'ml_qa_3', 'ml_qa_delivery_client', 'download_cursor', null );
exec ml_add_table_script( 'ml_qa_3', 'ml_qa_global_props_client', 'upload_insert', null );
exec ml_add_table_script( 'ml_qa_3', 'ml_qa_global_props_client', 'upload_update', null );
exec ml_add_table_script( 'ml_qa_3', 'ml_qa_global_props_client', 'upload_delete', null );
exec ml_add_table_script( 'ml_qa_3', 'ml_qa_global_props_client', 'download_delete_cursor', null );
exec ml_add_table_script( 'ml_qa_3', 'ml_qa_global_props_client', 'download_cursor', null );
/

drop procedure ml_qa_stage_status_from_client
/
drop procedure ml_qa_staged_status_for_client
/
drop table ml_qa_repository_staging
/
drop table ml_qa_status_staging
/

drop trigger ml_qa_delivery_trigger
/
drop procedure ml_qa_add_delivery
/
drop procedure ml_qa_add_message
/
drop procedure ml_qa_handle_error
/
drop procedure ml_qa_upsert_global_prop
/
drop function ml_qa_get_message_prop
/
drop function ml_qa_get_agent_prop
/
drop function ml_qa_get_agent_network_prop
/
drop function ml_qa_get_agent_object_prop
/

drop view ml_qa_messages
/
drop view ml_qa_messages_archive
/

drop table ml_qa_global_props
/
drop table ml_qa_delivery
/
drop table ml_qa_status_history
/
drop table ml_qa_repository_props
/
drop table ml_qa_repository
/
drop table ml_qa_notifications
/
drop table ml_qa_clients
/

drop table ml_qa_delivery_archive
/
drop table ml_qa_status_history_archive
/
drop table ml_qa_repository_props_archive
/
drop table ml_qa_repository_archive
/

delete from ml_script_version where name = 'ml_qa_3'
/

commit
/

quit
/
