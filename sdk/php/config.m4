dnl $Id$

PHP_ARG_WITH(sqlanywhere, for SQLAnywhere support,
[  --with-sqlanywhere        Include SQLAnywhere support. ])

if test "$PHP_SQLANYWHERE" != "no"; then

  PHP_NEW_EXTENSION(sqlanywhere, sacapidll.c sqlanywhere.c sqlany_dbg.c,  $ext_shared)

  AC_DEFINE(HAVE_SQLANYWHERE,1,[ ])

fi

