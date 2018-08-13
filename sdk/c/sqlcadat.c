// ***************************************************************************
// Copyright (c) 2013 SAP AG or an SAP affiliate company. All rights reserved.
// ***************************************************************************

#include "sqlca.h"

/******************************/
/* declare & initialize SQLCA */
/******************************/
SQLCA sqlca = {
    "SQLCA  ",                      /* sqlcaid  */
    sizeof( SQLCA ),                /* sqlabc   */
    0L,                             /* sqlcode */
    0,                              /* sqlerrml */
    "",                             /* sqlerrmc */
    { '\0', '\0', '\0', '\0', '\0', '\0', '\0', '\0' },    /* sqlerrp  */
    {0L, 0L, 0L, 0L, 0L, 0L},       /* sqlerrd */
    {0},                            /* sqlwarn  */
    {0,0,0,0,0,0}                   /* sqlstate   */
};

SQLCA *sqlcaptr = { &sqlca };
