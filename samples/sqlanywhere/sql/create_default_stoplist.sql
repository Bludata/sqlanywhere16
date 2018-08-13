-- ***************************************************************************
-- Copyright (c) 2013 SAP AG or an SAP affiliate company. All rights reserved.
-- ***************************************************************************
-- This sample code is provided AS IS, without warranty or liability
-- of any kind.
-- 
-- You may use, reproduce, modify and distribute this sample code
-- without limitation, on the condition that you retain the foregoing
-- copyright notice and disclaimer as to the original code.  
-- 
-- *********************************************************************

-- Create a table that associates the language with the iso_639 language code
if exists(select * from SYS.SYSTAB where table_name='stopword_language') then 
    drop table stopword_language 
end if;
create table stopword_language( lang char(2), label long varchar ) in system;
load table stopword_language from 'stopword_language.csv';

-- Load the examples stoplists into a table
if exists(select * from SYS.SYSTAB where table_name='stopword_table') then 
    drop table stopword_table 
end if;
create table stopword_table( lang char(2), stopword long nvarchar ) in system;
load table stopword_table from 'stopword_table.csv' encoding 'utf-8';

-- Create a variable holding the stoplist for the current language
if varexists( 'new_stoplist' ) = 0 then
    create variable new_stoplist long nvarchar;
end if;
set new_stoplist=(select list(stopword,' ') 
		from stopword_table 
		where stopword_table.lang = 
		    (select lang 
		    from stopword_language 
		    where label=property('language')));

-- Set both the CHAR and the NCHAR stoplist
alter text configuration default_char stoplist new_stoplist;
alter text configuration default_nchar stoplist new_stoplist;
