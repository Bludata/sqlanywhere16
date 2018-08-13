
--
-- Create the MobiLink Server system tables and stored procedures in
-- an SAP HANA consolidated database.
--


create table ml_ldap_server (
    ldsrv_id		integer		not null,
    ldsrv_name		varchar( 128 )	not null unique,
    search_url		varchar( 1024 )	not null,
    access_dn		varchar( 1024 )	not null,
    access_dn_pwd	varchar( 256 )	not null,
    auth_url		varchar( 1024 )	not null,
    num_retries		tinyint		not null default 3,
    timeout		integer		not null default 10,
    start_tls		tinyint		not null default 0,
    primary key ( ldsrv_id ) )
;

create sequence ml_ldap_server_sequence
    increment by 1 start with 1 minvalue 1 no maxvalue cycle
;

create table ml_trusted_certificates_file (
    file_name		varchar( 1024 ) not null ) 
;

create table ml_user_auth_policy (
    policy_id			integer		not null,
    policy_name			varchar( 128 )	not null unique,
    primary_ldsrv_id		integer		not null,
    secondary_ldsrv_id		integer		null,
    ldap_auto_failback_period	integer		not null default 900,
    ldap_failover_to_std	tinyint		not null default 1,
    primary key( policy_id ) ) 
;

create sequence ml_user_auth_policy_sequence
    increment by 1 start with 1 minvalue 1 no maxvalue cycle
;

create table ml_user (
    user_id		integer		not null,
    name		varchar( 128 )	not null unique,
    hashed_password	binary( 32 )	null,
    policy_id		integer		null,
    user_dn		varchar( 1024 )	null,
    primary key( user_id ) ) 
;

create sequence ml_user_sequence
    increment by 1 start with 1 minvalue 1 no maxvalue cycle
;

create table ml_database (
    rid			integer		not null,
    remote_id		varchar( 128 )	not null unique,
    script_ldt		timestamp	not null default '1900/01/01 00:00:00',
    seq_id		binary( 16 )	null,
    seq_uploaded	integer		not null default 0,
    sync_key		varchar( 40 ),
    description		varchar( 128 ),
    primary key( rid ) )
;

create sequence ml_database_sequence
    increment by 1 start with 1 minvalue 1 no maxvalue cycle
;

create table ml_subscription (
    rid			integer		not null,
    subscription_id	varchar( 128 )	not null default '<unknown>',
    user_id		integer		not null,
    progress		numeric( 20 )	not null default 0,
    publication_name	varchar( 128 )	not null default '<unknown>',
    last_upload_time	timestamp	not null default '1900/01/01 00:00:00',
    last_download_time	timestamp	not null default '1900/01/01 00:00:00',
    primary key( rid, subscription_id ) )
;

create table ml_table (
    table_id	    integer		not null,
    name	    varchar( 128 )     	not null unique,
    primary key( table_id ) )
;

create sequence ml_table_sequence
    increment by 1 start with 1 minvalue 1 no maxvalue cycle
;

create table ml_script (
    script_id		integer		not null,
    script		clob		not null,
    script_language	varchar( 128 )	not null default 'sql',
    checksum		varchar( 64 )	null,
    primary key( script_id ) )
;

create sequence ml_script_sequence
    increment by 1 start with 1 minvalue 1 no maxvalue cycle
;

create table ml_script_version (
    version_id		integer		not null,
    name		varchar( 128 )	not null unique,
    description		clob		null,
    primary key( version_id ) )
;

create sequence ml_script_version_sequence
    increment by 1 start with 1 minvalue 1 no maxvalue cycle
;

create table ml_connection_script (
    version_id		integer		not null,
    event		varchar( 128 )	not null,
    script_id		integer		not null,
    primary key( version_id, event ) )
;

create table ml_table_script (
    version_id		integer		not null,
    table_id		integer		not null,
    event		varchar( 128 )	not null,
    script_id		integer		not null,
    primary key( version_id, table_id, event ) )
;

create table ml_property (
    component_name	varchar( 128 )	not null,
    property_set_name	varchar( 128 )	not null,
    property_name	varchar( 128 )	not null,
    property_value	clob		not null,
    primary key( component_name, property_set_name, property_name ) )
;

create table ml_scripts_modified (
    last_modified	timestamp	not null primary key )
;

delete from ml_scripts_modified
;
    
insert into ml_scripts_modified ( last_modified ) values ( CURRENT_TIMESTAMP );
;

commit
;

create table ml_column (
    version_id	integer		not null,
    table_id	integer		not null,
    idx		integer		not null,
    name	varchar( 128 )	not null,
    type	varchar( 128 )	null,
    primary key( idx, version_id, table_id ),
    unique( version_id, table_id, name ) )
;
				
create column table ml_primary_server (
    server_id		integer		not null,
    name		varchar( 128 )	not null unique,
    connection_info	varchar( 2048 )	not null,
    instance_key	binary( 32 )	not null,
    start_time		timestamp	not null generated always as ( now() ),
    primary key( server_id ) )
;

create sequence ml_primary_server_sequence
    increment by 1 start with 1 minvalue 1 no maxvalue cycle
;

create table ml_passthrough_script (
    script_id			integer		not null,
    script_name			varchar( 128 )	not null unique,
    flags			varchar( 256 )	null,
    affected_pubs		clob		null,
    script			clob		not null,
    description 		varchar( 2000 )	null,
    primary key( script_id ) )
;

create sequence ml_passthrough_script_sequence
    increment by 1 start with 1 minvalue 1 no maxvalue cycle
;

create column table ml_passthrough (
    remote_id			varchar( 128 )	not null,
    run_order			integer		not null,
    script_id			integer		not null,
    last_modified 		timestamp	not null generated always as ( now() ),
    primary key( remote_id, run_order ) )
;

create table ml_passthrough_status (
    status_id			integer		not null,
    remote_id			varchar( 128 )	not null,
    run_order			integer		not null,
    script_id			integer		not null,
    script_status		char( 1 )	not null,
    error_code			integer		null,
    error_text			clob		null,
    remote_run_time		timestamp	not null,
    primary key( status_id ),
    unique( remote_id, run_order, remote_run_time ) )
;

create sequence ml_passthrough_status_sequence
    increment by 1 start with 1 minvalue 1 no maxvalue cycle
;

create table ml_passthrough_repair (
    failed_script_id		integer		not null,
    error_code			integer		not null,
    new_script_id		integer		null,
    action			char( 1 )	not null,
    primary key( failed_script_id, error_code ) )
;

create view ml_connection_scripts
as
    select ml_script_version.name version,
	   ml_connection_script.event,
	   ml_script.script_language,
	   ml_script.script
	from ml_connection_script,
	     ml_script_version,
	     ml_script
	where ml_connection_script.version_id = ml_script_version.version_id and
	      ml_connection_script.script_id = ml_script.script_id
;
	   
create view ml_table_scripts
as
    select ml_script_version.name version,
	   ml_table_script.event,
	   ml_table.name table_name,
	   ml_script.script_language,
	   ml_script.script
	from ml_table_script,
	     ml_script_version,
	     ml_script,
	     ml_table
	where ml_table_script.version_id = ml_script_version.version_id and
	      ml_table_script.script_id = ml_script.script_id and
	      ml_table_script.table_id = ml_table.table_id
;

create view ml_columns
as
    select ml_script_version.name version,
	  ml_table.name table_name,
	  ml_column.name column_name,
	  ml_column.type data_type,
	  ml_column.idx column_order
	from ml_script_version,
	     ml_table,
	     ml_column
	where ml_column.version_id = ml_script_version.version_id and
	      ml_column.table_id = ml_table.table_id
;

create procedure ml_delete_remote_id(
    in v_remote_id	varchar( 128 ) )
language sqlscript as
    v_rid	int;
    v_cnt	int;
begin
    select count(*) into v_cnt from ml_database where remote_id = :v_remote_id;
    if :v_cnt > 0 then
	select rid into v_rid from ml_database where remote_id = :v_remote_id;
	delete from ml_subscription where rid = :v_rid;
	delete from ml_passthrough_status where remote_id = :v_remote_id;
	delete from ml_passthrough where remote_id = :v_remote_id;
	delete from ml_database where rid = :v_rid;
    end if;
end
;

create procedure ml_delete_user_state(
    in p_user		varchar( 128 ) )
language sqlscript as
    v_uid	integer;
    v_rid	integer;
    v_uid_cnt	integer;
    v_rid_cnt	integer;
    v_remote_id	varchar( 128 );
    cursor remotes( v_uid int ) for
	select rid from ml_subscription where user_id = :v_uid;
begin
    select count(*) into v_uid_cnt from ml_user where name = :p_user;
    if :v_uid_cnt > 0 then
	select user_id into v_uid from ml_user where name = :p_user;
	open remotes( :v_uid );
	if not remotes::ISCLOSED then
	    while 1 = 1 do
		fetch remotes into v_rid;
		if remotes::NOTFOUND then
		    break;
		end if;
		delete from ml_subscription
		    where user_id = :v_uid and rid = :v_rid;
		select count(*) into v_rid_cnt from ml_subscription
		    where rid = :v_rid;
		if :v_rid_cnt = 0 then
		    select count(*) into v_rid_cnt from ml_database
			where rid = :v_rid;
		    if :v_rid_cnt > 0 then
			select remote_id into v_remote_id from ml_database
			    where rid = :v_rid;
			call ml_delete_remote_id( :v_remote_id );
		    end if;
		end if;
	    end while;
	end if;
	close remotes;
    end if;
end
;

create procedure ml_delete_user(
    in p_user		varchar( 128 ) )
language sqlscript as
begin
    call ml_delete_user_state( :p_user );
    delete from ml_user where name = :p_user;
end
;

create procedure ml_delete_sync_state(
    in p_user		varchar( 128 ),
    in p_remote_id	varchar( 128 ) )
language sqlscript as
    v_uid	integer := 1;
    v_rid	integer := 1;
    v_uid_cnt	integer;
    v_rid_cnt	integer;
    v_sid_cnt	integer;
begin
    select count(*) into v_uid_cnt from ml_user where name = :p_user;
    if :v_uid_cnt > 0 then
	select user_id into v_uid from ml_user where name = :p_user;
    end if;
    select count(*) into v_rid_cnt from ml_database where remote_id = :p_remote_id;
    if :v_rid_cnt > 0 then
	select rid into v_rid from ml_database where remote_id = :p_remote_id;
    end if;
    if :v_uid_cnt > 0 and :v_rid_cnt > 0 then
	delete from ml_subscription where user_id = :v_uid and rid = :v_rid;
	select count(*) into v_sid_cnt from ml_subscription where rid = :v_rid;
	if :v_sid_cnt = 0 then
	    call ml_delete_remote_id( :p_remote_id );
	end if;
    elseif :v_uid_cnt > 0 and :p_remote_id = '' then
	call ml_delete_user_state( :p_user );
    elseif :v_rid_cnt > 0 and :p_user = '' then
	call ml_delete_remote_id( :p_remote_id );
    end if;
end
;

create procedure ml_reset_sync_state(
    in p_user		varchar( 128 ),
    in p_remote_id	varchar( 128 ) )
language sqlscript as
    v_uid	integer := NULL;
    v_rid	integer := NULL;
    v_uid_cnt	integer;
    v_rid_cnt	integer;
begin
    select count(*) into v_uid_cnt from ml_user where name = :p_user;
    if :v_uid_cnt > 0 then
	select user_id into v_uid from ml_user where name = :p_user;
    end if;
    select count(*) into v_rid_cnt from ml_database where remote_id = :p_remote_id;
    if :v_rid_cnt > 0 then
	select rid into v_rid from ml_database where remote_id = :p_remote_id;
    end if;
    if :v_uid_cnt > 0 and :v_rid_cnt > 0 then
	update ml_subscription
	    set progress = 0,
		last_upload_time   = '1900/01/01 00:00:00',
		last_download_time = '1900/01/01 00:00:00'
	    where user_id = :v_uid and rid = :v_rid;
    elseif :v_uid_cnt > 0 and :p_remote_id = '' then
	update ml_subscription
	    set progress = 0,
		last_upload_time   = '1900/01/01 00:00:00',
		last_download_time = '1900/01/01 00:00:00'
	    where user_id = :v_uid;
    elseif :v_rid_cnt > 0 and :p_user = '' then	
	update ml_subscription
	    set progress = 0,
		last_upload_time   = '1900/01/01 00:00:00',
		last_download_time = '1900/01/01 00:00:00'
	    where rid = :v_rid;
    end if;
    if :v_rid_cnt > 0 then	
	update ml_database
	    set sync_key = NULL,
		seq_id = NULL,
		seq_uploaded = 0,
		script_ldt = '1900/01/01 00:00:00'
	    where remote_id = :p_remote_id;
    end if;
end
;

create procedure ml_delete_sync_state_before( in p_ts timestamp )
language sqlscript as
    v_rid	integer;
    v_cnt	integer;
    v_remote_id	varchar( 128 );
    cursor remotes( p_ts timestamp ) for
	select rid from ml_subscription
	    where last_upload_time < :p_ts and last_download_time < :p_ts;
begin
    if :p_ts is not null and :p_ts <> '' then
	open remotes( :p_ts );
	if not remotes::ISCLOSED then
	    while 1 = 1 do
		fetch remotes into v_rid;
		if remotes::NOTFOUND then
		    break;
		end if;
		delete from ml_subscription
		    where rid = :v_rid and
			  last_upload_time < :p_ts and
			  last_download_time < :p_ts;
		select count(*) into v_cnt from ml_subscription
		    where rid = :v_rid;
		if :v_cnt = 0 then
		    select count(*) into v_cnt from ml_database
			where rid = :v_rid;
		    if :v_cnt > 0 then
			select remote_id into v_remote_id from ml_database
			    where rid = :v_rid;
			call ml_delete_remote_id( :v_remote_id );
		    end if;
		end if;
	    end while;
	end if;
	close remotes;
    end if;
end
;

create procedure ml_add_lang_table_script_chk( 
    in p_version	varchar( 128 ),
    in p_table		varchar( 128 ),
    in p_event		varchar( 128 ),
    in p_script_language varchar( 128 ),
    in p_script		clob,
    in p_checksum	varchar( 64 ) )
language sqlscript as
    v_version_id	integer := 1;
    v_table_id		integer := 1;
    v_script_id		integer := 1;
    v_version_cnt	integer;
    v_table_cnt		integer;
    v_script_cnt	integer;
    v_upd_cnt		integer;
begin
    select count(*) into v_version_cnt
	from ml_script_version where name = :p_version;
    if :v_version_cnt > 0 then
	select version_id into v_version_id
	    from ml_script_version where name = :p_version;
    else
	select ml_script_version_sequence.nextval into v_version_id
	    from dummy;
    end if;
    select count(*) into v_table_cnt
	from ml_table where name = :p_table;
    if :v_table_cnt > 0 then
	select table_id into v_table_id
	    from ml_table where name = :p_table;
    else
	select ml_table_sequence.nextval into v_table_id
	    from dummy;
    end if;
    if :p_script is not null and :p_script <> '' then
	if :v_version_cnt = 0 then
	    insert into ml_script_version ( version_id, name )
		values ( :v_version_id, :p_version );
	end if;
	if :v_table_cnt = 0 then
	    insert into ml_table ( table_id, name )
		values ( :v_table_id, :p_table );
	end if;
	
	select ml_script_sequence.nextval into v_script_id from dummy;
	
	insert into ml_script ( script_id, script_language, script, checksum )
	    values ( :v_script_id, :p_script_language, :p_script, :p_checksum );
	
	select count(*) into v_upd_cnt from ml_table_script
	    where table_id = :v_table_id and
		version_id = :v_version_id and
		event = :p_event;
		
	if :v_upd_cnt = 0 then
	    insert into ml_table_script ( version_id, table_id, event, script_id ) 
		values ( :v_version_id, :v_table_id, :p_event, :v_script_id );
	else
	    update ml_table_script set script_id = :v_script_id
		where table_id = :v_table_id and
		    version_id = :v_version_id and
		    event = :p_event;
	end if;
    else
	delete from ml_table_script
	    where version_id = :v_version_id and
		table_id = :v_table_id and
		event = :p_event;
    end if;
    update ml_scripts_modified set last_modified = now();
end
;

create procedure ml_add_lang_table_script(
    in p_version	varchar( 128 ),
    in p_table		varchar( 128 ),
    in p_event		varchar( 128 ),
    in p_script_language varchar( 128 ),
    in p_script		clob )
language sqlscript as
begin
    call ml_add_lang_table_script_chk( :p_version, :p_table, :p_event, :p_script_language, :p_script, '' );
end
;

create procedure ml_add_table_script( 
    in p_version	varchar( 128 ),
    in p_table		varchar( 128 ),
    in p_event		varchar( 128 ),
    in p_script		clob )
language sqlscript as
begin
    call ml_add_lang_table_script( :p_version, :p_table, :p_event, 'sql', :p_script );
end
;

create procedure ml_add_java_table_script( 
    in p_version	varchar( 128 ),
    in p_table		varchar( 128 ),
    in p_event		varchar( 128 ),
    in p_script		clob )
language sqlscript as
begin
    call ml_add_lang_table_script( :p_version, :p_table, :p_event, 'java', :p_script );
end
;

create procedure ml_add_dnet_table_script( 
    in p_version	varchar( 128 ),
    in p_table		varchar( 128 ),
    in p_event		varchar( 128 ),
    in p_script		clob )
language sqlscript as
begin
    call ml_add_lang_table_script( :p_version, :p_table, :p_event, 'dnet', :p_script );
end
;

create procedure ml_add_lang_conn_script_chk( 
    in p_version	varchar( 128 ),
    in p_event		varchar( 128 ),
    in p_script_language varchar( 128 ),
    in p_script		clob,
    in p_checksum	varchar( 64 ) )
language sqlscript as
    v_version_id	integer := 1;
    v_script_id		integer := 1;
    v_version_cnt	integer;
    v_script_cnt	integer;
    v_upd_cnt		integer;
begin
    select count(*) into v_version_cnt
	from ml_script_version where name = :p_version;
    if :v_version_cnt > 0 then
	select version_id into v_version_id
	    from ml_script_version where name = :p_version;
    else
	select ml_script_version_sequence.nextval into v_version_id
	    from dummy;
    end if;
    if :p_script is not null and :p_script <> '' then
	if :v_version_cnt = 0 then
	    insert into ml_script_version ( version_id, name )
		values ( :v_version_id, :p_version );
	end if;
	
	select ml_script_sequence.nextval into v_script_id from dummy;
	
	insert into ml_script ( script_id, script_language, script, checksum )
	    values ( :v_script_id, :p_script_language, :p_script, :p_checksum );
	    
	select count(*) into v_upd_cnt from ml_connection_script
	    where version_id = :v_version_id and
		event = :p_event;
	if :v_upd_cnt = 0 then
	    insert into ml_connection_script ( version_id, event, script_id )
		values ( :v_version_id, :p_event, :v_script_id );
	else
	    update ml_connection_script set script_id = :v_script_id
		where version_id = :v_version_id and event = :p_event;
	end if;
    else
	delete from ml_connection_script
	    where version_id = :v_version_id and event = :p_event;
    end if;
    update ml_scripts_modified set last_modified = now();
end
;

create procedure ml_add_lang_connection_script(
    in p_version	varchar( 128 ),
    in p_event		varchar( 128 ),
    in p_script_language char( 128 ),
    in p_script		clob )
language sqlscript as
begin
    call ml_add_lang_conn_script_chk( :p_version, :p_event, :p_script_language, :p_script, '' );
end
;

create procedure ml_add_connection_script( 
    in p_version varchar( 128 ),
    in p_event	varchar( 128 ),
    in p_script	clob )
language sqlscript as
begin
    call ml_add_lang_connection_script( :p_version, :p_event, 'sql', :p_script );
end
;

create procedure ml_add_java_connection_script( 
    in p_version varchar( 128 ),
    in p_event	varchar( 128 ),
    in p_script	clob )
language sqlscript as
begin
    call ml_add_lang_connection_script( :p_version, :p_event, 'java', :p_script );
end
;

create procedure ml_add_dnet_connection_script( 
    in p_version varchar( 128 ),
    in p_event	varchar( 128 ),
    in p_script	clob )
language sqlscript as
begin
    call ml_add_lang_connection_script( :p_version, :p_event, 'dnet', :p_script );
end
;

create procedure ml_add_property(
    in p_comp_name	varchar( 128 ),
    in p_prop_set_name	varchar( 128 ),
    in p_prop_name	varchar( 128 ),
    in p_prop_value	varchar( 4000 ) )
language sqlscript as
    v_prop_cnt	integer := 1;
begin
    if :p_prop_value is null or :p_prop_value = '' then
	delete from ml_property
	    where component_name  = :p_comp_name and
		property_set_name = :p_prop_set_name and
		property_name     = :p_prop_name;
    else
	select count(*) into v_prop_cnt from ml_property 
	    where component_name = :p_comp_name and
		property_set_name = :p_prop_set_name and
		property_name = :p_prop_name;
	if :v_prop_cnt = 0 then
	    insert into ml_property
		( component_name, property_set_name, property_name, property_value )
		values ( :p_comp_name, :p_prop_set_name, :p_prop_name, :p_prop_value );
	else
	    update ml_property set property_value = :p_prop_value
		where component_name = :p_comp_name and
		    property_set_name = :p_prop_set_name and
		    property_name = :p_prop_name;
	end if;
    end if;
end
;

create procedure ml_add_column(
    in p_version	varchar( 128 ),
    in p_table		varchar( 128 ),
    in p_column		varchar( 128 ),
    in p_type		varchar( 128 ) )
language sqlscript as
    v_version_id	integer := 1;
    v_table_id		integer := 1;
    v_script_id		integer := 1;
    v_idx		integer := 1;
    v_version_cnt	integer;
    v_table_cnt		integer;
    v_idx_cnt		integer;
begin
    select count(*) into v_version_cnt
	from ml_script_version where name = :p_version;
    if :v_version_cnt > 0 then
	select version_id into v_version_id
	    from ml_script_version where name = :p_version;
    else
	select ml_script_version_sequence.nextval into v_version_id
	    from dummy;
    end if;
    select count(*) into v_table_cnt
	from ml_table where name = :p_table;
    if :v_table_cnt > 0 then
	select table_id into v_table_id
	    from ml_table where name = :p_table;
    else
	select ml_table_sequence.nextval into v_table_id
	    from dummy;
    end if;
    if :p_column is not null and :p_column <> '' then
	if :v_version_cnt = 0 then
	    insert into ml_script_version ( version_id, name )
		values ( :v_version_id, :p_version );
	end if;
	if :v_table_cnt = 0 then
	    insert into ml_table ( table_id, name )
		values ( :v_table_id, :p_table );
	end if;
	
	select count(*) into v_idx_cnt from ml_column
	    where version_id = :v_version_id and
		table_id = :v_table_id;
	if :v_idx_cnt > 0 then
	    select count(*) into v_idx_cnt from ml_column
		where version_id = :v_version_id and
		    table_id = :v_table_id;
	    if :v_idx_cnt > 0 then
		select max( idx ) + 1 into v_idx from ml_column
		    where version_id = :v_version_id and
			table_id = :v_table_id;
	    end if;
	end if;
	insert into ml_column ( version_id, table_id, idx, name, type ) 
	    values ( :v_version_id, :v_table_id, :v_idx, :p_column, :p_type );
    else
	delete from ml_column 
	    where version_id = :v_version_id and table_id = :v_table_id;
    end if;
    update ml_scripts_modified set last_modified = now();
end
;

create procedure ml_share_all_scripts( 
    in p_version	varchar( 128 ),
    in p_other_version	varchar( 128 ) )
language sqlscript as    
    v_version_id	integer;
    v_other_version_id	integer;
    v_version_cnt	integer;
    v_other_cnt		integer;
begin
    select count(*) into v_other_cnt from ml_script_version 
	where name = :p_other_version;
    if :v_other_cnt > 0 then
	select version_id into v_other_version_id from ml_script_version 
	    where name = :p_other_version;
		
	select count(*) into v_version_cnt from ml_script_version
	    where name = :p_version;
	if :v_version_cnt > 0 then
	    select version_id into v_version_id from ml_script_version
		where name = :p_version;
	else 
	    select ml_script_version_sequence.nextval into v_version_id
		from dummy;
	    insert into ml_script_version ( version_id, name )
		    values ( :v_version_id, :p_version );
	end if;

	insert into ml_table_script( version_id, table_id, event, script_id )
	    ( select v_version_id, table_id, event, script_id from ml_table_script 
		where version_id = :v_other_version_id );
	
	insert into ml_connection_script( version_id, event, script_id )
	    ( select v_version_id, event, script_id from ml_connection_script 
		where version_id = :v_other_version_id );
    end if;
end
;

create procedure ml_add_missing_dnld_scripts(
    in p_script_version	varchar( 128 ) )
language sqlscript as    
    v_vid_count		integer;
    v_version_id	integer;
    v_table_id		integer;
    v_count		integer;
    v_count_1		integer;
    v_count_2		integer;
    v_table_name	varchar( 128 );
    v_tid		integer;
    v_first		integer;
    cursor crsr( script_ver varchar( 128 ) ) for
	select t.table_id from ml_table_script t, ml_script_version v
	    where t.version_id = v.version_id and
		  v.name = :script_ver order by 1;
begin
    select count(*) into v_vid_count from ml_script_version
	where name = :p_script_version;
    if :v_vid_count > 0 then
	select version_id into v_version_id from ml_script_version
	    where name = :p_script_version;
	v_first := 1;
	open crsr( :p_script_version );
	if not crsr::ISCLOSED then
	    while 1 = 1 do
		fetch crsr into v_table_id;
		if crsr::NOTFOUND then
		    break;
		end if;
		if :v_first = 1 or :v_table_id <> :v_tid then
		    select count(*) into v_count_1 from ml_table_script
			where version_id = :v_version_id and
			    table_id = :v_table_id and
			    event = 'download_cursor';
		    select count(*) into v_count_2 from ml_table_script
			where version_id = :v_version_id and
			    table_id = :v_table_id and
			    event = 'download_delete_cursor';
		    if :v_count_1 = 0 or :v_count_2 = 0 then
			select name into v_table_name from ml_table where table_id = v_table_id;
			if :v_count_1 = 0 then
				ml_add_table_script( p_script_version, v_table_name,
				    'download_cursor', '--{ml_ignore}' );
			end if;
			if :v_count_2 = 0 then
				ml_add_table_script( p_script_version, v_table_name,
				    'download_delete_cursor', '--{ml_ignore}' );
			end if;
		    end if;
		    v_first := 0;
		    v_tid := v_table_id;
		end if;
	    end while;
	end if;
	close crsr;
    end if;
end
;

-- Create a stored procedure to get the connections
-- that are currently blocking the connections given
-- by @spids for more than p_block_time seconds

create global temporary table ml_blocked_info (
    conn1		int,
    conn2		int,
    blocked_time	int,
    on_table		smallint,
    waiting_for		varchar(1000) )
;

create procedure ml_get_blocked_info (
    in p_spids		varchar(2000),
    in p_block_time	integer )
language sqlscript as
    v_cnt		integer;
    v_sel		varchar(2000);
begin
    select count(*) into v_cnt from m_blocked_transactions
	where seconds_between(blocked_time, now()) > p_block_time;
    if :v_cnt > 0 then
	v_sel := 'insert into ml_blocked_info ' ||
	    'select t1.connection_id, t2.connection_id, ' ||
	        'seconds_between(b.blocked_time, now()), 1, ' ||
		'waiting_table_name ' ||
	    'from m_blocked_transactions b, m_transactions t1, m_transactions t2 ' ||
	    'where b.blocked_transaction_id = t1.transaction_id and ' ||
		  'b.lock_owner_transaction_id = t2.transaction_id and ' ||
		  'seconds_between( b.blocked_time, now() ) > ' || to_char( p_block_time ) || ' and ' ||
		  'to_char(t1.connection_id) in ( ' || p_spids || ' )';
	exec :v_sel;
	select conn1, conn2, blocked_time, on_table, waiting_for from ml_blocked_info;
    end if;
end;

create procedure ml_add_ldap_server ( 
    in p_ldsrv_name	varchar( 128 ),
    in p_search_url    	varchar( 1024 ),
    in p_access_dn    	varchar( 1024 ),
    in p_access_dn_pwd	varchar( 256 ),
    in p_auth_url	varchar( 1024 ),
    in p_conn_retries	smallint,
    in p_conn_timeout	smallint,
    in p_start_tls	smallint ) 
language sqlscript as
    v_sh_url	varchar( 1024 );
    v_as_dn	varchar( 1024 );
    v_as_pwd	varchar( 256 );
    v_au_url	varchar( 1024 );
    v_timeout	tinyint;
    v_retries	tinyint;
    v_tls	tinyint;
    v_count	integer;
    v_ldsrv_id	integer;
    v_error	integer;
begin
    if :p_ldsrv_name is not null and :p_ldsrv_name <> '' then
	if ( :p_search_url is null or :p_search_url = '' ) and
	   ( :p_access_dn is null or :p_access_dn = '' ) and
	   ( :p_access_dn_pwd is null or :p_access_dn_pwd = '' ) and
	   ( :p_auth_url is null or :p_auth_url = '' ) and
	   ( :p_conn_timeout is null or :p_conn_timeout < 0 ) and
	   ( :p_conn_retries is null or :p_conn_retries < 0 ) and
	   ( :p_start_tls is null or :p_start_tls < 0 ) then
	    
	    -- delete the server if it is not used
	    select count(*) into v_count
		from ml_ldap_server s, ml_user_auth_policy p
		where ( s.ldsrv_id = p.primary_ldsrv_id or
			s.ldsrv_id = p.secondary_ldsrv_id ) and
			s.ldsrv_name = :p_ldsrv_name;
	    if :v_count = 0 then
		delete from ml_ldap_server where ldsrv_name = :p_ldsrv_name; 
	    end if;
	else
	    select count(*) into v_count from ml_ldap_server
		where ldsrv_name = :p_ldsrv_name;
	    if :v_count = 0 then
		if( :p_search_url is null or :p_search_url = '' ) or
		  ( :p_access_dn is null or :p_access_dn = '' ) or
		  ( :p_access_dn_pwd is null or :p_access_dn_pwd = '' ) or
		  ( :p_auth_url is null or :p_auth_url = '' ) then
		    -- error
		    v_error := 1;
		else
		    -- add a new ldap server
		    if :p_conn_timeout is null or :p_conn_timeout < 0 then
			v_timeout := 10;
		    else
			v_timeout := :p_conn_timeout;
		    end if;
		    if :p_conn_retries is null or :p_conn_retries < 0 then
			v_retries := 3;
		    else
			v_retries := :p_conn_retries;
		    end if;
		    if :p_start_tls is null or :p_start_tls < 0 then
			v_tls := 0;
		    else
			v_tls := :p_start_tls;
		    end if;
		    
		    insert into ml_ldap_server ( ldsrv_id, ldsrv_name,
			    search_url, access_dn, access_dn_pwd, auth_url,
			    timeout, num_retries, start_tls )
			values( ml_ldap_server_sequence.nextval,
				:p_ldsrv_name, :p_search_url,
				:p_access_dn, :p_access_dn_pwd,
				:p_auth_url, :v_timeout, :v_retries, :v_tls );
		end if;
	    else
		-- update the ldap server info
		select search_url, access_dn, access_dn_pwd,
			auth_url, timeout, num_retries, start_tls
			into
			v_sh_url, v_as_dn, v_as_pwd,
			v_au_url, v_timeout, v_retries, v_tls
		    from ml_ldap_server where ldsrv_name = :p_ldsrv_name;
		    
		if :p_search_url is not null and :p_search_url <> '' then
		    v_sh_url := :p_search_url;
		end if;
		if :p_access_dn is not null and :p_access_dn <> '' then
		    v_as_dn := :p_access_dn;
		end if;
		if :p_access_dn_pwd is not null and :p_access_dn_pwd <> '' then
		    v_as_pwd := :p_access_dn_pwd;
		end if;
		if :p_auth_url is not null and :p_auth_url <> '' then
		    v_au_url := :p_auth_url;
		end if;
		if :p_conn_timeout is not null and :p_conn_timeout >= 0 then
		    v_timeout := :p_conn_timeout;
		end if;
		if :p_conn_retries is not null and :p_conn_retries >= 0 then
		    v_retries := :p_conn_retries;
		end if;
		if :p_start_tls is not null and :p_start_tls >= 0 then
		    v_tls := :p_start_tls;
		end if;
		    
		update ml_ldap_server set
			search_url = :v_sh_url,
			access_dn = :v_as_dn,
			access_dn_pwd = :v_as_pwd,
			auth_url = :v_au_url,
			timeout = :v_timeout,
			num_retries = :v_retries,
			start_tls = :v_tls
		where ldsrv_name = :p_ldsrv_name;
	    end if;
	end if;
    end if;
end
;

create procedure ml_add_certificates_file (
    in p_file_name	varchar( 128 ) )
language sqlscript as
begin
    if :p_file_name is not null and :p_file_name <> '' then
	delete from ml_trusted_certificates_file;
	insert into ml_trusted_certificates_file
	    ( file_name ) values( :p_file_name );
    end if;
end
;

create procedure ml_add_user_auth_policy (
    in p_policy_name		varchar( 128 ),
    in p_primary_ldsrv_name	varchar( 128 ),
    in p_secondary_ldsrv_name	varchar( 128 ),
    in p_ldap_auto_failback_period integer,
    in p_ldap_failover_to_std	integer )
language sqlscript as
    v_pldsrv_id	integer := null;
    v_sldsrv_id	integer := null;
    v_pid	integer;
    v_sid	integer;
    v_period	integer;
    v_failover	integer;
    v_count	integer;
begin sequential execution
    declare my_cond condition for SQL_ERROR_CODE 10001;
    declare exit handler for my_cond
	select ::SQL_ERROR_CODE, ::SQL_ERROR_MESSAGE from dummy;
    
    if :p_policy_name is not null and :p_policy_name <> '' then
	if ( :p_primary_ldsrv_name is null or :p_primary_ldsrv_name = '' ) and 
	   ( :p_secondary_ldsrv_name is null or :p_secondary_ldsrv_name = '' ) and 
	   ( :p_ldap_auto_failback_period is null or :p_ldap_auto_failback_period < 0 ) and 
	   ( :p_ldap_failover_to_std is null or :p_ldap_failover_to_std < 0 ) then
	    
	    -- delete the policy name if not used
	    select count(*) into v_count from ml_user u, ml_user_auth_policy p
		where u.policy_id = p.policy_id and
		      p.policy_name = :p_policy_name;
	    if :v_count = 0 then
		delete from ml_user_auth_policy
		    where policy_name = :p_policy_name;
	    end if;
	elseif :p_primary_ldsrv_name is null or :p_primary_ldsrv_name = '' then
	    -- error
	    signal my_cond set MESSAGE_TEXT = 'The primary LDAP server cannot be NULL or a zero-length string.';
	else
	    if :p_primary_ldsrv_name is not null and
	       :p_primary_ldsrv_name <> '' then
		select count(*) into v_count from ml_ldap_server
		    where ldsrv_name = :p_primary_ldsrv_name;
		if :v_count > 0 then
		    select ldsrv_id into v_pldsrv_id from ml_ldap_server
			where ldsrv_name = :p_primary_ldsrv_name;
		else
		    signal my_cond set MESSAGE_TEXT = 'The specified primary LDAP server is not defined.';
		end if;
	    end if;
	    if :p_secondary_ldsrv_name is not null and
	       :p_secondary_ldsrv_name <> '' then
		select count(*) into v_count from ml_ldap_server
		    where ldsrv_name = :p_secondary_ldsrv_name;
		if v_count > 0 then
		    select ldsrv_id into v_sldsrv_id from ml_ldap_server
			where ldsrv_name = :p_secondary_ldsrv_name;
		else
		    signal my_cond set MESSAGE_TEXT = 'The specified secondary LDAP server is not defined.';
		end if;
	    end if;
	    select count(*) into v_count from ml_user_auth_policy
		where policy_name = :p_policy_name;
	    if :v_count = 0 then
		if :p_ldap_auto_failback_period is null or
		   :p_ldap_auto_failback_period < 0 then
		    v_period := 900;
		else
		    v_period := :p_ldap_auto_failback_period;
		end if;
		if :p_ldap_failover_to_std is null or
		   :p_ldap_failover_to_std < 0 then
		    v_failover := 1;
		else
		    v_failover := :p_ldap_failover_to_std;
		end if;
		
		-- add a new user auth policy
		insert into ml_user_auth_policy
		    ( policy_id, policy_name, primary_ldsrv_id,
		      secondary_ldsrv_id, ldap_auto_failback_period,
		      ldap_failover_to_std )
		    values( ml_user_auth_policy_sequence.nextval,
			    :p_policy_name, :v_pldsrv_id, :v_sldsrv_id,
			    :v_period, :v_failover );
	    else
		select primary_ldsrv_id, secondary_ldsrv_id,
			ldap_auto_failback_period, ldap_failover_to_std
			into
			v_pid, v_sid, v_period, v_failover
		    from ml_user_auth_policy where policy_name = :p_policy_name;

		if :v_pldsrv_id is not null then
		    v_pid := :v_pldsrv_id;
		end if;
		if :v_sldsrv_id is not null then
		    v_sid := :v_sldsrv_id;
		end if;
		if :p_ldap_auto_failback_period is not null and
		   :p_ldap_auto_failback_period >= 0 then
		    v_period := :p_ldap_auto_failback_period;
		end if;
		if :p_ldap_failover_to_std is not null and
		   :p_ldap_failover_to_std > 0 then
		    v_failover := :p_ldap_failover_to_std;
		end if;

		-- update the user auth policy
		update ml_user_auth_policy set
			    primary_ldsrv_id = :v_pid,
			    secondary_ldsrv_id = :v_sid,
			    ldap_auto_failback_period = :v_period,
			    ldap_failover_to_std = :v_failover
		    where policy_name = :p_policy_name;
	    end if;
	end if;
    end if;
end
;

create procedure ml_add_user(
    in p_user		varchar( 128 ),
    in p_password	binary( 32 ),
    in p_policy_name	varchar( 128 ) )
language sqlscript as
    v_user_id		integer := 1;
    v_policy_id		integer := NULL;
    v_user_cnt		integer;
    v_policy_cnt	integer;
begin sequential execution
    declare my_cond condition for SQL_ERROR_CODE 10001;
    declare exit handler for my_cond
	select ::SQL_ERROR_CODE, ::SQL_ERROR_MESSAGE from dummy;
    
    if :p_user is not null then
	if :p_policy_name is not null and :p_policy_name <> '' then
	    select count(*) into v_policy_cnt from ml_user_auth_policy
		where policy_name = :p_policy_name;
	    if :v_policy_cnt > 0 then
		select policy_id into v_policy_id from ml_user_auth_policy
		    where policy_name = :p_policy_name;
	    else
		signal my_cond set MESSAGE_TEXT =
		    'Unable to find the specified user authentication policy';
	    end if;
	end if;
	select count(*) into v_user_cnt from ml_user
	    where name = :p_user;
	if :v_user_cnt > 0 then
	    select user_id into v_user_id from ml_user
		where name = :p_user;
	else
	    select ml_user_sequence.nextval into v_user_id from dummy;
	end if;
	if :v_user_cnt = 0 then
	    insert into ml_user ( user_id, name, hashed_password, policy_id )
		values ( :v_user_id, :p_user, :p_password, :v_policy_id );
	else
	    update ml_user set hashed_password = :p_password,
				policy_id = :v_policy_id
		where user_id = :v_user_id;
	end if;
    end if;
end
;

create procedure ml_add_database(
    in p_name		varchar( 128 ) )
language sqlscript as
begin
    if :p_name is not null or :p_name <> '' then
	insert into ml_database ( rid, remote_id )
		values ( ml_database_sequence.nextval, :p_name );
    end if;
end
;

create procedure ml_add_primary_server(
    in p_name		varchar( 128 ),
    in p_inst_key	binary( 32 ),
    in p_conn_info	varchar( 2048 ) )
language sqlscript as
begin
    if :p_name is not null and :p_name <> '' then
	insert into ml_primary_server ( server_id, name, instance_key,
					connection_info )
	    values ( ml_primary_server_sequence.nextval,
		     :p_name, :p_inst_key, :p_conn_info );
    end if;
end
;

------------------------------------------------------------------------------
-- Server Initiated Synchronization Schema and Logic
------------------------------------------------------------------------------

create table ml_device (
    device_name		varchar( 255 )	not null primary key,
    listener_version	varchar( 128 )	not null,
    listener_protocol	integer		not null,
    info		varchar( 255 )	not null,
    ignore_tracking	varchar( 1 )	not null,
    source		varchar( 255 )	not null )
;

create column table ml_device_address (
    device_name		varchar( 255 )	not null,
    medium		varchar( 255 )	not null,
    address		varchar( 255 )	not null,
    active		varchar( 1 )	not null,
    last_modified	timestamp	not null generated always as ( now() ),
    ignore_tracking	varchar( 1 )	not null,
    source		varchar( 255 )	not null,
    primary key( device_name, medium ) )
;

create table ml_listening (
    name		varchar( 128 )	not null primary key,
    device_name		varchar( 255 )	not null,
    listening		varchar( 1 )	not null,
    ignore_tracking	varchar( 1 )	not null,
    source		varchar( 255 )	not null )
;

create table ml_sis_sync_state (
    remote_id		varchar( 128 )	not null,
    subscription_id	varchar( 128 )	not null,
    publication_name	varchar( 128 )	not null,
    user_name		varchar( 128 )	not null,
    last_upload		timestamp	not null,
    last_download	timestamp	not null,
    primary key( remote_id, subscription_id ) )
;

create procedure ml_set_device(
    in p_device			varchar( 255 ),
    in p_listener_version	varchar( 128 ),
    in p_listener_protocol	integer,
    in p_info			varchar( 255 ),
    in p_ignore_tracking	varchar( 1 ),
    in p_source			varchar( 255 ) )
language sqlscript as
    cnt int;
begin
    select count(*) into cnt from ml_device where device_name = :p_device;
    if :cnt = 0 then
	insert into ml_device( device_name, listener_version, listener_protocol, info, ignore_tracking, source )
	    values( :p_device, :p_listener_version, :p_listener_protocol, :p_info, :p_ignore_tracking, :p_source );
    elseif :p_source = 'tracking' then
	update ml_device 
	    set listener_version = :p_listener_version,
		listener_protocol = :p_listener_protocol,
		info = :p_info,
		ignore_tracking = :p_ignore_tracking,
		source = :p_source
	    where device_name = :p_device and ignore_tracking = 'n';
    else
	update ml_device 
	    set listener_version = :p_listener_version,
		listener_protocol = :p_listener_protocol,
		info = :p_info,
		ignore_tracking = :p_ignore_tracking,
		source = :p_source
	    where device_name = :p_device;
    end if;
end
;

create procedure ml_set_device_address(
    in p_device		varchar( 255 ),
    in p_medium		varchar( 255 ),
    in p_address	varchar( 255 ),
    in p_active		varchar( 1 ),
    in p_ignore_tracking varchar( 1 ),
    in p_source		varchar( 255 ) )
language sqlscript as
    cnt int;
begin
    select count(*) into cnt from ml_device_address
		where device_name = :p_device and medium = :p_medium;
    if :cnt = 0 then
	insert into ml_device_address( device_name, medium, address, active, ignore_tracking, source )
		values( :p_device, :p_medium, :p_address, :p_active, :p_ignore_tracking, :p_source );
    elseif :p_source = 'tracking' then
	update ml_device_address 
	    set address = :p_address,
		active = :p_active,
		ignore_tracking = :p_ignore_tracking,
		source = :p_source
	    where device_name = :p_device and medium = :p_medium and ignore_tracking = 'n';
    else
	update ml_device_address 
	    set address = :p_address,
		active = :p_active,
		ignore_tracking = :p_ignore_tracking,
		source = :p_source
	    where device_name = :p_device and medium = :p_medium;
    end if;
end
;

create procedure ml_upload_update_device_address(
    in p_address	varchar( 255 ),
    in p_active		varchar( 1 ),
    in p_device		varchar( 255 ),
    in p_medium		varchar( 255 ) )
language sqlscript as
begin
    call ml_set_device_address( :p_device, :p_medium, :p_address, :p_active, 'n', 'tracking' );
end
;

create procedure ml_set_listening(
    in p_name		varchar( 128 ),
    in p_device		varchar( 255 ),
    in p_listening	varchar( 1 ),
    in p_ignore_tracking varchar( 1 ),
    in p_source		varchar( 255 ) )
language sqlscript as
    cnt int;
begin
    select count(*) into cnt from ml_listening where name = :p_name;
    if :cnt = 0 then
	insert into ml_listening( name, device_name, listening, ignore_tracking, source )
	    values( :p_name, :p_device, :p_listening, :p_ignore_tracking, :p_source );
    elseif :p_source = 'tracking' then
	update ml_listening
	    set device_name = :p_device,
		listening = :p_listening,
		ignore_tracking = :p_ignore_tracking,
		source = :p_source
	    where name = :p_name and ignore_tracking = 'n';
    else
	update ml_listening
	    set device_name = :p_device,
		listening = :p_listening,
		ignore_tracking = :p_ignore_tracking,
		source = :p_source
	    where name = :p_name;
    end if;
end
;

create procedure ml_set_sis_sync_state(
    in p_remote_id	    varchar( 128 ),
    in p_subscription_id    varchar( 128 ),
    in p_publication_name   varchar( 128 ),
    in p_user_name	    varchar( 128 ),
    in p_last_upload	    timestamp,
    in p_last_download	    timestamp )
language sqlscript as
    cnt int;
    sid varchar( 128 );
    lut timestamp;
begin
    if :p_subscription_id IS NULL then
	sid := 's:' || :p_publication_name;
    else 
	sid := :p_subscription_id;
    end if;
				    
    if :p_last_upload IS NULL then 
	SELECT count(*) into cnt FROM ml_sis_sync_state 
	    WHERE remote_id = :p_remote_id AND subscription_id = sid;
	if :cnt > 0 then
	    SELECT last_upload into lut FROM ml_sis_sync_state 
		WHERE remote_id = :p_remote_id AND subscription_id = sid;
	else
	    lut := '1900-01-01 00:00:00.000';
	end if ;
    else 
	lut := :p_last_upload;
    end if;
												    
    select count(*) into cnt from ml_sis_sync_state 
	where remote_id = :p_remote_id and subscription_id = sid;
    if :cnt > 0 then
	insert into ml_sis_sync_state( remote_id, subscription_id, publication_name, 
					user_name, last_upload, last_download )
	values( :p_remote_id, sid, :p_publication_name, 
		:p_user_name, lut, :p_last_download );
    else
	update ml_sis_sync_state
	    set publication_name = :p_publication_name,
		user_name = :p_user_name,
		last_upload = lut, 
		last_download = :p_last_download
	    where remote_id = :p_remote_id and subscription_id = sid;
    end if;
end
;

create procedure ml_upload_update_listening(
    in p_device		varchar( 255 ),
    in p_listening	varchar( 1 ),
    in p_name		varchar( 128 ) )
language sqlscript as
begin
    call ml_set_listening( :p_name, :p_device, :p_listening, 'n', 'tracking' );
end
;

create procedure ml_delete_device_address(
    in p_device		varchar( 255 ),
    in p_medium		varchar( 255 ) )
language sqlscript as
begin
    delete from ml_device_address where device_name = :p_device and medium = :p_medium;
end
;

create procedure ml_delete_listening( in p_name varchar( 128 ) )
language sqlscript as
begin
    delete from ml_listening where name = :p_name;
end
;

create procedure ml_delete_device( in p_device varchar( 255 ) )
language sqlscript as
begin
    delete from ml_device_address where device_name = :p_device;
    delete from ml_listening where device_name = :p_device;
    delete from ml_device where device_name = :p_device;
end
;

--
-- Out-of-the-box SIS settings
--
call ml_add_property( 'SIS', 'DeviceTracker(Default-DeviceTracker)', 'enable', 'yes' );
call ml_add_property( 'SIS', 'DeviceTracker(Default-DeviceTracker)', 'smtp_gateway', 'Default-SMTP' );
call ml_add_property( 'SIS', 'DeviceTracker(Default-DeviceTracker)', 'udp_gateway', 'Default-UDP' );
call ml_add_property( 'SIS', 'DeviceTracker(Default-DeviceTracker)', 'sync_gateway', 'Default-SYNC' );
call ml_add_property( 'SIS', 'SMTP(Default-SMTP)', 'enable', 'yes' );
call ml_add_property( 'SIS', 'UDP(Default-UDP)', 'enable', 'yes' );
call ml_add_property( 'SIS', 'SYNC(Default-SYNC)', 'enable', 'yes' );
call ml_add_property( 'SIS', 'BESHTTP(BES_HTTP)', 'enable', 'yes' );
call ml_add_property( 'SIS', 'BESHTTP(BES_HTTP)', 'bes', 'localhost' );
call ml_add_property( 'SIS', 'BESHTTP(BES_HTTP)', 'port', '8080' );
call ml_add_property( 'SIS', 'BESHTTP(BES_HTTP)', 'client_port', '4400' );
call ml_add_property( 'SIS', 'Carrier(Rogers)', 'enable', 'yes' );
call ml_add_property( 'SIS', 'Carrier(Rogers)', 'network_provider_id', 'ROGERS' );
call ml_add_property( 'SIS', 'Carrier(Rogers)', 'sms_email_user_prefix', '1' );
call ml_add_property( 'SIS', 'Carrier(Rogers)', 'sms_email_domain', 'pcs.rogers.com' );
call ml_add_property( 'SIS', 'Carrier(Bell Mobility)', 'enable', 'yes' );
call ml_add_property( 'SIS', 'Carrier(Bell Mobility)', 'network_provider_id', 'BELL' );
call ml_add_property( 'SIS', 'Carrier(Bell Mobility)', 'sms_email_domain', 'txt.bellmobility.ca' );
call ml_add_property( 'SIS', 'Carrier(Bell Mobility 1x)', 'enable', 'yes' );
call ml_add_property( 'SIS', 'Carrier(Bell Mobility 1x)', 'network_provider_id', 'CDMA1x:16420:65535' );
call ml_add_property( 'SIS', 'Carrier(Bell Mobility 1x)', 'sms_email_domain', 'txt.bellmobility.ca' );
;

call ml_add_property( 'SIRT', 'RTNotifier(RTNotifier1)', 'enable', 'no' )
;

commit
;
