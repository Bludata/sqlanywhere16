
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
--
alter table ml_user add policy_id integer null
//

alter table ml_user add constraint fk_policy_id foreign key (policy_id)
    references ml_user_auth_policy( policy_id )
// 

alter table ml_user add user_dn varchar( 1024 ) null
// 

--
-- Add new columns to the ml_database table
--
alter table ml_database add sync_key varchar(40) null
//

alter table ml_database add seq_id binary(16) null
//

alter table ml_database add seq_uploaded integer default 0 not null
//

drop table ml_active_remote_id
//

drop function ml_server_update
//

drop procedure ml_server_delete
//

drop table ml_server
//

--
-- Add trigger on ml_column table
--
create trigger ml_column_trigger_insert before 
    insert on ml_column for each row
begin
    update ml_scripts_modified set last_modified = sysdate();
end;
//

create trigger ml_column_trigger_update before 
    update on ml_column for each row
begin
    update ml_scripts_modified set last_modified = sysdate();
end;
//

create trigger ml_column_trigger_delete before 
    delete on ml_column for each row
begin
    update ml_scripts_modified set last_modified = sysdate();
end;
//

--
-- Add the ml_primary_server table
--
create table ml_primary_server (
    server_id		integer		not null auto_increment,
    name		varchar( 128 )	not null unique,
    connection_info	varchar( 2048 )	not null,
    instance_key	binary( 32 )	not null,
    start_time		datetime	default '1900-01-01 00:00:00.00000' not null,
    primary key( server_id ) )
//

drop procedure ml_delete_user
//

drop procedure ml_delete_sync_state
//

drop procedure ml_delete_sync_state_before
//

create procedure ml_delete_remote_id(
    p_remote_id		varchar( 128 ) )
begin
    declare v_rid	integer;
    
    select rid into v_rid from ml_database where remote_id = p_remote_id;
    if v_rid is not null then
	delete from ml_subscription where rid = v_rid;
	delete from ml_passthrough_status where remote_id = p_remote_id;
	delete from ml_passthrough where remote_id = p_remote_id;
	delete from ml_database where rid = v_rid;
    end if;
end;
//

create procedure ml_delete_user_state (
    p_user	varchar( 128 ) )
begin
    declare v_uid	integer;
    declare v_rid	integer;
    declare v_remote_id varchar( 128 ) default 0;
    declare done	int default 0;
    declare crsr cursor for select rid from ml_subscription
				    where user_id = v_uid;
    
    select user_id into v_uid from ml_user where name = p_user;
    if v_uid is not null then
	begin
	    declare continue handler for SQLSTATE '02000' set done = 1;
	    open crsr;
	    rid: loop
		fetch crsr into v_rid;
		if not done then
		    delete from ml_subscription where user_id = v_uid and rid = v_rid;
		    if not exists (select * from ml_subscription where rid = v_rid) then
			select remote_id into v_remote_id
			    from ml_database where rid = v_rid;
			call ml_delete_remote_id( v_remote_id );
		    end if;
		else
		    leave rid;
		end if;
	    end loop rid;
	    close crsr;
	end;
    end if;
end;
//

create procedure ml_delete_user(
    p_user		varchar( 128 ) )
begin
    call ml_delete_user_state( p_user );
    delete from ml_user where name = p_user;
end;
//

create procedure ml_delete_sync_state (
    p_user		varchar( 128 ),
    p_remote_id		varchar( 128 ) )
begin
    declare v_uid	integer;
    declare v_rid	integer;
    declare done	int default 0;
    declare crsr cursor for select rid from ml_subscription
				where user_id = v_uid;
    
    select user_id into v_uid from ml_user where name = p_user;
    select rid into v_rid from ml_database where remote_id = p_remote_id;
    
    if p_user is not null and p_remote_id is not null then
	delete from ml_passthrough_status where remote_id = p_remote_id;
	delete from ml_passthrough where remote_id = p_remote_id;
	delete from ml_subscription where user_id = v_uid and rid = v_rid;
	if not exists (select * from ml_subscription where rid = v_rid) then
	    call ml_delete_remote_id( p_remote_id );
	end if;
    elseif p_user is not null then
	call ml_delete_user_state( p_user );
    elseif p_remote_id is not null then
	call ml_delete_remote_id( p_remote_id );
    end if;
end;
//

create procedure ml_delete_sync_state_before( p_ts datetime )
begin
    declare v_rid	integer;
    declare v_rid_prev	integer;
    declare v_remote_id	varchar( 128 );
    declare done	int default 0;
    declare crsr cursor for select rid from ml_subscription
				where last_upload_time < p_ts and
				      last_download_time < p_ts
				order by 1;
    
    if p_ts is not null then
	begin
	    declare continue handler for SQLSTATE '02000' set done = 1;
	    set v_rid_prev = NULL;
	    open crsr;
	    rid: loop
		fetch crsr into v_rid;
		if not done then
		    if v_rid_prev is null or v_rid <> v_rid_prev then
			delete from ml_subscription where rid = v_rid and
							  last_upload_time < p_ts and
							  last_download_time < p_ts;
			if not exists (select * from ml_subscription where rid = v_rid) then
			    select remote_id into v_remote_id from ml_database where rid = v_rid;
			    call ml_delete_remote_id( v_remote_id );
			end if;
			set v_rid_prev = v_rid;
		    end if;
		else
		    leave rid;
		end if;
	    end loop rid;
	    close crsr;
	end;
    end if;
end;
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

create procedure ml_add_missing_dnld_scripts(
    p_script_version	varchar( 128 ) )
begin
    declare v_version_id	integer;
    declare v_table_id		integer;
    declare v_count		integer;
    declare v_count_1		integer;
    declare v_count_2		integer;
    declare v_table_name	varchar(128);
    declare done		integer default 0;
    declare v_tid		integer;
    declare v_first		integer;
    declare crsr cursor for
	    select t.table_id from ml_table_script t, ml_script_version v
		where t.version_id = v.version_id and
		      v.name = p_script_version order by 1;
    
    select version_id into v_version_id from ml_script_version
	where name = p_script_version;
    if v_version_id is not null then
	begin
	    declare continue handler for SQLSTATE '02000' set done = 1;
	    set v_first = 1;
	    open crsr;
	    tid: loop
		fetch crsr into v_table_id;
		if done then 
		    leave tid;
		end if;
		if v_first = 1 or v_table_id <> v_tid then
		    if not exists (select * from ml_table_script
				    where version_id = v_version_id and
					table_id = v_table_id and
					event = 'download_cursor') then
			set v_count_1 = 0;
		    else
			set v_count_1 = 1;
		    end if;
		    if not exists (select * from ml_table_script
				    where version_id = v_version_id and
					table_id = v_table_id and
					event = 'download_delete_cursor') then
			set v_count_2 = 0;
		    else
			set v_count_2 = 1;
		    end if;
		    if v_count_1 = 0 or v_count_2 = 0 then
			select name into v_table_name from ml_table where table_id = v_table_id;
			if v_count_1 = 0 then
			    call ml_add_table_script( p_script_version, v_table_name,
				'download_cursor', '--{ml_ignore}' );
			end if;
			if v_count_2 = 0 then
			    call ml_add_table_script( p_script_version, v_table_name,
				'download_delete_cursor', '--{ml_ignore}' );
			end if;
		    end if;
		    set v_first = 0;
		    set v_tid = v_table_id;
		end if;
	    end loop;
	    close crsr;
	end;
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


-- ------------------------------------------------
--   Schema for ML Remote administration
-- ------------------------------------------------

create table ml_ra_schema_name (
    schema_name                    varchar( 128 ) not null,
    remote_type                    varchar(1) not null,
    last_modified                  datetime not null,
    description		           varchar( 2048 ) null,
    primary key (schema_name) 
)
//

create table ml_ra_agent (
    aid                            integer not null auto_increment,
    agent_id                       varchar( 128 ) not null unique,
    taskdb_rid                     integer null,
    primary key( aid ),
    foreign key( taskdb_rid ) references ml_database ( rid )
)
//
create unique index tdb_rid on ml_ra_agent( taskdb_rid ) 
//

create table ml_ra_task (
    task_id                        bigint not null auto_increment,
    task_name                      varchar( 128 ) not null unique,
    schema_name			   varchar( 128 ) null,
    max_running_time               integer null,
    max_number_of_attempts         integer null,
    delay_between_attempts         integer null,
    flags                          bigint not null,
    cond                           mediumtext null,
    remote_event                   mediumtext null,
    random_delay_interval	   integer not null default 0,
    primary key( task_id ), 
    foreign key( schema_name ) references ml_ra_schema_name( schema_name )
)
//

create table ml_ra_deployed_task (
    task_instance_id               bigint not null auto_increment,
    aid                            integer not null,
    task_id                        bigint not null,
    assignment_time                timestamp not null default current_timestamp,
    state                          varchar( 4 ) not null default 'P',
    previous_exec_count            bigint not null default 0,
    previous_error_count           bigint not null default 0,
    previous_attempt_count         bigint not null default 0,
    reported_exec_count            bigint not null default 0,
    reported_error_count           bigint not null default 0,
    reported_attempt_count         bigint not null default 0,
    last_modified                  datetime not null,
    unique( aid, task_id ),
    primary key( task_instance_id ), 
    foreign key( aid ) references ml_ra_agent( aid ),
    foreign key( task_id ) references ml_ra_task( task_id )
)
//
create index dt_tid_idx on ml_ra_deployed_task( task_id )
//

create table ml_ra_task_command (
    task_id                        bigint not null,
    command_number                 integer not null,
    flags                          bigint not null default 0,
    action_type                    varchar( 4 ) not null,
    action_parm                    mediumtext not null,
    primary key( task_id, command_number ),
    foreign key( task_id ) references ml_ra_task( task_id )
)
//

create table ml_ra_event (
    event_id                       bigint not null auto_increment,
    event_class                    varchar( 4 ) not null,
    event_type                     varchar( 8 ) not null,
    aid				   integer null,
    task_id			   bigint null,
    command_number                 integer null,
    run_number                     bigint null,
    duration                       integer null,
    event_time                     datetime not null,
    event_received                 timestamp not null default current_timestamp,
    result_code                    bigint null,
    result_text                    longtext null,
    primary key (event_id) 
)
//
create index ev_tn_idx on ml_ra_event( task_id )
//
create index ev_time_idx on ml_ra_event( event_received )
//
create index ev_agent_idx on ml_ra_event( aid )
//

create table ml_ra_event_staging (
    taskdb_rid			   integer not null,
    remote_event_id                bigint not null,
    event_class                    varchar( 4 ) not null,
    event_type                     varchar( 8 ) not null,
    task_instance_id               bigint null,
    command_number                 integer null,
    run_number                     bigint null,
    duration                       integer null,
    event_time                     datetime not null,
    result_code                    bigint null,
    result_text                    longtext null,
    primary key( taskdb_rid, remote_event_id ) 
)
//

create index evs_type_idx on ml_ra_event_staging( event_type )
//

create table ml_ra_notify (
    agent_poll_key                 varchar( 128 ) not null,
    task_instance_id               bigint not null,
    last_modified                  datetime not null,
    primary key( agent_poll_key, task_instance_id ),
    foreign key( agent_poll_key ) references ml_ra_agent( agent_id )
)
//

create table ml_ra_task_property (
    task_id                        bigint not null,
    property_name                  varchar( 128 ) not null,
    last_modified                  datetime not null,
    property_value                 mediumtext null,
    primary key( property_name, task_id ), 
    foreign key( task_id ) references ml_ra_task( task_id )
)
//

create table ml_ra_task_command_property (
    task_id                        bigint not null,
    command_number                 integer not null,
    property_name                  varchar( 128 ) not null,
    property_value                 varchar( 2048 ) null,
    last_modified                  datetime not null,
    primary key( task_id, command_number, property_name ), 
    foreign key( task_id, command_number ) references ml_ra_task_command( task_id, command_number )
)
//

create table ml_ra_managed_remote (
    mrid                           integer not null auto_increment,
    remote_id			   varchar(128) null,
    aid                            integer not null,
    schema_name			   varchar( 128 ) not null,
    conn_str		           varchar( 2048 ) not null,
    last_modified                  datetime not null,
    unique( aid, schema_name ),
    primary key( mrid ),
    foreign key( aid ) references ml_ra_agent( aid ),
    foreign key( schema_name ) references ml_ra_schema_name( schema_name )
)
//

create table ml_ra_agent_property (
    aid                            integer not null,
    property_name                  varchar( 128 ) not null,
    property_value                 varchar( 2048 ) null,
    last_modified                  datetime not null,
    primary key( aid, property_name ),
    foreign key( aid ) references ml_ra_agent( aid )
)
//

create table ml_ra_agent_staging (
    taskdb_rid			   integer not null,
    property_name                  varchar( 128 ) not null,
    property_value                 varchar( 2048 ) null,
    primary key( taskdb_rid, property_name ) 
)
//

-- --------------------------------------------------------------
-- Stored procedures for Tasks
-- --------------------------------------------------------------

-- Assign a remote task to a specific agent.

create procedure ml_ra_assign_task (
    p_agent_id		varchar( 128 ),  
    p_task_name		varchar( 128 ) )
begin
    declare v_task_id		bigint;
    declare v_task_instance_id	bigint;
    declare v_old_state		varchar( 4 );
    declare v_aid		integer;
    declare v_rid		integer;
    declare v_error1		integer;
    declare v_error2		integer;

    select task_id into v_task_id
	from ml_ra_task where task_name = p_task_name;
    if v_task_id is null then
	set v_error1 = 'bad task name';
    end if;

    select aid into v_aid from ml_ra_agent where agent_id = p_agent_id;
    if v_aid is null then 
	set v_error2 = 'bad agent id';
    end if;

    select state, task_instance_id into v_old_state, v_task_instance_id
	from ml_ra_deployed_task where task_id = v_task_id and aid = v_aid;
    if v_task_instance_id is null then
	insert into ml_ra_deployed_task( aid, task_id, last_modified ) 
	    values ( v_aid, v_task_id, now() );
    elseif v_old_state != 'A' and v_old_state != 'P' then
	-- Re-activate the task
	update ml_ra_deployed_task 
	    set state = 'P',
	    previous_exec_count = reported_exec_count + previous_exec_count,
	    previous_error_count = reported_error_count + previous_error_count,
	    previous_attempt_count = reported_attempt_count + previous_attempt_count,
	    reported_exec_count = 0,
	    reported_error_count = 0,
	    reported_attempt_count = 0,
	    last_modified = now()
	where task_instance_id = v_task_instance_id;
    end if;
    -- if the task is already active then do nothing 
end;
//

create procedure ml_ra_int_cancel_notification(
    p_agent_id		varchar( 128 ),
    p_task_instance_id	bigint,
    p_request_time	datetime ) 
begin
    delete from ml_ra_notify
	where agent_poll_key = p_agent_id
	    and task_instance_id = p_task_instance_id
	    and last_modified <= p_request_time;
end;
//

create procedure ml_ra_cancel_notification(
    p_agent_id	varchar( 128 ),
    p_task_name	varchar( 128 ) )
begin
    declare v_task_instance_id	bigint;
    declare v_ts		datetime;

    select task_instance_id into v_task_instance_id
	from ml_ra_agent
	    join ml_ra_deployed_task on ml_ra_deployed_task.aid = ml_ra_agent.aid
	    join ml_ra_task on ml_ra_deployed_task.task_id = ml_ra_task.task_id
	where agent_id = p_agent_id and task_name = p_task_name;
	
    set v_ts = now();
    call ml_ra_int_cancel_notification( p_agent_id, v_task_instance_id, v_ts );
end;
//

create procedure ml_ra_cancel_task_instance(
    p_agent_id		varchar( 128 ), 
    p_task_name		varchar( 128 ) )
begin
    declare v_task_instance_id	bigint;
    declare v_task_id	bigint;
    declare v_aid	integer;
    declare v_error1	integer;

    select task_id into v_task_id
	from ml_ra_task where task_name = p_task_name;
    select ml_ra_agent.aid into v_aid
	from ml_ra_agent where agent_id = p_agent_id;
    select task_instance_id into v_task_instance_id from ml_ra_deployed_task dt
	where aid = v_aid and task_id = v_task_id and ( state = 'A' or state = 'P' );
    if v_task_instance_id is null then
	set v_error1 = 'bad task instance';
    end if;
    
    update ml_ra_deployed_task set state = 'CP', last_modified = now()
	where task_instance_id = v_task_instance_id;
    call ml_ra_cancel_notification( p_agent_id, p_task_name );
end;
//

-- If error is raised then caller must rollback

create procedure ml_ra_delete_task(
    p_task_name	varchar( 128 ) )
begin
    declare v_task_id	bigint;
    declare v_error1	integer;

    select task_id into v_task_id from ml_ra_task
	where task_name = p_task_name;
    if v_task_id is null then
	set v_error1 = 'bad task name';
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
//

-- result contains a row for each deployed instance of every task

create procedure ml_ra_get_task_status(
    p_agent_id	varchar( 128 ),
    p_task_name	varchar( 128 ) )
begin
    -- This if statement is a workaround for mysql not respecting
    -- the 'order by' when p_task_name is null.
    if p_task_name is null then
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
		where ml_ra_event.task_id = t.task_id ),
	    dt.assignment_time
	from ml_ra_task t 
	    join ml_ra_deployed_task dt on t.task_id = dt.task_id
	    join ml_ra_agent a on a.aid = dt.aid
	    left outer join ml_ra_managed_remote mr on mr.schema_name = t.schema_name
		and mr.aid = a.aid
	where p_agent_id is null or a.agent_id = p_agent_id
	order by a.agent_id, t.task_name;
    else
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
		where ml_ra_event.task_id = t.task_id ),
	    dt.assignment_time
	from ml_ra_task t 
	    join ml_ra_deployed_task dt on t.task_id = dt.task_id
	    join ml_ra_agent a on a.aid = dt.aid
	    left outer join ml_ra_managed_remote mr on mr.schema_name = t.schema_name
		and mr.aid = a.aid
	where
	    ( p_agent_id is null or a.agent_id = p_agent_id )
	    and t.task_name = p_task_name
	order by a.agent_id;
    end if;
end;
//

create procedure ml_ra_notify_agent_sync(
    p_agent_id	varchar( 128 ) )
begin
    declare v_aid	integer;

    select aid into v_aid from ml_ra_agent where agent_id = p_agent_id;

    main: begin
	if v_aid is null then
	    leave main;
	end if;
	
	insert into ml_ra_notify( agent_poll_key, task_instance_id, last_modified )
	    values( p_agent_id, -1, now() ) on duplicate key
		update last_modified = now();
    end;
end;
//

create procedure ml_ra_notify_task(
    p_agent_id		varchar( 128 ), 
    p_task_name		varchar( 128 ) )
begin
    declare v_cnt		integer;
    declare v_task_instance_id	bigint;

    select task_instance_id into v_task_instance_id
	from ml_ra_agent
	    join ml_ra_deployed_task on ml_ra_deployed_task.aid = ml_ra_agent.aid
	    join ml_ra_task on ml_ra_deployed_task.task_id = ml_ra_task.task_id
	where agent_id = p_agent_id 
	    and task_name = p_task_name;
    
    insert into ml_ra_notify( agent_poll_key, task_instance_id, last_modified )
	values( p_agent_id, v_task_instance_id, now() ) on duplicate key
	    update last_modified = now(); 
end;
//

create function ml_ra_get_latest_event_id()
    returns bigint deterministic
begin
    declare v_event_id	bigint;

    select max( event_id ) into v_event_id from ml_ra_event;
    
    return v_event_id;
end;
//

create procedure ml_ra_get_agent_events(
    p_start_at_event_id		bigint, 
    p_max_events_to_fetch	bigint )
begin
    prepare stmt from 
    'select
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
	event_id >= ?
    order by event_id
    limit ?';

    set @max_to_fetch = p_max_events_to_fetch;
    set @start_at = p_start_at_event_id;
    execute stmt using @start_at, @max_to_fetch;
end;
//

create procedure ml_ra_get_task_results( 
    p_agent_id		varchar( 128 ), 
    p_task_name		varchar( 128 ),
    p_run_number	integer )
begin
    declare v_run_number	integer;
    declare v_aid		integer;
    declare v_remote_id		varchar(128);
    declare v_task_id		bigint;

    select aid into v_aid from ml_ra_agent where agent_id = p_agent_id;
    select task_id, remote_id into v_task_id, v_remote_id from ml_ra_task t
	left outer join ml_ra_managed_remote mr 
	    on mr.schema_name = t.schema_name and mr.aid = v_aid
	where task_name = p_task_name;
    if p_run_number is null then
	-- get the latest run
	select max( run_number ) into v_run_number from ml_ra_event
	    where ml_ra_event.aid = v_aid and
		ml_ra_event.task_id = v_task_id;
    else
	set v_run_number = p_run_number;
    end if;

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
//

-- Maintenance functions ----------------------------------

create procedure ml_ra_get_agent_ids()
begin
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
    from ml_ra_agent 
	left outer join ml_database on ml_database.rid = taskdb_rid
	left outer join ml_ra_agent_property
	on ml_ra_agent.aid = ml_ra_agent_property.aid
	    and property_name = 'ml_ra_description'
    order by agent_id;
end;
//

create procedure ml_ra_get_remote_ids()
begin
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
//

create procedure ml_ra_set_agent_property(
    p_agent_id		varchar( 128 ),
    p_property_name	varchar( 128 ),
    p_property_value	varchar( 128 ) )
begin
    declare v_cnt		    integer;
    declare v_aid		    integer;
    declare v_server_interval	    integer;
    declare v_old_agent_interval    integer;
    declare v_new_agent_interval    integer;
    declare v_autoset		    varchar(3);

    select aid into v_aid from ml_ra_agent where agent_id = p_agent_id;
    
    if p_property_name = 'lwp_freq' then
	select property_value into v_autoset from ml_property where 
	    component_name = 'SIRT'
	    and property_set_name = 'RTNotifier(RTNotifier1)'
	    and property_name = 'autoset_poll_every';
	if v_autoset = 'yes' then
	    select property_value into v_server_interval from ml_property where 
		component_name = 'SIRT'
		and property_set_name = 'RTNotifier(RTNotifier1)'
		and property_name = 'poll_every';
	    select property_value into v_old_agent_interval from ml_ra_agent_property where
		aid = v_aid
		and property_name = 'lwp_freq';
	    set v_new_agent_interval = p_property_value;
	    if v_new_agent_interval < v_server_interval then
		call ml_add_property( 'SIRT', 'RTNotifier(RTNotifier1)', 'poll_every', p_property_value );
	    elseif v_new_agent_interval > v_server_interval then
		if v_new_agent_interval > v_old_agent_interval and v_old_agent_interval <= v_server_interval then
		    -- This agents interval is increasing, check if server interval should increase too
		    if not exists( select * from ml_ra_agent_property 
			where property_name = 'lwp_freq'
			    and cast(property_value as unsigned) <= v_old_agent_interval
			    and aid != v_aid ) then
			-- Need to compute the new server interval
			select min( cast( property_value as unsigned) ) into v_server_interval from ml_ra_agent_property 
			    where property_name = 'lwp_freq' and aid != v_aid;
			if v_server_interval is null then 
			    set v_server_interval = v_new_agent_interval;
			end if;
			call ml_add_property( 'SIRT', 'RTNotifier(RTNotifier1)', 'poll_every', v_server_interval );
		    end if;
		end if;
	    end if;
	end if;
    end if;	

    insert into ml_ra_agent_property( aid, property_name,
				      property_value, last_modified )
	values( v_aid, p_property_name, p_property_value, now() )
	on duplicate key update property_value = p_property_value,
				last_modified = now();
end;
//

-- If error is raised then caller must rollback

create procedure ml_ra_clone_agent_properties(
    p_dst_agent_id	varchar( 128 ),
    p_src_agent_id	varchar( 128 ) )
begin
    declare v_dst_aid	integer;
    declare v_src_aid	integer;
    declare v_error1	integer;

    select aid into v_dst_aid from ml_ra_agent where agent_id = p_dst_agent_id;
    select aid into v_src_aid from ml_ra_agent where agent_id = p_src_agent_id;
    if v_src_aid is null then
	set v_error1 = 'bad src';
    end if;

    delete from ml_ra_agent_property
	where aid = v_dst_aid
	    and property_name != 'agent_id'
	    and property_name not like( 'ml\_ra\_%' );

    insert into ml_ra_agent_property( aid, property_name, property_value, last_modified )
	select v_dst_aid, src.property_name, src.property_value, now() 
	from ml_ra_agent_property src 
	where src.aid = v_src_aid 
	    and property_name != 'agent_id' 
	    and property_name not like( 'ml\_ra\_%' );
end;
//

create procedure ml_ra_get_agent_properties(
    p_agent_id	varchar( 128 ) )
begin
    declare v_aid	integer;

    select aid into v_aid from ml_ra_agent where agent_id = p_agent_id;
    
    select property_name, property_value, last_modified
	from ml_ra_agent_property 
	where aid = v_aid
	    and property_name != 'agent_id'
	    and property_name not like( 'ml\_ra\_%' )
	order by property_name;
end;
//

-- If error is raised then caller must rollback

create procedure ml_ra_add_agent_id(
    p_agent_id	varchar( 128 ) )
begin
    declare v_aid	 integer;

    insert into ml_ra_agent( agent_id ) values ( p_agent_id );
    select last_insert_id() into v_aid;

    insert into ml_ra_event( event_class, event_type, aid, event_time ) 
	values( 'I', 'ANEW', v_aid, now() );
    call ml_ra_set_agent_property( p_agent_id, 'agent_id', p_agent_id );
    call ml_ra_set_agent_property( p_agent_id, 'max_taskdb_sync_interval', 86400 );
    call ml_ra_set_agent_property( p_agent_id, 'lwp_freq', 900 );
    call ml_ra_set_agent_property( p_agent_id, 'agent_id_status', 'OK' );
end;
//

-- If error is raised then caller must rollback

create procedure ml_ra_manage_remote_db(
    p_agent_id		varchar( 128 ), 
    p_schema_name	varchar( 128 ),
    p_conn_str		varchar( 2048 ) )
begin
    declare v_aid	 integer;
    declare v_ldt	 datetime;


    select aid, last_download_time into v_aid, v_ldt from 
	ml_ra_agent left outer join ml_subscription on taskdb_rid = rid
    where agent_id = p_agent_id;
    insert into ml_ra_managed_remote(aid, remote_id, schema_name, conn_str, last_modified ) 
	values( v_aid, null, p_schema_name, p_conn_str, now() );

    update ml_ra_deployed_task dt set state = 'A' 
	where aid = v_aid and state = 'P' and last_modified < v_ldt
	    and exists( select * from ml_ra_task t where t.task_id = dt.task_id and t.schema_name = p_schema_name );
end;
//

-- If error is raised then caller must rollback

create procedure ml_ra_unmanage_remote_db(
    p_agent_id		varchar( 128 ),
    p_schema_name	varchar( 128 ) )
begin
    declare v_aid		integer;
    declare v_has_tasks		integer;
    declare v_error1		integer;

    select aid into v_aid from ml_ra_agent where agent_id = p_agent_id;

    if exists (select * from ml_ra_deployed_task dt
		join ml_ra_task t on dt.task_id = t.task_id
		where dt.aid = v_aid and
		    t.schema_name = p_schema_name 
		    and (state = 'A' or state = 'P' or state = 'CP') ) then
	set v_error1 = 'has active tasks';
    end if;

    delete from ml_ra_deployed_task
	where aid = v_aid and state != 'A' and state != 'P' and state != 'CP'
	    and exists( select * from ml_ra_task where ml_ra_task.task_id = ml_ra_deployed_task.task_id
		and ml_ra_task.schema_name = p_schema_name );
    delete from ml_ra_managed_remote where aid = v_aid and schema_name = p_schema_name;
end;
//

-- If error is raised then caller must rollback

create procedure ml_ra_delete_agent_id(
    p_agent_id		varchar( 128 ) )
begin
    declare v_aid		integer;
    declare v_taskdb_rid	integer;
    declare v_taskdb_remote_id	varchar( 128 );
    declare v_error1		integer;
    declare v_done		int default 0;
    declare taskdb_crsr		cursor for
	select taskdb_rid, ml_database.rid remote_id from ml_ra_agent_staging
	    join ml_database on ml_database.rid = taskdb_rid
	    where property_name = 'agent_id' and property_value = p_agent_id;

    select aid, taskdb_rid into v_aid, v_taskdb_rid
	from ml_ra_agent where agent_id = p_agent_id;
    if v_aid is null then
	set v_error1 = 'bad agent id';
    end if;

    call ml_ra_set_agent_property( p_agent_id, 'lwp_freq', 2147483647 );

    -- Delete all dependent rows
    delete from ml_ra_agent_property where aid = v_aid;
    delete from ml_ra_deployed_task where aid = v_aid;
    delete from ml_ra_notify where agent_poll_key = p_agent_id;
    delete from ml_ra_managed_remote where aid = v_aid;

    -- Delete the agent
    delete from ml_ra_agent where aid = v_aid;

    -- Clean up any taskdbs that were associated with this agent_id
    begin
	declare continue handler for SQLSTATE '02000' set v_done = 1;
	open taskdb_crsr;
	crsr: loop
	    fetch taskdb_crsr into v_taskdb_rid, v_taskdb_remote_id;
	    if not v_done then
		delete from ml_ra_agent_staging where taskdb_rid = v_taskdb_rid;
		delete from ml_ra_event_staging where taskdb_rid = v_taskdb_rid;
		call ml_delete_remote_id( v_taskdb_remote_id );
	    else
		leave crsr;
	    end if;
	end loop crsr;
	close taskdb_crsr;
    end;
end;
//

create procedure ml_ra_int_move_events(
    p_aid		integer, 
    p_taskdb_rid	integer )
begin
    -- Copy events into ml_ra_event from staging table
    insert into ml_ra_event( event_class, event_type, aid, task_id,
			     command_number, run_number, duration, event_time,
			     event_received, result_code, result_text )
	select event_class, event_type, p_aid, dt.task_id,
	       command_number, run_number, duration, event_time,
	       now(), result_code, result_text
	    from ml_ra_event_staging es
		left outer join ml_ra_deployed_task dt on dt.task_instance_id = es.task_instance_id
	    where es.taskdb_rid = p_taskdb_rid
	    order by remote_event_id;

    -- Clean up staged values
    delete from ml_ra_event_staging where taskdb_rid = p_taskdb_rid;
end;
//

create procedure ml_ra_delete_events_before(
    p_delete_rows_older_than	datetime )
begin
    delete from ml_ra_event where event_received <= p_delete_rows_older_than;
end;
//

create procedure ml_ra_get_orphan_taskdbs()
begin
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
//

-- If error is raised then caller must rollback

create procedure ml_ra_reassign_taskdb(
    p_taskdb_remote_id	varchar( 128 ),
    p_new_agent_id	varchar( 128 ) )
begin
    declare v_other_taskdb_rid	integer;
    declare v_taskdb_rid	integer;
    declare v_other_agent_aid	integer;
    declare v_old_agent_id	varchar( 128 );
    declare v_new_aid		integer;
    declare v_error1		integer;

    select rid into v_taskdb_rid from ml_database
	where remote_id = p_taskdb_remote_id;
    if v_taskdb_rid is null then
	set v_error1 = 'bad remote';
    end if;

    select property_value into v_old_agent_id from ml_ra_agent_staging
	where taskdb_rid = v_taskdb_rid and
	property_name = 'agent_id';
    if v_old_agent_id is null then
	set v_error1 = 'bad remote';
    end if;

    select count(*) into v_other_taskdb_rid from ml_ra_agent
	where agent_id = p_new_agent_id;
    if v_other_taskdb_rid = 0 then
	call ml_ra_add_agent_id( p_new_agent_id );
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
    call ml_ra_int_move_events( v_new_aid, v_taskdb_rid );

    -- The next time the agent syncs it will receive its new agent_id
    call ml_ra_notify_agent_sync( v_old_agent_id );
end;
//

-- --------------------------------------------------------------
-- Synchronization scripts for the remote agent's task database
-- Note, there is no authenticate user script here, this will need
-- to be provided by the user.
-- --------------------------------------------------------------

create procedure ml_ra_ss_end_upload( 
    p_taskdb_remote_id			varchar( 128 ) )
begin
    declare v_taskdb_rid		integer;
    declare v_consdb_taskdb_rid		integer;
    declare v_consdb_taskdb_remote_id 	varchar( 128 );
    declare v_agent_id			varchar( 128 );
    declare v_provided_id 		varchar( 128 );
    declare v_old_machine_name		varchar( 128 );
    declare v_new_machine_name		varchar( 128 );
    declare v_aid			integer;
    declare v_used			varchar( 128 );
    declare v_name			varchar( 128 );
    declare v_value			varchar( 2048 );
    declare v_old_value			varchar( 2048 );
    declare v_schema_name		varchar( 128 );
    declare v_done1			integer default 0;
    declare v_done2			integer default 0;

    declare v_task_instance_id		decimal( 20 );
    declare v_result_code		decimal( 20 );
    declare v_event_type		varchar( 8 );
    declare event_crsr			cursor for
	    select event_type, result_code, substring( result_text, 1, 2048 ), task_instance_id
		from ml_ra_event_staging
		where taskdb_rid = v_taskdb_rid
		order by remote_event_id;
    declare as_crsr			cursor for
	    select property_name, property_value
		from ml_ra_agent_staging
		where taskdb_rid = v_taskdb_rid and
		    property_name not like ( 'ml\_ra\_%' );
		    
    select rid, agent_id, aid into v_taskdb_rid, v_agent_id, v_aid
	from ml_database left outer join ml_ra_agent on taskdb_rid = rid 
	where remote_id = p_taskdb_remote_id;

    main: begin
	if v_agent_id is null then 
	    -- This taskdb isn't linked to an agent_id in the consolidated yet
	    delete from ml_ra_agent_staging where taskdb_rid = v_taskdb_rid and property_name = 'agent_id_status';
	    select property_value into v_provided_id from ml_ra_agent_staging 
		where taskdb_rid = v_taskdb_rid and
		    property_name = 'agent_id';
	    if v_provided_id is null then
		-- Agent failed to provide an agent_id
		insert into ml_ra_agent_staging( taskdb_rid,
			property_name, property_value )
		    values( v_taskdb_rid, 'agent_id_status', 'RESET' );
		leave main;
	    end if;
		
	    select taskdb_rid, aid into v_consdb_taskdb_rid, v_aid
		from ml_ra_agent where agent_id = v_provided_id;
	    if v_consdb_taskdb_rid is not null then
		-- We have 2 remote task databases using the same agent_id.
		-- Attempt to determine if its a reset of an agent or 2 separate 
		-- agents conflicting with each other.
		select remote_id into v_consdb_taskdb_remote_id
		    from ml_database where rid = v_consdb_taskdb_rid;
		set v_old_machine_name = substring( v_consdb_taskdb_remote_id, 7,
					 length(v_consdb_taskdb_remote_id) - 43 );
		set v_new_machine_name = substring( p_taskdb_remote_id, 7,
					 length(p_taskdb_remote_id) - 43 );
		    
		if v_old_machine_name != v_new_machine_name then
		    -- There are 2 agents with conflicting agent_ids
		    -- This taskdb will not be allowed to download tasks.
		    insert into ml_ra_event( event_class, event_type, aid,
					     event_time, result_text ) 
			values( 'E', 'ADUP', v_aid, now(),
				p_taskdb_remote_id );
		    insert into ml_ra_agent_staging( taskdb_rid,
			    property_name, property_value )
			values( v_taskdb_rid, 'agent_id_status', 'DUP' );
		    leave main;
		end if; -- Otherwise, we allow replacement of the taskdb
	    end if;	    
    
	    set v_agent_id = v_provided_id;
	    if v_aid is null then
		-- We have a new agent_id
		call ml_ra_add_agent_id( v_agent_id );
		select aid into v_aid from ml_ra_agent where agent_id = v_agent_id;
	    end if;
    
	    select property_value into v_used from ml_ra_agent_staging 
		where taskdb_rid = v_taskdb_rid and
		    property_name = 'ml_ra_used';
	    if v_used is not null then
		-- We can only establish a mapping between new taskdb_remote_ids and agent_ids
		insert into ml_ra_agent_staging( taskdb_rid,
			property_name, property_value )
		    values( v_taskdb_rid, 'agent_id_status', 'RESET' );
		-- Preserve any events that may have been uploaded
		-- Note, no task state is updated here, these
		-- events could be stale and may no longer apply.
		call ml_ra_int_move_events( v_aid, v_taskdb_rid );
		leave main;
	    else
		insert into ml_ra_agent_staging( taskdb_rid, property_name,
						 property_value )
		    values( v_taskdb_rid, 'ml_ra_used', '1' );
	    end if;
    
	    -- Store the link between this agent_id and remote_id
	    update ml_ra_agent set taskdb_rid = v_taskdb_rid
		where agent_id = v_agent_id;
    
	    select property_value into v_used from ml_ra_agent_property
		where aid = v_aid and property_name = 'ml_ra_used';
	    if v_used is null then
		-- This is the first taskdb for an agent
		insert into ml_ra_event( event_class, event_type, aid,
					 event_time ) 
		    values( 'I', 'AFIRST', v_aid, now() );
		insert into ml_ra_agent_property( aid, property_name,
						  property_value, last_modified )
		    values( v_aid, 'ml_ra_used', '1', now() );
	    else
		-- A new taskdb is taking over
		insert into ml_ra_event( event_class, event_type, aid,
					 event_time, result_text ) 
		    values( 'I', 'ARESET', v_aid, now(),
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
			last_modified = now()
		    where aid = v_aid;
	    end if;
	end if;
    
	-- Update the status of deployed tasks
	begin
	    declare continue handler for SQLSTATE '02000' set v_done1 = 1;
	    open event_crsr;
	    event_loop: loop
		fetch event_crsr into v_event_type, v_result_code, v_value, v_task_instance_id;
		if v_done1 then
		    leave event_loop;
		else
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
					substring( v_event_type, 3, length( v_event_type ) - 2 )
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
			select substring( v_value, 6, length( v_value ) - 5 ) into v_value;
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
		end if;
	    end loop event_loop;
	    close event_crsr;
	end;
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
	begin
	    declare continue handler for SQLSTATE '02000' set v_done2 = 1;
	    open as_crsr;
	    crsr: loop
		fetch as_crsr into v_name, v_value;
		if not v_done2 then
		    if not exists (select * from ml_ra_agent_property
			    where aid = v_aid and property_name = v_name) then
			insert into ml_ra_agent_property( aid, property_name,
							  property_value, last_modified )
			    values( v_aid, v_name, v_value, now() );
		    else
			select property_value into v_old_value from ml_ra_agent_property
			    where aid = v_aid and property_name = v_name;
			if (v_old_value is null and v_value is not null )
				or (v_old_value is not null and v_value is null )
				or (v_old_value != v_value) then
			    update ml_ra_agent_property set property_value = v_value, last_modified = now()
				where aid = v_aid and property_name = v_name;
			end if;
		    end if;
		else
		    leave crsr;
		end if;
	    end loop crsr;
	    close as_crsr;
	
	    delete from ml_ra_agent_staging where taskdb_rid = v_taskdb_rid 
		and property_name not like ( 'ml\_ra\_%' )
		and property_name != 'agent_id';
	    call ml_ra_int_move_events( v_aid, v_taskdb_rid );
	end;
    end main;
end;
//
    
create procedure ml_ra_ss_download_prop(
    p_taskdb_remote_id		varchar( 128 ), 
    p_last_table_download	datetime )
begin
    declare v_aid		integer;
    declare v_taskdb_rid	integer;

    select a.aid, d.rid into v_aid, v_taskdb_rid from ml_database d 
	left outer join ml_ra_agent a on a.taskdb_rid = d.rid
	where d.remote_id = p_taskdb_remote_id;

    if v_aid is null then
	select property_name, property_value from ml_ra_agent_staging 
	    where taskdb_rid = v_taskdb_rid 
		and property_name not like 'ml\_ra\_%';
    else
	select property_name, property_value from ml_ra_agent_property p 
	    where p.aid = v_aid and property_name not like 'ml\_ra\_%' 
		and last_modified >= p_last_table_download;
    end if;
end;
//

create procedure ml_ra_ss_upload_prop(
    p_taskdb_remote_id		varchar( 128 ),
    p_property_name		varchar( 128 ),
    p_property_value		varchar( 2048 ) )

begin
    declare v_taskdb_rid	integer;

    select rid into v_taskdb_rid from ml_database where remote_id = p_taskdb_remote_id;

    insert into ml_ra_agent_staging( taskdb_rid, property_name, property_value )
	values( v_taskdb_rid, p_property_name, p_property_value )
	on duplicate key update property_value = p_property_value; 
end;
//

create procedure ml_ra_ss_download_task(
    p_taskdb_remote_id		varchar( 128 ) )
begin
    select task_instance_id, task_name, ml_ra_task.schema_name,
	max_number_of_attempts, delay_between_attempts,
	max_running_time, ml_ra_task.flags,
	case dt.state 
	    when 'P' then 'A'
	    when 'CP' then 'C'
	end,
	cond, remote_event
    from ml_database task_db
	join ml_ra_agent on ml_ra_agent.taskdb_rid = task_db.rid
	join ml_ra_deployed_task dt on dt.aid = ml_ra_agent.aid
	join ml_ra_task on dt.task_id = ml_ra_task.task_id
    where task_db.remote_id = p_taskdb_remote_id
	and ( dt.state = 'CP' or dt.state = 'P' );
end;
//

create procedure ml_ra_ss_download_task_cmd(
    p_taskdb_remote_id		varchar( 128 ) )
begin
    select task_instance_id, command_number, ml_ra_task_command.flags,
	action_type, action_parm
    from ml_database task_db
	join ml_ra_agent on ml_ra_agent.taskdb_rid = task_db.rid
	join ml_ra_deployed_task dt on dt.aid = ml_ra_agent.aid
	join ml_ra_task on dt.task_id = ml_ra_task.task_id
	join ml_ra_task_command on dt.task_id = ml_ra_task_command.task_id
    where task_db.remote_id = p_taskdb_remote_id
	and dt.state = 'P';
end;
//

create procedure ml_ra_ss_download_remote_dbs(
    p_taskdb_remote_id		varchar( 128 ),
    p_last_download		datetime )
begin
    select ml_ra_schema_name.schema_name, ml_ra_managed_remote.remote_id, conn_str, remote_type 
    from ml_database taskdb
	join ml_ra_agent on ml_ra_agent.taskdb_rid = taskdb.rid
	join ml_ra_managed_remote on ml_ra_managed_remote.aid = ml_ra_agent.aid
	join ml_ra_schema_name on ml_ra_schema_name.schema_name = ml_ra_managed_remote.schema_name
    where taskdb.remote_id = p_taskdb_remote_id
	and ml_ra_managed_remote.last_modified >= p_last_download;
end;
//

create procedure ml_ra_ss_upload_event(
    p_taskdb_remote_id	varchar( 128 ), 
    p_remote_event_id	bigint, 
    p_event_class	varchar( 1 ), 
    p_event_type	varchar( 4 ), 
    p_task_instance_id	bigint, 
    p_command_number	integer, 
    p_run_number	bigint, 
    p_duration		integer,
    p_event_time	datetime,
    p_result_code	bigint, 
    p_result_text	longtext )
begin
    declare v_taskdb_rid integer;

    select rid into v_taskdb_rid from ml_database where remote_id = p_taskdb_remote_id;
	
    insert into ml_ra_event_staging( taskdb_rid, remote_event_id, 
	    event_class, event_type, task_instance_id,
	    command_number, run_number, duration, event_time,
	    result_code, result_text )
	values ( v_taskdb_rid, p_remote_event_id, p_event_class,
	    p_event_type, p_task_instance_id, p_command_number,
	    p_run_number, p_duration, p_event_time, p_result_code,
	    p_result_text )
	on duplicate key update
	    event_class = p_event_class,
	    event_type = p_event_type,
	    task_instance_id = p_task_instance_id,
	    command_number = p_command_number,
	    run_number = p_run_number, 
	    duration = p_duration,
	    event_time = p_event_time,
	    result_code = p_result_code,
	    result_text = p_result_text;
end;
//

create procedure ml_ra_ss_download_ack(
    p_taskdb_remote_id	varchar( 128 ), 
    p_ldt		datetime )
begin
    declare v_aid		integer;
    declare v_agent_id		varchar( 128 );
    declare v_task_instance_id	bigint;
    declare v_done		integer default 0;

    declare task_ack cursor for
	select dt.task_instance_id from ml_ra_deployed_task dt
	    join ml_ra_task t on t.task_id = dt.task_id
	    left outer join ml_ra_managed_remote mr
		on t.schema_name = mr.schema_name and mr.aid = v_aid
	where dt.aid = v_aid
	    and dt.state = 'P' and dt.last_modified < p_ldt
	    and ( t.schema_name is null or mr.schema_name is not null ); 

    select aid, agent_id into v_aid, v_agent_id from ml_ra_agent
	join ml_database on taskdb_rid = rid
	where remote_id = p_taskdb_remote_id;

    begin
	declare continue handler for SQLSTATE '02000' set v_done = 1;
	open task_ack;
	crsr: loop
	    fetch task_ack into v_task_instance_id;
	    if not v_done then
		update ml_ra_deployed_task set state = 'A' 
		    where task_instance_id = v_task_instance_id;
	    else
		leave crsr;
	    end if;
	end loop crsr;
	close task_ack;
    end;
    delete from ml_ra_notify
	where agent_poll_key = v_agent_id
	    and task_instance_id = -1 
	    and last_modified <= p_ldt;
end;
//

-- Default file transfer scripts for upload and download

create procedure ml_ra_ss_agent_auth_file_xfer(
    p_requested_direction	varchar( 1 ),
    p_auth_code			INTEGER,
    p_ml_user			varchar( 128 ),
    p_remote_key		varchar( 128 ),
    p_fsize			bigint,
    p_filename			varchar( 128 ),
    p_sub_dir			varchar( 128 ) )  
begin
    declare v_offset		integer;
    declare v_cmd_num		integer;
    declare v_tiid		bigint;
    declare v_tid		bigint;
    declare v_aid		integer;
    declare v_task_state	varchar( 4 );
    declare v_max_size		bigint;
    declare v_direction		varchar( 1 );
    declare v_server_sub_dir	varchar( 128 );
    declare v_server_filename	varchar( 128 );
    declare v_agent_id		varchar( 128 );

    -- By convention file transfer commands will send up the remote key with...
    -- task_instance_id command_number
    -- eg 1 5	-- task_instance_id=1 command_number=5
    set v_offset = instr( p_remote_key, ' ' );
    if v_offset = 0 then
	set p_auth_code = 2000;
    else
	set v_tiid = substring( p_remote_key, 1, v_offset );
	set v_cmd_num = substring( p_remote_key, v_offset + 1, length( p_remote_key ) - v_offset );
	if v_tiid is null or v_tiid < 1 or v_cmd_num is null or v_cmd_num < 0 then
	    set p_auth_code = 2000;
	else
	    -- fetch properties of the task
	    select task_id, aid, state into v_tid, v_aid, v_task_state
		from ml_ra_deployed_task where task_instance_id = v_tiid;
	    -- Disallow transfer if the task is no longer active
	    if v_task_state is null or (v_task_state != 'A' and v_task_state != 'P') then
		set p_auth_code = 2001;
	    else
		-- Make sure the file isn't too big
		select property_value into v_max_size from ml_ra_task_command_property
		    where task_id = v_tid and
			command_number = v_cmd_num and
			property_name = 'mlft_max_file_size';
		if v_max_size > 0 and p_fsize > v_max_size then
		    set p_auth_code = 2002;
		else
		    -- Make sure the direction is correct
		    select property_value into v_direction from ml_ra_task_command_property
			where task_id = v_tid and
			    command_number = v_cmd_num and
			    property_name = 'mlft_transfer_direction';
		    if v_direction != p_requested_direction then
			set p_auth_code = 2003;
		    else
			-- set the filename output parameter
			select property_value into v_server_filename from ml_ra_task_command_property
			    where task_id = v_tid and
				command_number = v_cmd_num and
				property_name = 'mlft_server_filename';
			if v_server_filename is not null then
			    select agent_id into v_agent_id from ml_ra_agent where aid = v_aid;
			    set p_filename = replace(
				replace( v_server_filename, '{ml_username}', p_ml_user ),
				'{agent_id}', v_agent_id );
			end if;
			-- set the sub_dir output parameter
			select property_value into v_server_sub_dir from ml_ra_task_command_property
			    where task_id = v_tid and
				command_number = v_cmd_num and
				property_name = 'mlft_server_sub_dir';
			if v_server_sub_dir is null then
			    set p_sub_dir = '';
			else
			    select agent_id into v_agent_id from ml_ra_agent where aid = v_aid;
			    set p_sub_dir = replace(
				replace( v_server_sub_dir, '{ml_username}', p_ml_user ),
				'{agent_id}', v_agent_id );
			end if;
			-- Everything is ok, allow the file transfer
			set p_auth_code = 1000;
		    end if;
		end if;
	    end if;
	end if;
    end if;
    select p_auth_code, p_filename, p_sub_dir;
end;
//

create procedure ml_ra_adminprop_upload_upsert(
    p_rid		varchar( 128 ),
    p_name		varchar( 128 ),
    p_value    		varchar( 2048 ) )
begin 
    insert into ml_ra_agent_staging( taskdb_remote_id, property_name, property_value )
	values( v_rid, v_name, v_value ) on duplicate key 
	update property_value = v_value;
end;
//

call ml_add_table_script( 'ml_ra_agent_12', 'ml_ra_agent_adminprop', 'upload_insert', 
    '{ call ml_ra_ss_upload_prop( {ml s.remote_id}, {ml r.name}, {ml r.value} ) }' )
// 
call ml_add_table_script( 'ml_ra_agent_12', 'ml_ra_agent_adminprop', 'upload_update',
    '{ call ml_ra_ss_upload_prop( {ml s.remote_id}, {ml r.name}, {ml r.value} ) }' )
//
call ml_add_table_script( 'ml_ra_agent_12', 'ml_ra_agent_adminprop', 'download_cursor', 
    '{call ml_ra_ss_download_prop( {ml s.remote_id}, {ml s.last_table_download} )}' )
//
call ml_add_table_script( 'ml_ra_agent_12', 'ml_ra_agent_adminprop', 'download_delete_cursor', '--{ml_ignore}' )
//
call ml_add_connection_script( 'ml_ra_agent_12', 'end_upload', 
    '{call ml_ra_ss_end_upload( {ml s.remote_id} )}' )
//
call ml_add_connection_script( 'ml_ra_agent_12', 'nonblocking_download_ack', 
    '{call ml_ra_ss_download_ack( {ml s.remote_id}, {ml s.last_download} )}' )
//

call ml_add_table_script( 'ml_ra_agent_12', 'ml_ra_agent_task', 'download_cursor',  
    '{call ml_ra_ss_download_task( {ml s.remote_id} )}' )
//
call ml_add_table_script( 'ml_ra_agent_12', 'ml_ra_agent_task', 'download_delete_cursor', '--{ml_ignore}' )
//

call ml_add_table_script( 'ml_ra_agent_12', 'ml_ra_agent_command', 'download_cursor', 
    '{call ml_ra_ss_download_task_cmd( {ml s.remote_id} )}' )
//
call ml_add_table_script( 'ml_ra_agent_12', 'ml_ra_agent_command', 'download_delete_cursor', '--{ml_ignore}' )
//

call ml_add_table_script( 'ml_ra_agent_12', 'ml_ra_agent_remote_db', 'download_cursor',
    '{call ml_ra_ss_download_remote_dbs( {ml s.remote_id}, {ml s.last_table_download} )}' )
//
call ml_add_table_script( 'ml_ra_agent_12', 'ml_ra_agent_remote_db', 'download_delete_cursor', '--{ml_ignore}' )
//
call ml_add_table_script( 'ml_ra_agent_12', 'ml_ra_agent_remote_db', 'upload_insert', '--{ml_ignore}' )
//
call ml_add_table_script( 'ml_ra_agent_12', 'ml_ra_agent_remote_db', 'upload_update', '--{ml_ignore}' )
//
call ml_add_table_script( 'ml_ra_agent_12', 'ml_ra_agent_remote_db', 'upload_delete', '--{ml_ignore}' )
//

call ml_add_table_script( 'ml_ra_agent_12', 'ml_ra_agent_status', 'upload_insert',
    '{call ml_ra_ss_upload_event( 
{ml s.remote_id}, {ml r.id}, {ml r.class}, {ml r.status}, 
{ml r.task_instance_id}, {ml r.command_number}, {ml r.exec_count}, 
{ml r.duration}, {ml r.status_time}, {ml r.status_code}, {ml r.text} )}' )
//
call ml_add_table_script( 'ml_ra_agent_12', 'ml_ra_agent_status', 'upload_update', 
    '{call ml_ra_ss_upload_event( 
{ml s.remote_id}, {ml r.id}, {ml r.class}, {ml r.status}, 
{ml r.task_instance_id}, {ml r.command_number}, {ml r.exec_count}, 
{ml r.duration}, {ml r.status_time}, {ml r.status_code}, {ml r.text} )}' )
//
call ml_add_table_script( 'ml_ra_agent_12', 'ml_ra_agent_status', 'download_cursor', '--{ml_ignore}' )
//
call ml_add_table_script( 'ml_ra_agent_12', 'ml_ra_agent_status', 'download_delete_cursor', '--{ml_ignore}' )
//

call ml_add_connection_script( 'ml_ra_agent_12', 'authenticate_file_upload', 
    '{ call ml_ra_ss_agent_auth_file_xfer( ''U'', {ml s.file_authentication_code}, {ml s.username}, {ml s.remote_key}, {ml s.file_size}, {ml s.filename}, {ml s.subdir} ) }' )
//
call ml_add_connection_script( 'ml_ra_agent_12', 'authenticate_file_transfer',
    '{ call ml_ra_ss_agent_auth_file_xfer( ''D'', {ml s.file_authentication_code}, {ml s.username}, {ml s.remote_key}, 0, {ml s.filename}, {ml s.subdir} ) }' )
//
call ml_add_property( 'SIRT', 'RTNotifier(RTNotifier1)', 'request_cursor', 'select agent_poll_key,task_instance_id,last_modified from ml_ra_notify order by agent_poll_key' )
//

-- RT Notifier doesn't begin polling until an agent is created
call ml_add_property( 'SIRT', 'RTNotifier(RTNotifier1)', 'poll_every', '2147483647' )
//

-- Set to 'no' to disable auto setting 'poll_every', then manually set 'poll_every'
call ml_add_property( 'SIRT', 'RTNotifier(RTNotifier1)', 'autoset_poll_every', 'yes' )
//

call ml_add_property( 'SIRT', 'RTNotifier(RTNotifier1)', 'enable', 'yes' )
//

-- Check for updates to started notifiers every minute
call ml_add_property( 'SIRT', 'Global', 'update_poll_every', '60' )
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
