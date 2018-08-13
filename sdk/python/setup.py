#!/usr/bin/env python
# ***************************************************************************
# Copyright (c) 2013 SAP AG or an SAP affiliate company. All rights reserved.
# ***************************************************************************

r"""sqlanydb - pure Python SQL Anywhere database interface.

sqlanydb lets one access and manipulate SQL Anywhere databases
in pure Python.

http://code.google.com/p/sqlanydb

----------------------------------------------------------------"""

from distutils.core import setup

setup(name='sqlanydb',
      version='1.0.3',
      description='pure Python SQL Anywhere database interface',
      author='Graeme Perrow',
      author_email='graeme.perrow@sap.com',
      url='http://code.google.com/p/sqlanydb',
      py_modules=['sqlanydb'],
     )
