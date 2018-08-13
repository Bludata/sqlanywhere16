
-- ***************************************************************************
-- Copyright (c) 2013 SAP AG or an SAP affiliate company. All rights reserved.
-- ***************************************************************************
-- ***************************************************************************
-- Copyright (c) 2013 SAP AG or an SAP affiliate company. All rights reserved.
-- ***************************************************************************
--  WARNING: This is a program generated file. Do not edit.
--

if varexists( '@reloading' ) <> 0 then
    raiserror 30000 'Unload script cannot be re-executed';
end if
go

SET TEMPORARY OPTION allow_nulls_by_default = 'ON'
go

if exists (select * from SYS.SYSOPTION o
		JOIN SYS.SYSUSERPERM u ON (o.user_id = u.user_id)
	    where lower("option") = 'tsql_variables'
	    and user_name = 'PUBLIC') then
    set temporary option tsql_variables = 'off'
end if
go

create temporary procedure 
sa_make_variable( in varname char(128), in dtype char(100) )
begin
    if varexists( varname ) = 0 then
	execute immediate 'create variable ' || varname || ' ' || dtype;
    else
	execute immediate 'set ' || varname || ' = null';
    end if;
end
go

create temporary procedure sa_make_int_variable( in varname char(128) )
begin
    call sa_make_variable( varname, 'int' );
    execute immediate 'set ' || varname || ' = 0';
end
go

create temporary procedure sa_unload_display_status( in msg int )
begin
    declare l_msg long varchar;
    if @suppress_messages = 1 then
	return;
    end if;
    set l_msg = lang_message( msg );
    if db_property('Charset') != connection_property('Charset') then
	if db_property('Charset') <> 'unknown' then
	    set l_msg = csconvert( l_msg, connection_property('Charset') );
	end if;
    end if;
    message l_msg type info to client;
end
go

create temporary procedure sa_create_delimiter_variables()
begin
    call sa_make_variable( '@newline','char(10)' );
    if( property('Platform') like 'Windows%' ) then
	set @newline = char(13) || '\n';
    else
	set @newline = '\n';
    end if;
    call sa_make_variable( '@cmdsep','char(10)' );
    set @cmdsep = @newline || 'go' || @newline;
    call sa_make_variable( '@tab','char(1)' );
    set @tab = char(9);
    call sa_make_variable( '@escape_char','char(1)' );
    set @escape_char = '\\';
    call sa_make_variable( '@suppress_messages', 'bit' );
    set @suppress_messages = 0;
    call sa_make_variable( '@suppress_script_comments', 'bit' );
    set @suppress_script_comments = 0;
end
go

create temporary function f_unload_binary_string( instr long binary, is_bytecode int )
returns long varchar
begin
    declare hexval long varchar;
    declare i int;
    declare len int;
   
    if instr is null then
	return null;
    end if; 
    if is_bytecode = 1 then
	set hexval = 'set @byte_code = ';
    else
	set hexval = '';
    end if;
    set i = 1;
    set len = length(instr);
    set hexval = hexval || if len = 0 then '''''' else '0x' endif;
    lp: loop
	if i > len then leave lp end if;
	set hexval = hexval || 
	    right(inttohex(cast(cast(byte_substr(instr,i,1) as binary(1)) as int)),2);
	if is_bytecode = 1 and mod(i,1000) = 0 and i <> len then
	    set hexval = hexval || @cmdsep || 'set @byte_code = @byte_code || 0x';
	end if;
	set i = i + 1;
    end loop;
    return hexval;
end
go

create temporary function f_unload_remove_extra_backslashes( @instr long varchar )
returns long varchar
begin
    declare @retvalue long varchar;
    
    set @retvalue = @instr;
    while charindex( '\\\\', @retvalue ) > 0 loop
	set @retvalue = replace( @retvalue, '\\\\', '\\' );
    end loop;
    return @retvalue;
end
go

import optdeflt.sql
import opttemp.sql

create temporary function f_unload_literal( in @value long varchar )
returns long varchar
begin
    return ''''||replace(replace(@value,'''',''''''),'\\','\\\\')||'''';
end
go

create temporary procedure sa_unload_create_tables()
begin
    create local temporary table SQLDefn (
	line	    int		    not null default autoincrement,
	need_delim  bit		    not null default 1,
	txt	    long varchar,
	primary key (line) 
    ) in system not transactional;
    create local temporary table sa_unloaded_table_complete (
	table_id    unsigned int    not null,
	creator	    unsigned int    not null,
	file_id	    int		    not null,
	primary key (table_id)
    ) in system not transactional;
    create local temporary table sa_unloaded_table (
	table_id    unsigned int    not null,
	creator	    unsigned int    not null,
	file_id	    int		    not null,
	first_pkcol int,
	primary key (table_id)
    ) in system not transactional;
    create local temporary table sa_unload_table_ordering (
	table_id	unsigned int    not null,
	user_name	char(128)	not null,
	table_name	char(128)	not null,
	order_col	unsigned int    not null,
	order_progress	unsigned int    not null default autoincrement,
	is_omni_table	bit		not null,
	primary key (table_id)
    ) in system not transactional;
    create local temporary table yes_no ( 
	i	    int		    not null, 
	answer	    char(1)	    not null 
    ) in system not transactional;
    create local temporary table sa_unload_exclude_object(
	name	    char(128)	    not null,
	type	    char(1)	    not null, 
	primary key( name, type )
    ) in system not transactional;
    create local temporary table sa_unload_option_default ( 
	optname	    char(128)	    not null, 
	optval	    long varchar    not null,
	primary key (optname) 
    ) in system not transactional;
    create local temporary table sa_unload_temp_option ( 
	optname	    char(128)	    not null,
	primary key (optname)
    ) in system not transactional;
    create local temporary table sa_unload_obsolete_option(
	optname	    char(128)	    not null,
	primary key (optname )
    ) in system not transactional;
    create local temporary table sa_unload_stage1 (
	id	    unsigned int    not null,
	sub	    unsigned int    not null,
	need_delim  bit		    not null default 1,
	defn	    long varchar    not null,
	primary key (id, sub)
    ) in system not transactional;
    create local temporary table sa_unload_stage2 (
	id1	    unsigned int    not null,
	id2	    unsigned int    not null,
	sub	    unsigned int    not null,
	need_delim  bit		    not null default 1,
	defn	    long varchar    not null,
	primary key (id1, id2, sub)
    ) in system not transactional;
    create local temporary table sa_unload_users_list (
	user_id	    unsigned int    not null,
	user_name   char(128)       not null,
	user_type   tinyint         not null,
	primary key (user_id)
    ) in system not transactional;
    create local temporary table sa_extract_users (
	user_id	    unsigned int    not null,
	primary key (user_id)
    ) in system not transactional;
    create local temporary table sa_extract_pubs (
	publication_id unsigned int not null, 
	creator	    unsigned int    not null, 
	primary key ( publication_id ) 
    ) in system not transactional;
    create local temporary table sa_extract_tables (
	table_id    unsigned int    not null, 
	creator	    unsigned int    not null,
	primary key (table_id)
    ) in system not transactional;
    create local temporary table sa_unload_splayed_indexes (
	table_id    unsigned int    not null,
	index_id    unsigned int    not null,
	primary key (table_id, index_id)
    ) in system not transactional;
    create local temporary table sa_extract_columns (
	table_id    unsigned int    not null,
	column_id   unsigned int    not null,
	column_name char(128)	    not null,
	primary key (table_id, column_id) 
    ) in system not transactional;
    create local temporary table sa_unload_data (
	table_id    unsigned int    not null,
	user_name   char(128)	    not null,
	table_name  char(128)	    not null,
	primary key (table_id)
    ) in system not transactional;
    create local temporary table sa_unload_data_with_mat (
	table_id    unsigned int    not null,
	user_name   char(128)	    not null,
	table_name  char(128)	    not null,
	primary key (table_id)
    ) in system not transactional;
    create local temporary table sa_unload_old_exclude(
	name	    char(128)	    not null,
	type	    char(1)	    not null, 
	primary key( name, type )
    ) in system not transactional;
    create local temporary table sa_unload_jconnect_table (
	table_name  char(128)	    not null,
	primary key (table_name)
    ) in system not transactional;
    create local temporary table sa_unload_jconnect_proc (
	proc_name   char(128)	    not null,
	primary key (proc_name)
    ) in system not transactional;
    create local temporary table sa_unload_obsolete_user_func (
	proc_name   char(128)	    not null,
	primary key (proc_name)
    ) in system not transactional;
    create local temporary table sa_unload_listed_table (
	user_name   char(128)	    not null,
	table_name  char(128)	    not null,
	primary key (user_name,table_name)
    ) in system not transactional;
    create local temporary table sa_unload_selected_table (
	table_id    unsigned int    not null,
	user_id	    unsigned int    not null,
	user_name   char(128)	    not null,
	table_name  char(128)	    not null,
	primary key (table_id)
    ) in system not transactional;
    create local temporary table sa_unload_table_used_java (
	table_id    unsigned int    not null,
	primary key (table_id)
    ) in system not transactional;
    create local temporary table sa_unload_proc_used_java (
	proc_id	    unsigned int    not null,
	primary key (proc_id)
    ) in system not transactional;
    create local temporary table sa_unload_dropped_procedure (
	proc_name   char(128)	    not null,
	primary key (proc_name)
    ) in system not transactional;
    create local temporary table sa_unload_table_perm (
	table_id    unsigned int    not null,
	grantee	    unsigned int    not null,
	grantor	    unsigned int    not null,
	perm	    char(10)	    not null,
	order_col   unsigned int    not null,
	list_order  tinyint	    not null,
	primary key (table_id,grantee,grantor,perm)
    ) in system not transactional;
    create local temporary table sa_unload_table_or_view (
	table_id    unsigned int    not null,
	order_col   unsigned int    not null,
	primary key (table_id)
    ) in system not transactional;
    create local temporary table sa_unload_identity_tabs (
	table_id    unsigned int    not null,
	user_name   char(128)	    not null,
	table_name  char(128)	    not null,
	order_col   unsigned int    not null,
	primary key (table_id)
    ) in system not transactional;
    
    insert into yes_no values( 0, 'N' ); 
    insert into yes_no values( 1, 'Y' );
    commit;
   
    call sa_unload_define_obsolete_options(); 
  
    truncate table sa_unload_exclude_object; 
    call sa_unload_define_exclude_objects(); 
    
    insert into sa_unload_exclude_object on existing skip
	values( 'sync_passthrough_progress', 'D' );
    insert into sa_unload_exclude_object on existing skip
	values( 'sync_passthrough_script', 'D' );
    insert into sa_unload_exclude_object on existing skip
	values( 'sync_passthrough_status', 'D' );
    insert into sa_unload_exclude_object on existing skip
	values( 'sync_execute_next_passthrough_script', 'P' );
    insert into sa_unload_exclude_object on existing skip
	values( 'sync_get_next_passthrough_script', 'P' );
   
    truncate table sa_unload_users_list;
    if f_unload_column_exists( 'SYSUSER', 'user_type' ) = 1 then
    insert into sa_unload_users_list
    select user_id, user_name, user_type from SYS.SYSUSER;
    else
    insert into sa_unload_users_list
	select user_id, user_name, 0 from SYS.SYSUSERPERM;
    end if;

end
go

create temporary procedure sa_unload_define_obsolete_options()
begin
    truncate table sa_unload_obsolete_option;
    insert into sa_unload_obsolete_option values( 'SQLConnect' );
    insert into sa_unload_obsolete_option values( 'SQLStart' );
    insert into sa_unload_obsolete_option values( 'Thread_count' );
    insert into sa_unload_obsolete_option values( 'Thread_swaps' );
    insert into sa_unload_obsolete_option values( 'Thread_stack' );
    insert into sa_unload_obsolete_option values( 'Truncate_date_values' );
    insert into sa_unload_obsolete_option values( 'Max_work_table_hash_size' );
    insert into sa_unload_obsolete_option values( 'Min_table_size_for_histogram' );
    insert into sa_unload_obsolete_option values( 'Java_heap_size' );
    insert into sa_unload_obsolete_option values( 'Java_input_output' );
    insert into sa_unload_obsolete_option values( 'Java_namespace_size' );
    insert into sa_unload_obsolete_option values( 'Java_page_buffer_size' );
    insert into sa_unload_obsolete_option values( 'Log_detailed_plans' );
    insert into sa_unload_obsolete_option values( 'Log_max_requests' );
    insert into sa_unload_obsolete_option values( 'Optimization_logging' );
    insert into sa_unload_obsolete_option values( 'Return_java_as_string' );
    insert into sa_unload_obsolete_option values( 'Allow_replication_pkey_update' );
    insert into sa_unload_obsolete_option values( 'Allow_sync_pkey_update' );
    insert into sa_unload_obsolete_option values( 'auto_commit' );
    insert into sa_unload_obsolete_option values( 'auto_refetch' );
    insert into sa_unload_obsolete_option values( 'bell' );
    insert into sa_unload_obsolete_option values( 'command_delimiter' );
    insert into sa_unload_obsolete_option values( 'commit_on_exit' );
    insert into sa_unload_obsolete_option values( 'echo' );
    insert into sa_unload_obsolete_option values( 'input_format' );
    insert into sa_unload_obsolete_option values( 'nulls' );
    insert into sa_unload_obsolete_option values( 'on_error' );
    insert into sa_unload_obsolete_option values( 'output_format' );
    insert into sa_unload_obsolete_option values( 'output_length' );
    insert into sa_unload_obsolete_option values( 'output_nulls' );
    insert into sa_unload_obsolete_option values( 'truncation_length' );
    insert into sa_unload_obsolete_option values( 'quiet' );
    insert into sa_unload_obsolete_option values( 'screen_format' );
    insert into sa_unload_obsolete_option values( 'char_oem_translation' );
    insert into sa_unload_obsolete_option values( 'headings' );
    insert into sa_unload_obsolete_option values( 'statistics' );
    insert into sa_unload_obsolete_option values( 'isql_command_timing' );
    insert into sa_unload_obsolete_option values( 'isql_escape_character' );
    insert into sa_unload_obsolete_option values( 'isql_field_separator' );
    insert into sa_unload_obsolete_option values( 'isql_quote' );
    insert into sa_unload_obsolete_option values( 'isql_plan' );
    insert into sa_unload_obsolete_option values( 'isql_plan_cursor_sensitivity' );
    insert into sa_unload_obsolete_option values( 'isql_plan_cursor_writability' );
    insert into sa_unload_obsolete_option values( 'isql_log' );
    insert into sa_unload_obsolete_option values( 'describe_java_format' );
    -- This option is not obsolete, but we want to use the current default.
    insert into sa_unload_obsolete_option values( 'Temp_space_limit_check' );
    
    insert into sa_unload_obsolete_option values( 'ansi_integer_overflow' );

    insert into sa_unload_obsolete_option values( 'automatic_timestamp' );
    insert into sa_unload_obsolete_option values( 'float_as_double' );
    insert into sa_unload_obsolete_option values( 'optimistic_wait_for_commit' );
    insert into sa_unload_obsolete_option values( 'percent_as_comment' );
    insert into sa_unload_obsolete_option values( 'query_plan_on_open' );
    insert into sa_unload_obsolete_option values( 'ri_trigger_time' );
    insert into sa_unload_obsolete_option values( 'truncate_with_auto_commit' );
    insert into sa_unload_obsolete_option values( 'tsql_hex_constant' );
    commit;
end
go

create temporary procedure sa_unload_create_variables()
begin
    call sa_create_delimiter_variables();
    call sa_make_variable( '@subscriber_username','char(128)' );
    call sa_make_variable( '@sitename','char(128)' );
    call sa_make_int_variable( '@preserve_ids' );
    call sa_make_int_variable( '@preserve_identities' );
    set @preserve_identities = 0;
    call sa_make_int_variable( '@data_only' );
    call sa_make_int_variable( '@no_data' );
    call sa_make_int_variable( '@full_script' );
    call sa_make_int_variable( '@extracting' );
    call sa_make_int_variable( '@exclude_procedures' );
    call sa_make_int_variable( '@exclude_views' );
    call sa_make_int_variable( '@exclude_triggers' );
    call sa_make_int_variable( '@exclude_foreign_keys' );
    call sa_make_int_variable( '@exclude_statistics' );
    call sa_make_int_variable( '@reloading' );
    call sa_make_int_variable( '@subscriber' );
    call sa_make_int_variable( '@post_load_line' );
    call sa_make_int_variable( '@post_index_line' );
    call sa_make_int_variable( '@internal_unload' );
    set @internal_unload = 1;
    call sa_make_int_variable( '@internal_reload' );
    set @internal_reload = 1;
    call sa_make_int_variable( '@global_db_id' );
    call sa_make_int_variable( '@table_list_provided' );
    call sa_make_int_variable( '@exclude_tables' );
    call sa_make_int_variable( '@include_where_subscribe' );
    call sa_make_int_variable( '@make_auxiliary' );
    call sa_make_int_variable( '@profiling_uses_single_dbspace' );
    call sa_make_int_variable( '@recompute_values' );
    call sa_make_int_variable( '@java_enabled' );
    if f_unload_table_exists( 'SYSJAVACLASS' ) = 1 then
	if exists (select * from SYS.SYSJAVACLASS) then
	    set @java_enabled = 1;
	end if;
    end if;
    call sa_make_int_variable( '@has_preserved_source' );
    call sa_make_int_variable( '@has_omni_columns' );
    call sa_make_int_variable( '@remove_encryption_from_tables' );
    call sa_make_int_variable( '@refresh_mat_views' );
    call sa_make_int_variable( '@encrypted_output' );
    
    call sa_make_int_variable( '@use_alter_object' );

    call sa_make_int_variable( '@has_full_text' );
    if f_unload_table_exists( 'SYSTEXTCONFIG' ) = 1 then
	set @has_full_text = 1;
    end if;
    
    if f_unload_column_exists( 'SYSTABLE', 'source' ) = 1 then
	set @has_preserved_source = 1;
    end if;
    call sa_make_int_variable( '@has_named_constraints' );
    if f_unload_table_exists( 'SYSCONSTRAINT' ) = 1 then
	set @has_named_constraints = 1;
    end if;
    call sa_make_int_variable( '@has_column_type' );
    if f_unload_column_exists( 'SYSCOLUMN', 'column_type' ) = 1 then
	set @has_column_type = 1;
    end if;
    if f_unload_column_exists( 'SYSTABLE', 'existing_obj' ) = 1 then
	set @has_omni_columns = 1;
    end if;
    call sa_make_int_variable( '@has_last_download_time' );
    if f_unload_column_exists( 'SYSSYNC', 'last_download_time' ) = 1 then
	set @has_last_download_time = 1;
    end if;
    call sa_make_int_variable( '@has_log_sent' );
    if f_unload_column_exists( 'SYSSYNC', 'log_sent' ) = 1 then
	set @has_log_sent = 1;
    end if;
    call sa_make_int_variable( '@has_web_service_enabled' );
    if f_unload_column_exists( 'SYSWEBSERVICE', 'enabled' ) = 1 then
	set @has_web_service_enabled = 1;
    end if;
    call sa_make_int_variable( '@show_index_progress' );
    set @show_index_progress = 1;

    call sa_make_variable( '@db_name',	'long varchar' );
    select db_property( 'File' ) into @db_name;
    call sa_make_variable( '@log_name', 'long varchar' );
    select db_property( 'LogName' ) into @log_name;
    call sa_make_variable( '@mlog_name', 'long varchar' );
    select db_property( 'LogMirrorName' ) into @mlog_name;
    call sa_make_variable( '@page_size', 'unsigned integer' );
    select db_property( 'PageSize' ) into @page_size;
    call sa_make_variable( '@char_coll_name', 'long varchar' );
    set @char_coll_name = null;
    call sa_make_variable( '@char_coll_defn', 'long varchar' );
    set @char_coll_defn = null;
    call sa_make_variable( '@encryption_alg', 'varchar(100)' );
    select db_property( 'Encryption' ) into @encryption_alg;
    call sa_make_int_variable( '@encrypted_tables' );
    if db_property( 'EncryptionScope' ) = 'Table' then
	set @encrypted_tables = 1;
    else
	set @encrypted_tables = 0;
    end if;
    call sa_make_variable( '@encryption_key', 'long varchar' );
    set @encryption_key = '?';
    
    call sa_make_variable( '@cmtbeg','char(4)' );
    set @cmtbeg = ' /' || '* ';
    call sa_make_variable( '@cmtend','char(4)' );
    set @cmtend = ' *' || '/ ';
    call sa_make_variable( '@exclude_pub_id', 'unsigned int' );
    set @exclude_pub_id = 999999999;
    call sa_make_variable( '@name_order', 'bit' );
    set @name_order = 0;
    call sa_make_int_variable( '@has_rbac' );
    set @has_rbac = 0;
    if f_unload_table_exists( 'SYSROLEGRANT' ) = 1 then
	set @has_rbac = 1;
    end if;
    call sa_make_int_variable( '@sys_proc_definer' );
    if  @has_rbac= 1 then
	
	if ( HEXTOINT( substring(db_property('Capabilities'),1,length(db_property('Capabilities'))-20) ) & 8 ) = 8 then
	    set @sys_proc_definer = 0;
	else
	    set @sys_proc_definer = 1;
	end if;
    else
        
    	set @sys_proc_definer = 1;
    end if;
    call sa_make_int_variable( '@has_nagano_upgrade' );
    set @has_nagano_upgrade = @has_rbac;
end
go

create temporary procedure sa_unload_set_option_if_exists( @option char(128), @value char(128) )
begin
    if exists (select * from SYS.SYSOPTION o
		    JOIN sa_unload_users_list u ON (o.user_id = u.user_id)
		where lower("option") = @option
		and user_name = 'PUBLIC') then
	execute immediate 
	    'set temporary option ' || @option || 
		    ' = ''' || @value || '''';
    end if;
end
go

create temporary procedure sa_unload_initialize()
begin
    if varexists( '@reloading' ) = 0 then
	call sa_unload_create_tables();
	call sa_unload_create_variables();
    else
	truncate table SQLDefn;
	truncate table sa_unload_option_default;
	truncate table sa_unload_temp_option;
    end if;
    
    SET TEMPORARY OPTION date_format = 'yyyy-mm-dd hh:nn';
    SET TEMPORARY OPTION time_format = 'hh:nn:ss.ssssss';
    SET TEMPORARY OPTION timestamp_format = 'yyyy-mm-dd hh:nn:ss.ssssss';
    SET TEMPORARY OPTION quoted_identifier = 'ON';
    SET TEMPORARY OPTION allow_nulls_by_default = 'ON';
    call sa_unload_set_option_if_exists( 'st_geometry_describe_type', 'binary' );
    call sa_unload_set_option_if_exists( 'st_geometry_asbinary_format', 'EWKB' );
    call sa_unload_set_option_if_exists( 'st_geometry_on_invalid', 'Ignore' );
    call sa_unload_set_option_if_exists( 'timestamp_with_time_zone_format', 'yyyy-mm-dd hh:nn:ss.ssssss+hh:nn' );
    call sa_unload_set_option_if_exists( 'chained', 'ON' );
    call sa_unload_set_option_if_exists( 'escape_character', 'ON' );
    call sa_unload_set_option_if_exists( 'update_statistics', 'OFF' );
end
go

create temporary procedure sa_unload_staged_text1()
begin
    insert into SQLDefn (need_delim,txt)
	select s.need_delim,defn
	from sa_unload_stage1 s
	order by id,sub;
    truncate table sa_unload_stage1;
end
go

create temporary procedure sa_unload_staged_text2()
begin
    insert into SQLDefn (need_delim,txt)
	select s.need_delim,defn
	from sa_unload_stage2 s
	order by id1,id2,sub;
    truncate table sa_unload_stage2;
end
go

create temporary procedure 
sa_unload_script_comment( in cmt varchar(200), in add_commit int default 0 )
begin
    if @suppress_script_comments = 1 then
	return;
    end if;
    insert into SQLDefn (need_delim,txt)
	select 0,
	    @newline ||
	    repeat('-',49) || @newline ||
	    '--   ' || cmt || @newline ||
	    repeat('-',49) || @newline;
    if add_commit = 1 then
	
	insert into SQLDefn (need_delim,txt)
	    values (0,'commit' || @cmdsep || @newline);
    end if;
end
go

create temporary function f_sanitize_login_id( @object long varchar )
returns long varchar
begin
    return '"' || @object || '"';

end
go

create temporary function f_unload_object_comment(
    @objtype	char(40),
    @owner	char(128),
    @object	long varchar,
    @objsub	char(128),
    @remarks	long varchar )
returns long varchar
begin
    declare rslt long varchar;
    set rslt = 'COMMENT ON ' || @objtype || ' ' ||
	if @owner is not null then
	    '"' || @owner || '".'
	endif ||
	if @objtype = 'INTEGRATED LOGIN' then
	    f_sanitize_login_id( @object )
	else
	    if @objtype in ('JAVA CLASS','JAVA JAR','EXTERNAL ENVIRONMENT OBJECT') then
		'''' || @object || ''''
	    else
		'"' || @object || '"' 
	    endif
	endif ||
	if @objsub is not null then
	    '."' || @objsub || '"'
	endif ||
	' IS ' || 
	if @remarks is null then
	    'NULL'
	else 
	    @newline || @tab || f_unload_literal(@remarks)
	endif;
    return rslt;
end
go

create temporary function f_unload_preserved_source(
    @objtype	char(20),
    @owner	char(128),
    @object	char(128),
    @objsub	char(128),
    @source	long varchar )
returns long varchar
begin
    declare rslt long varchar;
    set rslt = 'COMMENT TO PRESERVE FORMAT ON ' || @objtype || ' ' ||
	if @owner is not null then
	    '"' || @owner || '".'
	endif ||
	'"' || @object || '"' ||
	if @objsub is not null then
	    '."' || @objsub || '"'
	endif ||
	' IS ' || @newline;
    if locate(@source,'}') <> 0 then
	set @source = replace(@source,'''','''''');
	set @source = replace(@source,'\\','\\\\');
	set @source = replace(@source,char(10),'\x0a');
	set @source = replace(@source,char(13),'\x0d');
	set rslt = rslt || '''' || @source || '''';
    else
	set rslt = rslt || '{' || @source || @newline || '}';
    end if;
    return rslt;
end
go

create temporary procedure sa_unload_remote_tables()
begin
    declare local temporary table article_cols (
	table_id    unsigned int not null,
	column_id   unsigned int not null,
	primary key (table_id, column_id)
    ) in system not transactional;
    
    truncate table sa_extract_pubs;
    INSERT INTO sa_extract_pubs 
	SELECT DISTINCT p.publication_id, creator 
	FROM SYS.SYSPUBLICATION p
	    JOIN SYS.SYSSUBSCRIPTION s ON (s.publication_id = p.publication_id)
	    JOIN SYS.SYSREMOTEUSER ru ON (ru.user_id = s.user_id) 
	    JOIN sa_unload_users_list up ON (up.user_id = ru.user_id)
	WHERE user_name = @subscriber_username AND p.publication_id <> @exclude_pub_id;

    truncate table sa_extract_tables;
    INSERT INTO sa_extract_tables 
	SELECT t.table_id, t.creator 
	FROM SYS.SYSTABLE t 
	WHERE EXISTS (SELECT a.publication_id 
		    FROM sa_extract_pubs ep
			JOIN SYS.SYSARTICLE a ON (a.publication_id = ep.publication_id)
		    WHERE t.table_id = a.table_id)
	OR t.table_type = 'GBL TEMP';
	
    insert into article_cols
	SELECT a.table_id, a.column_id 
	FROM SYS.SYSARTICLECOL a 
		JOIN sa_extract_pubs ep ON (ep.publication_id = a.publication_id);
    truncate table sa_extract_columns;
    INSERT INTO sa_extract_columns 
	SELECT c.table_id, c.column_id, column_name 
	FROM SYS.SYSCOLUMN c 
	    JOIN sa_extract_tables et ON (c.table_id = et.table_id)
	WHERE (column_id IN (SELECT column_id 
			    FROM article_cols ac
			    WHERE ac.table_id = c.table_id)
	   OR NOT EXISTS (SELECT * from article_cols ac
			    WHERE ac.table_id = c.table_id))
	ORDER BY c.table_id, c.column_id;
	
    truncate table sa_unload_splayed_indexes;
    insert into sa_unload_splayed_indexes 
	SELECT ind.table_id, ind.index_id 
	FROM SYS.SYSINDEX ind 
	WHERE ind.table_id IN (SELECT et.table_id from sa_extract_tables et)
	AND (select count(*) from SYS.SYSIXCOL ixc 
	   where ixc.table_id=ind.table_id 
	     and ixc.index_id=ind.index_id )
          !=(select count(*) from SYS.SYSIXCOL ixc, sa_extract_columns ec 
	   where ixc.table_id=ind.table_id 
	     and ixc.index_id=ind.index_id 
	     and ec.table_id=ixc.table_id 
	     and ec.column_id=ixc.column_id );

    truncate table sa_extract_users;
    INSERT INTO sa_extract_users 
	SELECT u.user_id 
	FROM SYS.SYSUSERPERM u
	JOIN sa_unload_users_list sl ON ( u.user_id = sl.user_id )
	WHERE u.user_name IN ('SYS', 'DBA', 'PUBLIC', 'dbo') 
	OR u.user_group = 'Y' 
	OR ( u.remotedbaauth = 'Y' 
	    AND u.user_id NOT IN (SELECT user_id FROM SYS.SYSREMOTEUSER) );
    INSERT INTO sa_extract_users ON EXISTING SKIP
	SELECT u.user_id 
	FROM SYS.SYSUSERPERM u
	JOIN sa_unload_users_list sl ON ( u.user_id = sl.user_id )
	WHERE u.publishauth = 'Y' 
	OR u.user_name = @subscriber_username
	OR u.user_id IN (SELECT group_member 
		    FROM SYS.SYSGROUP g
			JOIN sa_unload_users_list slg ON (slg.user_id = g.group_id)
		    WHERE slg.user_name = @subscriber_username);
    INSERT INTO sa_extract_users ON EXISTING SKIP
	select creator FROM sa_extract_tables
	union
	select creator FROM sa_extract_pubs
	union
	select grantor FROM SYS.SYSTABLEPERM
	union
	select grantor FROM SYS.SYSCOLPERM;
    if @exclude_procedures = 0 then
	INSERT INTO sa_extract_users ON EXISTING SKIP
	    select creator FROM SYS.SYSPROCEDURE;
    end if;
    if @exclude_views = 0 then
	INSERT INTO sa_extract_users ON EXISTING SKIP
	    select creator FROM SYS.SYSTABLE
	    where table_type = 'VIEW' or table_type = 'MAT VIEW';
    end if;
    if f_unload_table_exists( 'SYSJAVACLASS' ) = 1 then
	INSERT INTO sa_extract_users ON EXISTING SKIP
	    select creator FROM SYS.SYSJAVACLASS;
    end if;
end
go

create temporary function f_unload_database_info( @for_unprocessed bit )
returns long varchar
begin
    declare rslt long varchar;
    set rslt =  '-- Database file: ' || db_property('File')
    	     	|| @newline ||
    	     	'-- Database CHAR collation: ' || db_property('Collation') ||
		', NCHAR collation: ' || db_property('NCHARCollation') 
		|| @newline || 
		'-- Connection Character Set: ' || connection_property('CharSet') || @newline ||
		'--' || @newline ||
		'-- CREATE DATABASE command: '
		|| f_unload_create_database( ' ', 0, @for_unprocessed ) || @newline ||
		'--';
    return rslt;	
end
go

create temporary function f_unload_create_database( 
	in @sep char default ' ', 
	in @dbinit_output int default 0,
	in @for_unprocessed bit default 0 )
returns long varchar
begin
    declare rslt	    long varchar;
    declare @dba_username   char(128);
    declare @local_key	    long varchar;
    declare @with_checksum  int;
    
    if @dbinit_output = 0 then
        set rslt =  'CREATE DATABASE ' || f_unload_literal( @db_name );
    else
        set rslt =  'dbinit "' || @db_name || '"';
    end if;

    if db_property( 'LogName' ) is not null then
	if @dbinit_output = 0 then
	    set rslt = rslt || @sep || 'LOG ON ' || f_unload_literal( @log_name ); 
	else
	    set rslt = rslt || ' -t "' || @log_name || '"'; 
	end if;

	if db_property( 'LogMirrorName' ) is not null then 
	    if @dbinit_output = 0 then
		set rslt = rslt || @sep || 'MIRROR ' || f_unload_literal( @mlog_name );
	    else
		set rslt = rslt || ' -m "' || @mlog_name || '"';
	    end if;
	end if;
    else 
	if @dbinit_output = 0 then
	     set rslt = rslt || @sep || 'LOG OFF';
	else
	     set rslt = rslt ||' -n';
	end if;
    end if;

    if @dbinit_output = 0 then
	set rslt = rslt || @sep || 'CASE';
    end if;
    if upper(db_property( 'CaseSensitive' )) = 'ON' then
	if @dbinit_output = 0 then
	    set rslt = rslt || ' RESPECT';
	else
	    set rslt = rslt || ' -c';
	end if;
    else
	if @dbinit_output = 0 then
	    set rslt = rslt || ' IGNORE';
	end if;
    end if;

    if @dbinit_output = 0 then
	set rslt = rslt || @sep || 'ACCENT';
    end if;
    if upper(db_property( 'AccentSensitive' )) = 'ON' then
	if @dbinit_output = 0 then
	    set rslt = rslt || ' RESPECT';
	else
	    set rslt = rslt || ' -a';
	end if;
    elseif upper(db_property( 'AccentSensitive' )) = 'FRENCH' then
	if @dbinit_output = 0 then
	    set rslt = rslt || ' FRENCH';
	else
	    set rslt = rslt || ' -af';
	end if;
    else
	if @dbinit_output = 0 then
	    set rslt = rslt || ' IGNORE';
	end if;
    end if;

    if @dbinit_output = 0 then
	set rslt = rslt || @sep || 'PAGE SIZE ' || @page_size;
    else
	set rslt = rslt || ' -p ' || @page_size;
    end if;

    if db_property( 'HasCollationTailoring' ) = 'On' then
	if @dbinit_output = 0 then
	    set rslt = rslt || @sep || 'COLLATION '''
			    || db_extended_property( 'Collation', 'Specification' )
			    || '''';
	    set rslt = rslt || @sep || 'NCHAR COLLATION '''
			    || db_extended_property( 'NcharCollation',
						     'Specification' )
			    || '''';
	else
	    set rslt = rslt || ' -z "'
			    || db_extended_property( 'Collation', 'Specification' )
			    || '"';
	    set rslt = rslt || ' -zn "'
			    || db_extended_property( 'NcharCollation',
						     'Specification' )
			    || '"';
	end if;
    else
	if db_property( 'Collation' ) = 'UCA' then
	    if @dbinit_output = 0 then
		set rslt = rslt || @sep || 'COLLATION ''UCA''';
	    else
		set rslt = rslt || ' -z "UCA"';
	    end if;
	elseif @char_coll_name is not null and @char_coll_defn is not null then
	    if @dbinit_output = 0 then
		set rslt = rslt || @sep || 'COLLATION '''
		    	        || db_property( 'Collation' )
				|| ''' DEFINITION '
				|| @char_coll_defn;
	    else
		set rslt = rslt || ' -z "' || db_property( 'Collation' )
				|| '" DEFINITION ' 
				|| @char_coll_defn;
	    end if;
	else
	    if @dbinit_output = 0 then
		set rslt = rslt || @sep || 'COLLATION ''' 
		    	   	|| db_property( 'Collation' )
				|| '''';
	    else
		set rslt = rslt || ' -z "' || db_property( 'Collation' ) || '"';
	    end if;
	end if;

	if db_property( 'NcharCollation' ) is not null then
	    if @dbinit_output = 0 then
		set rslt = rslt || @sep || 'NCHAR COLLATION '''
				|| db_property( 'NcharCollation' ) || '''';
	    else
		set rslt = rslt ||' -zn "' || db_property( 'NcharCollation' )
		    	   	|| '"';
	    end if;
	end if;
    end if;

    if lower( @encryption_alg ) != 'none' then
	if @dbinit_output = 0 then
	    set rslt = rslt || @sep || 'ENCRYPTED';
	end if;
	if @encrypted_tables = 1 then
	    if @dbinit_output = 0 then
		set rslt = rslt || ' TABLE';
	    else
		set rslt = rslt || ' -et';
	    end if;
	end if;
	if @dbinit_output = 0 then
	    set rslt = rslt || ' ON';
	end if;
	if lower( @encryption_alg ) != 'simple' and @encryption_key != '' then
	    if @for_unprocessed = 1 then
		set @local_key = '?';
	    else
		set @local_key = @encryption_key;
	    end if;
	    if @dbinit_output = 0 then
		set rslt = rslt || ' KEY ' 
			        || f_unload_literal( @local_key )
				|| ' ALGORITHM '''
				|| @encryption_alg || '''';
	    else
		set rslt = rslt || ' -ek "' || @local_key || '" -ea "'
				|| @encryption_alg || '"';
	    end if;
        else
	    if @dbinit_output = 0 then
		set rslt = rslt || ' ALGORITHM ''simple''';
	    else
		set rslt = rslt || ' -ea "simple"';
	    end if;
	end if;
    end if;

    if @dbinit_output = 0 then
	set rslt = rslt || @sep || 'BLANK PADDING '
			|| upper( db_property( 'BlankPadding' ) );
    else
	if upper( db_property( 'BlankPadding') ) = 'ON' then
	    set rslt = rslt || ' -b';
	end if;
    end if;

    if @dbinit_output = 0 then
	set rslt = rslt || @sep || 'JCONNECT';
    end if;
    if exists (select * 
		from SYS.SYSTABLE 
		where table_name = 'jdbc_function_escapes') then
	if @dbinit_output = 0 then
	    set rslt = rslt || ' ON';
	end if;
    else
	if @dbinit_output = 0 then
	    set rslt = rslt || ' OFF';
	else
	    set rslt = rslt || ' -i';
	end if;
    end if;

    if f_unload_table_exists( 'SYSCOLUMNS' ) = 0 then
	if @dbinit_output = 0 then
	    set rslt = rslt || @sep || 'ASE COMPATIBLE';
	else
	    set rslt = rslt || ' -k';
	end if;
    end if;

    if db_property( 'Checksum' ) is not null and
           f_unload_table_exists( 'SYSMIRROROPTION' ) = 1 and
           upper( db_property( 'Checksum' ) ) = 'OFF' then
	set @with_checksum = 0;
    else 
	set @with_checksum = 1;
    end if;
    if @with_checksum = 0 then
	if @dbinit_output = 0 then
	    set rslt = rslt || @sep || 'CHECKSUM OFF';
	else
	    set rslt = rslt || ' -s-';
	end if;
    else 
	if @dbinit_output = 0 then
	    set rslt = rslt || @sep || 'CHECKSUM ON';
	else
	    set rslt = rslt || ' -s';
	end if;
    end if;
    
    set @dba_username = (select first user_name 
		from SYS.SYSUSERPERM 
		where upper(user_name) = 'DBA'
		and cast(user_name as binary) <> 'DBA'
		order by user_name);
    if @dba_username is not null then	
	if @dbinit_output = 0 then
	    set rslt = rslt || @sep || 'DBA USER ''' || @dba_username || ''''
	else
	    set rslt = rslt || ' -dba ' || @dba_username;
	end if;
    end if;

    if @dbinit_output = 0 then
        if @sys_proc_definer = 1 then
	    set rslt = rslt || @sep || 'SYSTEM PROC AS DEFINER ON';
	else
	    set rslt = rslt || @sep || 'SYSTEM PROC AS DEFINER OFF';
	end if;
    else
    	if @sys_proc_definer = 1 then
	    set rslt = rslt || ' -pd';
	end if;
    end if;

    return rslt;	
end
go

create temporary function sa_unload_createdb_info( in @dbinit_output int default 0 )
returns long varchar
begin
    return f_unload_create_database( @newline || @tab, @dbinit_output );
end
go

create temporary procedure sa_unload_database_info()
begin
    if @name_order = 1 then
	insert into SQLDefn (need_delim,txt)
	    values( 0, 
		    '****************** WARNING *******************************' || @newline ||
		    '*                                                        *' || @newline ||
		    '* This file contains object definitions ordered by name. *' || @newline ||
		    '* It should not be used to create a new database.        *' || @newline ||
		    '*                                                        *' || @newline ||
		    '****************** WARNING *******************************' || @newline ||
		    @newline );
    end if;
    insert into SQLDefn (need_delim,txt)
	values( 0, f_unload_database_info( 0 ) );
    insert into SQLDefn (need_delim,txt)
	values( 0, @newline );
end
go

create temporary procedure sa_unload_initial_options()
begin
    insert into SQLDefn (txt)
	values( 'SET OPTION date_order          = ''YMD''' );
    insert into SQLDefn (txt)
	values( 'SET OPTION PUBLIC.preserve_source_format = ''OFF''' );
    insert into SQLDefn (txt)
	values( 'SET TEMPORARY OPTION tsql_outer_joins = ''ON''' );
    insert into SQLDefn (txt)
	values( 'SET TEMPORARY OPTION st_geometry_describe_type = ''binary''' );
    insert into SQLDefn (txt)
	values( 'SET TEMPORARY OPTION st_geometry_on_invalid = ''Ignore''' );
    if @has_nagano_upgrade = 0 then
        insert into SQLDefn (txt)
            values( 'SET TEMPORARY OPTION non_keywords = ''row,array,varray,json,rowtype,unnest''' );
    end if;

    if exists (select * from SYS.SYSOPTION o
		    JOIN sa_unload_users_list u ON (o.user_id = u.user_id)
		where lower("option") = 'reserved_keywords'
		and user_name = 'PUBLIC') then
	insert into SQLDefn (txt)
		values( 'SET OPTION PUBLIC.reserved_keywords = ''' + (select setting from SYS.SYSOPTION o
		    JOIN sa_unload_users_list u ON (o.user_id = u.user_id)
		where lower("option") = 'reserved_keywords'
		and user_name = 'PUBLIC' ) + '''' );
   end if;

    insert into SQLDefn (txt)
	values( 'SET TEMPORARY OPTION non_keywords = ''' ||
	    'attach' ||
	    ',compressed' ||
	    ',detach' ||
	    ',kerberos' ||
	    ',nchar' ||
	    ',nvarchar' ||
	    ',refresh' ||
	    ',varbit' ||
	    ',row' ||
	    ',array' ||
	    ',varray' ||
	    ',json' ||
	    ',rowtype' ||
	    ',unnest' ||

	    '''' );
end
go

create temporary procedure sa_unload_dbspaces()
begin
    if @reloading = 1 then
	return;
    end if;
    call sa_unload_script_comment( 'Create dbspaces' );
    insert into SQLDefn (txt)
	SELECT 'CREATE DBSPACE "' || dbspace_name || '"' ||
		' AS ' || f_unload_literal(file_name)
	FROM SYS.SYSFILE f 
	WHERE file_id <> 0 and file_id <> 15
	AND (@extracting = 0 
		OR EXISTS (SELECT * 
			    FROM sa_extract_tables e
				JOIN SYS.SYSTABLE t ON (t.table_id = e.table_id)
			    WHERE t.file_id = f.file_id)
		OR EXISTS (SELECT * 
			    FROM sa_extract_tables e
				JOIN SYS.SYSINDEX i ON (i.table_id = e.table_id)
			    WHERE i.file_id = f.file_id ) 
	    )
	order by file_id;
	if f_unload_table_exists( 'ISYSDBSPACE' ) = 1 then
	    insert into SQLDefn (txt)
		select f_unload_object_comment( 'DBSPACE', null, dbspace_name, null, r.remarks )
		from SYS.SYSDBSPACE dbsp
			join SYS.SYSREMARK r ON (dbsp.object_id = r.object_id)
		order by dbspace_id;
	end if;
end
go

create temporary procedure sa_unload_dbspace_perms()
begin
    call sa_unload_script_comment( 'Create dbspace permissions' );
    if f_unload_table_exists( 'ISYSDBSPACEPERM' ) = 1 then
	
    	insert into SQLDefn (txt)
	    select 'begin' || @newline ||
		'    for dbspaces as dbcurs cursor for ' || @newline ||
		'	select privilege_type, dbspace_name, user_name ' || @newline ||
	    	'		from SYS.SYSDBSPACEPERM p ' || @newline ||
		'		join SYS.SYSDBSPACE d on p.dbspace_id = d.dbspace_id' || @newline ||
		'		join SYS.SYSUSER u on u.user_id = p.grantee' || @newline ||
    		'    do' || @newline ||
		'	execute immediate ''revoke '' + if privilege_type = 1 then ''CREATE'' else ''UNKNOWN'' endif + '' on "'' + dbspace_name + ''" from "'' + user_name + ''"''' || @newline ||
    		'    end for;' || @newline ||
		'end' || @newline;

	insert into SQLDefn (txt)
	    select 'grant ' + if privilege_type = 1 then 'CREATE' else 'UNKNOWN' endif + ' on "' + dbspace_name + '" to "' + user_name + '"'
		from SYS.SYSDBSPACEPERM p
			join SYS.SYSDBSPACE d on p.dbspace_id = d.dbspace_id
			join SYS.SYSUSER u on u.user_id = p.grantee;
    else
    	insert into SQLDefn (txt)
	    select 'begin' || @newline ||
		'    for dbspaces as dbcurs cursor for ' || @newline ||
		'	select dbspace_name from SYS.SYSDBSPACE ' || @newline ||
    		'    do' || @newline ||
		'	execute immediate ''grant CREATE ON "'' + dbspace_name + ''" to PUBLIC''' || @newline ||
    		'    end for;' || @newline ||
		'end' || @newline;
    end if;
end
go	

create temporary function f_unload_table_exists( @table_name char(128) )
returns int
begin
    if exists (select * 
		from SYS.SYSTABLE t 
		where creator = 0
		and table_name = @table_name) then
	return 1;
    else
	return 0;
    end if;
end
go

create temporary function f_unload_column_exists( @table_name char(128), @column_name char(128) )
returns int
begin
    if exists (select * 
		from SYS.SYSCOLUMN c
		    JOIN SYS.SYSTABLE t ON (t.table_id = c.table_id)
		where creator = 0
		and table_name = @table_name
		and column_name = @column_name) then
	return 1;
    else
	return 0;
    end if;
end
go

create temporary function f_unload_hex_string( instr char(255) )
returns long varchar
begin
    declare hexval long varchar;
    select list( '\\x' || 
	    right(inttohex(cast(cast(byte_substr(instr,row_num,1) as binary(1)) as int)),2),''
		 order by row_num)
	    into hexval
    from dbo.RowGenerator
    where row_num <= byte_length(instr);
    return hexval;
end
go

create temporary procedure sa_unload_login_policies()
begin	
    declare local temporary table default_policy_opts (
	option_name	char(128) not null,
	option_value	long varchar not null
    ) in system not transactional;
    
    if f_unload_table_exists( 'SYSLOGINPOLICY' ) = 0 then
	return;
    end if;
    call sa_unload_script_comment( 'Create login policies' );
    
    insert into default_policy_opts
	select login_option_name name, login_option_value val
	from SYS.SYSLOGINPOLICY lp 
	    join SYS.SYSLOGINPOLICYOPTION lpo ON (lp.login_policy_id = lpo.login_policy_id)
	where login_policy_name = 'root'
	and not (
	    (name = 'password_life_time' and val = 'unlimited') or
	    (name = 'password_grace_time' and val = '0') or
	    (name = 'password_expiry_on_next_login' and val = 'Off') or
	    (name = 'locked' and val = 'Off') or
	    (name = 'max_connections' and val = 'unlimited') or
	    (name = 'max_failed_login_attempts' and val = 'unlimited') or
	    (name = 'max_days_since_login' and val = 'unlimited') or
	    (name = 'max_non_dba_connections' and val = 'unlimited') or
	    (name = 'ldap_primary_server' and val = '') or
	    (name = 'ldap_secondary_server' and val = '') or
	    (name = 'ldap_auto_failback_period' and val = '15') or
	    (name = 'ldap_failover_to_std' and val = 'On') or
	    (name = 'ldap_refresh_dn' and val = '') or
	    (name = 'auto_unlock_time' and val = 'unlimited') or
	    (name = 'root_auto_unlock_time' and val = '1') or
	    (name = 'change_password_dual_control' and val = 'Off')
	    );
    if exists (select * from default_policy_opts) then
	insert into SQLDefn (txt)
	    select 'ALTER LOGIN POLICY "root" ' || @newline ||
	    (select list('    ' || option_name || ' = ' || option_value, @newline order by option_name, option_value )
	    from default_policy_opts);
    end if;
    insert into SQLDefn (txt)
	select 'CREATE LOGIN POLICY "' || login_policy_name || '" ' || @newline ||
	    (select list('    ' || login_option_name || ' = ' || login_option_value, @newline order by login_option_name, login_option_value )
	    from SYS.SYSLOGINPOLICYOPTION lpo
	    where lpo.login_policy_id = lp.login_policy_id and login_option_name not in ('ldap_refresh_dn'))
	from SYS.SYSLOGINPOLICY lp
	where login_policy_name <> 'root'
	order by login_policy_id;
    insert into SQLDefn (txt)
	select f_unload_object_comment( 'LOGIN POLICY', null, login_policy_name, null, r.remarks )
	from SYS.SYSLOGINPOLICY lp
		join SYS.SYSREMARK r ON (lp.login_policy_id = r.object_id)
	order by login_policy_id;
end
go

create temporary procedure sa_unload_extern_envs()
begin
    call sa_unload_script_comment( 'Create external environments' );
    if f_unload_table_exists( 'SYSEXTERNENV' ) = 0 then
	return;
    end if;
    insert into SQLDefn (txt)
        SELECT 'IF EXISTS( SELECT * FROM SYS.SYSEXTERNENV WHERE name = ''' ||
		    name || ''' ) THEN ' || @newline ||
	    '    ALTER EXTERNAL ENVIRONMENT "' || name || '"' || @newline ||
	    '        LOCATION ''' || location || ''' ' || @newline ||
	    'END IF ' 
	FROM SYS.SYSEXTERNENV;
    insert into SQLDefn (txt)
	select f_unload_object_comment( 'EXTERNAL ENVIRONMENT', null, name, null, r.remarks )
	from SYS.SYSEXTERNENV ext
		join SYS.SYSREMARK r ON (ext.object_id = r.object_id)
	where r.remarks is not null;
    
    call sa_unload_script_comment( 'Create external environment objects' );
    if f_unload_table_exists( 'SYSEXTERNENVOBJECT' ) = 0 then
	return;
    end if;
    if not exists (select * from SYS.SYSEXTERNENVOBJECT) then
	return;
    end if;
    insert into SQLDefn (txt)
        values( 'CREATE VARIABLE @byte_code long binary' );
    insert into SQLDefn (need_delim,txt)
	SELECT 0,
	       '-- object: ' || o.name || @newline ||
	       f_unload_binary_string( o.contents, 1 ) || @cmdsep ||
	       'INSTALL EXTERNAL OBJECT ''' || o.name || ''' NEW FROM VALUE @byte_code ENVIRONMENT ' || e.name ||
	       ' AS USER "' || cr.user_name || '"' || @cmdsep
	FROM SYS.SYSEXTERNENV e JOIN SYS.SYSEXTERNENVOBJECT o
	       ON( e.object_id = o.extenv_id )
	     JOIN sa_unload_users_list cr ON (cr.user_id = o.owner);
    insert into SQLDefn (txt)
        values( 'DROP VARIABLE @byte_code' );
    insert into SQLDefn (txt)
	select f_unload_object_comment( 'EXTERNAL ENVIRONMENT OBJECT', null, o.name, null, r.remarks )
	from SYS.SYSEXTERNENVOBJECT o
		join SYS.SYSREMARK r ON (o.object_id = r.object_id)
	where r.remarks is not null;
end
go

create temporary procedure sa_unload_certificates()
begin
    call sa_unload_script_comment( 'Create certificates' );
    if f_unload_table_exists( 'SYSCERTIFICATE' ) = 0 then
	return;
    end if;
    if not exists (select * from SYS.SYSCERTIFICATE) then
	return;
    end if;
    insert into SQLDefn (txt)
        values( 'CREATE VARIABLE @certificate_contents long binary' );
    insert into SQLDefn (need_delim,txt)
	SELECT 0,
	       '-- certificate: ' || c.cert_name || @newline ||
	       'set @certificate_contents = ' || f_unload_binary_string( c.contents, 0 ) || @cmdsep ||
	       'CREATE CERTIFICATE "' || c.cert_name || '" FROM @certificate_contents' || @cmdsep
	FROM SYS.SYSCERTIFICATE c
	     ORDER BY update_time;
    insert into SQLDefn (txt)
        values( 'DROP VARIABLE @certificate_contents' );
    insert into SQLDefn (txt)
	select f_unload_object_comment( 'CERTIFICATE', null, c.cert_name, null, r.remarks )
	from SYS.SYSCERTIFICATE c
		join SYS.SYSREMARK r ON (c.object_id = r.object_id)
	where r.remarks is not null;
end
go

create temporary procedure sa_unload_ldap_servers()
begin
    call sa_unload_script_comment( 'Create ldap servers' );
    if f_unload_table_exists( 'SYSLDAPSERVER' ) = 0 then
	return;
    end if;
    if not exists (select * from SYS.SYSLDAPSERVER) then
	return;
    end if;
    insert into SQLDefn (need_delim,txt)
	SELECT 0,
	       '-- ldap server: ' || l.ldsrv_name || @newline ||
	       'CREATE LDAP SERVER "' || l.ldsrv_name || '"' || @newline ||
	       '    SEARCH DN' || @newline ||
	       '        URL ' || if ldsrv_search_url is null then 'NULL' else '''' || ldsrv_search_url || '''' endif || @newline ||
	       '        ACCESS ACCOUNT ' || if ldsrv_access_dn is null then 'NULL' else '''' || ldsrv_access_dn || '''' endif || @newline ||
	       '        IDENTIFIED BY ENCRYPTED ' || if ldsrv_access_dn_pwd is null then 'NULL' else '''' || f_unload_hex_string( ldsrv_access_dn_pwd ) || '''' endif || @newline ||
	       '    AUTHENTICATION URL ' || if ldsrv_auth_url is null then 'NULL' else '''' || ldsrv_auth_url || '''' endif || @newline ||
	       '    CONNECTION TIMEOUT ' || ldsrv_timeout || @newline ||
	       '    CONNECTION RETRIES ' || ldsrv_num_retries || @newline ||
	       '    TLS ' || if ldsrv_start_tls = 1 then 'ON' else 'OFF' endif || @newline ||
	       if ldsrv_state in( 'READY', 'ACTIVE' ) then '    WITH ACTIVATE' else '' endif || @cmdsep
	FROM SYS.SYSLDAPSERVER l;
    insert into SQLDefn (txt)
	select f_unload_object_comment( 'LDAP SERVER', null, l.ldsrv_name, null, r.remarks )
	from SYS.SYSLDAPSERVER l
		join SYS.SYSREMARK r ON (l.ldsrv_id = r.object_id)
	where r.remarks is not null;
end
go

create temporary procedure sa_unload_users()
begin	
    declare local temporary table recreate_user (
	line	    unsigned int    not null default autoincrement,
	txt	    long varchar    not null,
	primary key (line)
    ) in system not transactional;
    declare local temporary table unload_user(
	user_id	    unsigned int    not null,
	order_col   unsigned int    not null,
	primary key (user_id)
    ) in system not transactional;

    call sa_unload_display_status( 17202 );
    call sa_unload_script_comment( 'Create users' );

    insert into unload_user
	select u.user_id, if @name_order = 0 then u.user_id else number() endif
	from sa_unload_users_list u
	where (@extracting = 0 OR 
		    exists (select * from sa_extract_users eu
			    where eu.user_id = u.user_id))
	order by u.user_name;

    -- For Old DBs: Fail unload if database contains users like 'SYS_%_ROLE'.
    if @has_rbac = 0 then
	
	begin
	    declare invalid_users exception for sqlstate '08WB3'; 
	    if exists (select * from SYS.SYSUSERPERM
	                where user_name LIKE 'SYS_%_ROLE'
	                and user_name != 'SYS_SPATIAL_ADMIN_ROLE') then
	                signal invalid_users;
	    end if;
	end;
    end if;

    insert into SQLDefn (txt)
	SELECT 'GRANT CONNECT' ||
	    if u.resourceauth  = 'Y' then ',RESOURCE'  endif ||
	    if u.dbaauth     = 'Y' then ',DBA'	     endif ||
	    if u.scheduleauth  = 'Y' then ',SCHEDULE'  endif ||
	    if u.remotedbaauth = 'Y' then ',REMOTE DBA' endif ||
	    if u.user_group    = 'Y' then ',GROUP'     endif ||
	    ' TO "' || u.user_name || '"' ||
	    if @preserve_ids = 1 then ' AT ' || u.user_id endif ||
	    if u.user_name = 'DBA' then
		' IDENTIFIED BY sql'
	    else 
		if u.password is not null then 
		    ' IDENTIFIED BY ENCRYPTED ''' || 
			f_unload_hex_string(u.password) || '''' 
		endif
	    endif ||
	    if u.remarks is not null then
		@cmdsep ||
		f_unload_object_comment( 'USER', null, u.user_name, null, u.remarks )
	    endif
	FROM SYS.SYSUSERPERM u 
	    JOIN sa_unload_users_list sl ON ( u.user_id = sl.user_id )
	    JOIN unload_user uu ON (uu.user_id = u.user_id)
	WHERE u.user_name NOT IN ('SYS','PUBLIC','SA_DEBUG','rs_systabgroup',
			    'diagnostics', 'dbo')
	AND    u.user_id <= 2147483647
	AND    sl.user_type <> ( 0x1 | 0x4 | 0x8 )
	-- Skip Pure Mutable Roles 
	AND    (@extracting = 0 OR 
		    exists (select * from sa_extract_users eu
			    where eu.user_id = u.user_id))
	ORDER BY uu.order_col;
    insert into SQLDefn (txt)
	select r.txt from recreate_user r;
    if f_unload_table_exists( 'SYSLOGINPOLICY' ) = 1 then
	
	insert into sa_unload_stage1 (id,sub,defn)
	    select uu.order_col,1,
	    'ALTER USER "' || user_name || '" ' || @newline ||
		'    LOGIN POLICY "' || login_policy_name || '"'
	    from SYS.SYSUSER u
		join unload_user uu on (uu.user_id = u.user_id)
		join SYS.SYSLOGINPOLICY lp on (u.login_policy_id = lp.login_policy_id)
	    where login_policy_name <> 'root';
	
	insert into sa_unload_stage1 (id,sub,defn)
	    select uu.order_col,2,
		'ALTER USER "' || user_name || '" ' || @newline ||
		'    FORCE PASSWORD CHANGE ' || 
		    if expire_password_on_login = 1 then 'ON' else 'OFF' endif
	    from SYS.SYSUSER u
		join unload_user uu on (uu.user_id = u.user_id)
		join SYS.SYSLOGINPOLICY lp on (u.login_policy_id = lp.login_policy_id)
	    where expire_password_on_login = 1
	    
	    or (select sum( (if login_option_value = 'On' then 1 else -1 endif) *
			    (if login_policy_name = 'root' then 1 else 100 endif) )
		    from SYS.SYSLOGINPOLICY lp2
			join SYS.SYSLOGINPOLICYOPTION lpo ON (lp2.login_policy_id = lpo.login_policy_id)
		    where (lpo.login_policy_id = lp.login_policy_id
			or lp2.login_policy_name = 'root')
		    and login_option_name = 'password_expiry_on_next_login') > 0;
	call sa_unload_staged_text1();
    end if;
    if @has_rbac = 0 then
	insert into SQLDefn (txt)
	    SELECT 'REVOKE MEMBERSHIP IN GROUP PUBLIC FROM "' || u.user_name || '"'
	    FROM 
		
		sa_unload_users_list u 
		JOIN unload_user uu ON (uu.user_id = u.user_id)
	    WHERE u.user_name NOT IN ('SYS','PUBLIC','SA_DEBUG','rs_systabgroup',
				'diagnostics','dbo')
	    AND    u.user_id <= 2147483647
	    AND    (@extracting = 0 OR 
			exists (select * from sa_extract_users eu
				where eu.user_id = u.user_id))
	    AND NOT EXISTS (SELECT * FROM SYS.SYSGROUP
			    WHERE group_id = 2 
			    AND group_member = u.user_id) 
	    ORDER BY uu.order_col;
    else 
	call sa_unload_rbac();
    end if;
end
go

create temporary procedure sa_unload_rbac()
begin
    create local temporary table sa_unload_roles_list (
	role_id	    unsigned int    not null,
	role_name   char(128)       not null,
	user_type   tinyint         not null,
	primary key (role_id)
    ) in system not transactional;
    create local temporary table sa_unload_role_adminlist (
	role_id	    unsigned int    not null,
	grantee_id  unsigned int    not null,
	grantee     char(128)       not null,
	primary key (role_id, grantee_id)
    ) in system not transactional;
    create local temporary table sa_unload_role_grantlist (
	role_id	    unsigned int    not null,
	role_name   char(128)       not null,
	grantee_id  unsigned int    not null,
	grantee     char(128)       not null,
	primary key (role_id, grantee_id)
    ) in system not transactional;
    create local temporary table sa_unload_sys_role_grantlist (
	role_id	    unsigned int    not null,
	role_name   char(128)       not null,
	grantee_id  unsigned int    not null,
	grantee     char(128)       not null,
	grant_type  tinyint         not null,
	primary key (role_id, grantee_id)
    ) in system not transactional;

    create local temporary table sa_unload_syspriv_grantlist (
	role_id	    unsigned int    not null,
	role_name   char(128)       not null,
	grantee_id  unsigned int    not null,
	grantee     char(128)       not null,
	grant_type  tinyint         not null,
	primary key (role_id, grantee_id)
    ) in system not transactional;

    create local temporary table sa_unload_sysudr_grantlist (
	role_id	    unsigned int    not null,
	role_name   char(128)       not null,
	grantee_id  unsigned int    not null,
	grantee     char(128)       not null,
	grant_type  tinyint         not null,
	primary key (role_id, grantee_id)
    ) in system not transactional;

    create local temporary table sa_unload_setuser_grantlist (
    	grant_id    unsigned int    not null,
	grantee     char(128)	    not null,
	grant_scope tinyint 	    not null,
	primary key (grant_id)
    ) in system not transactional;

    create local temporary table sa_unload_changepwd_grantlist (
    	grant_id    unsigned int    not null,
	grantee     char(128)	    not null,
	grant_scope tinyint 	    not null,
	primary key (grant_id)
    ) in system not transactional;

    create local temporary table sa_unload_extgrantlist (
    	grant_id    unsigned int    not null,
	username    char(128) 	    not null
    ) in system not transactional;

    call sa_unload_script_comment( 'Create role definitions' );

    truncate table sa_unload_roles_list;
    truncate table sa_unload_role_adminlist;
    truncate table sa_unload_role_grantlist;
    truncate table sa_unload_sys_role_grantlist;
    truncate table sa_unload_syspriv_grantlist;
    truncate table sa_unload_sysudr_grantlist;
    truncate table sa_unload_setuser_grantlist;
    truncate table sa_unload_changepwd_grantlist;
    truncate table sa_unload_extgrantlist;

--  Table with a row for each UDR/extended role
    insert into sa_unload_roles_list
        select user_id, user_name, user_type from sa_unload_users_list
	WHERE user_name NOT IN ('SYS','PUBLIC','SA_DEBUG','rs_systabgroup',
			    'diagnostics','dbo')
	AND    user_id <= 2147483647
	AND    (user_type = ( 0x1 | 0x4 | 0x8 ) or user_type = ( 0x2 | 0x4 | 0x8 ) );

--  Table with a row for each admin of a UDR/extended role
--  This also includes grants to Mutable System Roles
    insert into sa_unload_role_adminlist
        SELECT rg.role_id, rg.grantee, u.user_name
        from SYS.SYSROLEGRANT rg
		JOIN sa_unload_users_list u ON (rg.grantee = u.user_id)
	WHERE rg.role_id <= 2147483647 AND
	        rg.role_id NOT IN 
	            ( select user_id from sa_unload_users_list WHERE user_name IN 
	                ('SYS','PUBLIC','SA_DEBUG','rs_systabgroup','diagnostics','dbo')
	            ) AND
	        (grant_type = ( 0x2 | 0x4 ) or grant_type = ( 0x2 | 0x1 | 0x4 ));

--  Table with a row for each grant of a UDR/extended role
--  This also includes grants to Mutable System Roles
    insert into sa_unload_role_grantlist
        SELECT rg.role_id, r.user_name, rg.grantee, u.user_name
        from SYS.SYSROLEGRANT rg
		JOIN sa_unload_users_list r ON (rg.role_id = r.user_id)
		JOIN sa_unload_users_list u ON (rg.grantee = u.user_id)
	WHERE rg.role_id <= 2147483647 AND
	        rg.role_id NOT IN 
	            ( select user_id from sa_unload_users_list WHERE user_name IN 
	                ('SYS','PUBLIC','SA_DEBUG','rs_systabgroup','diagnostics','dbo')
	            ) AND
	        (grant_type = ( 0x1 | 0x4 ) or grant_type = ( 0x2 | 0x1 | 0x4 ));

--  Table with a row for each grant of following System Roles
-- 'SYS','dbo','PUBLIC','SA_DEBUG','rs_systabgroup','diagnostics','SYS_SPATIAL_ADMIN_ROLE'
    -- 1. 'SYS': All 'SYS' role grants except grants to 'PUBLIC' and 'dbo' 
    insert into sa_unload_sys_role_grantlist
        SELECT rg.role_id, r.user_name, rg.grantee, u.user_name, grant_type
        from SYS.SYSROLEGRANT rg
		JOIN sa_unload_users_list r ON (rg.role_id = r.user_id)
		JOIN sa_unload_users_list u ON (rg.grantee = u.user_id)
	WHERE rg.grantee <= 2147483647 AND
	        rg.role_id IN 
	            ( select user_id from sa_unload_users_list WHERE user_name IN 
	                ('SYS')
	            ) AND
	        rg.grantee NOT IN 
	            ( select user_id from sa_unload_users_list WHERE user_name IN 
	                ('PUBLIC','dbo')
	            );
    -- 2. 'dbo': All 'dbo' role grants except grants to 'PUBLIC'
    insert into sa_unload_sys_role_grantlist
        SELECT rg.role_id, r.user_name, rg.grantee, u.user_name, grant_type
        from SYS.SYSROLEGRANT rg
		JOIN sa_unload_users_list r ON (rg.role_id = r.user_id)
		JOIN sa_unload_users_list u ON (rg.grantee = u.user_id)
	WHERE rg.grantee <= 2147483647 AND
	        rg.role_id IN 
	            ( select user_id from sa_unload_users_list WHERE user_name IN 
	                ('dbo')
	            ) AND
	        rg.grantee NOT IN 
	            ( select user_id from sa_unload_users_list WHERE user_name IN 
	                ('PUBLIC')
	            );
    -- 3. 'PUBLIC' role grants to UDRs (excluding Extended Roles)
    insert into sa_unload_sys_role_grantlist
        SELECT rg.role_id, r.user_name, rg.grantee, u.user_name, grant_type
        from SYS.SYSROLEGRANT rg
		JOIN sa_unload_users_list r ON (rg.role_id = r.user_id)
		JOIN sa_unload_users_list u ON (rg.grantee = u.user_id)
	WHERE rg.grantee <= 2147483647 AND
	        rg.role_id IN 
	            ( select user_id from sa_unload_users_list WHERE user_name IN 
	                ('PUBLIC')
	            ) AND
	        u.user_type = ( 0x1 | 0x4 | 0x8 );
    -- 4. 'SA_DEBUG','rs_systabgroup','diagnostics','SYS_SPATIAL_ADMIN_ROLE'
    insert into sa_unload_sys_role_grantlist
        SELECT rg.role_id, r.user_name, rg.grantee, u.user_name, grant_type
        from SYS.SYSROLEGRANT rg
		JOIN sa_unload_users_list r ON (rg.role_id = r.user_id)
		JOIN sa_unload_users_list u ON (rg.grantee = u.user_id)
	WHERE rg.grantee <= 2147483647 AND
	        rg.role_id IN 
	            ( select user_id from sa_unload_users_list WHERE user_name IN 
	                ('SA_DEBUG','rs_systabgroup','diagnostics','SYS_SPATIAL_ADMIN_ROLE', 'SYS_REPLICATION_ADMIN_ROLE', 'SYS_SAMONITOR_ADMIN_ROLE')
	            );

--  Table with a row for each SYSTEM PRIVILEGE grant
--  This also includes System Privilege Grants to Mutable System Roles
    insert into sa_unload_syspriv_grantlist
        SELECT SYSPRIV.sys_priv_id, SYSPRIV.sys_priv_name, rg.grantee, u.user_name, grant_type
        from SYS.SYSROLEGRANT rg
		JOIN dbo.sp_sys_priv_role_info() SYSPRIV ON (SYSPRIV.sys_priv_id = rg.role_id)
		JOIN sa_unload_users_list u ON (rg.grantee = u.user_id)
	WHERE u.user_name NOT LIKE 'SYS_AUTH_%_ROLE' AND 
	      ( rg.grant_scope IS NULL OR rg.grant_scope = 0x1 );
        -- Skip System Privilege Grants to Authority System Roles and 
	-- extended grants

    -- Skip the Out-Of-the-Box System Privilege Grants to
    -- 'SYS_SPATIAL_ADMIN_ROLE', 'SA_DEBUG', 'SYS_RUN_REPLICATION_ROLE'
    -- 'SYS_REPLICATION_ADMIN_ROLE', 'SYS_SAMONITOR_ADMIN_ROLE'
    delete from sa_unload_syspriv_grantlist
	where grantee = 'SYS_SPATIAL_ADMIN_ROLE' and
	    grant_type = ( 0x1 | 0x4 ) and
	    role_name = 'MANAGE ANY SPATIAL OBJECT';
    delete from sa_unload_syspriv_grantlist
	where grantee = 'SA_DEBUG' and
	    grant_type = ( 0x1 | 0x4 ) and
	    role_name = 'DEBUG ANY PROCEDURE';
    delete from sa_unload_syspriv_grantlist
	where grantee = 'SYS_RUN_REPLICATION_ROLE' and
	    grant_type = ( 0x1 | 0x4 ) and
	    role_name IN ( 'SELECT ANY TABLE', 'SET ANY USER DEFINED OPTION',
			   'SET ANY SYSTEM OPTION', 'BACKUP DATABASE', 'MONITOR', 'DROP CONNECTION' );
    delete from sa_unload_syspriv_grantlist
	where grantee = 'SYS_REPLICATION_ADMIN_ROLE' and
	    grant_type = ( 0x1 | 0x4 ) and
	    role_name IN ( 'MANAGE REPLICATION', 'SET ANY SYSTEM OPTION',
			   'SET ANY PUBLIC OPTION', 'SET ANY USER DEFINED OPTION', 'SELECT ANY TABLE',
			   'CREATE ANY PROCEDURE', 'DROP ANY PROCEDURE', 'MANAGE ANY WEB SERVICE',
			   'CREATE ANY TABLE', 'DROP ANY TABLE', 'SERVER OPERATOR', 'MANAGE ANY USER',
			   'MANAGE ROLES', 'MANAGE ANY OBJECT PRIVILEGE' );
    delete from sa_unload_syspriv_grantlist
	where grantee = 'SYS_SAMONITOR_ADMIN_ROLE' and
	    grant_type = ( 0x1 | 0x4 ) and
	    role_name IN ( 'ALTER ANY PROCEDURE', 'CHECKPOINT', 'CREATE ANY PROCEDURE',
	                   'CREATE ANY TABLE', 'MANAGE ANY EVENT', 'MANAGE ANY LOGIN POLICY',
			   'MANAGE ANY OBJECT PRIVILEGE', 'MANAGE ANY USER', 'SERVER OPERATOR' );
    delete from sa_unload_syspriv_grantlist
	where grantee = 'SYS_SAMONITOR_ADMIN_ROLE' and
	    grant_type = ( 0x2 | 0x1 | 0x4 ) and
	    role_name IN ( 'BACKUP DATABASE', 'CREATE EXTERNAL REFERENCE', 'MANAGE ANY DBSPACE',
			   'MONITOR' );

--  Table with a row for SET USER grants
     insert into sa_unload_setuser_grantlist
    	SELECT rg.grant_id, u.user_name, rg.grant_scope
	from SYS.SYSROLEGRANT rg
		JOIN dbo.sp_sys_priv_role_info() SYSPRIV ON ( SYSPRIV.sys_priv_id = rg.role_id )
		JOIN sa_unload_users_list u ON ( rg.grantee = u.user_id )
	WHERE SYSPRIV.sys_priv_role_name = 'SYS_SET_USER_ROLE' 
	AND ( rg.grant_scope = 0x2 
	      OR rg.grant_scope = 0x4 ); 

--  Table with a row for CHANGE PASSWORD grants
     insert into sa_unload_changepwd_grantlist
    	SELECT rg.grant_id, u.user_name, rg.grant_scope
	from SYS.SYSROLEGRANT rg
		JOIN dbo.sp_sys_priv_role_info() SYSPRIV ON ( SYSPRIV.sys_priv_id = rg.role_id )
		JOIN sa_unload_users_list u ON ( rg.grantee = u.user_id )
	WHERE SYSPRIV.sys_priv_role_name = 'SYS_CHANGE_PASSWORD_ROLE' 
	AND ( rg.grant_scope = 0x2 
	      OR rg.grant_scope = 0x4 ); 

--  Table with users present in SYSROLEGRANTEXT
     insert into sa_unload_extgrantlist
         SELECT rxg.grant_id, su.user_name 
	 from SYS.SYSROLEGRANTEXT rxg
	      JOIN sa_unload_users_list su ON ( rxg.user_id = su.user_id );

-- Table of Authority System Role GRANTs
    insert into sa_unload_sysudr_grantlist
        SELECT AUTH.role_id, AUTH.role_name, rg.grantee, u.user_name, grant_type
        from SYS.SYSROLEGRANT rg
		JOIN dbo.sp_auth_sys_role_info() AUTH ON (AUTH.role_id = rg.role_id)
		JOIN sa_unload_users_list u ON (rg.grantee = u.user_id)
	WHERE rg.grantee NOT IN ( select role_id from dbo.sp_auth_sys_role_info() );

    -- Set password to NULL if dual_password column is non-NULL:
    insert into SQLDefn (txt)
	SELECT 'ALTER USER "' || user_name || '" ' || @newline ||
	    '    IDENTIFIED BY NULL'
	from SYS.SYSUSER u
	where dual_password is not null;

-- Create UDRs with default admin 'MANAGE ROLES'
-- Resolve 1: The pure roles creation can be combined with 
--            user creation (GRANT CONNECT) in sa_unload_users()
-- Resolve 2: Investigate any special handling reqd for -no (name order schema only unload).
--            Generating SQL (CREATE ROLE) for pure roles with user creation (GRANT CONNECT) 
--            would be one solution to ensure name order.
    insert into SQLDefn (txt)
	SELECT 'CREATE ROLE ' ||
	    if rl.user_type  = ( 0x2 | 0x4 | 0x8 ) then 'FOR USER ' endif ||
                '"' || rl.role_name || '"'
	FROM sa_unload_roles_list rl
	ORDER BY rl.role_id;

-- Comment on user defined roles
-- Skip for user extended roles as COMMENT ON USER will already be generated
    insert into SQLDefn (txt)
        SELECT
         f_unload_object_comment( 'ROLE', null, u.user_name, null, r.remarks )
        FROM sa_unload_roles_list rl JOIN SYS.SYSUSER u on (rl.role_id = u.user_id)
        JOIN SYS.SYSREMARK r on (r.object_id = u.object_id)
        WHERE u.user_type = ( 0x1 | 0x4 | 0x8 )
        ORDER BY rl.role_id;

-- Comment on system auth roles
    insert into SQLDefn (txt)
        SELECT
         f_unload_object_comment( 'ROLE', null, AUTH.user_name ,null, r.remarks )
        FROM SYS.SYSUSER AUTH JOIN SYS.SYSUSER u on (AUTH.user_id = u.user_id)
        JOIN SYS.SYSREMARK r on (r.object_id = u.object_id)
        where AUTH.user_name LIKE 'SYS_AUTH_%_ROLE'
        ORDER BY AUTH.user_id;

-- Comment on system privilege roles
    insert into SQLDefn (txt)
        SELECT
         f_unload_object_comment( 'ROLE', null, SYSPRIV.sys_priv_role_name, null, r.remarks )
        FROM dbo.sp_sys_priv_role_info() SYSPRIV JOIN SYS.SYSUSER u on (SYSPRIV.sys_priv_id = u.user_id)
        JOIN SYS.SYSREMARK r on (r.object_id = u.object_id)
        ORDER BY SYSPRIV.sys_priv_id;

-- Comment on system roles
    insert into SQLDefn (txt)
        SELECT
         f_unload_object_comment( 'ROLE', null, ul.user_name, null, r.remarks )
        FROM sa_unload_users_list ul JOIN SYS.SYSUSER u on (ul.user_id = u.user_id)
        JOIN SYS.SYSREMARK r on (r.object_id = u.object_id)
        where u.user_name IN( 'SYS', 'PUBLIC', 'SA_DEBUG', 'rs_systabgroup', 'diagnostics', 'dbo', 'SYS_SPATIAL_ADMIN_ROLE', 'SYS_REPLICATION_ADMIN_ROLE', 'SYS_SAMONITOR_ADMIN_ROLE' )
        ORDER BY ul.user_id;

-- Grant UDRs
    insert into SQLDefn (txt)
	SELECT 'GRANT ROLE ' ||
                '"' || role_name || '" TO ' ||
                '"' || grantee || '"'
	FROM sa_unload_role_grantlist r
	WHERE (@extracting = 0 OR 
		    exists (select * from sa_extract_users eu
			    where eu.user_id = r.grantee_id))
	ORDER BY role_id;

-- For users and extended roles that were explicitly revoked MEMBERSHIP from PUBLIC role,
-- generate REVOKE ROLE PUBLIC.
	insert into SQLDefn (txt)
	    SELECT 'REVOKE ROLE PUBLIC FROM "' || u.user_name || '"'
	    FROM sa_unload_users_list u
		JOIN unload_user uu ON (uu.user_id = u.user_id)
	    WHERE u.user_name NOT IN ('SYS','PUBLIC','SA_DEBUG','rs_systabgroup',
				'diagnostics','dbo')
	    AND    u.user_id <= 2147483647
	    AND    u.user_type != ( 0x1 | 0x4 | 0x8 )
	    AND    (@extracting = 0 OR 
			exists (select * from sa_extract_users eu
				where eu.user_id = u.user_id))
	    AND NOT EXISTS (SELECT * FROM SYS.SYSGROUP
			    WHERE group_id = 2 
			    AND group_member = u.user_id) 
	    ORDER BY uu.order_col;

-- Re-Create UDRs with actual admins
    insert into SQLDefn (txt)
	SELECT 'CREATE OR REPLACE ROLE ' ||
	    if rl.user_type  = ( 0x2 | 0x4 | 0x8 ) then 'FOR USER ' endif ||
                '"' || rl.role_name || '"' ||
		' WITH ADMIN ONLY ' || 
	(select list('"' || grantee || '"' order by grantee ) 
            FROM sa_unload_role_adminlist rg 
            WHERE rl.role_id = rg.role_id)
	FROM sa_unload_roles_list rl
	ORDER BY rl.role_id;

-- Handle System Role Grants
    insert into SQLDefn (txt)
	SELECT 'GRANT ROLE ' ||
                '"' || role_name || '" TO ' ||
                '"' || grantee || '"' ||
	    case grant_type
	    when ( 0x2 | 0x4 )	then ' WITH ADMIN ONLY OPTION'
	    when ( 0x1 | 0x4 )	then ' WITH NO ADMIN OPTION'
	    when ( 0x2 | 0x1 | 0x4 )	then ' WITH ADMIN OPTION'
	    when ( 0x1 )	then ' WITH NO ADMIN OPTION'
	    -- This grant type applies only to 'SYS' role grant
	    else ''
	    -- This condition should never occur
	    end 
	FROM sa_unload_sys_role_grantlist p
	WHERE (@extracting = 0 OR 
		    exists (select * from sa_extract_users eu
			    where eu.user_id = p.grantee_id))
	ORDER BY role_id;

-- Handle System Privilege Grants
    insert into SQLDefn (txt)
	SELECT 'GRANT ' ||
                role_name || ' TO ' ||
                '"' || grantee || '"' ||
	    case grant_type
	    when ( 0x2 | 0x4 )	then ' WITH ADMIN ONLY OPTION'
	    when ( 0x1 | 0x4 )	then ' WITH NO ADMIN OPTION'
	    when ( 0x2 | 0x1 | 0x4 )	then ' WITH ADMIN OPTION'
	    else ''
	    -- This condition should never occur
	    end 
	FROM sa_unload_syspriv_grantlist p
	WHERE (@extracting = 0 OR 
		    exists (select * from sa_extract_users eu
			    where eu.user_id = p.grantee_id))
	ORDER BY role_id;
	
-- Handle Extended Set User grants
    insert into SQLDefn(txt)
    	SELECT 'GRANT SET USER ( ' ||
	    case grant_scope 
	    when 0x2 	then ''
	    when 0x4  	then 'ANY WITH ROLES '
	    else ''
	    -- This condition should never occur
	    end
	    ||
	    ( select list( '"' || username || '"' ) 
            FROM sa_unload_extgrantlist sux
	    WHERE sux.grant_id = su.grant_id )
	    || ' ) TO "' || grantee || '"'
	FROM sa_unload_setuser_grantlist su 
	ORDER BY su.grant_id;

-- Handle Extended Change Password grants
    insert into SQLDefn(txt)
    	SELECT 'GRANT CHANGE PASSWORD ( ' ||
	    case grant_scope 
	    when 0x2 	then ''
	    when 0x4  	then 'ANY WITH ROLES '
	    else ''
	    -- This condition should never occur
	    end
	    ||
	    ( select list( '"' || username || '"' ) 
            FROM sa_unload_extgrantlist sux
	    WHERE sux.grant_id = su.grant_id )
	    || ' ) TO "' || grantee || '"'
	FROM sa_unload_changepwd_grantlist su 
	ORDER BY su.grant_id;

-- Handle Authority System ROLE Grants
-- This code will generate GRANT ROLE syntax for Authority grants.
    insert into SQLDefn (txt)
	SELECT 'GRANT ROLE ' ||
                '"' || role_name || '" TO ' ||
                '"' || grantee || '"' ||
	    case grant_type
	    when ( 0x1 )	then ' WITH NO SYSTEM PRIVILEGE INHERITANCE'
	    when ( 0x2 | 0x4 )	then ' WITH ADMIN ONLY OPTION'
	    when ( 0x2 | 0x1 ) then ' WITH ADMIN OPTION' ||
			' WITH NO SYSTEM PRIVILEGE INHERITANCE'
	    when ( 0x1 | 0x4 )	then ' WITH NO ADMIN OPTION'
	    when ( 0x2 | 0x1 | 0x4 )	then ' WITH ADMIN OPTION'
	    else ''
	    -- This condition should never occur
	    end 
	FROM sa_unload_sysudr_grantlist u
	WHERE (@extracting = 0 OR 
		    exists (select * from sa_extract_users eu
			    where eu.user_id = u.grantee_id))
	ORDER BY role_id;

    -- Drop Authority System Roles (except DBA) that dont exist in source database
    insert into SQLDefn (txt)
	SELECT 'DROP ROLE ' || '"' || role_name || '" WITH REVOKE'
	FROM dbo.sp_auth_sys_role_info()
	WHERE auth != 'DBA'
	AND NOT EXISTS (SELECT * FROM sa_unload_users_list WHERE role_id = user_id);

end
go

create temporary procedure sa_unload_group_memberships()
begin
    if @has_rbac = 1 then
	return;
    end if;
    call sa_unload_script_comment( 'Create group memberships' );
    insert into SQLDefn (txt)
	SELECT 'GRANT MEMBERSHIP IN GROUP "' || group_id.user_name || '"' ||
		' TO "' || mbr.user_name || '"' 
	FROM sa_unload_users_list group_id 
		JOIN SYS.SYSGROUP grp ON (group_id.user_id = grp.group_id)
		JOIN sa_unload_users_list mbr ON (mbr.user_id = grp.group_member)
	WHERE group_id.user_name not in ('PUBLIC','diagnostics')
	AND (mbr.user_name <> 'dbo' OR group_id.user_name <> 'SYS')
	AND (mbr.user_name <> 'PUBLIC' OR 
		(group_id.user_name <> 'SYS' AND group_id.user_name <> 'dbo'))
	AND    (@extracting = 0 OR 
		    exists (select * from sa_extract_users eu
			    where eu.user_id = mbr.user_id))
	order by group_id.user_name, mbr.user_name;
end
go

create temporary procedure sa_unload_user_types()
begin
    call sa_unload_script_comment( 'Create user types' );
    insert into SQLDefn (need_delim,txt)
	SELECT 0,
	    'CREATE DOMAIN "' || type_name || '" ' || 
	    domain_name ||
	    case
	    when domain_name = 'numeric' or domain_name = 'decimal' then
		'(' || width || ',' || scale || ')'
	    when domain_name IN ('nchar','nvarchar','binary','varbinary','varbit') then 
		'(' || width || ')' 
	    when domain_name IN ('char','varchar') then
		if scale = 1 then
		    '(' || width || ' CHAR)'
		else
		    '(' || width || ')'
		endif
	    end ||
	    case nulls
	    when 'Y' then ' NULL'
	    when 'N' then ' NOT NULL'
	    else ''
	    end ||
	    if "default" is not null then ' DEFAULT ' || "default" endif ||
	    if "check" is not null then ' ' || "check" endif ||
	    ' AS USER "' || cr.user_name || '"' || @cmdsep
	FROM SYS.SYSUSERTYPE t
		JOIN SYS.SYSDOMAIN d ON (t.domain_id = d.domain_id)
		JOIN sa_unload_users_list cr ON (t.creator = cr.user_id)
	WHERE t.creator <> 0
	AND   domain_name <> 'java.lang.Object'
	AND   type_name not in ('money')
	ORDER BY t.domain_id;
end
go

create temporary procedure sa_unload_sequences()
begin
    if f_unload_table_exists( 'ISYSSEQUENCE' ) = 0 then
	return;
    end if;
    call sa_unload_display_status( 19984 );
    call sa_unload_script_comment( 'Create sequences' );
    insert into SQLDefn (txt)
	SELECT 
	    'CREATE SEQUENCE "' || cr.user_name || '".'
	    || '"' || sequence_name || '"'
	    || ' MINVALUE ' || min_value
	    || ' MAXVALUE ' || max_value
	    || ' INCREMENT BY ' || increment_by
	    || ' START WITH ' || if @no_data = 1 then start_with else resume_at endif
	    || if cycle = 0 then ' NO CYCLE ' else ' CYCLE ' endif
	    || if cache = 0 then ' NO CACHE ' else ' CACHE ' || cache endif
	FROM SYS.SYSSEQUENCE s
		JOIN sa_unload_users_list cr ON (s.owner = cr.user_id)
	ORDER BY s.object_id;
    insert into SQLDefn( txt)
	SELECT 
	    'GRANT USAGE ON SEQUENCE "' || cr.user_name || '"."'
	    || sequence_name || '"'
	    || ' TO "' || grntee.user_name || '"'
	FROM SYS.SYSSEQUENCE s
		JOIN SYS.SYSSEQUENCEPERM p on p.sequence_id = s.object_id
		JOIN sa_unload_users_list grntee on grntee.user_id = p.grantee
		JOIN sa_unload_users_list cr ON (s.owner = cr.user_id)
	ORDER BY s.object_id;

    insert into SQLDefn( txt)
	SELECT f_unload_object_comment( 'SEQUENCE', cr.user_name, s.sequence_name, null, r.remarks )
	FROM SYS.SYSSEQUENCE s
		JOIN sa_unload_users_list cr ON (s.owner = cr.user_id),
		SYS.SYSREMARK r
	WHERE r.object_id = s.object_id;

end
go

create temporary procedure sa_unload_user_classes()
begin
    if @java_enabled = 0 then
	return;
    end if;
    call sa_unload_script_comment( 'Install user-defined classes' );
    insert into SQLDefn (txt)
	values( 'CREATE VARIABLE @byte_code long binary' );
    insert into SQLDefn (need_delim,txt)
	select 0,
	    '-- class: ' || class.class_name || @newline ||
	    f_unload_binary_string( jarcomp.contents, 1 ) || @cmdsep ||
	    'INSTALL JAVA ' ||
	    if jar.jar_name is not null then
		'UPDATE JAR ''' || jar.jar_name || ''' COMPONENT '
	    endif ||
	    'FROM @byte_code' ||
	    ' AS USER "' || cr.user_name || '"' || @cmdsep
	FROM SYS.SYSJAVACLASS class
		JOIN SYS.SYSJARCOMPONENT jarcomp 
		    ON (jarcomp.component_id = class.component_id)
		JOIN sa_unload_users_list cr ON (cr.user_id = class.creator)
		LEFT OUTER JOIN SYS.SYSJAR jar ON (jar.jar_id = class.jar_id)
	WHERE class.creator <> 0   
	  AND class.replaced_by IS NULL 
	  AND jarcomp.contents IS NOT NULL;
    insert into SQLDefn (txt)
	select f_unload_object_comment( 'JAVA CLASS', null, class_name, null, remarks )
	from SYS.SYSJAVACLASS class
	where remarks is not null;
    insert into SQLDefn (txt)
	select f_unload_object_comment( 'JAVA JAR', null, jar_name, null, remarks )
	from SYS.SYSJAR jr
	where remarks is not null;
    insert into SQLDefn (txt)
	values( 'DROP VARIABLE @byte_code' );
end
go

create temporary procedure sa_unload_set_table_list()
begin
    truncate table sa_unloaded_table_complete;
    if @table_list_provided = 1 and @exclude_tables = 0 then
	insert into sa_unloaded_table_complete (table_id,creator,file_id)
	    SELECT table_id,t.creator,t.file_id
	    FROM SYS.SYSTABLE t
		    JOIN sa_unload_users_list u ON (t.creator = u.user_id)
		    JOIN sa_unload_listed_table lt 
			ON (lt.user_name = u.user_name and lt.table_name = t.table_name)
	    WHERE table_type IN ('BASE','GBL TEMP','MAT VIEW') 
	    AND   u.user_name not in ('SYS','rs_systabgroup');
    else
	insert into sa_unloaded_table_complete (table_id,creator,file_id)
	    SELECT table_id,t.creator,t.file_id
	    FROM SYS.SYSTABLE t
		    JOIN sa_unload_users_list u ON (t.creator = u.user_id)
	    WHERE table_type IN ('BASE','GBL TEMP','MAT VIEW') 
	    AND   user_name not in ('SYS','rs_systabgroup')
	    and (@extracting = 0
		or exists (select * from sa_extract_tables et 
			    where et.table_id = t.table_id));
	if @table_list_provided = 1 and @exclude_tables = 1 then
	    delete from sa_unloaded_table_complete 
	    where table_id in 
		(select table_id 
		   from SYS.SYSTABLE t 
			JOIN sa_unload_users_list u ON (t.creator = u.user_id)
			JOIN sa_unload_listed_table lt 
			    ON (lt.user_name = u.user_name and lt.table_name = t.table_name));
	end if;
    end if;
    truncate table sa_unloaded_table;
    insert into sa_unloaded_table (table_id,creator,file_id)
	select tc.table_id,tc.creator,tc.file_id
	from sa_unloaded_table_complete tc
		JOIN SYS.SYSTABLE t ON (t.table_id = tc.table_id)
		JOIN sa_unload_users_list u ON (u.user_id = tc.creator)
	where t.table_type <> 'MAT VIEW'
	    and not exists
		    (select *
		     from sa_unload_jconnect_table jt
		     where jt.table_name=t.table_name)
	    and (u.user_name <> 'dbo'
	    or NOT EXISTS
		    (SELECT name 
		     FROM sa_unload_exclude_object
		     WHERE type IN ('U','E','D')
		     AND name=t.table_name
		     AND NOT name like 'rs_%'));
    truncate table sa_unload_table_used_java;
    insert into sa_unload_table_used_java
	select distinct table_id 
	from SYS.SYSCOLUMN c
	    JOIN SYS.SYSDOMAIN d on (d.domain_id = c.domain_id)
	where domain_name = 'java.lang.object';
    delete from sa_unloaded_table
	where table_id in (select table_id 
			    from sa_unload_table_used_java);
    update sa_unloaded_table t
	set first_pkcol=(select min(column_id) from SYS.SYSCOLUMN c
			 where c.table_id=t.table_id
			 and pkey='Y');
end
go

create temporary function unload_table_columnid_indexid( @table_id unsigned int )
returns long varchar
begin

    declare colidsrunlen long varchar;  
    declare indexidsrunlen long varchar;
    declare c1 int; 
    declare c2 int;     
    declare c3 int; 
    declare count int; 

    declare t1 int; 
    declare t2 int; 
    declare clid int;

    declare colidrange cursor for
        select * from colid_tab order by table_id,col_id;  
   
    declare indexidrange cursor for
        select * from colid_fpindexid_tab order by table_id, ind_id, col_id;
    
    set count=1;
    set colidsrunlen=' COLUMN ID ';
    set indexidsrunlen=' INDEX ID ';

    open colidrange;
    tabs1: loop
    fetch colidrange into t1,c1;
    if t1 = @table_id then
        set t2=t1;
        leave tabs1 end if;
    end loop;

    set c3=c1;
    set count=1;
    tabs2: loop
               fetch colidrange into t1,c2;
                  if SQLCODE <> 0 or t1 <> t2  then
		    set colidsrunlen = colidsrunlen || '(' || c3 || ',' || count || ')';	
		    leave tabs2
		  end if;
               if c1+1 = c2 then
                set count = count+1;
                set c1 = c2;
               else
		set colidsrunlen = colidsrunlen || '(' || c3 || ',' || count || '),';	
                set c3 = c2;
		set c1 = c2;
                set count = 1;
               end if;
         end loop;
    close colidrange;
    
    open indexidrange;
    tabs3: loop 
    fetch indexidrange into t1,c1,clid;
    if t1 = @table_id then 
        set t2=t1;
        leave tabs3 end if;
    end loop;

    set c3=c1;
    set count=1;
    tabs4: loop 
               fetch indexidrange into t1,c2,clid;
                  if SQLCODE <> 0 or t1 <> t2  then 
		    set indexidsrunlen = indexidsrunlen || '(' ||  c3 || ',' || count || ')';
                    leave tabs4
                  end if;
               if c1+1 = c2 then 
                set count = count+1;
                set c1 = c2;
               else 
	        set indexidsrunlen = indexidsrunlen || '(' ||  c3 || ',' || count || '),';
                set c3 = c2;
 		set c1 = c2;	
                set count = 1; 
               end if;
         end loop;
    close indexidrange;

    return colidsrunlen || indexidsrunlen;	

end
go
create temporary procedure sa_unload_table_definitions()
begin
    declare local temporary table unload_tabs (
	table_id	unsigned int	not null,
	object_id	unsigned bigint not null,
	order_col	unsigned int	not null,
	file_id		int		not null,
	last_page	int		not null,
	share_type	int		not null,
	table_type	char(10)	not null,
	table_name	char(128)	not null,
	user_name	char(128)	not null,
	existing_obj	char(1),
	remote_location long varchar,
	primary key (table_id)
    ) in system not transactional;
    declare local temporary table min_column_id (
	table_id	unsigned int	not null,
	column_id	unsigned int	not null,
	primary key (table_id)
    ) in system not transactional;
	
    call sa_unload_display_status( 17203 );
    call sa_unload_script_comment( 'Create tables' );
    if @has_omni_columns = 1 then 
	insert into unload_tabs
	    select tt.table_id, 
		    0,
		    t.table_id,
		    t.file_id, tt.last_page, 5, tt.table_type, 
		    tt.table_name, u.user_name, tt.existing_obj, tt.remote_location
	    FROM sa_unloaded_table t
		    JOIN SYS.SYSTABLE tt ON (t.table_id = tt.table_id)
		    JOIN sa_unload_users_list u ON (tt.creator = u.user_id)
	    order by u.user_name,tt.table_name;
    else
	insert into unload_tabs
	    select tt.table_id, 
		    0,
		    t.table_id,
		    t.file_id, tt.last_page, 5, tt.table_type, 
		    tt.table_name, u.user_name, NULL, NULL
	    FROM sa_unloaded_table t
		    JOIN SYS.SYSTABLE tt ON (t.table_id = tt.table_id)
		    JOIN sa_unload_users_list u ON (tt.creator = u.user_id)
	    order by u.user_name,tt.table_name;
    end if;
    call sa_make_table_ordering();
    if @name_order = 1 then
	update unload_tabs ut 
	    join sa_unload_table_ordering uo on (ut.table_id = uo.table_id)
	    set ut.order_col = uo.order_col;
    end if;
    insert into sa_unload_stage1 (id,sub,need_delim,defn)
	SELECT order_col, 0, 0, 
	'CREATE ' || 
	    case
	    when table_type = 'GBL TEMP' then 
		'GLOBAL TEMPORARY ' 
	    when remote_location is not null and existing_obj = 'Y' then
		'EXISTING '
	    end || 
	    'TABLE "' || user_name || '"."' || t.table_name || '" ('
	FROM unload_tabs t;

    insert into min_column_id (table_id,column_id)
	select t.table_id, min(column_id)
	FROM unload_tabs t
	    JOIN SYS.SYSCOLUMN c ON (c.table_id = t.table_id)
	GROUP BY t.table_id;

    insert into sa_unload_stage1 (id,sub,need_delim,defn)
	SELECT order_col,c.column_id,0,
	    if c.column_id = mc.column_id then '    ' else '   ,' endif ||
	    '"' || column_name || '" ' || repeat(' ',30-length(column_name)) || 
	    if ut.type_name is not null then
		if ut.type_name in ('bit','xml','uniqueidentifier') then
		    ut.type_name
		else
		    if ut.type_name = 'oldbit' then
			'bit'
		    else
			'"' || ut.type_name || '"'
		    endif
		endif
	    else
		domain_name ||
		    case
		    when domain_name = 'numeric' or domain_name = 'decimal' then
			'(' || c.width || ',' || c.scale || ')' 
		    when domain_name = 'char' or domain_name = 'varchar' then
			if c.scale = 1 then
			    '(' || c.width || ' CHAR)'
			else
			    '(' || c.width || ')'
			endif
		    when domain_name IN ( 'binary', 'varbinary', 'varbit', 'nchar', 'nvarchar' ) then 
			'(' || c.width || ')'
		    when domain_name = 'bit' then
			if c.width > 1 then
			    '(' || c.width || ')'
			endif
		    end 
	    endif ||
	    if c.nulls = 'Y' then ' NULL' else ' NOT NULL' endif ||
	    f_unload_column_default( c.table_id, c.column_id ) ||
	    f_unload_column_check( c.table_id, c.column_id )
	FROM unload_tabs t
		
		JOIN SYS.SYSCOLUMN c ON (t.table_id = c.table_id)
		JOIN min_column_id mc ON (t.table_id = mc.table_id)
		JOIN SYS.SYSDOMAIN d ON (c.domain_id = d.domain_id)
		LEFT OUTER JOIN SYS.SYSUSERTYPE ut ON (ut.type_id = c.user_type)
	WHERE (@extracting = 0
		or exists (select * from sa_extract_columns ec 
			    where ec.table_id = c.table_id
			    and ec.column_id = c.column_id))
        ORDER BY c.table_id,c.column_id;  

    call sa_unload_primary_keys();
	
    call sa_unload_constraints();

    call sa_unload_pctfree();
    
    insert into sa_unload_stage1 (id,sub,defn)
	SELECT order_col, 3000000,
		')' || 
		if t.file_id <> 0 and t.file_id <> 15
		and @profiling_uses_single_dbspace = 0
	    then ' IN "' || f.dbspace_name || '"' endif ||
		if remote_location is not null then
		    ' AT ' || f_unload_literal(remote_location) || ' LOCAL ONLY'
		endif ||
		if t.table_type = 'GBL TEMP' then
		    case last_page
		    when 0 then ' ON COMMIT PRESERVE ROWS'
		    when 1 then ' ON COMMIT DELETE ROWS'
		    when 3 then ' NOT TRANSACTIONAL'
		    end
		endif ||
		if t.share_type = 4 then
		    ' SHARE BY ALL'
		endif
	FROM unload_tabs t
		JOIN SYS.SYSFILE f ON (t.file_id = f.file_id);

    insert into sa_unload_stage1 (id,sub,defn)
	SELECT order_col, 6000000+c.column_id, 
	    f_unload_object_comment( 'COLUMN', user_name, t.table_name, column_name, c.remarks )
	FROM unload_tabs t
		JOIN SYS.SYSCOLUMN c ON (c.table_id = t.table_id)
	WHERE c.remarks is not null
	AND (@extracting = 0
		or exists (select * from sa_extract_columns ec 
			    where ec.table_id = c.table_id
			    and ec.column_id = c.column_id));
			    
    insert into sa_unload_stage1 (id,sub,defn)
	SELECT order_col, 7000000+column_id, 
	    'ALTER TABLE ' ||
		'"' || user_name || '"."' || table_name || '" ' || @newline ||
		if default_diff = 1 then
		    '    MODIFY "' || column_name || '" DEFAULT NULL' 
		endif ||
		if default_diff = 1 and check_diff = 1 then
		    ', ' || @newline
		endif ||
		if check_diff = 1 then
		    '    MODIFY "' || column_name || '" CHECK NULL' 
		endif 
	FROM 
	    (select order_col, t.table_id, c.column_id, 
		    user_name, c.column_name, t.table_name,
		    f_has_column_check( c.table_id, c.column_id ) as has_check,
		    if has_check = 0 and u."check" is not null then 1
		    else 0
		    endif as check_diff,
		    if c."default" is null and u."default" is not null then 1
		    else 0
		    endif as default_diff
	     from unload_tabs t
		JOIN SYS.SYSCOLUMN c ON (c.table_id = t.table_id)
		JOIN SYS.SYSUSERTYPE u ON (u.type_id = c.user_type)
	     where (@extracting = 0
		or exists (select * from sa_extract_columns ec 
			    where ec.table_id = c.table_id
			    and ec.column_id = c.column_id)) 
	     and (check_diff = 1 or default_diff = 1)
	    ) as chgs;
	
    call sa_unload_indexes( 1 );
    
    insert into sa_unload_stage1 (id,sub,defn)
	SELECT order_col, 20000000, 
	    f_unload_object_comment( 'TABLE', user_name, t.table_name, null, tt.remarks )
	FROM unload_tabs t
		JOIN SYS.SYSTABLE tt ON (tt.table_id = t.table_id)
	WHERE tt.remarks is not null;

    insert into sa_unload_stage1 (id,sub,defn)
	SELECT order_col, 21000000, 
	    'ALTER TABLE ' ||
		'"' || user_name || '"."' || t.table_name || '" REPLICATE ON'
	FROM unload_tabs t
		JOIN SYS.SYSTABLE tt ON (tt.table_id = t.table_id)
	WHERE tt.replicate = 'Y';
	
    if @has_named_constraints <> 0 then
	insert into sa_unload_stage1 (id,sub,defn)
	    select t.order_col, 22000000, 
		'ALTER INDEX PRIMARY KEY ON ' ||
		    '"' || user_name || '"."' || t.table_name || '" ' || 
		    'RENAME TO "' || t.table_name || '"'
	    from unload_tabs t
		LEFT OUTER JOIN SYS.SYSCONSTRAINT cns ON (cns.table_id = t.table_id and cns.column_id is null)
	    where constraint_type = 'P'
	    and substr(constraint_name,1,3) <> 'ASA';
    end if;

    insert into sa_unload_identity_tabs (table_id, user_name, table_name, order_col
	    )
	select table_id, user_name, table_name, order_col
	from unload_tabs;
	
    truncate table sa_unload_table_or_view;
    insert into sa_unload_table_or_view
	select u.table_id, u.order_col
	from unload_tabs u;
	
    call sa_unload_table_permissions();
    
    call sa_unload_staged_text1();

end
go

create temporary procedure sa_unload_define_tables()
begin
    truncate table sa_unload_data_with_mat;
    truncate table sa_unload_data;
    insert into sa_unload_data_with_mat (table_id, user_name, table_name)
	SELECT tt.table_id, u.user_name, tt.table_name
	FROM sa_unloaded_table_complete t
		JOIN SYS.SYSTABLE tt ON (tt.table_id = t.table_id)
		JOIN sa_unload_users_list u ON (tt.creator = u.user_id)
	WHERE tt.table_type IN ('BASE', 'MAT VIEW')

	AND   not exists
		(select *
		 from sa_unload_jconnect_table jt
		 where jt.table_name=tt.table_name)
	AND   (u.user_name <> 'dbo' OR
		NOT EXISTS
		    (SELECT name 
		     FROM sa_unload_exclude_object
		     WHERE type IN ('U','E','D')
		     AND name=tt.table_name
		     AND NOT name like 'rs_%'))
	ORDER BY t.table_id;
    
    if @table_list_provided = 0 or @data_only = 0 then
       delete from sa_unload_data_with_mat 
       	  where table_id in
		(select table_id
		from SYS.SYSTABLE
		where table_type = 'MAT VIEW');
    end if;
    if @has_omni_columns = 1 then
	delete from sa_unload_data_with_mat
	    where table_id in 
		(select table_id 
		from SYS.SYSTABLE 
		where remote_location is not null);
    end if;
    delete from sa_unload_data_with_mat
	where table_id in
	    (select table_id
	    from sa_unload_table_used_java);
    
    for l1 as c1 cursor for
	select user_name,table_name
	from sa_unload_data_with_mat tt
	where user_name = 'dbo'
	and exists
	    (SELECT name 
	     FROM sa_unload_exclude_object
	     WHERE type IN ('E','D')
	     AND name=tt.table_name
	     AND NOT name like 'rs_%')
    do
	execute immediate
	    'if not exists(select * ' ||
			    'from "' || user_name || '"."' || table_name || '") then ' ||
		'delete from sa_unload_data_with_mat ' ||
		'where user_name = ''' || user_name || ''' ' ||
		'and table_name = ''' || table_name || ''';' ||
	    'end if';
    end for;
    insert into sa_unload_data 
	(select * from sa_unload_data_with_mat 
		where table_id in 
			(select table_id
			from SYS.SYSTABLE
			where table_type <> 'MAT VIEW'));
    
    delete from sa_unloaded_table_complete 
	where table_id in
		(select table_id
		from SYS.SYSTABLE
		where table_type <> 'MAT VIEW');
end
go

create temporary procedure sa_unload_column_statistics()
begin
    declare @collation char(128);
    declare @pagesize int;
    
    if f_unload_table_exists( 'SYSCOLSTAT' ) = 0 then
	return;
    end if;
    if @exclude_statistics = 1 then
	return;
    end if; 
    call sa_unload_script_comment( 'Reload column statistics' );
    set @collation = db_property('Collation');
    set @pagesize = db_property('PageSize');
    insert into SQLDefn (txt) 
	SELECT 
	    'if db_property(''PageSize'') >= ' || @pagesize || 
	    if domain_id >= 7 and domain_id <= 12 then
		' and' || @newline ||
		'   db_property(''Collation'') = ''' || @collation || '''' 
	    endif ||		
	    ' then ' || @newline ||
		'    LOAD STATISTICS ' ||
			'"' || t.user_name || '"."' || t.table_name || '"."' || 
			    c.column_name || '" ' || @newline ||
		@tab ||
		    format_id || ', ' ||
		    density || ', ' || 
		    max_steps || ', ' ||
		    actual_steps || ', ' || @newline ||
		@tab || f_unload_binary_string( step_values, 0 ) || ',' || @newline ||
		@tab || f_unload_binary_string( frequencies, 0 ) || @newline ||
	    'end if'
	FROM sa_unload_data t
	    JOIN SYS.SYSCOLUMN c ON (c.table_id = t.table_id)
	    JOIN SYS.SYSCOLSTAT s 
		ON (s.table_id = c.table_id and s.column_id = c.column_id) 
	WHERE (@extracting = 0 
		or exists (select * from sa_extract_columns ec 
			    where ec.table_id = c.table_id
			    and ec.column_id = c.column_id))
	AND   (t.user_name <> 'dbo' OR
		NOT EXISTS
		    (SELECT name 
		     FROM sa_unload_exclude_object
		     WHERE type IN ('U','E','D')
		     AND name=t.table_name))
	ORDER BY c.table_id, c.column_id;
end
go

create temporary function f_unload_table_has_nchar_columns( @table_id int )
returns integer
begin
    return 0;
end
go

create temporary function f_unload_table_charset( @table_id int, authority char(50) )

returns long varchar
begin
    declare @charset long varchar;
    if f_unload_table_has_nchar_columns( @table_id ) != 0 then
	set @charset = 'UTF-8';
    elseif varexists( '@db_charset' ) != 0 then
	set @charset = @db_charset;
    elseif authority IS NULL then
	set @charset = db_property( 'Charset' );
    else
	set @charset = db_extended_property( 'Charset', authority );
    end if;
    return @charset;
end
go

create temporary procedure sa_unload_make_status_proc()
begin
    if @name_order = 1 then
	return;
    end if;
    insert into SQLDefn (txt)
	values(
	    'create temporary procedure sa_unload_display_table_status( ' || @newline ||
	    '    msgid int, ' ||
		'ord int, ' ||
		'numtabs int, ' ||
		'user_name char(128), ' ||
		'table_name char(128) )' || @newline ||
	    'begin ' || @newline ||
	    '  declare @fullmsg long varchar; ' || @newline ||
	    '  set @fullmsg = lang_message( msgid ) ||' || @newline ||		
	    '      '' ('' || ord || ''/'' || numtabs || '') '' ||' || @newline ||
	    '      ''"'' || user_name || ''"."'' || table_name || ''"''; ' || @newline ||
	    '  message ' ||
	    '@fullmsg type info to client; ' || @newline ||
	    'end' );
	    
end
go

create temporary procedure sa_unload_make_capability_proc()
begin
    insert into SQLDefn (txt)
	values(
	    'create temporary procedure sa_unload_define_capability( ' || @newline ||
	    '    srvname char(128), ' ||
		'capname char(128), ' ||
		'onoff char(3) ) ' || @newline ||
	    'begin ' || @newline ||
	    '  execute immediate ''alter server "'' || srvname || ''" '' || ' || @newline ||
	    '      ''CAPABILITY '''''' || capname || '''''' ''  || onoff; ' || @newline ||
	    ' exception when others then ' || @newline ||
	    'end' );
end
go

create temporary procedure sa_unload_load_statements( in data_dir long varchar )
begin
    declare @dir long varchar;
    declare @numtabs int;
    declare local temporary table unload_table (
	ord	    int not null primary key default autoincrement,
	table_id    unsigned int,
	user_name   char(128) not null,
	table_name  char(128) not null,
    ) in system not transactional;
    
    set @dir = replace(data_dir,'\\','/');
    if @reloading = 0 then
	call sa_unload_script_comment( 'Reload data' );
	insert into unload_table( table_id, user_name, table_name )
	    SELECT table_id, user_name, table_name
	    FROM sa_unload_data t
	    ORDER BY table_id;
	select count(*) into @numtabs from unload_table;
	if @show_index_progress = 1 and @name_order = 0 and @data_only = 0 then
	    insert into sa_unload_stage1 (id,sub,defn)
		select table_id,0, 
		    'call sa_unload_display_table_status( ' ||
			17737 || ', ' || 
			ord || ', ' || 
			@numtabs || ', ' ||
			f_unload_literal(user_name) || ', ' ||
			f_unload_literal(table_name) || ' )'
		from unload_table
		order by table_id;
	end if;
	if @internal_reload = 1 then
	    insert into sa_unload_stage1 (id,sub,defn)
		SELECT table_id,1,
			'LOAD TABLE "' || user_name || '"."' || table_name || '" ' ||
			if @extracting = 0 then 
			    '(' || (select list('"' || column_name || '"' 
						order by c.table_id,c.column_id)
				    from SYS.SYSCOLUMN c 
				    where c.table_id = t.table_id ) || ')'
			endif ||
			@newline || '    FROM ''' || @dir || table_id || '.dat''' ||
			if user_name = 'dbo' and 
			    table_name in ('ml_script','ml_user','ml_subscription') then
			    @newline || '    DEFAULTS ON'
			endif ||
			@newline || '    FORMAT ''TEXT'' QUOTES ON' ||
			@newline || '    ORDER OFF ESCAPES ON' ||
			@newline || '    CHECK CONSTRAINTS OFF COMPUTES OFF' ||
			@newline || '    STRIP OFF DELIMITED BY '',''' ||
			if @reloading = 1 then
			    
			    @newline || '    WITH CHECKPOINT OFF' 
			endif ||
			@newline ||
			    '    ENCODING ''' || f_unload_table_charset( table_id, NULL ) || '''' ||
			if @encrypted_output = 1 then 
			    @newline || '    ENCRYPTED KEY ''{encryption_key}'''
			endif
		FROM unload_table t
		ORDER BY table_id;
	else
	    insert into sa_unload_stage1 (id,sub,defn)
		SELECT table_id,1,
			'INPUT INTO "' || user_name || '"."' || table_name || '" ' ||
			@newline || '    FROM ''' || @dir || table_id || '.dat''' ||
			@newline || '    FORMAT TEXT' ||
			@newline || '    ESCAPE CHARACTER ''' || 
			    if @escape_char = '\\' then '\\\\' else @escape_char endif ||
			    '''' ||
			@newline || '    BY ORDER' ||	
			if @extracting = 0 then 
			    '(' || (select list('"' || column_name || '"' 
						order by c.table_id,c.column_id)
				    from SYS.SYSCOLUMN c 
				    where c.table_id = t.table_id ) || ')'
			endif ||
			@newline || '    ENCODING ''' || f_unload_table_charset( table_id, 'Java' ) || ''''
		FROM unload_table t
		ORDER BY table_id;
	end if;
	call sa_unload_staged_text1();
    end if;
end
go

create temporary procedure sa_unload_identity_values()
begin
    
    if @preserve_identities = 1 then
	
	call sa_unload_script_comment( 'Preserve identity values' );
	insert into sa_unload_stage1 (id,sub,defn)
	    SELECT order_col, c.column_id,
		'call dbo.sa_reset_identity(''' || t.table_name || ''', ''' || t.user_name || ''', ' || c.max_identity || ');'
	    FROM sa_unload_identity_tabs t
		JOIN SYS.SYSCOLUMN c ON (t.table_id = c.table_id)
	    WHERE
		c.max_identity > 0;
	call sa_unload_staged_text1();
    end if;
end
go

create temporary procedure sa_unload_foreign_keys()
begin
    declare local temporary table unloaded_fkeys (
	table_id	unsigned int	not null,
	
	fkey_id		int		not null,
	order_fk	unsigned int	not null,
	primary_table_id unsigned int	not null,
	role		char(128)	not null,
	check_on_commit char(1)		not null,
	nulls		char(1)		not null,
	is_gbl_temp	tinyint		not null,
	primary key (table_id,fkey_id) 
    ) in system not transactional;
  
    if @exclude_foreign_keys = 1 then
	return;
    end if; 
    insert into unloaded_fkeys 
	SELECT fk.foreign_table_id,fk.foreign_key_id,
		if @name_order = 0 then if foreign_key_id >= 0 then foreign_key_id else foreign_key_id+65536 endif else number() endif,
		fk.primary_table_id,fk.role,fk.check_on_commit,fk.nulls,
	    if table_type = 'GBL TEMP' then 1 else 0 endif
	FROM sa_unloaded_table t
		JOIN sa_unload_table_ordering ut ON (t.table_id = ut.table_id)
		JOIN SYS.SYSFOREIGNKEY fk ON (fk.foreign_table_id = t.table_id)
		JOIN SYS.SYSTABLE tt on (t.table_id = tt.table_id)
	WHERE (@extracting = 0 
		or fk.primary_table_id in (select table_id from sa_extract_tables))
	order by ut.order_col,fk.role;
    delete from unloaded_fkeys 
	where primary_table_id in (select table_id 
				    from sa_unload_table_used_java);
    
    insert into sa_unload_stage2 (id1,id2,sub,need_delim,defn)
	SELECT order_col,order_fk+100,0,0,
	    'ALTER TABLE ' ||
	    '"' || ut.user_name || '"."' || ut.table_name || '"'
	FROM unloaded_fkeys fk
		JOIN sa_unload_table_ordering ut ON (fk.table_id = ut.table_id);
    if @reloading = 1 then
	insert into sa_unload_stage2 (id1,id2,sub,need_delim,defn)
	    SELECT order_col,order_fk+100,1,0,
		@cmtbeg || 'Can use parallel INDEX creation' || @cmtend 
	    FROM unloaded_fkeys fk
		JOIN sa_unload_table_ordering ut ON (fk.table_id = ut.table_id)
	    WHERE fk.primary_table_id <= fk.table_id
	    and is_gbl_temp = 0;
    end if;
    insert into sa_unload_stage2 (id1,id2,sub,need_delim,defn)
	SELECT order_col,order_fk+100,2,0,
	    '    ADD ' ||
	    if nulls='N' then 'NOT NULL ' endif ||
	    'FOREIGN KEY "' || role || '" (' ||
	    (select list( '"' || column_name || '"' 
		    order by fkcol.foreign_table_id, fkcol.foreign_key_id, primary_column_id)
	    from SYS.SYSFKCOL fkcol
		JOIN SYS.SYSCOLUMN c 
			ON (fkcol.foreign_table_id = c.table_id
			    and fkcol.foreign_column_id = c.column_id)
	    where fkcol.foreign_table_id = fk.table_id
	    and fkcol.foreign_key_id = fk.fkey_id) || ')'
	FROM unloaded_fkeys fk
	    JOIN sa_unload_table_ordering ut ON (fk.table_id = ut.table_id);
    insert into sa_unload_stage2 (id1,id2,sub,need_delim,defn)
	SELECT order_col,order_fk+100,3,0,
	    '    REFERENCES "' || cr.user_name || '"."' || t.table_name || '" (' ||
	    (select list( '"' || column_name || '"' 
		    order by fkcol.foreign_table_id, fkcol.foreign_key_id, primary_column_id)
	    from SYS.SYSFKCOL fkcol
		JOIN SYS.SYSCOLUMN c 
			ON (fk.primary_table_id = c.table_id
			    and fkcol.primary_column_id = c.column_id)
	    where fkcol.foreign_table_id = fk.table_id
	    and fkcol.foreign_key_id = fk.fkey_id) || ')'
	FROM unloaded_fkeys fk
		JOIN sa_unload_table_ordering ut ON (fk.table_id = ut.table_id)
		JOIN SYS.SYSTABLE t ON (fk.primary_table_id = t.table_id)
		JOIN sa_unload_users_list cr ON (cr.user_id = t.creator);
    insert into sa_unload_stage2 (id1,id2,sub,need_delim,defn)
	SELECT order_col,order_fk+100,4,1,
	    (select '    ' ||
		    list( if event = 'D' then 'ON DELETE ' else 'ON UPDATE ' endif ||
			case referential_action
			when 'C' then 'CASCADE '
			when 'N' then 'SET NULL '
			when 'D' then 'SET DEFAULT '
			end, '' order by event )
		from SYS.SYSTRIGGER 
		WHERE foreign_table_id = fk.table_id
		AND   foreign_key_id = fk.fkey_id) ||
	    if check_on_commit='Y' then 'CHECK ON COMMIT ' endif ||
	    f_unload_clustered_attribute( fk.table_id, fk.fkey_id ) 
	FROM unloaded_fkeys fk
	    JOIN sa_unload_table_ordering ut ON (fk.table_id = ut.table_id);
    insert into sa_unload_stage2 (id1,id2,sub,need_delim,defn)
	SELECT order_col,order_fk+100,5,1, 
	    f_unload_object_comment( 'FOREIGN KEY' ||
		if @reloading = 1 and fk.primary_table_id <= fk.table_id and t.table_type != 'GBL TEMP' then
		    @cmtbeg || 'INDEX' || @cmtend
		endif,
		ut.user_name, ut.table_name, fk.role, fkey.remarks )
	FROM unloaded_fkeys fk
		JOIN SYS.SYSFOREIGNKEY fkey 
			ON (fk.table_id = fkey.foreign_table_id
			    and fk.fkey_id = fkey.foreign_key_id)
		JOIN SYS.SYSTABLE t ON (fk.table_id = t.table_id)
		JOIN sa_unload_table_ordering ut ON (fk.table_id = ut.table_id)
	WHERE fkey.remarks is not null;

end
go

create temporary function 
sa_unload_index_cols(
    @table_id	unsigned int,
    @index_id	unsigned int
)
returns long varchar
begin
    declare collist long varchar;
    SELECT '( ' || list( '"' || column_name || '"' || 
		if "order"='A' then '' else ' DESC' endif  
		order by t1.table_id,t1.index_id,t1.sequence ) || ' )'
	    into collist
	FROM
	    (SELECT DISTINCT column_name, "order", ic.table_id, ic.index_id, min(sequence) as sequence, 
	                     min(ic.column_id) as column_id
		FROM SYS.SYSCOLUMN c
			JOIN 
        SYS.SYSIXCOL ic 
		    	    ON (ic.table_id = c.table_id AND ic.column_id = c.column_id)
		WHERE ic.table_id = @table_id
		AND   ic.index_id = @index_id
		GROUP BY column_name, "order", ic.table_id, ic.index_id) AS t1;
    return collist;
end
go

create temporary procedure sa_indexes()
result( 
	table_id unsigned int, 
	index_id unsigned int, 
	object_id unsigned bigint, 
	file_id smallint, 
	"unique" char(1),
	with_nulls_not_distinct char(1),
	index_name char(128),
	index_type char(4),
	index_owner char(4)
	
      )
begin
    select table_id, index_id,         0, file_id, "unique", 'N', index_name,
	    NULL, NULL
    from SYS.SYSINDEX
end
go

create temporary function f_unload_text_index_options( @object_id unsigned bigint )
returns long varchar
begin
    return '';
end
go

create temporary procedure sa_make_table_ordering()
begin
    truncate table sa_unload_table_ordering;
    insert into sa_unload_table_ordering( table_id, user_name, table_name, order_col, is_omni_table )
	SELECT ut.table_id, cr.user_name, t.table_name, ut.table_id,
	    f_unload_is_remote_table( t.table_id )
	FROM sa_unloaded_table ut
	    JOIN SYS.SYSTABLE t ON (ut.table_id = t.table_id)
	    JOIN sa_unload_users_list cr ON (t.creator = cr.user_id)
	UNION ALL
	SELECT ut.table_id, cr.user_name, t.table_name, ut.table_id, 0
	FROM sa_unloaded_table_complete ut
	    JOIN SYS.SYSTABLE t ON (ut.table_id = t.table_id)
	    JOIN sa_unload_users_list cr ON (t.creator = cr.user_id)
	WHERE t.table_type = 'MAT VIEW'
	ORDER BY 1;
    if @name_order = 1 then
	update sa_unload_table_ordering
	    set order_col = number()
	    order by user_name,table_name;
    end if;
end
go

create temporary procedure sa_unload_indexes( in @unique_constraints_only int default 0 )
begin
    declare @numtabs int;
    declare local temporary table unloaded_indexes (
	table_id	unsigned int	not null,
	object_id	unsigned bigint not null,
	index_id	unsigned int	not null,
	order_ix	unsigned int	not null,
	file_id		int		not null,
	index_name	char(128),
	primary key (table_id,index_id) 
    ) in system not transactional;

    select count(*) into @numtabs from sa_unload_table_ordering;
    
    if @unique_constraints_only = 0 then       
	call sa_unload_display_status( 17205 );
	call sa_unload_script_comment( 'Create indexes' );
	if @show_index_progress = 1 and @name_order = 0 then
	    insert into sa_unload_stage2 (id1,id2,sub,defn)
		select order_col,0,0, 
		    'call sa_unload_display_table_status( ' ||
			17738 || ', ' || 
			order_progress || ', ' || 
			@numtabs || ', ' ||
			f_unload_literal(user_name) || ', ' ||
			f_unload_literal(table_name) || ' )'
		from sa_unload_table_ordering;
	end if;
	    
	call sa_unload_foreign_keys();

    end if;
    
    insert into unloaded_indexes
	SELECT i.table_id,
		    0,
		i.index_id,
		if @name_order = 0 then i.index_id else number() endif,
		i.file_id,
		i.index_name
	FROM sa_indexes() i
		JOIN sa_unload_table_ordering t ON (t.table_id = i.table_id)
	where (@extracting = 0 or
		not exists (select * from sa_unload_splayed_indexes si 
			 where si.table_id = i.table_id 
			   and si.index_id = i.index_id) )
	and ((@unique_constraints_only = 1 and "unique" = 'U' and t.is_omni_table = 0) or
	     (@unique_constraints_only = 0 and "unique" <> 'U'))
	order by t.order_col, i.index_name;

    insert into sa_unload_stage2 (id1,id2,sub,defn)
	SELECT order_col,order_ix+1000000,1,
		if "unique"='U' then
		    'ALTER TABLE "' ||
		    ut.user_name || '"."' || t.table_name || '"' || @newline || 
		    '    ADD ' ||
		    f_unload_unique_constraint_name( i.table_id, i.index_id ) ||
		    'UNIQUE ' || f_unload_clustered_attribute( i.table_id, i.index_id )
		else
		    'CREATE ' || 
		    if "unique" = 'Y' then 'UNIQUE ' endif || 
		    if "unique" = 'T' then 'TEXT ' endif || 
		    f_unload_clustered_attribute( i.table_id, i.index_id ) ||
		    if @reloading = 1 and t.table_type = 'GBL TEMP' then
			@cmtbeg || 'NO PARALLEL INDEX CREATION' || @cmtend
		    endif ||

		    if @reloading = 1 
			and f_unload_is_remote_table( t.table_id ) = 1 then
			@cmtbeg || 'FOR REMOTE PROXY TABLE' || @cmtend
		    endif ||
		    'INDEX "' || ii.index_name || '" ON "' ||
		    ut.user_name || '"."' || t.table_name || '"' || @newline || 
		    if @reloading = 1 and (t.table_type = 'MAT VIEW' or "unique" = 'T') then
		       @cmtbeg || 'NO PARALLEL INDEX CREATION' || @cmtend || @newline
		    endif ||
		    '    ' 
		endif ||
		sa_unload_index_cols( i.table_id, i.index_id ) ||
		if ii.with_nulls_not_distinct = 'Y' then ' WITH NULLS NOT DISTINCT' endif ||
		ISNULL( 
		    if upper(dbspace_name) <> 'SYSTEM' and i.file_id <> 15 and "unique" != 'U' and @profiling_uses_single_dbspace = 0 then
			@newline || ' IN "' || dbspace_name || '"'
		    endif, '' )
	FROM unloaded_indexes i 
		JOIN SYS.SYSTABLE t ON (i.table_id = t.table_id)
		JOIN sa_unload_table_ordering ut ON (t.table_id = ut.table_id)
		JOIN sa_indexes() ii 
		    ON (i.table_id = ii.table_id and i.index_id = ii.index_id)
		LEFT OUTER JOIN SYS.SYSFILE f ON (i.file_id = f.file_id);
		
    if @unique_constraints_only = 0 then
	insert into sa_unload_stage2 (id1,id2,sub,defn)
	    SELECT order_col,order_ix+1000000,2,
		f_unload_object_comment( 'INDEX', cr.user_name, t.table_name, ii.index_name, ii.remarks )
	    FROM unloaded_indexes i
		    JOIN SYS.SYSTABLE t ON (i.table_id = t.table_id)
		    JOIN sa_unload_table_ordering ut ON (t.table_id = ut.table_id)
		    JOIN sa_unload_users_list cr ON (t.creator = cr.user_id)
		    JOIN SYS.SYSINDEX ii 
			ON (i.table_id = ii.table_id and i.index_id = ii.index_id)
	    WHERE ii.remarks is not null;
	call sa_unload_staged_text2();	
    else
	
	insert into sa_unload_stage1 (id,sub,defn)
	    select id1,id2+10000000,s2.defn
	    from sa_unload_stage2 s2;

	truncate table sa_unload_stage2;

	insert into sa_unload_stage1 (id,sub,defn)
	    SELECT order_col,order_ix+25000000,
		f_unload_object_comment( 'INDEX', cr.user_name, t.table_name, ii.index_name, ii.remarks )
	    FROM unloaded_indexes i
		    JOIN SYS.SYSTABLE t ON (i.table_id = t.table_id)
		    JOIN sa_unload_table_ordering ut ON (t.table_id = ut.table_id)
		    JOIN sa_unload_users_list cr ON (t.creator = cr.user_id)
		    JOIN SYS.SYSINDEX ii 
			ON (i.table_id = ii.table_id and i.index_id = ii.index_id)
	    WHERE ii.remarks is not null;

    end if;

end
go

create temporary procedure sa_unload_add_table_perm( 
    in @list_order tinyint,
    in @perm char(10), 
    in @colname char(128), 
    in @setting char(1) )
begin
    if @colname = 'loadauth' or @colname = 'truncateauth' then 
    	if @has_rbac = 0 then
    	    return;
	end if;
    end if;
    execute immediate
	'insert into sa_unload_table_perm ' ||
	    'select u.table_id,tp.grantee,tp.grantor,@perm,order_col,@list_order ' ||
	    'FROM sa_unload_table_or_view u ' ||
		    'JOIN SYS.SYSTABLEPERM tp ON (tp.stable_id = u.table_id) ' ||
	    'where ' || @colname || ' = @setting ' ||
	    'and grantee <> 0 ';
end
go

create temporary procedure sa_unload_add_table_grants( 
    in @sub	unsigned int,
    in @setting char(1) )
begin
    declare local temporary table tab_perm (
	order_col	unsigned int not null,
	table_id	unsigned int not null,
	grantee		unsigned int not null,
	grantor		unsigned int not null,
	perms		long varchar not null,
    ) in system not transactional;
    
    truncate table sa_unload_table_perm;
    
    call sa_unload_add_table_perm( 1, 'SELECT', 'selectauth', @setting );
    call sa_unload_add_table_perm( 2, 'INSERT', 'insertauth', @setting );
    call sa_unload_add_table_perm( 3, 'DELETE', 'deleteauth', @setting );
    call sa_unload_add_table_perm( 4, 'UPDATE', 'updateauth', @setting );
    call sa_unload_add_table_perm( 5, 'ALTER',  'alterauth', @setting );
    call sa_unload_add_table_perm( 6, 'REFERENCES', 'referenceauth', @setting );
    call sa_unload_add_table_perm( 7, 'LOAD', 'loadauth', @setting );
    call sa_unload_add_table_perm( 8, 'TRUNCATE',  'truncateauth', @setting );
    
    if @extracting = 1 then
	delete from sa_unload_table_perm
	    where grantee not in
		    (select eu.user_id from sa_extract_users eu);
    end if;
    
    insert into tab_perm
	select order_col,table_id,grantee,grantor,list(perm order by list_order)
	from sa_unload_table_perm tp
	group by order_col,table_id,grantee,grantor;
    
    insert into sa_unload_stage1 (id,sub,defn)
	SELECT pl.order_col,@sub+number(*),
		'GRANT ' ||
		perms ||
		' ON "' || c.user_name || '"."' || table_name || '"' ||
		' TO "' || grantee.user_name || '" ' ||
		if @setting = 'G' then
		    ' WITH GRANT OPTION ' 
		endif ||
		if grantor.user_name <> 'DBA' then 'FROM "' || grantor.user_name || '"' endif
	FROM sa_unload_table_or_view u
		JOIN SYS.SYSTABLE t ON (t.table_id = u.table_id)
		JOIN sa_unload_users_list c ON (c.user_id = t.creator)
		JOIN SYS.SYSTABLEPERM tp ON (tp.stable_id = t.table_id)
		JOIN sa_unload_users_list grantee ON (grantee.user_id = tp.grantee)
		JOIN sa_unload_users_list grantor ON (grantor.user_id = tp.grantor)
		JOIN tab_perm pl 
		    ON (pl.table_id = tp.stable_id and
			pl.grantee = tp.grantee and
			pl.grantor = tp.grantor) 
	ORDER BY grantor.user_name,grantee.user_name;
end
go

create temporary procedure sa_unload_column_permissions( in @sub unsigned int )
begin
    if f_unload_column_exists( 'SYSCOLPERM', 'privilege_type' ) = 0 then
	return;
    end if;
    insert into sa_unload_stage1 (id,sub,defn)
	SELECT 
	    u.order_col,@sub+number(*),
	    'GRANT ' ||
	    case privilege_type
	    when 1 then 'SELECT'
	    when 8 then 'UPDATE'
	    when 16 then 'REFERENCE'
	    else 'UNKNOWN'
	    end ||
	    '(' || list('"' || column_name || '"' order by column_name) || ') ' ||
	    'ON "' || cr.user_name || '"."' || t.table_name || '" ' ||
	    'TO "' || grantee.user_name || '" ' ||
	    if is_grantable ='Y' then 'WITH GRANT OPTION ' endif ||
	    if grantor.user_name <> 'DBA' then 'FROM "' || grantor.user_name || '"' endif 
	FROM sa_unload_table_or_view u
		JOIN SYS.SYSTABLE t ON (t.table_id = u.table_id)
		JOIN sa_unload_users_list cr ON (cr.user_id = t.creator) 
		JOIN SYS.SYSCOLPERM cp ON (cp.table_id = t.table_id)
		JOIN SYS.SYSCOLUMN c 
		    ON (c.table_id = cp.table_id and c.column_id = cp.column_id)
		JOIN sa_unload_users_list grantee ON (grantee.user_id = cp.grantee)
		JOIN sa_unload_users_list grantor ON (grantor.user_id = cp.grantor)
	where (@extracting = 0 or 
		exists (select * from sa_extract_users eu 
			where eu.user_id = cp.grantee))
	GROUP BY u.order_col, u.table_id, cp.grantor, cr.user_name, cp.grantee, t.table_name,
		grantee.user_name, grantor.user_name, privilege_type, is_grantable
	ORDER BY u.order_col, cp.grantor;
end
go

create temporary procedure sa_unload_table_permissions()
begin
    call sa_unload_add_table_grants( 60000000, 'Y' );
    call sa_unload_add_table_grants( 61000000, 'G' );
    call sa_unload_column_permissions( 62000000 );
end
go

create temporary procedure sa_unload_views()
begin
    declare @numviews int;
    declare local temporary table unloaded_views (
	table_id    unsigned int    not null primary key ,
	order_col   unsigned int    not null,
	user_name   char(128)	    not null
    ) in system not transactional;
   
    if @exclude_views = 1 then
	return;
    end if; 
    call sa_unload_display_status( 17204 );
    call sa_unload_script_comment( 'Create views', 1 );
    insert into SQLDefn (txt)
	values ('SET TEMPORARY OPTION force_view_creation=''ON''' );
    insert into unloaded_views
	SELECT table_id,if @name_order = 0 then table_id else number() endif,user_name
	FROM sa_unload_users_list u
		JOIN SYS.SYSTABLE t ON (u.user_id = t.creator)
	WHERE table_type = 'VIEW' 
	AND   user_id <> 0 
	AND   NOT EXISTS
		(SELECT name 
		 FROM sa_unload_exclude_object
		 WHERE type='V' 
		 AND name=t.table_name)
	order by u.user_name,t.table_name;
    
    if @use_alter_object = 1 then
	insert into sa_unload_stage1 (id,sub,defn)
	    SELECT order_col, 1, 
		'call dbo.sa_make_object(' ||
		    '''view'',' ||
		    '''' || table_name || ''',' ||
		    '''' || user_name || ''')'
	    FROM  SYS.SYSTABLE t
		    JOIN unloaded_views v ON (t.table_id = v.table_id);
    end if;
    insert into sa_unload_stage1 (id,sub,defn)
	SELECT order_col, 2, 
	    if @use_alter_object = 0 then
		view_def
	    else
		'alter' || substr(view_def,7) 
	    endif
	FROM  SYS.SYSTABLE t
		JOIN unloaded_views v ON (t.table_id = v.table_id);
    insert into sa_unload_stage1 (id,sub,defn)
	SELECT order_col, 3,
	    f_unload_object_comment( 'VIEW', user_name, table_name, null, t.remarks )
	FROM  SYS.SYSTABLE t
		JOIN unloaded_views v ON (t.table_id = v.table_id)
	WHERE t.remarks is not null;
    if @has_preserved_source = 1 then
	insert into sa_unload_stage1 (id,sub,defn)
	    SELECT order_col, 4, 
		    f_unload_preserved_source( 'VIEW', user_name, table_name, null, source )
	    FROM  SYS.SYSTABLE t
		    JOIN unloaded_views v ON (t.table_id = v.table_id)
	    AND source is not null;
    end if;

    truncate table sa_unload_table_or_view;
    insert into sa_unload_table_or_view
	select u.table_id, u.order_col
	from unloaded_views u;
	
    call sa_unload_table_permissions();
    
    call sa_unload_staged_text1();

    insert into SQLDefn (txt)
	values ('SET TEMPORARY OPTION force_view_creation=''OFF''' );
    insert into SQLDefn (txt)
	values ('call dbo.sa_recompile_views(1)' );
end
go

create temporary procedure sa_unload_procedures( in @proc_type char(1) )
begin
    declare @numprocs int;
    declare @status_message int;
    declare objtype char(10);
    declare local temporary table unload_procs (
	proc_id	    unsigned int    not null,
	owner	    unsigned int    not null,
	is_func	    int		    not null,
	order_col1  unsigned int    not null,
	order_col2  unsigned int    not null,
	primary key (proc_id)
    ) in system not transactional;

    if @exclude_procedures = 1 then
	return;
    end if; 
    if @proc_type = 'F' then
	set objtype = 'FUNCTION';
	call sa_unload_script_comment( 'Create functions', 1 );
	call sa_unload_display_status( 17208 );
    else
	set objtype = 'PROCEDURE';
	call sa_unload_script_comment( 'Create procedures', 1 );
	call sa_unload_display_status( 17207 );
    end if;
    insert into unload_procs(proc_id,owner,is_func,order_col1,order_col2)
	SELECT p.proc_id, p.creator, 0, number(), 0
	FROM SYS.SYSPROCEDURE p
	    JOIN SYS.SYSUSERPERM u ON (u.user_id = p.creator)
	WHERE creator <> 0
	AND not exists
		(select *
		 from sa_unload_jconnect_proc jp
		 where jp.proc_name=p.proc_name)
	AND not exists
		(select *
		 from sa_unload_obsolete_user_func obs
		 where obs.proc_name=p.proc_name)
	AND NOT EXISTS
		(SELECT name 
		 FROM sa_unload_exclude_object
		 WHERE type='P' 
		 AND name=p.proc_name
		 AND NOT name like 'rs_%')
	order by u.user_name, p.proc_name;
    
    delete from unload_procs
    where proc_id in
	(select proc_id from SYS.SYSPROCEDURE p
		join SYS.SYSUSERPERM u on (p.creator = u.user_id)
		where user_name = 'rs_systabgroup'
		and proc_name like 'rs_%');
	
    if @name_order = 0 then
	update unload_procs
	    set order_col1 = owner, order_col2 = proc_id;
    end if;
    insert into sa_unload_proc_used_java
	on existing skip
	select distinct proc_id 
	from SYS.SYSPROCPARM pp
	    JOIN SYS.SYSDOMAIN d on (d.domain_id = pp.domain_id)
	where domain_name = 'java.lang.object';
    delete from unload_procs
    where proc_id in (select proc_id from sa_unload_proc_used_java);
    update unload_procs u
	set is_func = if exists (select *
		    from SYS.SYSPROCPARM pp
		    where pp.proc_id = u.proc_id
		    and pp.parm_type=4) then 1 else 0 endif;
    delete from unload_procs
    where is_func <> if @proc_type = 'F' then 1 else 0 endif;
    
    if @use_alter_object = 1 then
	insert into sa_unload_stage2 (id1,id2,sub,defn)
	    SELECT order_col1, order_col2, 1, 
		'call dbo.sa_make_object(' ||
		    '''' || if @proc_type = 'F' then 'function' else 'procedure' endif || ''',' ||
		    '''' || proc_name || ''',' ||
		    '''' || user_name || ''')'
	    FROM SYS.SYSPROCEDURE p
		    JOIN unload_procs u ON (p.proc_id = u.proc_id)
		    JOIN sa_unload_users_list cr ON (p.creator = cr.user_id);
    end if;
    insert into sa_unload_stage2 (id1,id2,sub,defn)
	SELECT order_col1, order_col2, 2, 
	    if @use_alter_object = 0 then 
		proc_defn
	    else
		'alter' || substr(proc_defn,7) 
	    endif
	FROM SYS.SYSPROCEDURE p
		JOIN unload_procs u ON (p.proc_id = u.proc_id);
		
    insert into sa_unload_stage2 (id1,id2,sub,defn)
	SELECT order_col1, order_col2, 3,
	    f_unload_object_comment( 'PROCEDURE', user_name, proc_name, null, p.remarks )
	FROM SYS.SYSPROCEDURE p
		JOIN unload_procs u ON (p.proc_id = u.proc_id)
		JOIN sa_unload_users_list cr ON (p.creator = cr.user_id)
	where p.remarks is not null;
    
    if @has_preserved_source = 1 then
	insert into sa_unload_stage2 (id1,id2,sub,defn)
	    SELECT order_col1, order_col2, 4,
		    f_unload_preserved_source( 'PROCEDURE', user_name, proc_name, null, source )
	    FROM SYS.SYSPROCEDURE p
		    JOIN unload_procs u ON (p.proc_id = u.proc_id)
		    JOIN sa_unload_users_list cr ON (p.creator = cr.user_id)
	    WHERE source is not null;
    end if;

    insert into sa_unload_stage2 (id1,id2,sub,defn)
	SELECT order_col1, order_col2, 5, 
	    'ALTER PROCEDURE ' ||
		'"' || user_name || '"."' || proc_name || '" REPLICATE ON'
	    FROM SYS.SYSPROCEDURE p
		    JOIN unload_procs u ON (p.proc_id = u.proc_id)
		    JOIN sa_unload_users_list cr ON (p.creator = cr.user_id)
	    WHERE replicate = 'Y';
    
    insert into sa_unload_stage2 (id1,id2,sub,defn)
	SELECT order_col1, order_col2, 100 + number(*),
		'GRANT EXECUTE ON "' || cr.user_name || '"."' || proc_name || '"' ||
		' TO "' || grantee.user_name || '"' 
	FROM SYS.SYSPROCEDURE p
		JOIN sa_unload_users_list cr ON (p.creator = cr.user_id)
		JOIN SYS.SYSPROCPERM pp ON (p.proc_id = pp.proc_id)
		JOIN sa_unload_users_list grantee ON (pp.grantee = grantee.user_id)
		JOIN unload_procs u ON (p.proc_id = u.proc_id)
	WHERE (@extracting = 0 OR 
		    exists (select * from sa_extract_users eu
			    where eu.user_id = grantee.user_id))
	order by order_col1, order_col2, grantee.user_name;
			    
    call sa_unload_staged_text2();
    
    if @proc_type <> 'F' then
	
	insert into SQLDefn (txt)
	    values( 
	      replace(
		'begin $' ||
		'  declare prev_count int;$' ||
		'  declare new_count int;$' ||
		'  declare local temporary table dependent_proc ( $' ||
		'    proc_id    unsigned int    not null, $' ||
		'    primary key (proc_id) $' ||
		'  ) in system not transactional; $' ||
		'  set prev_count = -1;$' ||
		'  lp: loop$' ||
		'      truncate table dependent_proc;$' ||
		'      insert into dependent_proc $' ||
		'	select proc_id from SYS.SYSPROCEDURE p $' ||
		'	where exists (select * from SYS.SYSPROCPARM pp $' ||
		'	    where pp.proc_id = p.proc_id $' ||
		'	    and parm_name = ''expression'' $' ||
		'	    and parm_type = 1 $' ||
		'	   and domain_id = 1); $' ||
		'      select count(*) into new_count from dependent_proc;$' ||
		'      if new_count = 0 or (new_count >= prev_count and prev_count >= 0) then$' ||
		'        leave lp;$' ||
		'      end if;$' ||
		'      set prev_count = new_count;$' ||
		'      for l1 as c1 cursor for $' ||
		'	select u.user_name, proc_name$' ||
		'	from SYS.SYSPROCEDURE p$' ||
		'	    join dependent_proc d on (d.proc_id = p.proc_id)$' ||
		'	    join SYS.SYSUSER u on (p.creator = u.user_id)$' ||
		'      do$' ||
		'        begin$' ||
		'	   execute immediate with quotes on$' ||
		'            ''alter procedure "'' || user_name || ''"."'' || proc_name || ''" recompile'';$' ||
		'          exception when others then$' ||
		'        end$' ||
		'      end for;$' ||
		'  end loop;$' ||
		'end$', '$', @newline ) )
    end if;
end
go

create temporary procedure sa_unload_remove_dropped_procedures()
begin
    if exists(select * from sa_unload_dropped_procedure) then
	call sa_unload_script_comment( 'Drop dbo procedures' );
	insert into SQLDefn (txt)
	    select 'DROP PROCEDURE dbo."' || proc_name || '"'
	    from sa_unload_dropped_procedure;
    end if;
end
go

create temporary procedure sa_unload_triggers()
begin
    declare @numtriggers int;
    declare local temporary table objects_with_triggers (
	table_id    unsigned int    not null,
	creator	    unsigned int    not null,
	primary key (table_id)
    ) in system not transactional;
    declare local temporary table unload_trig (
	trigger_id  unsigned int not null,
	order_col1  unsigned int not null,
	order_col2  unsigned int not null,
	creator	    unsigned int not null,
	remarks	    long varchar,
	primary key (trigger_id),
    ) in system not transactional;
  
    if @exclude_triggers = 1 then
	return;
    end if; 
    call sa_unload_display_status( 17209 );
    insert into objects_with_triggers 
	select table_id, creator
	from sa_unloaded_table;
    if @table_list_provided = 0 then
	
	insert into objects_with_triggers
	    SELECT table_id,t.creator
	    FROM SYS.SYSTABLE t
		    JOIN sa_unload_users_list u ON (t.creator = u.user_id)
	    WHERE table_type = 'VIEW' 
	    AND   user_name not in ('SYS','rs_systabgroup')
	    and (@extracting = 0
		or exists (select * from sa_extract_tables et 
			    where et.table_id = t.table_id))
	    and exists (select * from SYS.SYSTRIGGER tr
			where tr.table_id = t.table_id);
    end if;
    insert into unload_trig
	select tr.trigger_id, 
		if @name_order = 0 then ul.creator else number() endif,
		if @name_order = 0 then tr.trigger_id else 0 endif,
		ul.creator, tr.remarks
	FROM SYS.SYSTRIGGER tr
		JOIN objects_with_triggers ul ON (ul.table_id = tr.table_id)
		JOIN SYS.SYSTABLE t ON (t.table_id = tr.table_id)
		JOIN SYS.SYSUSERPERM u ON (u.user_id = ul.creator)
	WHERE foreign_table_id IS NULL
	AND NOT EXISTS (SELECT * FROM sa_unload_exclude_object
			WHERE name=trigger_name AND type='T')
	and (@extracting = 0
	    or exists (select * from sa_extract_tables e 
			where e.table_id = tr.table_id))
	order by u.user_name,t.table_name,tr.trigger_name;
    call sa_unload_script_comment( 'Create triggers', 1 );
    
    if @use_alter_object = 1 then
	insert into sa_unload_stage2 (id1,id2,sub,defn)
	    SELECT order_col1, order_col2, 1, 
		'call dbo.sa_make_object(' ||
		    '''trigger'',' ||
		    '''' || trigger_name || ''',' ||
		    '''' || user_name || ''',' ||
		    '''' || table_name || ''')'
	    FROM SYS.SYSTRIGGER tr
		    JOIN unload_trig ul ON (tr.trigger_id = ul.trigger_id)
		    JOIN SYS.SYSTABLE t ON (t.table_id = tr.table_id)
		    JOIN sa_unload_users_list u ON (t.creator = u.user_id);
    end if;
    insert into sa_unload_stage2 (id1,id2,sub,defn)
	SELECT order_col1, order_col2, 2, 
	    if @use_alter_object = 0 then
		trigger_defn
	    else
		'alter' || substr(trigger_defn,7) 
	    endif
	FROM unload_trig ul
		JOIN SYS.SYSTRIGGER tr ON (tr.trigger_id = ul.trigger_id);
		    
    insert into sa_unload_stage2 (id1,id2,sub,defn)
	SELECT order_col1, order_col2, 3, 
	    f_unload_object_comment( 'TRIGGER', user_name, table_name, trigger_name, tr.remarks )
	FROM unload_trig ul
		JOIN SYS.SYSTRIGGER tr ON (tr.trigger_id = ul.trigger_id)
		JOIN SYS.SYSTABLE t ON (t.table_id = tr.table_id)
		JOIN sa_unload_users_list u ON (t.creator = u.user_id)
    where tr.remarks is not null;
    
    if @has_preserved_source = 1 then
	insert into sa_unload_stage2 (id1,id2,sub,defn)
	    SELECT order_col1, order_col2, 4, 
		    f_unload_preserved_source( 'TRIGGER', user_name, table_name, trigger_name, tr.source )
	    FROM unload_trig ul
		    JOIN SYS.SYSTRIGGER tr ON (tr.trigger_id = ul.trigger_id)
		    JOIN SYS.SYSTABLE t ON (t.table_id = tr.table_id)
		    JOIN sa_unload_users_list u ON (t.creator = u.user_id)
	    WHERE tr.source is not null;
    end if;
    
    call sa_unload_staged_text2();
end
go

create temporary procedure sa_unload_remote_message_types()
begin
    declare local temporary table unload_remote_type (
	type_name   char(128)	not null,
	address	    long varchar,
	remarks	    long varchar
    ) in system not transactional;
    
    if @extracting = 1 then
	insert into unload_remote_type
	    select t.type_name, f_unload_literal(r.address), t.remarks
	    FROM SYS.SYSREMOTETYPE t 
		JOIN SYS.SYSREMOTEUSER r ON (r.type_id = t.type_id)
		JOIN sa_unload_users_list p ON (p.user_id = r.user_id)
	    WHERE p.user_name = @subscriber_username;
    else
	insert into unload_remote_type
	    select t.type_name, f_unload_literal(t.publisher_address), t.remarks
	    FROM SYS.SYSREMOTETYPE t
	    WHERE t.type_id in 
		(SELECT r.type_id
		FROM SYS.SYSREMOTEUSER r 
		    JOIN sa_unload_users_list p ON (p.user_id = r.user_id))
	    AND   ((NOT (t.publisher_address = '' 
			and t.type_name in ('FILE','MAPI','VIM','SMTP','FTP','HTTP')))
		OR t.remarks is not null);
    end if;
    insert into SQLDefn (txt)
	SELECT 
	    'CREATE REMOTE TYPE "' || type_name || '" ' ||
	    'ADDRESS ' || address || ' ' 
	from unload_remote_type;
    insert into SQLDefn (txt)
	SELECT 
	    f_unload_object_comment( 'REMOTE TYPE', null, type_name, null, remarks )
	from unload_remote_type
	where remarks is not null;
end
go

create temporary procedure sa_unload_subscriber_userids()
begin
    if @extracting = 1 then
	insert into SQLDefn (txt)
	    select
		'GRANT CONSOLIDATE TO "' || u.user_name || '" ' ||
		'TYPE "' || t.type_name || '" ' ||
		'ADDRESS ' || f_unload_literal(t.publisher_address) || 
		case
		when frequency = 'P' then
		    ' SEND EVERY ''' || send_time || ''''

		end
	   FROM SYS.SYSUSERPERM u
		JOIN sa_unload_users_list sl ON ( u.user_id = sl.user_id ),
		SYS.SYSREMOTETYPE t
		JOIN SYS.SYSREMOTEUSER ru ON (ru.type_id = t.type_id) 
		JOIN sa_unload_users_list subscriber ON (subscriber.user_id = ru.user_id)
	   WHERE u.publishauth = 'Y' 
	     AND subscriber.user_name = @subscriber_username;
    else
	insert into SQLDefn (txt)
	    select
		'GRANT ' || 
		if consolidate = 'Y' then 'CONSOLIDATE' else 'REMOTE' endif ||
		' TO "' || p.user_name || '" ' ||
		'TYPE "' || type_name || '" ' ||
		'ADDRESS ' || f_unload_literal(address) || 
		case
		when frequency = 'P' then
		    ' SEND EVERY ''' || send_time || ''''
		when frequency = 'D' then
		    ' SEND AT ''' || send_time || ''''
		end ||
		if @preserve_ids = 1 then
		    @cmdsep ||
		    'call SYS.sa_setremoteuser( ' || 
			r.user_id || ',' ||
			log_sent || ',' ||            
			confirm_sent || ',' ||        
			send_count || ',' ||          
			resend_count || ',' ||        
			log_received || ',' ||        
			isnull(cast(confirm_received as char(20)),'NULL') || ',' ||    
			receive_count || ',' ||       
			rereceive_count || 
		    ')'      
		endif
	    FROM SYS.SYSREMOTETYPE t
		    JOIN SYS.SYSREMOTEUSER r ON (r.type_id = t.type_id)
		    JOIN sa_unload_users_list p ON (p.user_id = r.user_id)
	    ORDER BY p.user_name;
    end if;
end
go

create temporary function f_unload_format_sync_option( @opt long varchar )
returns long varchar
begin
    declare rslt    long varchar;
    declare len	    int;
   
    if byte_length(@opt) > 0 then
	set rslt =
	    @newline ||
	    '    OPTION ' || 
		
		replace(
		    replace(
			replace(
			    replace(@opt,'''','{'),
			    '=','='''),
			';',''','),
		    '{','''');
	set len = length(rslt);
	if substr(rslt,len,1) = ',' then
	    set rslt = substr(rslt,1,len-1);
	end if;
    end if;
    return rslt;
end
go

create temporary procedure sa_unload_publications()
begin
    declare @max_pub unsigned int;
    declare @has_syssync int;
    declare @any_syncs int;
    declare local temporary table unload_pubs (
	user_name	    char(128)	    not null,
	publication_id	    unsigned int    not null,
	publication_name    char(128)	    not null,
	remarks		    long varchar,
	sync_id		    unsigned int,
	site_name	    char(128),
	server_conn_type    long varchar,
	server_connect	    long varchar,
	"option"	    long varchar,
	type		    char(1),
	sync_type	    unsigned int default 0,
	object_id	    bigint
    ) in system not transactional;
   
    if not exists (select * from SYS.SYSPUBLICATION) then
	return;
    end if;
    
    set @has_syssync = 0;
    set @any_syncs = 0;
    if f_unload_table_exists( 'SYSSYNC' ) = 1 then
	set @has_syssync = 1;
	if exists (select * from SYS.SYSSYNC) then
	    set @any_syncs = 1;
	end if;
    end if;

    if @has_syssync = 0 or 
	    @extracting = 1 or
	    (@extracting = 0 and @any_syncs = 0) then
	insert into unload_pubs (user_name,publication_id,
				publication_name,remarks,type,
				sync_type,object_id)
	    SELECT 
		u.user_name,
		p.publication_id,
		p.publication_name,
		p.remarks, 
		'R',
		0,
		NULL
		FROM SYS.SYSPUBLICATION p
			JOIN sa_unload_users_list u ON (u.user_id = p.creator)
	    WHERE ((@extracting = 0 or 
		exists (select * from sa_extract_pubs ep 
			where ep.publication_id = p.publication_id))
		AND p.publication_id <> @exclude_pub_id);
    else
	insert into unload_pubs
		SELECT distinct 
		    u.user_name, 
		    p.publication_id, 
		    p.publication_name, 
		    p.remarks, 
		    if p.type <> 'R' then s.sync_id endif, 
		    if p.type <> 'R' then s.site_name endif, 
		    if p.type <> 'R' then s.server_conn_type endif, 
		    if p.type <> 'R' then s.server_connect endif, 
		    if p.type <> 'R' then s."option" endif, 
		    p.type,
		    0,
		    NULL
		FROM SYS.SYSPUBLICATION p
			JOIN sa_unload_users_list u ON (u.user_id = p.creator),
		     SYS.SYSSYNC s 
		WHERE 
		    ( (p.type = 'R') OR 
		      (p.type = 'S' AND p.publication_id = s.publication_id) ) 
		AND p.publication_id <> @exclude_pub_id
		AND s.type <> 'S'; 
    end if;
    
    select max(publication_id) into @max_pub from unload_pubs;
    
    insert into sa_unload_stage1 (id,sub,defn)
	select publication_id,1,
	    'CREATE PUBLICATION dummy_pub_' || publication_id || 
		'( TABLE dbo.RowGenerator )' || @cmdsep ||
	    'DROP PUBLICATION dummy_pub_' || publication_id
	from (select (r1.row_num-1)*255+r2.row_num
		from dbo.RowGenerator r1, dbo.RowGenerator r2) as pub_holes( publication_id )
	where publication_id < @max_pub
	and not exists (select publication_id from unload_pubs up 
			where up.publication_id = pub_holes.publication_id)
	order by publication_id;
	
    if @extracting = 0 then 
	insert into sa_unload_stage1 (id,sub,defn)
	    select publication_id,2,
		'call dbo.sa_sync( ' || sync_id || ', ''SET NEXTSYNCID'', '''' )'
	from unload_pubs
	where type <> 'R';
    end if;
    insert into sa_unload_stage1 (id,sub,need_delim,defn)
	select publication_id,3,0,
	    'CREATE PUBLICATION "' || user_name || '"."' || publication_name || '" ' ||
	    case sync_type
		when 0 then ''
		when 1 then 'WITH SCRIPTED UPLOAD '
		when 2 then 'FOR DOWNLOAD ONLY '
	    end	    
	from unload_pubs
	where type in ('R','S');
    
    insert into sa_unload_stage1 (id,sub,defn)
	select a.publication_id,4,
	    '(' || @newline ||
	    list(
		@tab || 'TABLE "' || u.user_name || '"."' || table_name || '" ' ||
		if exists(select * from SYS.SYSARTICLECOL ac 
			where ac.publication_id = up.publication_id 
			and ac.table_id = a.table_id) then
		    '(' ||
		    (select list( '"' || column_name || '"' order by c.column_id )
		    from SYS.SYSARTICLECOL ac
			JOIN SYS.SYSCOLUMN c 
			    ON (c.table_id = ac.table_id and c.column_id = ac.column_id)
		    where ac.publication_id = up.publication_id
		    and ac.table_id = a.table_id) ||
		    ')'
		endif ||
		if @extracting = 0 or @include_where_subscribe = 1 then 
		    if where_expr is not null then
			' WHERE ' || where_expr
		    endif ||
		    if subscribe_by_expr is not null then
			' SUBSCRIBE BY ' || subscribe_by_expr 
		    endif
		endif,
		',' || @newline order by u.user_name, table_name ) ||
	    @newline || ')'
       FROM unload_pubs up
	    JOIN SYS.SYSARTICLE a ON (a.publication_id = up.publication_id)
	    JOIN SYS.SYSTABLE t ON (t.table_id = a.table_id)
	    JOIN sa_unload_users_list u ON (u.user_id = t.creator)
	GROUP BY a.publication_id;
    
    insert into sa_unload_stage1 (id,sub,defn)
	select up.publication_id,4,
	    '( TABLE dbo.RowGenerator )'
	FROM unload_pubs up
	where not exists (select * from SYS.SYSARTICLE a 
			where a.publication_id = up.publication_id);
    insert into sa_unload_stage1 (id,sub,defn)
	select up.publication_id,5,
	    'ALTER PUBLICATION "' || user_name || '"."' || publication_name || '" ' ||
		'DROP TABLE dbo.RowGenerator'
	from unload_pubs up
	where not exists (select * from SYS.SYSARTICLE a 
			where a.publication_id = up.publication_id);
    
    insert into sa_unload_stage1 (id,sub,defn)
	select publication_id,6,
	    f_unload_object_comment( 'PUBLICATION', user_name, publication_name, null, remarks )
    from unload_pubs
    where remarks is not null;
    
    call sa_unload_staged_text1();
    
    if exists (select * from unload_pubs where type <> 'R') then
	insert into SQLDefn (txt)
	    values( 'call dbo.sa_sync( 0 , ''RESET NEXTSYNCID'', '''' )' );
    end if;
end
go

create temporary procedure sa_unload_subscriptions()
begin
    declare @extract_subscriber char(128);
    declare local temporary table unload_subs (
	pk		    unsigned int    not null default autoincrement,
	user_name	    char(128)	    not null,
	publication_name    char(128)	    not null,
	subscribe_by	    char(128),
	subscriber_name	    char(128)	    not null,
	publication_id	    unsigned int    not null,
	s_user_id	    unsigned int    not null,
	created		    numeric(20,0),
	started		    numeric(20,0),
	first_pub	    unsigned int    not null,
	primary key (pk)
    ) in system not transactional;

    if @extracting = 1 then
	select first p.user_name into @extract_subscriber
	  FROM SYS.SYSUSERPERM p
		JOIN sa_unload_users_list sl ON ( p.user_id = sl.user_id ),
		SYS.SYSREMOTETYPE t
		JOIN SYS.SYSREMOTEUSER u ON (u.type_id = t.type_id)
		JOIN sa_unload_users_list subscriber ON (subscriber.user_id = u.user_id)
	 WHERE p.publishauth = 'Y' 
	   AND subscriber.user_name = @subscriber_username
	 order by 1; 
    end if;
    
    insert into unload_subs 
	(user_name,publication_name,subscribe_by,subscriber_name,publication_id,
	 s_user_id,created,started,first_pub)
	select    
	    p.user_name,pub.publication_name,a.subscribe_by,
	    if @extracting = 1 then
		@extract_subscriber
	    else
		s.user_name
	    endif,
	    a.publication_id, s.user_id, a.created, a.started, 0
	  FROM sa_unload_users_list s
		JOIN SYS.SYSSUBSCRIPTION a ON (a.user_id = s.user_id)
		JOIN SYS.SYSPUBLICATION pub ON (pub.publication_id = a.publication_id)
		JOIN sa_unload_users_list p ON (p.user_id = pub.creator)
	  WHERE (@extracting = 0 or s.user_name = @subscriber_username)
		AND pub.publication_id <> @exclude_pub_id;
    if @extracting = 1 and @include_where_subscribe = 0 then
	
	update unload_subs us1
	    set first_pub = (select min(pk) from unload_subs us2 
			    where us1.publication_id = us2.publication_id);
	delete from unload_subs
	 where first_pub <> pk;
    end if;
	  
    insert into SQLDefn (txt)
	select
	    'CREATE SUBSCRIPTION TO ' || 
		'"' || user_name || '"."' || publication_name || '" ' ||
		if (@extracting = 0 or @include_where_subscribe = 1)
			and subscribe_by <> '' then
		    '(''' || subscribe_by || ''') '
		endif ||
		'FOR "' || subscriber_name || '"' || @cmdsep ||
	    if @extracting = 0 then
		'call SYS.sa_setsubscription(' ||
		    publication_id || ',' ||
		    s_user_id || ',' ||
		    '''' || subscribe_by || ''',' ||
		    created || ',' ||
		    isnull(cast(started as char(20)),'NULL') ||
		')'
	    else
		'START SUBSCRIPTION TO ' ||
		    '"' || user_name || '"."' || publication_name || '" ' ||
		if @include_where_subscribe = 1 and subscribe_by <> '' then
		    '(''' || subscribe_by || ''') '
		endif ||
		'FOR "' || @extract_subscriber || '" '
	    endif
	  FROM unload_subs
	  ORDER BY publication_id,s_user_id,subscribe_by;
end
go

create temporary procedure sa_unload_remote_options()
begin
    if f_unload_table_exists( 'SYSREMOTEOPTION' ) = 0 then
	return;
    end if;
    if @extracting = 1 then
	insert into SQLDefn (txt)
	    select
		'SET REMOTE "' || type_name || '" OPTION ' ||
		'"' || user_name || '"."' || "option" || '" = ' ||
		f_unload_literal("setting")
	    FROM SYS.SYSREMOTETYPE srt
		    JOIN SYS.SYSREMOTEOPTIONTYPE srot ON (srot.type_id = srt.type_id)
		    JOIN SYS.SYSREMOTEOPTION sro ON (sro.option_id = srot.option_id)
		    JOIN sa_unload_users_list sup ON (sup.user_id = sro.user_id)
	    WHERE (sro.user_id = @subscriber 
		   OR sro.user_id IN (select group_id 
			    FROM SYS.SYSGROUP 
			    WHERE group_member = @subscriber));
    else
	insert into SQLDefn (txt)
	    select
		'SET REMOTE "' || type_name || '" OPTION ' ||
		'"' || user_name || '"."' || "option" || '" = ' ||
		f_unload_literal("setting")
	    FROM SYS.SYSREMOTETYPE srt
		    JOIN SYS.SYSREMOTEOPTIONTYPE srot ON (srot.type_id = srt.type_id)
		    JOIN SYS.SYSREMOTEOPTION sro ON (sro.option_id = srot.option_id) 
		    JOIN sa_unload_users_list sup ON (sup.user_id = sro.user_id);
    end if;
end
go

create temporary procedure sa_unload_sql_remote()
begin
    call sa_unload_display_status( 17212 );
    call sa_unload_script_comment( 'Create SQL Remote definitions' );
    call sa_unload_remote_message_types();
    if @has_rbac = 0 or @extracting = 1 then 
	insert into SQLDefn (txt)
	    select
		'GRANT PUBLISH TO "' || u.user_name || '"'
	    from SYS.SYSUSERPERM u
	    JOIN sa_unload_users_list sl ON ( u.user_id = sl.user_id )
	    where (@extracting = 1 and u.user_name = @subscriber_username)
	    or    (@extracting = 0 and u.publishauth = 'Y')
	    order by u.user_id;
    end if;
    call sa_unload_subscriber_userids();
    call sa_unload_publications();
    call sa_unload_subscriptions();
    call sa_unload_remote_options();
end
go

create temporary function f_unload_sync(
    @server_conn_type	long varchar,
    @server_connect	long varchar,
    @optval		long varchar
    )
returns long varchar
begin
    declare rslt	long varchar;
   
    set rslt = 
	if @server_conn_type is not null then
	    @newline || @tab || 'TYPE ''' || @server_conn_type || ''''
	endif ||
	if @server_connect is not null then
	    @newline || @tab || 'ADDRESS ''' || @server_connect || ''''
	endif ||
	if @optval is not null then
	    f_unload_format_sync_option( @optval )
	endif;
    return rslt; 
end
go

create temporary function f_unload_sync_script_version( @sync_id unsigned int )
returns long varchar
begin
    declare rslt	long varchar;
    set rslt = (select script_version from SYS.SYSSYNC where sync_id = @sync_id);
    return rslt;
end
go

create temporary function f_unload_sync_subscription_name( @sync_id unsigned int )
returns char(128)
begin
    declare rslt	char(128);
    set rslt = (select subscription_name from SYS.SYSSYNC where sync_id = @sync_id);
    return rslt;
end
go

create temporary function f_unload_sync_server_protocol( @sync_id unsigned int )
returns bigint
begin
    declare rslt	bigint;
    set rslt = (select server_protocol from SYS.SYSSYNC where sync_id = @sync_id);
    return rslt;
end
go

create temporary procedure sa_unload_sync_subscriptions()
begin
    declare @has_script_version bit;
    declare @has_server_protocol bit;
    declare local temporary table unload_sync(
	user_name	    char(128),
	publication_id	    unsigned int,
	publication_name    char(128),
	type		    char(1),
	progress	    numeric(20,0),
	site_name	    char(128),
	optval		    long varchar,
	server_connect	    long varchar,
	server_conn_type    long varchar,
	last_download_time  timestamp,
	sync_id		    unsigned int,
	log_sent	    numeric(20,0),
	created		    numeric(20,0),
	last_upload_time    timestamp,
	generation_number   integer,
	extended_state	    varchar(1024),
	script_version	    long varchar,
	subscription_name   char(128),
        server_protocol     bigint
    ) in system not transactional;
    
    if @extracting = 1 then
	return;
    end if;
    
    set @has_script_version = f_unload_column_exists( 'SYSSYNC', 'script_version' );
    set @has_server_protocol = f_unload_column_exists( 'SYSSYNC', 'server_protocol' ); 

    insert into unload_sync
	    SELECT 
		(select user_name from sa_unload_users_list u 
		    where u.user_id = p.creator) as user_name, 
		s.publication_id, 
		p.publication_name,
		if (p.type = 'R' AND s.type = 'D') 
		or (p.type IS NULL AND s.type = 'D') then 
		    'D' 
		else 
		    'X' 
		endif, 
		s.progress, 
		s.site_name, 
		s."option", 
		s.server_connect, 
		s.server_conn_type, 
		f_unload_sync_last_download_time( s.sync_id ),
		s.sync_id,
		f_unload_sync_log_sent( s.sync_id ),
		f_unload_sync_created( s.sync_id ),
		f_unload_sync_last_upload_time( s.sync_id ),
		f_unload_sync_generation_number( s.sync_id ),
		f_unload_sync_extended_state( s.sync_id ),
		null,
		null,
		null 
	    FROM SYS.SYSSYNC s 
		LEFT OUTER JOIN SYS.SYSPUBLICATION p 
		    ON (p.publication_id = s.publication_id)
	    WHERE ( 
		    (p.type = 'S' AND s.type = 'D') OR   
		    (p.type = 'R' AND s.type = 'D') OR    
		    (p.type IS NULL and s.type = 'D') ) 
		AND isnull(p.publication_id,-1) <> @exclude_pub_id
	    ORDER BY s.sync_id;
   
    insert into sa_unload_stage1 (id,sub,defn)
	select sync_id,1,
	    'call dbo.sa_sync( ' || sync_id || ', ''SET NEXTSYNCID'', '''' )'
	from unload_sync;

    insert into sa_unload_stage1 (id,sub,defn)
	select sync_id,2,
	    'CREATE SYNCHRONIZATION USER "' || site_name || '" ' ||
	    f_unload_sync( server_conn_type, server_connect, optval )
	from unload_sync
	where site_name is not null
	and (publication_name is null or type = 'X');
	
    insert into sa_unload_stage1 (id,sub,defn)
	select sync_id,3,

		'CREATE SYNCHRONIZATION SUBSCRIPTION ' ||
		    if subscription_name is not null then
			'"' || subscription_name || '" '
		    endif ||
		    @newline || @tab ||
		    'TO "' || user_name || '"."' || publication_name || '"' ||
		    if site_name is not null then
			' FOR "' || site_name || '"'
		    endif ||
		    f_unload_sync( server_conn_type, server_connect, optval ) ||
		    if script_version is not null then
			' SCRIPT VERSION ' || f_unload_literal( script_version )
		    endif

	from unload_sync
	where publication_name is not null;
	
    insert into sa_unload_stage1 (id,sub,defn)
	    select sync_id,4,
		'call dbo.sa_sync_sub( ' || 
		    publication_id || ', ' ||
		    '''' || site_name || ''', ' ||
		    '''set progress'', ' || 
		    progress || ' )' || @cmdsep ||
		if log_sent is not null then
		    'call dbo.sa_sync_sub( ' || publication_id || ', ' ||
			'''' || site_name || ''', ' ||
			'''set log_sent'', ' || 
			log_sent || ' )' || @cmdsep 
		endif ||
		if created is not null then
		    'call dbo.sa_sync_sub( ' || publication_id || ', ' ||
			'''' || site_name || ''', ' ||
			'''set created'', ' || 
			created || ' )' || @cmdsep 
		endif ||
		if last_download_time is not null then
		    'call dbo.sa_sync_sub( ' || publication_id || ', ' ||
			'''' || site_name || ''', ' ||
			'''set lastdownloadtime'', ''' || 
			last_download_time || ''' )' || @cmdsep 
		endif ||
		if last_upload_time is not null then
		    'call dbo.sa_sync_sub( ' || publication_id || ', ' ||
		        '''' || site_name || ''', ' ||
			'''set lastuploadtime'', ''' ||
			last_upload_time || ''' )' || @cmdsep
		endif ||
		if generation_number is not null then
		    'call dbo.sa_sync_sub( ' || publication_id || ', ' ||
			'''' || site_name || ''', ' ||
			'''set generation_number'', ' || 
			generation_number || ' )' || @cmdsep 
		endif ||	
		if extended_state is not null then
		    'call dbo.sa_sync_sub( ' || publication_id || ', ' ||
			'''' || site_name || ''', ' ||
			'''set extended_state'', ''' || 
			extended_state || ''' )' || @cmdsep 
		endif
	    from unload_sync
	    where progress is not null
	    and site_name is not null
	    and publication_id is not null;

    if @has_server_protocol = 1 then
        insert into sa_unload_stage1 (id,sub,defn)
        select sync_id,5,
               if publication_id is null then 
                  'call dbo.sa_sync_sub( null, '
               else 
                  'call dbo.sa_sync_sub( ' ||  publication_id || ', '
               endif || 
                                      '''' || site_name || ''', ' ||
                                      '''set server_protocol'', ' || 
                                      server_protocol || ' )' || @cmdsep 
	from unload_sync 
        where server_protocol is not null;
    end if;

    call sa_unload_staged_text1();
    
    if exists (select * from unload_sync) then
	
	insert into SQLDefn (txt)
	    values( 'call dbo.sa_sync( 0 , ''RESET NEXTSYNCID'', '''' )' );
    end if;
end
go

create temporary procedure sa_unload_sync_profiles()
begin
    if f_unload_table_exists( 'SYSSYNCPROFILE' ) = 0 then
	return;
    end if;
    call sa_unload_script_comment( 'Create Synchronization profiles' );
    insert into SQLDefn (txt)
	select 'CREATE SYNCHRONIZATION PROFILE "' || profile_name || '" ' || @newline ||
	    '    ' || f_unload_literal(profile_defn)
	from SYS.SYSSYNCPROFILE
	order by profile_name;

    insert into SQLDefn (txt)
        select f_unload_object_comment( 'SYNCHRONIZATION PROFILE', null, p.profile_name, null, r.remarks )
  	from SYS.SYSSYNCPROFILE p JOIN SYS.SYSREMARK r on (p.object_id = r.object_id)
	order by p.profile_name
end
go

create temporary procedure sa_unload_mobilink()
begin
    call sa_unload_display_status( 17213 );
    if f_unload_table_exists( 'SYSSYNC' ) = 0 then
	return;
    end if;
    call sa_unload_script_comment( 'Create MobiLink definitions' );
    if @extracting = 1 then
	call sa_unload_publications();
    end if;
    call sa_unload_sync_subscriptions();
    call sa_unload_sync_profiles();
end
go

create temporary procedure sa_unload_recompute_values()
begin
    if @recompute_values = 0 then
	return;
    end if;
    call sa_unload_script_comment( 'Recompute columns' );
    if @has_column_type = 0 then
	return;
    end if;
    insert into SQLDefn (txt )
	select
	    'ALTER TABLE "' || user_name || '"."' || tt.table_name || '" ' || @newline ||
	    '    ALTER "' || column_name || '" SET COMPUTE ' ||
		'(' || "default" || ')'
	from sa_unloaded_table t
	    JOIN SYS.SYSTABLE tt ON (tt.table_id = t.table_id)
	    JOIN SYS.SYSCOLUMN c ON (c.table_id = t.table_id)
	    JOIN sa_unload_users_list u ON (u.user_id = t.creator)
	where c."default" is not null
	  and c.column_type = 'C';
end
go

create temporary procedure sa_unload_events()
begin
    declare local temporary table unload_events (
	event_id	    unsigned int    not null,
	order_col	    unsigned int    not null,
	creator		    unsigned int    not null,
	event_name	    varchar(128)    not null,
	enabled		    char(1)	    not null,
	location	    char(1)	    not null,
	extract_defn        char(1)         not null,
	event_type_id	    unsigned int    null,
	action		    long varchar    null,
	condition	    long varchar    null,
	remarks 	    long varchar    null,
	primary key( event_id )
    ) in system not transactional;

    call sa_unload_script_comment( 'Create events', 1 );
    if f_unload_table_exists( 'SYSEVENT' ) = 0 then
	return;
    end if;
    if not exists(select * from SYS.SYSEVENT) then
	return;
    end if;

    insert into unload_events
	select event_id,if @name_order = 0 then event_id else number() endif,
	    creator,event_name,enabled,location,
	    if (@extracting = 0 or location not in ('C','D','E')) then 'Y' else 'N' endif,
	    event_type_id,action,condition,
	    remarks
	from SYS.SYSEVENT e
        where (@extracting = 0 OR
               exists (select * from sa_extract_users eu
                       where eu.user_id = e.creator))	
	order by event_name;

    if @use_alter_object = 1 then
	insert into sa_unload_stage1 (id,sub,defn)
	    select order_col, 0, 
		    'call dbo.sa_make_object(' ||
			'''event'',' ||
			'''' || event_name || ''')' 
	    FROM unload_events e 
	    WHERE extract_defn = 'Y';
    end if;
    insert into sa_unload_stage1 (id,sub,defn)
	select order_col, 1, 
		if @use_alter_object = 0 then 'CREATE' else 'ALTER' endif ||
		' EVENT "' || user_name || '"."' || event_name || '"' ||
		if event_type_id is not null then 
		    (select ' TYPE "' || name || '"' from SYS.SYSEVENTTYPE 
		     where event_type_id = e.event_type_id) 
		endif ||
		if condition is not null then 
		    @newline || 'WHERE ' || condition
		endif ||
		if enabled = 'Y' then ' ENABLE ' else ' DISABLE ' endif ||
		case location 
		    when 'C' then 'AT CONSOLIDATED' 
		    when 'D' then 'AT CONSOLIDATED' 
		    when 'E' then 'AT CONSOLIDATED' 
		    when 'R' then 'AT REMOTE'
		    when 'S' then 'AT REMOTE'
		    when 'T' then 'AT REMOTE'
		    when 'A' then 'AT ALL'
		    when 'B' then 'AT ALL'
		    when 'Y' then 'AT ALL'
		end ||
		if location in ('B','D','S','M') then
		    ' FOR ALL'
		else
		    if location in ('E','P','T','Y') then
			' FOR PRIMARY'
		    endif
		endif ||
		if action is not null then 
		    if substr(action,1,1) != '''' then
			@newline || 'HANDLER' || @newline || action
		    else
			@newline || 'HIDDEN ' || action
		    endif
		endif 
	FROM unload_events e 
		JOIN sa_unload_users_list cr ON (cr.user_id = e.creator)
	WHERE extract_defn = 'Y'
	;
    insert into sa_unload_stage1 (id,sub,defn)
	SELECT order_col, 2,
	    f_unload_object_comment( 'EVENT', null, event_name, null, remarks )
	FROM  unload_events
	WHERE extract_defn = 'Y'
	AND   remarks is not null;
    if @has_preserved_source = 1 then
	insert into sa_unload_stage1 (id,sub,defn)
	    SELECT order_col, 3,
		    f_unload_preserved_source( 'EVENT', null, ue.event_name, null, e.source )
	    FROM  unload_events ue
		JOIN SYS.SYSEVENT e ON (ue.event_id = e.event_id)
	    WHERE extract_defn = 'Y'
	    AND   e.source is not null;
    end if;
    for l1 as c1 cursor for
	select event_id,order_col,event_name from unload_events
	WHERE extract_defn = 'Y'
    do
	insert into sa_unload_stage1 (id,sub,defn)
	    select order_col, 100+number(*), 
		'ALTER EVENT "' || event_name || '"' || 
		@newline || '    ADD SCHEDULE "' || sched_name || '" ' || sched_def
	    from dbo.sa_event_schedules( event_id )
	    order by sched_name;
    end for;
    
    call sa_unload_staged_text1();
end
go

create temporary function f_unload_service_enabled( @service_id unsigned int )
returns char(10)
begin
    if @has_web_service_enabled = 1 then
	if exists( select * from SYS.SYSWEBSERVICE
		where service_id = @service_id 
		and enabled <> 'Y') then 
	    return 'disable ';
	end if;
    end if;
    return ' ';
end
go

create temporary procedure sa_unload_services()
begin
    declare local temporary table unload_service (
	service_id  unsigned int not null,
	order_col   unsigned int not null,
	primary key (service_id)
    ) in system not transactional;
    
    call sa_unload_script_comment( 'Create services', 1 );
    if f_unload_table_exists( 'SYSWEBSERVICE' ) = 0 then
	return;
    end if;
    insert into unload_service
	select s.service_id, if @name_order = 0 then s.service_id else number() endif
	from SYS.SYSWEBSERVICE s
	order by service_name;
    if @use_alter_object = 1 then
	insert into sa_unload_stage1 (id,sub,defn)
	    select order_col, 0, 
		    'call dbo.sa_make_object(' ||
			'''service'',' ||
			'''' || service_name || ''')' 
	FROM SYS.SYSWEBSERVICE s
	    JOIN unload_service us ON (us.service_id = s.service_id);
    end if;
    insert into sa_unload_stage1 (id,sub,defn)
	select order_col, 1, 
		if @use_alter_object = 0 then 'CREATE' else 'ALTER' endif ||
		' SERVICE "' || service_name || '" ' || @newline || '    ' ||
		'TYPE ''' || service_type || ''' ' ||
		'AUTHORIZATION ' || if auth_required = 'Y' then 'ON' else 'OFF' endif || ' ' ||
		'SECURE ' || if secure_required = 'Y' then 'ON' else 'OFF' endif || ' ' ||
		'URL PATH ' ||
			case url_path
			when 'Y' then 'ON'
			when 'N' then 'OFF'
			when 'E' then 'ELEMENTS'
			end || ' ' ||
		if u.user_name is not null then 'USER "' || u.user_name || '" ' endif ||
		if parameter is not null then 'USING "' || parameter || '" ' endif ||
		f_unload_service_enabled( s.service_id ) ||
		if statement is not null then 'AS' || @newline || statement endif
	FROM SYS.SYSWEBSERVICE s
	    JOIN unload_service us ON (us.service_id = s.service_id)
	    LEFT OUTER JOIN sa_unload_users_list u ON (u.user_id = s.user_id);
    insert into sa_unload_stage1 (id,sub,defn)
	SELECT order_col, 3,
	    f_unload_object_comment( 'SERVICE', null, service_name, null, remarks )
	FROM  SYS.SYSWEBSERVICE s
	    JOIN unload_service us ON (us.service_id = s.service_id)
	WHERE remarks is not null;
    
    call sa_unload_staged_text1();
end
go

create temporary procedure sa_unload_mirror_settings()
begin
    declare local temporary table mirror_server (
	object_id   unsigned bigint not null,
	server_name char(128)	    not null,
	server_type char(20)	    null,
	parent	    unsigned bigint null,
	alt_parent  unsigned bigint null,
	order_col   int		    not null
    ) in system not transactional;
    
    call sa_unload_script_comment( 'Create mirror options and servers', 0 );
    if f_unload_table_exists( 'SYSMIRROROPTION' ) = 0 then
	return;
    end if;
    insert into SQLDefn( txt )
	select 'SET MIRROR OPTION "' || option_name || '"' ||
	    ' = ' || f_unload_literal( option_value )
	from SYS.SYSMIRROROPTION;
    
    insert into mirror_server
	with recursive mirror_server 
	    (object_id, server_name, server_type, parent, alt_parent, level ) as
	((select object_id, server_name, server_type, parent, alternate_parent, 0
	from SYS.SYSMIRRORSERVER ms
	where parent is null)
	union all
	(select ms.object_id, ms.server_name, ms.server_type, ms.parent, ms.alternate_parent, s.level + 1
	  from SYS.SYSMIRRORSERVER ms 
		join mirror_server s on ms.parent = s.object_id
	  and s.level < 20))
	select object_id, server_name, server_type, parent, alt_parent, number(*)
	from mirror_server
	order by level,object_id;
    insert into sa_unload_stage1 (id,sub,defn)
	select order_col,1,
	    'CREATE MIRROR SERVER "' || ms.server_name || '" ' ||
		'AS ' || ms.server_type || ' ' ||
		if ms.parent is not null then 
		    'FROM SERVER "' || mp.server_name || '"' ||
		    if ms.alt_parent is not null then
			' OR SERVER "' || mp2.server_name || '"'
		    endif
		endif 
	from mirror_server ms
	    left outer join SYS.SYSMIRRORSERVER mp on ms.parent = mp.object_id
	    left outer join SYS.SYSMIRRORSERVER mp2 on ms.alt_parent = mp2.object_id;
    insert into sa_unload_stage1 (id,sub,defn)
	select order_col,2,
	    'ALTER MIRROR SERVER "' || server_name || '" ' || @newline || @tab ||
		    (select list( option_name || ' = ' || f_unload_literal( option_value ), @newline || @tab order by option_name, option_value )
		    from SYS.SYSMIRRORSERVEROPTION o where o.server_id = ms.object_id) 
	from mirror_server ms
	where exists (select * from SYS.SYSMIRRORSERVEROPTION o 
			where o.server_id = ms.object_id);
    insert into sa_unload_stage1 (id,sub,defn)
	select order_col,3,f_unload_object_comment( 'MIRROR SERVER', null, ms.server_name, null, r.remarks )
	from mirror_server ms
		join SYS.SYSREMARK r ON (ms.object_id = r.object_id);
    call sa_unload_staged_text1();
end
go

create temporary procedure sa_unload_auxiliary_catalog()
begin
    call sa_unload_script_comment( 'Auxiliary catalog' );

    insert into SQLDefn( txt )
	values(
	    'create temporary procedure sa_insert_auxiliary_table( ' || @newline ||
	    '   in obj_id unsigned bigint, ' || @newline ||
	    '   in pg_count int, ' || @newline ||
	    '   in row_count unsigned bigint, ' || @newline ||
	    '   in tabname char(128), ' || @newline ||
	    '   in owner char(128) ) ' || @newline ||
	    'begin ' || @newline ||
	    '  insert into dbo.sa_diagnostic_auxiliary_catalog ' || @newline ||
	    '    select obj_id, T.object_id, pg_count, row_count ' || @newline ||
	    '    from SYS.SYSTABLE T join SYS.SYSUSERPERM U ON ( T.creator = U.user_id ) ' || @newline ||
	    '    where T.table_name = tabname ' || @newline ||
	    '        and U.user_name = owner; ' || @newline ||
	    'end' 
	);
	
    insert into SQLDefn( txt )
	values(
	    'create temporary procedure sa_insert_auxiliary_user( ' || @newline ||
	    '   in obj_id unsigned bigint, ' || @newline ||
	    '   in username char(128) ) ' || @newline ||
	    'begin ' || @newline ||
	    '  insert into dbo.sa_diagnostic_auxiliary_catalog ' || @newline ||
	    '    select obj_id, U.object_id, NULL, NULL ' || @newline ||
	    '    from SYS.SYSUSER U ' || @newline ||
	    '    where U.user_name = username; ' || @newline ||
	    'end' 
	);

    insert into SQLDefn( txt )
	values(
	    'create temporary procedure sa_insert_auxiliary_trigger( ' || @newline ||
	    '   in obj_id unsigned bigint, ' || @newline ||
	    '   in trigname char(128), ' || @newline ||
	    '	in tableobjid unsigned bigint ) ' || @newline ||
	    'begin ' || @newline ||
	    '  insert into dbo.sa_diagnostic_auxiliary_catalog ' || @newline ||
	    '    select obj_id, T.object_id, NULL, NULL ' || @newline ||
	    '    from SYS.SYSTRIGGER T ' || @newline ||
	    '	    JOIN SYS.SYSTABLE TAB ' || @newline ||
	    '		ON ( T.table_id = TAB.table_id ) ' || @newline ||
	    '	    JOIN dbo.sa_diagnostic_auxiliary_catalog C ' || @newline ||
	    '		ON (TAB.object_id = C.local_object_id) ' || @newline ||
	    '    WHERE T.trigger_name = trigname AND ' || @newline ||
	    '	    C.original_object_id = tableobjid;' || @newline ||
	    'end' 
	);

    insert into SQLDefn( txt )
	values(
	    'create temporary procedure sa_insert_auxiliary_procedure( ' || @newline ||
	    '   in obj_id unsigned bigint, ' || @newline ||
	    '	in owner char(128), ' || @newline ||
	    '   in procname char(128) ) ' || @newline ||
	    'begin ' || @newline ||
	    '  insert into dbo.sa_diagnostic_auxiliary_catalog ' || @newline ||
	    '    select obj_id, P.object_id, NULL, NULL ' || @newline ||
	    '    from SYS.SYSPROCEDURE P join SYS.SYSUSERPERM U ON ( P.creator = U.user_id) ' || @newline ||
	    '    where P.proc_name = procname ' || @newline ||
	    '	 and U.user_name = owner ; ' || @newline ||
	    'end' 
	);
	
    insert into SQLDefn( txt )
	select
	    'call sa_insert_auxiliary_table( ' ||
		T.object_id || ', ' ||
		T.table_page_count || ', ' ||
		T.count || ', ' ||
		'''' || T.table_name || ''', ' ||
		'''' || U.user_name || ''' )'
	from SYS.SYSTABLE T JOIN sa_unload_users_list U ON ( T.creator = U.user_id );

    insert into SQLDefn( txt )
	select
	    'call sa_insert_auxiliary_user( ' ||
		U.object_id || ', ' ||
		'''' || U.user_name || ''' )'
	from SYS.SYSUSER U;

    insert into SQLDefn( txt )
	select
	    'call sa_insert_auxiliary_trigger( ' ||
		T.object_id || ', ' ||
		'''' || T.trigger_name || ''' , ' || TAB.object_id || ' )'
	from SYS.SYSTRIGGER T JOIN SYS.SYSTABLE TAB ON ( T.table_id = TAB.table_id );

    insert into SQLDefn( txt )
	select
	    'call sa_insert_auxiliary_procedure( ' ||
		P.object_id || ', ' ||
		'''' || U.user_name || ''',' ||
		'''' || P.proc_name || ''' )'
	from SYS.SYSPROCEDURE P JOIN sa_unload_users_list U on ( P.creator = U.user_id );

    insert into SQLDefn( txt )
	select
	    'create local temporary table AuxiliaryCostModelData(' ||
	    '	stat_id			unsigned int	not null,' ||
	    '	group_id		unsigned int	not null,' ||
	    '	format_id		smallint	not null,' ||
	    '	data			long binary		 ' ||
	    ') in system not transactional				 ';
    
    insert into SQLDefn( txt )
	select
	    'insert into AuxiliaryCostModelData values ' || @newline ||
	    '(' || stat_id || ',' || group_id || ',' || format_id || ',''' || 
	    data || ''')'
	from SYS.SYSOPTSTAT where stat_id = 1;
    
    insert into SQLDefn( txt )
	select
	    'call dbo.sa_internal_load_cost_model( ''AuxiliaryCostModelData'' )';

    insert into SQLDefn( txt )
	values ( 'COMMIT WORK' );

end
go

create temporary procedure sa_unload_remove_rs_objects()
begin
    if exists (select * from SYS.SYSCATALOG 
		where tname='rs_lastcommit' and creator='dbo') then
	call sa_unload_script_comment( 'Remove objects owned by rs_systabgroup' );
	insert into SQLDefn (txt)
	    select
		'if exists (select * from SYS.SYSPROCEDURE p ' || @newline ||
		'        join SYS.SYSUSER u on (p.creator = u.user_id) ' || @newline ||
		'        where proc_name = ''' || name || ''' ' || @newline ||
		'          and user_name = ''rs_systabgroup'') then ' || @newline || 
		'    DROP PROCEDURE rs_systabgroup."' || name || '";' || @newline ||
		'end if'    
	    from dbo.EXCLUDEOBJECT
	    where name like 'rs_%'
	    and type = 'P';
	insert into SQLDefn (txt)
	    select
		'if exists (select * from SYS.SYSTAB t ' || @newline ||
		'        join SYS.SYSUSER u on (t.creator = u.user_id) ' || @newline ||
		'        where table_name = ''' || name || ''' ' || @newline ||
		'          and user_name = ''rs_systabgroup'') then ' || @newline || 
		'    DROP TABLE rs_systabgroup."' || name || '";' || @newline ||
		'end if'    
	    from dbo.EXCLUDEOBJECT
	    where name like 'rs_%'
	    and type <> 'P';
    end if;
end
go

create temporary procedure sa_unload_drop_dba_role()
begin
    -- Drop DBA Authority System Role, if does not exist in source database
    if @has_rbac = 1 then
	if not exists (select * from SYS.SYSUSER where user_name ='SYS_AUTH_DBA_ROLE') then
	    insert into SQLDefn (txt)
		values( 'BEGIN ' ||
			'IF EXISTS (SELECT * FROM SYS.SYSUSER WHERE user_name = ''SYS_AUTH_DBA_ROLE'') ' ||
			'THEN DROP ROLE SYS_AUTH_DBA_ROLE WITH REVOKE ' ||
			'END IF; END; ' );
	end if;
    end if;
end
go

create temporary procedure sa_unload_remove_dba()
begin
    declare other_user char(128);
    declare other_password binary(128);
    
    if not exists (select * from SYS.SYSUSERPERM u
		    JOIN sa_unload_users_list sl ON ( u.user_id = sl.user_id )
		    where upper(u.user_name)='DBA' and u.dbaauth='Y') then
	call sa_unload_script_comment( 'Remove or modify DBA userid' );
	set other_user = CURRENT USER;
	select u.password into other_password
	from SYS.SYSUSERPERM u
	JOIN sa_unload_users_list sl ON ( u.user_id = sl.user_id )
	where u.user_name = other_user;
	insert into SQLDefn (txt)
	    values( 'GRANT CONNECT TO "' || other_user || '" IDENTIFIED BY sql' );
	call sa_unload_drop_dba_role();
	insert into SQLDefn (txt)
	    values( 'CONNECT USING ''UID=' || 
	                replace(other_user,'''','''''') || 
			';PWD=sql''' );
	if exists (select * from sa_unload_users_list where upper(user_name)='DBA') then
	    if @has_rbac = 1 then
	    insert into SQLDefn (txt)
		values( 'BEGIN ' ||
			'IF EXISTS (SELECT * FROM SYS.SYSUSER WHERE user_name = ''SYS_AUTH_DBA_ROLE'') ' ||
			'THEN REVOKE DBA FROM DBA ' ||
			'END IF; END; ' )
	    else
	    insert into SQLDefn (txt)
		values( 'REVOKE DBA FROM DBA ' );
	    end if;
	else
	    insert into SQLDefn (txt)
		values( 'BEGIN ' ||
			'IF EXISTS (SELECT * FROM SYS.SYSUSER WHERE user_name = ''DBA'') ' ||
			'THEN REVOKE CONNECT FROM DBA ' ||
			'END IF; END; ' )
	end if;
	insert into SQLDefn (txt)
	    values( 'GRANT CONNECT TO "' || other_user || '" ' ||
		    'IDENTIFIED BY ENCRYPTED ''' || 
			f_unload_hex_string(other_password) || '''' );
    elseif exists (select * from SYS.SYSUSERPERM u
		    JOIN sa_unload_users_list sl ON ( u.user_id = sl.user_id )
		    where upper(u.user_name)='DBA' and u.password is null) then
	call sa_unload_script_comment( 'Remove DBA password' );
	call sa_unload_drop_dba_role();
	insert into SQLDefn (txt)
	    values( 'GRANT CONNECT TO DBA' );
    else
	call sa_unload_script_comment( 'Set DBA password' );
	call sa_unload_drop_dba_role();
	insert into SQLDefn (txt)
	    select 'GRANT CONNECT TO DBA ' ||
		    'IDENTIFIED BY ENCRYPTED ''' || 
			f_unload_hex_string(u.password) || ''''
	    FROM SYS.SYSUSERPERM u
	    JOIN sa_unload_users_list sl ON ( u.user_id = sl.user_id )
	    where upper(u.user_name) = 'DBA';
    end if;
end
go

create temporary procedure sa_unload_options()
begin
    declare local temporary table temp_option (
	user_name   char(128)	    not null,
	option_name char(128)	    not null,
	setting	    long varchar    not null,
	primary key( user_name,option_name)
    ) in system not transactional;
    
    call sa_unload_script_comment( 'Create options' );
    call sa_unload_define_option_defaults();
    if f_unload_table_exists( 'ISYSLOGINPOLICY' ) = 0 then
	update sa_unload_option_default
	    set optval = ''
	    where optname = 'post_login_procedure';
    end if;
    call sa_unload_define_temporary_options();
    insert into SQLDefn (txt)
	values( 'SET OPTION date_order =' );
    insert into SQLDefn (txt)
	values( 'SET OPTION PUBLIC.preserve_source_format =' );
    insert into temp_option
	SELECT u.user_name, coalesce(dflt.optname,"option"), setting
	FROM SYS.SYSOPTION o
		JOIN sa_unload_users_list u ON (o.user_id = u.user_id)
		LEFT OUTER JOIN sa_unload_option_default dflt 
		    ON (lower(o."option") = dflt.optname)
	WHERE NOT (user_name = 'PUBLIC' 
		AND EXISTS (
		    SELECT * FROM sa_unload_option_default
		    WHERE lower(optname) = lower(o."option")
		    AND lower(optval) = lower(setting)))
	AND NOT EXISTS (SELECT * FROM sa_unload_obsolete_option
			WHERE lower(optname) = lower(o."option"))
	AND NOT EXISTS (SELECT * FROM sa_unload_temp_option 
			WHERE lower(optname) = lower(o."option"))
	AND NOT (u.user_name <> 'PUBLIC' 
		and "option" in ('Recovery_time', 'Checkpoint_time'))
	AND    (@extracting = 0 OR 
		    exists (select * from sa_extract_users eu
			    where eu.user_id = o.user_id));
    
    delete temp_option 
	where user_name <> 'PUBLIC'
	and lower(setting) = (select lower(optval) from sa_unload_option_default
				where lower(optname) = lower(option_name))
	and not exists(select * from SYS.SYSOPTION o
			where lower("option") = lower(option_name)
			and lower(o.setting) <> lower(temp_option.setting));

    delete temp_option 
	where user_name <> 'PUBLIC'
	and lower(option_name) in ( 'precision', 'scale', 'reserved_keywords' );
    update temp_option
	set setting = ''''''
	where (lower(option_name) = 'isql_quote' or option_name = 'ISQL_quote')
	and setting = '''';
    delete temp_option
	where lower(option_name) = 'post_login_procedure' 
	and lower(setting) = 'dba.sp_iq_process_post_login';
    delete temp_option
        where lower(option_name) = 'login_procedure'
        and lower(setting) = 'dba.sp_iq_process_login';
    if @make_auxiliary = 1 then
	delete from temp_option
	where lower(option_name) = 'auditing';
    end if;
    
    if @extracting = 1 then
	delete from temp_option
	where option_name = 'global_database_id';
	insert into temp_option
	    values( 'PUBLIC', 'global_database_id', @global_db_id );
	update temp_option
	    set setting = 'Standard'
	    where user_name = 'PUBLIC'
	    and option_name = 'login_mode';
	delete from temp_option
	where lower(option_name) = 'db_publisher';
    end if;
    
    insert into SQLDefn (txt)
	SELECT 'SET OPTION "' || user_name || '"."' || option_name || '"=' || 
		    f_unload_literal( setting ) ||
		    if lower(option_name) = 'db_publisher' and setting <> '-1' then string( ' // ', user_name( setting ) ) else '' endif
	FROM temp_option
	WHERE NOT (lower(option_name) = 'quoted_identifier' and lower(setting) = 'off')
	ORDER BY if user_name='PUBLIC' then 0 else 1 endif,user_name,option_name;
    insert into SQLDefn (txt)
	SELECT 'SET OPTION ' || user_name || '.' || option_name || '=' || 
		    f_unload_literal( setting )
	FROM temp_option
	WHERE (lower(option_name) = 'quoted_identifier' and lower(setting) = 'off')
	ORDER BY if user_name='PUBLIC' then 0 else 1 endif,user_name,option_name;
end
go

create temporary procedure sa_unload_build_definitions( in data_dir long varchar )
begin
    declare @limited_definitions int;
    
    set @limited_definitions = 0;
    if @table_list_provided = 1 and @data_only = 0 then
	set @limited_definitions = 1;
    end if;
    if @extracting = 1 then
	call sa_unload_remote_tables();
    end if;
    call sa_unload_set_table_list();
    if @data_only = 0 then
	if @limited_definitions = 0 or @no_data = 0 or @full_script = 1 then
	    call sa_unload_database_info();
	    call sa_unload_initial_options();
	end if;
	if @limited_definitions = 0 then
	    if @profiling_uses_single_dbspace = 0 then
		call sa_unload_dbspaces();
	    end if;
	    call sa_unload_ldap_servers();
	    call sa_unload_login_policies();
	    call sa_unload_users();
	    call sa_unload_user_types();
	    call sa_unload_user_classes();
	    call sa_unload_group_memberships();
	    call sa_unload_servers();
	    if @profiling_uses_single_dbspace = 0 then
		call sa_unload_dbspace_perms();
	    end if;
	    call sa_unload_extern_envs();
	    call sa_unload_certificates();
	end if;
	if @show_index_progress = 1 then
	    call sa_unload_make_status_proc();
	end if;
	call sa_unload_sequences(); 
	call sa_unload_table_definitions();
    end if;
    if @no_data = 0 or @full_script = 1 or @make_auxiliary = 1 then
	call sa_unload_define_tables();
    end if;
    if @no_data = 0 or @full_script = 1 then
	call sa_unload_load_statements( data_dir );
    end if;
    if @no_data = 1 and @full_script = 1 then
	truncate table sa_unload_data;
	truncate table sa_unload_data_with_mat;
    end if;
    insert into SQLDefn (txt)
	
	values ('commit work');
    set @post_load_line = (select max(line) from SQLDefn);
    if @data_only = 0 then
	call sa_unload_indexes();
	insert into SQLDefn (txt)
	    
	    values ('commit work');
	set @post_index_line = (select max(line) from SQLDefn);
	if @limited_definitions = 0 then
	    call sa_unload_procedures('F');
	    call sa_unload_views();
	    call sa_unload_user_messages();
	    call sa_unload_procedures('P');
	    insert into SQLDefn (txt)
		values ('call dbo.sa_recompile_views(0)' );
	    call sa_unload_remove_dropped_procedures();
	end if;
	call sa_unload_triggers();
	if @limited_definitions = 0 then
	    call sa_unload_sql_remote();
	    if @extracting = 0 then
		call sa_unload_mobilink();
	    end if;
	    call sa_unload_logins();
	    call sa_unload_identity_values();
	    call sa_unload_recompute_values();
	    call sa_unload_events();
	    call sa_unload_services();
	    call sa_unload_mirror_settings();
	    call sa_unload_remove_rs_objects();
	    call sa_unload_remove_dba();
	    call sa_unload_options();
	end if;
    end if;
    if @make_auxiliary = 1 then
	call sa_unload_auxiliary_catalog();
    end if;
     
end
go

create temporary procedure sa_unload_definition_script( in reload_file long varchar )
begin
    unload 
	select txt || if need_delim=1 then @cmdsep endif
	from SQLDefn
	order by line
    to reload_file quotes off escapes off hexadecimal off;
end
go

create temporary function f_unload_script( script_subset char(10) default 'all' )
returns long varchar
begin
    declare rslt long varchar;
    if script_subset = 'all' then
	select list(txt || if need_delim=1 then @cmdsep endif,@newline order by line) 
	    into rslt 
	from SQLDefn;
    elseif script_subset = 'preload' then
	select list(txt || if need_delim=1 then @cmdsep endif,@newline order by line) 
	    into rslt 
	from SQLDefn
	where line <= @post_load_line;
    elseif script_subset = 'indexes' then
	select list(txt || if need_delim=1 then @cmdsep endif,@newline order by line) 
	    into rslt 
	from SQLDefn
	where line > @post_load_line and line <= @post_index_line;
    else 
	select list(txt || if need_delim=1 then @cmdsep endif,@newline order by line) 
	    into rslt 
	from SQLDefn
	where line > @post_index_line;
    end if;
    return rslt;
end
go

create temporary function f_unload_one_table( 
    in @owner varchar(128), in @table varchar(128) )
returns long varchar
begin
    declare @defn long varchar;

    call sa_unload_initialize();
    set @table_list_provided = 1;
    set @no_data = 1;
    set @show_index_progress = 0;
    
    set @newline = char(10);
    set @cmdsep = @newline || ';' || @newline;
    set @suppress_messages = 1;
    set @suppress_script_comments = 1;
    delete from sa_unload_listed_table;
    insert into sa_unload_listed_table  
	values ( @owner, @table );
    call sa_unload_build_definitions( '' );
    set @defn =   
	f_unload_script('preload') ||
	f_unload_script('indexes') ||
	f_unload_script('postload');
    
    return @defn;
end
go

create temporary procedure sa_unload_define_old_excludes()
begin
    insert into sa_unload_old_exclude values ( 'xp_stopmail', 'P' );
    insert into sa_unload_old_exclude values ( 'xp_real_startmail', 'P' );
    insert into sa_unload_old_exclude values ( 'xp_startmail', 'P' );
    insert into sa_unload_old_exclude values ( 'xp_sendmail', 'P' );
    insert into sa_unload_old_exclude values ( 'xp_real_sendmail', 'P' );
    insert into sa_unload_old_exclude values ( 'xp_startsmtp', 'P' );
    insert into sa_unload_old_exclude values ( 'xp_real_startsmtp', 'P' );
    insert into sa_unload_old_exclude values ( 'xp_stopsmtp', 'P' );
    insert into sa_unload_old_exclude values ( 'xp_cmdshell', 'P' );
    insert into sa_unload_old_exclude values ( 'xp_real_cmdshell', 'P' );
    insert into sa_unload_old_exclude values ( 'xp_sprintf', 'P' );
    insert into sa_unload_old_exclude values ( 'xp_scanf', 'P' );
    insert into sa_unload_old_exclude values ( 'xp_msver', 'P' );
    insert into sa_unload_old_exclude values ( 'xp_real_write_file', 'P' );
    insert into sa_unload_old_exclude values ( 'xp_write_file', 'P' );
    insert into sa_unload_old_exclude values ( 'xp_real_read_file', 'P' );
    insert into sa_unload_old_exclude values ( 'xp_read_file', 'P' );

    insert into sa_unload_old_exclude values ( 'sa_conn_info', 'P' );
    insert into sa_unload_old_exclude values ( 'sa_conn_compression_info', 'P' );
    insert into sa_unload_old_exclude values ( 'sa_db_info', 'P' );
    insert into sa_unload_old_exclude values ( 'sa_eng_properties', 'P' );
    insert into sa_unload_old_exclude values ( 'sa_db_properties', 'P' );
    insert into sa_unload_old_exclude values ( 'sa_conn_properties', 'P' );
    insert into sa_unload_old_exclude values ( 'sa_internal_table_page_usage', 'P' );
    insert into sa_unload_old_exclude values ( 'sa_table_page_usage', 'P' );
    insert into sa_unload_old_exclude values ( 'sa_index_statistics', 'P' );
    insert into sa_unload_old_exclude values ( 'sa_validate', 'P' );
    insert into sa_unload_old_exclude values ( 'sa_checkpoint_execute', 'P' );

    insert into sa_unload_old_exclude values ( 'sp_tsql_feature_not_supported', 'P' );
    insert into sa_unload_old_exclude values ( 'sp_addalias', 'P' );
    insert into sa_unload_old_exclude values ( 'sp_addauditrecord', 'P' );
    insert into sa_unload_old_exclude values ( 'sp_addgroup', 'P' );
    insert into sa_unload_old_exclude values ( 'sp_dropdevice', 'P' );
    insert into sa_unload_old_exclude values ( 'sp_addlanguage', 'P' );
    insert into sa_unload_old_exclude values ( 'sp_addlogin', 'P' );
    insert into sa_unload_old_exclude values ( 'sp_addmessage', 'P' );
    insert into sa_unload_old_exclude values ( 'sp_addremotelogin', 'P' );
    insert into sa_unload_old_exclude values ( 'sp_addsegment', 'P' );
    insert into sa_unload_old_exclude values ( 'sp_addserver', 'P' );
    insert into sa_unload_old_exclude values ( 'sp_addthreshold', 'P' );
    insert into sa_unload_old_exclude values ( 'sp_addtype', 'P' );
    insert into sa_unload_old_exclude values ( 'sp_bindmsg', 'P' );
    insert into sa_unload_old_exclude values ( 'sp_adddumpdevice', 'P' );
    insert into sa_unload_old_exclude values ( 'sp_adduser', 'P' );
    insert into sa_unload_old_exclude values ( 'sp_auditdatabase', 'P' );
    insert into sa_unload_old_exclude values ( 'sp_auditlogin', 'P' );
    insert into sa_unload_old_exclude values ( 'sp_auditobject', 'P' );
    insert into sa_unload_old_exclude values ( 'sp_auditoption', 'P' );
    insert into sa_unload_old_exclude values ( 'sp_auditsproc', 'P' );
    insert into sa_unload_old_exclude values ( 'sp_bindefault', 'P' );
    insert into sa_unload_old_exclude values ( 'sp_bindrule', 'P' );
    insert into sa_unload_old_exclude values ( 'sp_changedbowner', 'P' );
    insert into sa_unload_old_exclude values ( 'sp_changegroup', 'P' );
    insert into sa_unload_old_exclude values ( 'sp_checknames', 'P' );
    insert into sa_unload_old_exclude values ( 'sp_checkperms', 'P' );
    insert into sa_unload_old_exclude values ( 'sp_checkreswords', 'P' );
    insert into sa_unload_old_exclude values ( 'sp_clearstats', 'P' );
    insert into sa_unload_old_exclude values ( 'sp_configure', 'P' );
    insert into sa_unload_old_exclude values ( 'sp_commonkey', 'P' );
    insert into sa_unload_old_exclude values ( 'sp_cursorinfo', 'P' );
    insert into sa_unload_old_exclude values ( 'sp_dropgroup', 'P' );
    insert into sa_unload_old_exclude values ( 'sp_dboption', 'P' );
    insert into sa_unload_old_exclude values ( 'sp_dbremap', 'P' );
    insert into sa_unload_old_exclude values ( 'sp_depends', 'P' );
    insert into sa_unload_old_exclude values ( 'sp_diskdefault', 'P' );
    insert into sa_unload_old_exclude values ( 'sp_displaylogin', 'P' );
    insert into sa_unload_old_exclude values ( 'sp_dropalias', 'P' );
    insert into sa_unload_old_exclude values ( 'sp_dropkey', 'P' );
    insert into sa_unload_old_exclude values ( 'sp_droplanguage', 'P' );
    insert into sa_unload_old_exclude values ( 'sp_droplogin', 'P' );
    insert into sa_unload_old_exclude values ( 'sp_dropmessage', 'P' );
    insert into sa_unload_old_exclude values ( 'sp_dropremotelogin', 'P' );
    insert into sa_unload_old_exclude values ( 'sp_dropsegment', 'P' );
    insert into sa_unload_old_exclude values ( 'sp_dropserver', 'P' );
    insert into sa_unload_old_exclude values ( 'sp_dropthreshold', 'P' );
    insert into sa_unload_old_exclude values ( 'sp_droptype', 'P' );
    insert into sa_unload_old_exclude values ( 'sp_dropuser', 'P' );
    insert into sa_unload_old_exclude values ( 'sp_helpindex', 'P' );
    insert into sa_unload_old_exclude values ( 'sp_estspace', 'P' );
    insert into sa_unload_old_exclude values ( 'sp_extendsegment', 'P' );
    insert into sa_unload_old_exclude values ( 'sp_foreignkey', 'P' );
    insert into sa_unload_old_exclude values ( 'sp_forward_to', 'P' );
    insert into sa_unload_old_exclude values ( 'sp_monitor', 'P' );
    insert into sa_unload_old_exclude values ( 'sp_getmessage', 'P' );
    insert into sa_unload_old_exclude values ( 'sp_help', 'P' );
    insert into sa_unload_old_exclude values ( 'sp_helpconstraint', 'P' );
    insert into sa_unload_old_exclude values ( 'sp_helpdb', 'P' );
    insert into sa_unload_old_exclude values ( 'sp_helpdevice', 'P' );
    insert into sa_unload_old_exclude values ( 'sp_helpgroup', 'P' );
    insert into sa_unload_old_exclude values ( 'sp_helpjoins', 'P' );
    insert into sa_unload_old_exclude values ( 'sp_helpkey', 'P' );
    insert into sa_unload_old_exclude values ( 'sp_helplanguage', 'P' );
    insert into sa_unload_old_exclude values ( 'sp_helplog', 'P' );
    insert into sa_unload_old_exclude values ( 'sp_helpremotelogin', 'P' );
    insert into sa_unload_old_exclude values ( 'sp_helpprotect', 'P' );
    insert into sa_unload_old_exclude values ( 'sp_helpsegment', 'P' );
    insert into sa_unload_old_exclude values ( 'sp_helpserver', 'P' );
    insert into sa_unload_old_exclude values ( 'sp_helpsort', 'P' );
    insert into sa_unload_old_exclude values ( 'sp_helptext', 'P' );
    insert into sa_unload_old_exclude values ( 'sp_helpthreshold', 'P' );
    insert into sa_unload_old_exclude values ( 'sp_helpuser', 'P' );
    insert into sa_unload_old_exclude values ( 'sp_indsuspect', 'P' );
    insert into sa_unload_old_exclude values ( 'sp_lock', 'P' );
    insert into sa_unload_old_exclude values ( 'sp_locklogin', 'P' );
    insert into sa_unload_old_exclude values ( 'sp_logdevice', 'P' );
    insert into sa_unload_old_exclude values ( 'sp_modifylogin', 'P' );
    insert into sa_unload_old_exclude values ( 'sp_modifythreshold', 'P' );
    insert into sa_unload_old_exclude values ( 'sp_password', 'P' );
    insert into sa_unload_old_exclude values ( 'sp_placeobject', 'P' );
    insert into sa_unload_old_exclude values ( 'sp_primarykey', 'P' );
    insert into sa_unload_old_exclude values ( 'sp_procxmode', 'P' );
    insert into sa_unload_old_exclude values ( 'sp_recompile', 'P' );
    insert into sa_unload_old_exclude values ( 'sp_remap', 'P' );
    insert into sa_unload_old_exclude values ( 'sp_remoteoption', 'P' );
    insert into sa_unload_old_exclude values ( 'sp_rename', 'P' );
    insert into sa_unload_old_exclude values ( 'sp_renamedb', 'P' );
    insert into sa_unload_old_exclude values ( 'sp_reportstats', 'P' );
    insert into sa_unload_old_exclude values ( 'sp_role', 'P' );
    insert into sa_unload_old_exclude values ( 'sp_serveroption', 'P' );
    insert into sa_unload_old_exclude values ( 'sp_setlangalias', 'P' );
    insert into sa_unload_old_exclude values ( 'sp_spaceused', 'P' );
    insert into sa_unload_old_exclude values ( 'sp_who', 'P' );
    insert into sa_unload_old_exclude values ( 'sp_syntax', 'P' );
    insert into sa_unload_old_exclude values ( 'sp_unbindefault', 'P' );
    insert into sa_unload_old_exclude values ( 'sp_unbindmsg', 'P' );
    insert into sa_unload_old_exclude values ( 'sp_unbindrule', 'P' );
    insert into sa_unload_old_exclude values ( 'sp_volchanged', 'P' );
    insert into sa_unload_old_exclude values ( 'sp_column_privileges', 'P' );
    insert into sa_unload_old_exclude values ( 'sp_columns', 'P' );
    insert into sa_unload_old_exclude values ( 'sp_databases', 'P' );
    insert into sa_unload_old_exclude values ( 'sp_datatype_info', 'P' );
    insert into sa_unload_old_exclude values ( 'sp_fkeys', 'P' );
    insert into sa_unload_old_exclude values ( 'sp_pkeys', 'P' );
    insert into sa_unload_old_exclude values ( 'sp_server_info', 'P' );
    insert into sa_unload_old_exclude values ( 'sp_serverinfo', 'P' );
    insert into sa_unload_old_exclude values ( 'sp_special_columns', 'P' );
    insert into sa_unload_old_exclude values ( 'sp_sproc_columns', 'P' );
    insert into sa_unload_old_exclude values ( 'sp_statistics', 'P' );
    insert into sa_unload_old_exclude values ( 'sp_stored_procedures', 'P' );
    insert into sa_unload_old_exclude values ( 'proc_role', 'P' );
    insert into sa_unload_old_exclude values ( 'sp_table_privileges', 'P' );
    insert into sa_unload_old_exclude values ( 'sp_tables', 'P' );
    insert into sa_unload_old_exclude values ( 'sp_tsql_environment', 'P' );
    insert into sa_unload_old_exclude values ( 'sp_login_environment', 'P' );
    insert into sa_unload_old_exclude values ( 'col_length', 'P' );
    insert into sa_unload_old_exclude values ( 'col_name', 'P' );
    insert into sa_unload_old_exclude values ( 'index_col', 'P' );
    insert into sa_unload_old_exclude values ( 'object_id', 'P' );
    insert into sa_unload_old_exclude values ( 'object_name', 'P' );
    insert into sa_unload_old_exclude values ( 'show_role', 'P' );
    insert into sa_unload_old_exclude values ( 'user_id', 'P' );
    insert into sa_unload_old_exclude values ( 'user_name', 'P' );
    insert into sa_unload_old_exclude values ( 'suser_id', 'P' );
    insert into sa_unload_old_exclude values ( 'suser_name', 'P' );
    insert into sa_unload_old_exclude values ( 'java_debug_release_vm', 'P' );
    insert into sa_unload_old_exclude values ( 'java_debug_connect', 'P' );
    insert into sa_unload_old_exclude values ( 'java_debug_get_vm_name', 'P' );
    insert into sa_unload_old_exclude values ( 'java_debug_attach_to_vm', 'P' );
    insert into sa_unload_old_exclude values ( 'java_debug_disconnect', 'P' );
    insert into sa_unload_old_exclude values ( 'java_debug_get_existing_vms', 'P' );
    insert into sa_unload_old_exclude values ( 'java_debug_free_existing_vms', 'P' );
    insert into sa_unload_old_exclude values ( 'java_debug_wait_for_debuggable_vm', 'P' );
    insert into sa_unload_old_exclude values ( 'java_debug_detach_from_vm', 'P' );
    insert into sa_unload_old_exclude values ( 'java_debug_request', 'P' );
    insert into sa_unload_old_exclude values ( 'sp_jdbc_datatype_info', 'P' );
    insert into sa_unload_old_exclude values ( 'sp_jdbc_function_escapes', 'P' );
    insert into sa_unload_old_exclude values ( 'sp_jdbc_tables', 'P' );
    insert into sa_unload_old_exclude values ( 'sp_jdbc_columns', 'P' );
    insert into sa_unload_old_exclude values ( 'sp_mda', 'P' );
    insert into sa_unload_old_exclude values ( 'sp_jdbc_fkeys', 'P' );
    insert into sa_unload_old_exclude values ( 'sp_jdbc_exportkey', 'P' );
    insert into sa_unload_old_exclude values ( 'sp_jdbc_importkey', 'P' );
    insert into sa_unload_old_exclude values ( 'sp_jdbc_getcrossreferences', 'P' );
    insert into sa_unload_old_exclude values ( 'sp_jdbc_getschemas', 'P' );
    insert into sa_unload_old_exclude values ( 'sp_jdbc_convert_datatype', 'P' );
    insert into sa_unload_old_exclude values ( 'sp_jdbc_getprocedurecolumns', 'P' );
    insert into sa_unload_old_exclude values ( 'sp_jdbc_primarykey', 'P' );
    insert into sa_unload_old_exclude values ( 'sp_jdbc_stored_procedures', 'P' );
    insert into sa_unload_old_exclude values ( 'sp_jdbc_gettableprivileges', 'P' );
    insert into sa_unload_old_exclude values ( 'sp_jdbc_getcolumnprivileges', 'P' );
    insert into sa_unload_old_exclude values ( 'sp_jdbc_getbestrowidentifier', 'P' );
    insert into sa_unload_old_exclude values ( 'sp_jdbc_getversioncolumns', 'P' );
    insert into sa_unload_old_exclude values ( 'sp_jdbc_getindexinfo', 'P' );
    insert into sa_unload_old_exclude values ( 'sp_jdbc_escapeliteralforlike', 'P' );
    insert into sa_unload_old_exclude values ( 'sp_sql_type_name', 'P' );
    insert into sa_unload_old_exclude values ( 'sp_default_charset', 'P' );

    insert into sa_unload_old_exclude values ( 'rs_get_last_commit', 'P' );
    insert into sa_unload_old_exclude values ( 'rs_update_last_commit', 'P' );
    insert into sa_unload_old_exclude values ( 'rs_marker', 'P' );
    insert into sa_unload_old_exclude values ( 'rs_initialize_threads', 'P' );
    insert into sa_unload_old_exclude values ( 'rs_update_threads', 'P' );

    insert into sa_unload_old_exclude values ( 'sa_audit_string', 'P' );

    insert into sa_unload_old_exclude values ( 'add_user_security_manager', 'P' );
    insert into sa_unload_old_exclude values ( 'update_user_security_manager', 'P' );
    insert into sa_unload_old_exclude values ( 'delete_user_security_manager', 'P' );
    insert into sa_unload_old_exclude values ( 'set_default_security_manager', 'P' );

    insert into sa_unload_old_exclude values ( 'sa_disk_free_space', 'P' );
    insert into sa_unload_old_exclude values ( 'sa_internal_disk_free_space', 'P' );

    insert into sa_unload_old_exclude values ( 'sa_internal_alter_index_ability', 'P' );
    insert into sa_unload_old_exclude values ( 'sa_enable_index', 'P' );
    insert into sa_unload_old_exclude values ( 'sa_disable_index', 'P' );
    insert into sa_unload_old_exclude values ( 'sa_virtual_sysixcol', 'P' );
    insert into sa_unload_old_exclude values ( 'sa_internal_virtual_sysixcol', 'P' );
    insert into sa_unload_old_exclude values ( 'sa_virtual_sysindex', 'P' );
    insert into sa_unload_old_exclude values ( 'sa_internal_virtual_sysindex', 'P' );
    insert into sa_unload_old_exclude values ( 'sa_get_simulated_scale_factor', 'P' );
    insert into sa_unload_old_exclude values ( 'sa_internal_get_simulated_scale_factor', 'P' );
    insert into sa_unload_old_exclude values ( 'sa_set_simulated_scale_factor', 'P' );
    insert into sa_unload_old_exclude values ( 'sa_internal_recommend_indexes', 'P' );
    insert into sa_unload_old_exclude values ( 'sa_recommend_indexes', 'P' );
    insert into sa_unload_old_exclude values ( 'sa_remove_index_tuning_analysis', 'P' );
    insert into sa_unload_old_exclude values ( 'sa_add_index_tuning_analysis', 'P' );
    insert into sa_unload_old_exclude values ( 'sa_add_workload_query', 'P' );
    insert into sa_unload_old_exclude values ( 'sa_internal_stop_index_tuning', 'P' );
    insert into sa_unload_old_exclude values ( 'sa_stop_index_tuning', 'P' );

    insert into sa_unload_old_exclude values ( 'sysalternates', 'V' );
    insert into sa_unload_old_exclude values ( 'syscolumns', 'V' );
    insert into sa_unload_old_exclude values ( 'syscomments', 'V' );
    insert into sa_unload_old_exclude values ( 'sysconstraints', 'V' );
    insert into sa_unload_old_exclude values ( 'sysdepends', 'V' );
    insert into sa_unload_old_exclude values ( 'sysindexes', 'V' );
    insert into sa_unload_old_exclude values ( 'syskeys', 'V' );
    insert into sa_unload_old_exclude values ( 'syslogs', 'V' );
    insert into sa_unload_old_exclude values ( 'sysobjects', 'V' );
    insert into sa_unload_old_exclude values ( 'sysprocedures', 'V' );
    insert into sa_unload_old_exclude values ( 'sysprotects', 'V' );
    insert into sa_unload_old_exclude values ( 'sysreferences', 'V' );
    insert into sa_unload_old_exclude values ( 'sysroles', 'V' );
    insert into sa_unload_old_exclude values ( 'syssegments', 'V' );
    insert into sa_unload_old_exclude values ( 'systhresholds', 'V' );
    insert into sa_unload_old_exclude values ( 'systypes', 'V' );
    insert into sa_unload_old_exclude values ( 'sysusers', 'V' );
    insert into sa_unload_old_exclude values ( 'syscharsets', 'V' );
    insert into sa_unload_old_exclude values ( 'sysconfigures', 'V' );
    insert into sa_unload_old_exclude values ( 'syscurconfigs', 'V' );
    insert into sa_unload_old_exclude values ( 'sysdatabases', 'V' );
    insert into sa_unload_old_exclude values ( 'sysdevices', 'V' );
    insert into sa_unload_old_exclude values ( 'sysengines', 'V' );
    insert into sa_unload_old_exclude values ( 'syslanguages', 'V' );
    insert into sa_unload_old_exclude values ( 'syslocks', 'V' );
    insert into sa_unload_old_exclude values ( 'sysloginroles', 'V' );
    insert into sa_unload_old_exclude values ( 'syslogins', 'V' );
    insert into sa_unload_old_exclude values ( 'sysmessages', 'V' );
    insert into sa_unload_old_exclude values ( 'sysprocesses', 'V' );
    insert into sa_unload_old_exclude values ( 'sysservers', 'V' );
    insert into sa_unload_old_exclude values ( 'sysremotelogins', 'V' );
    insert into sa_unload_old_exclude values ( 'syssrvroles', 'V' );
    insert into sa_unload_old_exclude values ( 'sysusages', 'V' );
    insert into sa_unload_old_exclude values ( 'sysaudits', 'V' );
    insert into sa_unload_old_exclude values ( 'sysauditoptions', 'V' );

    insert into sa_unload_old_exclude values ( 'RowGenerator', 'U' );
    insert into sa_unload_old_exclude values ( 'spt_jdatatype_info', 'U' );
    insert into sa_unload_old_exclude values ( 'jdbc_function_escapes', 'U' );
    insert into sa_unload_old_exclude values ( 'spt_mda', 'U' );
    insert into sa_unload_old_exclude values ( 'spt_jtext', 'U' );
    insert into sa_unload_old_exclude values ( 'jdbc_helpkeys', 'U' );
    insert into sa_unload_old_exclude values ( 'spt_jdbc_conversion', 'U' );
    insert into sa_unload_old_exclude values ( 'jdbc_tableprivileges', 'U' );
    insert into sa_unload_old_exclude values ( 'jdbc_columnprivileges', 'U' );
    insert into sa_unload_old_exclude values ( 'jdbc_indexhelp', 'U' );
    insert into sa_unload_old_exclude values ( 'spt_collation_map', 'U' );
    insert into sa_unload_old_exclude values ( 'EXCLUDEOBJECT', 'U' );
    insert into sa_unload_old_exclude values ( 'rs_lastcommit', 'U' );
    insert into sa_unload_old_exclude values ( 'rs_threads', 'U' );
    insert into sa_unload_old_exclude values ( 'ixtun_master', 'U' );
    insert into sa_unload_old_exclude values ( 'ixtun_query_text', 'U' );
    insert into sa_unload_old_exclude values ( 'ixtun_query_phase', 'U' );
    insert into sa_unload_old_exclude values ( 'ixtun_workload', 'U' );
    insert into sa_unload_old_exclude values ( 'ixtun_query_index', 'U' );
    insert into sa_unload_old_exclude values ( 'ixtun_index', 'U' );
    insert into sa_unload_old_exclude values ( 'ixtun_ixcol', 'U' );
    insert into sa_unload_old_exclude values ( 'ixtun_affected_columns', 'U' );
    insert into sa_unload_old_exclude values ( 'ixtun_log', 'U' );
    insert into sa_unload_old_exclude values ( 'ixtun_capture', 'U' );

    insert into sa_unload_old_exclude values ( 'ul_statement', 'E' );
    insert into sa_unload_old_exclude values ( 'JAVAUSERSECURITY', 'E' );
    insert into sa_unload_old_exclude values ( 'rs_threads', 'E' );
    insert into sa_unload_old_exclude values ( 'rs_lastcommit', 'E' );
    insert into sa_unload_old_exclude values ( 'ul_file', 'E' );
    insert into sa_unload_old_exclude values ( 'ul_variable', 'E' );
    
    insert into sa_unload_old_exclude values ( 'sp_jdbc_class_for_name' , 'P' );
    insert into sa_unload_old_exclude values ( 'sp_jdbc_classes_in_jar' , 'P' );
    
    insert into sa_unload_old_exclude values ( 'sa_get_server_messages' , 'P' );
    insert into sa_unload_old_exclude values ( 'jdbc_functioncolumns', 'U' );
    insert into sa_unload_old_exclude values ( 'sp_jdbc_getfunctioncolumns', 'P' );
end
go

create temporary procedure sa_unload_define_jconnect_tables()
begin
    insert into sa_unload_jconnect_table values ( 'jdbc_columnprivileges' );
    insert into sa_unload_jconnect_table values ( 'jdbc_function_escapes' );
    insert into sa_unload_jconnect_table values ( 'jdbc_tableprivileges' );
    insert into sa_unload_jconnect_table values ( 'spt_datatype_info' );
    insert into sa_unload_jconnect_table values ( 'spt_jdbc_conversion' );
    insert into sa_unload_jconnect_table values ( 'spt_jtext' );
    insert into sa_unload_jconnect_table values ( 'spt_mda' );
end
go

create temporary procedure sa_unload_define_jconnect_procs()
begin
    insert into sa_unload_jconnect_proc values ( 'sp_jdbc_columns' );
    insert into sa_unload_jconnect_proc values ( 'sp_jdbc_convert_datatype' );
    insert into sa_unload_jconnect_proc values ( 'sp_jdbc_datatype_info' );
    insert into sa_unload_jconnect_proc values ( 'sp_jdbc_exportkey' );
    insert into sa_unload_jconnect_proc values ( 'sp_jdbc_function_escapes' );
    insert into sa_unload_jconnect_proc values ( 'sp_jdbc_getbestrowidentifier' );
    insert into sa_unload_jconnect_proc values ( 'sp_jdbc_getcolumnprivileges' );
    insert into sa_unload_jconnect_proc values ( 'sp_jdbc_getcrossreferences' );
    insert into sa_unload_jconnect_proc values ( 'sp_jdbc_getindexinfo' );
    insert into sa_unload_jconnect_proc values ( 'sp_jdbc_getprocedurecolumns' );
    insert into sa_unload_jconnect_proc values ( 'sp_jdbc_getschemas' );
    insert into sa_unload_jconnect_proc values ( 'sp_jdbc_gettableprivileges' );
    insert into sa_unload_jconnect_proc values ( 'sp_jdbc_getversioncolumns' );
    insert into sa_unload_jconnect_proc values ( 'sp_jdbc_importkey' );
    insert into sa_unload_jconnect_proc values ( 'sp_jdbc_primarykey' );
    insert into sa_unload_jconnect_proc values ( 'sp_jdbc_stored_procedures' );
    insert into sa_unload_jconnect_proc values ( 'sp_jdbc_tables' );
    insert into sa_unload_jconnect_proc values ( 'sp_mda' );
end
go

create temporary procedure sa_unload_define_obsolete_user_funcs()
begin
    insert into sa_unload_obsolete_user_func values ( 'user_name' );
    insert into sa_unload_obsolete_user_func values ( 'user_id' );
    insert into sa_unload_obsolete_user_func values ( 'suser_name' );
    insert into sa_unload_obsolete_user_func values ( 'suser_id' );
end
go

create temporary function f_unload_table_has_rows( @tabname char(128) )
returns int
begin
    set @table_has_rows = 0;
    if exists(select * from SYS.SYSCATALOG 
	where tname=@tabname and creator='dbo') then
	execute immediate
	    'if exists(select * from dbo.' || @tabname || ') then ' ||
	    '   set @table_has_rows = 1; ' ||
	    'end if';
    end if;
    return @table_has_rows;
end
go

create temporary procedure sa_unload_define_exclude_objects()
begin
    declare @include_ultralite int;
    declare @include_mobilink int;
    
    set @include_mobilink = 0;
    call sa_make_int_variable( '@table_has_rows' );
    if f_unload_table_has_rows( 'ml_user' ) = 1
    or f_unload_table_has_rows( 'ml_script' ) = 1
    or f_unload_table_has_rows( 'ml_subscription' ) = 1 then
	set @include_mobilink = 1;
    end if;
    
    call sa_unload_define_old_excludes();
    if exists(select * from SYS.SYSCATALOG 
	where tname='EXCLUDEOBJECT' and creator='dbo') then
	insert into sa_unload_exclude_object
	    select name,type from dbo.EXCLUDEOBJECT
	    where @include_mobilink = 0 or name not like 'ml_%';
	
	insert into sa_unload_exclude_object
	    select name,type from sa_unload_old_exclude e1
	    where not exists (select * from sa_unload_exclude_object e2
			      where e1.name = e2.name);
    else
	insert into sa_unload_exclude_object
	    select name,type from sa_unload_old_exclude;
    end if;
    
    set @include_ultralite = f_unload_table_has_rows( 'ul_file' );;
    if @include_ultralite = 1 then
	delete from sa_unload_exclude_object
	    where name in ('ul_file','ul_variable','ul_statement');
    else
	update sa_unload_exclude_object
	    set type = 'U'
	    where name in ('ul_file','ul_variable','ul_statement');
    end if;
    
    call sa_unload_define_jconnect_tables();
    call sa_unload_define_jconnect_procs();
    call sa_unload_define_obsolete_user_funcs();
end
go

create temporary function f_unload_column_default( @table_id unsigned int, @column_id unsigned int )
returns long varchar
begin
    declare rslt long varchar;
    if @has_column_type = 1 then
	select
		if c."default" is not null then 
		    if c.column_type = 'C' then
			' COMPUTE (' || c."default" || ')'
		    else
			' DEFAULT ' || c."default" 
		    endif
		endif
	    into rslt
	    from SYS.SYSCOLUMN c
	    where c.table_id = @table_id
	    and c.column_id = @column_id;
    else
	select
		if c."default" is not null then 
		    ' DEFAULT ' || c."default" 
		endif
	    into rslt
	    from SYS.SYSCOLUMN c
	    where c.table_id = @table_id
	    and c.column_id = @column_id;
    end if;
    return rslt;
end
go

create temporary function f_unload_column_check( 
    @table_id	    unsigned int,
    @column_id	    unsigned int )
returns long varchar
begin
    declare rslt long varchar;

    if @has_named_constraints = 0 then
	select ' ' || "check" 
	into rslt
	from SYS.SYSCOLUMN
	where table_id = @table_id
	  and column_id = @column_id;
    else
	select list(
			' ' ||
			if substr(constraint_name,1,3) <> 'ASA' then
			    'CONSTRAINT "' || constraint_name || '" '
			endif ||
			check_defn, '' )
	    into rslt
	    from SYS.SYSCONSTRAINT cns 
		JOIN SYS.SYSCHECK chk ON (chk.check_id = cns.constraint_id)
	    where cns.table_id = @table_id
	      and cns.column_id = @column_id
	      and cns.index_id IS NULL
	      and cns.fkey_id IS NULL;
    end if;
    return rslt;
end
go

create temporary function f_has_column_check( 
    @table_id	    unsigned int,
    @column_id	    unsigned int )
returns int
begin
    if @has_named_constraints = 0 then
	if exists(select * from SYS.SYSCOLUMN
		    where table_id = @table_id
		      and column_id = @column_id
		      and "check" is not null) then
	    return 1;
	else
	    return 0;
	end if;
    else
	if exists(SELECT * FROM SYS.SYSCONSTRAINT 
		  WHERE table_id = @table_id
		  AND   column_id = @column_id) then
	    return 1;
	else
	    return 0;
	end if;
    end if;
end
go

create temporary function f_unload_unique_constraint_name( 
    @table_id unsigned int,
    @index_id unsigned int )
returns long varchar
begin
    declare rslt long varchar;

    if @has_named_constraints = 0 then
	set rslt = null;
    else
	select 
		    if substr(constraint_name ,1,3) <> 'ASA' then
			'CONSTRAINT "' || constraint_name || '" '
		    endif 
	    into rslt
	    from SYS.SYSCONSTRAINT cns
	    where cns.table_id = @table_id
	    and cns.index_id = @index_id
	    and constraint_type = 'U';
    end if;
    return rslt;
end
go

create temporary function f_unload_clustered_attribute( @table_id unsigned int, @index_id int )
returns varchar(20)
begin
    declare rslt char(10);
    set rslt = '';
    if f_unload_table_exists( 'SYSATTRIBUTE' ) = 1 then
	if exists (select * 
		    from SYS.SYSATTRIBUTE at
			JOIN SYS.SYSATTRIBUTENAME an 
			    ON (an.attribute_id = at.attribute_id)
		    WHERE at.object_type = 'T' 
		    AND an.attribute_name = 'Clustered index' 
		    AND at.object_id = @table_id
		    AND at.attribute_value = @index_id) then 
	    set rslt = 'CLUSTERED ';
	end if;
    end if;
    return rslt;
end
go

create temporary function f_unload_sync_last_download_time( @sync_id unsigned int )
returns timestamp
begin
    declare rslt timestamp;
    if @has_last_download_time = 1 then
	select last_download_time into rslt from SYS.SYSSYNC where sync_id = @sync_id;
    else
	set rslt = NULL;
    end if;
    return rslt;
end
go

create temporary function f_unload_sync_log_sent( @sync_id unsigned int )
returns numeric(20,0)
begin
    declare rslt numeric(20,0);
    if @has_log_sent = 1 then
	select log_sent into rslt from SYS.SYSSYNC where sync_id = @sync_id;
    else
	set rslt = NULL;
    end if;
    return rslt;
end
go

create temporary function f_unload_sync_created( @sync_id unsigned int )
returns numeric(20,0)
begin
    declare rslt numeric(20,0);
    if @has_log_sent = 1 then
	select created into rslt from SYS.SYSSYNC where sync_id = @sync_id;
    else
	set rslt = NULL;
    end if;
    return rslt;
end
go

create temporary function f_unload_sync_last_upload_time( @sync_id unsigned int )
returns timestamp
begin
    declare rslt timestamp;
    if @has_log_sent = 1 then
	select last_upload_time into rslt from SYS.SYSSYNC where sync_id = @sync_id;
    else
	set rslt = NULL;
    end if;
    return rslt;
end
go

create temporary function f_unload_sync_generation_number( @sync_id unsigned int )
returns integer
begin
    declare rslt integer;
    if @has_log_sent = 1 then
	select generation_number into rslt from SYS.SYSSYNC where sync_id = @sync_id;
    else
	set rslt = NULL;
    end if;
    return rslt;
end
go

create temporary function f_unload_sync_extended_state( @sync_id unsigned int )
returns varchar(1024)
begin
    declare rslt varchar(1024);
    if @has_log_sent = 1 then
	select extended_state into rslt from SYS.SYSSYNC where sync_id = @sync_id;
    else
	set rslt = NULL;
    end if;
    return rslt;
end
go

create temporary procedure sa_unload_primary_keys()
begin
    if @has_named_constraints = 0 then
	insert into sa_unload_stage1 (id,sub,need_delim,defn)
	    SELECT t.order_col, 1000000, 0,
		'   ,PRIMARY KEY ' ||
		    f_unload_clustered_attribute( t.table_id, 0 ) ||
		    '(' || 
			list('"' || column_name || '"' order by column_id) ||
		    ') '
	    FROM unload_tabs t
		    JOIN SYS.SYSCOLUMN c ON (t.table_id = c.table_id)
	    WHERE c.pkey='Y'
	    GROUP BY t.table_id, t.order_col;
    else
	insert into sa_unload_stage1 (id,sub,need_delim,defn)
	    SELECT order_col, 1000000, 0,
		'   ,' ||
		(select 
		    if substr(constraint_name,1,3) <> 'ASA' then
			'CONSTRAINT "' || constraint_name || '" '
		    endif 
		  from SYS.SYSCONSTRAINT cns 
		 where cns.table_id = t.table_id 
		 and cns.constraint_type = 'P'
		 and cns.column_id is null) ||
		'PRIMARY KEY (' || 
			list('"' || column_name || '"' order by column_id) ||
			') '
	    FROM unload_tabs t
		    JOIN SYS.SYSCOLUMN c ON (t.table_id = c.table_id)
	    WHERE c.pkey='Y'
	    GROUP BY t.table_id, t.order_col;
    end if;
end
go

create temporary procedure sa_unload_constraints()
begin
    if @has_named_constraints = 0 then
	insert into sa_unload_stage1 (id,sub,need_delim,defn)
	    select t.order_col, 2000000, 0,
		'   , ' || tt.view_def
	    from unload_tabs t
		JOIN SYS.SYSTABLE tt ON (tt.table_id = t.table_id)
	    where tt.view_def is not null
	    and tt.table_type = 'BASE';
    else
	insert into sa_unload_stage1 (id,sub,need_delim,defn)
	    select t.order_col, 2000000, 0,
		    list(
			'   ,' || 
			if substr(constraint_name,1,3) <> 'ASA' then 
			    'CONSTRAINT "' || constraint_name || '" ' 
			endif ||
			check_defn, @newline order by cns.constraint_id)
	    from unload_tabs t
		LEFT OUTER JOIN SYS.SYSCONSTRAINT cns ON (cns.table_id = t.table_id and cns.column_id is null)
		JOIN SYS.SYSCHECK chk ON (chk.check_id = cns.constraint_id)
	    where constraint_type = 'T'
	      and cns.index_id is null
	      and cns.fkey_id is null
	    group by t.table_id, t.order_col;
    end if;
end
go

create temporary procedure sa_unload_pctfree()
begin
    if f_unload_table_exists( 'SYSATTRIBUTE' ) = 1 then
	insert into sa_unload_stage1 (id,sub,need_delim,defn)
	    select t.order_col, 2999999, 0,
		'   ,PCTFREE ' || at.attribute_value
	    from unload_tabs t
		JOIN SYS.SYSATTRIBUTE at ON (at.object_id = t.table_id)
		JOIN SYS.SYSATTRIBUTENAME an ON  (an.attribute_id = at.attribute_id)
	    where at.object_type = 'T' 
	    and   an.attribute_name = 'Table Page Percent Free';
    end if;
end
go

create temporary procedure sa_unload_user_messages()
begin
    call sa_unload_script_comment( 'Create user messages' );
    insert into SQLDefn (need_delim,txt)
	SELECT 0,
	    'CREATE MESSAGE ' || error || ' AS ''' || replace(description,'''','''''') || '''' || ' USER ' || cr.user_name || @cmdsep
	FROM SYS.SYSUSERMESSAGES m
		JOIN SYS.SYSUSERPERM cr ON (m.uid = cr.user_id);
end
go

create temporary procedure sa_unload_servers()
begin
    call sa_unload_script_comment( 'Create remote servers' );
    if f_unload_table_exists( 'SYSSERVERS' ) = 0 then
	return;
    end if;
    if f_unload_table_exists( 'SYSCAPABILITY' ) = 0 then
	return;
    end if;
    insert into SQLDefn (txt)
	SELECT 'CREATE SERVER "' || srvname || '" ' ||
		'CLASS ''' || srvclass || ''' ' ||
		'USING ''' || replace(srvinfo,'''','''''') || ''' ' ||
		if srvreadonly = 'Y' then 'READ ONLY' endif
	FROM SYS.SYSSERVERS
	ORDER BY srvid;
    if exists(select * from SYS.SYSCAPABILITY) then
	call sa_unload_make_capability_proc();
    end if;
    insert into SQLDefn (txt)
	SELECT 'call sa_unload_define_capability( ' ||
		'''' || srvname || ''', ' ||
		'''' || capname || ''', ' ||
		if capvalue = 'T' then '''ON''' else '''OFF''' endif || ' )'
	FROM SYS.SYSSERVERS s
		JOIN SYS.SYSCAPABILITY c ON (c.srvid = s.srvid)
		JOIN SYS.SYSCAPABILITYNAME cn ON (cn.capid = c.capid)
	ORDER BY s.srvid, c.capid;
    insert into SQLDefn (txt)
	SELECT 'CREATE EXTERNLOGIN "' || user_name || '" ' ||
		'TO "' || srvname || '" ' ||
		if remote_login is not null then 
		    'REMOTE LOGIN "' || remote_login || '" ' 
		endif ||
		if remote_password is not null then 
		    'IDENTIFIED BY ENCRYPTED ''' || 
			f_unload_hex_string( remote_password ) || '''' 
		endif
	FROM SYS.SYSSERVERS s
		JOIN SYS.SYSEXTERNLOGINS l ON (s.srvid = l.srvid)
		JOIN SYS.SYSUSERPERM u ON (u.user_id = l.user_id)
	ORDER BY s.srvid, l.user_id;
end
go

create temporary procedure sa_unload_logins()
begin	
    if @extracting = 1 then
	return;
    end if;
    if f_unload_table_exists( 'SYSLOGIN' ) = 0 then
	return;
    end if;
    call sa_unload_script_comment( 'Create logins' );
    insert into sa_unload_stage1 (id,sub,defn)
	SELECT number(*),1,
		'GRANT INTEGRATED LOGIN TO [' || l.integrated_login_id || '] ' ||
		'AS USER "' || u.user_name || '"'
	FROM SYS.SYSLOGIN l
	       JOIN SYS.SYSUSERPERM u ON (l.login_uid = u.user_id)
	ORDER BY l.integrated_login_id;
    insert into sa_unload_stage1 (id,sub,defn)
	SELECT number(*),2,
	    f_unload_object_comment( 'INTEGRATED LOGIN', null, l.integrated_login_id, null, l.remarks )
	FROM SYS.SYSLOGIN l
	ORDER BY l.integrated_login_id;
    call sa_unload_staged_text1();
end
go

create temporary function f_unload_is_remote_table( @table_id int )
returns int
begin
    declare @rslt int;
    
    if @has_omni_columns = 0 then
	return 0;
    end if;
    select if remote_location is null then 0 else 1 endif into @rslt
    from SYS.SYSTABLE
    where table_id = @table_id;
    return isnull( @rslt, 0 );
end
go

