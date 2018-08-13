SQL Anywhere 16.0 Release Notes for Unix and Mac OS X

Copyright (c) 2013 SAP AG or an SAP affiliate company. All rights reserved.


Installing SQL Anywhere 16
--------------------------

1. Change to the created directory and start the setup script by running
   the following commands:
        cd ga1600
        ./setup

   For a complete list of the available setup options, run the following
   command:
        ./setup -h

2. Follow the instructions in the setup program.


Installation notes
------------------

o There are no items at this time.
   
   
Documentation
-------------

The documentation is available on DocCommentXchange at:
    http://dcx.sybase.com
    
DocCommentXchange is an online community for accessing and discussing 
SQL Anywhere documentation on the web. DocCommentXchange is the default 
documentation format for SQL Anywhere 16. 


SQL Anywhere Forum
------------------

The SQL Anywhere Forum is a web site where you can ask and answer questions 
about the SQL Anywhere software and comment and vote on the questions of 
others and their answers. Visit the SQL Anywhere Forum at: 
    http://sqlanywhere-forum.sybase.com. 


Setting environment variables for SQL Anywhere 16
-------------------------------------------------

Each user who uses the software must set the necessary SQL Anywhere environment
variables. These depend on your particular operating system, and are discussed
in the documentation in "SQL Anywhere Server - Database Administration > 
Database Configuration > SQL Anywhere environment variables".


Release notes for SQL Anywhere 16
---------------------------------


SQL Anywhere Server
-------------------

o There are no items at this time.

  
Administration tools
--------------------

o When installing SQL Anywhere on 64-bit Linux machines, the default option 
  is to install the 64-bit version of the graphical administration tools 
  (Sybase Central, Interactive SQL, DBConsole, ML Profiler).  
      
  You also have the option to install 32-bit administration tools. This 
  option is only for OEMs who need the 32-bit files for redistribution.  
	    
  We do not support running the 32-bit administration tools on 64-bit Linux. 
		
o To enable the Java Access Bridge for the administration tools, 
  edit the accessibility.properties file and uncomment the last two lines.

  The file appears as follows:
  #
  # Load the Java Access Bridge class into the JVM
  #
  #assistive_technologies=com.sun.java.accessibility.AccessBridge
  #screen_magnifier_present=true

o On 64-bit Linux distributions, you must install the 32-bit compatibility 
  libraries if you want to use the administration tools. In particular, the
  32-bit X11 libraries are required. On Ubuntu, run:
	sudo apt-get install ia32-libs

  On RedHat, run:
	yum install glibc.i686
	
  If you do not install these libraries, the operating system cannot
  load the administration tools' binaries. When the load fails,
  you see an error like:
  
  -bash: /opt/sqlanywhere16/bin32/dbisql: No such file or directory
  

o In some Asian locales, the graphical administration tools may not always 
  display Asian characters properly by default.

  The display problems are primarily the result of missing font configuration 
  files (files with the prefix fontconfig in the JRE's lib directory). In some
  cases, you can obtain font configuration files for the operating system and
  language combination from the operating system vendor. Read the section
  below that corresponds most closely with your operating system. If none of
  the sections apply, try the steps in the section OTHER.


  Red Flag 5 (Chinese)

  Make sure you have installed the following RPM for the Simplified Chinese
  locale:
           ttfonts-zh_CN-5.0-2

  If not, then the RPMs are available on CD #2 of the RedFlag 5 distribution.

  The RPM can be installed with the "rpm -i" command when you are logged in 
  as root.

  Run the following commands so that the JRE finds the font configuration
  file for your system:

  1. cd $SQLANY16/bin32/jre170/lib

  2. cp fontconfig.RedHat.3.properties.src fontconfig.Linux.properties
  
  Alternatively, you can copy the zysong.ttf file into the JRE's fonts 
  directory.
  
  Run the following commands so that the JRE finds the fonts:

  1. cd /usr/share/fonts/zh_CN/TrueType

  2. mkdir $SQLANY16/bin32/jre170/lib/fonts/fallback

  3. cp zysong.ttf $SQLANY16/bin32/jre170/lib/fonts/fallback


  
  Red Flag Linux Desktop 6

  1. Shut down any graphical administration tools (Sybase Central, Interactive
     SQL (dbisql), the MobiLink Profiler, SQL Anywhere Monitor, or SQL Anywhere 
     Console utility (dbconsole)) that are running.

  2. Run the following commands so that the JRE finds the fonts:

     mkdir $SQLANY16/bin32/jre170/lib/fonts/fallback
     ln -s /usr/share/fonts/zh_CN/TrueType/*.ttf $SQLANY16/bin32/jre170/lib/fonts/fallback



  RedHat Enterprise Linux 4

  Make sure you have installed fonts for the Asian locales. If not, then the 
  RPMs are available on CD #4 of the Redhat Enterprise Linux 4 distribution.

  The following RPMs contain the fonts for Asian locales:

           ttfonts-ja-1.2-36.noarch.rpm
           ttfonts-ko-1.0.11-32.2.noarch.rpm
           ttfonts-zh_CN-2.14-6.noarch.rpm
           ttfonts-zh_TW-2.11-28.noarch.rpm

  Each of these RPMs can be installed with the "rpm -i" command when you are
  logged in as root.

  Run the following commands so that the JRE finds the font
  configuration file for your system:

  1. cd $SQLANY16/bin32/jre170/lib

  2. cp fontconfig.RedHat.3.properties.src fontconfig.RedHat.4.properties



  RedHat Enterprise Linux 5
  
  1. Shut down any graphical administration tools (Sybase Central, Interactive
     SQL (dbisql), the MobiLink Profiler, SQL Anywhere Monitor, or SQL Anywhere 
     Console utility (dbconsole)) that are running.

  2. Ensure that the fonts required to display the Asian language are 
     installed. At the time of writing, a guide to installing fonts 
     was available from the Red Hat web site:

     www.redhat.com/docs/manuals/enterprise/RHEL-5-manual/en-US/Internationalization_Guide.pdf

  3. The administration tools should then be able to display the Asian
     fonts without futher action.



  RedHat Enterprise Linux 6
  
  1. Shut down any graphical administration tools (Sybase Central, Interactive
     SQL (dbisql), the MobiLink Profiler, SQL Anywhere Monitor, or SQL Anywhere 
     Console utility (dbconsole)) that are running.

  2. Ensure that the language support and fonts required to display the Asian
     language are installed.

  3. Run the following commands so that the JRE finds the fonts: 
  
       ln -s /usr/share/fonts/cjkuni-ukai/ukai.ttc $SQLANY16/bin32/jre170/lib/fonts/fallback/ukai.ttc



  SUSE 10

  Make sure you have installed fonts for the Asian locales. If not, then the 
  RPMs are available on the SuSE 10 distribution CDs.

	  sazanami-fonts-20040629-7.noarch.rpm		    (CD #1)
	  unfonts-1.0.20040813-6.noarch.rpm		    (CD #2)
	  ttf-founder-simplified-0.20040419-6.noarch.rpm    (CD #1)
	  ttf-founder-traditional-0.20040419-6.noarch.rpm   (CD #1)

  If these fonts do not contain the characters you want to display, try the
  steps in the section OTHER.

  Each of these RPMs can be installed with the "rpm -i" command when you are
  logged in as root.

  Run the following commands so that the JRE finds the fonts:

  1. ln -s /usr/X11R6/lib/X11/fonts/truetype $SQLANY16/bin32/jre170/lib/fonts/fallback

  Note: Setting the language at the Login prompt is not sufficient for the
  JRE (and hence the administration tools) to determine the locale. Before
  launching the administration tools, the environment variable LANG should be
  set to one of the following values:

           ja_JP
           ko_KR
           zh_CN
           zh_TW

  For example, in the Bourne shell and its derivatives, run the following
  command before launching the administration tools:

        export LANG=ja_JP

  Some German characters (for example, "a" with an umlaut) do not appear
  correctly in window title bars if the locale is set to de_DE.UTF-8.
  A workaround for this problem is to use the de_DE@euro locale.

  For a complete list of valid locale settings for this environment variable,
  see the directory listing of /usr/lib/locale.
  
  
  
  SUSE 11 Linux Enterprise Server
 
  1. Shut down any graphical administration tools (Sybase Central, Interactive
     SQL (dbisql), the MobiLink Profiler, SQL Anywhere Monitor, or SQL Anywhere 
     Console utility (dbconsole)) that are running.
     
  2. Run Control Center, and then click Language, and then select Japanese 
     (for example) in the list of languages. Click OK.
  
  3. Run the following commands:
     
     mkdir $SQLANY16/bin32/jre170/lib/fonts/fallback
     ln -s /usr/share/fonts/truetype/*.ttf $SQLANY16/bin32/jre170/lib/fonts/fallback

     

  UBUNTU 8.10
  
  1. Shut down any graphical administration tools (Sybase Central, Interactive
     SQL (dbisql), the MobiLink Profiler, SQL Anywhere Monitor, or SQL Anywhere 
     Console utility (dbconsole)) that are running.
  
  2. Run the following commands:
 
     mkdir $SQLANY16/bin32/jre170/lib/fonts/fallback
     ln -s /usr/share/fonts/truetype/kochi/*.ttf $SQLANY16/bin32/jre170/lib/fonts/fallback
  

  
  UBUNTU 9.10
  
  1. Shut down any graphical administration tools (Sybase Central, Interactive
     SQL (dbisql), the MobiLink Profiler, SQL Anywhere Monitor, or SQL Anywhere 
     Console utility (dbconsole)) that are running.
  
  2. Run the following commands:
 
     mkdir $SQLANY16/bin32/jre170/lib/fonts/fallback
     ln -s /usr/share/fonts/truetype/vlgothic/*.ttf $SQLANY16/bin32/jre170/lib/fonts/fallback

 
  
  UBUNTU 10.04 and 11.04
  
  1. Shut down any graphical administration tools (Sybase Central, Interactive
     SQL (dbisql), the MobiLink Profiler, SQL Anywhere Monitor, or SQL Anywhere 
     Console utility (dbconsole)) that are running.
  
  2. Run the following command:
	
	mkdir $SQLANY16/bin32/jre170/lib/fonts/fallback
	    
  3. Run one or more of the following commands to enable fonts for the indicated language:

     JAPANESE:
	ln -s /usr/share/fonts/truetype/takao/*.ttf $SQLANY16/bin32/jre170/lib/fonts/fallback


     SIMPLIFIED CHINESE:
	ln -s /usr/share/fonts/truetype/arphic/*.ttc $SQLANY16/bin32/jre170/lib/fonts/fallback
	ln -s /usr/share/fonts/truetype/wqy/*.ttc $SQLANY16/bin32/jre170/lib/fonts/fallback
 

  OTHER

  If you have a distribution of the same type, but different version number
  than those listed in the above sections, then it is recommended that you try the 
  steps from the closest corresponding section, adapting them as necessary to 
  the different version number. You should also do an Internet search for a
  specific solution for your distribution. If none of these steps produces a
  satisfactory resolution, then the following general solution can be used.

  The following is a procedure for installing a Unicode, TrueType font into
  the JRE used by the administration tools. This method can be used for any
  Linux operating system not mentioned above. Other TrueType fonts can be
  installed in a similar manner.

  1. Shut down any administration tools that are running.

  2. Download a freely available Unicode font, such as Bitstream Cyberbit,
     which is available from:

     ftp://ftp.netscape.com/pub/communicator/extras/fonts/windows/Cyberbit.ZIP

  3. Unzip Cyberbit.ZIP into a temporary directory.

  4. Create the directory $SQLANY16/bin32/jre170/lib/fonts/fallback.

  5. Copy Cyberbit.ttf into the $SQLANY16/bin32/jre170/lib/fonts/fallback 
     directory.
     

MobiLink
--------

o The MobiLink server requires an ODBC driver to communicate with
  consolidated databases. The recommended ODBC drivers for supported 
  consolidated databases can be found from the Sybase home page through the 
  following link:
    http://www.sybase.com/detail?id=1011880
    
o For information about the platforms supported by MobiLink, see:
    http://www.sybase.com/detail?id=1002288
  

QAnywhere
---------

o There are no items at this time.

 
UltraLite
---------

o There are no items at this time.


Operating system support
------------------------

o RedHat Enterprise Linux 6 Direct I/O and THP support - Red Hat Linux 6 has a
  possible bug in the transparent huge pages (THP) feature introduced in this
  operating system version, when used with Direct I/O. The most likely 
  manifestation of this bug in SQL Anywhere is assertion 200505 (checksum 
  failure on page X). Red Hat bug 891857 has been created to track this issue.

  To work around this issue, SQL Anywhere avoids using Direct I/O on this 
  operating system. If you wish to use Direct I/O you must disable THP with
  the following command:
       echo never > /sys/kernel/mm/redhat_transparent_hugepage/enabled

o 64-bit Linux support - some 64-bit Linux operating systems do not include
  pre-installed 32-bit compatability libraries. To use 32-bit software,
  you may need to install 32-bit compatability libraries for your Linux
  distribution. For example, on Ubuntu, you may need to run the following 
  command:
	sudo apt-get install ia32-libs
	
  On RedHat, run:
	yum install glibc.i686
	yum install libpk-gtk-module.so 
	yum install libcanberra-gtk2.i686 
	yum install gtk2-engines.i686

o Linux support for dbsvc - The dbsvc utility requires the LSB init-functions.
  Some Linux operating systems do not preinstall these functions by default.
  To use dbsvc, you need to install them for your Linux distribution. 
  For example, on Fedora, run the following command:
	yum install redhat-lsb redhat-lsb.i686 
	
o SELinux support - If you are having problems running SQL Anywhere on SELinux,
  you have several options:

  o Re-label the shared libraries so that they can be loaded. This solution 
    works on Red Hat Enterprise Linux 5, but has the drawback of not using the
    SELinux features.
	find $SQLANY16 -name "*.so" | xargs chcon -t textrel_shlib_t 2>/dev/null

  o Install the policy provided with SQL Anywhere 16. In the the selinux 
    directory of your installation there are policy sources. See the README 
    file in that directory for instructions on building and installing that 
    policy.

  o Write your own policy. You may want to use the policy provided with 
    SQL Anywhere 16 as a starting point.

  o Disable SELinux:
        /usr/sbin/setenforce 0
	
o Threads and semaphores - The type of threads and semaphores used in
  software can be quite important, as some systems can run out of these
  resources.

    o On Linux, AIX, HP-UX, and Mac OS X, SQL Anywhere uses
      pthreads (POSIX threads) and System V semaphores.
      
      Note: On platforms where System V semaphores are used, if the database
      server or a client application is terminated with SIGKILL, then System V 
      semaphores are leaked. You must manually clean them up by using the 
      ipcrm command.  In addition, client applications that terminate using
      the _exit() system call also leak System V semaphores unless the
      SQL Anywhere client libraries (such as ODBC and DBLib) are unloaded 
      before this call.

o Alarm handling - This feature is of interest only if you are developing
  non-threaded applications and use SIGALRM or SIGIO handlers.

  SQL Anywhere uses a SIGALRM and a SIGIO handler in non-threaded
  clients and starts up a repeating alarm (every 200ms). For correct behavior,
  SQL Anywhere must be allowed to handle these signals.

  If you define a SIGALRM or SIGIO handler before loading any SQL Anywhere
  libraries, then SQL Anywhere chains to these handlers.
  If you define a handler after loading any SQL Anywhere libraries,
  you need to chain from the SQL Anywhere handlers.

  If you use the TCP/IP communications protocol, SQL Anywhere uses
  SIGIO handlers in only non-threaded clients. This handler is always
  installed, but it is used only if your application makes use of TCP/IP.

o On Red Hat Enterprise Linux, some Private Use characters may not display
  in Sybase Central, Interactive SQL (dbisql), the MobiLink Profiler, the SQL
  Anywhere Monitor, or the SQL Anywhere Console Utility (dbconsole).
  
  For the Unicode codepoints "U+E844" and "U+E863" (designated as private use
  characters) no glyphs are provided in any of the TrueType fonts provided
  with the Red Hat Linux distribution. The characters in question are
  Simplified Chinese characters and are available in the Red Flag (Chinese
  Linux) distribution as part of their zysong.ttf (DongWen-Song) font.
		    

