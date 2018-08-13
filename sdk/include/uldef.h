// ***************************************************************************
// Copyright (c) 2013 SAP AG or an SAP affiliate company. All rights reserved.
// ***************************************************************************

#ifndef _ULDEF_H_INCLUDED
#define _ULDEF_H_INCLUDED

// Standard definitions
#if defined(UNDER_CE)
    #include <stdlib.h>
    #include <windef.h>
#else
    #if !defined(NO_STDDEF_H)
	// note: no wchar_t on Unix/Linux for us!
	#include <stddef.h>
    #endif
#endif

#endif
