SQL Anywhere 16.0 UNIX 版および Mac OS X 版リリースノート

Copyright (c) 2013 SAP AG or an SAP affiliate company. All rights reserved.


SQL Anywhere 16 のインストール
--------------------------

1. 作成されたディレクトリに移動し、次のコマンドを実行して
   設定スクリプトを開始します。
cd ga1600
        ./setup

   使用可能な設定オプションのリストを表示するには、
   次のコマンドを実行します。
./setup -h

2. セットアッププログラムの指示に従います。


インストールに関する注意事項
------------------

o 現時点では何もありません。


マニュアル
-------------

マニュアルは DocCommentXchange にあります。アドレスは次のとおりです。
http://dcx.sybase.com

DocCommentXchange は Web 上の SQL Anywhere マニュアルを参照して
議論するためのオンラインコミュニティです。DocCommentXchange は 
SQL Anywhere 16 のデフォルトのマニュアルセットです。


SQL Anywhere フォーラム
------------------

SQL Anywhere フォーラムは、SQL Anywhere ソフトウェアに関する質問や
回答を投稿できる Web サイトです。他の投稿者の質問やその回答にコメントや
評価を加えることもできます。SQL Anywhere フォーラムの URL は次のとおりです。
http://sqlanywhere-forum.sybase.com


SQL Anywhere 16 の環境変数の設定
-------------------------------------------------

ソフトウェアを使用するユーザごとに、SQL Anywhere の環境変数を設定する
必要があります。必要な環境変数はオペレーティングシステムによって異なり、
『SQL Anywhere サーバ - データベース管理』>
「データベースの設定」>「SQL Anywhere の環境変数」で説明しています。


SQL Anywhere 16 のリリースノート
---------------------------------


SQL Anywhere サーバ
-------------------

o 現時点では何もありません。


管理ツール
--------------------

o 64 ビットの Linux マシン上に SQL Anywhere をインストールする場合、デフォルトのオプションは、
  64 ビット版のグラフィカル管理ツール (Sybase Central、Interactive SQL、DB コンソール、ML プロファイラ) がインストールされます。

  32 ビットの管理ツールをインストールするというオプションもあります。
 ただし、このオプションは、32 ビットファイルの再ディストリビューションを必要とする OEM の場合に限ります。

  64 ビット Linux での 32 ビットの管理ツールの実行をサポートしていません。

o 管理ツール用の Java Access Bridge を有効にするには、
  accessibility.properties ファイルを編集して最後の 2 行をコメント解除します。

  ファイルには次のように表示されます。
  #
  # Load the Java Access Bridge class into the JVM
  #
  #assistive_technologies=com.sun.java.accessibility.AccessBridge
  #screen_magnifier_present=true

o 64 ビット Linux ディストリビューションで管理ツールを使用するには、
  32 ビット互換性ライブラリをインストールします。特に、32 ビット
  X11 ライブラリが必要です。Ubuntu では次のコマンドを実行します。
	sudo apt-get install ia32-libs

  RedHat では次のコマンドを実行します。
	yum install glibc.i686

  これらのライブラリがインストールされていない場合、
  オペレーティングシステムで管理ツールのバイナリをロードできません。ロードに失敗すると、
  次のエラーが表示されます。

  -bash:/opt/sqlanywhere16/bin32/dbisql:そのようなファイルまたはディレクトリは存在しません


o 一部のアジアのロケールでは、グラフィカル管理ツールにデフォルトで
  アジアの文字が正常に表示されない場合があります。

  表示の問題は、フォント設定ファイル (JRE の lib ディレクトリ内にある
  プレフィクスが fontconfig のファイル) が見つからないことが主な原因です。特定の
  オペレーティングシステムと言語の組み合わせのフォント設定ファイルを、
  オペレーティングシステムのベンダから入手できる場合があります。下記のうち、お使いのオペレーティング
  システムに該当する項を参照してください。該当する項目がない場合は、「その他」の
  項の手順を試してください。


  Red Flag 5 (中国語)

  簡体字中国語ロケール用の次の RPM がインストールされていることを
  確認します。
ttfonts-zh_CN-5.0-2

  インストールされていない場合、RedFlag 5 ディストリビューションの CD #2 の RPM を使用します。

  RPM をインストールするには、root でログインして "rpm -i" コマンドを
  実行します。

  次のコマンドを実行して、JRE でシステムのフォント設定ファイルが
  見つかるようにします。

  1. cd $SQLANY16/bin32/jre170/lib

  2. cp fontconfig.RedHat.3.properties.src fontconfig.Linux.properties

  または、zysong.ttf ファイルを JRE のフォントディレクトリに
  コピーします。

  次のコマンドを実行して JRE でフォントが見つかるようにします。

  1. cd /usr/share/fonts/zh_CN/TrueType

  2. mkdir $SQLANY16/bin32/jre170/lib/fonts/fallback

  3. cp zysong.ttf $SQLANY16/bin32/jre170/lib/fonts/fallback



  Red Flag Linux Desktop 6

  1. 実行中のグラフィカル管理ツール (Sybase Central、Interactive
     SQL (dbisql)、Mobile Link プロファイラ、SQL Anywhere モニタ、
     SQL Anywhere コンソールユーティリティ (dbconsole)) をすべてシャットダウンします。

  2. 次のコマンドを実行して JRE でフォントが見つかるようにします。

     mkdir $SQLANY16/bin32/jre170/lib/fonts/fallback
     ln -s /usr/share/fonts/zh_CN/TrueType/*.ttf $SQLANY16/bin32/jre170/lib/fonts/fallback



  RedHat Enterprise Linux 4

  アジアのロケール用のフォントがインストールされていることを確認します。インストール
  されていない場合、Redhat Enterprise Linux 4 ディストリビューションの CD #4 の RPM を使用します。

  次の RPM にアジアのロケールのフォントが含まれます。

           ttfonts-ja-1.2-36.noarch.rpm
ttfonts-ko-1.0.11-32.2.noarch.rpm
ttfonts-zh_CN-2.14-6.noarch.rpm
ttfonts-zh_TW-2.11-28.noarch.rpm

  これらの RPM をインストールするには、root でログインして
  "rpm -i" コマンドを実行します。

  次のコマンドを実行して、JRE でシステムの
  フォント設定ファイルが見つかるようにします。

  1. cd $SQLANY16/bin32/jre170/lib

  2. cp fontconfig.RedHat.3.properties.src fontconfig.RedHat.4.properties



  RedHat Enterprise Linux 5

  1. 実行中のグラフィカル管理ツール (Sybase Central、Interactive
     SQL (dbisql)、Mobile Link プロファイラ、SQL Anywhere モニタ、
     SQL Anywhere コンソールユーティリティ (dbconsole)) をすべてシャットダウンします。

  2. アジア言語の表示に必要なフォントがインストールされていることを
     確認します。この文書の執筆時点では、フォントのインストールガイドが
      Red Hat の Web サイトで提供されています。

     www.redhat.com/docs/manuals/enterprise/RHEL-5-manual/en-US/Internationalization_Guide.pdf

  3. フォントがインストールされている場合は、管理ツールに
     アジアのフォントが表示されます。別途操作をする必要はありません。



  RedHat Enterprise Linux 6

  1. 実行中のグラフィカル管理ツール (Sybase Central、Interactive
     SQL (dbisql)、Mobile Link プロファイラ、SQL Anywhere モニタ、
     SQL Anywhere コンソールユーティリティ (dbconsole)) をすべてシャットダウンします。

  2. アジア言語の表示に必要な言語サポートとフォントがインストールされていることを
     確認します。

  3. 次のコマンドを実行して JRE でフォントが見つかるようにします。

        ln -s /usr/share/fonts/cjkuni-ukai/ukai.ttc $SQLANY16/bin32/jre170/lib/fonts/fallback/ukai.ttc



  SUSE 10

  アジアのロケール用のフォントがインストールされていることを確認します。インストール
  されていない場合、SuSE 10 ディストリビューション CD の RPM を使用します。

	  sazanami-fonts-20040629-7.noarch.rpm		    (CD #1)
	  unfonts-1.0.20040813-6.noarch.rpm		    (CD #2)
	  ttf-founder-simplified-0.20040419-6.noarch.rpm    (CD #1)
	  ttf-founder-traditional-0.20040419-6.noarch.rpm   (CD #1)

  表示する文字がこれらのフォントに含まれていない場合は、
  「その他」の項の手順を試してください。

  これらの RPM をインストールするには、root でログインして
  "rpm -i" コマンドを実行します。

  次のコマンドを実行して JRE でフォントが見つかるようにします。

  1. ln -s /usr/X11R6/lib/X11/fonts/truetype $SQLANY16/bin32/jre170/lib/fonts/fallback

  注意 : JRE (および管理ツール) でロケールを決定するには、
  ログインプロンプトで言語を設定するだけでは不十分です。管理
  ツールを起動する前に、環境変数 LANG を次のいずれかの値に
  設定してください。

           ja_JP
ko_KR
zh_CN
zh_TW

  たとえば、Bourne シェルとその派生シェルでは、次のコマンドを
  実行してから管理ツールを起動します。

        export LANG=ja_JP

  一部のドイツ語の文字 (ウムラウト記号付きの "a" など) は、
  ロケールを de_DE.UTF-8 に設定しても、ウィンドウのタイトルバーに正常に表示されません。
この問題を回避するには、de_DE@euro ロケールを使用します。

  この環境変数の有効なロケール設定のリストについては、
  /usr/lib/locale のディレクトリリストを参照してください。



  SUSE 11 Linux Enterprise Server

  1. 実行中のグラフィカル管理ツール (Sybase Central、Interactive
     SQL (dbisql)、Mobile Link プロファイラ、SQL Anywhere モニタ、
     SQL Anywhere コンソールユーティリティ (dbconsole)) をすべてシャットダウンします。

  2. Control Center を実行して [Language] をクリックします。
     次に、(たとえば) [Japanese] を選択して、[OK] をクリックします。

  3. 次のコマンドを実行します。

     mkdir $SQLANY16/bin32/jre170/lib/fonts/fallback
     ln -s /usr/share/fonts/truetype/*.ttf $SQLANY16/bin32/jre170/lib/fonts/fallback



  UBUNTU 8.10

  1. 実行中のグラフィカル管理ツール (Sybase Central、Interactive
     SQL (dbisql)、Mobile Link プロファイラ、SQL Anywhere モニタ、
     SQL Anywhere コンソールユーティリティ (dbconsole)) をすべてシャットダウンします。

  2. 次のコマンドを実行します。

     mkdir $SQLANY16/bin32/jre170/lib/fonts/fallback
     ln -s /usr/share/fonts/truetype/kochi/*.ttf $SQLANY16/bin32/jre170/lib/fonts/fallback



  UBUNTU 9.10

  1. 実行中のグラフィカル管理ツール (Sybase Central、Interactive
     SQL (dbisql)、Mobile Link プロファイラ、SQL Anywhere モニタ、
     SQL Anywhere コンソールユーティリティ (dbconsole)) をすべてシャットダウンします。

  2. 次のコマンドを実行します。

     mkdir $SQLANY16/bin32/jre170/lib/fonts/fallback
     ln -s /usr/share/fonts/truetype/vlgothic/*.ttf $SQLANY16/bin32/jre170/lib/fonts/fallback



  UBUNTU 10.04 および 11.04

  1. 実行中のグラフィカル管理ツール (Sybase Central、Interactive
     SQL (dbisql)、Mobile Link プロファイラ、SQL Anywhere モニタ、
     SQL Anywhere コンソールユーティリティ (dbconsole)) をすべてシャットダウンします。

  2. 次のコマンドを実行します。

	mkdir $SQLANY16/bin32/jre170/lib/fonts/fallback

  3. 次の 1 つまたは複数のコマンドを実行して、各言語のフォントを有効にします。

     日本語:
	ln -s /usr/share/fonts/truetype/takao/*.ttf $SQLANY16/bin32/jre170/lib/fonts/fallback


     簡体中国語:
	ln -s /usr/share/fonts/truetype/arphic/*.ttc $SQLANY16/bin32/jre170/lib/fonts/fallback
	ln -s /usr/share/fonts/truetype/wqy/*.ttc $SQLANY16/bin32/jre170/lib/fonts/fallback


  その他

  上記の項に示すディストリビューションとタイプが同じで
  バージョンが異なる場合は、最も関連する項の手順を、
  必要に応じてバージョン番号を置き換えて試すことを
  お勧めします。また、お使いのディストリビューションに
  固有の解決策をインターネットで検索してみてください。それでも解決できない場合は、
  次に示す一般的な解決策を実行します。

  Unicode、TrueType フォントを、管理ツールで使用される
  JRE にインストールする手順を次に示します。この手順は、上記にないすべての
  Linux オペレーティングシステムに使用できます。他の TrueType フォントも
  同様の方法でインストールできます。

  1. 管理ツールを実行している場合は終了します。

  2. 無料で提供されている Unicode フォントをダウンロードします。
     たとえば、Bitstream Cyberbit は次のサイトからダウンロードできます。

     ftp://ftp.netscape.com/pub/communicator/extras/fonts/windows/Cyberbit.ZIP

  3. Cyberbit.ZIP をテンポラリディレクトリに解凍します。

  4. $SQLANY16/bin32/jre170/lib/fonts/fallback ディレクトリを作成します。

  5. Cyberbit.ttf を $SQLANY16/bin32/jre170/lib/fonts/fallback
     ディレクトリにコピーします。


Mobile Link
--------

o Mobile Link サーバでは、統合データベースと通信するために、
  ODBC ドライバが必要です。サポートされている統合データベースの
  推奨 ODBC ドライバは、Sybase のホームページから入手できます。
  ホームページには次のリンクからアクセスできます。
    http://www.sybase.com/detail?id=1011880

o Mobile Link でサポートされているプラットフォームの詳細については、次のサイトを参照してください。
http://www.sybase.com/detail?id=1002288


QAnywhere
---------

o 現時点では何もありません。


Ultra Light
---------

o 現時点では何もありません。


オペレーティングシステムのサポート
------------------------

o RedHat Enterprise Linux 6 の Direct I/O および THP のサポート - Red Hat Linux 6 では、
  このオペレーティングシステムバージョンで導入された Transparent Huge Page (THP) 機能に
  バグがあり、Direct I/O と使用した場合に発現する可能性があります。SQL Anywhere で
  このバグを表すものとして最も可能性が高いのは、アサーション 200505 (X ページの障害の
  チェックサム) です。Red Hat bug 891857 は、この問題を追跡するために作成されました。

  この問題を回避するため、SQL Anywhere では、このオペレーティングシステムで
  Direct I/O を使用しないようにしています。Direct I/O を使用する場合は、次のコマンドで THP を
  無効にしてください。       echo never > /sys/kernel/mm/redhat_transparent_hugepage/enabled

o 64 ビット Linux のサポート - 一部の 64 ビット Linux オペレーティングシステム
  には、32 ビット互換性ライブラリがプリインストールされていません。32 ビットの
  ソフトウェアを使用するには、お使いの Linux ディストリビューション用の 32 ビット
  互換性ライブラリをインストールする必要があります。たとえば、Ubuntu では次のコマンド
  を実行します。
	sudo apt-get install ia32-libs

  RedHat では次のコマンドを実行します。
	yum install glibc.i686
	yum install libpk-gtk-module.so
	yum install libcanberra-gtk2.i686
	yum install gtk2-engines.i686

o dbsvc に対する Linux のサポート - dbsvc ユーティリティを使用するには、LSB init ファンクションが必要です。
一部の Linux オペレーティングシステムには、これらのファンクションがデフォルトでプレインストールされていません。
dbsvc を使用するには、Linux ディストリビューション用にこれらをインストールする必要があります。
たとえば、Fedora では次のコマンドを実行します。
	yum install redhat-lsb redhat-lsb.i686

o SELinux のサポート - SELinux で SQL Anywhere を実行できない場合は、
  次の解決方法があります。

  o 共有ライブラリをロードできるようにラベルを変更します。この方法は、
    Red Hat Enterprise Linux 5 で機能しますが、SELinux の機能を使用
    できないという欠点があります。
	find $SQLANY16 -name "*.so" | xargs chcon -t textrel_shlib_t 2>/dev/null

  o SQL Anywhere 16 に付属するポリシーをインストールします。インストールの
    selinux ディレクトリにポリシーのソースがあります。ポリシーの構築と
    インストールについては、このディレクトリ内の
    README ファイルを参照してください。

  o 独自のポリシーを作成します。SQL Anywhere 16 に付属するポリシーを
    テンプレートとして使用できます。

  o 次のように入力して SELinux を無効にします。
/usr/sbin/setenforce 0

o スレッドとセマフォ - ソフトウェアで使用されているスレッドと
  セマフォの種類は重要です。システムによっては、これらの
  リソースが不足する可能性があります。

    o Linux、AIX、HP-UX、Mac OS X では、SQL Anywhere で
      pthreads (POSIX スレッド) と System V のセマフォが使用されます。

      注意 : System V セマフォを使用しているプラットフォームでは、データベース
      サーバまたはクライアントアプリケーションが SIGKILL で終了する場合、
      System V セマフォがリークされます。これらを手動でクリーンアップするには、
      ipcrm コマンドを使用します。また、システム呼び出し _exit() を使用して
      終了するクライアントアプリケーションも、この呼び出しより前に SQL Anywhere
      クライアント ライブラリ (ODBC、DBLib など) がアンロードされていない限り、
      System V セマフォをリークします。

o アラーム処理 - この機能は、非スレッド化アプリケーションの
  開発に SIGALRM または SIGIO ハンドラを使用している場合にのみ関係します。

  SQL Anywhere では、非スレッド化クライアントで SIGALRM と
  SIGIO のハンドラーが使用され、200 ミリ秒ごとに繰り返しアラームが開始されます。処理が正常に
  行われるには、SQL Anywhere でこれらの信号を処理できる必要があります。

  SQL Anywhere のライブラリをロードする前に SIGALRM または
  SIGIO のハンドラーを定義すると、SQL Anywhere はこれらのハンドラーに接続されます。
SQL Anywhere のライブラリのロード後にハンドラーを
  定義した場合は、SQL Anywhere のハンドラーから接続する必要があります。

  TCP/IP 通信プロトコルを使用する場合、SQL Anywhere では、
  非スレッド化クライアントでのみ SIGIO のハンドラーが使用されます。このハンドラーは
  常にインストールされますが、使用されるのは、アプリケーションで TCP/IP を使用する場合だけです。

o Red Hat Enterprise Linux では、一部の私用文字が Sybase Central、Interactive 
  SQL (dbisql)、Mobile Link プロファイラ、SQL Anywhere モニタ、または
   SQL Anywhere コンソールユーティリティ (dbconsole) で表示されない場合があります。

  Red Hat Linux ディストリビューションに付属するどの TrueType
  フォントにも、ユニコードのコードポイント "U+E844" と "U+E863"
  (私用文字) のグリフはありません。問題の文字は簡体字中国語の
  文字で、Red Flag (中国語版 Linux) ディストリビューションで
  zysong.ttf (DongWen-Song) フォントに含まれます。

