#!/bin/sh
#

# the following lines set the SA location.
SQLANY16="/opt/sqlanywhere16"
export SQLANY16

[ -r "$HOME/.sqlanywhere16/sample_env32.sh" ] && . "$HOME/.sqlanywhere16/sample_env32.sh" 
[ -z "${SQLANYSAMP16:-}" ] && SQLANYSAMP16="/opt/sqlanywhere16/samples"
export SQLANYSAMP16

# the following lines add SA binaries to your path.
PATH="$SQLANY16/bin32:$SQLANY16/bin64:${PATH:-}"
export PATH
LD_LIBRARY_PATH="$SQLANY16/lib64:${LD_LIBRARY_PATH:-}"
LD_LIBRARY_PATH="$SQLANY16/lib32:${LD_LIBRARY_PATH:-}"
export LD_LIBRARY_PATH
