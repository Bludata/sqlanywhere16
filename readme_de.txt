SQL Anywhere 16.0 - Versionshinweise für Unix und Mac OS X

Copyright (c) 2013 SAP AG or an SAP affiliate company. All rights reserved.


SQL Anywhere 16 installieren
----------------------------

1. Wechseln Sie zu dem erstellten Verzeichnis und starten Sie das
   Installationsskript, indem Sie die folgenden Befehle eingeben:
        cd ga1600
        ./setup

   Eine vollständige Liste der verfügbaren Installationsoptionen erhalten 
   Sie, indem Sie den folgenden Befehl eingeben:
        ./setup -h

2. Befolgen Sie die Anweisungen des Installationsprogramms.


Installationshinweise 
---------------------

o Derzeit keine Einträge.


Dokumentation
-------------

Die Dokumentation finden Sie auf DocCommentXchange unter der folgenden Adresse:
    http://dcx.sybase.com

DocCommentXchange ist eine Online-Community für den Zugang zur
SQL Anywhere-Dokumentation im Internet mit Diskussionsforum. DocCommentXchange ist das
Standarddokumentationsformat für SQL Anywhere 16.


SQL Anywhere-Forum
------------------

Das SQL Anywhere-Forum ist eine Website zum Austausch von Fragen und Antworten
über die SQL Anywhere-Software sowie zum Kommentieren von und Abstimmen über
die Fragen und Antworten anderer Benutzer. Besuchen Sie das SQL Anywhere-Forum unter:
    http://sqlanywhere-forum.sybase.com.


Umgebungsvariablen für SQL Anywhere 16 festlegen
------------------------------------------------

Jeder Benutzer der Software muss die erforderlichen SQL Anywhere-
Umgebungsvariablen festlegen. Diese hängen vom jeweiligen Betriebssystem ab und werden
in der Dokumentation unter "SQL Anywhere-Server - Datenbankadministration >
Konfiguration Ihrer Datenbank > SQL Anywhere-Umgebungsvariablen" beschrieben.


Versionshinweise für SQL Anywhere 16
------------------------------------


SQL Anywhere-Server
-------------------

o Derzeit keine Einträge.


Administrationstools
--------------------

o Beim Installieren von SQL Anywhere unter 64-Bit-Linux-Systemen wird
  standardmäßig die 64-Bit-Version der grafischen Administrationstools
  (Sybase Central, Interactive SQL, DBConsole, ML-Profiler) installiert.

  Sie können auch 32-Bit-Administrationstools installieren. Dies Option gilt nur für
  OEMs, die die 32-Bit-Dateien für den Weitervertrieb benötigen.

  Das Ausführen der 32-Bit-Administrationstools unter 64-Bit-Linux-Systemen
 wird nicht unterstützt.

o Um Java Access Bridge für die Administrationstools zu aktivieren,
  bearbeiten Sie die Datei "accessibility.properties"
  und entkommentieren Sie die letzten zwei Zeilen.

  Die Datei wird wie folgt angezeigt:
  #
  # Load the Java Access Bridge class into the JVM
  #
  #assistive_technologies=com.sun.java.accessibility.AccessBridge
  #screen_magnifier_present=true

o Bei 64-Bit-Linux-Distributionen müssen Sie die
  32-Bit-Kompatibilitätsbibliotheken installieren, wenn Sie die
  Administrationstools verwenden wollen. Speziell die 
  32-Bit-X11-Bibliotheken sind erforderlich. Auf Ubuntu führen Sie 
  folgenden Befehl aus:


    Auf RedHat führen Sie folgenden Befehl aus: 
        yum install glibc.i686 

  Wenn Sie diese Bibliotheken nicht installieren, kann das Betriebssystem
  nicht die Binärdateien der Administrationstools laden. Wenn der Ladevorgang fehlschlägt,
  erhalten Sie eine Fehlermeldung wie die folgende:

  -bash: /opt/sqlanywhere16/bin32/dbisql: Datei oder Verzeichnis nicht vorhanden


o In einigen asiatischen Sprachversionen kann es vorkommen, dass die
  Administrationstools die asiatischen Zeichen nicht richtig auf Linux anzeigen.

  Die Anzeigeprobleme werden hauptsächlich durch fehlende Schriften verursacht
  (Dateien mit dem Präfix "fontconfig" im Bibliotheksverzeichnis des JRE). In
  einigen Fällen können Sie die Schriftkonfigurationsdateien für das
  Betriebssystem und die Sprachkombination vom Betriebssystemhersteller
  erhalten. Lesen Sie den Abschnitt unten, der Ihrem Betriebssystem am ehesten
  entspricht. Falls keiner der Abschnitte zutrifft, versuchen Sie es mit den
  Schritten im Abschnitt WEITERE BETRIEBSSYSTEME.


  Red Flag 5 (Chinesisch)

  Stellen Sie sicher, dass Sie das folgende RPM-Paket für die Sprachumgebung
  Vereinfachtes Chinesisch installiert haben:
           ttfonts-zh_CN-5.0-2

  Andernfalls finden Sie die RPM-Pakete auf CD Nr. 2 der Red Flag 5-Distribution.

  Das RPM-Paket kann mit dem Befehl "rpm -i" installiert werden, wenn Sie als
  Root angemeldet sind.

  Führen Sie die folgenden Befehle aus, so dass die JRE die 
  Schriftkonfigurationsdatei für das System findet:

  1. cd $SQLANY16/bin32/jre170/lib

  2. cp fontconfig.RedHat.3.properties.src fontconfig.Linux.properties

  Als Alternative können Sie die Datei "zysong.ttf" in das
  JRE-Schriftenverzeichnis kopieren.

  Führen Sie die folgenden Befehle aus, so dass die JRE die Schriften findet:

  1. cd /usr/share/fonts/zh_CN/TrueType

  2. mkdir $SQLANY16/bin32/jre170/lib/fonts/fallback

  3. cp zysong.ttf $SQLANY16/bin32/jre170/lib/fonts/fallback



  Red Flag Linux Desktop 6

  1. Fahren Sie alle aktiven grafischen Administrationstools (Sybase Central,
     Interactive SQL (dbisql), MobiLink-Profiler, SQL Anywhere-Monitor bzw.
     das SQL Anywhere-Konsolendienstprogramm (dbconsole) herunter.

  2. Führen Sie die folgenden Befehle aus, so dass die JRE die Schriften findet:

     mkdir $SQLANY16/bin32/jre170/lib/fonts/fallback
     ln -s /usr/share/fonts/zh_CN/TrueType/*.ttf 
    $SQLANY16/bin32/jre170/lib/fonts/fallback



  RedHat Enterprise Linux 4

  Stellen Sie sicher, dass Sie die Schriften für die asiatischen
  Sprachumgebungen installiert haben. Andernfalls
  finden Sie die RPM-Pakete auf CD Nr. 4 der Redhat Enterprise Linux 4-Distribution.

  Die folgenden RPM-Pakete enthalten die Schriften für asiatische
  Sprachumgebungen:

           ttfonts-ja-1.2-36.noarch.rpm
           ttfonts-ko-1.0.11-32.2.noarch.rpm
           ttfonts-zh_CN-2.14-6.noarch.rpm
           ttfonts-zh_TW-2.11-28.noarch.rpm

  Jedes dieser RPM-Pakete kann mit dem Befehl "rpm -i" installiert werden, wenn
  Sie als Root angemeldet sind.

  Führen Sie die folgenden Befehle aus, so dass die JRE die
  Schriftkonfigurationsdatei für Ihr System findet:

  1. cd $SQLANY16/bin32/jre170/lib

  2. cp fontconfig.RedHat.3.properties.src fontconfig.RedHat.4.properties



  RedHat Enterprise Linux 5

  1. Fahren Sie alle aktiven grafischen Administrationstools (Sybase Central,
     Interactive SQL (dbisql), MobiLink-Profiler, SQL Anywhere-Monitor bzw.
     das SQL Anywhere-Konsolendienstprogramm (dbconsole) herunter.

  2. Stellen Sie sicher, dass die Schriften zur Anzeige der asiatischen
     Sprachen installiert sind. Zum Zeitpunkt des Verfassens dieser
     Informationen war eine Anleitung auf der folgenden Red Hat-Website
     verfügbar:

     www.redhat.com/docs/manuals/enterprise/RHEL-5-manual/en-US/Internationalization_Guide.pdf

  3. Die Administrationstools sollten dann in der Lage sein, die asiatischen
     Schriften anzuzeigen, ohne dass eine weitere Aktion notwendig ist.



  RedHat Enterprise Linux 6

  1. Fahren Sie alle aktiven grafischen Administrationstools (Sybase Central,
     Interactive SQL (dbisql), MobiLink-Profiler, SQL Anywhere-Monitor bzw.
     das SQL Anywhere-Konsolendienstprogramm (dbconsole) herunter.

  2. Stellen Sie sicher, dass die Sprachunterstützung und Schriften installiert sind, 
     die zum Anzeigen asiatischer Sprachen benötigt werden. 

  3. Führen Sie die folgenden Befehle aus, so dass die JRE die Schriften findet:

       ln -s /usr/share/fonts/cjkuni-ukai/ukai.ttc $SQLANY16/bin32/jre170/lib/fonts/fallback/ukai.ttc



  SUSE 10

  Stellen Sie sicher, dass Sie die Schriften für die asiatischen
  Sprachumgebungen installiert haben. Andernfalls finden Sie die RPM-Pakete
  auf den CDs der SuSE 10-Distribution.

	  sazanami-fonts-20040629-7.noarch.rpm		    (CD #1)
	  unfonts-1.0.20040813-6.noarch.rpm		    (CD #2)
	  ttf-founder-simplified-0.20040419-6.noarch.rpm    (CD #1)
	  ttf-founder-traditional-0.20040419-6.noarch.rpm   (CD #1)

  Wenn diese Schriften nicht die gewünschten Zeichen enthalten, versuchen Sie
  es mit Schritten im Abschnitt WEITERE BETRIEBSSYSTEME.

  Jedes dieser RPM-Pakete kann mit dem Befehl "rpm -i" installiert werden, wenn
  Sie als Root angemeldet sind.

  Führen Sie die folgenden Befehle aus, so dass die JRE die Schriften findet:

  1. ln -s /usr/X11R6/lib/X11/fonts/truetype $SQLANY16/bin32/jre170/lib/fonts/fallback

  Hinweis: Das Festlegen der Sprache in der Login-Eingabeaufforderung ist für
  JRE (und daher auch für die Administrationstools) nicht ausreichend, um die
  Sprachumgebung zu bestimmen. Vor dem Starten der Administrationstools sollte
  die Umgebungsvariable LANG auf einen der folgenden Werte festgelegt werden:

           ja_JP
           ko_KR
           zh_CN
           zh_TW

  Beispiel: In der Bourne-Shell und ihren Derivaten führen Sie folgenden
  Befehl aus, bevor Sie die Administrationstools starten:

        export LANG=ja_JP

  Einige deutsche Zeichen (z.B. Umlaut-A) werden in der Windows-Titelleiste
  nicht korrekt angezeigt, wenn die Sprachumgebung auf de_DE.UTF-8 gesetzt ist.
  Dieses Problem kann umgangen werden, indem die Sprachumgebung de_DE@euro
  verwendet wird.

  Eine vollständige Liste von gültigen Sprachumgebungseinstellungen finden 
  Sie in der Verzeichnisliste unter /usr/lib/locale.



  SUSE 11 Linux Enterprise Server

  1. Fahren Sie alle aktiven grafischen Administrationstools (Sybase Central,
     Interactive SQL (dbisql), MobiLink-Profiler, SQL Anywhere-Monitor bzw.
     das SQL Anywhere-Konsolendienstprogramm (dbconsole) herunter.

  2. Führen Sie Control Center aus, klicken Sie auf "Sprache", und wählen Sie
     beispielsweise "Japanisch" aus. Klicken Sie auf OK.

  3. Führen Sie die folgenden Befehle aus:

     mkdir $SQLANY16/bin32/jre170/lib/fonts/fallback
     ln -s /usr/share/fonts/truetype/*.ttf
     $SQLANY16/bin32/jre170/lib/fonts/fallback



  UBUNTU 8.10

  1. Fahren Sie alle aktiven grafischen Administrationstools (Sybase Central,
     Interactive SQL (dbisql), MobiLink-Profiler, SQL Anywhere-Monitor bzw.
     das SQL Anywhere-Konsolendienstprogramm (dbconsole) herunter.

  2. Führen Sie die folgenden Befehle aus:

     mkdir $SQLANY16/bin32/jre170/lib/fonts/fallback
     ln -s /usr/share/fonts/truetype/kochi/*.ttf
     $SQLANY16/bin32/jre170/lib/fonts/fallback



  UBUNTU 9.10

  1. Fahren Sie alle aktiven grafischen Administrationstools (Sybase Central,
     Interactive SQL (dbisql), MobiLink-Profiler, SQL Anywhere-Monitor bzw.
     das SQL Anywhere-Konsolendienstprogramm (dbconsole) herunter.

  2. Führen Sie die folgenden Befehle aus:

     mkdir $SQLANY16/bin32/jre170/lib/fonts/fallback
     ln -s /usr/share/fonts/truetype/vlgothic/*.ttf
     $SQLANY16/bin32/jre170/lib/fonts/fallback



  UBUNTU 10.04 und 11.04

  1. Fahren Sie alle aktiven grafischen Administrationstools (Sybase Central,
     Interactive SQL (dbisql), MobiLink-Profiler, SQL Anywhere-Monitor bzw.
     das SQL Anywhere-Konsolendienstprogramm (dbconsole) herunter.

  2. Führen Sie den folgenden Befehl aus:

	mkdir $SQLANY16/bin32/jre170/lib/fonts/fallback

  3. Führen Sie einen oder mehrere der folgenden Befehle aus, um Schriften für
 die angegebene Sprache zu aktivieren:

     JAPANISCH:
	ln -s /usr/share/fonts/truetype/takao/*.ttf
	$SQLANY16/bin32/jre170/lib/fonts/fallback


     VEREINFACHTES CHINESISCH:
	ln -s /usr/share/fonts/truetype/arphic/*.ttc
	$SQLANY16/bin32/jre170/lib/fonts/fallback
	ln -s /usr/share/fonts/truetype/wqy/*.ttc
	$SQLANY16/bin32/jre170/lib/fonts/fallback


  WEITERE BETRIEBSSYSTEME

  Wenn Sie über eine Distribution vom gleichen Typ, aber mit einer anderen
  Versionsnummer als in den obigen Abschnitten aufgeführt, verfügen, empfehlen
  wir, dass Sie die Schritte in dem am ehesten zutreffenden Abschnitt
  ausführen. Eventuell sollten Sie die Schritte für die Version anpassen. 
Außerdem empfehlen wir, im Internet nach einer spezifischen Lösung für Ihre
  Distribution zu suchen. Falls mit keinem der Schritte eine zufriedenstellende
  Lösung erzielt wird, kann die nachfolgend beschriebene allgemeine Lösung
  angewandt werden.

  Im Folgenden wird eine Prozedur zur Installation einer Unicode
  TrueType-Schrift für die JRE erläutert, die von den Administrationstools
  verwendet wird. Diese Methode kann für alle nicht oben erwähnten
  Linux-Betriebssysteme angewandt werden. Andere TrueType-Schriften lassen
  sich auf ähnliche Weise installieren.

  1. Fahren Sie alle Administrationstools herunter, die ausgeführt werden.

  2. Laden Sie eine kostenlos erhältliche Unicode-Schrift wie Bitstream
     Cyberbit herunter. Diese Schrift finden Sie unter:

     ftp://ftp.netscape.com/pub/communicator/extras/fonts/windows/Cyberbit.ZIP

  3. Entzippen Sie Cyberbit.ZIP in ein temporäres Verzeichnis.

  4. Erstellen Sie das Verzeichnis $SQLANY16/bin32/jre170/lib/fonts/fallback.

  5. Kopieren Sie Cyberbit.ttf in das Verzeichnis
     $SQLANY16/bin32/jre170/lib/fonts/fallback.


MobiLink
--------

o Der MobiLink-Server benötigt einen ODBC-Treiber für die Kommunikation
  mit konsolidierten Datenbanken. Die für die unterstützten konsolidierten
  Datenbanken empfohlenen ODBC-Treiber finden Sie über den folgenden Link
  auf der Sybase-Startseite:
    http://www.sybase.com/detail?id=1011880

o Informationen zu den von MobiLink unterstützten Plattformen finden Sie unter:
    http://www.sybase.com/detail?id=1002288


QAnywhere
---------

o Derzeit keine Einträge.


UltraLite
---------

o Derzeit keine Einträge.


Betriebssystemunterstützung
---------------------------

o Unterstützung von Direct I/O und THP durch RedHat Enterprise Linux 6 -
  RedHat Linux 6 weist einen möglichen Bug in der THP-Funktion (Transparent
  Huge Pages) auf, die in dieser Version des Betriebssystems eingeführt wurde,
  bei Verwendung mit Direct I/O. Das wahrscheinlichste Auftreten dieses Bugs in
  SQL Anywhere ist Assertierung 200505 (Prüfsummenfehler auf Seite X). 
Red Hat-Bug 891857 wurde erstellt, um dieses Problem zu verfolgen.

  Um dieses Problem zu umgehen, vermeidet SQL Anywhere unter diesem
  Betriebssystem die Verwendung von Direct I/O. Wenn Sie Direct
 I/O verwenden möchten, müssen Sie THP mit dem folgenden Befehl deaktivieren:
       echo never > /sys/kernel/mm/redhat_transparent_hugepage/enabled

o 64-Bit-Linux-Unterstützung - Einige 64-Bit-Linux-Betriebssysteme enthalten
  keine vorinstallierten 32-Bit-Kompatibilitätsbibliotheken. Um 32-Bit-Software
 zu verwenden, müssen Sie eventuell 32-Bit-Kompatibilitätsbibliotheken für
  Ihre Linux- Distribution installieren. Unter Ubuntu müssen Sie dazu
  beispielsweise führen Sie den folgenden Befehl ausführen:
	sudo apt-get install ia32-libs

  Auf RedHat führen Sie folgenden Befehl aus:
   yum install glibc.i686
    yum install libpk-gtk-module.so 
   yum install libcanberra-gtk2.i686 
    yum install gtk2-engines.i686    

o Linux-Unterstützung für dbsvc - Das Dienstprogramm dbsvc
erfordert LSB init-Funktionen.
  Bei einigen Linux-Betriebssystemen sind diese Funktionen
nicht standardmäßig vorinstalliert.
  Wenn Sie dbsvc verwenden wollen, müssen diese Funktionen für Ihre
Linux-Distribution installiert werden.  Führen Sie beispielsweise unter Fedora
  den folgenden Befehl aus:
	yum install redhat-lsb redhat-lsb.i686

o SELinux-Unterstützung - Wenn Sie Probleme mit der Ausführung von SQL Anywhere 
  auf SELinux haben, stehen mehrere Lösungsmöglichkeiten zur Verfügung:

  o Markieren Sie die gemeinsam genutzten Bibliotheken um, so dass sie geladen
werden können. Dies funktioniert unter Red Hat Enterprise Linux 5, hat aber
    den Nachteil, dass die SELinux-Funktionen nicht verwendet werden.
	find $SQLANY12 -name "*.so" | xargs chcon -t textrel_shlib_t 2>/dev/null

  o Installieren Sie die mit SQL Anywhere 16 bereitgestellte Richtlinie. Im
 selinux-Verzeichnis der Installation befinden sich Quelldateien der
    Richtlinie. Anweisungen zum Erstellen und Installieren dieser Richtlinie
    finden Sie in der README-Datei in diesem Verzeichnis.

  o Schreiben Sie Ihre eigene Richtlinie. Sie können die mit SQL Anywhere 16
    bereitgestellte Richtlinie als Ausgangspunkt verwenden.

  o Deaktivieren Sie SELinux:
        /usr/sbin/setenforce 0

o Threads und Semaphore - Die Art der in der Software verwendeten Threads und
  Semaphore kann ziemlich wichtig sein, da es bei einigen Systemen zu
  Knappheit dieser Ressourcen kommen kann.

    o Unter Linux, AIX, HP-UX und Mac OS X verwendet SQL Anywhere pthreads
      (POSIX-Threads) und System V-Semaphore.

      Hinweis: Auf Plattformen, auf denen System V-Semaphore verwendet werden,
      gehen diese verloren, wenn der Datenbankserver oder eine Clientanwendung
      mit SIGKILL beendet wird. Sie müssen sie mit dem Befehl
      "ipcrm" manuell bereinigen.  Außerdem gehen System V-Semaphore
      bei Clientanwendungen verloren, die mit dem _exit()-Systemaufruf
      beendet werden, es sei denn, die SQL Anywhere-Clientbibliotheken
      (z.B. ODBC und DBLib) werden vor diesem Aufruf entladen.

o Verarbeitung von Alarmsignalen - Dies ist nur von Interesse, wenn Sie
  Non-Threaded-Anwendungen entwickeln und SIGALRM- oder SIGIO-Handler verwenden.

  SQL Anywhere verwendet SIGALRM- und einen SIGIO-Handler in Non-Threaded-
  Clients und startet einen sich wiederholenden Alarm (alle 200 ms). Korrektes
  Verhalten erhalten Sie, wenn SQL Anywhere diese Signale verarbeiten kann.

  Falls Sie einen SIGALRM- oder SIGIO-Handler definieren, bevor Sie eine oder mehrere
  der SQL Anywhere-Bibliotheken laden, wird SQL Anywhere sich an diese Handler 
  anhängen. Falls Sie einen Handler nach dem Laden von SQL Anywhere-Bibliotheken
  definieren, müssen Sie den Handler an SQL Anywhere anhängen. 

  Bei Verwendung des TCP/IP-Kommunikationsprotokolls benutzt SQL Anywhere
  SIGIO-Handler nur in Non-Threaded-Clients. Dieser Handler ist immer
  installiert, wird aber nur benutzt, wenn die Anwendung TCP/IP verwendet.

o Unter Red Hat Enterprise Linux werden einige Zeichen des privaten
  Nutzungsbereichs in Sybase Central, Interactive SQL (dbisql), MobiLink-
  Profiler, SQL Anywhere-Monitor oder SQL Anywhere-Konsolendienstprogramm
  (dbconsole) möglicherweise nicht richtig angezeigt.

  Für die Unicode-Codepoints "U+E844" und "U+E863" (als Zeichen für private
  Nutzung reserviert) werden in keiner der mit der Red Hat-Linux-Distribution
  ausgelieferten Truetype-Schriften Glyphen bereitgestellt. Die betreffenden
  Zeichen sind vereinfachte chinesische Schriftzeichen und in der
  Linux-Distribution Red Flag (chinesische Distribution) im Rahmen der Schrift
  zysong.ttf (DongWen-Song) verfügbar.

