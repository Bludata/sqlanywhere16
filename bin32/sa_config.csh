#!/bin/csh
#

# the following lines set the SA location.
setenv SQLANY16 "/opt/sqlanywhere16"

[ -r "$HOME/.sqlanywhere16/sample_env32.csh" ] && source "$HOME/.sqlanywhere16/sample_env32.csh" 
if ( ! $?SQLANYSAMP16 ) then
    setenv SQLANYSAMP16 "/opt/sqlanywhere16/samples"
endif

# the following lines add SA binaries to your path.
if ( $?PATH ) then
    setenv PATH "$SQLANY16/bin32:$SQLANY16/bin64:$PATH"
else
    setenv PATH "$SQLANY16/bin32:$SQLANY16/bin64"
endif
if ( $?LD_LIBRARY_PATH ) then
    setenv LD_LIBRARY_PATH "$SQLANY16/lib64:$LD_LIBRARY_PATH"
else
    setenv LD_LIBRARY_PATH "$SQLANY16/lib64"
endif
if ( $?LD_LIBRARY_PATH ) then
    setenv LD_LIBRARY_PATH "$SQLANY16/lib32:$LD_LIBRARY_PATH"
else
    setenv LD_LIBRARY_PATH "$SQLANY16/lib32"
endif
