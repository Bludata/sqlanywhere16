
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
alter table ml_user add policy_id integer null
    references ml_user_auth_policy( policy_id )
go 

alter table ml_user add user_dn varchar( 1024 ) null
go 

--
-- Alter the ml_database table to add two new columns
--
alter table ml_database add seq_id binary(16) null
go

alter table ml_database add seq_uploaded integer default 0 not null
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
-- Add stored procedures for retrieving locking/blocking information
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
-- Remove QAnywhere objects
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

exec ml_add_property 'SIS', 'Notifier(QAnyLWNotifier_client)', 'gui', null
go
exec ml_add_property 'SIS', 'Notifier(QAnyLWNotifier_client)', 'enable', null
go
exec ml_add_property 'SIS', 'Notifier(QAnyLWNotifier_client)', 'poll_every', null
go
exec ml_add_property 'SIS', 'Notifier(QAnyLWNotifier_client)', 'request_cursor', null
go


exec ml_add_connection_script 'ml_qa_3', 'handle_error', null
go
exec ml_add_java_connection_script 'ml_qa_3', 'begin_publication', null
go
exec ml_add_java_connection_script 'ml_qa_3', 'nonblocking_download_ack', null
go
exec ml_add_java_connection_script 'ml_qa_3', 'prepare_for_download', null
go
exec ml_add_java_connection_script 'ml_qa_3', 'begin_download', null
go
exec ml_add_java_connection_script 'ml_qa_3', 'modify_next_last_download_timestamp', null
go

exec ml_add_table_script 'ml_qa_3', 'ml_qa_repository_client', 'upload_insert', null
go
exec ml_add_table_script 'ml_qa_3', 'ml_qa_repository_client', 'download_delete_cursor', null
go
exec ml_add_table_script 'ml_qa_3', 'ml_qa_repository_client', 'download_cursor', null
	    
go
exec ml_add_table_script 'ml_qa_3', 'ml_qa_delivery_client', 'upload_insert', null
go
exec ml_add_table_script 'ml_qa_3', 'ml_qa_delivery_client', 'upload_update', null
go
exec ml_add_table_script 'ml_qa_3', 'ml_qa_delivery_client', 'download_delete_cursor', null
go
exec ml_add_table_script 'ml_qa_3', 'ml_qa_delivery_client', 'download_cursor', null

go
exec ml_add_table_script 'ml_qa_3', 'ml_qa_global_props_client', 'upload_insert', null
go
exec ml_add_table_script 'ml_qa_3', 'ml_qa_global_props_client', 'upload_update', null
go
exec ml_add_table_script 'ml_qa_3', 'ml_qa_global_props_client', 'upload_delete', null
go
exec ml_add_table_script 'ml_qa_3', 'ml_qa_global_props_client', 'download_delete_cursor', null
go
exec ml_add_table_script 'ml_qa_3', 'ml_qa_global_props_client', 'download_cursor', null
go

drop procedure ml_qa_stage_status_from_client
go
drop procedure ml_qa_staged_status_for_client
go
drop table ml_qa_repository_staging
go
drop table ml_qa_status_staging
go

drop trigger ml_qa_delivery_trigger
go
drop procedure ml_qa_add_delivery
go
drop procedure ml_qa_handle_error
go
drop procedure ml_qa_upsert_global_prop
go

drop view ml_qa_messages
go
drop view ml_qa_messages_archive
go

drop table ml_qa_global_props
go
drop table ml_qa_delivery
go
drop table ml_qa_status_history
go
drop table ml_qa_repository_props
go
drop table ml_qa_repository
go
drop table ml_qa_notifications
go

drop table ml_qa_delivery_archive
go
drop table ml_qa_status_history_archive
go
drop table ml_qa_repository_props_archive
go
drop table ml_qa_repository_archive
go

delete from ml_script_version where name = 'ml_qa_3'
go

commit
go
