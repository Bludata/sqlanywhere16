
--
-- Upgrade the MobiLink Server system tables and stored procedures in
-- a MySQL consolidated database.
--


delimiter //

--
-- Add new tables for user authentication using LDAP servers
--
create table ml_ldap_server (
    ldsrv_id		integer		not null auto_increment,
    ldsrv_name		varchar( 128 )	not null unique,
    search_url		varchar( 1024 )	not null,
    access_dn		varchar( 1024 )	not null,
    access_dn_pwd	varchar( 256 )	not null,
    auth_url		varchar( 1024 )	not null,
    num_retries		smallint	default 3,
    timeout		integer		default 10,
    start_tls		smallint	default 0,
    primary key ( ldsrv_id ) ) 
//

create table ml_trusted_certificates_file (
    file_name		varchar( 1024 ) not null ) 
//

create table ml_user_auth_policy (
    policy_id			integer		not null auto_increment,
    policy_name			varchar( 128 )	not null unique,
    primary_ldsrv_id		integer		not null,
    secondary_ldsrv_id		integer		null,
    ldap_auto_failback_period	integer		default 900,
    ldap_failover_to_std	smallint	default 1,
    foreign key( primary_ldsrv_id ) references ml_ldap_server( ldsrv_id ),
    foreign key( secondary_ldsrv_id ) references ml_ldap_server( ldsrv_id ),
    primary key( policy_id ) ) 
//

--
-- Alter the ml_user table to add two new columns
--
alter table ml_user add policy_id integer null
//

alter table ml_user add constraint fk_policy_id foreign key (policy_id)
    references ml_user_auth_policy( policy_id )
// 

alter table ml_user add user_dn varchar( 1024 ) null
// 

--
-- Alter the ml_database table to add two new columns
--
alter table ml_database add seq_id binary(16) null
//

alter table ml_database add seq_uploaded integer default 0 not null
//

--
-- Add new stored procedures for user authentication using LDAP servers
--
create procedure ml_add_ldap_server ( 
    p_ldsrv_name	varchar( 128 ),
    p_search_url    	varchar( 1024 ),
    p_access_dn    	varchar( 1024 ),
    p_access_dn_pwd	varchar( 256 ),
    p_auth_url		varchar( 1024 ),
    p_conn_retries	smallint,
    p_conn_timeout	smallint,
    p_start_tls		smallint ) 
begin
    declare v_sh_url	varchar( 1024 );
    declare v_as_dn	varchar( 1024 );
    declare v_as_pwd	varchar( 256 );
    declare v_au_url	varchar( 1024 );
    declare v_timeout	smallint;
    declare v_retries	smallint;
    declare v_tls	smallint;
    declare v_count	integer;
    declare v_ldsrv_id	integer;
    
    if p_ldsrv_name is not null then
	if p_search_url is null and
	    p_access_dn is null and
	    p_access_dn_pwd is null and
	    p_auth_url is null and
	    p_conn_timeout is null and
	    p_conn_retries is null and
	    p_start_tls is null then
	    
	    -- delete the server if it is not used
	    if not exists ( select * from ml_ldap_server s, ml_user_auth_policy p
		    where ( s.ldsrv_id = p.primary_ldsrv_id or
			    s.ldsrv_id = p.secondary_ldsrv_id ) and
			    s.ldsrv_name = p_ldsrv_name ) then
		delete from ml_ldap_server where ldsrv_name = p_ldsrv_name; 
	    end if;
	else
	    if not exists ( select * from ml_ldap_server
				where ldsrv_name = p_ldsrv_name ) then
		-- add a new ldap server
		if p_conn_timeout is null then
		    set v_timeout = 10;
		else
		    set v_timeout = p_conn_timeout;
		end if;
		if p_conn_retries is null then
		    set v_retries = 3;
		else
		    set v_retries = p_conn_retries;
		end if;
		if p_start_tls is null then
		    set v_tls = 0;
		else
		    set v_tls = p_start_tls;
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
		    set v_sh_url = p_search_url;
		end if;
		if p_access_dn is not null then
		    set v_as_dn = p_access_dn;
		end if;
		if p_access_dn_pwd is not null then
		    set v_as_pwd = p_access_dn_pwd;
		end if;
		if p_auth_url is not null then
		    set v_au_url = p_auth_url;
		end if;
		if p_conn_timeout is not null then
		    set v_timeout = p_conn_timeout;
		end if;
		if p_conn_retries is not null then
		    set v_retries = p_conn_retries;
		end if;
		if p_start_tls is not null then
		    set v_tls = p_start_tls;
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
end
//

create procedure ml_add_certificates_file (
    p_file_name	varchar( 1024 ) )
begin
    if p_file_name is not null then
	delete from ml_trusted_certificates_file;
	insert into ml_trusted_certificates_file ( file_name )
	    values( p_file_name );
    end if;
end
//

create procedure ml_add_user_auth_policy (
    p_policy_name			varchar( 128 ),
    p_primary_ldsrv_name		varchar( 128 ),
    p_secondary_ldsrv_name		varchar( 128 ),
    p_ldap_auto_failback_period	integer,
    p_ldap_failover_to_std		integer )
begin
    declare v_pldsrv_id	integer;
    declare v_sldsrv_id	integer;
    declare v_pid	integer;
    declare v_sid	integer;
    declare v_period	integer;
    declare v_failover	integer;
    declare v_error	integer;
    declare v_msg	varchar( 1024 );
    declare error	integer;
    
    if p_policy_name is not null then
	if p_primary_ldsrv_name is null and 
	    p_secondary_ldsrv_name is null and 
	    p_ldap_auto_failback_period is null and 
	    p_ldap_failover_to_std is null then
	    
	    -- delete the policy name if not used
	    if not exists ( select * from ml_user u, ml_user_auth_policy p
				where u.policy_id = p.policy_id and
				      p.policy_name = p_policy_name ) then
		delete from ml_user_auth_policy
		    where policy_name = p_policy_name;
	    end if;
	elseif p_primary_ldsrv_name is null then
	    -- error
	    set v_msg = 'The primary LDAP server cannot be NULL.';
	    set error = v_msg;
	else
	    set v_error = 0;
	    if p_primary_ldsrv_name is not null then
		select ldsrv_id into v_pldsrv_id from ml_ldap_server
				where ldsrv_name = p_primary_ldsrv_name;
		if v_pldsrv_id is null then
		    set v_error = 1;
		    set v_msg = CONCAT( 'Primary LDAP server "', p_primary_ldsrv_name, '" is not defined.' );
		    set error = v_msg;
		end if;
	    else
		set v_pldsrv_id = null;
	    end if;
	    if p_secondary_ldsrv_name is not null then
		select ldsrv_id into v_sldsrv_id from ml_ldap_server
				where ldsrv_name = p_secondary_ldsrv_name;
		if v_sldsrv_id is null then
		    set v_error = 1;
		    set v_msg = CONCAT( 'Secondary LDAP server "', p_secondary_ldsrv_name, '" is not defined.' );
		    set error = v_msg;
		end if;
	    else
		set v_sldsrv_id = null;
	    end if;
	    if v_error = 0 then
		if not exists ( select * from ml_user_auth_policy
				where policy_name = p_policy_name ) then
		    if p_ldap_auto_failback_period is null then
			set v_period = 900;
		    else
			set v_period = p_ldap_auto_failback_period;
		    end if;
		    if p_ldap_failover_to_std is null then
			set v_failover = 1;
		    else
			set v_failover = p_ldap_failover_to_std;
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
			set v_pid = v_pldsrv_id;
		    end if;
		    if v_sldsrv_id is not null then
			set v_sid = v_sldsrv_id;
		    end if;
		    if p_ldap_auto_failback_period is not null then
			set v_period = p_ldap_auto_failback_period;
		    end if;
		    if p_ldap_failover_to_std is not null then
			set v_failover = p_ldap_failover_to_std;
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
end
//

--
-- Recreate the ml_add_user stored procedure
--
drop procedure ml_add_user
//

create procedure ml_add_user (
    p_user		varchar( 128 ),
    p_password		binary( 32 ),
    p_policy_name	varchar( 128 ) ) 
begin
    declare v_user_id	integer;
    declare v_policy_id	integer;
    declare v_error	integer;
    declare v_msg	varchar( 1024 );
    declare error	integer;
    
    if p_user is not null then
	set v_error = 0;
	if p_policy_name is not null then
	    select policy_id into v_policy_id from ml_user_auth_policy
				where policy_name = p_policy_name;
	    if v_policy_id is null then
		set v_msg = CONCAT( 'Unable to find the user authentication policy: "', p_policy_name, '".' );
		set error = v_msg;
		set v_error = 1;
	    end if;
	else 
	    set v_policy_id = null;
	end if;
	if v_error = 0 then
	    select user_id into v_user_id from ml_user where name = p_user;
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
end
//

--
-- Add a stored procedure for retrieving locking/blocking information
--
-- Create a stored procedure to get the connections
-- that are currently blocking the connections given
-- by p_conn_ids for more than p_block_time seconds

create procedure ml_get_blocked_info (
    p_conn_ids		varchar(2000),
    p_block_time	integer )
begin
    set @sql = concat(
	'select id, ''unknown'', time, 2, info from information_schema.processlist where id in (',
	p_conn_ids,
	') and upper( command ) <> ''SLEEP'' and info is not NULL and time > ',
	p_block_time,
	' order by id' );
    prepare stmt from @sql;
    execute stmt;
    deallocate prepare stmt;
end;
//

--
-- Recreate the ml_reset_sync_state stored procedure
--
drop procedure ml_reset_sync_state
//

create procedure ml_reset_sync_state (
    p_user		varchar( 128 ),
    p_remote_id		varchar( 128 ) )
begin
    declare v_uid	integer;
    declare v_rid	integer;

    select user_id into v_uid from ml_user where name = p_user;
    select rid into v_rid from ml_database where remote_id = p_remote_id;
    
    if p_user is not null and p_remote_id is not null then
	update ml_subscription
	    set progress = 0,
		last_upload_time   = '1900-01-01 00:00:00.000',
		last_download_time = '1900-01-01 00:00:00.000'
	    where user_id = v_uid and rid = v_rid;
    elseif p_user is not null then 
	update ml_subscription
	    set progress = 0,
		last_upload_time   = '1900-01-01 00:00:00.000',
		last_download_time = '1900-01-01 00:00:00.000'
	    where user_id = v_uid;
    elseif p_remote_id is not null then
	update ml_subscription
	    set progress = 0,
		last_upload_time   = '1900-01-01 00:00:00.000',
		last_download_time = '1900-01-01 00:00:00.000'
	    where rid = v_rid;
    end if;
    
    update ml_database
	set sync_key = NULL,
	    seq_id = NULL,
	    seq_uploaded = 0,
	    script_ldt = '1900-01-01 00:00:00.000'
	where remote_id = p_remote_id;
end;
//

--
-- Changes for ML Remote administration
--

alter table ml_ra_task add random_delay_interval integer default 0 not null
//

create procedure ml_share_all_scripts( 
    in p_version	varchar( 128 ),
    in p_other_version	varchar( 128 ) )
begin
    declare v_version_id		integer;
    declare v_other_version_id	integer;
    
    select version_id into v_version_id from ml_script_version 
		where name = p_version;
    select version_id into v_other_version_id from ml_script_version 
		where name = p_other_version;

    if v_version_id is null then
	-- Insert to the ml_script_version table
	select max( version_id )+1 into v_version_id from ml_script_version;
	if v_version_id is null then
	    -- No rows are currently in ml_script_version
	    set v_version_id = 1;
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
//

create procedure ml_ra_ss_download_task2(
    p_taskdb_remote_id		varchar( 128 ) )
begin
    select task_instance_id, task_name, ml_ra_task.schema_name,
	max_number_of_attempts, delay_between_attempts,
	max_running_time, ml_ra_task.flags,
	case dt.state 
	    when 'P' then 'A'
	    when 'CP' then 'C'
	end,
	cond, remote_event, random_delay_interval
    from ml_database task_db
	join ml_ra_agent on ml_ra_agent.taskdb_rid = task_db.rid
	join ml_ra_deployed_task dt on dt.aid = ml_ra_agent.aid
	join ml_ra_task on dt.task_id = ml_ra_task.task_id
    where task_db.remote_id = p_taskdb_remote_id
	and ( dt.state = 'CP' or dt.state = 'P' );
end;
//

/* Updated Script for 12.0.1 */
call ml_share_all_scripts( 'ml_ra_agent_12_1', 'ml_ra_agent_12' )
//
call ml_add_table_script( 'ml_ra_agent_12_1', 'ml_ra_agent_task', 'download_cursor', 
   'call ml_ra_ss_download_task2( {ml s.remote_id} )' )
//


--
-- Add new objects to support deploying synchronization models from Sybase Central
--

create table ml_model_schema (
    schema_type		varchar( 32 )	not null,
    schema_name		varchar( 128 )  not null,
    table_name		varchar( 128 )  not null,
    object_name		varchar( 128 )  not null,
    drop_stmt		varchar( 2000 ) not null,
    checksum		varchar( 64 )   not null,
    db_checksum		varchar( 64 )   null,
    locked		integer		not null,
    primary key( schema_type, schema_name, table_name, object_name ) ) 
//

create table ml_model_schema_use (
    version_id		integer		not null,
    schema_type		varchar( 32 )   not null,
    schema_name		varchar( 128 )  not null,
    table_name		varchar( 128 )  not null,
    object_name		varchar( 128 )  not null,
    checksum		varchar( 64 )   not null,
    primary key( version_id, schema_type, schema_name, table_name, object_name ) ) 
//

create procedure ml_model_begin_check(
    p_version		varchar(128) )
begin
    declare v_version_id integer;

    select version_id into v_version_id from ml_script_version 
	where name = p_version;

    -- If this same script version was previously installed, 
    -- clean-up any meta-data associated with it.
    delete from ml_model_schema_use where version_id = v_version_id;
end;
//

create procedure ml_model_begin_install(
    p_version		varchar(128) )
begin
    declare v_version_id integer;

    select version_id into v_version_id from ml_script_version 
	where name = p_version;

    -- If this same script version was previously installed, 
    -- clean-up any meta-data associated with it.
    delete from ml_column where version_id = v_version_id;
    delete from ml_connection_script where version_id = v_version_id;
    delete from ml_table_script where version_id = v_version_id;
    delete from ml_model_schema_use where version_id = v_version_id;
    delete from ml_script_version where version_id = v_version_id;
end;
//

create function ml_model_get_catalog_checksum(
    p_schema_type	varchar(32),
    p_schema_name	varchar(128),
    p_table_name	varchar(128),
    p_object_name	varchar(128) )
    returns varchar(64)
begin
    return null;
end;
//

create procedure ml_model_register_schema (
    p_schema_type	varchar(32),
    p_schema_name	varchar(128),
    p_table_name	varchar(128),
    p_object_name	varchar(128),
    p_drop_stmt		varchar(4000),
    p_checksum		varchar(64),
    p_locked		integer )
begin
    declare v_db_checksum varchar(64);

    if p_drop_stmt is null then
	select drop_stmt into p_drop_stmt from ml_model_schema 
	    where schema_type = p_schema_type and schema_name = p_schema_name
		and table_name = p_table_name and object_name = p_object_name;
    end if;		

    if p_checksum is null then
	select checksum into p_checksum from ml_model_schema 
	    where schema_type = p_schema_type and schema_name = p_schema_name
		and table_name = p_table_name and object_name = p_object_name;
    end if;		

    if p_locked is null then
	select locked into p_locked from ml_model_schema 
	    where schema_type = p_schema_type and schema_name = p_schema_name
		and table_name = p_table_name and object_name = p_object_name;
    end if;

    set v_db_checksum = ml_model_get_catalog_checksum( p_schema_type, p_schema_name, p_table_name, p_object_name );

    insert into ml_model_schema
	( schema_type, schema_name, table_name, object_name, drop_stmt, checksum, locked )
	values( p_schema_type, p_schema_name, p_table_name, p_object_name, p_drop_stmt, p_checksum, p_locked )
	on duplicate key update drop_stmt = p_drop_stmt, checksum = p_checksum, locked = p_locked;
end;
//

create procedure ml_model_deregister_schema (
    p_schema_type	varchar(32),
    p_schema_name	varchar(128),
    p_table_name	varchar(128),
    p_object_name	varchar(128) )
begin
    if p_schema_type = 'TABLE' then
	delete from ml_model_schema 
	    where schema_type = p_schema_type 
		and schema_name = p_schema_name 
		and table_name = p_table_name;
    else
	delete from ml_model_schema 
	    where schema_type = p_schema_type 
		and schema_name = p_schema_name 
		and table_name = p_table_name
		and object_name = p_object_name;
    end if;	    
end;
//

create procedure ml_model_register_schema_use (
    p_version		varchar(128),
    p_schema_type	varchar(32),
    p_schema_name	varchar(128),
    p_table_name	varchar(128),
    p_object_name	varchar(128),
    p_checksum		varchar(65) )
begin
    declare v_version_id	integer;
	
    select version_id into v_version_id from ml_script_version 
	where name = p_version;

    if v_version_id is null then
	-- Insert to the ml_script_version
	select max( version_id )+1 into v_version_id from ml_script_version;
	if v_version_id is null then
	    -- No rows are currently in ml_script_version
	    set v_version_id = 1;
	end if;
	insert into ml_script_version ( version_id, name )
		values ( v_version_id, p_version );
    end if;

    insert into ml_model_schema_use
	( version_id, schema_type, schema_name, table_name, object_name, checksum )
	values( v_version_id, p_schema_type, p_schema_name, p_table_name, p_object_name, p_checksum )
	on duplicate key update checksum = p_checksum;
end;
//

create procedure ml_model_mark_schema_verified (
    p_version		varchar(128),
    p_schema_type	varchar(32),
    p_schema_name	varchar(128),
    p_table_name	varchar(128),
    p_object_name	varchar(128) )
begin
    declare v_checksum		varchar( 64 );
    declare v_version_id	integer;
    declare v_locked		integer;

    select version_id into v_version_id from ml_script_version 
	where name = p_version;

   select checksum into v_checksum from ml_model_schema
	    where schema_type = p_schema_type and schema_name = p_schema_name 
		and table_name = p_table_name and object_name = p_object_name;

    if @checksum is not null then
	update ml_model_schema_use set checksum = 'IGNORE'
	    where version_id = v_version_id and schema_type = p_schema_type and schema_name = p_schema_name
		and table_name = p_table_name and object_name = p_object_name;
    else
	select checksum into v_checksum from ml_model_schema_use 
		where version_id = v_version_id and schema_type = p_schema_type
		    and schema_name = p_schema_name and table_name = p_table_name
		    and object_name = p_object_name;
	if p_schema_type = 'COLUMN' then
	    set v_locked = 1;
	else
	    set v_locked = 0;
	end if;
	call ml_model_register_schema( p_schema_type, p_schema_name, p_table_name, p_object_name, 
		'-- Not dropped during uninstall', v_checksum, v_locked );
    end if;
end;
//

create function ml_model_get_schema_action (
    p_version		varchar(128),
    p_schema_type	varchar(32),
    p_schema_name	varchar(128),
    p_table_name	varchar(128),
    p_object_name	varchar(128),
    p_upd_mode		varchar(32) )
    returns varchar(32)
begin
    declare v_status		varchar(32);
    declare v_locked		integer;

    select ml_model_check_schema( p_version, p_schema_type, p_schema_name, p_table_name, p_object_name ) into v_status;
    if v_status = 'MISSING' then 
	return 'CREATE';
    elseif v_status = 'UNUSED' or v_status = 'INSTALLED' or p_upd_mode != 'OVERWRITE' or p_schema_type = 'COLUMN' then
	    -- Preserve the existing schema
	    -- Note, 'REPLACE' won't work for columns because the column is likely 
	    --     in an index and the drop will fail.  If the status is 'MISMATCH' 
	    --     then the column will need to be manually altered in the database.
	    return 'SKIP';
    end if;

    if exists ( select locked 
	    from ml_model_schema
	    where schema_type = p_schema_type and schema_name = p_schema_name and table_name = p_table_name 
		and object_name = p_object_name and locked != 0 ) then
	-- The schema is marked as locked, preserve it.
	return 'SKIP';
    end if;

    set v_status = ml_model_check_catalog( p_schema_type, p_schema_name, p_table_name, p_object_name );
    if v_status = 'MISMATCH' then
	-- The schema was modified since ML was deployed, we are careful not to destroy any schema
	-- that was not created by ML
	return 'SKIP';
    end if;

    -- The existing schema doesn't match what is needed so replace it.
    return 'REPLACE';
end;
//

create function ml_model_check_catalog(
    p_schema_type	varchar(32),
    p_schema_name	varchar(128),
    p_table_name	varchar(128),
    p_object_name	varchar(128) ) 
    returns varchar(32)
begin    
    declare v_checksum		varchar(64);
    declare v_orig_db_checksum	varchar(64);
    declare v_db_checksum	varchar(64);
    declare v_count		integer;

    -- Return values
    -- 'UNUSED' - The requested schema isn't referenced by any ML meta-data
    -- 'MISSING' - The requested schema is not installed.
    -- 'MISMATCH' - The current schema doesn't match the ML meta-data
    -- 'UNVERIFIED' - A full schema comparison wasn't done, 
    --                generally we assume the schema is correct in this case
    -- 'INSTALLED' - The required schema is correctly installed.
    set v_count = 0;
    if p_schema_type = 'TABLE' then
	select count(*) into v_count from INFORMATION_SCHEMA.TABLES where TABLE_SCHEMA like p_schema_name and TABLE_NAME like p_table_name;
    elseif p_schema_type = 'TRIGGER' then
	select count(*) into v_count from INFORMATION_SCHEMA.TRIGGERS where TRIGGER_SCHEMA like p_schema_name 
	    and EVENT_OBJECT_TABLE like p_table_name and TRIGGER_NAME like p_object_name;
    elseif p_schema_type = 'INDEX' then
	select count(*) into v_count from INFORMATION_SCHEMA.STATISTICS where INDEX_SCHEMA like p_schema_name 
	    and TABLE_NAME like p_table_name and INDEX_NAME like p_object_name;
    elseif p_schema_type = 'COLUMN' then
	select count(*) into v_count from INFORMATION_SCHEMA.COLUMNS where TABLE_SCHEMA like p_schema_name 
	    and TABLE_NAME like p_table_name and COLUMN_NAME like p_object_name;
    elseif p_schema_type = 'PROCEDURE' then
	select count(*) into v_count from INFORMATION_SCHEMA.ROUTINES where ROUTINE_SCHEMA like p_schema_name 
	    and ROUTINE_NAME like p_object_name;
    end if;

    if v_count != 0 then 
	-- The schema exists
	set v_db_checksum = ml_model_get_catalog_checksum( p_schema_type, p_schema_name, p_table_name, p_object_name );

	select s.checksum, s.db_checksum into v_checksum, v_orig_db_checksum from ml_model_schema s
	where s.schema_type = p_schema_type and s.schema_name = p_schema_name 
	    and s.table_name = p_table_name and s.object_name = p_object_name;

	if v_checksum is null then return 'UNUSED'; end if;
	if v_orig_db_checksum is null or v_db_checksum is null then return 'UNVERIFIED'; end if;
	if v_orig_db_checksum = v_db_checksum then return 'INSTALLED'; end if;
	return 'MISMATCH';
    end if;
	   
    -- The schema does not exist
    return 'MISSING';
end;
//

create function ml_model_check_schema (
    p_version		varchar(128),
    p_schema_type	varchar(32),
    p_schema_name	varchar(128),
    p_table_name	varchar(128),
    p_object_name	varchar(128) )
    returns varchar(32)
begin
    declare v_db_status		varchar(32);
    declare v_status		varchar(32);
    declare v_count		integer;
    -- Return values
    -- 'UNUSED' - The requested schema isn't needed for this version.
    -- 'MISSING' - The required schema is not installed.
    -- 'MISMATCH' - The current schema doesn't match what is needed and must be replaced.
    -- 'UNVERIFIED' - The existing schema must be manually checked to see if it matches what is needed.
    -- 'INSTALLED' - The required schema is correctly installed.

    select case when s.checksum is null then 'MISSING' else
	    case when u.checksum = 'IGNORE' or u.checksum = s.checksum then 'INSTALLED' else 'MISMATCH' end
	end into v_status
    from ml_model_schema_use u
	join ml_script_version v on v.version_id = u.version_id 
	left outer join ml_model_schema s 
	    on s.schema_type = u.schema_type and s.schema_name = u.schema_name 
		and s.table_name = u.table_name and s.object_name = u.object_name
    where v.name = p_version and u.schema_type = p_schema_type 
	and u.table_name = p_table_name and u.object_name = p_object_name;
    if v_status is null then set v_status = 'UNUSED'; end if;

    set v_db_status = ml_model_check_catalog( p_schema_type, p_schema_name, p_table_name, p_object_name );
    if v_db_status = 'MISSING' then return 'MISSING'; end if;
    if v_status = 'UNUSED' or v_status = 'MISMATCH' then return v_status; end if;
    if v_status = 'MISSING' then return 'UNVERIFIED'; end if;

    -- v_status = 'INSTALLED'
    if v_db_status = 'MISMATCH' then return 'MISMATCH'; end if;

    -- If v_db_status = 'UNVERIFIED' we are optimistic and assume it is correct
    return 'INSTALLED';
end;
//

create procedure ml_model_check_all_schema()
begin
    select 
	case when s.schema_name is null then u.schema_name else s.schema_name end schema_name, 
	case when s.table_name is null then u.table_name else s.table_name end table_name, 
	case when s.schema_type is null then u.schema_type else s.schema_type end schema_type, 
	case when s.object_name is null then u.object_name else s.object_name end object_name, 
	s.locked, 
	ver.name used_by,
	ml_model_check_schema( ver.name, 
	    case when s.schema_type is null then u.schema_type else s.schema_type end, 
	    case when s.schema_name is null then u.schema_name else s.schema_name end, 
	    case when s.table_name is null then u.table_name else s.table_name end, 
	    case when s.object_name is null then u.object_name else s.object_name end ) status,
	case when ver.name is null then null else ml_model_get_schema_action( ver.name, u.schema_type, u.schema_name, u.table_name, u.object_name, 'OVERWRITE' ) end overwrite_action,
	case when ver.name is null then null else ml_model_get_schema_action( ver.name, u.schema_type, u.schema_name, u.table_name, u.object_name, 'PRESERVE_EXISTING_SCHEMA' ) end preserve_action
    from ml_model_schema s 
	left outer join ml_model_schema_use u on
	    u.schema_type = s.schema_type and u.schema_name = s.schema_name
	    and u.table_name = s.table_name and u.object_name = s.object_name
	left outer join ml_script_version ver on
	    u.version_id = ver.version_id
    UNION
    select 
	case when s.schema_name is null then u.schema_name else s.schema_name end schema_name, 
	case when s.table_name is null then u.table_name else s.table_name end table_name, 
	case when s.schema_type is null then u.schema_type else s.schema_type end schema_type, 
	case when s.object_name is null then u.object_name else s.object_name end object_name, 
	s.locked, 
	ver.name used_by,
	ml_model_check_schema( ver.name, 
	    case when s.schema_type is null then u.schema_type else s.schema_type end, 
	    case when s.schema_name is null then u.schema_name else s.schema_name end, 
	    case when s.table_name is null then u.table_name else s.table_name end, 
	    case when s.object_name is null then u.object_name else s.object_name end ) status,
	case when ver.name is null then null else ml_model_get_schema_action( ver.name, u.schema_type, u.schema_name, u.table_name, u.object_name, 'OVERWRITE' ) end overwrite_action,
	case when ver.name is null then null else ml_model_get_schema_action( ver.name, u.schema_type, u.schema_name, u.table_name, u.object_name, 'PRESERVE_EXISTING_SCHEMA' ) end preserve_action
    from ml_model_schema s 
	right outer join ml_model_schema_use u on
	    u.schema_type = s.schema_type and u.schema_name = s.schema_name
	    and u.table_name = s.table_name and u.object_name = s.object_name
	left outer join ml_script_version ver on
	    u.version_id = ver.version_id
    order by schema_name, table_name, schema_type, object_name, used_by;
end;
//

create procedure ml_model_check_version_schema(
    p_version		varchar(128) )
begin
    select u.schema_name, u.table_name, u.schema_type, u.object_name, s.locked,
	ml_model_check_schema( ver.name, u.schema_type, u.schema_name, u.table_name, u.object_name ) status,
	ml_model_get_schema_action( ver.name, u.schema_type, u.schema_name, u.table_name, u.object_name, 'OVERWRITE' ) overwrite_action,
	ml_model_get_schema_action( ver.name, u.schema_type, u.schema_name, u.table_name, u.object_name, 'PRESERVE_EXISTING_SCHEMA' ) preserve_action
    from ml_model_schema_use u join ml_script_version ver on u.version_id = ver.version_id
	left outer join ml_model_schema s on
	    u.schema_type = s.schema_type and u.schema_name = s.schema_name
	    and u.table_name = s.table_name and u.object_name = s.object_name
    where ver.name = p_version
    order by u.schema_name, u.table_name, u.schema_type, u.object_name;
end;
//

create procedure ml_model_drop_unused_schema()
begin
    declare v_status	    varchar(32);
    declare v_schema_type   varchar(32);
    declare v_schema_name   varchar(128);
    declare v_object_name   varchar(128);
    declare v_table_name    varchar(128);
    declare v_drop_stmt	    varchar(2000);
    declare v_done	    integer default 0;

    declare drop_crsr cursor for
	select s.schema_type, s.schema_name, s.table_name, s.object_name, s.drop_stmt 
	from ml_model_schema s 
	    left outer join ml_model_schema_use u 
	    on u.schema_type = s.schema_type and u.schema_name = s.schema_name 
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

    declare continue handler for SQLSTATE '02000' set v_done = 1;
    open drop_crsr;
    drop_loop: loop
	fetch drop_crsr into v_schema_type, v_schema_name, v_table_name, v_object_name, v_drop_stmt;
	if v_done then
	    leave drop_loop;
	end if;

	set v_status = ml_model_check_catalog( v_schema_type, v_schema_name, v_table_name, v_object_name );
	-- We don't drop any schema modified since ML was deployed.
	if v_status != 'MISMATCH' and v_status != 'MISSING' then
	    set @drop_stmt := replace( v_drop_stmt, '"', '`' );
	    prepare stmt from @drop_stmt;
	    execute stmt;
	    deallocate prepare stmt;
	end if;
	call ml_model_deregister_schema( v_schema_type, v_schema_name, v_table_name, v_object_name );
    end loop drop_loop;
    close drop_crsr;
end;
//

create procedure ml_model_drop(
    p_version	    varchar(128) )
begin
    declare v_version_id    integer;

    select version_id into v_version_id from ml_script_version 
	where name = p_version;

    delete from ml_model_schema_use where version_id = v_version_id;
    delete from ml_column where version_id = v_version_id;
    delete from ml_connection_script where version_id = v_version_id;
    delete from ml_table_script where version_id = v_version_id;
    delete from ml_script_version where version_id = v_version_id;
    call ml_model_drop_unused_schema();
end;
//

commit
//
