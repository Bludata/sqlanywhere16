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
// *********************************************************************

      SQL Anywhere サンプル ストアドプロシージャーとファンクション
      ============================================================

このフォルダーで説明しているプロシージャーおよびファンクションは、
例として提供されているものです。

verify_password
---------------

この例では、パスワードに特定の種類の文字を要求し、パスワードの再利用を
禁止するなど、詳細なパスワード規則を実装する関数を定義します。
f_verify_pwd 関数は、ユーザー ID の作成またはパスワードの変更が行われた
ときに、verify_password_function オプションを使用してサーバーから呼び出
されます。

デフォルトのログインプロファイルは、180 日ごとにパスワードを失効させ、
5 回連続してログインに失敗した場合に DBA 以外のアカウントをロックする
ように設定されています。アプリケーションは、post_login_procedure オプ
ションによって指定されたプロシージャーを呼び出し、パスワードの期限が切れ
る前にパスワードを変更するように警告することができます。

***************************************************************************

sa_get_column_list
------------------

パラメーター：
1) テーブル名
2) 除外リスト (オプション)
3) セパレータ (オプション)
4) キーカラムまたは非キーカラムのみ (オプション)


DBA として demo.db に接続した場合：
        Select * from sa_get_column_list('GROUPO.SalesOrderItems')
結果：
        column_list
        ------------------------------------------------------
        ID, LineID, ProductID, Quantity, ShipDate


別のテーブルオーナーを指定する場合：
        Select * from sa_get_column_list('SYS.SYSTABLE')
結果：
        column_list
        ------------------------------------------------------
        table_id, file_id, count, first_page, last_page, primary_root, creator, ...


カラムを除外することもできます。
        Select column_list
        from sa_get_column_list('GROUPO.SalesOrderItems','LineID,Quantity')
結果：
        column_list
        -------------------------------
        ID, ProductID, ShipDate


これは、以下の場合に使用できます。
1.  パブリケーションおよびアーティクルのリストを作成する。
2.  プログラムの実行中にSQL 文を生成する (INSERTなど)。


以下のセパレーターを指定することもできます。
        Select '<td>'||column_list||'</td>' as cells
        from sa_get_column_list('GROUPO.SalesOrderItems', '', '</td><td>',)
結果：
        cells
        ------------------------------------------------------
        <td>ID</td><td>LineID</td><td>ProductID</td><td>Quantity</td><td>ShipDate</td>

最後に、プライマリキーカラムまたは非プライマリキーカラムのみを含める場
合、その旨を示すこともできます。
        Select column_list
        from sa_get_column_list('GROUPO.SalesOrderItems', '', ', ', NULL)
結果：
        ID, LineID, ProductID, Quantity, ShipDate

        Select column_list
        from sa_get_column_list('GROUPO.SalesOrderItems', '', ', ', 'Y')
または
        Select column_list
        from sa_get_column_list('GROUPO.SalesOrderItems', @only_keys='Y')
結果：
        ID, LineID

        Select column_list
        from sa_get_column_list('GROUPO.SalesOrderItems', '', ', ', 'N')
または
        Select column_list
        from sa_get_column_list('GROUPO.SalesOrderItems', @only_keys='N')
結果：
        ID, LineID, ProductID, Quantity, ShipDate

これを利用して、UPDATE 文の SET および WHERE 部分を生成できます。

*************************************************************************

create_default_stoplist
-----------------------

この例は、2 つのテーブルを作成し、ロードします。一方のテーブルは言語の
数に関するデフォルトのストップリストを定義します。もう一方は 'language' 
サーバプロパティによって返された名前に iso_639 言語コードをマップします。
2 つのテーブルは、ロードされた後、'language' サーバープロパティの値に基
づいた default_char および default_nchar のテキスト構成を設定するため
に使用されます。

このサンプルを実行する前に、次の手順を実行して下さい：

    1. .csv ファイルにフルパスを指定するために、load コマンドを修正し
       て下さい。必ず2重円記号 (\\) を使用して下さい。

    2. データベースのフォルダーに .csv ファイルをコピーして下さい。

*************************************************************************

simplify_geometry
-----------------

この例は線ストリングとジオメトリリングの点の数を減らすために使用される
関数を実行します。消去する点は指定した許容度以下の多角形を変えます。
これは共線または共線に近い多くの連続する点を持つジオメトリの複雑性を減
らすのに役立ちます。

simplify_geometry 関数は２つのパラメーターを取ります：
1) g は簡素化された多角形を入力します。平面空間参照システムで使用され
   ます。
2) toler は元のジオメトリと簡素化されたジオメトリの最大差（許容度）です。
   空間参照システム用の直線測定単位のデフォルトを指定します。
g と同じタイプで同じ空間参照システムの簡素化されたジオメトリを返します。
全てのジオメトリまたはジオメトリタイプが簡素化できるわけではないので、
簡素化できなかった場合は、元のジオメトリを返します。

注意：入力した線ストリングが有効であっても有効でない（ST_IsValidが 0 
を返す）ジオメトリを返す場合があります。簡素化されたジオメトリの指定
した許容度の範囲内で点を削除することにより、自信の交点とリボン型を返す
場合があります。このサンプルを使用する前に、ST_IsValid メソッドを使用
してジオメトリの有効性を確認する事を推奨します。
