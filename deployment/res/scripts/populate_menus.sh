set_parent CAT_DATABASES none
set_parent CAT_SQLANY64 CAT_DATABASES
set_parent CAT_CLIENT_INTERFACES64 CAT_SQLANY64
add_component CAT_CLIENT_INTERFACES64 OPT_ODBC64 64 64 none none none
add_component CAT_CLIENT_INTERFACES64 OPT_ESQL64 64 64 none none none
add_component CAT_CLIENT_INTERFACES64 OPT_JDBC64 64 64 none none none
add_component CAT_CLIENT_INTERFACES64 OPT_DEPLOY_CLIENT_TOOLS64 64 64 none none none
set_parent CAT_SERVER64 CAT_SQLANY64
add_component CAT_SERVER64 OPT_SERVER_PERSONAL64 64 64 none none none
add_component CAT_SERVER64 OPT_SERVER_NETWORK64 64 64 none none none
add_component CAT_SERVER64 OPT_OMNI64 64 64 none none none
add_component CAT_SERVER64 OPT_JAVA_IN_THE_DATABASE64 64 64 none none none
add_component CAT_SERVER64 OPT_EXTDLL64 64 64 none none none
add_component CAT_SERVER64 OPT_SERVER_TOOLS64 64 64 none none none
add_component CAT_SERVER64 OPT_SERVER_UNLOADSUPPORT64 64 64 none none none
set_parent CAT_SQLANY32 CAT_DATABASES
set_parent CAT_CLIENT_INTERFACES32 CAT_SQLANY32
add_component CAT_CLIENT_INTERFACES32 OPT_ODBC32 none none none none none
add_component CAT_CLIENT_INTERFACES32 OPT_ESQL32 none none none none none
add_component CAT_CLIENT_INTERFACES32 OPT_JDBC32 none none none none none
add_component CAT_CLIENT_INTERFACES32 OPT_DEPLOY_CLIENT_TOOLS32 none none none none none
set_parent CAT_SERVER32 CAT_SQLANY32
add_component CAT_SERVER32 OPT_SERVER_PERSONAL32 none none none none none
add_component CAT_SERVER32 OPT_SERVER_NETWORK32 none none none none none
add_component CAT_SERVER32 OPT_OMNI32 none none none none none
add_component CAT_SERVER32 OPT_JAVA_IN_THE_DATABASE32 none none none none none
add_component CAT_SERVER32 OPT_EXTDLL32 none none none none none
add_component CAT_SERVER32 OPT_SERVER_TOOLS32 none none none none none
add_component CAT_SERVER32 OPT_SERVER_UNLOADSUPPORT32 none none none none none
set_parent CAT_ULTRALITE CAT_DATABASES
add_component CAT_ULTRALITE OPT_ULTRALITE64 64 64 none none none
set_parent CAT_SYNCHRONIZATION none
set_parent CAT_MOBILINK64 CAT_SYNCHRONIZATION
add_component CAT_MOBILINK64 OPT_MOBILINK_SQLANY64 64 64 none none none
add_component CAT_MOBILINK64 OPT_ML64 64 64 none none none
set_parent CAT_MOBILINK32 CAT_SYNCHRONIZATION
add_component CAT_MOBILINK32 OPT_MOBILINK_SQLANY32 none none none none none
add_component CAT_SYNCHRONIZATION OPT_DBREMOTE32 none none none none none
add_component CAT_SYNCHRONIZATION OPT_DBREMOTE64 64 64 none none none
set_parent CAT_ADMINTOOLS32 none
set_parent CAT_SYBCENTRAL CAT_ADMINTOOLS32
add_component CAT_SYBCENTRAL OPT_SYBASECENTRAL32 none none none none none
add_component CAT_SYBCENTRAL OPT_SAPLUGIN32 none none none none none
add_component CAT_ADMINTOOLS32 OPT_ISQL32 none none none none none
add_component CAT_ADMINTOOLS32 OPT_DBCONSOLE32 none none none none none
set_parent CAT_ADMINTOOLS64 none
set_parent CAT_SYBCENTRAL CAT_ADMINTOOLS64
add_component CAT_SYBCENTRAL OPT_SYBASECENTRAL64 64 64 none none none
add_component CAT_SYBCENTRAL OPT_SAPLUGIN64 64 64 none none none
add_component CAT_SYBCENTRAL OPT_MLPLUGIN64 64 64 none none none
add_component CAT_SYBCENTRAL OPT_ULPLUGIN64 64 64 none none none
add_component CAT_ADMINTOOLS64 OPT_ISQL64 64 64 none none none
add_component CAT_ADMINTOOLS64 OPT_DBCONSOLE64 64 64 none none none