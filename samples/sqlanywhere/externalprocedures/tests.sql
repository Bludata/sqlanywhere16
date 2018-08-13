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

-- This file calls the sample external stored procedures.
-- Results are stored in a temporary table and displayed at the end.

begin
    declare local temporary table results(
	pk int primary key default autoincrement,
	test_name char(20),
	_result long varchar ) on commit preserve rows;
    declare rslt long varchar;
    declare len int;

    message 'Testing xp_all_types' to client;
    begin
	set rslt = xp_all_types( 1234567, 255, 12345, 1234567890123,
			'abcdefghijkl', 12.34e15, repeat('*',50) );
	insert into results(test_name,_result) 
	    values( '1)', 'Result: ' || rslt );
	set rslt = xp_all_types( null, 127, -12345, null,
			'abcdefghijkl', 12.34e15, repeat('=',300) );
	insert into results(test_name,_result) 
	    values( '1)', 'Result: ' || rslt );
	set rslt = xp_all_types( 1, 2, 3, 4,
			dateformat(cast( '2010/01/31 15:43:18.617' as timestamp),
			    'yyyy/mm/dd hh:nn:ss.sss'), 
			12.34e15, repeat('1234567890',5) );
	insert into results(test_name,_result) 
	    values( '1)', 'Result: ' || rslt );
	commit;
    end;
    
    message 'Testing xp_replicate' to client;
    begin
	call xp_replicate( 5, 'abc123', rslt );
	insert into results(test_name,_result) 
	    values( '2)', 'Result: ' || rslt );
	call xp_replicate( 5000, 'abc123', rslt );
	insert into results(test_name,_result) 
	    values( '2)', 'Result: ' || 'length = ' || length( rslt ) );
	call xp_replicate( 5, repeat('-',50000), rslt );
	insert into results(test_name,_result) 
	    values( '2)', 'Result: ' || 'length = ' || length( rslt ) );
    end;
    
    message 'Testing xp_strip_punctuation_and_spaces' to client;
    begin
	declare str long varchar;
	set str='this is some text which needs to have the ' ||
		'special chars !@##$%^&()_ removed';
	set rslt = xp_strip_punctuation_and_spaces( str );
	insert into results(test_name,_result) 
	    values( '3)', 'Result: ' || 
		    '(' || length(rslt) || '/' || length(str) || ') ' || rslt );
	commit;
    end;
    
    message 'Testing xp_get_word' to client;
    begin
	declare str char(255);
	set str='one two three four five six seven eight nine ten';
	insert into results(test_name,_result) 
	    values( '4)', 'Result: ' || xp_get_word( str, 1 ) );
	insert into results(test_name,_result) 
	    values( '4)', 'Result: ' || xp_get_word( str, 3 ) );
    end;
    
    select test_name, _result from results order by pk;
end
