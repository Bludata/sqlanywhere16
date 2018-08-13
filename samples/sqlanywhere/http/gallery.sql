-- ***************************************************************************
-- Copyright (c) 2013 SAP AG or an SAP affiliate company. All rights reserved.
-- ***************************************************************************
// This sample code is provided AS IS, without warranty or liability of any kind.
// 
// You may use, reproduce, modify and distribute this sample code without
// limitation,  on the condition that you retain the foregoing copyright
// notice and disclaimer as to the original code.  
// 
// *******************************************************************

-- gallery
--     procedure definitions and services

-- To use this example with larger images, set the server command line http
-- option MaxRequestSize to 3M or greater.
-- e.g., -xs http(MaxRequestSize=3m)

-- From a browser:
-- http://localhost/gallery 
-- Once images have been loaded, you can also try the gallery_image service:
-- http://localhost/gallery_image?url=1 (or 2, 3, etc.)

-- A sample image file is located at:
-- <samples-dir>\SQLAnywhere\HTTP\picture.jpg

create table if not exists dba.gallery (
    id           unsigned int     not null default autoincrement,
    title        char(80)         not null,
    filename     char(250)        not null,
    filetype     char(50)         not null,
    filesize     unsigned int     not null,
    descr        long varchar     null,
    image        long binary      not null,
    primary key ( id )
)
go

create or replace procedure gallery( action varchar(10) )
result (html_document long varchar)
begin
	declare res long varchar;	-- ultimate result
	declare bar long varchar;	-- top and bottom button bar
	declare str long varchar;	-- work str

	set action = ifnull( action, 'welcome', action );

	set bar = ''
	||	'<table bgcolor=yellow width="100%"><tr align=center>\n'
	||	' <td><a href="gallery?action=welcome">Home</a></td>\n'
	||	' <td><a href="gallery?action=list">List All</a></td>\n'
	||	' <td><a href="gallery?action=first">Show First</a></td>\n'
	||	' <td><a href="gallery?action=last">Show Last</a></td>\n'
	||	' <td><a href="gallery?action=add">Add File</a></td>\n'
	||	'</tr></table>\n';

	set res = '<html><head><title>Gallery</title></head>\n<body>\n' || bar || '<hr>';

	--------------------
	if action = 'welcome' then
	    begin
		declare v_count int;

		select count(*) into v_count from dba.gallery;

		set res = res
		||	'<h1><center>Welcome to Gallery</center></h1>'
		||	'<br><br><center>There are currently ' || v_count || ' items stored</center>'
		||	'<br><br><center>Please choose an option from the button bar above or below<center><br>';
	    end;

	--------------------
	elseif action = 'list' then
		set res = res
		||	'<h1><center>Gallery Listing</center></h1>'
		||	'<table width="100%" border=1 align=center>\n'
		||	'<tr>\n'
		||	' <th>Id</td>\n'
		||	' <th>Size</td>\n'
		||	' <th>Type</td>\n'
		||	' <th>File Name</td>\n'
		||	' <th>Title</td>\n'
		||	' <th>Description</td>\n'
		||	'</tr>\n'
		||	( select list(	'<tr align=center valign=top><td><a href="gallery?action=show&id=' || g.id
				||	'">' || g.id || '</a>'
				||	'</td><td>' || html_encode( g.filesize )
				||	'</td><td>' || html_encode( g.filetype )
				||	'</td><td>' || html_encode( g.filename )
				||	'</td><td>' || html_encode( g.title )
				||	'</td><td>' || replace( html_encode(g.descr), '\n', '<br>' )
				||	'&nbsp;</td>',
					'' order by g.id )
			    from dba.gallery g )
		||	'</table>';

	--------------------
	elseif action = 'add' or action = 'edit' or action='del' then
	    begin
		declare v_title varchar(80);
		declare v_name  varchar(250);
		declare v_descr long varchar;
		declare v_id	int;

		if action = 'add' then
			set v_id = NULL;
		else
			set v_id = http_variable( 'id' );
			if v_id is not NULL then
				select g.title, g.filename, g.descr
				  into v_title, v_name, v_descr
				  from dba.gallery g
				 where g.id = v_id;
			end if;
		end if;
		if v_id is NULL or v_id = '' then
			set res = res
			||	'<h1><center>Add Gallery File</center></h1>'
			||	'<form method="POST" action="gallery" enctype="multipart/form-data">\n';
		else
			set res = res
			||	'<h1><center>Edit Gallery File # ' || v_id || '</center></h1>'
			||	'<center><img src="gallery_image/' || v_id
			||      '" alt="' || html_encode(v_name) || '" height=250></center>\n'
			||	'<form method="POST" action="gallery">\n';
		end if;
		set res = res
		||	' <input type="hidden" name="action" value="save">\n'
		||	ifnull( v_id, '', ' <input type="hidden" name="id" value="' || v_id || '">\n' )
		||	'<center><table>\n'
		||	'<tr>\n'
		||	' <td align=right>Title:</td>\n'
		||	' <td><input type="text" name="title" size=60 maxlength=80 value="'
		||      html_encode(v_title) || '"></td>\n'
		||	'</tr>\n'
		||	'<tr>\n'
		||	' <td align=right>File:</td>\n';
		if v_id is NULL or v_id = '' then
			set res = res
			||	' <td><input type="file" name="image" size=60 maxlength=1000000 value="'
			||      html_encode(v_name) || '" accept="image/gif, image/jpg"></td>\n';
		else
			set res = res
			||	' <td>' || html_encode(v_name) || '</td>\n';
		end if;
		set res = res
		||	'</tr>\n'
		||	'<tr>\n'
		||	' <td align=right>Description:</td>\n'
		||	' <td><textarea name="descr" rows=5 cols=60>'
		||      html_encode(v_descr) || '</textarea></td>\n'
		||	'</tr>\n'
		||	'<tr>\n'
		||	' <td><input type="reset" value="Clear"></td>\n';
		if v_id is NULL or v_id = '' then
			set res = res
			||	' <td align=right><input type="submit" value="Add File to Gallery"></td>\n';
		else
			set res = res
			||	' <td align=right><input type="submit" value="Update Gallery File"></td>\n'
			||	'</tr>\n<tr>\n';
			if action = 'del' then
				set res = res
				||	' <td colspan=2>Are you really sure you want to delete this entry?'
				||	' <a href="gallery?action=edit&id=' || v_id || '">No, I want to keep it.</a>'
				||	' or <a href="gallery?action=delete&id=' || v_id || '">Yes, delete it now.</a>'
				||	'</td>';
			else
				set res = res
				||	' <td colspan=2><a href="gallery?action=del&id=' || v_id
				||      '">Delete this entry</a></td>';
			end if;
		end if;
		set res = res
		||	'</tr>\n'
		||	'</table></form>\n';
	    end;

	--------------------
	elseif action = 'delete' then
	    begin
		declare v_id	int;

		set v_id    = http_variable( 'id' );

		delete from dba.gallery where id = v_id;

		set res = res
		||	'<h1><center>Delete From Gallery</center></h1>'
		||	'<center>Entry # ' || v_id || ' has been successfully deleted.</center>\n';
	    exception
		when others then
			set res = res
			||	'<br><b>An error occurred while attempting to delete entry # '
				|| v_id || '</b><br>'
			||	html_encode(errormsg())
			||	'<br>';
	    end;

	--------------------
	elseif action = 'save' then
	    begin
		declare v_title varchar(80);
		declare v_name  varchar(250);
		declare v_type  varchar(50);
		declare v_descr long varchar;
		declare v_image long binary;
		declare i       int;
		declare v_id	int;
                declare v_filesize int;
                declare v_resize varchar(15);

		set v_id    = http_variable( 'id' );
		set v_title = http_variable( 'title' );
		set v_descr = http_variable( 'descr' );

		set v_name  = http_variable( 'image', NULL, 'Content-Disposition' );
		set v_type  = http_variable( 'image', NULL, 'Content-Type' );
		set v_image = http_variable( 'image', NULL, '@BINARY' );
                set v_filesize = length( v_image );

		-- pick out the filename from the Content-Disposition
		set i = locate( v_name, 'filename=' );
		set v_name = substr( v_name, i+10 );
		set i = locate( v_name, '"' );
		set v_name = left( v_name, i-1 );

		if v_title is NULL or v_title = '' then
			set v_title = v_name;
		end if;
		if v_id is NULL then
			insert into dba.gallery( title, filename, filetype, filesize, descr, image )
				values( v_title, v_name, v_type, v_filesize, v_descr, v_image );
			select @@identity into v_id;
			set res = res
			||	'<h1><center>Gallery File Added</center></h1>'
			||	'<center>File has been successfully added.</center>\n';
		else
			update dba.gallery
			   set	title = v_title,
				descr = v_descr
			  where id = v_id;
			set res = res
			||	'<h1><center>Gallery File Updated</center></h1>'
			||	'<center>File has been successfully updated.</center>\n';
		end if;

		if v_filesize <= 81920 then
		    set v_resize = ''
		else
		    set v_resize = 'height="50%"'
		end if;

		set str = ''
		||	'<center><table><tr align=center>\n'
		||	' <td width=100><a href="gallery?action=first">First</a></td>\n'
		||	' <td width=100><a href="gallery?action=prev&id=' || v_id || '">Prev</a></td>\n'
		||	' <td width=100><a href="gallery?action=edit&id=' || v_id || '">- ' || v_id || ' -</a></td>\n'
		||	' <td width=100><a href="gallery?action=next&id=' || v_id || '">Next</a></td>\n'
		||	' <td width=100><a href="gallery?action=last">Last</a></td>\n'
		||	'</tr></table></center>\n';

		set res = res
		||	str
		||	'<h1><center>' || html_encode(v_title) || '</center></h1>\n'
		||	'<center><img src="gallery_image/' || v_id
		||      '" alt="' || html_encode(v_name) || '" '|| v_resize || '></center>\n'
		||	'<br><center>' || replace( html_encode( v_descr ), '\n', '<br>' ) || '</center>'
		||	str;

	    exception
		when others then
			set res = res
			||	'<br><b>An error occurred while attempting to add the file</b><br>'
			||	html_encode(errormsg())
			||	'<br>';
	    end;

	--------------------
	elseif action = 'first' or action = 'last' or action = 'prev' or action = 'next' or action = 'show' then
	    begin
		declare v_title varchar(80);
		declare v_name  varchar(250);
		declare v_descr long varchar;
		declare v_id	int;
		declare v_filesize int;
		declare v_resize varchar(15);

		if action = 'first' then
			select min(g.id) into v_id from dba.gallery g;
		elseif action = 'last' then
			select max(g.id) into v_id from dba.gallery g;
		elseif action = 'prev' then
			select max(g.id) into v_id from dba.gallery g where g.id < http_variable( 'id' );
			if v_id is NULL then
				select max(g.id) into v_id from dba.gallery g;
			end if;
		elseif action = 'next' then
			select min(g.id) into v_id from dba.gallery g where g.id > http_variable( 'id' );
			if v_id is NULL then
				select min(g.id) into v_id from dba.gallery g;
			end if;
		elseif action = 'show' then
			set v_id = http_variable( 'id' );
		else
			-- bad input... just pick a random one - we will use #1
			set v_id = NULL;
		end if;

		if v_id is not NULL then
			select g.title, g.filename, g.descr, g.filesize
			  into v_title, v_name, v_descr, v_filesize
			  from dba.gallery g
			 where g.id = v_id;
		end if;

		if v_filesize <= 81920 then
		    set v_resize = ''
		else
		    set v_resize = 'height="50%"'
		end if;

		set str = ''
		||	'<center><table><tr align=center>\n'
		||	' <td width=100><a href="gallery?action=first">First</a></td>\n'
		||	' <td width=100><a href="gallery?action=prev&id=' || v_id || '">Prev</a></td>\n'
		||	' <td width=100><a href="gallery?action=edit&id=' || v_id || '">- ' || v_id || ' -</a></td>\n'
		||	' <td width=100><a href="gallery?action=next&id=' || v_id || '">Next</a></td>\n'
		||	' <td width=100><a href="gallery?action=last">Last</a></td>\n'
		||	'</tr></table></center>\n';

		set res = res
		||	str
		||	'<h1><center>' || html_encode(v_title) || '</center></h1>\n'
		||	'<center><img src="gallery_image/' || v_id
		||      '" alt="' || html_encode(v_name) || '" '|| v_resize || '></center>\n'
		||	'<br><center>' || replace( html_encode( v_descr ), '\n', '<br>' ) || '</center>'
		||	str;

	    exception
		when others then
			set res = res
			||	'<br><b>An error occurred while attempting to add the file</b><br>'
			||	html_encode(errormsg())
			||	'<br>';
	    end;

	else
		set res = res
		||      '<h1><center>Huh?</center></h1>\n'
		||      '<br>Huh? unknown action - please try again !<br>';
	end if;	

	set res = res	
	||	'<br><hr>\n' || bar || '<hr>\n'
	||	'<div class=powered><center>POWERED BY<br>'
	||	'<i>' || html_encode( property('ProductName') || ' ' || property('ProductVersion') ) || '</i><br>'
	||	'<small><i>' || html_encode( property('LegalCopyright') ) || '</i></small></center><hr></div>\n'
	||	'</body>\n</html>\n';

	call dbo.sa_set_http_header( 'Content-Type', 'text/html' );
	select res;
end
go

create or replace procedure gallery_image( i_url varchar(250) )
result (rawdoc long binary)
begin
	declare try     char(100);
	declare v_type  varchar(50);
	declare v_image long binary;

	if isnumeric( i_url ) = 1 then
		-- try selection by number
		set try = 'by id ' || i_url;
		select g.filetype, g.image into v_type, v_image
		  from dba.gallery g
		 where g.id = i_url;
	end if;
	if v_image is NULL then
		-- try selection by filename
		set try = 'by name "' || i_url || '"';
		select g.filetype, g.image into v_type, v_image
		  from dba.gallery g
		 where g.filename = i_url;
	end if;
	if v_image is NULL then
		-- try selection by title?
		set try = 'by title "' || i_url || '"';
		select g.filetype, g.image into v_type, v_image
		  from dba.gallery g
		 where g.title = i_url;
	end if;
	if v_image is NULL then
		set try = 'not found: "' || i_url || '"';
		set v_type = 'text/html';
		set v_image = 'Image not found';
	else
		set try = 'found ' || try;
	end if;
	call sa_set_http_header( 'Content-Type', v_type );
	call sa_set_http_header( 'Content-Length', string(length(v_image)) );
	select v_image;
exception
	when others then
		select 'An error occurred during ' || try || ': ' || html_encode(errormsg());
end;
go

if exists(select * from SYS.SYSWEBSERVICE where service_name='gallery') then
    drop service gallery;
end if;
if exists(select * from SYS.SYSWEBSERVICE where service_name='gallery_image') then
    drop service gallery_image;
end if;
go

create service gallery type 'raw' authorization off user dba secure off
  as call gallery( :action )
go
create service gallery_image type 'raw' authorization off user dba secure off url on
  as call gallery_image( :url )
go
