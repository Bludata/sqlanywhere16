// ***************************************************************************
// Copyright (c) 2013 SAP AG or an SAP affiliate company. All rights reserved.
// ***************************************************************************

#ifndef LANGLOAD_H
#define LANGLOAD_H

#include "consts.h"
// #include "extenv.h"

typedef void* (EXTENVCALL * create_loader_func) (void* eevm );
typedef EXTENVRET (EXTENVCALL * free_loader_func) (void* lang_loader_handle );
typedef EXTENVRET (EXTENVCALL * execute_func) (void *lang_loader_handle, const char *method );
typedef EXTENVRET (EXTENVCALL * interrupt_func) ( void* lang_loader_handle );
typedef EXTENVRET (EXTENVCALL * set_thread_func) ( void* lang_loader_handle, void* thread_handle );

struct a_language_loader {
    create_loader_func create_loader;
    free_loader_func   free_loader;
    execute_func       execute;
    interrupt_func     interrupt;
    set_thread_func    set_thread;
};

#endif
