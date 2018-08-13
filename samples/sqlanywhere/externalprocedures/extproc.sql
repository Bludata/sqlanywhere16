// ***************************************************************************
// Copyright (c) 2013 SAP AG or an SAP affiliate company. All rights reserved.
// ***************************************************************************
// This sample code is provided AS IS, without warranty or liability of any kind.
// 
// You may use, reproduce, modify and distribute this sample code without limitation, 
// on the condition that you retain the foregoing copyright notice and disclaimer 
// as to the original code.  
// 
// *******************************************************************

create or replace function dbo.xp_all_types( 
    in p1 integer,
    in p2 tinyint,
    in p3 smallint,
    in p4 bigint,
    in p5 char(30),
    in p6 double,
    in p7 long varchar )
    returns long varchar
    external name 'xp_all_types@extproc.dll'
go

grant execute on dbo.xp_all_types to public
go


create or replace procedure dbo.xp_replicate( 
    in p1 integer,
    in p2 long varchar,
    out p3 long varchar )
    external name 'xp_replicate@extproc.dll'
go

grant execute on dbo.xp_replicate to public
go


create or replace function dbo.xp_strip_punctuation_and_spaces( in str long varchar )
    returns long varchar
    external name 'xp_strip_punctuation_and_spaces@extproc.dll'
go

grant execute on dbo.xp_strip_punctuation_and_spaces to public
go


create or replace function dbo.xp_get_word( in str char(255), in wordnum int )
    returns char(255)
    external name 'xp_get_word@extproc.dll'
go


grant execute on dbo.xp_get_word to public
go

