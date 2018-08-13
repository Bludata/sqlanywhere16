create temporary procedure sa_unload_define_temporary_options()
begin
    insert into sa_unload_temp_option values( 'blocking_others_timeout' );
    insert into sa_unload_temp_option values( 'connection_authentication' );
    insert into sa_unload_temp_option values( 'upgrade_database_capability' );
    insert into sa_unload_temp_option values( 'conn_auditing' );
    insert into sa_unload_temp_option values( 'return_date_time_as_string' );
    insert into sa_unload_temp_option values( 'time_zone_adjustment' );
    insert into sa_unload_temp_option values( 'force_view_creation' );
    insert into sa_unload_temp_option values( 'dedicated_task' );
    insert into sa_unload_temp_option values( 'secure_feature_key' );
end
go
