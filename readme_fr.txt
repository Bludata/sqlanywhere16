SQL Anywhere 16.0 - Notes de mise à jour pour Unix, Linux et Mac OS X

Copyright (c) 2013 SAP AG or an SAP affiliate company. All rights reserved.


Installation de SQL Anywhere 16
-------------------------------

1. Dans le répertoire créé, lancez le script d'installation en exécutant
   les commandes suivantes :
        cd ga1600
        ./setup

   Pour obtenir la liste complète des options d'installation disponibles,
   exécutez cette commande :
        ./setup -h

2. Suivez les instructions du programme d'installation.


Notes d'installation
--------------------

o Aucune information disponible.


Documentation
-------------

La documentation est disponible sur DocCommentXchange :
    http://dcx.sybase.com

DocCommentXchange est un site communautaire sur lequel vous pouvez consulter
et commenter la documentation de SQL Anywhere. DocCommentXchange est le format
de documentation par défaut pour SQL Anywhere 16.


Forum SQL Anywhere
------------------

Le forum SQL Anywhere est un site Web sur lequel vous pouvez poser
des questions sur le logiciel SQL Anywhere et apporter des réponses,
ainsi que commenter les questions et réponses des autres participants.
Rendez-vous sur le forum SQL Anywhere à l'adresse :
    http://sqlanywhere-forum.sybase.com.


Configuration des variables d'environnement pour SQL Anywhere 16
----------------------------------------------------------------

Les variables d'environnement de SQL Anywhere doivent être définies
préalablement à l'utilisation du logiciel. Leur paramétrage dépend du système
d'exploitation. Pour le connaître, consultez la section "Database
Configuration" > "SQL Anywhere environment variables" du manuel "SQL Anywhere
Server - Database Administration".


SQL Anywhere 16 - Notes de mise à jour
--------------------------------------


Serveur SQL Anywhere
--------------------

o Aucune information disponible.


Outils d'administration
-----------------------

o Lorsque vous installez SQL Anywhere sur des machines Linux 64 bits, les
  outils d'administration graphiques (Sybase Central, Interactive SQL,
  la console SQL Anywhere et le Profileur MobiLink) s'installent par défaut
  en version 64 bits.

  Vous avez également la possibilité de les installer en version 32 bits,
   cette option étant réservée aux OEM dont la redistribution inclut des
  fichiers 32 bits.

  Les outils d'administration 32 bits ne sont pas pris en charge sur
  Linux 64 bits.

o Pour activer Java Access Bridge pour les outils d'administration,
  modifiez le fichier accessibility.properties en supprimant la mise en
  commentaire des deux dernières lignes.

  Le fichier se présente ainsi :
  #
  # Load the Java Access Bridge class into the JVM
  #
  #assistive_technologies=com.sun.java.accessibility.AccessBridge
  #screen_magnifier_present=true

o Pour utiliser les outils d'administration sur une distribution Linux
  64 bits, vous devez installer les bibliothèques de compatibilité 32 bits,
  les bibliothèques X11 32 bits étant obligatoires. Sur Ubuntu, exécutez :
	sudo apt-get install ia32-libs

  Sur RedHat, exécutez :
	yum install glibc.i686

  Si vous n'installez pas ces bibliothèques, le système d'exploitation ne
  pourra pas charger les binaires des outils d'administration. Lorsque le
  chargement échoue, une erreur de ce type s'affiche :

  -bash: /opt/sqlanywhere16/bin32/dbisql: Il n'existe aucun fichier ou
  répertoire de ce type


o Dans certains environnements linguistiques asiatiques, il se peut que
  les outils d'administration graphiques n'affichent pas correctement
  les caractères asiatiques par défaut.

  Les problèmes d'affichage sont principalement liés à l'absence des fichiers
  de configuration des polices (dont le préfixe est fontconfig et qui se
  trouvent dans le répertoire lib du JRE). Dans certains cas, vous pouvez
  obtenir auprès du fournisseur de votre système d'exploitation les fichiers
  correspondant à celui-ci et à votre combinaison linguistique. Consultez la
  section ci-dessous qui correspond le mieux à votre système d'exploitation.
  A défaut, tentez la procédure de la section AUTRE.


  Red Flag 5 (chinois)

  Assurez-vous que vous avez installé le package RPM suivant pour
  l'environnement linguistique en chinois simplifié :
           ttfonts-zh_CN-5.0-2

  Les packages RPM se trouvent sur le CD n°2 de la distribution RedFlag 5.

  Pour installer le package RPM, vous devez être connecté en tant
  qu'utilisateur racine (root) et exécuter la commande "rpm -i".

  Exécutez les commandes suivantes pour que le JRE localise le fichier de
  configuration des polices pour votre système :

  1. cd $SQLANY16/bin32/jre170/lib

  2. cp fontconfig.RedHat.3.properties.src fontconfig.Linux.properties

  Sinon, vous pouvez copier le fichier zysong.ttf dans le répertoire des
  polices du JRE.

  Exécutez les commandes suivantes pour que le JRE localise les polices :

  1. cd /usr/share/fonts/zh_CN/TrueType

  2. mkdir $SQLANY16/bin32/jre170/lib/fonts/fallback

  3. cp zysong.ttf $SQLANY16/bin32/jre170/lib/fonts/fallback



  Red Flag Linux Desktop 6

  1. Fermez tous les outils d'administration graphiques actuellement en cours
     d'exécution (Sybase Central, Interactive SQL (dbisql), le Profileur
     MobiLink, le Moniteur SQL Anywhere et la console SQL Anywhere
     (dbconsole)).

  2. Exécutez les commandes suivantes pour que le JRE localise les polices :

     mkdir $SQLANY16/bin32/jre170/lib/fonts/fallback
     ln -s /usr/share/fonts/zh_CN/TrueType/*.ttf $SQLANY16/bin32/jre170/lib/fonts/fallback



  RedHat Enterprise Linux 4

  Assurez-vous que les polices des environnements linguistiques asiatiques 
  sont installées. Si elles ne le sont pas, utilisez les packages RPM qui se
  trouvent sur le CD n°4 de la distribution Redhat Enterprise Linux 4.

  Ces polices sont contenues dans les packages RPM suivants :

           ttfonts-ja-1.2-36.noarch.rpm
           ttfonts-ko-1.0.11-32.2.noarch.rpm
           ttfonts-zh_CN-2.14-6.noarch.rpm
           ttfonts-zh_TW-2.11-28.noarch.rpm

  Pour installer chacun de ces packages RPM, vous devez être connecté en tant
  qu'utilisateur racine (root) et exécuter la commande "rpm -i".

  Exécutez les commandes suivantes pour que le JRE localise le fichier de
  configuration des polices pour votre système :

  1. cd $SQLANY16/bin32/jre170/lib

  2. cp fontconfig.RedHat.3.properties.src fontconfig.RedHat.4.properties



  RedHat Enterprise Linux 5

  1. Fermez tous les outils d'administration graphiques actuellement en cours
     d'exécution (Sybase Central, Interactive SQL (dbisql), le Profileur
     MobiLink, le Moniteur SQL Anywhere et la console SQL Anywhere
     (dbconsole)).

  2. Assurez-vous que les polices requises pour afficher les langues
     asiatiques sont installées. Au moment où ces instructions ont été
     rédigées, le guide d'installation des polices était disponible sur le
     site Web de Red Hat :

     www.redhat.com/docs/manuals/enterprise/RHEL-5-manual/en-US/Internationalization_Guide.pdf

  3. Les polices asiatiques devraient alors s'afficher dans les outils
     d'administration sans nécessiter aucune autre action.



  RedHat Enterprise Linux 6

  1. Fermez tous les outils d'administration graphiques actuellement en cours
     d'exécution (Sybase Central, Interactive SQL (dbisql), le Profileur
     MobiLink, le Moniteur SQL Anywhere et la console SQL Anywhere
     (dbconsole)).

  2. Assurez-vous que la prise en charge de la langue et les polices requises
     pour afficher les langues asiatiques sont installées.

  3. Exécutez les commandes suivantes pour que le JRE localise les polices :

       ln -s /usr/share/fonts/cjkuni-ukai/ukai.ttc $SQLANY16/bin32/jre170/lib/fonts/fallback/ukai.ttc



  SUSE 10

  Assurez-vous que les polices des environnements linguistiques asiatiques 
  sont installées. Si elles ne le sont pas, utilisez les packages RPM qui se
  trouvent sur les CD de la distribution SuSE 10.

	  sazanami-fonts-20040629-7.noarch.rpm		    (CD n°1)
	  unfonts-1.0.20040813-6.noarch.rpm		    (CD n°2)
	  ttf-founder-simplified-0.20040419-6.noarch.rpm    (CD n°1)
	  ttf-founder-traditional-0.20040419-6.noarch.rpm   (CD n°1)

  Si ces polices ne contiennent pas les caractères à afficher, tentez la
  procédure de la section AUTRE.

  Pour installer chacun de ces packages RPM, vous devez être connecté en tant
  qu'utilisateur racine (root) et exécuter la commande "rpm -i".

  Exécutez les commandes suivantes pour que le JRE localise les polices :

  1. ln -s /usr/X11R6/lib/X11/fonts/truetype $SQLANY16/bin32/jre170/lib/fonts/fallback

  Remarque : Il ne suffit pas de choisir une langue à l'invite de connexion
  pour que le JRE (et par extension, les outils d'administration) puisse
  définir l'environnement linguistique. Avant de lancer les outils
  d'administration, attribuez l'une des valeurs suivantes à la variable
  d'environnement LANG :

           ja_JP
           ko_KR
           zh_CN
           zh_TW

  Par exemple, dans le shell Bourne et ses dérivés, exécutez la commande
  suivante avant de lancer les outils d'administration :

        export LANG=ja_JP

  Certains caractères allemands (comme le "a" avec un umlaut, par exemple)
  ne s'affichent pas correctement dans les barres de titre si la valeur
  d'environnement linguistique de_DE.UTF-8 n'est pas définie. Le contournement
  consiste à utiliser l'environnement linguistique de_DE@euro.

  La liste complète des paramètres d'environnement linguistique applicables
  est disponible dans le répertoire /usr/lib/locale.



  SUSE 11 Linux Enterprise Server

  1. Fermez tous les outils d'administration graphiques actuellement en cours
     d'exécution (Sybase Central, Interactive SQL (dbisql), le Profileur
     MobiLink, le Moniteur SQL Anywhere et la console SQL Anywhere
     (dbconsole)).

  2. Démarrez le Centre de contrôle et choisissez le japonais (par exemple),
     parmi les langues proposées. Cliquez sur OK.

  3. Exécutez les commandes suivantes :

     mkdir $SQLANY16/bin32/jre170/lib/fonts/fallback
     ln -s /usr/share/fonts/truetype/*.ttf $SQLANY16/bin32/jre170/lib/fonts/fallback



  UBUNTU 8.10

  1. Fermez tous les outils d'administration graphiques actuellement en cours
     d'exécution (Sybase Central, Interactive SQL (dbisql), le Profileur
     MobiLink, le Moniteur SQL Anywhere et la console SQL Anywhere
     (dbconsole)).

  2. Exécutez les commandes suivantes :

     mkdir $SQLANY16/bin32/jre170/lib/fonts/fallback
     ln -s /usr/share/fonts/truetype/kochi/*.ttf $SQLANY16/bin32/jre170/lib/fonts/fallback



  UBUNTU 9.10

  1. Fermez tous les outils d'administration graphiques actuellement en cours
     d'exécution (Sybase Central, Interactive SQL (dbisql), le Profileur
     MobiLink, le Moniteur SQL Anywhere et la console SQL Anywhere
     (dbconsole)).

  2. Exécutez les commandes suivantes :

     mkdir $SQLANY16/bin32/jre170/lib/fonts/fallback
     ln -s /usr/share/fonts/truetype/vlgothic/*.ttf $SQLANY16/bin32/jre170/lib/fonts/fallback



  UBUNTU 10.04 et 11.04

  1. Fermez tous les outils d'administration graphiques actuellement en cours
     d'exécution (Sybase Central, Interactive SQL (dbisql), le Profileur
     MobiLink, le Moniteur SQL Anywhere et la console SQL Anywhere
     (dbconsole)).

  2. Exécutez la commande suivante :

	mkdir $SQLANY16/bin32/jre170/lib/fonts/fallback

  3. Exécutez une ou plusieurs des commandes suivantes pour activer
     les polices de la langue indiquée :

     JAPONAIS :
	ln -s /usr/share/fonts/truetype/takao/*.ttf $SQLANY16/bin32/jre170/lib/fonts/fallback


     CHINOIS SIMPLIFIE :
	ln -s /usr/share/fonts/truetype/arphic/*.ttc $SQLANY16/bin32/jre170/lib/fonts/fallback
	ln -s /usr/share/fonts/truetype/wqy/*.ttc $SQLANY16/bin32/jre170/lib/fonts/fallback


  AUTRE

  Si vous disposez d'une distribution de même type, mais dont le numéro de
  version n'est pas répertorié dans les sections précédentes, il est
  recommandé d'essayer la procédure la plus proche, en l'adaptant au numéro de
  version. Vous pouvez également rechercher sur Internet la solution
  spécifique de votre distribution. Si aucune de ces procédures n'aboutit à
  une résolution satisfaisante, vous pouvez utiliser la solution générique
  décrite ci-après.

  La procédure suivante permet d'installer une police TrueType Unicode dans le
  JRE qu'utilisent les outils d'administration. Cette méthode est applicable
  sur tous les systèmes d'exploitation Linux mentionnés ci-avant. Vous pouvez
  installer d'autres polices TrueType de la même façon.

  1. Fermez les outils d'administration actuellement en cours d'exécution.

  2. Téléchargez une police Unicode gratuite, comme Bitstream Cyberbit,
     disponible sur :

     ftp://ftp.netscape.com/pub/communicator/extras/fonts/windows/Cyberbit.ZIP

  3. Décompactez Cyberbit.ZIP dans un répertoire temporaire.

  4. Créez un répertoire $SQLANY16/bin32/jre170/lib/fonts/fallback.

  5. Copiez Cyberbit.ttf dans le répertoire
     $SQLANY16/bin32/jre170/lib/fonts/fallback.


MobiLink
--------

o Le serveur MobiLink nécessite un pilote ODBC pour communiquer avec
  les bases de données consolidées. Les pilotes ODBC recommandés pour assurer
  la prise en charge des bases consolidées sont répertoriés sur le site
  de Sybase, à la page :
    http://www.sybase.com/detail?id=1011880

o Pour connaître les plates-formes prises en charge par MobiLink, consultez :
    http://www.sybase.com/detail?id=1002288


QAnywhere
---------

o Aucune information disponible.


UltraLite
---------

o Aucune information disponible.


Système d'exploitation requis
-----------------------------

o Prise en charge des THP et des E/S directes de RedHat EnterpriseLinux 6 - Il
  est possible qu'un bug se produise avec la nouvelle fonctionnalité THP
  (transparent huge pages, pages très volumineuses transparentes) de cette
  version de système d'exploitation lorsqu'elle est utilisée avec des E/S
  directes. Ce bug se traduira probablement par une assertion 200505 dans SQL
  Anywhere (erreur de checksum à la page X). Pour le suivi du problème, le bug
  Red Hat 891857 a été créé.

  Pour contourner le problème, SQL Anywhere évite d'utiliser des E/S directes
  sur ce système d'exploitation. Pour en utiliser, vous devez désactiver
  les THP à l'aide de la commande suivante :
       echo never > /sys/kernel/mm/redhat_transparent_hugepage/enabled

o Prise en charge de Linux 64 bits - Les bibliothèques de compatibilité
  32 bits ne sont pas pré-installées sur certains systèmes d'exploitation
  Linux 64 bits. Pour utiliser des logiciels 32 bits, vous devrez probablement
  installer les bibliothèques de compatibilité 32 bits adaptées à votre
  distribution Linux. Sur Ubuntu, par exemple, vous devrez peut-être exécuter
  cette commande :
	sudo apt-get install ia32-libs

  Sur RedHat, exécutez :
	yum install glibc.i686
	yum install libpk-gtk-module.so
	yum install libcanberra-gtk2.i686
	yum install gtk2-engines.i686

o Prise en charge de dbsvc sur Linux - Les fonctions LSB init-functions sont
  nécessaires pour cet utilitaire. Or, certains systèmes d'exploitation ne
  les pré-installent pas par défaut. Pour utiliser dbsvc, vous devez donc
  installer les fonctions adaptées à votre distribution Linux. Par exemple,
  sur Fedora, exécutez cette commande :
	yum install redhat-lsb redhat-lsb.i686

o Prise en charge de SELinux - Si vous rencontrez des problèmes à l'exécution
  de SQL Anywhere sur SELinux, différentes possibilités s'offrent à vous :

  o Modifiez l'étiquette des bibliothèques partagées pour en permettre le
    chargement. Si cette solution fonctionne sur Red Hat Enterprise Linux 5,
    elle comporte l'inconvénient de ne pas utiliser les fonctionnalités
    SELinux.
	find $SQLANY16 -name "*.so" | xargs chcon -t textrel_shlib_t 2>/dev/null

  o Installez la stratégie fournie avec SQL Anywhere 16. Vous trouverez des
    sources de stratégie dans le répertoire selinux de votre installation.
    Le fichier README présent dans ce répertoire fournit des instructions de
    construction et d'installation de stratégie.

  o Rédigez votre propre stratégie. Vous pouvez vous servir de celle fournie
    avec SQL Anywhere 16 comme point de départ.

  o Désactivez SELinux :
        /usr/sbin/setenforce 0

o Threads et sémaphores - Les types de thread et de sémaphore utilisés dans
  le logiciel sont assez déterminants dans la mesure où ces ressources peuvent
  s'épuiser sur certains systèmes.

    o Sur Linux, AIX, HP-UX et Mac OS X, SQL Anywhere utilise des threads
      pthreads (threads POSIX) et des sémaphores System V.

      Remarque : Sur les plates-formes qui utilisent des sémaphores System V,
      si l'arrêt du serveur de base de données ou d'une application cliente
      est exécuté par SIGKILL, une perte se produit au niveau des sémaphores
      System V. Vous devez les nettoyer manuellement ceux-ci à l'aide de la
      commande ipcrm. En outre, les applications clientes arrêtées à l'aide
      du système _exit() peuvent également entraîner une telle perte, sauf si
      les bibliothèques clientes SQL Anywhere (comme ODBC et DBLib) sont
      déchargées avant l'appel.

o Gestion des alarmes - Cette fonctionnalité vous concerne uniquement si vous
  développez des applications sans thread et utilisez les gestionnaires
  SIGALRM ou SIGIO.

  SQL Anywhere utilise un gestionnaire SIGALRM et SIGIO pour les clients sans
  thread et démarre une alarme avec signaux répétitifs (toutes les 200 ms).
  Pour un fonctionnement correct, il doit être autorisé à gérer ces signaux.

  Si vous paramétrez un gestionnaire SIGALRM ou SIGIO avant de charger les
  bibliothèques SQL Anywhere, le logiciel enchaîne à partir de ce
  gestionnaire. Si vous paramétrez le gestionnaire après le chargement d'une
  quelconque bibliothèque SQL Anywhere, vous devez enchaîner à partir des
  gestionnaires SQL Anywhere.

  Avec le processus de communication TCP/IP, SQL Anywhere utilise le
  gestionnaire SIGIO pour les clients sans thread uniquement. Celui-ci est
  toujours installé, mais il ne sert que si votre application utilise le
  protocole TCP/IP.

o Sur Red Hat Enterprise Linux, certains caractères d'usage privé ne
  s'affichent pas dans Sybase Central, Interactive SQL (dbisql), le Profileur
  MobiLink, le Moniteur SQL Anywhere et la console SQL Anywhere (dbconsole).

  Concernant les points de code Unicode "U+E844" et "U+E863" (désignés comme
  des caractères d'usage privé), aucun glyphe n'est fourni dans aucune des
  polices TrueType fournies avec la distribution Red Hat Linux. Il s'agit de
  caractères chinois simplifiés disponibles dans la distribution Red Flag
  (Linux en chinois) et qui font partie de la police zysong.ttf
  (DongWen-Song).