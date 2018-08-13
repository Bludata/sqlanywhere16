/*-----------------------------------------------------------------------------+
 * Copyright 2013 SAP AG or an SAP affiliate company.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *                                                                                
 * http://www.apache.org/licenses/LICENSE-2.0
 * 
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * 
 * See the License for the specific language governing permissions and
 * limitations under the License.
 * 
 * While not a requirement of the license, if you do modify this file, we
 * would appreciate hearing about it. Please email sqlany_interfaces@sybase.com
 *-----------------------------------------------------------------------------+
 */

#ifndef PHP_SQLANYWHERE_H
#define PHP_SQLANYWHERE_H

#if HAVE_SQLANYWHERE 
#include "php_sqlany_ver.h"
#include "sacapi.h"

extern zend_module_entry sqlanywhere_module_entry;
#define phpext_sqlanywhere_ptr &sqlanywhere_module_entry

#ifdef PHP_WIN32
#define PHP_SQLANYWHERE_API __declspec(dllexport)
typedef __int64 	   sasql_int64;
typedef unsigned __int64   sasql_uint64;
#define SA_FMT64	"I64"
#if (PHP_MAJOR_VERSION < 5) ||  \
    (PHP_MAJOR_VERSION == 5 && PHP_MINOR_VERSION < 2 ) || \
    (PHP_MAJOR_VERSION == 5 && PHP_MINOR_VERSION == 2 && PHP_RELEASE_VERSION <= 3 )
    #undef  SA_FMT64
    #define SA_FMT64 "ll"
#endif
#else
#define PHP_SQLANYWHERE_API
typedef long long 	   sasql_int64;
typedef unsigned long long sasql_uint64;
#define SA_FMT64	"ll"
#endif

#ifdef ZTS
#include "TSRM.h"
#endif

ZEND_BEGIN_MODULE_GLOBALS(sqlanywhere)
        void * context;
	long num_conns,num_pconns;
	long max_conns,max_pconns;
	long allow_persistent;
	char * server_message;
	long auto_commit;
	long verbose_errors;
	int  debug_trace;
	char error[SACAPI_ERROR_SIZE];
	int  error_code;
	char sqlstate[6];
	long sqlany_init_called;
ZEND_END_MODULE_GLOBALS(sqlanywhere)

#ifdef ZTS
#define SAG(v) TSRMG(sqlanywhere_globals_id, zend_sqlanywhere_globals *, v)
#else
#define SAG(v) (sqlanywhere_globals.v)
#endif

ZEND_EXTERN_MODULE_GLOBALS(sqlanywhere)

#else /* not HAVE_SQLANYWHERE */

#define phpext_sqlanywhere_ptr NULL

#endif /* HAVE_SQLANYWHERE */

#endif	/* PHP_SQLANYWHERE_H */

/*
 * Local variables:
 * tab-width: 4
 * c-basic-offset: 4
 * End:
 */


