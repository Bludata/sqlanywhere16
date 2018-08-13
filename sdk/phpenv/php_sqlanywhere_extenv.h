// ***************************************************************************
// Copyright (c) 2013 SAP AG or an SAP affiliate company. All rights reserved.
// ***************************************************************************
/* +----------------------------------------------------------------------+
   | Authors: Mohammed Abouzour mabouzou@ianywhere.com                    |
   +----------------------------------------------------------------------+ */

#ifndef PHP_SQLANYWHERE_EXTENV_H
#define PHP_SQLANYWHERE_EXTENV_H

#if HAVE_SQLANYWHERE 

#define ASA_BUILD_NUM 

#define PHP_SQLANYWHERE_EXTENV_VERSION  "1.0.8" ASA_BUILD_NUM

extern zend_module_entry sqlanywhere_extenv_module_entry;
#define phpext_sqlanywhere_extenv_ptr &sqlanywhere_extenv_module_entry

#ifdef PHP_WIN32
#define PHP_SQLANYWHERE_EXTENV_API __declspec(dllexport)
#else
#define PHP_SQLANYWHERE_EXTENV_API
#endif

ZEND_MINIT_FUNCTION(sqlanywhere_extenv);
ZEND_MSHUTDOWN_FUNCTION(sqlanywhere_extenv);
ZEND_MINFO_FUNCTION(sqlanywhere_extenv);

#else /* not HAVE_SQLANYWHERE */

#define phpext_sqlanywhere_extenv_ptr NULL

#endif /* HAVE_SQLANYWHERE */

#endif	/* PHP_SQLANYWHERE_H */

/*
 * Local variables:
 * tab-width: 4
 * c-basic-offset: 4
 * End:
 */



