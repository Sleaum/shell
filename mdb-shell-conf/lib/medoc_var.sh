#!/bin/bash
#
#=======================================================================
# Initialisation environnement MEDOCDB
#=======================================================================
export MDB_VERS_VAR="00.18"

# =======> DEBUT >-- VARIABLES CONNEXION au SERVER API 'medocdbapi'     --------- Version : 00.10 -------
export MDB_PGCNX_SERV="api"         	 	# Methode d'acces aux BDD MEDOCDB : "api" = via API
export MDB_API_HOST="localhost"   	 	# Adresse ou Hostname du server d'API
export MDB_API_PORT="8180"          	 	# Port du server d'API
export MDB_API_CNX_ENABLED="true"      # APPEL API = true|false
# variable récupérées depuis l'api de connexion
export MDB_COULOIR=""
export MDB_ETAT_COULOIR=""
export MDB_DATMAJ=""
export MDB_PGUSER=""
export MDB_PGHOST=""
export MDB_PGPORT=""
export MDB_PGBASE=""
# cf "_api_cnx_test()" => CREATION VARIABLE : MDB_API_CNX="http://${MDB_API_HOST}:${MDB_API_PORT}/medocdbapi"
# =======>  FIN  >-- VARIABLES CONNEXION au SERVER API 'medocdbapi'     --------- Version : 00.10 -------

export MDB_ROOTDIR="/medocdb"
export MDB_USERNAME="medocdb"
#default ROOTDIR set to current directory is  usefull for test 
# Premier niveau de l'arborescence
export MDB_SRC="${MDB_ROOTDIR}/src"
export MDB_APP="${MDB_ROOTDIR}/application"
export MDB_DATA="${MDB_ROOTDIR}/donnees"
export MDB_ETATS="${MDB_DATA}/etats"
#export MDB_TRACES="${MDB_ROOTDIR}/traces" #OLD
export MDB_TRACES="/var/log/medocdb"	   #NEW
export MAP_ROOT="${MDB_ROOTDIR}/map"
export MDB_RPM_CONFIG="/etc/medocdb/conf.d/"

# Deuxieme niveau de l'arborescence APP
export MDB_BATCHS="${MDB_APP}/batchs"
export MDB_SCRIPTS="${MDB_APP}/scripts"
export MDB_SCRIPTS_LIB="${MDB_SCRIPTS}/lib"
export MDB_SHELL_EMAJ="${MDB_SCRIPTS}/emaj"
export MDB_TEST="${MDB_APP}/test"
export MDB_CONFIG="${MDB_APP}/config"
export MDB_VARIABLE="${MDB_APP}/variables"
export MDB_LIB="${MDB_APP}/lib"
export MDB_LIB_ARGOS="${MDB_LIB}/ARGOS"
export MDB_LIB_BELEM="${MDB_LIB}/belem"
export MDB_LIB_COBUTIL="${MDB_LIB}/cobutil"
export MDB_LIB_COB="${MDB_LIB}/cob"
export MDB_LIB_LIBPIVOT="${MDB_LIB}/libpivot"
export MDB_LIB_MICADO="${MDB_LIB}/micado"

# Deuxieme niveau de l'arborescence DATA
export MDB_TMP="${MDB_DATA}/temp"
export MDB_TEMP="${MDB_DATA}/temp"
export MDB_PERM="${MDB_PERM:-${MDB_DATA}/perm}"
export MDB_JCL="${MDB_TEMP}"
export MDB_SORTANTS="${MDB_DATA}/sortants"
export MDB_ENTRANTS="${MDB_DATA}/entrants"

# Deuxieme niveau de l'arborescence TRACES
export MDB_JOB="${MDB_TRACES}/jobs"
export MDB_LOGS="${MDB_TRACES}/logs"	
export MDB_LOG="${MDB_TRACES}/logs"
export MDB_LOG_LEVEL=3                     # Niveau de trace des messages  : <= 7=DEBUG|[6=INFO]|5=NOTICE|4=WARNING|3=ERROR|2=CRITIC|1=ALERT|0=EMERG
export MDB_LOGGER_LEVEL=3                # Niveau de trace via 'loggger' : <    6=INFO ou 7=DEBUG 
export MDB_LOG_LEVEL_MICADO=3
export MDB_BILAN="${MDB_TRACES}/bilan"

# troisieme niveau de l'arborescence TEST
export MDB_TEST_TC="${MDB_TEST}/tc"
export MDB_TEST_TA="${MDB_TEST}/ta"
export MDB_TEST_TBEB="${MDB_TEST}/tbeb"
export MDB_TEST_TESTAUTO="${MDB_TEST}/testauto"

######################################
# Variables qui dcoulent du socle 
######################################
# LD_PRELOAD ne sert que pour les libs de /medocdb/application/lib/belem ; normalement pas utilisé
export LD_PRELOAD="/usr/pgsql-18/lib/libpq.so.5:/usr/lib64/libc.so.6:/medocdb/application/lib/belem/versionBelem.so:/usr/lib64/libsyslog.so"
# MDB_LIB_BELEM n'est pas utilisé, on ne se sert que de MDB_LIB_ARGOS
export LIBRARY_PATH="/usr/pgsql-18/lib:/usr/lib64:${MDB_LIB}:${MDB_LIB_ARGOS}:${MDB_LIB_COBUTIL}:${MDB_LIB_COB}:${MDB_LIB_LIBPIVOT}:${MDB_LIB_MICADO}:/usr/lib:/usr/local/lib"
export LD_LIBRARY_PATH="${LIBRARY_PATH}"
export COB_LIBRARY_PATH="${LIBRARY_PATH}"
export COB_CONFIG_DIR="/opt/gnucobol/share/gnucobol/config/"
export COB_CFLAGS="-I /opt/gnucobol/include/"

######################################
# Variables li�e au domaine
######################################
export MDB_DOM_CONFIG_SOURCE=${MDB_DOM_CONFIG_SOURCE:-LOCAL} 	# API ou LOCAL
export MDB_DOM_CONFIG_URL="http://${MDB_API_HOST}:${MDB_API_PORT}/v2/get_dom_vars"
export MDB_DOM_FIC="${MDB_CONFIG}/dom_config.json"

######################################
# Variables transfo shelletudes et init_fct.sh 
######################################
export V_OP=""
export V_DAT="000000"
export V_CR="0"
export V_LOT="proto"
export V_HOME="$HOME"
export V_ENV="$HOME/fichier"
#
export REP_PERM="${MDB_PERM}"
export REP_TEMP="${MDB_TMP}"
export REP_SYSOUT="${MDB_JOB}"
export REP_LOG="${MDB_LOGS}"
export REP_ARCH="${MDB_PERM}"
#
export REP_SCRIPTS="${MDB_SCRIPTS}"
export REP_BATCHS="$MDB_BATCHS"
export REP_BIN="$MDB_BATCHS"
export REP_PARM="${MDB_VARIABLE}"
#
export V_APPLI="${MDB_SCRIPTS}"
export V_GOTO="CONTINUE"

######################################
# Accs base de donnes
######################################
# export MDB_PGSQL_CONN_STRING="postgresql://medocdb:medocdb@db:5432/medocdb_test"
export PGCLIENTENCODING="ISO_8859_1"

######################################
# ENCODAGE
######################################
export ENCODAGE_CODE="ISO-8859-1"
export ENCODAGE_DONNEES="UTF-8"
export ENCODAGE_DEFAULT="UTF-8"

######################################
# Accs BTW
######################################
export URL_BTW="http://btw.kubemedoc.nubo.dgfip/"
export SUFFIX_REFJDD="rjdd.html"
export SUFFIX_DUMBAU="dumbau.html"
######################################
# Variables pour MiCaDo
######################################
export MICADO_CONFIG_REP="${MDB_CONFIG}"
export MDB_TBREF="${MDB_TBREF:-${MDB_PERM}/pivots/Tables_de_reference}"
export MICADO_LOGS_REP="${MDB_LOGS}"
export MDB_PIVOTS_REP="pivots"
export MDB_PIVOTS_XSD="pivots.xsd"
export MICADO_TABLE_REFERENCE_LIST="R19-ROL-DOC-ANO-ELI-FPJ-JUG-PDF-PEN-PRF-TNC"
export MICADO_LOGS_CONF="logger.conf" 
export MICADO_MODE_COMPARAISON_CLES=COLLATE
export LC_COLLATE=fr_EB.iso88591

######################################
# Variables pour GCSORT
######################################
export REP_GCSORT="/opt/gcsort"
export GCSORT_LOG_CHEMIN="${MDB_LOGS}"
# Variable 'GCSORT' qui sera utilisée par la fonction publique "exec_sort()"
export GCSORT=${GCSORT:-"/opt/gcsort/gcsort -fcolseq=EBCDIC -febcdic-table=ebcdic500_latin1 "}
export GCSORT_DEBUG=${GCSORT_DEBUG:-0}                  # 0 no print info, 1 info DEBUG, 2 for info Parser
export GCSORT_BYTEORDER=${GCSORT_BYTEORDER:-0}          # 0 for Native or 1 for BigEndian
export GCSORT_MEMSIZE=${GCSORT_MEMSIZE:-1024000000}     # Memory Allocation in byte (Default 512000000 byte)
export GCSORT_STATISTICS=${GCSORT_STATISTICS:-1}        # 0 minimal informations, 1 for Summary, 2 for Details
export GCSORT_PATHTMP=${REP_GCSORT:-/opt/gcsort}	# Pathname for temporary files  # (Default TMP / TEMP / TMPDIR)
export GCSORT_TESTCMD=${GCSORT_TESTCMD:-0}              # 0 for normal operations , 1 for ONLY test command line (NO SORT)

######################################
# Variables pour mode DEBUG 
######################################
 
export V_DEBUG="normal"				# possible values [normal|debug|dump|valgrind] 
if ! [[ ${V_DEBUG} == "normal" || -z ${V_DEBUG} ]]; then
# if mode debug|dump|valgrind is set,change dir for rpm-debug
export MDB_BATCHS="${MDB_ROOTDIR}/application-debug/batchs"
export MDB_LIB_COB="${MDB_ROOTDIR}/application-debug/lib/cob"
export MDB_SRC="${MDB_ROOTDIR}/application-debug/code"
fi

######################################
# Variable Test
######################################
export CAT_LOG="TRUE"

######################################
# Variables repertoire des tests auto
######################################
export MDB_REP_TC_LIBPIVOT="${MDB_TEST_TC}/libpivot"
export MDB_REP_TC_MICADO="${MDB_TEST_TC}/micado"
export MDB_REP_TC_COBUTIL="${MDB_TEST_TC}/cobutil"
export MDB_REP_TC_COB="${MDB_TEST_TC}/cob"
export MDB_REP_TC_SHELLETUDES="${MDB_TEST_TC}/shelletudes"
export MDB_REP_TC_BDD="${MDB_TEST_TC}/bdd"
export MDB_REP_TC_PIVOTSTRUCTURE="${MDB_TEST_TC}/pivotstructure"
export MDB_REP_TC_PIVOTDONNEES="${MDB_TEST_TC}/pivotdonnees"
export MDB_REP_TC_BELEM="${MDB_TEST_TC}/belem"

export MDB_REP_TA_MICADO_BDD="${MDB_TEST_TA}/micado_bdd"
export MDB_REP_TA_GCSORT_FIC="${MDB_TEST_TA}/gcsort_fic"
export MDB_REP_TA_SHELLETUDES_COB="${MDB_TEST_TA}/shelletudes_cob"
export MDB_REP_TA_COB_COBUTIL="${MDB_TEST_TA}/cob_cobutil"
export MDB_REP_TA_COB_FIC="${MDB_TEST_TA}/cob_fic"

export  MDB_REP_SCRIPTS_AUTO="${MDB_TEST_TESTAUTO}/scripts_auto"

######################################
# Organisation
######################################


######################################
# PATH
######################################
export PATH="${PATH}:/opt/gnucobol/bin:${REP_GCSORT}"

######################################
# rpm de conf
######################################
if [ -d ${MDB_RPM_CONFIG} ]; then
  for conf in $(ls ${MDB_RPM_CONFIG}); do
      source /etc/medocdb/conf.d/${conf}
  done
fi

# echo "----------- fin medoc_var.fct - Version:$MDB_VERS_VAR -----------------"
