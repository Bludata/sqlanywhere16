# ***************************************************************************
# Copyright (c) 2013 SAP AG or an SAP affiliate company. All rights reserved.
# ***************************************************************************
# This sample code is provided AS IS, without warranty or liability of any kind.
# 
# You may use, reproduce, modify and distribute this sample code without limitation, 
# on the condition that you retain the foregoing copyright notice and disclaimer 
# as to the original code.  
# 
# *******************************************************************

if [ "${OBJDIR:-}" = "" ]; then
    OBJDIR=.
fi

rm -f $OBJDIR/odbc
rm -f $OBJDIR/odbc.o
rm -f $OBJDIR/cur
rm -f $OBJDIR/cur.o
rm -f $OBJDIR/dcur
rm -f $OBJDIR/dcur.o
rm -f $OBJDIR/mainch.o

