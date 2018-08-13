// ***************************************************************************
// Copyright (c) 2013 SAP AG or an SAP affiliate company. All rights reserved.
// ***************************************************************************
// This sample code is provided AS IS, without warranty or liability of any kind.
// 
// You may use, reproduce, modify and distribute this sample code without
// limitation,  on the condition that you retain the foregoing copyright
// notice and disclaimer as to the original code.  
// 
// *******************************************************************

-- show_table
--     procedure definition and service

-- Browse to http://localhost/show_table

-- Provide a valid database userid and password when prompted.

create or replace procedure query_table( in @tablename varchar(128), in @owner varchar(128) default NULL )
result ( xmldoc long varchar )
begin
        declare @query long varchar;
        declare @result long varchar;

        call dbo.sa_set_http_header( 'Content-Type', 'text/xml' );
        if @owner is null then
                set @query = ( 'select * into @result from "'
                    || replace( @tablename, '"', '""' )
                    || '" for xml auto' );
        else
                set @query = ( 'select * into @result from "'
                    || replace( @owner, '"', '""' )
                    || '"."'
                    || replace( @tablename, '"', '""' )
                    || '" for xml auto' );
        end if;
        execute immediate
                with quotes on
                with escapes off
                with result set off
                @query;
        select '<root>' || @result || '</root>';
exception
        when others then
                set @result = '** Exception ** ' || errormsg() || ', query is ' || @query;
                select '<root><error>' || html_encode(@result) || '</error></root>';
end;

if exists(select * from SYS.SYSWEBSERVICE where service_name='qtable') then
    drop service qtable;
end if
go

create service qtable type 'raw' authorization on url off
  as call query_table( :tablename, :owner )
go


create or replace procedure show_table( user_name long varchar, table_name long varchar, limit int, start_at int )
result (html_document long varchar)
BEGIN
    declare and_user long varchar;
    declare user_dot long varchar;
    declare top_n    long varchar;
    declare st_at    long varchar;
    declare header_a long varchar;
    declare header_b long varchar;
    declare header_c long varchar;

    set and_user = ifnull( user_name, '', ' and t.creator = '
                || '( select user_id from sysuserperm where user_name = ''' || user_name || ''' )' );
    set user_dot = ifnull( user_name, '', '"' || user_name || '".' );
    set top_n    = ifnull( limit, '', ' top ' || cast( limit as long varchar ) || ' ' );
    set st_at    = ifnull( start_at, '', ' start at ' || cast( start_at as long varchar ) || ' ' );

    set header_a = '<table width="100%" bgcolor="#FFFF11"><tr>'
                || '<td align=center><a href="show_table">Full List of Tables</a></td>\n'
                || ifnull( user_name, '', '<td align=center><a href="show_table?user_name='
                || http_encode( user_name ) || '">List of Tables For User '
                || html_encode( user_name ) || '</a></td>\n' );
    set header_b = '';
    set header_c = '<td align=center><a href="show_table?user_name=SYS&table_name=SysWebService">Web Services</a></td>\n'
                || '<td align=center><a href="show_table?user_name=SYS&table_name=SysHistory">Database History</a></td>\n'
                || '</tr></table>\n';

    call dbo.sa_set_http_header( 'Content-Type', 'text/html' );

    IF table_name is null THEN
        -- display list of all tables
        -- in this example, we concatenate the result into one large string 'res'
        BEGIN
            declare res    long varchar;
            declare query  long varchar;

            IF start_at is not null OR limit is not null THEN
                set start_at = coalesce( start_at, 1 );
                set header_b =
                        if start_at = 1 then '' else
                                '<td align=center><a href="show_table?'
                             || ifnull( user_name, '', 'user_name=' || http_encode( user_name ) || '&' )
                             || 'start=' || cast( (if start_at<20 then 1 else (start_at-20) endif) as int )
                             || ifnull( limit, '', '&limit=' || cast( limit as int ) )
                             || '">Previous Rows</a>'
                        endif
                        || '<td align=center><a href="show_table?'
                        || ifnull( user_name, '', 'user_name=' || http_encode( user_name ) || '&' )
                        || 'start=' || cast( (start_at+20) as int )
                        || ifnull( limit, '', '&limit=' || cast( limit as int ) )
                        || '">Next Rows</a>';
            END IF;

            set res = '<html><head><title>Database Tables'
                || ifnull( user_name, '', ' Owned By ' || html_encode( user_name ) )
                || '</title></head>\n<body>\n'
                || header_a || header_b || header_c
                || '<h1>Database Tables'
                || ifnull( user_name, '', ' Owned By ' || html_encode( user_name ) )
                || '</h1>\n'
                || '<u>Link Legend:</u><table>\n'
                || ' <tr><td>&oplus;</td><td>Query table using "qtable" HTML service.</td></tr>\n'
                || ' <tr><td>&Delta;</td><td>Show first 20 rows of table using show_table service.</td></tr>\n'
                || ' <tr><td>Name</td><td>Show entire contents of table using show_table service.</td></tr>\n'
                || '</table>\n';
                
            set query = 'select '
                || top_n || st_at
                || ' u.user_name, t.table_name from sys.sysuserperm u, sys.systable t'
                || ' where u.user_id = t.creator'
                || and_user
                || ' order by u.user_name, t.table_name';
            BEGIN
                    
                declare curt cursor using query;
                declare last_usr long varchar;
                declare usr_name long varchar;
                declare tab_name long varchar;
                open curt;
                set last_usr = '';
            loop1:
                LOOP
                    fetch curt into usr_name, tab_name;
                    IF SQLCODE <> 0 THEN leave loop1 END IF;
                    IF usr_name <> last_usr THEN
                        set res = res || '<hr><h2>User ' || html_encode( usr_name ) || '</h2>\n';
                        set last_usr = usr_name;
                    END IF;
                    set res = res
                        || '&nbsp;|&mdash;&nbsp;&nbsp;&nbsp;<a href="qtable?tablename='
                        || http_encode( tab_name )
                        || '&owner='
                        || http_encode( usr_name )
                        || '">&oplus;</a>'
                        || '&nbsp;&nbsp;<a href="show_table?user_name='
                        || http_encode( usr_name )
                        || '&table_name='
                        || http_encode( tab_name )
                        || '&limit=20">&Delta;</a>'
                        || '&nbsp;&nbsp;&mdash;&nbsp;<a href="show_table?user_name='
                        || http_encode( usr_name )
                        || '&table_name='
                        || http_encode( tab_name ) || '">'
                        || html_encode( tab_name ) || '</a><br>\n';
                END LOOP;
                close curt;
            END;
            set res = res || '<hr>' || header_a || header_b || header_c || '</body></html>';
            select res;
            RETURN;
        END;
    else
        -- display contents of a table
        -- in this example, we use a temporary table to store the results
        BEGIN
            declare local temporary table #res ( s long varchar, i integer default autoincrement );
            declare query long varchar;
            declare qcols long varchar;

            IF start_at is not null OR limit is not null THEN
                set start_at = coalesce( start_at, 1 );
                set header_b =
                        if start_at = 1 then '' else
                                '<td align=center><a href="show_table?'
                             || ifnull( user_name, '', 'user_name=' || http_encode( user_name ) || '&' )
                             || 'table_name=' || http_encode( table_name ) || '&'
                             || 'start=' || cast( (if start_at<20 then 1 else (start_at-20) endif) as int )
                             || ifnull( limit, '', '&limit=' || cast( limit as int ) )
                             || '">Previous Rows</a>'
                        endif
                        || '<td align=center><a href="show_table?'
                        || ifnull( user_name, '', 'user_name=' || http_encode( user_name ) || '&' )
                        || 'table_name=' || http_encode( table_name ) || '&'
                        || 'start=' || cast( (start_at+20) as int )
                        || ifnull( limit, '', '&limit=' || cast( limit as int ) )
                        || '">Next Rows</a>';
            END IF;

            insert #res(s) values( '<html><head><title>Table ' || html_encode( user_dot )
                                 || html_encode( table_name ) || '</title></head><body>\n'
                                 || header_a || header_b || header_c
                                 || '<h1>Table ' || html_encode( user_dot )
                                 || html_encode( table_name ) || '</h1>\n' );
            insert #res(s) values( '<table border=1>\n' );

            -- add table column headers
            -- use a 'list()' trick to combine the columns
            set query = 'select list( ''<th>''||html_encode(c.column_name)||''</th>'', '''' )'
                    || ' from sys.syscolumn c, sys.systable t'
                    || ' where t.table_id = c.table_id'
                    || and_user
                    || ' and t.table_name = ''' || table_name || '''';
            execute immediate 'insert into #res(s) ' || query;

            -- generate list of data columns to be queried
            -- rather than using list(), this is the more traditional (but slower) method
            set query = 'select c.column_name'
                    || ' from sys.syscolumn c, sys.systable t'
                    || ' where t.table_id = c.table_id'
                    || and_user
                    || ' and t.table_name = ''' || table_name || '''';

            set qcols = '''<tr>''';
            BEGIN
                declare curc cursor using query;
                declare col_name long varchar;
                open curc;
                insert #res(s) values( '<tr>' );
            loop2:
                LOOP
                    fetch curc into col_name;
                    IF SQLCODE <> 0 THEN leave loop2 END IF;
                        set qcols = qcols
                                || '||''<td>''|| ifnull("' || col_name
                                || '", ''<i>-NULL-</i>'', html_encode(cast("' || col_name
                                || '" as long varchar))) ||''</td>\n''';
                END LOOP;
                close curc;
                insert #res(s) values( '</tr>\n' );
            EXCEPTION
                WHEN OTHERS THEN
                    insert #res(s) values( 'An error occurred during processing - ' || html_encode( errormsg() ) );
                    insert #res(s) values( '<br>Query: ' || html_encode( query ) );
                    set qcols = qcols || '<td>error</td>';
            END;
            set qcols = qcols || '||''</tr>\n''';

            -- and finally query the column data
            set query = 'select ' || top_n || st_at || qcols || ' from ' || user_dot || '"' || table_name || '"';
            BEGIN
                execute immediate 'insert into #res(s) ' || query;
            EXCEPTION
                WHEN OTHERS THEN
                    insert #res(s) values( 'An error occurred during processing - ' || html_encode( errormsg() ) );
                    insert #res(s) values( '<br>Query: ' || html_encode( query ) );
            END;

            insert #res(s) values( '</table>\n' );
            insert #res(s) values( '<hr>' || header_a || header_b || header_c );
            insert #res(s) values( '</body></html>' );
            select s from #res order by i;
            RETURN;
        END;
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        select '<html><head><title>show_table error</title></head>'
            || '<body>An error occurred during processing - '
            || html_encode( errormsg() )
            || '<br></body></html>';
        return;
END;
go

if exists(select * from SYS.SYSWEBSERVICE where service_name='show_table') then
    drop service show_table;
end if
go

create service show_table type 'raw' authorization on user dba secure off
  as call show_table( :user_name, :table_name, :limit, :start )
go
