dnl $Id$

AC_DEFUN(AC_SQLANYWHERE_EXTENV_VERSION,[
    AC_CHECK_SIZEOF(void *, 8)
    AC_MSG_CHECKING([if we're at 64-bit platform])
    if test "$ac_cv_sizeof_void_p" = "4" ; then
        AC_MSG_RESULT([no])
        CFLAGS="$CXXFLAGS -DUNIX"
        CXXFLAGS="$CFLAGS -DUNIX"
        SA_BITS=32
    else
        AC_MSG_RESULT([yes])
        CFLAGS="$CFLAGS -DUNIX64"
        CXXFLAGS="$CXXFLAGS -DUNIX64"
        SA_BITS=64
    fi

    if test -f "$SQLANY_DIR/lib$SA_BITS/libdblib12.$SHLIB_SUFFIX_NAME"; then
	SQLANY_VERSION=12
    elif test -f "$SQLANY12/lib$SA_BITS/libdblib12.$SHLIB_SUFFIX_NAME"; then
	SQLANY_VERSION=12
	SQLANY_DIR="$SQLANY12"

    else
	if test -f "$SQLANY_DIR/lib$SA_BITS/libdblib?.$SHLIB_SUFFIX_NAME" ||
           test -f "$SQLANY_DIR/lib/libdblib?.$SHLIB_SUFFIX_NAME"; then
	    AC_MSG_ERROR(Unsupported SQLAnywhere version)
 	else 
	    AC_MSG_ERROR(SQLAnywhere libdblib?.$SHLIB_SUFFIX_NAME not found)
	fi
    fi
])


PHP_ARG_WITH(sqlanywhere, for SQLAnywhere external environemnt support,
[  --with-sqlanywhere-extenv=[DIR]     
                          Include SQLAnywhere external environment support.
                          DIR is the SQLAnywhere home directory, 
                          defaults to SQLANY ])


if test "$PHP_SQLANYWHERE_EXTENV" != "no"; then

  if test "$PHP_SQLANYWHERE_EXTENV" = "yes"; then
	SQLANY_DIR="$SQLANY"
  else
	SQLANY_DIR="$PHP_SQLANYWHERE_EXTENV"
  fi
  AC_SQLANYWHERE_EXTENV_VERSION($SQLANY_DIR)

  AC_MSG_CHECKING([    SQLAnywhere install dir])
  AC_MSG_RESULT($SQLANY_DIR)
  AC_MSG_CHECKING([    SQLAnywhere version])
  AC_MSG_RESULT($SQLANY_VERSION)


  if test $SQLANY_VERSION -lt 10; then
        SA_BITS=
  fi

  if test -d "$SQLANY_DIR/sdk/include"; then
	  PHP_ADD_INCLUDE($SQLANY_DIR/sdk/include)
  else	   
	  AC_MSG_ERROR(SQLAnywhere include files missing:$SQLANY_DIR/sdk/include)
  fi

  if test ! -f "$SQLANY_DIR/bin$SA_BITS/sqlpp"; then
	  AC_MSG_ERROR(SQLAnywhere preprocessor is missing:$SQLANY_DIR/bin$SA_BITS/sqlpp)
  fi

  PHP_ADD_INCLUDE($SQLANY_DIR/sdk/include)
  PHP_ADD_LIBRARY_WITH_PATH(dblib${SQLANY_VERSION}_r, $SQLANY_DIR/lib$SA_BITS, SQLANYWHERE_EXTENV_SHARED_LIBADD)
  PHP_ADD_LIBRARY_WITH_PATH(dbtasks${SQLANY_VERSION}_r, $SQLANY_DIR/lib$SA_BITS, SQLANYWHERE_EXTENV_SHARED_LIBADD)
  PHP_ADD_LIBRARY_WITH_PATH(dbextenv${SQLANY_VERSION}_r, $SQLANY_DIR/lib$SA_BITS, SQLANYWHERE_EXTENV_SHARED_LIBADD)

  PHP_NEW_EXTENSION(sqlanywhere_extenv, sqlanywhere_extenv.c,  $ext_shared)
  PHP_SUBST(SQLANYWHERE_EXTENV_SHARED_LIBADD)

  AC_DEFINE(HAVE_SQLANYWHERE_EXTENV,1,[ ])
fi

