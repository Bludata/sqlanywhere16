// ***************************************************************************
// Copyright (c) 2013 SAP AG or an SAP affiliate company. All rights reserved.
// ***************************************************************************
#ifndef PHP_SQLANY_VER
#define PHP_SQLANY_VER

#define PHP_SA_MAJOR 	2
#define PHP_SA_MINOR 	0
#define PHP_SA_PATCH 	11 
#define PHP_SA_BUILD    0

#define _php_str( x ) # x
#define _eval( x ) _php_str( x )

#define PHP_SQLANY_MAJOR _eval( PHP_SA_MAJOR )
#define PHP_SQLANY_MINOR _eval( PHP_SA_MINOR )
#define PHP_SQLANY_PATCH _eval( PHP_SA_PATCH )
#define PHP_SQLANY_BUILD _eval( PHP_SA_BUILD )

#define PHP_SQLANYWHERE_VERSION  PHP_SQLANY_MAJOR "." PHP_SQLANY_MINOR "." PHP_SQLANY_PATCH "." PHP_SQLANY_BUILD

#endif
