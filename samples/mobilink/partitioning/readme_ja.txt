// ***************************************************************************
// Copyright (c) 2013 SAP AG or an SAP affiliate company. All rights reserved.
// ***************************************************************************
// サンプルコードは「現状有姿(as is)」の条件で提供されるものであり、
// お客様に対しいかなる保証責任も賠償責任も負わないものとします。
//
// お客様は、当該サンプルコードを使用、複製および配布することができます。
// ただし、アイエニウェアの原コードに関する著作権表示およびにこれに対する
// 免責表示をすることを条件とします。
// 
// ********************************************************************

		    Mobile Link ローワイズ分割のサンプル

目的
----
このサンプルは、リモートデータベース間でテーブルの分割を実行する方法
を示します。

このサンプルでは、1 つの統合データベースと 2 つのリモートデータベース
間の同期が示されます。

各データベースは、従業員と顧客のデータを保持する 2 つのテーブルで構成
されています。
同期スクリプトは、タイムスタンプ同期を行います。

必要条件
--------
このサンプルは、SQL Anywhere Studio がインストール済みであることを前提
としています。

処理手順
--------
UNIX 上でこのサンプルを実行する場合、以下の手順で .bat を .sh に置き換
えてください。

build.bat を実行すると、統合データベースおよびリモートデータベースを作
成し、スクリプト、パブリケーション、およびデータを追加します。

step1.bat を実行すると、Mobile Link 同期サーバを起動します。
step2.bat を実行すると
		   - 同期を行います。
           - リモートおよび統合データベースにおいて追加データを追加します。
		   - 再同期を行います。
step3.bat を実行すると、Mobile Link 同期サーバをシャットダウンします。

report.bat を実行すると、各データベースの内容を report.txt に出力します。

clean.bat を実行すると、生成されたすべてのファイルを削除します。


