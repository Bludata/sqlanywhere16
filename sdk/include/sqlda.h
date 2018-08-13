// ***************************************************************************
// Copyright (c) 2013 SAP AG or an SAP affiliate company. All rights reserved.
// ***************************************************************************

#ifndef _SQLDA_H_INCLUDED
#define _SQLDA_H_INCLUDED
#define II_SQLDA

#include "sqlca.h"

#if defined( _SQL_PACK_STRUCTURES )
    #if defined( _MSC_VER ) && _MSC_VER > 800
	#pragma warning(push)
        #pragma warning(disable:4103)
    #endif
    #include "pshpk1.h"
#endif

#define SQL_MAX_NAME_LEN        30

#define _sqldafar

typedef	short int	a_sql_type;

struct sqlname {
    short int           length;                     /* length of char data */
    char		data[ SQL_MAX_NAME_LEN ];   /* data                */
};

struct sqlvar {                  /* array of variable descriptors        */
    short int           sqltype;           /* type of host variable      */
    a_sql_len           sqllen;            /* length of host variable    */
    void		*sqldata;          /* address of variable        */
    a_sql_len		*sqlind;           /* indicator variable pointer */
    struct sqlname      sqlname;
};

#if defined( _SQL_PACK_STRUCTURES )
    #include "poppk.h"
    /* The SQLDA should be 4-byte aligned */
    #include "pshpk4.h"
#endif

struct sqlda {
    unsigned char       sqldaid[8];  /* eye catcher "SQLDA"                   */
    a_sql_int32         sqldabc;     /* length of sqlda structure             */
    short int           sqln;        /* descriptor size in number of entries  */
    short int           sqld;        /* number of variables found by DESCRIBE */
    struct sqlvar       sqlvar[1];   /* array of variable descriptors         */
};

#define SCALE(sqllen)           ((sqllen)/256)
#define PRECISION(sqllen)       ((sqllen)&0xff)
#define SET_PRECISION_SCALE(sqllen,precision,scale)     \
                                sqllen = (scale)*256 + (precision)
#define DECIMALSTORAGE(sqllen)  (PRECISION(sqllen)/2 + 1)

typedef struct sqlda    SQLDA;
typedef struct sqlvar   SQLVAR, SQLDA_VARIABLE;
typedef struct sqlname  SQLNAME, SQLDA_NAME;

#ifndef SQLDASIZE
#define SQLDASIZE(n)    ( sizeof( struct sqlda ) +  \
                          (n-1) * sizeof( struct sqlvar) )
#endif

#if defined( _SQL_PACK_STRUCTURES )
    #include "poppk.h"
    #if defined( _MSC_VER ) && _MSC_VER > 800
        #pragma warning(pop)
    #endif
#endif

#endif
