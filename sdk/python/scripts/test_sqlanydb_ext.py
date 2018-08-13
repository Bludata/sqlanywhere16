#!/usr/bin/env python
# ***************************************************************************
# Copyright (c) 2013 SAP AG or an SAP affiliate company. All rights reserved.
# ***************************************************************************
#######################################################################
# 
# This sample program contains a hard-coded userid and password
# to connect to the demo database. This is done to simplify the
# sample program. The use of hard-coded passwords is strongly
# discouraged in production code.  A best practice for production
# code would be to prompt the user for the userid and password.
#
#######################################################################
import unittest
import time, threading
import sqlanydb

class SQLAnyDBExtensions(unittest.TestCase):
    connect_args = () # List of arguments to pass to connect
    connect_kw_args = {'uid': 'dba', 'pwd': 'sql'}

    def setUp(self): 
        pass

    def tearDown(self): 
        pass

    def _connect(self):
        return sqlanydb.connect(*self.connect_args, **self.connect_kw_args)

    def test_cancel(self):
        class CancelThread(threading.Thread):
            def __init__(self):
                threading.Thread.__init__(self)
                self.s = threading.Semaphore(0)

            def run(self):
                self.s.release()
                time.sleep(1)
                conn.cancel()

            def start(self):
                threading.Thread.start(self)
                self.s.acquire()

        conn = self._connect()
        curs = conn.cursor()
        CancelThread().start()
        self.assertRaises(sqlanydb.OperationalError, curs.execute,
                          "waitfor delay '00:00:30' check every 500")
        conn.close()

if __name__ == '__main__':
    unittest.main()
    print( '''Done''')
