// ***************************************************************************
// Copyright (c) 2013 SAP AG or an SAP affiliate company. All rights reserved.
// ***************************************************************************
alter function dbo.xp_real_startmail( 
		in mail_user   long varchar   default null, 
		in mail_password long varchar default null,
		in cid int )
	returns int 
	external name 'xp_startmail@dbextf.dll' 
go

alter function dbo.xp_real_stopmail( in cid int )
	returns int 
	external name 'xp_stopmail@dbextf.dll' 
go

alter function dbo.xp_real_startsmtp(
		in smtp_sender		long varchar,
		in smtp_server		long varchar,
		in smtp_port		int		default 25,
		in timeout		int		default 60,
		in smtp_sender_name	long varchar	default null,
		in smtp_auth_username	long varchar	default null,
		in smtp_auth_password	long varchar	default null,
		in trusted_certificates	long varchar	default null,
		in certificate_company	long varchar	default null,
		in certificate_unit	long varchar	default null,
		in certificate_name	long varchar	default null,
		in cid			int )
	returns int
	external name 'xp_startsmtp@dbextf;Unix:xp_startsmtp@libdbextf'
go

alter function dbo.xp_real_stopsmtp( in cid int )
	returns int 
	external name 'xp_stopsmtp@dbextf;Unix:xp_stopsmtp@libdbextf'
go

alter function dbo.xp_real_sendmail( 	
		in recipient           long varchar, 
		in subject             long varchar	default null, 
		in cc_recipient        long varchar	default null, 
		in bcc_recipient       long varchar	default null, 
		in query               long varchar	default null, 
		in "message"           long varchar	default null, 
		in attachname          long varchar	default null, 
		in attach_result       int		default 0, 
		in echo_error          int		default 1, 
		in include_file        long varchar	default null, 
		in no_column_header    int		default 0, 
		in no_output           int		default 0, 
		in width               int		default 80, 
		in separator           char(1)		default char(9), 
		in dbuser              long varchar	default 'guest', 
		in dbname              long varchar	default 'master', 
		in type                long varchar	default null, 
		in include_query       int		default 0,
		in content_type        long varchar	default null, 
		in cid		       int ) 
	returns int 
	external name 'xp_sendmail@dbextf;Unix:xp_sendmail@libdbextf' 
go
drop function dbo.xp_get_mail_error_code
go
drop function dbo.xp_real_get_mail_error_code
go
drop function dbo.xp_get_mail_error_text
go
drop function dbo.xp_real_get_mail_error_text
go

