SQL Anywhere 16.0 发行说明（用于 Unix 和 Mac OS X）

Copyright (c) 2013 SAP AG or an SAP affiliate company. All rights reserved.


安装 SQL Anywhere 16
--------------------

1. 切换至已创建的目录，并通过运行
以下命令启动安装程序脚本：
cd ga1600
        ./setup

   有关可用安装选项的完整列表，
请运行以下命令：
./setup -h

2. 按照安装程序中的说明操作。


安装说明
------------------

o 现在没有内容。


文档
-------------

文档可在 DocCommentXchange 上获取，网址为：
http://dcx.sybase.com

DocCommentXchange 是在 Web 上访问和讨论
SQL Anywhere 文档的在线社区。DocCommentXchange 是
SQL Anywhere 16 的缺省文档格式。


SQL Anywhere 论坛
-----------------

SQL Anywhere 论坛是一个 Web 站点，您可以
在其中提出及回答关于 SQL Anywhere 软件的问题，
并对他人的问题及回答进行评论和投票。可以通过以下网址访问 SQL Anywhere 论坛：
http://sqlanywhere-forum.sybase.com。


设置 SQL Anywhere 16 的环境变量
-------------------------------

每个使用该软件的用户都必须设置必要的 SQL Anywhere
环境变量。这些变量的设置取决于您使用的特定操作系统，
具体内容在文档中的“SQL Anywhere 服务器 - 数据库管理 >
数据库配置 > SQL Anywhere 环境变量”中讨论。


SQL Anywhere 16 的发行说明
--------------------------


SQL Anywhere 服务器
-------------------

o 现在没有内容。


管理工具
--------

o 在 64 位 Linux 计算机中安装 SQL Anywhere 时，缺省选项为
  安装 64 位版本的图形管理工具
  （Sybase Central、Interactive SQL、DBConsole、ML 分析器）。

  也可以选择安装 32 位管理工具。
  此选项仅适用于需要 32 位文件进行重新分发的 OEM 厂商。

  不支持在 64 位 Linux 上运行 32 位管理工具。

o 要针对管理工具启用 Java Access Bridge，
  请编辑辅助功能属性文件并取消最后两行的注释。

  文件显示形式如下：
#
  # Load the Java Access Bridge class into the JVM
  #
  #assistive_technologies=com.sun.java.accessibility.AccessBridge
  #screen_magnifier_present=true

o 在 64 位 Linux 发布版本中，要使用管理工具，
必须安装 32 位兼容库。尤其需要 32 位
X11 库。在 Ubuntu 上运行：
	sudo apt-get install ia32-libs

  在 RedHat 上运行：
	yum install glibc.i686

  如果不安装这些库，则操作系统无法
  装载管理工具的二进制内容。如果装载失败，
  将显示类似下面的错误：

  -bash:/opt/sqlanywhere16/bin32/dbisql:无此类文件或目录


o 在某些亚洲区域设置中，缺省情况下图形管理工具无法始终
正确地显示亚洲字符。

  显示问题主要是由于缺少字体配置
  文件（JRE 的 lib 目录中前缀为 fontconfig 的文件）所导致。在某些情况下，
可以从操作系统服务商处获得操作系统的字体配置文件和
语言组合。阅读下面与您的操作系统最相关的章节。
如果没有适用的章节，尝试“其它”一节中的步骤。



  Red Flag 5（中文）

  确保已为简体中文区域设置安装了
以下 RPM：
ttfonts-zh_CN-5.0-2

  如果尚未安装，则可在 RedFlag 5 发布版本的 CD #2 上找到该 RPM。

  当以根用户身份登录时，可使用 "rpm -i" 命令来
安装 RPM。

  运行以下命令，这样 JRE 便能找到您的系统的
字体配置文件：

  1. cd $SQLANY16/bin32/jre170/lib

  2. cp fontconfig.RedHat.3.properties.src fontconfig.Linux.properties

  您也可以将 zysong.ttf 文件复制到 JRE 的字体
目录中。

  运行以下命令，这样 JRE 就会找到相应字体:

  1. cd /usr/share/fonts/zh_CN/TrueType

  2. mkdir $SQLANY16/bin32/jre170/lib/fonts/fallback

  3. cp zysong.ttf $SQLANY16/bin32/jre170/lib/fonts/fallback



  Red Flag Linux Desktop 6

  1. 关闭所有正在运行的图形管理工具（Sybase Central、Interactive
     SQL (dbisql)、MobiLink 分析器、SQL Anywhere 监控器或 SQL Anywhere
     控制台应用程序 (dbconsole)）。

  2. 运行以下命令，这样 JRE 就会找到相应字体:

     mkdir $SQLANY16/bin32/jre170/lib/fonts/fallback
     ln -s /usr/share/fonts/zh_CN/TrueType/*.ttf $SQLANY16/
bin32/jre170/lib/fonts/fallback



  RedHat Enterprise Linux 4

  确保已安装了亚洲区域设置所需的字体。如果尚未安装，可在 Redhat Enterprise Linux 4 发布版本
  的 CD #4 上找到该 RPM。

  以下 RPM 包含亚洲区域设置所需的字体:

           ttfonts-ja-1.2-36.noarch.rpm
           ttfonts-ko-1.0.11-32.2.noarch.rpm
           ttfonts-zh_CN-2.14-6.noarch.rpm
           ttfonts-zh_TW-2.11-28.noarch.rpm

  当以根用户身份登录时，可使用 "rpm -i" 命令来
安装这些 RPM 中的每一个 RPM。

  运行以下命令，这样 JRE 便能找到您的系统的
字体配置文件：

  1. cd $SQLANY16/bin32/jre170/lib

  2. cp fontconfig.RedHat.3.properties.src fontconfig.RedHat.4.properties



  RedHat Enterprise Linux 5

  1. 关闭所有正在运行的图形管理工具（Sybase Central、Interactive
     SQL (dbisql)、MobiLink 分析器、SQL Anywhere 监控器或 SQL Anywhere
     控制台应用程序 (dbconsole)）。

  2. 确保已安装显示亚洲语言所需的
字体。目前，可访问以下 Red Hat 网址获得
安装字体的指导：

     www.redhat.com/docs/manuals/enterprise/RHEL-5-manual/en-US/Internationalization_Guide.pdf

  3. 然后管理工具便应能够显示亚洲字体而无需进一步操作。




  RedHat Enterprise Linux 6

  1. 关闭所有正在运行的图形管理工具（Sybase Central、Interactive
     SQL (dbisql)、MobiLink 分析器、SQL Anywhere 监控器或 SQL Anywhere
     控制台应用程序 (dbconsole)）。

  2. 确保已安装显示亚洲语言所需的语言支持和字体。


  3. 运行以下命令，这样 JRE 就会找到相应字体:

       ln -s /usr/share/fonts/cjkuni-ukai/ukai.ttc $SQLANY16/bin32/jre170/lib/fonts/fallback/ukai.ttc



  SUSE 10

  确保已安装了亚洲区域设置所需的字体。如果尚未安装，
  可在 SuSE 10 发布版本的 CD 上找到 RPM。

	  sazanami-fonts-20040629-7.noarch.rpm		    (CD #1)
	  unfonts-1.0.20040813-6.noarch.rpm		    (CD #2)
	  ttf-founder-simplified-0.20040419-6.noarch.rpm    (CD #1)
	  ttf-founder-traditional-0.20040419-6.noarch.rpm   (CD #1)

  如果这些字体不包含您要显示的字符，请尝试
“其它”一节中的步骤。

  当以根用户身份登录时，可使用 "rpm -i" 命令来
安装这些 RPM 中的每一个 RPM。

  运行以下命令，这样 JRE 就会找到相应字体:

  1. ln -s /usr/X11R6/lib/X11/fonts/truetype $SQLANY16/bin32/jre170/lib/fonts/fallback

  注意:在登录提示时设置语言并不足以使
JRE（以及管理工具）确定区域设置。启动管理工具之前，
应将环境变量 LANG 设置为以下值之一：


           ja_JP
           ko_KR
           zh_CN
           zh_TW

  例如，在 Bourne shell 及其衍生 shell 下，在启动管理工具之前运行以下命令：


        export LANG=ja_JP

  如果将区域设置设为 de_DE.UTF-8，则窗口标题栏中不显示某些德语
字符（例如，带变音符号的 "a"）。
解决此问题的方法是使用 de_DE@euro 区域设置。

  有关此环境变量的有效区域设置的完整列表，
请参见 /usr/lib/locale 目录清单。



  SUSE 11 Linux Enterprise Server

  1. 关闭所有正在运行的图形管理工具（Sybase Central、Interactive
     SQL (dbisql)、MobiLink 分析器、SQL Anywhere 监控器或 SQL Anywhere
     控制台应用程序 (dbconsole)）。

  2. 运行“控制中心”，单击“语言”，在语言列表中
选择“日语”（示例）。单击“确定”。

  3. 运行以下命令:

     mkdir $SQLANY16/bin32/jre170/lib/fonts/fallback
     ln -s /usr/share/fonts/truetype/*.ttf $SQLANY16/bin32/
jre170/lib/fonts/fallback



  UBUNTU 8.10

  1. 关闭所有正在运行的图形管理工具（Sybase Central、Interactive
     SQL (dbisql)、MobiLink 分析器、SQL Anywhere 监控器或 SQL Anywhere
     控制台应用程序 (dbconsole)）。

  2. 运行以下命令:

     mkdir $SQLANY16/bin32/jre170/lib/fonts/fallback
     ln -s /usr/share/fonts/truetype/kochi/*.ttf $SQLANY16/
bin32/jre170/lib/fonts/fallback



  UBUNTU 9.10

  1. 关闭所有正在运行的图形管理工具（Sybase Central、Interactive
     SQL (dbisql)、MobiLink 分析器、SQL Anywhere 监控器或 SQL Anywhere
     控制台应用程序 (dbconsole)）。

  2. 运行以下命令:

     mkdir $SQLANY16/bin32/jre170/lib/fonts/fallback
     ln -s /usr/share/fonts/truetype/vlgothic/*.ttf $SQLANY16/
bin32/jre170/lib/fonts/fallback



  UBUNTU 10.04 和 11.04

  1. 关闭所有正在运行的图形管理工具（Sybase Central、Interactive
     SQL (dbisql)、MobiLink 分析器、SQL Anywhere 监控器或 SQL Anywhere
     控制台应用程序 (dbconsole)）。

  2. 运行以下命令：

	mkdir $SQLANY16/bin32/jre170/lib/fonts/fallback

  3. 运行以下命令中的一条或多条以启用指定语言的字体：

     JAPANESE:
	ln -s /usr/share/fonts/truetype/takao/*.ttf $SQLANY16/
bin32/jre170/lib/fonts/fallback


     SIMPLIFIED CHINESE:
	ln -s /usr/share/fonts/truetype/arphic/
*.ttc $SQLANY16/bin32/jre170/lib/fonts/fallback
	ln -s /usr/share/fonts/truetype/wqy/
*.ttc $SQLANY16/bin32/jre170/lib/fonts/fallback


  其它

  如果您的发布版本类型相同，但版本号与以上章节中列出
  的版本号不同，建议您尝试执行最相关部分中的步骤，
  并根据需要修改为不同的版本号。
您还应在 Internet 中搜索，查找适合您的
发布版本的具体解决方案。如果执行完这些步骤后仍然未能得到
满意的解决方案，则可使用下面的一般解决方案。

  执行下面的过程可将 Unicode、TrueType 字体安装到
管理工具所使用的 JRE 中。该方法可用于上面未提及的任何
Linux 操作系统。其它 TrueType 字体可通过
类似方式安装。

  1. 关闭所有正在运行的管理工具。

  2. 下载可免费获取的 Unicode 字体，如 Bitstream Cyberbit，
     可从以下网址获得：

     ftp://ftp.netscape.com/pub/communicator/extras/fonts/windows/Cyberbit.ZIP

  3. 将 Cyberbit.ZIP 解压缩到临时目录。

  4. 创建目录 $SQLANY16/bin32/jre170/lib/fonts/fallback。

  5. 将 Cyberbit.ttf 复制到 $SQLANY16/bin32/jre170/lib/fonts/fallback
     目录中。


MobiLink
--------

o MobiLink 服务器需要 ODBC 驱动程序才能与
  统一数据库通信。可通过以下链接从 Sybase 主页
  找到推荐用于所支持的统一数据库的
  ODBC 驱动程序：
http://www.sybase.com/detail?id=1011880

o 有关 MobiLink 支持的平台的信息，请参见：
http://www.sybase.com/detail?id=1002288


QAnywhere
---------

o 现在没有内容。


UltraLite
---------

o 现在没有内容。


操作系统支持
------------------------

o RedHat Enterprise Linux 6 Direct I/O 和 THP 支持 - 当和 Direct I/O 一起
  使用时，Red Hat Linux 6 在该操作系统版本所引入的大内存页 (THP) 功能中
  可能存在错误。该错误在 SQL Anywhere 中最有可能的表现形式为
  声明 200505（页面 X 上的校验和失败）。
已创建 Red Hat 错误 891857 跟踪该问题。

  为了解决该问题，SQL Anywhere 不在
  该操作系统上使用 Direct I/O。如果希望使用 Direct I/O，
  则必须使用以下命令禁用 THP：
echo never > /sys/kernel/mm/redhat_transparent_hugepage/enabled

o 64 位 Linux 支持 – 某些 64 位 Linux
  操作系统不包含预安装的 32 位兼容库。要使用 32 位软件，
需要为您的 Linux 发布版本安装 32 位兼容库。
例如，在 Ubuntu 上，可能需要运行以下
命令：
	sudo apt-get install ia32-libs

  在 RedHat 上运行：
	yum install glibc.i686
	yum install libpk-gtk-module.so
	yum install libcanberra-gtk2.i686
	yum install gtk2-engines.i686

o Linux 对 dbsvc 的支持 - dbsvc 实用程序需要使用 LSB 初始化函数。
某些 Linux 操作系统在缺省情况下不预安装这些函数。
要使用 dbsvc，需要为 Linux 发布版本安装这些函数。
例如，在 Fedora 上运行以下命令：
	yum install redhat-lsb redhat-lsb.i686

o SELinux 支持 – 如果在 SELinux 上运行 SQL Anywhere 时出现问题，
您有以下几种选择：

  o 重新标记共享库，以便可以装载。该解决方案
    在 Red Hat Enterprise Linux 5 上有效，但缺点是不使用
    SELinux 功能。
	find $SQLANY16 -name "*.so" | xargs chcon -t textrel_shlib_t 2>/dev/null

  o 安装随 SQL Anywhere 16 提供的策略。在安装的 selinux 目录
中有策略源。请参见此目录中
的 README 文件来了解构建和安装此策略的说明。


  o 编写您自己的策略。您可能希望以随 SQL Anywhere 16 提供的策略为基础进行编写。


  o 禁用 SELinux：
/usr/sbin/setenforce 0

o 线程和信号 – 软件中使用的线程和信号的类型
非常重要，因为某些系统可能耗尽这些资源。


    o 在 Linux、AIX、HP-UX 和 Mac OS X 中，SQL Anywhere 使用
pthreads（POSIX 线程）和系统 V 信号。

      注意:在使用系统 V 信号的平台上，
      如果使用 SIGKILL 终止数据库服务器或客户端应用程序，
      则系统 V 信号会发生泄漏。必须使用 ipcrm 命令
      手动进行清理。此外，使用 _exit() 系统调用终止的
      客户端应用程序也将泄漏系统 V 信号，
      除非 SQL Anywhere 客户端库（如 ODBC 和 DBLib）
      在此调用前已卸载。

o 警报处理 – 仅当开发非线程应用程序
  并使用 SIGALRM 或 SIGIO 处理程序时，该功能才有用。

  SQL Anywhere 在非线程客户端使用 SIGALRM 和 SIGIO 处理程序并启动重复警报（每 200 毫秒一次）。
为了实施正确的行为，
必须允许 SQL Anywhere 处理这些信号。

  如果在装载任何 SQL Anywhere 库之前定义 SIGALRM 或 SIGIO 处理
程序，则 SQL Anywhere 会链接到这些处理程序。
如果在装载任何 SQL Anywhere 库之后定义处理程序，
则需要从 SQL Anywhere 处理程序进行链接。

  如果使用 TCP/IP 通信协议，则 SQL Anywhere 将只在
非线程客户端使用 SIGIO 处理程序。该处理程序始终都会安装，
但只在您的应用程序使用 TCP/IP 时才使用。

o 在 Red Hat Enterprise Linux 上，某些专用字符
  在 Sybase Central、Interactive SQL (dbisql)、MobiLink 分析器、SQL Anywhere 监控器
  或 SQL Anywhere 控制台实用程序 (dbconsole) 中可能不显示。

  对于 Unicode 代码点 "U+E844" 和 "U+E863"（指定为专用字符），
  在随 Red Hat Linux 发布版本提供的任何 TrueType 字体中，
  均不提供轮廓。上述字符是简体中文字符，在 Red Flag（中文版 Linux）发布版本
中作为 zysong.ttf (DongWen-Song) 字体的一部分提供。


