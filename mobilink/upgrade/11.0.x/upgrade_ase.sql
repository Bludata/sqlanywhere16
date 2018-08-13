
--
-- Upgrade the MobiLink Server system tables and stored procedures in
-- a Sybase ASE consolidated database.
--


--
-- Add new tables for user authentication using LDAP servers
--
create table ml_ldap_server (
    ldsrv_id		integer		identity,
    ldsrv_name		varchar( 128 )	not null,
    search_url		varchar( 1024 )	not null,
    access_dn		varchar( 1024 )	not null,
    access_dn_pwd	varchar( 256 )	not null,
    auth_url		varchar( 1024 )	not null,
    num_retries		tinyint		default 3,
    timeout		integer		default 10,
    start_tls		tinyint		default 0,
    unique( ldsrv_name ),
    primary key ( ldsrv_id ) ) 
    lock datarows
go

create table ml_trusted_certificates_file (
    file_name		varchar( 1024 ) not null ) 
    lock datarows
go

create table ml_user_auth_policy (
    policy_id			integer		identity,
    policy_name			varchar( 128 )	not null,
    primary_ldsrv_id		integer		not null,
    secondary_ldsrv_id		integer		null,
    ldap_auto_failback_period	integer		default 900,
    ldap_failover_to_std	tinyint		default 1,
    unique( policy_name ),
    foreign key( primary_ldsrv_id ) references ml_ldap_server( ldsrv_id ),
    foreign key( secondary_ldsrv_id ) references ml_ldap_server( ldsrv_id ),
    primary key( policy_id ) ) 
    lock datarows
go

--
-- Alter the ml_user table to add two new columns
--
--
alter table ml_user add policy_id integer null
    references ml_user_auth_policy( policy_id )
go 

alter table ml_user add user_dn varchar( 1024 ) null
go 

-- Add new columns to the ml_database table
--
alter table ml_database add seq_id binary(16) null
go

alter table ml_database add seq_uploaded integer default 0 not null
go

alter table ml_database add sync_key varchar(40) null
go

--
-- Enable row-level locking on the following tables
--
alter table ml_user lock datarows
alter table ml_database lock datarows
alter table ml_subscription lock datarows
go

drop table ml_active_remote_id
go

drop procedure ml_server_update
go

drop procedure ml_server_delete
go

drop table ml_server
go

--
-- Add trigger on ml_column table
--
create trigger ml_column_trigger on ml_column for insert, update, delete
as
    update ml_scripts_modified set last_modified = getdate()
go

--
-- Add the ml_primary_server table
--
create table ml_primary_server (
    server_id		integer		identity,
    name		varchar( 128 )	not null unique,
    connection_info	varchar( 1700 )	not null,
    instance_key	binary( 32 )	not null,
    start_time		datetime	default getdate() not null,
    primary key( server_id ) )
go

drop procedure ml_delete_user
go

drop procedure ml_delete_sync_state
go

drop procedure ml_delete_sync_state_before
go

create procedure ml_delete_remote_id
    @remote_id		varchar(128)
as
    declare @rid integer
    
    select @rid = rid from ml_database where remote_id = @remote_id
    if @rid is not null begin
	delete from ml_subscription where rid = @rid
	delete from ml_passthrough_status where remote_id = @remote_id
	delete from ml_passthrough where remote_id = @remote_id
	delete from ml_database where rid = @rid
    end
go
exec sp_procxmode 'ml_delete_remote_id', 'anymode'
go

create procedure ml_delete_user_state
    @user		varchar( 128 )
as
    declare @uid	integer
    declare @rid	integer
    declare @remote_id	varchar(128)
    declare crsr	cursor for select rid from ml_subscription
				       where user_id = @uid

    select @uid = user_id from ml_user where name = @user
    if @uid is not null begin
	open crsr
	while 1 = 1 begin
	    fetch crsr into @rid
	    if @@sqlstatus != 0 break
	    delete from ml_subscription where user_id = @uid and rid = @rid
	    if not exists
		(select * from ml_subscription where rid = @rid) begin
		select @remote_id = remote_id
		    from ml_database where rid = @rid
		exec ml_delete_remote_id @remote_id
	    end
	end
	close crsr
    end
go
exec sp_procxmode 'ml_delete_user_state', 'anymode'
go

create procedure ml_delete_user
    @user		varchar( 128 )
as
    exec ml_delete_user_state @user
    delete from ml_user where name = @user
go
exec sp_procxmode 'ml_delete_user', 'anymode'
go

create procedure ml_delete_sync_state
    @user		varchar( 128 ),
    @remote_id		varchar( 128 )
as
    declare @uid	integer
    declare @rid	integer

    select @uid = user_id from ml_user where name = @user
    select @rid = rid from ml_database where remote_id = @remote_id
    
    if @user is not null and @remote_id is not null begin
	delete from ml_subscription where user_id = @uid and rid = @rid
	if not exists (select * from ml_subscription where rid = @rid)
	    exec ml_delete_remote_id @remote_id
    end
    else if @user is not null begin
	exec ml_delete_user_state @user
    end
    else if @remote_id is not null begin
	exec ml_delete_remote_id @remote_id
    end
go
exec sp_procxmode 'ml_delete_sync_state',	   'anymode'
go

create procedure ml_delete_sync_state_before @ts datetime
as
    declare @rid	integer
    declare @remote_id	varchar(128)
    declare crsr	cursor for select rid from ml_subscription
					where last_upload_time < @ts and
					      last_download_time < @ts

    if @ts is not null begin
	open crsr
	while 1 = 1 begin
	    fetch crsr into @rid
	    if @@sqlstatus != 0 break
	    delete from ml_subscription where rid = @rid and
					      last_upload_time < @ts and
					      last_download_time < @ts
	    if not exists (select * from ml_subscription where rid = @rid) begin
		select @remote_id = remote_id from ml_database where rid = @rid
		exec ml_delete_remote_id @remote_id
	    end
	end
	close crsr
    end
go
exec sp_procxmode 'ml_delete_sync_state_before', 'anymode'
go

create procedure ml_share_all_scripts 
    @version		varchar( 128 ),
    @other_version	varchar( 128 ) 
as
begin
    declare @version_id		integer
    declare @other_version_id	integer
    
    select @version_id = version_id from ml_script_version 
		where name = @version
    select @other_version_id = version_id from ml_script_version 
		where name = @other_version

    if @version_id is null begin
	-- Insert to the ml_script_version
	select @version_id = max( version_id )+1 from ml_script_version
	if @version_id is null begin
	    -- No rows are currently in ml_script_version
	    set @version_id = 1
	end
	insert into ml_script_version ( version_id, name ) 
		values ( @version_id, @version )
    end

    insert into ml_table_script( version_id, table_id, event, script_id )
	select @version_id, table_id, event, script_id from ml_table_script 
	    where version_id = @other_version_id
    
    insert into ml_connection_script( version_id, event, script_id )
	select @version_id, event, script_id from ml_connection_script 
	    where version_id = @other_version_id
end
go

create procedure ml_add_missing_dnld_scripts
    @script_version	varchar( 128 )
as
    declare @version_id	integer
    declare @table_id	integer
    declare @count_1	integer
    declare @count_2	integer
    declare @table_name	varchar(128)
    declare @first	integer
    declare @tid	integer
    
    select @version_id = version_id from ml_script_version
	where name = @script_version
    if @version_id is not null begin
	declare crsr cursor for
	    select t.table_id from ml_table_script t, ml_script_version v
		where t.version_id = v.version_id and
		      v.name = @script_version order by 1
	select @first = 1
	open crsr
	while 1 = 1 begin
	    fetch crsr into @table_id
	    if @@FETCH_STATUS != 0 break
	    if @first = 1 or @table_id <> @tid begin
		if not exists (select * from ml_table_script
				where version_id = @version_id and
				    table_id = @table_id and
				    event = 'download_cursor')
		    select @count_1 = 0
		else
		    select @count_1 = 1
		if not exists (select * from ml_table_script
				where version_id = @version_id and
				    table_id = @table_id and
				    event = 'download_delete_cursor')
		    select @count_2 = 0
		else
		    select @count_2 = 1
		if @count_1 = 0 or @count_2 = 0 begin
		    select @table_name = name from ml_table where table_id = @table_id
		    if @count_1 = 0
			exec ml_add_table_script @script_version, @table_name,
			    'download_cursor', '--{ml_ignore}' 
		    if @count_2 = 0
			exec ml_add_table_script @script_version, @table_name,
			    'download_delete_cursor', '--{ml_ignore}'
		end
		select @first = 0
		select @tid = @table_id
	    end
	end
	close crsr
    end
go
exec sp_procxmode 'ml_add_missing_dnld_scripts', 'anymode'
go

--
-- Add a stored procedure for retrieving locking/blocking information
--
-- Create a stored procedure to get the connections
-- that are currently blocking the connections given
-- by @spids for more than @block_time seconds

create procedure ml_get_blocked_info
    @spids		varchar(2000),
    @block_time		integer
as
begin
    declare @sql	varchar( 2000 )
	    
    select @sql = 'select spid, blocked, time_blocked, 2, cmd' +
	' from master..sysprocesses where blocked>0 and time_blocked > ' + convert(varchar(10),@block_time) +
	' and convert(varchar(10),spid) in (' + @spids + ')'

    exec( @sql )
end
go
exec sp_procxmode 'ml_get_blocked_info', 'anymode'
go

--
-- Add new stored procedures for user authentication using LDAP servers
--
create procedure ml_add_ldap_server 
    @ldsrv_name		varchar( 128 ),
    @search_url    	varchar( 1024 ),
    @access_dn    	varchar( 1024 ),
    @access_dn_pwd	varchar( 256 ),
    @auth_url		varchar( 1024 ),
    @conn_retries	tinyint,
    @conn_timeout	tinyint,
    @start_tls		tinyint 
as
    declare @sh_url	varchar( 1024 )
    declare @as_dn	varchar( 1024 )
    declare @as_pwd	varchar( 256 )
    declare @au_url	varchar( 1024 )
    declare @timeout	tinyint
    declare @retries	tinyint
    declare @tls	tinyint
    
    if @ldsrv_name is not null begin
	if @search_url is null and
	    @access_dn is null and
	    @access_dn_pwd is null and
	    @auth_url is null and
	    @conn_timeout is null and
	    @conn_retries is null and
	    @start_tls is null begin
	    
	    -- delete the server if not used
	    if not exists (select s.ldsrv_id from ml_ldap_server s,
				ml_user_auth_policy p
			    where ( s.ldsrv_id = p.primary_ldsrv_id or
				    s.ldsrv_id = p.secondary_ldsrv_id ) and
				    s.ldsrv_name = @ldsrv_name ) begin
		delete from ml_ldap_server where ldsrv_name = @ldsrv_name 
	    end
	end
	else begin
	    if not exists ( select * from ml_ldap_server where
				ldsrv_name = @ldsrv_name ) begin
		-- add a new ldap server
		if @conn_timeout is null
		    select @timeout = 10
		else
		    select @timeout = @conn_timeout
		if @conn_retries is null
		    select @retries = 3
		else
		    select @retries = @conn_retries
		if @start_tls is null
		    select @tls = 0
		else
		    select @tls = @start_tls
		
		insert into ml_ldap_server ( ldsrv_name, search_url,
			access_dn, access_dn_pwd, auth_url,
			timeout, num_retries, start_tls )
		values( @ldsrv_name, @search_url,
			@access_dn, @access_dn_pwd,
			@auth_url, @timeout, @retries, @tls )
	    end
	    else begin
		-- update the ldap server info
		select @sh_url = search_url,
			@as_dn = access_dn,
			@as_pwd = access_dn_pwd,
			@au_url = auth_url,
			@timeout = timeout,
			@retries = num_retries,
			@tls = start_tls
		    from ml_ldap_server where ldsrv_name = @ldsrv_name
		    
		if @search_url is not null
		    select @sh_url = @search_url
		if @access_dn is not null
		    select @as_dn = @access_dn
		if @access_dn_pwd is not null
		    select @as_pwd = @access_dn_pwd
		if @auth_url is not null
		    select @au_url = @auth_url
		if @conn_timeout is not null
		    select @timeout = @conn_timeout
		if @conn_retries is not null
		    select @retries = @conn_retries
		if @start_tls is not null
		    select @tls = @start_tls
		    
		update ml_ldap_server set
			search_url = @sh_url,
			access_dn = @as_dn,
			access_dn_pwd = @as_pwd,
			auth_url = @au_url,
			timeout = @timeout,
			num_retries = @retries,
			start_tls = @tls
		where ldsrv_name = @ldsrv_name
	    end
	end
    end
go
exec sp_procxmode 'ml_add_ldap_server', 'anymode'
go

create procedure ml_add_certificates_file 
    @file_name		varchar( 1024 ) 
as
    if @file_name is not null begin
	delete from ml_trusted_certificates_file
	insert into ml_trusted_certificates_file ( file_name ) values( @file_name )
    end
go
exec sp_procxmode 'ml_add_certificates_file', 'anymode'
go

create procedure ml_add_user_auth_policy
    @policy_name		varchar( 128 ),
    @primary_ldsrv_name		varchar( 128 ),
    @secondary_ldsrv_name	varchar( 128 ),
    @ldap_auto_failback_period	integer,
    @ldap_failover_to_std	integer 
as
    declare @pldsrv_id	integer
    declare @sldsrv_id	integer
    declare @pid	integer
    declare @sid	integer
    declare @period	integer
    declare @failover	integer
    declare @error	integer
    declare @msg	varchar( 1024 )
    
    if @policy_name is not null begin
	if @primary_ldsrv_name is null and 
	    @secondary_ldsrv_name is null and 
	    @ldap_auto_failback_period is null and 
	    @ldap_failover_to_std is null begin
	    
	    -- delete the policy name if not used
	    if not exists ( select p.policy_id from ml_user u,
				ml_user_auth_policy p where
				    u.policy_id = p.policy_id and
				    policy_name = @policy_name ) begin
		delete from ml_user_auth_policy
		    where policy_name = @policy_name
	    end
	end
	else if @primary_ldsrv_name is null begin
	   -- error
	   select @msg = 'The primary LDAP server cannot be NULL.'
	   raiserror 20000 @msg
	end
	else begin
	    select @error = 0
	    if @primary_ldsrv_name is not null begin
		select @pldsrv_id = ldsrv_id from ml_ldap_server where
		    ldsrv_name = @primary_ldsrv_name
		if @pldsrv_id is null begin
		    select @error = 1
		    select @msg = 'Primary LDAP server "' + @primary_ldsrv_name + '" is not defined.'
		    raiserror 20000 @msg
		end
	    end
	    else begin
		select @pldsrv_id = null
	    end
	    if @secondary_ldsrv_name is not null begin
		select @sldsrv_id = ldsrv_id from ml_ldap_server where
		    ldsrv_name = @secondary_ldsrv_name
		if @sldsrv_id is null begin
		    select @error = 1
		    select @msg = 'Secondary LDAP server "' + @secondary_ldsrv_name + '" is not defined.'
		    raiserror 20000 @msg
		end
	    end
	    else begin
		select @sldsrv_id = null
	    end
	    if @error = 0 begin
		if not exists ( select * from ml_user_auth_policy
				where policy_name = @policy_name ) begin
		    if @ldap_auto_failback_period is null
			select @period = 900
		    else
			select @period = @ldap_auto_failback_period
		    if @ldap_failover_to_std is null
			select @failover = 1
		    else
			select @failover = @ldap_failover_to_std
		    
		    -- add a new user auth policy
		    insert into ml_user_auth_policy
			( policy_name, primary_ldsrv_id, secondary_ldsrv_id,
			  ldap_auto_failback_period, ldap_failover_to_std )
			values( @policy_name, @pldsrv_id, @sldsrv_id,
				@period, @failover )
		end 
		else begin
		    select @pid = primary_ldsrv_id,
			   @sid = secondary_ldsrv_id,
			   @period = ldap_auto_failback_period,
			   @failover = ldap_failover_to_std
			from ml_user_auth_policy where policy_name = @policy_name
    
		    if @pldsrv_id is not null
			select @pid = @pldsrv_id
		    if @sldsrv_id is not null
			select @sid = @sldsrv_id
		    if @ldap_auto_failback_period is not null
			select @period = @ldap_auto_failback_period
		    if @ldap_failover_to_std is not null
			select @failover = @ldap_failover_to_std

		    -- update the user auth policy
		    update ml_user_auth_policy set
				primary_ldsrv_id = @pid,
				secondary_ldsrv_id = @sid,
				ldap_auto_failback_period = @period,
				ldap_failover_to_std = @failover
			where policy_name = @policy_name
		end
	    end
	end
    end
go
exec sp_procxmode 'ml_add_user_auth_policy', 'anymode'
go

--
-- Recreate the ml_add_user stored procedure
--
drop procedure ml_add_user
go

create procedure ml_add_user
    @user		varchar( 128 ),
    @password		binary( 32 ),
    @policy_name	varchar( 128 ) 
as
    declare @user_id	integer
    declare @policy_id	integer
    declare @error	integer
    declare @msg	varchar( 1024 )
    
    if @user is not null begin
	select @error = 0
	if @policy_name is not null begin
	    select @policy_id = policy_id from ml_user_auth_policy
		where policy_name = @policy_name
	    if @policy_id is null begin
		select @msg = 'Unable to find the user authentication policy: "' +
			    @policy_name + '"'
		raiserror 20000 @msg
		select @error = 1
	    end
	end
	else begin 
	    select @policy_id = null
	end
	if @error = 0 begin
	    select @user_id = user_id from ml_user where name = @user
	    if @user_id is null
		insert into ml_user ( name, hashed_password, policy_id )
		    values ( @user, @password, @policy_id )
	    else
		update ml_user set hashed_password = @password,
				    policy_id = @policy_id
		    where user_id = @user_id
	end
    end
go
exec sp_procxmode 'ml_add_user', 'anymode'
go

--
-- Recreate the ml_reset_sync_state stored procedure
--
drop procedure ml_reset_sync_state
go

create procedure ml_reset_sync_state
    @user		varchar( 128 ),
    @remote_id		varchar( 128 )
as
    declare @uid	integer
    declare @rid	integer

    select @uid = user_id from ml_user where name = @user
    select @rid = rid from ml_database where remote_id = @remote_id
    
    if @user is not null and @remote_id is not null begin
	update ml_subscription
	    set progress = 0,
		last_upload_time   = '1900/01/01 00:00:00',
		last_download_time = '1900/01/01 00:00:00'
	    where user_id = @uid and rid = @rid
    end
    else if @user is not null begin 
	update ml_subscription
	    set progress = 0,
		last_upload_time   = '1900/01/01 00:00:00',
		last_download_time = '1900/01/01 00:00:00'
	    where user_id = @uid
    end
    else if @remote_id is not null begin	
	update ml_subscription
	    set progress = 0,
		last_upload_time   = '1900/01/01 00:00:00',
		last_download_time = '1900/01/01 00:00:00'
	    where rid = @rid
    end
    update ml_database
	set sync_key = NULL,
	    seq_id = NULL,
	    seq_uploaded = 0,
	    script_ldt = '1900/01/01 00:00:00'
	where remote_id = @remote_id
go
exec sp_procxmode 'ml_reset_sync_state', 'anymode'
go

--
-- Add new objects to support deploying synchronization models from Sybase Central
--

create table ml_model_schema (
    schema_type		varchar( 32 )	not null,
    schema_owner	varchar( 256 )  not null,
    table_name		varchar( 256 )  not null,
    object_name		varchar( 256 )  not null,
    drop_stmt		varchar( 2000 ) not null,
    checksum		varchar( 256 )	not null,
    db_checksum		varchar( 64 )	null,
    locked		tinyint		not null,
    primary key( schema_type, schema_owner, table_name, object_name ) ) 
go

create table ml_model_schema_use (
    version_id		integer		not null,
    schema_type		varchar( 32 )   not null,
    schema_owner	varchar( 256 )  not null,
    table_name		varchar( 256 )  not null,
    object_name		varchar( 256 )  not null,
    checksum		varchar( 256 )  not null,
    primary key( version_id, schema_type, schema_owner, table_name, object_name ) ) 
go

create table ml_model_schema_status (
    schema_owner	varchar( 256 )  not null,
    table_name		varchar( 256 )  not null,
    schema_type		varchar( 32 )   not null,
    object_name		varchar( 256 )  not null,
    locked		tinyint		null,
    used_by		varchar( 128 )	null,
    status		varchar( 32 )   not null,
    overwrite_action	varchar( 32 )   null,
    preserve_action	varchar( 32 )   null )
go

create procedure ml_model_begin_check
    @version		varchar( 128 )
as
begin
    declare @version_id		integer
    
    select @version_id = version_id from ml_script_version 
	where name = @version

    -- If this same script version was previously installed, 
    -- clean-up any meta-data associated with it.
    delete from ml_model_schema_use where version_id = @version_id
end
go
exec sp_procxmode 'ml_model_begin_check', 'anymode'
go

create procedure ml_model_begin_install
    @version		varchar( 128 )
as
begin
    declare @version_id		integer
    
    select @version_id = version_id from ml_script_version 
	where name = @version

    -- If this same script version was previously installed, 
    -- clean-up any meta-data associated with it.
    delete from ml_column where version_id = @version_id
    delete from ml_connection_script where version_id = @version_id
    delete from ml_table_script where version_id = @version_id
    delete from ml_model_schema_use where version_id = @version_id
    delete from ml_script_version where version_id = @version_id
end
go
exec sp_procxmode 'ml_model_begin_install', 'anymode'
go

create procedure ml_model_get_catalog_checksum(
    @schema_type	varchar( 32 ),
    @schema_owner	varchar( 256 ),
    @table_name		varchar( 256 ),
    @object_name	varchar( 256 ),
    @db_checksum	varchar( 64 ) output )
as
begin
    SET @db_checksum = null
end
go
exec sp_procxmode 'ml_model_get_catalog_checksum', 'anymode'
go

create procedure ml_model_register_schema 
    @schema_type	varchar( 32 ),
    @schema_owner	varchar( 256 ),
    @table_name		varchar( 256 ),
    @object_name	varchar( 256 ),
    @drop_stmt		varchar( 2000 ),
    @checksum		varchar( 256 ),
    @locked		tinyint
as
begin
    declare @db_checksum varchar(64)

    if @drop_stmt is null 
	select @drop_stmt = drop_stmt from ml_model_schema 
	    where schema_type = @schema_type and schema_owner = @schema_owner
		and table_name = @table_name and object_name = @object_name

    if @checksum is null
	select @checksum = checksum from ml_model_schema 
	    where schema_type = @schema_type and schema_owner = @schema_owner
		and table_name = @table_name and object_name = @object_name

    if @locked is null
	select @locked = locked from ml_model_schema 
	    where schema_type = @schema_type and schema_owner = @schema_owner
		and table_name = @table_name and object_name = @object_name

    exec ml_model_get_catalog_checksum @schema_type, @schema_owner, @table_name, @object_name, @db_checksum output

    if exists( select * from ml_model_schema where schema_type = @schema_type 
	    and schema_owner = @schema_owner and table_name = @table_name and object_name = @object_name )
	update ml_model_schema set drop_stmt = @drop_stmt, checksum = @checksum, db_checksum = @db_checksum, locked = @locked
	    where schema_type = @schema_type and schema_owner = @schema_owner
		and table_name = @table_name and object_name = @object_name
    else
	insert into ml_model_schema
	    ( schema_type, schema_owner, table_name, object_name, drop_stmt, checksum, db_checksum, locked )
	    values( @schema_type, @schema_owner, @table_name, @object_name, @drop_stmt, @checksum, @db_checksum, @locked )
end
go
exec sp_procxmode 'ml_model_register_schema', 'anymode'
go


create procedure ml_model_deregister_schema 
    @schema_type	varchar( 32 ),
    @schema_owner	varchar( 256 ),
    @table_name		varchar( 256 ),
    @object_name	varchar( 256 )
as    
begin
    if @schema_type = 'TABLE'
	delete from ml_model_schema 
	    where schema_type = @schema_type 
		and schema_owner = @schema_owner 
		and table_name = @table_name
    else
	delete from ml_model_schema 
	    where schema_type = @schema_type 
		and schema_owner = @schema_owner 
		and table_name = @table_name
		and object_name = @object_name
end
go
exec sp_procxmode 'ml_model_deregister_schema', 'anymode'
go


create procedure ml_model_register_schema_use
    @version		varchar( 128 ),
    @schema_type	varchar( 32 ),
    @schema_owner	varchar( 256 ),
    @table_name		varchar( 256 ),
    @object_name	varchar( 256 ),
    @checksum		varchar( 256 )
as
begin
    declare @version_id	integer
    
    select @version_id = version_id from ml_script_version 
	where name = @version
    if @version_id is null begin
	-- Insert to the ml_script_version
	select @version_id = max( version_id )+1 from ml_script_version
	if @version_id is null begin
	    -- No rows are currently in ml_script_version
	    set @version_id = 1
	end
	insert into ml_script_version ( version_id, name )
		values ( @version_id, @version )
    end

    if exists ( select * from ml_model_schema_use
	where version_id = @version_id and schema_type = @schema_type
	    and schema_owner = @schema_owner and table_name = @table_name
	    and object_name = @object_name ) 
	update ml_model_schema_use set checksum = @checksum
	    where version_id = @version_id and schema_type = @schema_type
		and schema_owner = @schema_owner and table_name = @table_name
		and object_name = @object_name
    else		
	insert into ml_model_schema_use
	    ( version_id, schema_type, schema_owner, table_name, object_name, checksum )
	    values( @version_id, @schema_type, @schema_owner, @table_name, @object_name, @checksum )
end
go
exec sp_procxmode 'ml_model_register_schema_use', 'anymode'
go


create procedure ml_model_mark_schema_verified
    @version		varchar( 128 ),
    @schema_type	varchar( 32 ),
    @schema_owner	varchar( 256 ),
    @table_name		varchar( 256 ),
    @object_name	varchar( 256 )
as
begin
    declare @checksum	    varchar( 256 )
    declare @version_id	    integer
    declare @locked	    tinyint

    select @version_id = version_id from ml_script_version 
	where name = @version

    select @checksum = checksum from ml_model_schema
	where schema_type = @schema_type and schema_owner = @schema_owner 
	    and table_name = @table_name and object_name = @object_name
	    
    if @checksum is not null
	update ml_model_schema_use set checksum = 'IGNORE'
	    where version_id = @version_id and schema_type = @schema_type and schema_owner = @schema_owner
		and table_name = @table_name and object_name = @object_name
    else begin
	select @checksum = checksum from ml_model_schema_use 
	    where version_id = @version_id and schema_type = @schema_type
		and schema_owner = @schema_owner and table_name = @table_name
		and object_name = @object_name
	select @locked = case when @schema_type = 'COLUMN' then 1 else 0 end
	exec ml_model_register_schema @schema_type, @schema_owner, @table_name, @object_name, 
	    '-- Not dropped during uninstall', @checksum, @locked
    end
end
go
exec sp_procxmode 'ml_model_mark_schema_verified', 'anymode'
go

create procedure ml_model_check_catalog(
    @schema_type	varchar( 32 ),
    @schema_owner	varchar( 256 ),
    @table_name		varchar( 256 ),
    @object_name	varchar( 256 ),
    @status		varchar( 32 ) output )
as
begin
    declare @checksum	      varchar(256)
    declare @orig_db_checksum varchar(64)
    declare @db_checksum     varchar(64)

    -- Return values
    -- 'UNUSED' - The requested schema isn't referenced by any ML meta-data
    -- 'MISSING' - The requested schema is not installed.
    -- 'MISMATCH' - The current schema doesn't match the ML meta-data
    -- 'UNVERIFIED' - A full schema comparison wasn't done, 
    --                generally we assume the schema is correct in this case
    -- 'INSTALLED' - The required schema is correctly installed.

    if ( @schema_type = 'TABLE'
	    and exists( select 1 from sysobjects so join sysusers su on so.uid = su.uid
		where so.name = @table_name and su.name = @schema_owner 
		    and so.type = 'U' ) )
	or ( @schema_type = 'TRIGGER'
	    and exists( select 1 from sysobjects tr 
		join sysobjects tb on (tr.id = tb.deltrig or tr.id = tb.instrig or tr.id = tb.updtrig)
		join sysusers su on tb.uid = su.uid
		where tb.name = @table_name and su.name = @schema_owner 
		    and tr.name = @object_name and tr.type = 'TR' and tb.type = 'U' ) )
	or ( @schema_type = 'INDEX'
	    and exists( SELECT 1 FROM sysindexes x
		join sysobjects t on x.id = t.id
		join sysusers u on u.uid = t.uid
		WHERE t.type = 'U' AND t.name = @table_name 
		    AND (x.name = @object_name or x.name = '"' + @object_name + '"' ) 
		    AND u.name = @schema_owner ) )
	or ( @schema_type = 'COLUMN' 
	    and exists( SELECT 1 FROM syscolumns sc 
		join sysobjects so on sc.id = so.id 
		join sysusers su on su.uid = so.uid
		WHERE so.type = 'U' and so.name = @table_name and sc.name = @object_name and su.name = @schema_owner ) ) 
	or ( @schema_type = 'PROCEDURE' 
	    and exists( SELECT 1 FROM sysobjects so 
		join sysusers su on su.uid = so.uid
		WHERE so.type = 'P' and so.name = @object_name and su.name = @schema_owner ) ) 
    begin
	-- The schema exists
	exec ml_model_get_catalog_checksum @schema_type, @schema_owner, @table_name, @object_name, @db_checksum output
	select @checksum = s.checksum, @orig_db_checksum = s.db_checksum from ml_model_schema s
		where s.schema_type = @schema_type and s.schema_owner = @schema_owner 
		    and s.table_name = @table_name and s.object_name = @object_name

	if @checksum is null begin
	    set @status = 'UNUSED'
	    return
	end

	if @orig_db_checksum is null or @db_checksum is null begin
	    set @status = 'UNVERIFIED'
	    return
	end

	if @orig_db_checksum = @db_checksum begin
	    set @status = 'INSTALLED'
	    return
	end

	set @status = 'MISMATCH'
	return
    end

    -- The schema does not exist
    set @status = 'MISSING'
end
go
exec sp_procxmode 'ml_model_check_catalog', 'anymode'
go

create procedure ml_model_check_schema (
    @version		varchar( 128 ),
    @schema_type	varchar( 32 ),
    @schema_owner	varchar( 256 ),
    @table_name		varchar( 256 ),
    @object_name	varchar( 256 ),
    @status		varchar( 32 ) output )
as
begin
    declare @db_status	 varchar(32)
    
    -- Return values
    -- 'UNUSED' - The requested schema isn't needed for this version.
    -- 'MISSING' - The required schema is not installed.
    -- 'MISMATCH' - The current schema doesn't match what is needed and must be replaced.
    -- 'UNVERIFIED' - The existing schema must be manually checked to see if it matches what is needed.
    -- 'INSTALLED' - The required schema is correctly installed.

    select @status = case when s.checksum is null then 'MISSING' else
	    case when u.checksum = 'IGNORE' or u.checksum = s.checksum then 'INSTALLED' else 'MISMATCH' end
	end 
    from ml_model_schema_use u
	join ml_script_version v on v.version_id = u.version_id 
	left outer join ml_model_schema s 
	    on s.schema_type = u.schema_type and s.schema_owner = u.schema_owner 
		and s.table_name = u.table_name and s.object_name = u.object_name
    where v.name = @version and u.schema_type = @schema_type and u.schema_owner = @schema_owner 
	and u.table_name = @table_name and u.object_name = @object_name
    if @status is null set @status = 'UNUSED'

    exec ml_model_check_catalog @schema_type, @schema_owner, @table_name, @object_name, @db_status output

    if @db_status = 'MISSING' begin
	set @status = 'MISSING'
	return
    end

    if @status = 'UNUSED' or @status = 'MISMATCH'
	return

    if @status = 'MISSING' begin
	-- Note, @db_status != 'MISSING'
	set @status = 'UNVERIFIED'
	return
    end

    -- @status = 'INSTALLED'
    if @db_status = 'MISMATCH' begin
	set @status = 'MISMATCH'
	return
    end

    -- If @db_status = 'UNVERIFIED' we are optimistic and assume it is correct
    set @status = 'INSTALLED'
end
go
exec sp_procxmode 'ml_model_check_schema', 'anymode'
go

create procedure ml_model_get_schema_action (
    @version		varchar( 128 ),
    @schema_type	varchar( 32 ),
    @schema_owner	varchar( 256 ),
    @table_name		varchar( 256 ),
    @object_name	varchar( 256 ),
    @upd_mode		varchar( 64 ),
    @action		varchar( 32 ) output )
as
begin
    declare @status	varchar(32)
    declare @locked	tinyint

    exec ml_model_check_schema @version, @schema_type, @schema_owner, @table_name, @object_name, @status output
    if @status = 'MISSING' begin
	if @schema_type = 'TRIGGER'
	    -- ASE can only support one ins/upd/del trigger per table so we need to find any 
	    -- conflicting triggers
	    and exists( select 1 from sysobjects tr
		join ml_model_schema_use u on
		    u.schema_type = @schema_type and u.schema_owner = @schema_owner
		    and u.table_name = @table_name and u.object_name = @object_name
		join sysobjects tb on 
		    tb.name = @table_name and tb.type = 'U'
		    and ( (u.checksum like '%INSERT%' and tr.id = tb.instrig)
		       or (u.checksum like '%UPDATE%' and tr.id = tb.updtrig)
		       or (u.checksum like '%DELETE%' and tr.id = tb.deltrig) )
		join sysusers su on tb.uid = su.uid and  su.name = @schema_owner
		where tr.name != @object_name and tr.type = 'TR' ) begin
	    set @action = 'SKIP'
	    return
	end

	set @action = 'CREATE'
	return
    end

    if @status = 'UNUSED' or @status = 'INSTALLED' or @upd_mode != 'OVERWRITE' or @schema_type = 'COLUMN' begin
	-- Preserve the existing schema
	-- Note, 'REPLACE' won't work for columns because the column is likely 
	--     in an index and the drop will fail.  If the status is 'MISMATCH' 
	--     then the column will need to be manually altered in the database.
	set @action = 'SKIP'
	return
    end

    if exists ( select locked from ml_model_schema
	    where schema_type = @schema_type and schema_owner = @schema_owner and table_name = @table_name 
		and object_name = @object_name and locked != 0 ) begin
	-- The schema is marked as locked, preserve it.
	set @action = 'SKIP'
	return
    end

    exec ml_model_check_catalog @schema_type, @schema_owner, @table_name, @object_name, @status output
    if @status = 'MISMATCH' begin
	-- The schema was modified since ML was deployed, we are careful not to destroy any schema
	-- that was not created by ML
	set @action = 'SKIP'
	return
    end

    -- The existing schema doesn't match what is needed so replace it.
    set @action = 'REPLACE'
end
go
exec sp_procxmode 'ml_model_get_schema_action', 'anymode'
go

create procedure ml_model_check_all_schema
as
begin
    declare @schema_owner	varchar( 256 )
    declare @table_name		varchar( 256 )
    declare @schema_type	varchar( 32 )
    declare @object_name	varchar( 256 )
    declare @locked		tinyint
    declare @version		varchar( 128 )
    declare @status		varchar( 128 )
    declare @overwrite_action	varchar( 128 )
    declare @preserve_action	varchar( 128 )

    declare crsr cursor for
	select 
	    case when s.schema_owner is null then u.schema_owner else s.schema_owner end schema_owner, 
	    case when s.table_name is null then u.table_name else s.table_name end table_name, 
	    case when s.schema_type is null then u.schema_type else s.schema_type end schema_type, 
	    case when s.object_name is null then u.object_name else s.object_name end object_name, 
	    s.locked, 
	    ver.name used_by
	from ml_model_schema s 
	    left outer join ml_model_schema_use u on
		u.schema_type = s.schema_type and u.schema_owner = s.schema_owner
		and u.table_name = s.table_name and u.object_name = s.object_name
	    left outer join ml_script_version ver on
		u.version_id = ver.version_id
	UNION
	select 
	    case when s.schema_owner is null then u.schema_owner else s.schema_owner end schema_owner, 
	    case when s.table_name is null then u.table_name else s.table_name end table_name, 
	    case when s.schema_type is null then u.schema_type else s.schema_type end schema_type, 
	    case when s.object_name is null then u.object_name else s.object_name end object_name, 
	    s.locked, 
	    ver.name used_by
	from ml_model_schema s 
	    right outer join ml_model_schema_use u on
		u.schema_type = s.schema_type and u.schema_owner = s.schema_owner
		and u.table_name = s.table_name and u.object_name = s.object_name
	    left outer join ml_script_version ver on
		u.version_id = ver.version_id

    delete from ml_model_schema_status
    
    open crsr
    while 1 = 1 begin
	fetch crsr into @schema_owner, @table_name, @schema_type, @object_name, @locked, @version
	if @@fetch_status != 0 break
	exec ml_model_check_schema @version, @schema_type, @schema_owner, @table_name, @object_name, @status output
	if @version is null begin
	    set @overwrite_action = null
	    set @preserve_action = null
	end else begin
	    exec ml_model_get_schema_action @version, @schema_type, @schema_owner, @table_name, @object_name, 'OVERWRITE', @overwrite_action output
	    exec ml_model_get_schema_action @version, @schema_type, @schema_owner, @table_name, @object_name, 'PRESERVE_EXISTING_SCHEMA', @preserve_action output
	end
	
	insert into ml_model_schema_status( schema_owner, table_name, schema_type, object_name, locked, used_by, status, overwrite_action, preserve_action )
	    values( @schema_owner, @table_name, @schema_type, @object_name, @locked, @version, @status, @overwrite_action, @preserve_action )
    end
    close crsr
    deallocate crsr

    select schema_owner, table_name, schema_type, object_name, locked, used_by, status, overwrite_action, preserve_action
	from ml_model_schema_status
	order by schema_owner, table_name, schema_type, object_name, used_by
end
go
exec sp_procxmode 'ml_model_check_all_schema', 'anymode'
go

create procedure ml_model_check_version_schema
    @version	varchar( 128 )
as
begin
    declare @schema_owner	varchar( 256 )
    declare @table_name		varchar( 256 )
    declare @schema_type	varchar( 32 )
    declare @object_name	varchar( 256 )
    declare @locked		tinyint
    declare @status		varchar( 128 )
    declare @overwrite_action	varchar( 128 )
    declare @preserve_action	varchar( 128 )

    declare crsr cursor for
	select u.schema_owner, u.table_name, u.schema_type, u.object_name, s.locked
	from ml_model_schema_use u join ml_script_version ver on u.version_id = ver.version_id
	    left outer join ml_model_schema s on
		u.schema_type = s.schema_type and u.schema_owner = s.schema_owner
		and u.table_name = s.table_name and u.object_name = s.object_name
	where ver.name = @version

    delete from ml_model_schema_status where used_by = @version

    open crsr
    while 1 = 1 begin
	fetch crsr into @schema_owner, @table_name, @schema_type, @object_name, @locked
	if @@fetch_status != 0 break
	exec ml_model_check_schema @version, @schema_type, @schema_owner, @table_name, @object_name, @status output
	exec ml_model_get_schema_action @version, @schema_type, @schema_owner, @table_name, @object_name, 'OVERWRITE', @overwrite_action output
	exec ml_model_get_schema_action @version, @schema_type, @schema_owner, @table_name, @object_name, 'PRESERVE_EXISTING_SCHEMA', @preserve_action output
	insert into ml_model_schema_status( schema_owner, table_name, schema_type, object_name, locked, used_by, status, overwrite_action, preserve_action )
	    values ( @schema_owner, @table_name, @schema_type, @object_name, @locked, @version, @status, @overwrite_action, @preserve_action )
    end
    close crsr
    deallocate crsr

    select schema_owner, table_name, schema_type, object_name, locked, status, overwrite_action, preserve_action
	from ml_model_schema_status
	where used_by = @version
	order by schema_owner, table_name, schema_type, object_name
end
go
exec sp_procxmode 'ml_model_check_version_schema', 'anymode'
go


create procedure ml_model_drop_unused_schema
as
begin
    declare @status	    varchar(32)
    declare @schema_type    varchar(32)
    declare @schema_owner   varchar(256)
    declare @object_name    varchar(256)
    declare @table_name     varchar(256)
    declare @qualified_table varchar(256)
    declare @drop_stmt	    varchar(2000)
    declare @drop_stmt2	    varchar(2000)

    declare drop_crsr cursor for
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
		end )

    open drop_crsr
    while 1 = 1 begin
	fetch drop_crsr into @schema_type, @schema_owner, @table_name, @object_name, @drop_stmt
	if @@fetch_status != 0 break

	exec ml_model_check_catalog @schema_type, @schema_owner, @table_name, @object_name, @status output
	-- We don't drop any schema modified since ML was deployed.
	if @status != 'MISMATCH' and @status != 'MISSING' begin
	    exec( @drop_stmt )
	end 
	exec ml_model_deregister_schema @schema_type, @schema_owner, @table_name, @object_name
    end
    close drop_crsr
    deallocate drop_crsr
end
go
exec sp_procxmode 'ml_model_drop_unused_schema', 'unchained'
go


create procedure ml_model_drop
    @version	    varchar( 128 )
as
begin
    declare @version_id    integer

    select @version_id = version_id from ml_script_version 
	where name = @version

    delete from ml_model_schema_use where version_id = @version_id
    delete from ml_column where version_id = @version_id
    delete from ml_connection_script where version_id = @version_id
    delete from ml_table_script where version_id = @version_id
    delete from ml_script_version where version_id = @version_id
    exec ml_model_drop_unused_schema
end
go
exec sp_procxmode 'ml_model_drop', 'unchained'
go


--
-- QAnywhere Upgrades
--

exec ml_add_property 'SIS', 'Notifier(QAnyNotifier_client)', 'gui', null
go
exec ml_add_property 'SIS', 'Notifier(QAnyNotifier_client)', 'enable', null
go
exec ml_add_property 'SIS', 'Notifier(QAnyNotifier_client)', 'poll_every', null
go
exec ml_add_property 'SIS', 'Notifier(QAnyNotifier_client)', 'request_cursor', null
go
exec ml_add_property 'SIS', 'Notifier(QAnyNotifier_client)', 'request_delete', null
go

drop procedure ml_qa_add_delivery
go
drop trigger ml_qa_delivery_trigger
go
drop procedure ml_qa_upsert_global_prop
go
drop procedure ml_qa_stage_status_from_client
go
drop procedure ml_qa_staged_status_for_client
go
drop procedure ml_qa_handle_error
go

drop view ml_qa_messages
go

drop table ml_qa_global_props
go
drop table ml_qa_status_history
go
drop table ml_qa_repository_props
go
drop table ml_qa_delivery
go
drop table ml_qa_repository
go
drop table ml_qa_notifications
go
drop table ml_qa_repository_staging
go
drop table ml_qa_status_staging
go

drop view ml_qa_messages_archive
go

drop table ml_qa_delivery_archive
go
drop table ml_qa_status_history_archive
go
drop table ml_qa_repository_props_archive
go
drop table ml_qa_repository_archive
go


---------------------------------------------------
--   Schema for ML Remote administration
---------------------------------------------------

create table ml_ra_schema_name (
    schema_name                     varchar( 128 ) not null,
    remote_type                    varchar(1) not null,
    last_modified                  datetime not null,
    description		           varchar( 2048 ) null,
    primary key( schema_name ) 
)
go

create table ml_ra_agent (
    aid                            integer identity,
    agent_id                       varchar( 128 ) not null unique,
    taskdb_rid                     integer null,
    primary key( aid ),
    foreign key( taskdb_rid ) references ml_database ( rid )
)
go
create index tdb_rid on ml_ra_agent( taskdb_rid ) 
go

create table ml_ra_task(
    task_id                        numeric( 20 ) identity,
    task_name                      varchar( 128 ) not null unique,
    schema_name		           varchar( 128 ) null,
    max_running_time               integer null,
    max_number_of_attempts         integer null,
    delay_between_attempts         integer null,
    flags                          numeric( 20 ) not null,
    cond                           text null,
    remote_event                   text null,
    random_delay_interval	   integer default 0 not null,
    primary key( task_id ), 
    foreign key( schema_name ) references ml_ra_schema_name( schema_name )
)
go

create table ml_ra_deployed_task (
    task_instance_id               numeric( 20 ) identity,
    aid                            integer not null,
    task_id                        numeric( 20 ) not null,
    assignment_time                datetime default getdate() not null,
    state                          varchar( 4 ) default 'P' not null,
    previous_exec_count            numeric( 20 ) default 0 not null,
    previous_error_count           numeric( 20 ) default 0 not null,
    previous_attempt_count         numeric( 20 ) default 0 not null,
    reported_exec_count            numeric( 20 ) default 0 not null,
    reported_error_count           numeric( 20 ) default 0 not null,
    reported_attempt_count         numeric( 20 ) default 0 not null,
    last_modified                  datetime not null,
    unique( aid, task_id ),
    primary key( task_instance_id ), 
    foreign key( aid ) references ml_ra_agent( aid ),
    foreign key( task_id ) references ml_ra_task( task_id )
)
go
create index dt_tid_idx on ml_ra_deployed_task( task_id )
go

create table ml_ra_task_command (
    task_id                        numeric( 20 ) not null,
    command_number                 integer not null,
    flags                          numeric( 20 ) default 0 not null,
    action_type                    varchar( 4 ) not null,
    action_parm                    text not null,
    primary key( task_id, command_number ),
    foreign key( task_id ) references ml_ra_task( task_id )
)
go

create table ml_ra_event (
    event_id                       numeric( 20 ) identity,
    event_class                    varchar( 4 ) not null,
    event_type                     varchar( 8 ) not null,
    aid				   integer null,
    task_id			   numeric(20),
    command_number                 integer null,
    run_number                     numeric( 20 ) null,
    duration                       integer null,
    event_time                     datetime not null,
    event_received                 datetime default getdate() not null,
    result_code                    numeric( 20 ) null,
    result_text                    text null,
    primary key( event_id ) 
)
go
create index ev_tn_idx on ml_ra_event( task_id )
go
create index ev_time_idx on ml_ra_event( event_received )
go
create index ev_agent_idx on ml_ra_event( aid )
go

create table ml_ra_event_staging (
    taskdb_rid			   integer not null,
    remote_event_id                numeric( 20 ) not null,
    event_class                    varchar( 4 ) not null,
    event_type                     varchar( 8 ) not null,
    task_instance_id               numeric( 20 ) null,
    command_number                 integer null,
    run_number                     numeric( 20 ) null,
    duration                       integer null,
    event_time                     datetime not null,
    result_code                    numeric( 20 ) null,
    result_text                    text null,
    primary key( taskdb_rid, remote_event_id ) 
)
go
create index evs_type_idx on ml_ra_event_staging( event_type )
go

create table ml_ra_notify (
    agent_poll_key                 varchar( 128 ) not null,
    task_instance_id               numeric( 20 ) not null,
    last_modified                  datetime not null,
    primary key( agent_poll_key, task_instance_id ),
    foreign key( agent_poll_key ) references ml_ra_agent( agent_id )
)
go

create table ml_ra_task_property (
    task_id                        numeric( 20 ) not null,
    property_name                  varchar( 128 ) not null,
    last_modified                  datetime not null,
    property_value                 text null,
    primary key( property_name, task_id ), 
    foreign key( task_id ) references ml_ra_task( task_id )
)
go

create table ml_ra_task_command_property (
    task_id                        numeric( 20 ) not null,
    command_number                 integer not null,
    property_name                  varchar( 128 ) not null,
    property_value                 varchar( 2048 ) null,
    last_modified                  datetime not null,
    primary key( task_id, command_number, property_name ), 
    foreign key( task_id, command_number ) references ml_ra_task_command( task_id, command_number )
)
go

create table ml_ra_managed_remote (
    mrid			   integer identity,
    remote_id                      varchar(128) null,
    aid                            integer not null,
    schema_name			   varchar( 128 ) not null,
    conn_str		           varchar( 2048 ) not null,
    last_modified                  datetime not null,
    unique( aid, schema_name ),
    primary key( mrid ),
    foreign key( aid ) references ml_ra_agent( aid ),
    foreign key( schema_name ) references ml_ra_schema_name( schema_name )
)
go

create table ml_ra_agent_property (
    aid                            integer not null,
    property_name                  varchar( 128 ) not null,
    property_value                 varchar( 2048 ) null,
    last_modified                  datetime not null,
    primary key( aid, property_name ),
    foreign key( aid ) references ml_ra_agent( aid )
)
go

create table ml_ra_agent_staging (
    taskdb_rid			   integer not null,
    property_name                  varchar( 128 ) not null,
    property_value                 varchar( 2048 ) null,
    primary key( taskdb_rid, property_name ) 
)
go

-----------------------------------------------------------------
-- Stored procedures for Tasks
-----------------------------------------------------------------

-- Assign a remote task to a specific agent.

create procedure ml_ra_assign_task
    @agent_id	varchar( 128 ),  
    @task_name	varchar( 128 )
as
begin
    declare @task_id		numeric( 20 )
    declare @task_instance_id	numeric( 20 )
    declare @old_state		varchar( 4 )
    declare @aid		integer
    declare @rid		integer

    select @task_id = task_id
	from ml_ra_task where task_name = @task_name
    if @task_id is null begin
	exec sp_addmessage 99001, 'bad task name'
	raiserror 99001
	exec sp_dropmessage 99001
	return
    end

    select @aid = aid from ml_ra_agent where agent_id = @agent_id
    if @aid is null begin 
	exec sp_addmessage 99002, 'bad agent id'
	raiserror 99002
	exec sp_dropmessage 99002
	return
    end

    select @old_state = state, @task_instance_id = task_instance_id
	from ml_ra_deployed_task where task_id = @task_id and aid = @aid
    if @task_instance_id is null begin
	insert into ml_ra_deployed_task( aid, task_id, last_modified ) 
	    values ( @aid, @task_id, getdate() )
    end
    else if @old_state != 'A' and @old_state != 'P' begin
	-- Re-activate the task
	update ml_ra_deployed_task 
	    set state = 'P',
	    previous_exec_count = reported_exec_count + previous_exec_count,
	    previous_error_count = reported_error_count + previous_error_count,
	    previous_attempt_count = reported_attempt_count + previous_attempt_count,
	    reported_exec_count = 0,
	    reported_error_count = 0,
	    reported_attempt_count = 0,
	    last_modified = getdate()
	where task_instance_id = @task_instance_id
    end
    -- if the task is already active then do nothing 
end
go

create procedure ml_ra_int_cancel_notification
    @agent_id		varchar( 128 ),
    @task_instance_id	numeric( 20 ),
    @request_time	datetime 
as
begin
    delete from ml_ra_notify
	where agent_poll_key = @agent_id
	    and task_instance_id = @task_instance_id
	    and last_modified <= @request_time
end
go

create procedure ml_ra_cancel_notification
    @agent_id	varchar( 128 ),
    @task_name	varchar( 128 )
as
begin
    declare @task_instance_id	numeric( 20 )
    declare @ts			datetime

    select @task_instance_id = task_instance_id
	from ml_ra_agent
	    join ml_ra_deployed_task on ml_ra_deployed_task.aid = ml_ra_agent.aid
	    join ml_ra_task on ml_ra_deployed_task.task_id = ml_ra_task.task_id
	where agent_id = @agent_id 
	    and task_name = @task_name

    select @ts = getdate()
    exec ml_ra_int_cancel_notification @agent_id, @task_instance_id, @ts
end
go

create procedure ml_ra_cancel_task_instance
    @agent_id	varchar( 128 ), 
    @task_name	varchar( 128 )
as
begin
    declare @task_id		numeric( 20 )
    declare @aid		integer

    select @task_id = task_id from ml_ra_task where task_name = @task_name
    select @aid = ml_ra_agent.aid from ml_ra_agent where agent_id = @agent_id
    update ml_ra_deployed_task set state = 'CP', last_modified = getdate()
	where aid = @aid and task_id = @task_id 
	    and ( state = 'A' or state = 'P' )
    if @@rowcount = 0 begin
	exec sp_addmessage 99001, 'bad task instance'
	raiserror 99001
	exec sp_dropmessage 99001
	return
    end
    exec ml_ra_cancel_notification @agent_id, @task_name
end
go

-- If error is raised then caller must rollback

create procedure ml_ra_delete_task
    @task_name	varchar( 128 ) 
as
begin
    declare @task_id		numeric( 20 )

    select @task_id = task_id from ml_ra_task where task_name = @task_name
    if @task_id is null begin
	exec sp_addmessage 99001, 'bad task name'
	raiserror 99001
	exec sp_dropmessage 99001
    end

    -- Only delete inactive instances, operation
    -- will fail if active instances exist.
    delete from ml_ra_deployed_task where task_id = @task_id 
	and ( state != 'A' and state != 'P' and state != 'CP' )
    delete from ml_ra_task_command_property where task_id = @task_id	
    delete from ml_ra_task_command where task_id = @task_id	
    delete from ml_ra_task_property where task_id = @task_id	
    delete from ml_ra_task where task_id = @task_id	
end
go

-- result contains a row for each deployed instance of every task

create procedure ml_ra_get_task_status
    @agent_id	varchar( 128 ),
    @task_name	varchar( 128 ) 
as
begin
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
	( @agent_id is null or a.agent_id = @agent_id )
	and ( @task_name is null or t.task_name = @task_name )
    order by agent_id, task_name
end
go

create procedure ml_ra_notify_agent_sync
    @agent_id	varchar( 128 )
as
begin
    declare @aid integer
    
    select @aid = aid from ml_ra_agent where agent_id = @agent_id
    if @aid is null begin
	return
    end

    if exists ( select * from ml_ra_notify where
		    agent_poll_key = @agent_id and task_instance_id = -1 )
	update ml_ra_notify set last_modified = getdate()
	where agent_poll_key = @agent_id and task_instance_id = -1
    else
	insert into ml_ra_notify( agent_poll_key, task_instance_id,
				  last_modified )
	    values( @agent_id, -1, getdate() ) 
end
go

create procedure ml_ra_notify_task
    @agent_id	varchar( 128 ), 
    @task_name	varchar( 128 ) 
as
begin
    declare @task_instance_id	numeric( 20 )

    select @task_instance_id = task_instance_id
	from ml_ra_agent
	    join ml_ra_deployed_task on ml_ra_deployed_task.aid = ml_ra_agent.aid
	    join ml_ra_task on ml_ra_deployed_task.task_id = ml_ra_task.task_id
	where agent_id = @agent_id 
	    and task_name = @task_name

    if exists (select * from ml_ra_notify where 
		    agent_poll_key = @agent_id and
		    task_instance_id = @task_instance_id) 
	update ml_ra_notify set last_modified = getdate()
	    where agent_poll_key = @agent_id and
		task_instance_id = @task_instance_id
    else
	insert into ml_ra_notify( agent_poll_key, task_instance_id,
				  last_modified )
	    values( @agent_id, @task_instance_id, getdate() ) 
end
go

create procedure ml_ra_get_latest_event_id
    @event_id	numeric( 20 ) out 
as
begin
    select @event_id = max( event_id ) from ml_ra_event
end
go

create procedure ml_ra_get_agent_events
    @start_at_event_id		numeric( 20 ), 
    @max_events_to_fetch	integer
as
begin
    if @max_events_to_fetch > 0
        set rowcount @max_events_to_fetch
    select 
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
	event_id >= @start_at_event_id
    order by event_id
    set rowcount 0
end
go

create procedure ml_ra_get_task_results 
    @agent_id	varchar( 128 ), 
    @task_name	varchar( 128 ),
    @run_number	integer
as
begin    
    declare @aid integer
    declare @task_id bigint
    declare @remote_id varchar(128)

    select @aid = aid from ml_ra_agent where agent_id = @agent_id
    select @task_id = task_id, @remote_id = remote_id from ml_ra_task t
	left outer join ml_ra_managed_remote mr 
	    on mr.schema_name = t.schema_name and mr.aid = @aid
	where task_name = @task_name

    if @run_number is null begin
	-- get the latest run
	select @run_number = max( run_number ) from ml_ra_event
	    where ml_ra_event.aid = @aid and
		ml_ra_event.task_id = @task_id
    end

    select 
	event_id, 
	event_class, 
	event_type,
	@agent_id, 
	@remote_id,
	@task_name,
	command_number,
	run_number,
	duration,
	event_time, 
	event_received,
	result_code, 
	result_text
     from ml_ra_event e where
	e.aid = @aid and e.task_id = @task_id and e.run_number = @run_number
    order by event_id
end
go


-- Maintenance functions ----------------------------------

create procedure ml_ra_get_agent_ids
as
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
    order by agent_id
end
go

create procedure ml_ra_get_remote_ids
as
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
	left outer join ml_ra_agent_staging s on s.taskdb_rid = ml_database.rid
	    and property_name = 'agent_id'
    where property_value is null
    order by ml_database.remote_id
end
go

create procedure ml_ra_set_agent_property
    @agent_id		varchar( 128 ),
    @property_name	varchar( 128 ),
    @property_value	varchar( 2048 )
as
begin
    declare @aid		integer
    declare @server_interval	integer
    declare @old_agent_interval integer
    declare @new_agent_interval integer
    declare @autoset		varchar(3)
    declare @temp		varchar(128)

    select @aid = aid from ml_ra_agent where agent_id = @agent_id
   
    if @property_name = 'lwp_freq' begin
	select @autoset = cast( property_value as varchar(3) ) from ml_property where 
	    component_name = 'SIRT'
	    and property_set_name = 'RTNotifier(RTNotifier1)'
	    and property_name = 'autoset_poll_every'
	if @autoset = 'yes' begin
	    select @server_interval = cast( cast( property_value as varchar(128) ) as integer ) from ml_property where 
		component_name = 'SIRT'
		and property_set_name = 'RTNotifier(RTNotifier1)'
		and property_name = 'poll_every'
	    set @new_agent_interval = cast( @property_value as integer )
	    if @new_agent_interval < @server_interval begin
		exec ml_add_property 'SIRT', 'RTNotifier(RTNotifier1)', 'poll_every', @property_value
	    end else if @new_agent_interval > @server_interval begin
		select @old_agent_interval = cast( property_value as integer ) from ml_ra_agent_property where
		    aid = @aid
		    and property_name = 'lwp_freq'
		if @new_agent_interval > @old_agent_interval and @old_agent_interval <= @server_interval begin
		    -- This agents interval is increasing, check if server interval should increase too
		    if not exists( select * from ml_ra_agent_property where property_name = 'lwp_freq'
			and cast(property_value as integer) <= @old_agent_interval
			and aid != @aid ) begin
			-- Need to compute the new server interval
			select @server_interval = min( cast( property_value as integer ) ) from ml_ra_agent_property 
			    where property_name = 'lwp_freq' and aid != @aid
			if @server_interval is null begin
			    set @server_interval = @new_agent_interval
			end 
			set @temp = cast( @server_interval as varchar(20) )
			exec ml_add_property 'SIRT', 'RTNotifier(RTNotifier1)', 'poll_every', @temp
		    end
		end
	    end
	end
    end

    if exists (select * from ml_ra_agent_property where
		    aid = @aid and property_name = @property_name)
	update ml_ra_agent_property
	    set property_value = @property_value,
		last_modified = getdate()
	    where aid = @aid and property_name = @property_name
    else
	insert into ml_ra_agent_property( aid, property_name,
					  property_value, last_modified )
	    values( @aid, @property_name, @property_value, getdate() )
end
go

-- If error is raised then caller must rollback

create procedure ml_ra_clone_agent_properties
    @dst_agent_id	varchar( 128 ),
    @src_agent_id	varchar( 128 )
as
begin
    declare @dst_aid	integer
    declare @src_aid	integer

    select @dst_aid = aid from ml_ra_agent where agent_id = @dst_agent_id
    select @src_aid = aid from ml_ra_agent where agent_id = @src_agent_id
    if @src_aid is null begin
	exec sp_addmessage 99001, 'bad src'
	raiserror 99001
	exec sp_dropmessage 99001
	return
    end

    delete from ml_ra_agent_property
	where aid = @dst_aid
	    and property_name != 'agent_id'
	    and property_name not like( 'ml[_]ra[_]%' )

    insert into ml_ra_agent_property( aid, property_name, property_value, last_modified )
	select @dst_aid, src.property_name, src.property_value, getdate() 
	from ml_ra_agent_property src 
	where src.aid = @src_aid 
	    and property_name != 'agent_id' 
	    and property_name not like( 'ml[_]ra[_]%' )
end
go

create procedure ml_ra_get_agent_properties
    @agent_id	varchar( 128 )
as
begin
    declare @aid integer
    
    select @aid = aid from ml_ra_agent where agent_id = @agent_id
    select property_name, property_value, last_modified from ml_ra_agent_property 
	where aid = @aid
	    and property_name != 'agent_id'
	    and property_name not like( 'ml[_]ra[_]%' )
	order by property_name
end
go

-- If error is raised then caller must rollback

create procedure ml_ra_add_agent_id
    @agent_id	varchar( 128 )
as
begin
    declare @aid integer

    insert into ml_ra_agent( agent_id ) values ( @agent_id )
    if @@error != 0 begin return end

    select @aid = @@identity
    insert into ml_ra_event( event_class, event_type, aid, event_time ) 
	values( 'I', 'ANEW', @aid, getdate() )
    exec ml_ra_set_agent_property @agent_id, 'agent_id', @agent_id 
    exec ml_ra_set_agent_property @agent_id, 'max_taskdb_sync_interval', '86400'
    exec ml_ra_set_agent_property @agent_id, 'lwp_freq', '900'
    exec ml_ra_set_agent_property @agent_id, 'agent_id_status', 'OK' 
end
go

-- If error is raised then caller must rollback

create procedure ml_ra_manage_remote_db
    @agent_id		varchar( 128 ), 
    @schema_name	varchar( 128 ),
    @conn_str		varchar( 2048 )
as
begin
    declare @aid integer
    declare @ldt datetime

    select @aid = aid, @ldt = last_download_time from 
	ml_ra_agent left outer join ml_subscription on taskdb_rid = rid
    where agent_id = @agent_id

    insert into ml_ra_managed_remote(aid, remote_id, schema_name, conn_str, last_modified ) 
	values( @aid, null, @schema_name, @conn_str, getdate() )
	
    update ml_ra_deployed_task set state = 'A' 
	where aid = @aid and state = 'P' and last_modified < @ldt
	    and exists( select * from ml_ra_task t where t.task_id = ml_ra_deployed_task.task_id and t.schema_name = @schema_name )
end
go

-- If error is raised then caller must rollback

create procedure ml_ra_unmanage_remote_db
    @agent_id		varchar( 128 ),
    @schema_name	varchar( 128 )
as
begin
    declare @aid		integer
    declare @has_tasks		integer

    select @aid = aid from ml_ra_agent where agent_id = @agent_id

    if exists( select * from ml_ra_deployed_task dt join ml_ra_task t
		    on dt.task_id = t.task_id
		    where dt.aid = @aid and
			t.schema_name = @schema_name
			and (state = 'A' or state = 'P' or state = 'CP') ) 
	select @has_tasks = 1
    else
	select @has_tasks = 0

    if @has_tasks = 1 begin
	exec sp_addmessage 99001, 'has active tasks'
	raiserror 99001
	exec sp_dropmessage 99001
	return
    end

    delete from ml_ra_deployed_task
	where aid = @aid and state != 'A' and state != 'P' and state != 'CP'
	    and exists( select * from ml_ra_task where ml_ra_task.task_id = ml_ra_deployed_task.task_id
		and ml_ra_task.schema_name = @schema_name )
    delete from ml_ra_managed_remote where aid = @aid and schema_name = @schema_name
end
go

-- If error is raised then caller must rollback

create procedure ml_ra_delete_agent_id
    @agent_id		varchar( 128 )
as
begin
    declare @aid		integer
    declare @taskdb_rid		integer
    declare @next_taskdb_rid	integer
    declare @taskdb_remote_id	    varchar( 128 )
    declare @next_taskdb_remote_id  varchar( 128 )
    
    declare taskdb_crsr cursor for
	select taskdb_rid, remote_id from ml_ra_agent_staging
	    join ml_database on ml_database.rid = taskdb_rid	
	    where property_name = 'agent_id' and property_value = @agent_id
    
    select @aid = aid, @taskdb_rid = taskdb_rid
	from ml_ra_agent where agent_id = @agent_id
    if @aid is null begin
	exec sp_addmessage 99001, 'bad agent id'
	raiserror 99001
	exec sp_dropmessage 99001
	return
    end

    exec ml_ra_set_agent_property @agent_id, 'lwp_freq', '2147483647' 

    -- Delete all dependent rows
    delete from ml_ra_agent_property where aid = @aid
    delete from ml_ra_deployed_task where aid = @aid
    delete from ml_ra_notify where agent_poll_key = @agent_id
    delete from ml_ra_managed_remote where aid = @aid

    -- Delete the agent
    delete from ml_ra_agent where aid = @aid

    -- Clean up any taskdbs that were associated with this agent_id
    open taskdb_crsr
    fetch taskdb_crsr into @taskdb_rid, @taskdb_remote_id
    if @@sqlstatus = 0 begin
	while 1 = 1 begin
	    fetch taskdb_crsr into @next_taskdb_rid, @next_taskdb_remote_id
	    if @@sqlstatus != 0 begin
		delete from ml_ra_event_staging where taskdb_rid = @taskdb_rid
		delete from ml_ra_agent_staging where taskdb_rid = @taskdb_rid
		exec ml_delete_remote_id @taskdb_remote_id
		break
	    end
	    delete from ml_ra_event_staging where taskdb_rid = @taskdb_rid
	    delete from ml_ra_agent_staging where taskdb_rid = @taskdb_rid
	    exec ml_delete_remote_id @taskdb_remote_id
	    set @taskdb_rid = @next_taskdb_rid
	    set @taskdb_remote_id = @next_taskdb_remote_id
	end 
    end
    close taskdb_crsr
end
go

create procedure ml_ra_int_move_events
    @aid	    integer,	
    @taskdb_rid	    integer	
as
begin
    -- Copy events into ml_ra_event from staging table
    insert into ml_ra_event( event_class, event_type, aid, task_id,
			     command_number, run_number, duration, event_time,
			     event_received, result_code, result_text )
	select event_class, event_type, @aid, dt.task_id, command_number,
	       run_number, duration, event_time, getdate(), result_code,
	       result_text
	    from ml_ra_event_staging es
		left outer join ml_ra_deployed_task dt on dt.task_instance_id = es.task_instance_id
	    where es.taskdb_rid = @taskdb_rid
	    order by remote_event_id

    -- Clean up staged values
    delete from ml_ra_event_staging where taskdb_rid = @taskdb_rid
end
go

create procedure ml_ra_delete_events_before
    @delete_rows_older_than	datetime
as
begin
    delete from ml_ra_event where event_received <= @delete_rows_older_than
end
go

create procedure ml_ra_get_orphan_taskdbs
as
begin
    select remote_id,
	property_value,
	( select max( last_upload_time ) from ml_subscription mlsb where mlsb.rid = ml_database.rid ) 
    from ml_database 
	left outer join ml_ra_agent agent on agent.taskdb_rid = rid
	left outer join ml_ra_agent_staging s on s.taskdb_rid = rid 
	    and property_name = 'agent_id'
    where property_value is not null and agent_id is null
    order by remote_id
end
go

-- If error is raised then caller must rollback

create procedure ml_ra_reassign_taskdb
    @taskdb_remote_id	varchar( 128 ),
    @new_agent_id	varchar( 128 )
as
begin
    declare @other_taskdb_rid	integer
    declare @taskdb_rid		integer
    declare @other_agent_aid	integer
    declare @old_agent_id	varchar( 128 )
    declare @new_aid		integer

    select @taskdb_rid = rid from ml_database where remote_id = @taskdb_remote_id
    if @taskdb_rid is null begin
	exec sp_addmessage 99001, 'bad remote'
	raiserror 99001
	exec sp_dropmessage 99001
	return
    end

    select @old_agent_id = property_value from ml_ra_agent_staging where
	taskdb_rid = @taskdb_rid and property_name = 'agent_id'
    if @old_agent_id is null begin
	exec sp_addmessage 99001, 'bad remote'
	raiserror 99001
	exec sp_dropmessage 99001
	return
    end

    select @other_taskdb_rid = count(*) from ml_ra_agent
	where agent_id = @new_agent_id
    if @other_taskdb_rid = 0 begin
	exec ml_ra_add_agent_id @new_agent_id
    end
    -- if @other_taskdb_rid is not null then it becomes a new orphan taskdb

    -- If the taskdb isn't already orphaned then break the link with its original agent_id
    update ml_ra_agent set taskdb_rid = null where taskdb_rid = @taskdb_rid

    update ml_ra_agent_staging set property_value = @new_agent_id
	where taskdb_rid = @taskdb_rid
	    and property_name = 'agent_id'

    -- Preserve any events that have been uploaded
    -- Note, no task state is updated here, these
    -- events are stale and may no longer apply.
    select @new_aid = aid from ml_ra_agent where agent_id = @new_agent_id
    exec ml_ra_int_move_events @new_aid, @taskdb_rid
    if @@error != 0 begin return end

    -- The next time the agent syncs it will receive its new agent_id
    exec ml_ra_notify_agent_sync @old_agent_id
end
go

-----------------------------------------------------------------
-- Synchronization scripts for the remote agent's task database
-- Note, there is no authenticate user script here, this will need
-- to be provided by the user.
-----------------------------------------------------------------

create procedure ml_ra_ss_end_upload 
    @taskdb_remote_id	varchar( 128 )
as
begin
    declare @taskdb_rid		integer
    declare @consdb_taskdb_rid	integer
    declare @consdb_taskdb_remote_id varchar( 128 )
    declare @agent_id		varchar( 128 )
    declare @provided_id	varchar( 128 )
    declare @old_machine_name	varchar( 128 )
    declare @new_machine_name	varchar( 128 )
    declare @aid		integer
    declare @used		varchar( 128 )
    declare @name		varchar( 128 )
    declare @value		varchar( 2048 )
    declare @old_value		varchar( 2048 )
    declare @schema_name	varchar( 128 )

    declare @task_instance_id	numeric( 20 )
    declare @result_code	numeric( 20 )
    declare @event_type		varchar(8)

    select @taskdb_rid = rid, @agent_id = agent_id, @aid = aid 
	from ml_database left outer join ml_ra_agent on taskdb_rid = rid 
	where remote_id = @taskdb_remote_id

    if @agent_id is null begin 
	-- This taskdb isn't linked to an agent_id in the consolidated yet
	delete from ml_ra_agent_staging where taskdb_rid = @taskdb_rid and property_name = 'agent_id_status'
	select @provided_id = property_value from ml_ra_agent_staging 
	    where taskdb_rid = @taskdb_rid and property_name = 'agent_id'
	if @provided_id is null begin
	    -- Agent failed to provide an agent_id
	    insert into ml_ra_agent_staging( taskdb_rid,
		    property_name, property_value )
		    values( @taskdb_rid, 'agent_id_status', 'RESET' )
	    return
	end
	    
	select @consdb_taskdb_rid = taskdb_rid, @aid = aid
	    from ml_ra_agent where agent_id = @provided_id
	if @consdb_taskdb_rid is not null begin
	    -- We have 2 remote task databases using the same agent_id.
	    -- Attempt to determine if its a reset of an agent or 2 separate 
	    -- agents conflicting with each other.
	    select @consdb_taskdb_remote_id = remote_id
		from ml_database where rid = @consdb_taskdb_rid
	    select @old_machine_name = substring( @consdb_taskdb_remote_id,
				7, datalength(@consdb_taskdb_remote_id) - 43 )
	    select @new_machine_name = substring( @taskdb_remote_id,
				7, datalength(@taskdb_remote_id) - 43 )
		
	    if @old_machine_name != @new_machine_name begin
		-- There are 2 agents with conflicting agent_ids
		-- This taskdb will not be allowed to download tasks.
		insert into ml_ra_event(event_class, event_type, aid, event_time, result_text ) 
		    values( 'E', 'ADUP', @aid, getdate(), @taskdb_remote_id )
		insert into ml_ra_agent_staging( taskdb_rid,
			property_name, property_value )
			values( @taskdb_rid, 'agent_id_status', 'DUP' )
		return
	    end -- Otherwise, we allow replacement of the taskdb
	end	    

	set @agent_id = @provided_id
	if @aid is null begin
	    -- We have a new agent_id
	    exec ml_ra_add_agent_id @agent_id
	    select @aid = aid from ml_ra_agent where agent_id = @agent_id
	end

	select @used = property_value from ml_ra_agent_staging 
	    where taskdb_rid = @taskdb_rid and property_name = 'ml_ra_used'
	if @used is not null begin
	    insert into ml_ra_agent_staging( taskdb_rid,
		    property_name, property_value )
		    values( @taskdb_rid, 'agent_id_status', 'RESET' )
	    -- Preserve any events that may have been uploaded
	    -- Note, no task state is updated here, these
	    -- events could be stale and may no longer apply.
	    exec ml_ra_int_move_events @aid, @taskdb_rid
	    return
	end
	else begin
	    insert into ml_ra_agent_staging( taskdb_rid, property_name, property_value )
		values( @taskdb_rid, 'ml_ra_used', '1' )
	end

	-- Store the link between this agent_id and remote_id
	update ml_ra_agent set taskdb_rid = @taskdb_rid where agent_id = @agent_id

	select @used = property_value from ml_ra_agent_property
	    where aid = @aid and property_name = 'ml_ra_used'
	if @used is null begin
	    -- This is the first taskdb for an agent
	    insert into ml_ra_event(event_class, event_type, aid, event_time ) 
		values( 'I', 'AFIRST', @aid, getdate() )
	    insert into ml_ra_agent_property( aid, property_name, property_value, last_modified )
		values( @aid, 'ml_ra_used', '1', getdate() )
	end
	else begin
	    -- A new taskdb is taking over
	    insert into ml_ra_event(event_class, event_type, aid, event_time, result_text ) 
		values( 'I', 'ARESET', @aid, getdate(), @consdb_taskdb_remote_id )

	    update ml_ra_deployed_task set
		state = ( case state 
		    when 'A' then 'P'
		    when 'CP' then 'C'
		    else state end ),
		previous_exec_count = reported_exec_count + previous_exec_count,
		previous_error_count = reported_error_count + previous_error_count,
		previous_attempt_count = reported_attempt_count + previous_attempt_count,
		reported_exec_count = 0,
		reported_error_count = 0,
		reported_attempt_count = 0,
		last_modified = getdate()
	    where aid = @aid
	end
    end

    begin
	-- Update the status of deployed tasks
	declare event_crsr cursor for 
	    select event_type, result_code, convert( varchar(128), result_text ), task_instance_id from ml_ra_event_staging
	    where taskdb_rid = @taskdb_rid order by remote_event_id
	open event_crsr
	while 1 = 1 begin
	    fetch event_crsr into @event_type, @result_code, @value, @task_instance_id
	    if @@sqlstatus != 0 break

	    if @event_type like 'TI%' or @event_type like 'TF%' begin
		update ml_ra_deployed_task  
		    set reported_exec_count = case when @event_type = 'TIE' then @result_code else reported_exec_count end,
			reported_error_count = case when @event_type = 'TIF' then @result_code else reported_error_count end,
			reported_attempt_count = case when @event_type = 'TIA' then @result_code else reported_attempt_count end,
			state = case when @event_type like('TF%') then substring( @event_type, 3, datalength( @event_type ) - 2 ) else 
			    state end 
		    where task_instance_id = @task_instance_id
	    end

	    -- Store any updated remote_ids
	    if @event_type = 'TRID' begin
		select @schema_name = t.schema_name from ml_ra_deployed_task dt
		    join ml_ra_task t on t.task_id = dt.task_id
		    where dt.task_instance_id = @task_instance_id
		update ml_ra_managed_remote set remote_id = @value
		    where aid = @aid and schema_name = @schema_name
	    end

	    -- Update remote schema names
	    if @event_type = 'CR' and @value like 'CHSN:%' begin
		select @value = substring( @value, 6, datalength( @value ) - 5 )
		select @schema_name = t.schema_name from ml_ra_deployed_task dt
		    join ml_ra_task t on t.task_id = dt.task_id
		    where dt.task_instance_id = @task_instance_id
		update ml_ra_managed_remote set schema_name = @value
		    where aid = @aid and schema_name = @schema_name
			and exists( select * from ml_ra_schema_name where schema_name = @value )
		update ml_ra_deployed_task set state = 'P' 
		    where aid = @aid and state = 'A'
			and exists( select * from ml_ra_task t left outer join ml_ra_managed_remote mr
				on t.schema_name = mr.schema_name and mr.aid = @aid
				where t.task_id = ml_ra_deployed_task.task_id
				    and t.schema_name is not null 
				    and mr.schema_name is null )
	    end
	end
	close event_crsr
    end

    -- TI status rows are not true events
    delete from ml_ra_event_staging
    	where taskdb_rid = @taskdb_rid and event_type like 'TI%'

    -- Process SIRT ack
    delete from ml_ra_notify
	from ml_ra_event_staging
	where taskdb_rid = @taskdb_rid and event_type like 'TS%'
	    and ml_ra_notify.task_instance_id = ml_ra_event_staging.task_instance_id 
	    and last_modified <= event_time

    -- Cleanup any obsolete SIRT requests
    delete from ml_ra_notify where agent_poll_key = @agent_id and task_instance_id != -1 
	and not exists(	select * from ml_ra_deployed_task where
	    ml_ra_deployed_task.task_instance_id = ml_ra_notify.task_instance_id )

    -- Get properties from the agent
    begin
	declare as_crsr cursor for
	    select property_name, property_value
		from ml_ra_agent_staging
		where taskdb_rid = @taskdb_rid and
		    property_name not like ( 'ml[_]ra[_]%' )
	open as_crsr
	while 1 = 1 begin
	    fetch as_crsr into @name, @value
	    if @@sqlstatus != 0 break
	    if not exists (select * from ml_ra_agent_property
				where aid = @aid and property_name = @name) begin
		insert into ml_ra_agent_property( aid, property_name,
				      property_value, last_modified )
		    values( @aid, @name, @value, getdate() )
	    end else begin
		select @old_value = property_value from ml_ra_agent_property
		    where aid = @aid and property_name = @name
		if (@old_value is null and @value is not null )
			or (@old_value is not null and @value is null )
			or (@old_value != @value)
		    update ml_ra_agent_property set property_value = @value, last_modified = getdate()
			where aid = @aid and property_name = @name
	    end
	end
	close as_crsr
    end

    delete from ml_ra_agent_staging where taskdb_rid = @taskdb_rid 
	and property_name not like ( 'ml[_]ra[_]%' )
	and property_name != 'agent_id'
    exec ml_ra_int_move_events @aid, @taskdb_rid
end
go

create procedure ml_ra_ss_download_prop
    @taskdb_remote_id		varchar( 128 ), 
    @last_table_download	datetime
as
begin
    declare @aid integer
    declare @taskdb_rid integer

    select @aid = a.aid, @taskdb_rid = d.rid from ml_database d 
	left outer join ml_ra_agent a on a.taskdb_rid = d.rid
	where d.remote_id = @taskdb_remote_id

    if @aid is null begin
	select property_name, property_value from ml_ra_agent_staging 
	    where taskdb_rid = @taskdb_rid 
		and property_name not like 'ml[_]ra[_]%'
    end
    else begin
	select property_name, property_value from ml_ra_agent_property p 
	    where p.aid = @aid and property_name not like 'ml[_]ra[_]%' 
		and last_modified >= @last_table_download
    end
end
go

create procedure ml_ra_ss_upload_prop
    @taskdb_remote_id varchar(128), 
    @property_name varchar(128), 
    @property_value varchar(2048) 
as
begin
    declare @taskdb_rid integer

    select @taskdb_rid = rid from ml_database where remote_id = @taskdb_remote_id

    if exists( select * from ml_ra_agent_staging 
	where taskdb_rid = @taskdb_rid and property_name = @property_name ) 
    begin
	update ml_ra_agent_staging set property_value = @property_value
	    where taskdb_rid = @taskdb_rid and property_name = @property_name 
    end
    else begin
	insert into ml_ra_agent_staging( taskdb_rid, property_name, property_value )
	    values( @taskdb_rid, @property_name, @property_value ) 
    end
end
go

create procedure ml_ra_ss_download_task 
    @taskdb_remote_id		varchar( 128 ) 
as
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
    where task_db.remote_id = @taskdb_remote_id
	and ( dt.state = 'CP' or dt.state = 'P' )
end
go

create procedure ml_ra_ss_download_task_cmd 
    @taskdb_remote_id		varchar( 128 ) 
as
begin
    select task_instance_id, command_number, ml_ra_task_command.flags,
	action_type, action_parm
    from ml_database task_db
	join ml_ra_agent on ml_ra_agent.taskdb_rid = task_db.rid
	join ml_ra_deployed_task dt on dt.aid = ml_ra_agent.aid
	join ml_ra_task on dt.task_id = ml_ra_task.task_id
	join ml_ra_task_command on dt.task_id = ml_ra_task_command.task_id
    where task_db.remote_id = @taskdb_remote_id
	and dt.state = 'P'
end
go

create procedure ml_ra_ss_download_remote_dbs
    @taskdb_remote_id		varchar( 128 ),
    @last_download		datetime
as
begin
    select ml_ra_schema_name.schema_name, ml_ra_managed_remote.remote_id, conn_str, remote_type 
    from ml_database taskdb
	join ml_ra_agent on ml_ra_agent.taskdb_rid = taskdb.rid
	join ml_ra_managed_remote on ml_ra_managed_remote.aid = ml_ra_agent.aid
	join ml_ra_schema_name on ml_ra_schema_name.schema_name = ml_ra_managed_remote.schema_name
    where taskdb.remote_id = @taskdb_remote_id
	and ml_ra_managed_remote.last_modified >= @last_download
end
go

create procedure ml_ra_ss_download_ack
    @taskdb_remote_id	varchar( 128 ), 
    @ldt		datetime
as
begin
    declare @aid	integer
    declare @agent_id	varchar( 128 )

    select @aid = aid, @agent_id = agent_id
	from ml_ra_agent
	    join ml_database on taskdb_rid = rid
	where remote_id = @taskdb_remote_id

    update ml_ra_deployed_task set state = 'A' 
	where ml_ra_deployed_task.aid = @aid and state = 'P' and last_modified < @ldt
	    and exists( select * from ml_ra_task t left outer join ml_ra_managed_remote mr
		    on t.schema_name = mr.schema_name and mr.aid = @aid
		    where t.task_id = ml_ra_deployed_task.task_id
			and ( t.schema_name is null or mr.schema_name is not null ) )
     
    delete from ml_ra_notify
	where agent_poll_key = @agent_id
	    and task_instance_id = -1 
	    and last_modified <= @ldt
end
go

-- Default file transfer scripts for upload and download

create procedure ml_ra_ss_agent_auth_file_up
    @auth_code	INTEGER		out,
    @ml_user	varchar( 128 ),
    @remote_key	varchar( 128 ),
    @fsize	numeric( 20 ),
    @filename	varchar( 128 )	out,
    @sub_dir	varchar( 128 )	out  
as
begin
    declare @offset		integer
    declare @cmd_num		integer
    declare @tiid		numeric( 20 )
    declare @tid		numeric( 20 )
    declare @aid		integer
    declare @task_state		varchar( 4 )
    declare @max_size		numeric( 20 )
    declare @direction		varchar(1)
    declare @server_sub_dir	varchar( 128 )
    declare @server_filename	varchar( 128 )

    -- By convention file transfer commands will send up the remote key with...
    -- task_instance_id command_number
    -- eg 1 5	-- task_instance_id=1 command_number=5
    select @offset = charindex( ' ', @remote_key )
    if @offset = 0 begin
	select @auth_code = 2000
	return
    end

    select @tiid = cast( substring( @remote_key, 1, @offset ) as numeric( 20 ) ) 
    select @cmd_num = cast( substring( @remote_key, @offset + 1, datalength( @remote_key ) - @offset ) as numeric( 20 ) )
    if @tiid is null or @tiid < 1 or @cmd_num is null or @cmd_num < 0 begin	
	select @auth_code = 2000
	return
    end

    -- fetch properties of the task
    select @tid = task_id, @aid = aid, @task_state = state 
	from ml_ra_deployed_task where task_instance_id = @tiid

    -- Disallow transfer if the task is no longer active
    if @task_state is null or (@task_state != 'A' and @task_state != 'P') begin 
	select @auth_code = 2001
	return
    end

    -- Make sure the file isn't too big
    select @max_size = convert( numeric(20), property_value )
	from ml_ra_task_command_property
	where task_id = @tid and
	    command_number = @cmd_num and
	    property_name = 'mlft_max_file_size'
    if @max_size > 0 and @fsize > @max_size begin
	select @auth_code = 2002
	return
    end

    -- Make sure the direction is correct
    select @direction = property_value from ml_ra_task_command_property
	where task_id = @tid and
	    command_number = @cmd_num and
	    property_name = 'mlft_transfer_direction'
    if @direction != 'U' begin
	select @auth_code = 2003
	return
    end

    -- set the filename output parameter
    select @server_filename = property_value from ml_ra_task_command_property
	where task_id = @tid and command_number = @cmd_num and
	    property_name = 'mlft_server_filename'
    if @server_filename is not null begin
	select @filename = str_replace( str_replace( @server_filename, '{ml_username}', @ml_user ), '{agent_id}',
	    ( select agent_id from ml_ra_agent where aid = @aid ) )
    end

    -- set the sub_dir output parameter
    select @server_sub_dir = property_value from ml_ra_task_command_property
	where task_id = @tid and
	    command_number = @cmd_num and
	    property_name = 'mlft_server_sub_dir'

    if @server_sub_dir is null begin
	select @sub_dir = ''
    end
    else begin
	select @sub_dir = str_replace( str_replace( @server_sub_dir, '{ml_username}', @ml_user ), '{agent_id}',
	    ( select agent_id from ml_ra_agent where aid = @aid ) )
    end

    -- Everything is ok, allow the file transfer
    select @auth_code = 1000
end
go

create procedure ml_ra_ss_agent_auth_file_down
    @auth_code	INTEGER		out,
    @ml_user	varchar( 128 ),
    @remote_key	varchar( 128 ),
    @filename	varchar( 128 )	out,
    @sub_dir	varchar( 128 )	out  
as
begin
    declare @offset		integer
    declare @cmd_num		integer
    declare @tiid		numeric( 20 )
    declare @tid		numeric( 20 )
    declare @aid		integer
    declare @task_state		varchar( 4 )
    declare @max_size		numeric( 20 )
    declare @direction		varchar(1)
    declare @server_sub_dir	varchar( 128 )
    declare @server_filename	varchar( 128 )

    -- By convention file transfer commands will send up the remote key with...
    -- task_instance_id command_number
    -- eg 1 5	-- task_instance_id=1 command_number=5
    select @offset = charindex( ' ', @remote_key )
    if @offset = 0 begin
	select @auth_code = 2000
	return
    end

    select @tiid = cast( substring( @remote_key, 1, @offset ) as numeric( 20 ) ) 
    select @cmd_num = cast( substring( @remote_key, @offset + 1, datalength( @remote_key ) - @offset ) as numeric( 20 ) )
    if @tiid is null or @tiid < 1 or @cmd_num is null or @cmd_num < 0 begin	
	select @auth_code = 2000
	return
    end

    -- fetch properties of the task
    select @tid = task_id, @aid = aid, @task_state = state 
	from ml_ra_deployed_task where task_instance_id = @tiid

    -- Disallow transfer if the task is no longer active
    if @task_state is null or (@task_state != 'A' and @task_state != 'P') begin 
	select @auth_code = 2001
	return
    end

    -- Make sure the direction is correct
    select @direction = property_value from ml_ra_task_command_property
	where task_id = @tid and
	    command_number = @cmd_num and
	    property_name = 'mlft_transfer_direction'
    if @direction != 'D' begin
	select @auth_code = 2003
	return
    end

    -- set the filename output parameter
    select @server_filename = property_value from ml_ra_task_command_property
	where task_id = @tid and command_number = @cmd_num and
	    property_name = 'mlft_server_filename'
    if @server_filename is not null begin
	select @filename = str_replace( str_replace( @server_filename, '{ml_username}', @ml_user ), '{agent_id}',
	    ( select agent_id from ml_ra_agent where aid = @aid ) )
    end

    -- set the sub_dir output parameter
    select @server_sub_dir = property_value from ml_ra_task_command_property
	where task_id = @tid and
	    command_number = @cmd_num and
	    property_name = 'mlft_server_sub_dir'

    if @server_sub_dir is null begin
	select @sub_dir = ''
    end
    else begin
	select @sub_dir = str_replace( str_replace( @server_sub_dir, '{ml_username}', @ml_user ), '{agent_id}',
	    ( select agent_id from ml_ra_agent where aid = @aid ) )
    end

    -- Everything is ok, allow the file transfer
    select @auth_code = 1000
end
go

exec sp_procxmode 'ml_ra_get_latest_event_id', 'anymode'
go
exec sp_procxmode 'ml_ra_assign_task', 'anymode'
go
exec sp_procxmode 'ml_ra_cancel_task_instance', 'anymode'
go
exec sp_procxmode 'ml_ra_delete_task', 'anymode'
go
exec sp_procxmode 'ml_ra_get_task_status', 'anymode'
go
exec sp_procxmode 'ml_ra_notify_agent_sync', 'anymode'
go
exec sp_procxmode 'ml_ra_notify_task', 'anymode'
go
exec sp_procxmode 'ml_ra_int_cancel_notification', 'anymode'
go
exec sp_procxmode 'ml_ra_cancel_notification', 'anymode'
go
exec sp_procxmode 'ml_ra_get_agent_events', 'anymode'
go
exec sp_procxmode 'ml_ra_get_task_results', 'anymode'
go
exec sp_procxmode 'ml_ra_get_agent_ids', 'anymode'
go
exec sp_procxmode 'ml_ra_get_remote_ids', 'anymode'
go
exec sp_procxmode 'ml_ra_set_agent_property', 'anymode'
go
exec sp_procxmode 'ml_ra_clone_agent_properties', 'anymode'
go
exec sp_procxmode 'ml_ra_get_agent_properties', 'anymode'
go
exec sp_procxmode 'ml_ra_add_agent_id', 'anymode'
go
exec sp_procxmode 'ml_ra_manage_remote_db', 'anymode'
go
exec sp_procxmode 'ml_ra_unmanage_remote_db', 'anymode'
go
exec sp_procxmode 'ml_ra_delete_agent_id', 'anymode'
go
exec sp_procxmode 'ml_ra_int_move_events', 'anymode'
go
exec sp_procxmode 'ml_ra_delete_events_before', 'anymode'
go
exec sp_procxmode 'ml_ra_get_orphan_taskdbs', 'anymode'
go
exec sp_procxmode 'ml_ra_reassign_taskdb', 'anymode'
go
exec sp_procxmode 'ml_ra_ss_end_upload', 'anymode'
go
exec sp_procxmode 'ml_ra_ss_upload_prop', 'anymode'
go
exec sp_procxmode 'ml_ra_ss_download_prop', 'anymode'
go
exec sp_procxmode 'ml_ra_ss_download_task', 'anymode'
go
exec sp_procxmode 'ml_ra_ss_download_task_cmd', 'anymode'
go
exec sp_procxmode 'ml_ra_ss_download_remote_dbs', 'anymode'
go
exec sp_procxmode 'ml_ra_ss_download_ack', 'anymode'
go
exec sp_procxmode 'ml_ra_ss_agent_auth_file_up', 'anymode'
go
exec sp_procxmode 'ml_ra_ss_agent_auth_file_down', 'anymode'
go

exec ml_add_table_script 'ml_ra_agent_12', 'ml_ra_agent_adminprop', 'upload_insert', 
    '{ call ml_ra_ss_upload_prop( {ml s.remote_id}, {ml r.name}, {ml r.value} ) }'
go
exec ml_add_table_script 'ml_ra_agent_12', 'ml_ra_agent_adminprop', 'upload_update', 
    '{ call ml_ra_ss_upload_prop( {ml s.remote_id}, {ml r.name}, {ml r.value} ) }'
go
exec ml_add_table_script 'ml_ra_agent_12', 'ml_ra_agent_adminprop', 'download_cursor', 
    '{call ml_ra_ss_download_prop( {ml s.remote_id}, {ml s.last_table_download} )}'
go
exec ml_add_table_script 'ml_ra_agent_12', 'ml_ra_agent_adminprop', 'download_delete_cursor', '--{ml_ignore}'
go
exec ml_add_connection_script 'ml_ra_agent_12', 'end_upload',
    '{call ml_ra_ss_end_upload( {ml s.remote_id} )}'
go
exec ml_add_connection_script 'ml_ra_agent_12', 'nonblocking_download_ack',
    '{call ml_ra_ss_download_ack( {ml s.remote_id}, {ml s.last_download} )}'
go

exec ml_add_table_script 'ml_ra_agent_12', 'ml_ra_agent_task', 'download_cursor', 
    '{call ml_ra_ss_download_task( {ml s.remote_id} )}'
go
exec ml_add_table_script 'ml_ra_agent_12', 'ml_ra_agent_task', 'download_delete_cursor', '--{ml_ignore}'
go

exec ml_add_table_script 'ml_ra_agent_12', 'ml_ra_agent_command', 'download_cursor', 
    '{call ml_ra_ss_download_task_cmd( {ml s.remote_id} )}'
go
exec ml_add_table_script 'ml_ra_agent_12', 'ml_ra_agent_command', 'download_delete_cursor', '--{ml_ignore}'
go

exec ml_add_table_script 'ml_ra_agent_12', 'ml_ra_agent_remote_db', 'download_cursor', 
    '{call ml_ra_ss_download_remote_dbs( {ml s.remote_id}, {ml s.last_table_download} )}'
go
exec ml_add_table_script 'ml_ra_agent_12', 'ml_ra_agent_remote_db', 'download_delete_cursor', '--{ml_ignore}'
go
exec ml_add_table_script 'ml_ra_agent_12', 'ml_ra_agent_remote_db', 'upload_insert', '--{ml_ignore}'
go
exec ml_add_table_script 'ml_ra_agent_12', 'ml_ra_agent_remote_db', 'upload_update', '--{ml_ignore}'
go
exec ml_add_table_script 'ml_ra_agent_12', 'ml_ra_agent_remote_db', 'upload_delete', '--{ml_ignore}'
go

exec ml_add_table_script 'ml_ra_agent_12', 'ml_ra_agent_status', 'upload_insert', 
    'begin
	declare @taskdb_rid integer

	select @taskdb_rid = rid from ml_database
	    where remote_id = {ml s.remote_id}

	if not exists (select * from ml_ra_event_staging
			where taskdb_rid = @taskdb_rid and
			    remote_event_id = {ml r.id})
	    insert into ml_ra_event_staging( taskdb_rid, remote_event_id, 
		    event_class, event_type, task_instance_id,
		    command_number, run_number, duration, event_time,
		    result_code, result_text )
		values ( @taskdb_rid, {ml r.id}, {ml r.class},
		    {ml r.status}, {ml r.task_instance_id}, {ml r.command_number},
		    {ml r.exec_count}, {ml r.duration}, {ml r.status_time}, {ml r.status_code},
		    {ml r.text} )
    end'
go
exec ml_add_table_script 'ml_ra_agent_12', 'ml_ra_agent_status', 'upload_update', 
    'begin
	declare @taskdb_rid integer

	select @taskdb_rid = rid from ml_database
	    where remote_id = {ml s.remote_id}

	if not exists (select * from ml_ra_event_staging
			where taskdb_rid = @taskdb_rid and
			    remote_event_id = {ml r.id})
	    insert into ml_ra_event_staging( taskdb_rid, remote_event_id, 
		    event_class, event_type, task_instance_id,
		    command_number, run_number, duration, event_time,
		    result_code, result_text )
		values ( @taskdb_rid, {ml r.id}, {ml r.class},
		    {ml r.status}, {ml r.task_instance_id}, {ml r.command_number},
		    {ml r.exec_count}, {ml r.duration}, {ml r.status_time}, {ml r.status_code},
		    {ml r.text} )
    end'
go
exec ml_add_table_script 'ml_ra_agent_12', 'ml_ra_agent_status', 'download_cursor', '--{ml_ignore}'
go
exec ml_add_table_script 'ml_ra_agent_12', 'ml_ra_agent_status', 'download_delete_cursor', '--{ml_ignore}'
go

exec ml_add_connection_script 'ml_ra_agent_12', 'authenticate_file_upload', 
    '{ call ml_ra_ss_agent_auth_file_up( {ml s.file_authentication_code}, {ml s.username}, {ml s.remote_key}, {ml s.file_size}, {ml s.filename}, {ml s.subdir} ) }'
go
exec ml_add_connection_script 'ml_ra_agent_12', 'authenticate_file_transfer', 
    '{ call ml_ra_ss_agent_auth_file_down( {ml s.file_authentication_code}, {ml s.username}, {ml s.remote_key}, {ml s.filename}, {ml s.subdir} ) }'
go

exec ml_add_property 'SIRT', 'RTNotifier(RTNotifier1)', 'request_cursor', 'select agent_poll_key,task_instance_id,last_modified from ml_ra_notify order by agent_poll_key'
go

-- RT Notifier doesn't begin polling until an agent is created
exec ml_add_property 'SIRT', 'RTNotifier(RTNotifier1)', 'poll_every', '2147483647'
go

 -- Set to 'no' to disable auto setting 'poll_every', then manually set 'poll_every'
exec ml_add_property 'SIRT', 'RTNotifier(RTNotifier1)', 'autoset_poll_every', 'yes'
go

exec ml_add_property 'SIRT', 'RTNotifier(RTNotifier1)', 'enable', 'yes'
go

-- Check for updates to started notifiers every minute
exec ml_add_property 'SIRT', 'Global', 'update_poll_every', '60'
go

create procedure ml_ra_ss_download_task2 
    @taskdb_remote_id		varchar( 128 ) 
as
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
    where task_db.remote_id = @taskdb_remote_id
	and ( dt.state = 'CP' or dt.state = 'P' )
end
go

exec sp_procxmode 'ml_ra_ss_download_task2', 'anymode'
go

/* Updated Script for 12.0.1 */
exec ml_share_all_scripts 'ml_ra_agent_12_1', 'ml_ra_agent_12' 
go
exec ml_add_table_script 'ml_ra_agent_12_1', 'ml_ra_agent_task', 'download_cursor', 
   '{ call ml_ra_ss_download_task2( {ml s.remote_id} ) }' 
go

commit
go
