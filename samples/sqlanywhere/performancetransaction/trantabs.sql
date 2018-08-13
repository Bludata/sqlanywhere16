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

drop table if exists TT_Sync
go

drop table if exists TT_RunDesc
go

drop table if exists TT_Result
go

// This table is used to synchronize startup when running several client
// machines.
create table TT_Sync(
    thread_group    smallint	primary key,
    status	    char(10)	not null
)
go

create table TT_RunDesc(
    run_nbr	    smallint	primary key default autoincrement,
    thread_count    smallint	not null,
    run_duration    smallint	not null,
    start_time	    timestamp	default current timestamp,
    parms	    long varchar
)
go

create table TT_Result(
    run_nbr	    smallint	not null,
    thread_group    smallint	not null,
    thread_num	    smallint	not null,
    trans	    int		not null,
    avg_response    int		not null,
    max_response    int		not null,
    avg_waiting	    int		not null,
    percent_under   int		not null,
    primary key (run_nbr, thread_group, thread_num)
)
go

alter table TT_Result
    add foreign key RunDesc (run_nbr) references TT_RunDesc (run_nbr)
go


