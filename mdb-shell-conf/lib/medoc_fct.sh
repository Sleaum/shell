#!/usr/bin/bash

# ---------------------------------------------------------------------------------------------------------------
#  Nom                   : medoc_fct.sh
#  Création              : 06 fevrier 2023 - Serge Corgnet
#  Auteur                : DGFiP - Tristana
#  Version de la SFG     : 0.1
#  Appel dans les JOBs   : . ${MDB_SCRIPTS_LIB}/medoc_var.sh    # variables medocdb globales
#     + fichier          : . ${MDB_SCRIPTS_LIB}/medoc_fct.sh    # fonctions medocdb "dgfip" compatible "Tristana"
#     + fichier          : . ${MDB_SCRIPTS_LIB}/medoc_log.sh    # fonctions medocdb "log" des variables
# ---------------------------------------------------------------------------------------------------------------
#  Fonctions "PUBLIQUES" : APPELABLES PAR LES JOBs MEDOC-DB
#   -- nom_fonction()    : ------ libelle de la fonction  --------------: ------ appel de la fonction avec les arguments et parametres -------
#     exec_prog          : execution d'un programme COBOL               : exec_prog -p prog_name [-i ${INPUT}] # parametre(s) lu(s) par 'ACCEPT'
#     exec_sort          : Tri|Fusion de 1 à n Fichier(s) GCSORT        : exec_sort -i "$IF1 opt;...;$IFn opt" -o "$OF" -p "GCSORT commandes"
#     exec_sql           : execution d'un script SQL/PLPGSQL            : exec_sql -f "$SQLINF" -o "$SQLOUF" [-p "psqlOptions"]
#     file_exist         : Controle exitence d'un fichier               : file_exist "$FILE" "[f]|d" # f=fichier par defaut | d=directory/repertoire
#     file_assign        : Assignation "$IFN" "$EFN"                    : file_assign "$IFN" "$EFN"
#     file_assign_2      : Assignation|Creation fichier ou directory    : file_assign_2 "$IFN" "$EFN" "[]|CREATE" "[f]|d"
#     file_cat           : Concaténation fichier(s) dans 1 fichier      : file_cat -i "$IF1,...$IFn" -o "$OF" -p "Options cat"
#     file_copy          : copie d'un fichier vers 1 fichier            : file_copy -i "$IF1" -o "$OF" -p "Options cp"
#     file_rename        : Renommer un fichier                          : file_rename -i "$IF1" -o "$OF" -p "Options mv"
#     file_delete        : Suppression d'un fichier ou directory        : file_delete -o "$OF" -p "Options rm"
#     file_clear         : Suppression du contenu d'un fichier          : file_clear -o "$OF"
#     mdb_api_cnx        : API de restitution des infos de cnx BDD      : mdb_api_cnx -b "MAJ|LECT" -c "couloir" -i GEO|NAT|BEL
#     mdb_api_get        : API de consultation couloir(s) d’exécution   : mdb_api_get [ -c "couloir" -e "ESI" -t "TDS" -d "DOMAINE" ]
#     mdb_api_patch      : API de mise à jour couloir(s) d’exécution    : mdb_api_patch -c "couloir" -e "etat" -d "datmaj" -m "message" -o "BATCH|ADAME"
#     msg                : Ecriture de message dans la log              : msg "libelle du message" n (n="niveau":7=DEBUG|[6=INFO]|5=NOTICE|4=WARNING|3=ERROR|2=CRITICAL|1=ALERT|0=EMERG)
#     deb_job            : initialisation JOB                           :
#     fin_job            : sortie du JOB                                :
#     phase              : debut phase                                  :
#     endphase           : fin phase + Determine le CR_MAX              : _cr_max $SEV
#     step               : debut d'etape + temps debut exec             : step typ_prg
#     endstep            : fin d'etape   + temps  fin  exec + duree     : endstep typ_prg
#     load_dom_config    : Valorisation des variables li�e au domaine d'execution
#     gestion_exit_ops   : Retourne 1 à l’ordonnanceur si la phase retourne une sévérité non nulle
# ---------------------------------------------------------------------------------------------------------------
#  Fonctions "PRIVEES"   : Fonctions "internes" aux FONCTIONS PUBLIQUES: Le nom des fonctions est préfixé par '_'
#                        : --------------------------------------------------------------------------------------
#    _0_fct_init         : Assignation du Tableau Associatif Fonctions Publiques|Privées
#    _0_var_init         : Assignation de variables GLOBALES necessaires aux Fonctions Publiques|Privées
# Fonctions Grpt Deb *** : -------- Potentiellement à revoir ! --------------------------------------------------
#    _path_prog          : chemin programme cobol                        _path_prog nom du programme, mode debug ( ? voir Grpt )
#    _analyze_args       : Valorisation variable                         _analyze_args variable, valeur si vrai, argument à rechercher, liste des variables ( ? voir Grpt )
# Fonctions Grpt Fin *** : --------------------------------------------------------------------------------------
#    _fct_medoc_init     : Initialisation JOBs MedocDb.                 cf:deb_job
#    _fct_medoc_fini     : Finalisation   JOBs MedocDb                  cf:fin_job
#    _fct_is_exec        : Indique si 1 Fonction est executable ou pas. cf:FCT_EXEC
#    _fct_exec           : Excecution des commandES des Fonctions Publiques + Analyse code retour, Gestion des erreurs, ...
#    _fct_err            : Erreur d'appel d'une fonction avec parametres
#    _fic_in_out         : Controle fichier entrée doit etre different fichier sortie : SEV=3
#    _fic_ctrl           : Controle si le Nom du fichier est bien renseigné
#    _cpt_lig            : Comptage du nombre de ligne d'un fichier entrée ou sortie
#    _continue_false     : Positionne CONTINUE à "false" pour FORCER l'arret du JOB BATCH !
#    _cr_test            : Controle  du code retour des Fonctions
#    _cr_max             : On conserve le code retour CR_MAX & NIV_MSG le plus élévé du JOB
#    _max_min            : Renvoi la valeur la "maxi" ou "mini" entre plusieurs variables
#    _msg                : MDB_LOG_LEVEL=1 + Preparations affichage des libellés
#    _msg_op             : Emmission message $V_OP                      cf:_msg_op "texte du message" + ecriture dans un fichier "Operateur $V_OP" ( ? voir Grpt )
#    _time_exec          : Calcul du Temps d'Execution entre 'debut' et 'fin' de STEP
#    _trim               : Suppression des espaces AVANT et APRES d'une variable
#    _date_utc           : Generation d'une date format : ISO-8601 UTC
#    _api_exec           : Execution d'une API via curl
#    _api_parser         : Parser json : "jq"  normalement installé sur le server Linux
#    _api_cnx_test       : Test Connexion server API 'medocdbapi'       cf: _bdd_cnx
#    _bdd_cnx            : Connexion à la base de donnée MedocDb        cf:_fct_medoc_init
#    _bdd_pwd            : Password connexion base de données MedocDb   cf:_fct_medoc_init
#    _bdd_opt            : Chargement des Options "psql"                cf:_fct_medoc_init
#    _bdd_dcnx           : Deconnexion de la base de données MedocDb    cf:_fct_medoc_fini
# ---------------------------------------------------------------------------------------------------------------
# Evolution/modification :Version:--  date  --:-qui-:------------ libelle -----------------------------------------------
#  LIST_IFN_REP          : 00.00 : 2023/03/10 : SCO : gestion repertoire -> file_exist, file_assign
#  exec_sql              : 00.01 : 2023/03/22 : SCO : execution script SQL  (cf: _bdd_cnx|_bdd_pwd|_bdd_opt|_bdd_dcnx)
#  FCT_EXEC_LIST         : 00.02 : 2023/05/16 : SCO : Test existence du tableau "FCT_EXEC" AVANT valorisation (cf:medocdb_scripts_exec.sh)
# _cpt_lig               : 00.03 : 2023/05/30 : SCO : Compter le nombre de lignes dans les fichiers
# _time_exec             : 00.04 : 2023/06/06 : SCO : Calcul Temps d'execution ( + statistiques 'time' cf:TIME_EXE )
#  deb_job               : 00.05 : 2023/06/26 : SCO : Sourcer les variables de configuration du JOB autres que VTOM
# _fic_ctrl|_fic_in_out  : 00.06 : 2023/07/20 : SCO : Controle la bonne valorisation des fichiers entrées/sorties des Fonctions Publiques
# _fic_log               : 00.07 : 2023/08/08 : SCO : Construction du Nom du Fichier de Log selon le type de programme
# _msg | msg             : 00.08 : 2023/08/30 : SCO : Gestion niveau message idem 'rsyslog' : 7=DEBUG|[6=INFO]|5=NOTICE|4=WARNING|3=ERROR|2=CRITIC|1=ALERT|0=EMERG
# _path_prog | _fct_exec : 00.09 : 2025/02/03 : SCO : PRE_GNR_VUE = Gestion des "shells de génération des vues"
#  deb_job | fin_job     : 00.09 : 2025/02/05 : AOM : Abderraouf OMari : Nouvelle GESTION DES LOGS au format JSON 'logger/rsyslog'
# mdb_api_xxx |_api_xxx  : 00.10 : 2025/02/10 : SCO : Fonctions de gestions des BdD MedocDB via API's
# _0_var_init            : 00.10 : 2025/02/10 : SCO : Declaration des variables GLOBALES de gestion BDD medocdb via API's
#                        : 00.11 : 2025/02/14 : SCO : Suppression _fic_log : les logs sont gérées via logger/rsylog cf JSON_RSYSLOG
#                        : 00.11 : 2025/02/14 : SCO : Suppression file_assign_2 : cf file_assign ( simplifié )
# mdb_api_patch          : 00.11 : 2025/02/17 : SCO : Passage des parametres à mettre à jour via "body"  | api "couloirs/cxx"  et non pas "couloirs?cxx"
# mdb_api_patch|_get     : 00.11 : 2025/02/17 : SCO : l'appel à l'api = "couloirs/cxx"  et non pas "couloirs?cxx"
#                        : 00.12 : 2025/02/19 : SCO : Evolutions "technico-fonctionnelles" cf : D. Ackerman
# step                   : 00.12 : 2025/02/19 : SCO :  - mise en commentaire de l'appel "mdb_api_get" ( On ne teste plus l'etat de la base )
# mdb_api_cnx|get|       : 00.12 : 2025/02/19 : SCO :  - execution seulement si la variable MDB_MICADO_PGSQL_CONN_STRING ou MDB_API_GET_ETAT n'existent pas déjà ( ex: VTOM charge ces variables d'environnement par exemple )
# pre_/post_{JOBNAME}    : 00.13 : 2025/02/27 : SGE : Lancement de scripts dans deb_job et fin_job s’ils existent
# _api_exec		 : 00.14 : 2025/04/07 : AOM : Mise en oeuvre "fonctions executables ou non"  pour les fonctions API
# exec_sort		 : 00.15 : 2025/05/20 : AOM : Ajouter une condition "_fct_is_exec" = "true", pour l'execution de gcsort, par defaut=true
# load_dom_config        : 00.17 : 2025/10/09 : AOM : Ajouter une fonction pour recuperer les variables liee au domaine d'execution
# deb_job                : 00.18 : 2026/03/20 : SGS : Debug api de connexion 
# gestion_exit_ops       : 00.19 : 2026/04/27 : SGS : Retourne 1 à l’ordonnanceur si la phase retourne une sévérité non nulle
# exec_sprog             : 00.20 : 2026/06/24 : SGS : fork de exec_prog pour les sous programmes
# --------------------------------------------------------------------------------------------------------------
#
# MDB_VERS_FCT est la variable qui gere la VERSION du module "medoc_fct.sh" : A MAINTENIR A CHAQUE EVOLUTION sous la forme MAJEURE.mineure
#    -) 00.nn VERSION EN COURS DE DEVELOPPEMENT
#    -) 01.00 SERA LA PREMIERE VERSION MISE EN PRODUCTION
#    -) deb_job() affichera le message avec les versions des modules: medoc_fct.sh, medoc_var.sh
MDB_VERS_FCT="00.20"
# ---------------------------------------------------------------------------------------------------------------

# ======================================================================
# Variables GLOBALES 'medoc_fct' pour suivi execution JOBs MEDOCDB
# NB : _msg() valorise 3 variables pour la gestion des logs
# _0_fct_init,_0_var_init et _msg sont appelé par deb_job()
# ======================================================================

# ----------------------------------------------------------------------
# Variables GLOBALES de niveau "JOB" en dehors des fonctions !!
# ----------------------------------------------------------------------

# Récupération Parametres Execution du JOB (ex: MDCBC90X.sh -debug) ( ? voir Grpt )
JOB_PARAM_EXEC="$@" # "-debug" par exemple ( cf _analyze_args ou exec_prog )
[[ $MDB_LOG_LEVEL = 7 ]] && echo "JOB_PARAM_EXEC=$JOB_PARAM_EXEC" # DEBUG

# ---------------------------------------------------------------------
# Definit un TABLEAU des Fonctions EXECUTABLES" ou PAS (cf deb_job)
# ---------------------------------------------------------------------
_0_fct_init() {
    declare fct_name=${FUNCNAME[0]}
    msg "$fct_name:Debut execution" 7 # DEBUG

    # FCT_EXEC = Tableau associatif des fonctions Publiques ( et certaines "Privées" )
    #  Objet   = Autorise (true) ou pas(false) l'execution des fonctions
    #     NB1  = Ne peut pas etre dans la fonction "_0_var_init", sinon FCT_EXEC serait LOCALE à la fonction par le 'declare -A' !
    #     NB2  : Toute fonction "DEBRAYABLE" n'ayant pas une valeaur à 'true' sera considérée comme 'false' !
    #          :  => Chercher les appels à '_fct_is_exec' pour trouver les fonctions concernées ( normalement, la liste ci_dessous est complète )
    #     NB3  : Afin de pouvoir tester les scripts Medoc_db SANS les executer réellement, on peut forcer à "false" (= 'non execution') des fonctions !
    #     NB4  : Si FCT_EXEC_LIST existe, on crée le tableau FCT_EXEC avec ces valeurs de FCT_EXEC_LIST ! : 2023/05/16 cf medocdb_scripts_exec.sh
    #
    declare -gA FCT_EXEC= # -g=GLOBAL -A=ASSOCIATIF
    if [[ ! -v FCT_EXEC_LIST ]] ; then  # test existence variable "FCT_EXEC_LIST", car un tableau ne peut pas etre "EXPORTÉ" ! 2023/05/16
      FCT_EXEC=(
        [file_exist]=true
        [file_assign]=true
        [exec_prog]=true
        [_path_prog]=true # NB : appelé dans "exec_prog", mais AVANT l'execution du programme COBOL !!
        [exec_sort]=true
        #[exec_sql]=true
        [file_cat]=true
        [file_copy]=true
        [file_rename]=true
        [file_delete]=true
        [file_clear]=true
        # Fonctions PRIVEES "spéciales" à mettre à 'true' en DEV|IA|INTEX et eventuellement 'false' en PROD ( 05/2023: A voir selon la methode de cnx BdD qui sera définie )
        [_bdd_cnx]=${MDB_API_CNX_ENABLED}	     # APPEL API = true|false
        [_bdd_dcnx]=true
        [_bdd_pwd]=true
        [_bdd_opt]=true
	[_api_exec]=${MDB_API_CNX_ENABLED}           # APPEL API = true|false
      )
    # FCT_EXEC_LIST existe et contient la liste des fonctions à executer ou pas ! 2023/05/16
    #  => Déclaration du tableau FCT_EXEC avec les valeurs présentent dans "FCT_EXEC_LIST=$(declare -p FCT_EXEC)"
    #  cf: "medocdb_scripts_exec.sh" = lancer tous les scripts medocdb MAIS les FONCTIONS sont "débrayées" => N'EXECUTENT PAS les FONCTIONS=false !
    else
        eval $FCT_EXEC_LIST
    fi

    msg "$fct_name:Fin execution" 7 # DEBUG
}

# ---------------------------------------------------------------------
# variables GLOBALES utiles aux Fonctions medocdb (cf _fct_medoc_init )
# appel : _0_var_init
# ---------------------------------------------------------------------
_0_var_init() {
    declare fct_name=${FUNCNAME[0]}
    msg "$fct_name:Debut execution" 7 # DEBUG

    # =======> DEBUT >-- VARIABLES liee au domaine d'execution --------- Version : 00.17 --------

    if [[ ! -z ${EQAMMDOM} ]]; then
        load_dom_config ${EQAMMDOM}
    fi

    # Gestion des erreurs d'une phase
    SEV=0;
    # Code retour le plus élevé du JOB en cas d'erreur dans les phases
    CR_MAX=0
    # Si Code retour < à la valeur MAX => Traitement est OK -> SEV=0
    CR_MAX_COB=7    # Code Retour Max Cobol  : 0 (ok) - 7 (warning) - 8> (error)
    CR_MAX_SRT=4    # Code Retour Max Gcsort : 0 (ok) - 4 (warning) - 16 (error)
    CR_MAX_SQL=0    # Code Retour Max PgSql  : 0 (ok) - 1 (error)   - 3  (error)
    CR_MAX_SHL=1    # Code Retour Max Shell  : 0 (ok) - 1 (warning) - 3  (error)
    CR_MAX_JOB=1    # Code Retour Max Job    : 0 (ok) - 1 (warning) - 3  (error)
    msg "$fct_name:MDB_LOG_LEVEL=$NIV_MSG:Code retour MAX:CR_MAX_JOB=$CR_MAX_JOB:CR_MAX_COB=$CR_MAX_COB:CR_MAX_SRT=$CR_MAX_SRT:CR_MAX_SQL=$CR_MAX_SQL:CR_MAX_SHL=$CR_MAX_SHL:SEV=$SEV" 5 # NOTICE

    # cf "_cr_test" : Type Erreur à rechercher dans la log si Code Retour > 0
    # MDB_ERR_LOG=Liste de mots-clés à rechercher selon les programmes :
    #     BASH(ERROR|FATAL|CRITIC)/COBOL(ABORT)/GCSORT(DATAERR)/PSQL(failed,échoué,refusé,FATAL)
    MDB_ERR_LOG="ANORMALE|ERROR|FATAL|CRITIC|ABORT|DATAERR|refusé|échoué|failed"
    msg "$fct_name:Type Erreur à rechercher dans la log si Code Retour > 0 :$MDB_ERR_LOG:" 5 # NOTICE

    # cf "_time_exec" : "/usr/bin/time ( ou \time)" : permet de recuperer les informations systemes :  temps utilisateur, systeme, %CPU, MemKb, ..
    TIME_LOG=`mktemp ${MDB_TEMP}/XXXXXXXXXX_time.exec`;  > ${TIME_LOG}
    trap "rm -f $TIME_LOG" EXIT  # Suppression du fichier en fin de JOB
    TIME_EXE=${TIME_EXE:-"/usr/bin/time -o ${TIME_LOG} -pf '%C:user=%U:sys=%S:CPU=%P:MEM=%Kkb:swap=%W:RC=%x'"}
    msg "Statistiques Job:TIME_EXE=${TIME_EXE:-NON}:" # INFO

    msg "$fct_name:Fin execution" 7 # DEBUG
}


# ======================================================================
#  Fonctions "PUBLIQUES" : APPELABLES PAR LES JOB MedocDb
# ======================================================================

# ----------------------------------------------------------------------
# EXECUTION d'un Programme COBOL
# Appel  : exec_prog -p "prog_name" [-i "${Param File}"]
# Retour : SEV
# ----------------------------------------------------------------------
exec_prog() {
    declare fct_name=${FUNCNAME[0]}
    declare fct_parent=${FUNCNAME[1]}

    #Check if exec_prog is enabled (added for tir_a_blanc tests)   # AOM
    ! _fct_is_exec $fct_name && return                             # AOM Default=true

    msg "$fct_name:Debut execution:$*" 7 # DEBUG

    # Analyse des parametres et arguments passés
    unset OPTIND # Obligatoire pour réentrance
    while getopts :p:i:h param; do
        case $param in
            p) declare prog_name=${OPTARG} ;;
            i) declare parm_file=${OPTARG} ;;
            h) msg "$fct_name -p ProgCobol -i InputFile " ;;
            *) _fct_err "$*"; return $SEV ;;
        esac
    done

    declare msg_lib="$fct_name:-p $prog_name:-i $parm_file"
    msg "$msg_lib"  # INFO

    # Parametre(s) "INPUT" optionnel
    if file_exist "$parm_file" ; then
        msg "Parametre(s) INPUT $parm_file :"      # INFO
        cat ${parm_file}; parm_file="< $parm_file"
    fi

    # Alimente COB_SET_DEBUG à Y si '-debug' fait partie des arguments      # SCO : Je ne vois pas en quoi cela change qqchose !!
    _analyze_args 'COB_SET_DEBUG' 'Y' '-debug' "${JOB_PARAM_EXEC}"          # SCO : JOB_PARAM_EXEC contient les arguments passés au JOB shell

    # Recherche chemin/executable du programme : ${PROG_PATH} + PRE_GNR_VUE
    _path_prog ${prog_name} ${COB_SET_DEBUG}                                # SCO : V_DEBUG_PROG n'existe pas !!

    # Si exécutable COBOL est trouvé
    declare cmd_exec=
    [[ $SEV -eq 0 ]] && { # Test code retour "_path_prog"

        export COB_SET_DEBUG="Y"; # Vrai, si V_DEBUG=[debug|dump|valgrind]  # SCO : set COB_SET_DEBUG="Y" si mode 'debug' ( en quoi c'est different du 'analyzeArgs' ??)
        case ${V_DEBUG} in                                                  # SCO : d'où vient V_DEBUG ? export V_DEBUG="debug" dans le terminal ?
        debug)
            msg "$fct_parent:DEBUG gdb debug" 7 # DEBUG
            cmd_exec="gdb -q -d ${MDB_SRC} --args ${PROG_PATH} ${parm_file}"  ;;
        dump)
            msg "$fct_parent:DEBUG gdb dump" 7 # DEBUG
            cmd_exec="gdb -q -batch -ex \"run\" -ex \"bt\" -d ${MDB_SRC} --args ${PROG_PATH} ${parm_file} "  ;;
        valgrind)
            msg "$fct_parent:DEBUG Valgrind $*" 7 # DEBUG
            cmd_exec="/usr/bin/valgrind --leak-check=full --show-leak-kinds=all --track-origins=yes --verbose \"${cmd_exec}\" "  ;;
        *|normal) # execution normale
            unset COB_SET_DEBUG
            msg "$fct_parent:DEBUG normal" 7 # DEBUG
            cmd_exec="${PROG_PATH} ${parm_file}"  ;;
        esac


        # Execution de la commande générée ci-dessus + eventuellement précédé de PRE_GNR_VUE
        _fct_exec -n "COBOL" -c "${cmd_exec:-NULL}" -l "Execution programme COBOL ${cmd_exec}" -r ${CR_MAX_COB}
        # SEV=$? # Inutile car Variable GLOBALE
    }

    msg "$fct_name:Fin execution:$msg_lib:SEV=$SEV" 7 # DEBUG
    return $SEV
}

# ----------------------------------------------------------------------
# EXECUTION d'un Programme COBOL
# Appel  : exec_prog -p "prog_name" [-i "${Param File}"]
# Retour : SEV
# ----------------------------------------------------------------------
exec_sprog() {
    declare fct_name=${FUNCNAME[0]}
    declare fct_parent=${FUNCNAME[1]}

    #Check if exec_prog is enabled (added for tir_a_blanc tests)   # AOM
    ! _fct_is_exec $fct_name && return                             # AOM Default=true

    msg "$fct_name:Debut execution:$*" 7 # DEBUG

    # Analyse des parametres et arguments passés
    unset OPTIND # Obligatoire pour réentrance
    while getopts :p:i:h param; do
        case $param in
            p) declare prog_name=${OPTARG} ;;
            i) declare parm_file=${OPTARG} ;;
            h) msg "$fct_name -p ProgCobol -i InputFile " ;;
            *) _fct_err "$*"; return $SEV ;;
        esac
    done

    # gestion de la variables d'environnement MDB_MICADO_VUES
    # on recherche le fichier temporaire le plus récent généré par le script pre_<PROG>.sh
    fichier_vues_micado=$(ls -t ${MDB_TMP}/vuesMicado_${prog_name}_${EQAMMDOM}* 2>/dev/null | head -n 1)
    # si il existe, MDB_MICADO_VUES vaut son chemin, sinon MDB_MICADO_VUES est vide
    export MDB_MICADO_VUES=${fichier_vues_micado}
    
#    (MDCHA10 MDCHJ10 MDCHM10 MDGSS40 MDGSS50 CEERI36 CEERI53 SFECA69 SFECA79 SFECB10 SFECB50 SFEFT39 SFEFT59 MDUEIFI MDGAV87 MDIEH50 MDRQM45 MDIEJ20)
#    RG:Q2:1 et RG:EXPL:3 ne servent plus à rien sous GNU/Linux
    FIC_LOG_COB=${MDB_LOG}/_tmp_cob_${JOBNAME}_$(date +'%Y%m').log
    if [[ -n ${parm_file} ]]; then
        ${MDB_BATCHS}/${prog_name} RG:Q2:1 < ${parm_file} | tee -a $FIC_LOG_COB | xargs -0 -I{} -d\\n -n1 bash -c 'echo "{}";logger -t $JOBNAME --msgid ${MDB_CORRELATION_ID} -i --rfc5424 --sd-id medoc@1 --sd-param composant=\"COB\" --sd-param log_level=\"${log_level}\" --sd-param domaine=\"${EQAMMDOM}\" --sd-param etape=\"$ETAPE\" --sd-param location=\"${MACH}\" --sd-param dateJC=\"$EQAAMMJJ\" --sd-param table=\"ND\" --sd-param fichier=\"ND\" --sd-param service=\"ND\" --sd-param id_dossier=\"ND\" --sd-param classe=\"ND\" --sd-param objet=\"ND\" "{}"'
    else
        ${MDB_BATCHS}/${prog_name} RG:EXPL:3 | tee -a $FIC_LOG_COB | xargs -0 -I{} -d\\n -n1 bash -c 'echo "{}";logger -t $JOBNAME --msgid ${MDB_CORRELATION_ID} -i --rfc5424 --sd-id medoc@1 --sd-param composant=\"COB\" --sd-param log_level=\"${log_level}\" --sd-param domaine=\"${EQAMMDOM}\" --sd-param etape=\"$ETAPE\" --sd-param location=\"${MACH}\" --sd-param dateJC=\"$EQAAMMJJ\" --sd-param table=\"ND\" --sd-param fichier=\"ND\" --sd-param service=\"ND\" --sd-param id_dossier=\"ND\" --sd-param classe=\"ND\" --sd-param objet=\"ND\" "{}"'
    fi
    SEV=${PIPESTATUS[0]}

    rm -rf ${FIC_LOG_COB} # AOM suppresion du fichier FIC_LOG_COB temporaire

    # on supprime la variable d'env MDB_MICADO_VUES après l'exécution du programme
    unset $MDB_MICADO_VUES

    msg "$fct_name:Fin execution:$msg_lib:SEV=$SEV"  # INFO
    return $SEV
}

# ----------------------------------------------------------------------
# Fonction d'appel du GCSORT GnuCobol
# Separateur des fichiers est ';' car il peut y avoir ',' dans les ordres GCSORT !!
# Appel  : exec_sort -i "$IF1 opt ;$IF2 ...;$IFn opt" -o "$OF" -p "$SORT cmmand"
# Retour : SEV
# ----------------------------------------------------------------------

exec_sort() {
    #declare fct_name="GCSORT"
    declare fct_name=${FUNCNAME[0]} #GCSORT

    #Check if GCsort is enabled (added for tir_a_blanc tests)	# AOM
    ! _fct_is_exec $fct_name && return        			# AOM Default=true

    msg "$fct_name:Debut execution" 7 # DEBUG
    FIC_LOG_GC=${MDB_LOG}/_tmp_${JOBNAME}_$(date +'%Y%m').log

    [[ "$(which gcsort)" = "" ]] && { # Controle existence binaire GCSORT
            SEV=4; # SYSTEM ERROR
            msg "$GCSORT NON INSTALLÉ SUR CE SERVER !" 2 # CRITICAL
            _cr_max $SEV # On conserve le code retour le plus élévé
            return $SEV
        }

    # Execution GCSORT + Forward OUTPUT to rsyslog
    ${GCSORT} "$@" 2>&1 | tee -a $FIC_LOG_GC | xargs -0 -I{} -d\\n -n1 bash -c 'echo "{}";logger -t $JOBNAME --msgid ${MDB_CORRELATION_ID} -i --rfc5424 --sd-id medoc@1 --sd-param composant=\"GCSORT\" --sd-param log_level=\"INFO\" --sd-param domaine=\"${EQAMMDOM}\" --sd-param etape=\"$ETAPE\" --sd-param location=\"${MACH}\" --sd-param dateJC=\"$EQAAMMJJ\" --sd-param table=\"ND\" --sd-param fichier=\"ND\" --sd-param service=\"ND\" --sd-param id_dossier=\"ND\" --sd-param classe=\"ND\" --sd-param objet=\"ND\" "{}"'
    SEV=${PIPESTATUS[0]}

    rm -rf ${FIC_LOG_GC} # AOM suppresion du fichier FIC_LOG_GC temporaire

    msg "$fct_name:Fin execution:$msg_lib:SEV=$SEV"  # INFO
    return $SEV
}


# ----------------------------------------------------------------------
# Fonction test existence fichier[f] non vide(s) ou repertoire(d)
# $1 = efn
# $2 = type file = [f]|s : file ou d : directory
# Appel  : if file_exist ${efn} "f" ;then msg "$efn existe"
# Retour : true(0) ou false(1)
# ----------------------------------------------------------------------
file_exist() {
    declare fct_name=${FUNCNAME[0]}
    msg "$fct_name:Debut execution:$*" 7 # DEBUG

    declare file_name=${1:-/fileDoesNotExists}
    declare type_file=${2:-"f"} # type = "fichier" par defaut
    msg "$fct_name:file_name=${file_name}:type_file=-${type_file}" 7 # DEBUG

    ! _fct_is_exec $fct_name && return # Test si fonction est "executable"
    # Controle type de fichier ou repertoire
    [[ ! ${type_file} =~ ^(f|s|d)$ ]] && { msg "$fct_name: parametre 2 invalide = ${type_file} au lieu de [f|s|d] " 3; return false ; } # ERROR

    # Test existence fichier ou repertoire => retourne 0=true ou 1=false
    [ -${type_file} ${file_name} ] # pour retourner 0 ou 1 !!
    case $? in 0) true ;; 1) false ;; esac
}

# ----------------------------------------------------------------------
# Fonction d'Assignation de fichier ( simplification de file_assign_2 )
# $1 = ifn
# $2 = efn
# Appel  : file_assign <IFNAME> <PHYSICAL_FILE>
# ----------------------------------------------------------------------
file_assign() {
    declare fct_name=${FUNCNAME[0]}
    msg "$fct_name:Debut execution:$*" 7 # DEBUG

    declare ifn=$1              # Internal FileName Cobol|Utilitaire
    declare efn=$2              # External FileName/repertoire Linux
    # Verification de la bonne valorisation des parametres
    [[ -z ${ifn} ]] && { _fct_err "$*"; return $SEV ; }
    [[ -z ${efn} ]] && { _fct_err "$*"; return $SEV ; }

    declare msg_lib="$fct_name:export $ifn=$efn"

    export ${ifn}=${efn}
    msg "${msg_lib}" 7 # DEBUG
}

# ----------------------------------------------------------------------
# Fonction de concatenation de fichiers APRES le contenu fichier sortie
# Appel  : file_cat -i "$IF1,$IF2,.,$IFn -o $OF" -p "cat Options"
# Retour : SEV
# ----------------------------------------------------------------------
file_cat() {
    declare fct_name=${FUNCNAME[0]}
    msg "$fct_name:Debut execution:$*" 7 # DEBUG

    # Analyse des parametres et arguments passés
    unset OPTIND # Obligatoire pour réentrance
    while getopts :i:o:p:h param; do
        case $param in
            i) declare infiles=${OPTARG} ;;
            o) declare outfile=${OPTARG} ;;
            p) declare options=${OPTARG} ;;
            h) msg "$fct_name -i \"infile\" -o \"outfile\" -p \"options\" " ;;
            *) _fct_err "$*"; return $SEV ;;
        esac
    done

    declare msg_lib="$fct_name:-i ${infiles}:-o ${outfile}::-p $options:"
    msg "$msg_lib"  # INFO

    # Controle si fichier entrée renseigné : est une liste donc controle dans la boucle ci-dessous
    # Controle si fichier sortie renseigné et valide ! => SEV = 3 si non OK
    _fic_ctrl ${outfile} "sortie"
    SEV=$?

    declare cmd_exec=
    # Analyse infile(s)
    IFS=","
    [[ $SEV -eq 0 ]]  && {
        for infile in $infiles
        do
            infile=$(_trim ${infile})
            [[ -n $infile ]] && {
                msg "$fct_name:trt du Fichier entrée : [$infile]" 7 # DEBUG
                # Controle fichier entree <> sortie
                if _fic_ctrl ${infile}  &&  _fic_in_out ${infile} ${outfile} ; then
                    # Preparation commande à executer
                    cmd_exec="$cmd_exec $infile"
                    _cpt_lig -i $infile # Comptage du nombre de ligne dans le fichier
                fi
            }
        done
        IFS=$OLDIFS

        # Si pas d'erreur sur fichier(s) en entrée(s)... ni sortie
        [[ -n ${cmd_exec} && $SEV -eq 0 ]] && {
            _cpt_lig -o $outfile # Comptage du nombre de ligne dans le fichier AVANT concatenation

            # Execution de la commande 'cat' si fichier en entrée valide
            cmd_exec="cat $options $cmd_exec >> $outfile"
            _fct_exec -n "CAT" -c "${cmd_exec:-NULL}" -l "Concatenation fichiers $infiles vers $outfile" -r ${CR_MAX_SHL}
            # SEV=$? # Inutile car Variable GLOBALE
            [[ $SEV -eq 0 ]] && _cpt_lig -o $outfile # Comptage du nombre de ligne dans le fichier APRES concatenation
        }
    }

    msg "$fct_name:Fin execution:$msg_lib:SEV=$SEV" 7 # DEBUG
    return $SEV
}

# ----------------------------------------------------------------------
# Fonction d'initialisation à vide d'un fichier
# Appel  : file_clear -o "$OF"
# Retour : SEV
# ----------------------------------------------------------------------
file_clear() {
    declare fct_name=${FUNCNAME[0]}
    msg "$fct_name:Debut execution:$*" 7 # DEBUG

    # Analyse des parametres et arguments passés
    unset OPTIND # Obligatoire pour réentrance
    while getopts :o:h param; do
        case $param in
            o) declare outfile=${OPTARG}   ;;
            h) msg "$fct_name -o outfile " ;;
            *) _fct_err "$*"; return $SEV  ;;
        esac
    done

    declare msg_lib="$fct_name:-o $outfile:"
    msg "$msg_lib"  # INFO

    declare cmd_exec=""
    # Execution commande ${INIT_FILE}
    [[ -n $outfile ]] && cmd_exec="${INIT_FILE} $outfile " && _cpt_lig -o $outfile # Comptage du nombre de ligne dans le fichier
    _fct_exec -n "CLEAR" -c "${cmd_exec:-NULL}" -l "Initialisation fichier $outfile" -r ${CR_MAX_SHL}
    # SEV=$? # Inutile car Variable GLOBALE
    [[ $SEV -eq 0 ]] && _cpt_lig -o $outfile # Comptage du nombre de ligne dans le fichier

    msg "$fct_name:Fin execution:$msg_lib:SEV=$SEV" 7 # DEBUG
    return $SEV
}

# ----------------------------------------------------------------------
# Fonction de copy(sauvegarde) d'un fichier
# Appel  : file_copy -i "$IF" -o $OF -p "cp Options"
# Retour : SEV
# ----------------------------------------------------------------------
file_copy() {
    declare fct_name=${FUNCNAME[0]}
    msg "$fct_name:Debut execution:$*" 7 # DEBUG

    # Analyse des parametres et arguments passés
    unset OPTIND # Obligatoire pour réentrance
    while getopts :i:o:p:h param; do
        case $param in
            i) declare infile=${OPTARG}  ;;
            o) declare outfile=${OPTARG} ;;
            p) declare options=${OPTARG} ;;
            h) msg "$fct_name -i \"infile\" -o \"outfile\" -p \"options\" " ;;
            *) _fct_err "$*"; return $SEV ;;
        esac
    done

    declare msg_lib="$fct_name:-i $infile:-o $outfile:-p $options"
    msg "$msg_lib"  # INFO

    declare sev_in= sev_ou=
    # Controle si fichier entree renseigné et valide ! => 3 si non OK
    _fic_ctrl ${infile}  "entree"
    sev_in=$?
    # Controle si fichier sortie renseigné et valide ! => 3 si non OK
    _fic_ctrl ${outfile} "sortie"
    sev_ou=$?
    # On conserve le code retour le plus élevé :
    SEV=$(_max_min "max" "$SEV" "$sev_in" "$sev_ou")
    [[ $sev_in -gt $sev_ou ]] && sev_msg="entrée: ${infile}" || sev_msg="sortie:${outfile}"

    declare cmd_exec=
    [[ $SEV -eq 0 ]] && {
        msg "$fct_name:trt du Fichier entrée : [$infile]" 7 # DEBUG
        # Controle nom fichier entree et sortie ne sont pas identique
        if _fic_in_out ${infile} ${outfile} ; then
            _cpt_lig -i $infile # Comptage du nombre de ligne dans le fichier
            # Execution de la commande 'cp'
            cmd_exec="cp $options $infile $outfile"
            _fct_exec -n "COPY" -c "${cmd_exec:-NULL}" -l "Copy fichier $infile vers $outfile" -r ${CR_MAX_SHL}
            # SEV=$? # Inutile car Variable GLOBALE
            [[ $SEV -eq 0 ]] && _cpt_lig -o $outfile # Comptage du nombre de ligne dans le fichier sortie
        fi
    } || {
        msg "Le fichier $sev_msg est invalide" 3 # ERROR
    }

    msg "$fct_name:Fin execution:$msg_lib:SEV=$SEV" 7 # DEBUG
    return $SEV
}

# ----------------------------------------------------------------------
# Fonction de suppression fichier(s) ou repertoire
# Appel  : file_delete -o "$OF" -p "rm Options" ( si r|R = Directory)
# Retour : SEV
# ----------------------------------------------------------------------
file_delete() {
    declare fct_name=${FUNCNAME[0]}
    msg "$fct_name:Debut execution:$*" 7 # DEBUG

    # On conserve le code retour MAX de la phase
    _cr_max "$SEV"

    # Analyse des parametres et arguments passés
    unset OPTIND # Obligatoire pour réentrance
    while getopts :o:p:h param; do
        case $param in
            o) declare outfile=${OPTARG} ;;
            p) declare options=${OPTARG} ;;
            h) msg "$fct_name -o \"outfile\" -p \"options\" " ;;
            *) _fct_err "$*"; return $SEV ;;
        esac
    done

    declare msg_lib="$fct_name:-o $outfile:-p $options "
    msg "$msg_lib" 7 # DEBUG au lieu d'INFO pour DELETE

    declare cmd_exec=
    # Execution de la commande 'rm' sur fichier(s) ou repertoire
    declare lib_del="fichier"
    [[ `echo $options | grep -E "^[drR]$"` != "" ]] && lib_del="repertoire"

    [[ -n $outfile ]] && file_exist "$outfile" && {
        cmd_exec="rm $options $outfile"
        _fct_exec -n "DELETE" -c "${cmd_exec:-NULL}" -l "Suppression $lib_del $outfile" -r ${CR_MAX_SHL}
        # SEV=$? # Inutile car Variable GLOBALE
    } || {
        msg "$fct_name:Fichier inexistant:$outfile" 5 # NOTICE
    }
    msg "$fct_name:Fin execution:$msg_lib:SEV=$SEV" 7 # DEBUG
    return $SEV
}

# ----------------------------------------------------------------------
# Fonction de renommage d'un fichier
# Appel  : file_rename -i "$IF" -o "$OF" -p "mv Options"
# Retour : SEV
# ----------------------------------------------------------------------
file_rename() {
    declare fct_name=${FUNCNAME[0]}
    msg "$fct_name:Debut execution:$*" 7 # DEBUG
    # Analyse des parametres et arguments passés
    unset OPTIND # Obligatoire pour réentrance
    while getopts :i:o:p:h param; do
        case $param in
            i) declare infile=${OPTARG}  ;;
            o) declare outfile=${OPTARG} ;;
            p) declare options=${OPTARG} ;;
            h) msg "$fct_name -i \"infile\" -o \"outfile\" -p \"options\" " ;;
            *) _fct_err "$*"; return $SEV ;;
        esac
    done

    declare msg_lib="$fct_name:-i $infile:-o $outfile: -p $options :"
    msg "$msg_lib"  # INFO

    declare sev_in= sev_ou= sev_msg=
    # Controle si fichier entree renseigné et valide ! => 3 si non OK
    _fic_ctrl ${infile}  "entrée"
    sev_in=$?
    # Controle si fichier sortie renseigné et valide ! => 3 si non OK
    _fic_ctrl ${outfile} "sortie"
    sev_ou=$?
    # On conserve le code retour le plus élevé :
    SEV=$(_max_min "max" "$SEV" "$sev_in" "$sev_ou")
    [[ $sev_in -gt $sev_ou ]] && sev_msg="entrée: ${infile}" || sev_msg="sortie:${outfile}"

    declare cmd_exec=
    [[ $SEV -eq 0 ]]  && {
        msg "$fct_name:trt du Fichier entrée : [$infile]" 7 # DEBUG
        # Controle nom du fichier entree et sortie
        if _fic_in_out ${infile} ${outfile} ; then
            _cpt_lig -i $infile # Comptage du nombre de ligne dans le fichier
            # Execution de la commande 'mv'
            cmd_exec="mv $options $infile $outfile "
            _fct_exec -n "RENAME" -c "${cmd_exec:-NULL}" -l "Renommage fichier $infile en $outfile" -r ${CR_MAX_SHL}
            # SEV=$? # Inutile car Variable GLOBALE
            [[ $SEV -eq 0 ]] && _cpt_lig -o $outfile # Comptage du nombre de ligne dans le fichier sortie
        fi
    } || {
        msg "Le fichier $sev_msg est invalide" 3 # ERROR
    }

    msg "$fct_name:Fin execution:$msg_lib:SEV=$SEV" 7 # DEBUG
    return $SEV
}

# ----------------------------------------------------------------------
# Gestion et Affichage des messages ( cf _msg )
# $1 : Libellé
# $2 : niveau : 7=DEBUG|[6=INFO]|5=NOTICE|4=WARNING|3=ERROR|2=CRITICAL|1=ALERT|0=EMERG
# Appel  : msg "libelle du message" $niv_msg
# exemple :
#     2023-02-07 16:36:34|INFO.|Fichier de commandes du tri = /tmp/MDACQ9A-ADEVMJTP-TRI.gcsort
#     2023-02-07 16:36:34|FATAL|gcsort -fcolseq=EBCDIC -febcdic-table=ebcdic500_latin1 NON INSTALLÉ SUR CE SERVER !
# ----------------------------------------------------------------------
msg() {
    declare lib_msg="$1"     # Libellé du message
    declare niv_msg=${2:-6}  # Niveau  du message (6=INFO Si non renseigné !)

    # Affiche le message seulement si le "niveau" est >= à MDB_LOG_LEVEL (6=INFO par defaut )
    [[ ${niv_msg} > ${MDB_LOG_LEVEL} ]] && return 0

    # "libelleEnCouleur" en fonction du niveau du message
    case ${niv_msg} in
      7) lib_niv=$dbug ;;    # "DEBUG"
      6) lib_niv=$info ;;    # "INFO."
      5) lib_niv=$noti ;;    # "NOTIC"
      4) lib_niv=$wrng ;;    # "WARNG"
      3) lib_niv=$erro ;;    # "ERROR"
      2) lib_niv=$crtc ;;    # "CRTIC"
      1) lib_niv=$alrt ;;    # "ALERT"
      0) lib_niv=$emrg ;;    # "EMERG"
      *) lib_niv=$ukwn ;;    # "UNKWN"
    esac

    declare dh=`date "+%Y-%m-%d %T"`      # SSAA-MM-JJ hh:mn:ss : "2023-06-02 08:44:31"
    declare nl=""
    [[ "${lib_msg}" =~ "Debut Phase" ]] && nl="\n"  # Saut ligne à chaque "Nouvelle phase"

    # Affichage du message à l'ecran
    echo -e "$nl$dh|${lib_niv}|${lib_msg}"

    log_level=$(echo "$lib_niv" | tr -d -c 'A-Z') # AOM Suppression des "caracteres couleurs" ( \033[1;34m )
    # ecriture via "logger" si niv_msg < NIV_LOGGER ("6=INFO") # NB : IFS=${OLDIFS}; OBLIGATOIRE car il peut avoir été changé dans une fonction
    [[ ${niv_msg} < ${NIV_LOGGER} && "${LOGGER}" != "" ]] && { IFS=${OLDIFS}; ${LOGGER}${quote}SHELL${quote} --sd-param log_level=${quote}${log_level}${quote} --sd-param domaine=${quote}${EQAMMDOM}${quote} --sd-param etape=${quote}$ETAPE${quote} --sd-param location=${quote}${MACH}${quote} --sd-param dateJC=${quote}$EQAAMMJJ${quote} --sd-param table=${quote}ND${quote} --sd-param fichier=${quote}ND${quote} --sd-param service=${quote}ND${quote} --sd-param id_dossier=${quote}ND${quote} --sd-param classe=${quote}ND${quote} --sd-param objet=${quote}ND${quote} $JOBNAME "${lib_msg}" ; }  # AOM

    return 0
}

# ----------------------------------------------------------------------
# Execution en DEBUT de JOB
# Appel  : deb_job
# ATTENTION à bien respecter l'ordre des commandes ci-dessous !!
# ----------------------------------------------------------------------
deb_job()
{
    local ret=0
    declare fct_name=${FUNCNAME[0]}
    # Gestion Gestion des messages et niveau de log :
      # VTOM_EXEC=true => signifie que le JOB est Lancé par VTOM -> PAS DE MESSAGE EN COULEUR
      # NB : On peut toujours mettre à "false" pour affichage, car les "couleurs" sont systematiquement supprimées dans les fichiers log. cf:fin_fob()  # SCO 08/2023
      VTOM_EXEC=${VTOM_EXEC:-false} # false = AFFICHAGE DES MESSAGES EN COULEUR à l'ecran
    _msg

    # Sauvegarde IFS original : ' \t\n'
    OLDIFS=$IFS
    # Gestion des \" pour 'eval' et 'logger' ( permet à notepad++ d'r toutes les "Function List", sinon il en mnaque)
    quote="\""

    # Preparation des VARIABLES GLOBALES du JOB
    # ------------------------------------------------------------------
    [[ ! $JOBNAME ]] && export JOBNAME=`basename $0 | cut -d"." -f1`
    export PID=$$                                                   # RON
    export JOBID=${JOBID:-"${JOBNAME}_${EQAMMDOM}"}                 # Vu C.M le 01/08/2023 = MDCBCTA_X77 si EQAMMDOM=X77
    export MACH=`uname -n`                                          # Nom du server
    export MDB_CORRELATION_ID=`cat /proc/sys/kernel/random/uuid`    # faa188b4-eb5e-45b6-83f6-83e8bd6a6de3
    export MSGID=${MDB_CORRELATION_ID:0:8}                          # id -> nom fichier(s) de log (

    # Fichier de log "temporaire", car les logs sont gérées via logger/rsylog
    FIC_LOG=${MDB_LOG}/${JOBNAME}_$(date +'%Y%m').log
    touch ${FIC_LOG}

    # On a toutes les infos pour ecrire des messages ....
    msg "$fct_name:Debut execution" 7 # DEBUG

    #    --> logger" ecrira dans /var/log/syslog
    LOGGER="logger -t $JOBNAME --msgid ${MDB_CORRELATION_ID} -i --rfc5424 --sd-id medoc@1 --sd-param composant="

    # Si 1er Param = "exit_trap" => appel de la fonction "_trap" = Sortie sur erreur de script bash !
    _trap_enable $JOB_PARAM_EXEC

    # Sourcer les variables de configuration du JOB autres que VTOM
    [[ -s ${MDB_CONFIG}/${JOBNAME}.sh ]] && . ${MDB_CONFIG}/${JOBNAME}.sh

    ## Sourcer l'eventuel fichier ${MDB_VARIABLE}/${JOBNAME}.env ( ? voir Grpt )
    #[[ -s ${MDB_VARIABLE}/${JOBNAME}.env ]] && . ${MDB_VARIABLE}/${JOBNAME}.env

    # V00.13 : Sourcer un "pre shell" du JOB
    [[ -s ${MDB_SCRIPTS}/pre_${JOBNAME}.sh ]] && . ${MDB_SCRIPTS}/$pre_{JOBNAME}.sh

    #AOM Gestion log au format json -> JSON_RSYSLOG
    JSON_RSYSLOG="${MDB_LOG}/${JOBNAME}_SHELL_$MSGID"_"$(hostname -s)_${EQAMMDOM}_$(date +'%Y%m').log"

    # Debut Traitement du JOB + affichage des versions des modules "medoc_xxx.sh"

    MSG_TRT="PID=$PID:JOBID=$JOBID:USER=$MDB_USERNAME:MACH=$MACH:JOB_PARAM_EXEC=$JOB_PARAM_EXEC:" # 2023/08/07 :${MDB_CORRELATION_ID} cf "msg"
    msg "$fct_name:DEBUT DU TRAITEMENT:JOB=$JOBNAME:$MSG_TRT"  # INFO
    msg "$fct_name:Fichier de log  JOB:$FIC_LOG"  # INFO
    msg "$fct_name:Fichier de log JSON:$JSON_RSYSLOG"  # INFO
    msg "$fct_name:VERSION:medoc_fct.sh=${MDB_VERS_FCT}:medoc_var.sh:${MDB_VERS_VAR}"  # INFO

    # Suppression des eventuels fichiers temporaires du "JOBNAME"
    [[ -f ${MDB_TEMP}/${JOBNAME}_* ]] && rm ${MDB_TEMP}/${JOBNAME}_* 2>&1

    # Initialisation debut de job => Execution fonctions "privées": connexion BdD cia les API's... valorisations Variables
    _fct_medoc_init

    msg "$fct_name:Fin execution:$*" 7 # DEBUG
    return $ret
}
# ----------------------------------------------------------------------
# Execution en FIN de JOB
# Appel  : fin_job
# Retour : CR_MAX
# ----------------------------------------------------------------------
fin_job()
{
    declare fct_name=${FUNCNAME[0]}
    msg "$fct_name:Debut execution:$*" 7 # DEBUG

    if [[ $CR_MAX -le ${CR_MAX_JOB} ]]; then
       RESULT='OK';
    else
       _msg_op ">>>>> ERREUR DANS LE DEROULEMENT - VERIFIER ETAPE=$ETAPE ..." $NIV_MSG # ERROR
       RESULT='KO'
    fi

    # finalisation JOB's MedocDb : Execut° qq fonctions "privées" de fin de JOB
    _fct_medoc_fini

    # V00.13 : Sourcer un "post shell" du JOB
    [[ -s ${MDB_SCRIPTS}/post_${JOBNAME}.sh ]] && . ${MDB_SCRIPTS}/$post_{JOBNAME}.sh

    msg "$fct_name:FIN DU TRAITEMENT:JOB=$JOBNAME:CR=[$CR_MAX]:ETAPE=$ETAPE($RESULT):$MSG_TRT" $NIV_MSG # INFO|ERROR

    msg "$fct_name:Fin execution:SEV=$SEV:CR_MAX=$CR_MAX" 7 # DEBUG

    # Affichage du contenu de la log ( ? voir Grpt )
    if [[ $CAT_LOG = "TRUE" ]]; then
        echo ""
        echo ""
        echo "===================================================================================="
        echo "$JOBNAME, check log file : ${JSON_RSYSLOG}"
        echo "===================================================================================="
        [[ -f $JSON_RSYSLOG ]] && rm -rf ${FIC_LOG} # AOM suppresion du fichier FIC_LOG si logger/rsyslog -> JSON_RSYSLOG
    fi

    # Retour VTOM
    return $CR_MAX # Le code retour MAX du JOB !
}
# ----------------------------------------------------------------------
# Execution à chaque debut de PHASE
# Appel  : phase
# ----------------------------------------------------------------------
phase()
{
    declare fct_name=${FUNCNAME[0]}
    declare fct_parent=${FUNCNAME[1]}
    msg "Debut execution ${fct_parent}"
}
# ----------------------------------------------------------------------
# Execution à chaque fin de PHASE
# Appel  : endphase
# ----------------------------------------------------------------------
endphase()
{
    declare fct_name=${FUNCNAME[0]}
    declare fct_parent=${FUNCNAME[1]}
    # On conserve le code retour MAX de la phase
    _cr_max "$SEV"
    msg "Fin execution ${fct_parent} - code retour=$SEV" 
}
# ----------------------------------------------------------------------
# Execution à chaque debut de STEP : Sauvegarde date et heure debut step
# Appel  : step $typ_prg ( COBOL|GCSORT|SQL|...) : cf _fct_exec
# ----------------------------------------------------------------------
step()
{
    declare fct_name=${FUNCNAME[0]}
    declare fct_parent=${FUNCNAME[2]}
    msg "$fct_name:Debut execution:$*" 7 # DEBUG

    declare typ_prg=$1

    # Calcul Temps d'Execution DEBUT
    _time_exec "deb" ${typ_prg} ${fct_parent}
    msg "$fct_name:Fin execution:$*" 7 # DEBUG
}
# ----------------------------------------------------------------------
# Execution à chaque fin de STEP : Calcul temps d'execution du step
# Appel  : endstep $typ_prg ( COBOL|GCSORT|SQL|...) : cf _fct_exec
# ----------------------------------------------------------------------
endstep()
{
    declare fct_name=${FUNCNAME[0]}
    declare fct_parent=${FUNCNAME[2]}
    msg "$fct_name:Debut execution:$*" 7 # DEBUG

    declare typ_prg=$1
    # Calcul Temps d'Execution FIN
    _time_exec "fin" ${typ_prg} ${fct_parent}
    msg "$fct_name:Fin execution:$*" 7 # DEBUG
}

# ----------------------------------------------------------------------
# Valorisation des variables liée au domaine d'execution
# Appel : load_dom_config <DOM>
# Retour : 0 si ok
# ----------------------------------------------------------------------
load_dom_config() {

    declare fct_name=${FUNCNAME[0]}
    declare fct_parent=${FUNCNAME[1]}

    msg "$fct_name:Debut execution:$*" 7 #DEBUG

    local dom="$1"
    local source="$MDB_DOM_CONFIG_SOURCE"
    local json_data
    local entry

    if [[ -z "$dom" ]]; then
	    msg "$fct_name Usage: load_config <DOMAINE>" 3 # ERROR
	    return 1
    fi

    if [[ "$source" = API ]]; then
            msg "$fct_name:Using API to retrieving config for $dom..." 7 #DEBUG
            local http_code=$(curl -s -o /dev/null -k -w "%{http_code}\n" "$MDB_DOM_CONFIG_URL?domaine=$dom")
            if [[ "$http_code" -ne 200 ]]; then
                    msg "$fct_name:Problem occured when using API HTTP/$http_code" 3 #ERROR
                    exit 1
            fi
            json_data=$(curl -s -k "$MDB_DOM_CONFIG_URL?domaine=$dom")
    
    elif [[ "$source" = LOCAL ]]; then
            msg "$fct_name:Reading config from Local file : $MDB_DOM_FIC..." 7 #DBUG
            if [[ ! -f "$MDB_DOM_FIC" ]]; then
                msg "$fct_name:File '$MDB_DOM_FIC' not found." 3 #ERROR
                return 1
            fi
            json_data=$(cat "$MDB_DOM_FIC")
    fi


    entry=$(echo "$json_data" | jq -c --arg dom "$dom" '.[] | select(.DOMAINE == $dom)')
    if [[ -z "$entry" ]]; then
            msg "$fct_name:No config found for DOMAINE='$dom'." 3 #ERROR
            return 1
    fi
    
    local keys key value
    keys=$(echo "$entry" | jq -r 'keys[] | select(. != "DOMAINE")')
    for key in $keys; do
        value=$(echo "$entry" | jq -r --arg key "$key" '.[$key]')
        if [[ -n "$value" && "$value" != "null" ]]; then
            export "$key"="$value"
        fi
    done
    
    msg "$fct_name:Following variables for $dom where found & exported : $(echo "$keys" | tr '\n' ' ')"
    
    return $?

}
# ----------------------------------------------------------------------
# Retourne 1 à l’ordonnanceur si la phase retourne une sévérité non nulle
# Appel  : gestion_exit_ops $?
# ----------------------------------------------------------------------
gestion_exit_ops() {
    if [ "$1" -ne 0 ]; then
        exit 1
    fi
}

# ----------------------------------------------------------------------
# ======================================================================
#  Fonctions "PRIVEES"   : NON APPELABLES PAR LES SCRIPTS MEDOC-DB
# ======================================================================

# Fonctions Groupement : ( ? voir Grpt ) Potentiellement à revoir !?

# ----------------------------------------------------------------------
# Determine le chemin de l'executable Cobol -> PROG_PATH
# Appel  : _path_prog $prog_name $COB_SET_DEBUG
# Retour : SEV
# ----------------------------------------------------------------------
_path_prog() {
    declare fct_name=${FUNCNAME[0]}
    declare fct_parent=${FUNCNAME[1]}
    msg "$fct_name:Debut execution:$*" 7 # DEBUG

    _fct_is_exec $fct_name || return 0 # Test si fonction est "executable"

    declare progName=$1
    declare ModDebug=$2
    msg "$fct_name:progName=$progName:ModDebug=$ModDebug:" 7 # DEBUG

    # Chemin executable
    unset PROG_PATH
    PROG_PATH=`find ${MDB_BATCHS} -type f -name $progName 2>/dev/null`
    # Chemin executable en mode DEBUG
    [[ ! -z "$ModDebug" ]] && PROG_PATH=${MDB_BATCHS_DEBUG}/${progName}  # SCO MDB_BATCHS_DEBUG n'existe pas !
    msg "$fct_name:PROG_PATH=${PROG_PATH}" 7 # DEBUG

    [[ ! -f "${PROG_PATH}" ]] && {
        SEV=4; # SYSTEM ERROR
        msg "$fct_parent:$fct_name:PROGRAMME:${progName} NON TROUVE (PROG_PATH=${PROG_PATH}:ModDebug=$ModDebug:MDB_BATCHS=${MDB_BATCHS}" 2 # CRITICAL
        _cr_max $SEV # On conserve le code retour le plus élévé
    } ||{
        # existe-t-il un shell de GÉNÉRATION DE VUES pour ce programme COBOL ( cas exceptionnel pour amélioration des perfs ) ?     # SCO 2025/02/03
        PRE_GNR_VUE=${MDB_BATCHS}/pre_${progName}.sh
        [[ ! -f ${PRE_GNR_VUE} ]] && {
            # Shell non trouvé : suppression de la variable ( cf _fct_exec )
            msg "$fct_parent:$fct_name:PROGRAMME:${PRE_GNR_VUE} NON TROUVE" 7 # DEBUG
            unset PRE_GNR_VUE
        }
    }
    msg "$fct_name:Fin execution:PROG_PATH=${PROG_PATH}:SEV=$SEV" 7 # DEBUG
    return $SEV
}
# ----------------------------------------------------------------------
# Analyse Variable et Argument -> export Variable=Arg (utile en DEV ?)
#   argument 1 : nom de la variable à alimenter
#   argument 2 : valeur si vrai
#   argument 3 : argument à rechercher dans la liste
#   argument 4 : liste des arguments à rechercher ( = "$JOB_PARAM_EXEC")
# Appel  : _analyze_args 'COB_SET_DEBUG' 'Y' '-debug' "$JOB_PARAM_EXEC"
# ----------------------------------------------------------------------
_analyze_args() {
    declare fct_name=${FUNCNAME[0]}
    declare fct_parent=${FUNCNAME[1]}
    msg "$fct_name:Debut execution:$fct_parent:$*" 7 # DEBUG

    declare fct_name=${FUNCNAME[0]}
    declare varToSet="$1"
    declare valIfTrue="$2"
    declare argToSearch="$3"
    declare arguments="$JOB_PARAM_EXEC" # au lieu de "$4"
    declare msg_lib="$fct_parent:$fct_name:varToSet=$varToSet:valIfTrue=$valIfTrue:argToSearch=$argToSearch:arguments=$arguments"
    msg "$msg_lib" 7 # DEBUG
    declare isFound='NO'
    for arg in $arguments ; do
       [[ "$argToSearch" =~ "$arg" ]] && { export $varToSet=$valIfTrue; isFound='YES' ; break; }
    done
    msg "$fct_parent:$fct_name:$varToSet=$valIfTrue=$isFound" 7 # DEBUG
    msg "$fct_name:Fin execution:$*" 7 # DEBUG
}
# FIN Fonctions Groupement : ( ? voir Grpt ) Potentiellement à revoir !?

# ----------------------------------------------------------------------
# Fonction "trap" de sortie sur erreur de shell
# APPEL : _trap_enable "trap" "[-E]|-e"
# set -E : ANALYSER tout le script                  : VALEUR DEFAUT
# set -e : SORTIR à la 1ere erreur
# ERR    : execute le code de la fct '_trap_start'  : VALEUR DEFAUT
# EXIT   : sortie du script dès l'erreur rencontrée !
# ----------------------------------------------------------------------
_trap_enable() {
    declare fct_name=${FUNCNAME[0]}
    msg "$fct_name:Debut execution:$@" 7 # DEBUG

    declare fct_trap=$1
    declare typ_set=${2:-"-E"}
    declare typ_trap="ERR"
    # NB : tjs "ERR" pour avoir le message via _trap_start!  "EXIT" sort du script dès l'erreur rencontrée et AVANT affichage du message !
    # [[ $typ_set == "-e" ]] && typ_trap="EXIT"
    msg "$fct_name:fct_trap:$fct_trap:typ_set:$typ_set:typ_trap:$typ_trap" 7 # DEBUG

    [[ $fct_trap =~ (trap) ]] && {
        set $typ_set                                 # -E=ERR ou -e=EXIT  : TRAP du job sur erreur rencontrée
        trap '_trap_start $? $LINENO' $typ_trap      # "[ERR]|EXIT"
        msg "$fct_name:trap du JOB='$typ_set:$typ_trap' pour toute erreur de script bash rencontrée" 5 # NOTICE
    } || {
        msg "$fct_name:trap erreur script non activé" 5 # NOTICE
    }
    return 0
}
_trap_start () {
    declare fct_name=${FUNCNAME[0]}
    declare lc="$BASH_COMMAND" rc=$1 ln=$2
    msg "$fct_name:$0:Commande [$lc] est sortie en erreur:code=[$rc] à la ligne=[$ln]" 3 # ERROR
    return 0
}
# Decommenter la ligne ci-dessous pour tester la fonction _trap
# _trap_enable "trap" # "-E"

# ----------------------------------------------------------------------
# Fonction d'execution des commandes générées par les "Fontions PUBLIQUES"
# Appel  : _fct_exec -n "CLEAR" -c "${cmd_exec:-NULL}" -l "Init file $outfile" -r CR_MAX_<SHL>
# Retour : SEV
# ----------------------------------------------------------------------
_fct_exec() {
    declare fct_name=${FUNCNAME[0]}
    declare fct_parent=${FUNCNAME[1]}
    msg "$fct_name:Debut execution:$fct_parent:$*" 7 # DEBUG

    # Analyse des parametres et arguments passés
    unset OPTIND # Obligatoire pour réentrance
    while getopts :c:l:n:r:h param; do
        case $param in
            c) declare cmd_exec=${OPTARG} ;;
            l) declare libelle=${OPTARG} ;;
            n) declare typ_prg=${OPTARG} ;;
            r) declare cr_max_prg=${OPTARG} ;;
            h) msg "$fct_name [-n prgName -c cmd_exec -l libelle ] -r [ cr_max_prg]" ;;
        esac
    done
    msg "$fct_parent:typ_prg=$typ_prg:cmd_exec=$cmd_exec:cr_max_prg=$cr_max_prg:libelle=$libelle" 7 # DEBUG

    declare msg_lib="$fct_parent:-c $cmd_exec"
    msg "$msg_lib:-l $libelle:" 7 # DEBUG

    # Execution commande SEULEMENT SI la fonction est "EXECUTABLE" :
    if _fct_is_exec $fct_parent ; then # Test si FONCTION PARENTE est "executable"

        # Controle si la Commande est valide :
        if [[ "$cmd_exec" = "NULL" ]] ; then
            SEV=3 # A voir si on laisse 3 ??
            msg "$fct_parent:$typ_prg:Aucun fichier valide !!" 3 #ERROR
        else
            # Debut de step ... sauf pour : ASSIGN, DELETE
            step ${typ_prg}
            [[ $SEV -eq 0 ]] && { # SEV = 8 si mdb_api_get est en ERREUR

                export typ_logger="SHELL"
	    	export SHELL=/bin/bash
                [[ ${typ_prg} =~ (COB|GCSORT|PGSQL) ]] && typ_logger="${typ_prg}" # logger ecrira dans /var/log/syslog
                [[ ${typ_prg} = COBOL ]] && typ_logger=COB

                # Si variable PRE_GNR_VUE existe -> EXECUTION DU SHELL DE GENERATION DE LA VUE  # SCO 2025/02/03
                [[ -n ${PRE_GNR_VUE} ]] && {
                    msg "$fct_parent:SHELL DE GENERATION DE LA VUE:${PRE_GNR_VUE}: en cours..." # INFO
                    eval "$TIME_EXE ${PRE_GNR_VUE}" 2>&1 | xargs -0 -I{} -d\\n -n1 ${LOGGER}${quote}${typ_logger}${quote} ${quote}{}${quote}
                    declare cr="${PIPESTATUS[0]}"
                    # VUE-004<200d> : Si le script de génération tombe en anomalie, un warning est écrit dans la LOG puis le shell principal appelle le programme Cobol.
                    [[ ${cr} -ne 0 ]] && msg "$ETAPE:$fct_parent:VUE-004:${PRE_GNR_VUE}:terminé en erreur:Code Retour:${cr}:" 4 # WARNING
                    unset PRE_GNR_VUE
                }

                # EXECUTION DE LA COMMANDE générée par la FONCTION PUBLIQUE "exec_<xxxx>" et EVENTUELLEMENT précédée de "TIME_EXE"
                msg "$fct_parent:$libelle en cours..." # INFO
                FIC_LOG_COB=${MDB_LOG}/_tmp_cob_${JOBNAME}_$(date +'%Y%m').log
                eval "$TIME_EXE $cmd_exec" 2>&1 | tee -a $FIC_LOG_COB | xargs -0 -I{} -d\\n -n1 bash -c 'echo "{}";logger -t $JOBNAME --msgid ${MDB_CORRELATION_ID} -i --rfc5424 --sd-id medoc@1 --sd-param composant=\"${typ_logger}\" --sd-param log_level=\"${log_level}\" --sd-param domaine=\"${EQAMMDOM}\" --sd-param etape=\"$ETAPE\" --sd-param location=\"${MACH}\" --sd-param dateJC=\"$EQAAMMJJ\" --sd-param table=\"ND\" --sd-param fichier=\"ND\" --sd-param service=\"ND\" --sd-param id_dossier=\"ND\" --sd-param classe=\"ND\" --sd-param objet=\"ND\" "{}"'

                SEV="${PIPESTATUS[0]}" # recupératon code retour de $cmd_exec !

                rm -rf ${FIC_LOG_COB} # AOM suppresion du fichier FIC_LOG_COB temporaire

                msg "$fct_name:$cmd_exec:SEV=$SEV" 7 # DEBUG
            }
        fi


        # Fin de step ... sauf pour : ASSIGN, DELETE
        endstep ${typ_prg}
    fi
    # Controle du code retour $SEV en fonction du cr_max_prg définit selon le type de programme executé via la FONCTION !
    _cr_test "${typ_prg}" "$SEV" ${cr_max_prg}
    [[ $SEV -ne 0 ]] && msg "$ETAPE:$fct_parent:$msg_lib terminé en erreur:Code Retour:$SEV:" $NIV_MSG # INFO|ERROR

    msg "$fct_name:Fin execution:$*:SEV=$SEV" 7 # DEBUG
    return $SEV
}
# ----------------------------------------------------------------------
# Test si on execute ou pas une fonction. cf FCT_EXEC
# NB     : Si une fonction n'est pas présente dans FCT_EXEC => false !!
# Appel  : _fct_is_exec "fct_name"
# Retour : true(0) ou false(1)
# ----------------------------------------------------------------------
_fct_is_exec() {
    declare fct_name=${FUNCNAME[0]}
    declare fct_exec=$1
    declare is_exec=""
    is_exec=${FCT_EXEC[${fct_exec}]#*:} # "true|false" pour la fonction
    is_exec=${is_exec:-true}           # false si non renseigné => NON EXECUTABLE !
    msg "$fct_name:$fct_exec:executable:${is_exec}:" 7 # DEBUG
    ${is_exec} || { SEV=0 ; msg "${fct_exec}:non executable !!!" 7; } # DEBUG
    ${is_exec}                          # renvoie "true|false"
}
# ----------------------------------------------------------------------
# Erreur d'appel d'une fonction
# But : Décrire ici chacun des formats d'appel des Fonctions Publiques
# Retour : SEV
# ----------------------------------------------------------------------
_fct_err() {
    SEV=3 # ERROR
    msg "$fct_name:parametre inconnu de la fonction:param=$*" 3 # ERROR
    # usage ()
    case $fct_name in
        exec_prog  ) usage_msg="-p \"Nom Prog Cobol\" -i \"input param file\" " ;;
        exec_sort  ) usage_msg="-i \"infiles list\" -o \"outfile\" -p \"gcort parametres\" " ;;
        exec_sql   ) usage_msg="-f \"QueryFile\" -o \"ResultFile\" -p \"options\" " ;;
        file_cat   ) usage_msg="-i \"infiles\ list\" -o \"outfile\" -p \"options\" " ;;
        file_copy  ) usage_msg="-i \"infile\" -o \"outfile\" -p \"options\" " ;;
        file_rename) usage_msg="-i \"infile\" -o \"outfile\" -p \"options\" " ;;
        file_delete) usage_msg="-o \"outfile\" -p \"options\" " ;;
        file_clear ) usage_msg="-o \"outfile\" -p \"options\" " ;;

        file_assign) usage_msg="ifn efn []|CREATE [f]|d" ;;
        file_exist ) usage_msg="efn f|s|d (f=file|s=not empty|d=directory)" ;;
    esac
    msg "usage :$fct_name $usage_msg" 3 # ERROR

    _cr_max $SEV # On conserve le code retour le plus élévé
    return $SEV
}
# ----------------------------------------------------------------------
# Verification si nom fichier correctement renseigné et existe.
# Appel  : _fic_ctrl "file_name" "[entree]|sortie"
# Retour : 0 ou 3 sans maj de SEV !
# ----------------------------------------------------------------------
_fic_ctrl() {
    declare fct_name=${FUNCNAME[0]}
    declare fct_parent=${FUNCNAME[1]}
    msg "$fct_name:Debut execution:$*" 7 # DEBUG

    declare file_name="$1"
    declare in_out=${2:-entree} # ou sortie
    declare cr_fct=0

    # Controle que la variable "file_name" est renseignée
    if [[ ! -n $file_name ]] ; then
        cr_fct=3
        msg "$fct_parent:$fct_name:Fichier ${in_out} non renseigné:$file_name" 4 # WARNING
    else
        # existence du filename si "entrée" ou repertoire si "sortie"
        case ${in_out} in
          entree|entrée)
            if ! file_exist ${file_name} ; then
                cr_fct=3
                msg "$fct_parent:Fichier entrée inexistant:${file_name}" 4 # WARNING
            fi ;;
          sortie)
            declare rep=$(dirname ${file_name})   # Le repertoire est > 3c. et existe
            msg "repertoire=$rep:len=${#rep}" 7 # DEBUG
            if  [[ ${#rep} -lt 4 ]] || \
                ! file_exist "${rep}" "d" ; then  # Existence du Repertoire du fichier de sortie
                cr_fct=3
                msg "$fct_parent:Repertoire du Fichier sortie inexistant:${file_name}" 4 # WARNING
            fi ;;
        esac
    fi
    msg "$fct_name:Fin execution:$*:cr_fct=$cr_fct" 7 # DEBUG
    return $cr_fct
}
# ----------------------------------------------------------------------
# Controle fichier entrée doit etre different fichier sortie : SEV=3
# Appel  : _fic_in_out "$infile" "$outfile"
# Retour : SEV
# ----------------------------------------------------------------------
_fic_in_out() {
    declare fct_name=${FUNCNAME[0]}
    declare fct_parent=${FUNCNAME[1]}
    msg "$fct_name:Debut execution:$*" 7 # DEBUG

    declare infile="$1"
    declare outfile="$2"

    # On controle que le fichier en entrée est different du fichier en sortie
    [[ ${infile} == ${outfile} ]] && {
        SEV=3
        msg "${fct_parent}:fichiers identiques:entree=${infile}:sortie=${outfile}:CR=$SEV" 3  # ERROR
    }

    _cr_max "$SEV" # On conserve le code retour le plus élévé
    msg "$fct_name:Fin execution:$*:SEV=$SEV" 7 # DEBUG
    return $SEV
}
# ----------------------------------------------------------------------
# Comptage du nombre de ligne dans un fichier
# Appel  : _cpt_lig -i|o $ifn ( i=Entrée | o=Sortie )
# ----------------------------------------------------------------------
_cpt_lig() {
    declare fct_name=${FUNCNAME[0]}
    declare fct_parent=${FUNCNAME[1]}
    msg "$fct_name:Debut execution:$*" 7 # DEBUG

    # Analyse des parametres et arguments passés
    unset OPTIND # Obligatoire pour réentrance
    while getopts :i:o:h param; do
        case $param in
            i) declare file_name=${OPTARG}; declare in_out="ENTREE" ;;
            o) declare file_name=${OPTARG}; declare in_out="SORTIE" ;;
            h) msg "$fct_name [-i|o $file_name ] " ;;
        esac
    done
    # On compte le nombre de ligne du fichier s'il existe...
    file_exist ${file_name} && {
        declare nb_lig=`wc -l ${file_name} | cut -d" " -f1`
        msg "${fct_parent}:Nombre de lignes dans le fichier ${in_out}:${file_name}=$nb_lig:"
    }
    msg "$fct_name:Fin execution:$*" 7 # DEBUG
}
# ----------------------------------------------------------------------
# Test du Code Retour d'un Programme ou Utilitaire ou SQL
# Appel  : _cr_test $typ_prg $cr_exec $cr_max
# Retour : SEV
# ----------------------------------------------------------------------
_cr_test() {
    declare fct_name=${FUNCNAME[0]}
    msg "$fct_name:Debut execution:$*" 7 # DEBUG

    declare typ_prg=$1  # Type de Programme : COBOL|GCSORT|PGSQL|<commande bash>...
    declare cr_exec=$2  # Code Retour du programme executé
    declare cr_max=$3   # Code Retour autorisé pour le "type de Programme"
    msg "$fct_name:typ_prg=$typ_prg:cr_exec=$cr_exec:cr_max=$cr_max" 7 # DEBUG

    # si 'rm' fichier inexistant => on force le code retour à 0 au lieu de 127 ( N'arrivera pas car file_assign fait ce qu'il faut !! )
    [[ ${typ_prg} =~ (DELETE|rm) ]] && cr_exec=0

    SEV=$cr_exec
    # Controle si le code retour est > au code retour MAX permis pour ce "Type de Programme"
    [[ $cr_exec -gt $cr_max ]] && {

        # Message Erreur selon Type de Programme et reaffectation d'un code erreur = 3(USER   ERROR) ou 4(SYSTEM ERROR)
        declare err_prg="CODE RETOUR=$cr_exec";
        case $typ_prg in
            SHELL ) SEV=3 ;; # USER   ERROR
            COBOL ) SEV=4 ;; # SYSTEM ERROR
            GCSORT) SEV=4 ;; # SYSTEM ERROR
            PGSQL ) SEV=4 ;; # SYSTEM ERROR
                * ) SEV=6 ;; # SYSTEM CRASH
        esac

        # Recupération ligne(s) en ERREUR, parmi les 6 dernieres lignes de la log. cf "MDB_ERR_LOG"
        declare today=`date "+%Y-%m-%d"`
        declare err_lib=`tail -6 ${FIC_LOG} | grep -Ei "${MDB_ERR_LOG}" | grep -v "$today"`
        [[ -n $err_lib ]] && msg "$err_lib" 3 # ERROR
        msg "ERREUR TYPE PROGRAMME=$typ_prg:$err_prg:ETAPE=$ETAPE:SEV=$SEV" 2 # FATAL

        # On conserve le code retour(CR_MAX) et le niveau de message(NIV_MSG) le plus élévé du JOB
        _cr_max $SEV
    }
    msg "$fct_name:Fin execution:$*" 7 # DEBUG
    return $SEV
}
# ----------------------------------------------------------------------
# CR_MAX  = code retour le plus élévé + valorisation NIV_MSG et CR_MAX
#    avec : 0=OK|3=USER ERROR|4=SYSTEM ERROR|5=SYSTEM STRONG|6=SYSTEM CRASH|7=SYSTEM I/O ( ? voir Grpt )
# NIV_MSG = 3 # ERROR ou 2 # CRITICAL
# Appel  : _cr_max $cr_exec
# ----------------------------------------------------------------------
_cr_max() {
    declare fct_name=${FUNCNAME[0]}
    msg "$fct_name:Debut execution:$*:CR_MAX=$CR_MAX" 7 # DEBUG
    declare cr_exec=$1
    [[ $cr_exec -gt $CR_MAX ]] && {
        CR_MAX=$cr_exec
        # On force l'affichage des messages d'erreur : ERROR ou CRITIC
        NIV_MSG=3 # ERROR
        [[ $cr_exec > 3 ]] && NIV_MSG=2 # CRITICAL
        msg "$fct_name:Nouvelle affectation CR_MAX=$CR_MAX" $NIV_MSG
    }
    msg "$fct_name:Fin execution:$*:CR_MAX=$CR_MAX" 7 # DEBUG
}
# ----------------------------------------------------------------------
# Positionne CONTINUE à "false" pour FORCER l'arret du  BATCH !
#      avec n = 7=DEBUG|[6=INFO]|5=NOTICE|4=WARNING|3=ERROR|2=CRITICAL|1=ALERT|0=EMERG
# Appel  : _continue_false "message" "n"
# ----------------------------------------------------------------------
_continue_false() {
    declare fct_name=${FUNCNAME[0]}
    declare fct_parent=${FUNCNAME[1]}
    msg "$fct_name:Debut execution:$*" 7 # DEBUG
    declare lib_msg=${1:-"ERREUR EXECUTION dans $fct_parent"}
    SEV=${2:-3}
    msg "$fct_parent:$fct_name:$lib_msg" 3 # ERROR
    _cr_max $SEV
    CONTINUE=false
    msg "$fct_name:Fin execution:$*:CONTINUE:${CONTINUE}:" 7 # DEBUG
}
# ----------------------------------------------------------------------
# Préparation affichage des Messages en fonction du "niveau" passé à msg()
#   L'affichage des messages sera conditionné par le NIVEAU de TRACES
#    export MDB_LOG_LEVEL=n  # Modifier le niveau d'affichage des messages
#      avec n = 7=DEBUG|[6=INFO]|5=NOTICE|4=WARNING|3=ERROR|2=CRITIC|1=ALERT|0=EMERG
# ----------------------------------------------------------------------
_msg() {
    # Niveau de trace par defaut pour affichage à l'ecran et logger
    NIV_MSG=${MDB_LOG_LEVEL:-6}              # 6=INFO
    MDB_LOG_LEVEL=${MDB_LOG_LEVEL:-$NIV_MSG} # Niveau de TRACES dans la log via 'msg()' vaut 6=INFO par defaut
    NIV_LOGGER=${MDB_LOGGER_LEVEL:-$NIV_MSG} # Niveau 'logger': NIV_LOGGER doit etre > NIV_MSG pour ecrire "/var/log/syslog"

    # Gestion des messages selon niveau (niv_msg) d'information à afficher (cf https://www.linuxtricks.fr/wiki/syslog-les-journaux-systeme-sous-linux)
    nrml=""       # niv_msg
    dbug="DEBUG" #    7
    info="INFO"  #    6
    noti="NOTICE"  #    5
    wrng="WARNING"  #    4
    erro="ERROR"  #    3
    crtc="CRIT"  #    2
    alrt="ALERT"  #    1
    emrg="EMERG"  #    0
    ukwn="UNKWN"  #    *
    # Affichage des Messages en couleur : "VTOM_EXEC=false" dans le job
    ! ${VTOM_EXEC} && {                 # si true => Lancé par VTOM en PROD => pas de message en couleur
        nrml='\033[00m'                 # white
        dbug='\033[1;34m'"DEBUG"$nrml  # blue
        info='\033[1;36m'"INFO"$nrml  # green
        noti='\033[1;32m'"NOTICE"$nrml  # green lemon
        wrng='\033[1;33m'"WARNING"$nrml  # yellow
        erro='\033[1;31m'"ERROR"$nrml  # red
        crtc='\033[7;31m'"CRIT"$nrml  # red 'HighLight'
        alrt='\033[5;31m'"ALERT"$nrml  # red 'blink'
        emrg='\033[5;31m'"EMERG"$nrml  # red 'blink'
        ukwn='\033[35m'"UNKWN"$nrml    # purple
    }
    return 0
}
# ----------------------------------------------------------------------
# Affichage message à la console ( ? voir Grpt )
# ----------------------------------------------------------------------
_msg_op() {
    msg "$1" $2 # Niveau Message
    if [[ "$V_OP" != "" ]]; then
       write $V_OP <<EOF
$1:[$MDB_CORRELATION_ID]
EOF
    fi
}
# ----------------------------------------------------------------------
# Calcul du Temps d'Execution entre 'debut' et 'fin' de STEP
# Appel  : _time_exec "deb|fin" $typeProgram $fct_parent
# ----------------------------------------------------------------------
_time_exec() {
    declare fct_name=${FUNCNAME[0]}
    msg "$fct_name:Debut execution:$*" 7 # DEBUG

    declare time_sfx=$1
    declare typ_prg=$2
    declare fct_parent=${3:-${FUNCNAME[2]}}

    # On ne gere pas le temps d'execution pour les opérations : ASSIGN|DELETE|CLEAR
    [[ ${typ_prg} =~ (ASSIGN|DELETE|CLEAR) ]] && { msg "$fct_name:${typ_prg}:'temps execution' non géré" 7 ; return ; } || msg "${typ_prg}: 'temps execution' géré" 7 # DEBUG

    # "-n" : reference une autre variable = soit 'time_exec_deb', soit 'time_exec_fin'
    declare -n time_exec_var=time_exec_${time_sfx}
    # date et heure -> 'time_exec_deb' ou 'time_exec_fin' selon la variable "referencée" dans 'time_exec_var'
    eval ${!time_exec_var}=${quote}`date "+%D %T"`${quote}
    msg "$fct_parent:$fct_name:${!time_exec_var}=${time_exec_var}" 7 # DEBUG

    # Calcul temps d'execution = time_exec_fin - time_exec_deb
    declare time_exec=
    [[ ${time_sfx} = "fin" ]] && {
        time_exec=$(date -d @$(( $(date -d "$time_exec_fin" +%s) - $(date -d "$time_exec_deb" +%s) )) -u +'%Hh%Mm%Ss')
        msg "${fct_parent}:$fct_name:Temps Execution=${time_exec}" # INFO
        unset time_exec_deb    # Suppression variable "globale"

        # Si "time" est 'actif' ( /usr/bin/time : \time ) : Affichage statitiques supplémentaire
        [[ ${TIME_EXE} != "" ]] && msg "$(cat ${TIME_LOG})" # INFO
    }
    msg "$fct_name:Fin execution:$*:time_exec=$time_exec" 7 # DEBUG
}
# ----------------------------------------------------------------------
# On conserve la valeur "maxi" ou "mini" entre plusieurs variables
# Appel  : _max_min "[max]|min" var1 var2 ... var<n>
# Retour : value
# ----------------------------------------------------------------------
_max_min() {
    declare var= ret_val= oper=$1
    [[ $oper =~ (min|max) ]] && { ret_val=$2; shift; } || { oper=max; ret_val=$1; } # oper="max" si $1 different de "max|min"
    for var in "$@"; do
        case $oper in
          max) [[ $var > $ret_val ]] && ret_val=$var ;;
          min) [[ $var < $ret_val ]] && ret_val=$var ;;
        esac
    done
    return $ret_val
}
# ----------------------------------------------------------------------
# suppression des espaces AVANT et APRES dans une variable
# Appel  : $(_trim Variable)
# Retour : Variable
# ----------------------------------------------------------------------
_trim() {
    echo $(echo $1 | xargs)
}
# ----------------------------------------------------------------------
# Generation d'une date format : ISO-8601 UTC
# Appel  : $(_date_utc)
# Retour : Variable => 2025-02-06T15:08:57.097Z
# ----------------------------------------------------------------------
_date_utc () {
    declare date_utc=$(date -u --iso-8601=ns | sed s/,/./)   # ISO-8601 UTC nanosecondes
    echo ${date_utc:0:23}Z
}

_bdd_pwd() {
    declare fct_name=${FUNCNAME[0]}
    msg "$fct_name:Debut execution:$*" 7 # DEBUG
    _fct_is_exec $fct_name || return 0 # Test si fonction est "executable"

    declare msg_lib="$fct_name:Gestion mot de passe:MDB_PGCNX_PWD=${MDB_PGCNX_PWD}"

    case ${MDB_PGCNX_PWD} in
      # creation ".pgpass" file = "hostname:port:database:username:password"
      passfile)
        declare pass_line="${MDB_PGHOST}:${MDB_PGPORT}:${MDB_PGBASE}:${MDB_PGUSER}:${MDB_PGPSWD}"
        msg_lib="$msg_lib:fichier ${MDB_PGFIC_PWD}"
        file_exist ${MDB_PGFIC_PWD} || { # Creation du fichier si absent
            > ${MDB_PGFIC_PWD}
            chmod 0600 ${MDB_PGFIC_PWD}
            drop_pgpass=true
        }
        [[ `grep -e "${pass_line}" ${MDB_PGFIC_PWD}` = "" ]] && echo ${pass_line} >> ${MDB_PGFIC_PWD}
        ;;
      # via variable PGPASSWORD
      password)
        msg_lib="$msg_lib:creation variable PGPASSWORD"
        export PGPASSWORD=${MDB_PGPSWD}
        ;;
      *)
        msg_lib="$msg_lib:via serveur API" ;;
    esac
    msg "$msg_lib" 5 # NOTICE
    msg "$fct_name:Fin execution:$*" 7 # DEBUG
}

# ----------------------------------------------------------------------
# Options "psql" ( sera chargé par 'serdep' en PROD )
# ----------------------------------------------------------------------
_bdd_opt() {
    declare fct_name=${FUNCNAME[0]}
    msg "$fct_name:Debut execution:$*" 7 # DEBUG
    _fct_is_exec $fct_name || return 0 # Test si fonction est "executable"

    MDB_PGFIC_SQLRC=${MDB_PGFIC_SQLRC:-"$HOME/.psqlrc"}
    msg "$fct_name:Ajout option(s) $MDB_PGOPTION dans $MDB_PGFIC_SQLRC" 7 # DEBUG
    msg_lib="$fct_name:Option(s)"

    IFS=","; declare opt=""
    touch ${MDB_PGFIC_SQLRC}
    for opt in $MDB_PGOPTION; do
        msg_lib="$msg_lib:$opt"
        [[ `grep -e "${opt}" ${MDB_PGFIC_SQLRC}` = "" ]] && echo "\set ${opt}" >> ${MDB_PGFIC_SQLRC}
    done
    IFS=$OLDIFS
    msg "$msg_lib" 5 # NOTICE
    msg "$fct_name:Fin execution:$*" 7 # DEBUG
}

# ----------------------------------------------------------------------
# la fonction _fct_medoc_init() est executée dans 'deb_job' :
#   - Initialise les variables GLOBALES necessaires pour execution JOB
#     + affichage Fonctions Publiques|PRIVEES si executable (true|false)
#     + connexion BdD, ...
# ----------------------------------------------------------------------
_fct_medoc_init() {
    declare fct_name=${FUNCNAME[0]}
    msg "$fct_name:Debut execution:$*" 7 # DEBUG

    # Definition du TABLEAU "FCT_EXEC" des Fonctions EXECUTABLES" ou PAS ( cf _fct_is_exec )
    _0_fct_init

    # Inititialisation variables internes GLOBALES aux JOBs Medoc-db
    _0_var_init

    # Affichage Autorisations d'execution des Fonctions : true|false
    declare msg_fct=""
    for key in "${!FCT_EXEC[@]}"; do
        msg_fct="${msg_fct}:${key}=${FCT_EXEC[$key]}"
    done
    msg "Fonctions Executables[true|false]${msg_fct}" # INFO

    # Affichage parametrage du GCSORT
    msg "Programme GCSORT et Options:$GCSORT" # INFO

    # Affichage des variables générales MedocDb
    logVTOM      # cf medoc_log.sh
    logEQVLDATV  # cf eqvaldatv.sh
    # Affichage des variables spécifiques au JOB dont $MDB_APP/config/${JOBNAME}.sh
    logVariables

    msg "$fct_name:Fin execution:$*:CONTINUE:${CONTINUE}:CR_MAX=$CR_MAX:SEV:$SEV" 7 # DEBUG
}
# ----------------------------------------------------------------------
# la fonction _fct_medoc_fini() est executée dans 'fin_job' :
#     - Deconnexion BdD, ...
# ----------------------------------------------------------------------
_fct_medoc_fini() {
    declare fct_name=${FUNCNAME[0]}
    msg "$fct_name:Debut execution:$*" 7 # DEBUG

    # Restore IFS original : ' \t\n'
    IFS=$OLDIFS;

    # suppression variable CONTINUE : pour enchainement scripts multi-job ( medocdb_scripts_exec.sh )
    unset CONTINUE

    # Supprimer le trap ERR
    trap - ERR

    msg "$fct_name:Fin execution:$*" 7 # DEBUG
}



# ----------------------------------------------------------------------
# Éxecute les fichiers pre/post_phase{jobname} s’ils existent
# 1 paramètre: le nom du fichier sans '.sh' [pre|post_job_{jobname}]
# ----------------------------------------------------------------------
script_prepost() {
  declare fct_name=${FUNCNAME[0]}
  msg "$fct_name:Debut execution:$*" 7 # DEBUG
  file="${1}"
  local ret=0
  if [ -x "${MDB_SCRIPTS}/${file}.sh" ]; then
    . ${MDB_SCRIPTS}/${file}.sh
    ret=$?
    if [[ ! $ret -eq 0 ]]; then
        msg "$fct_name: ERREUR exec script ${file}.sh = $ret" 7
       return 1
    fi
  fi
  return 0
}

# ----------------------------------------------------------------------
# Valorise les variables MDB_{BELEM|MICADO}_PGSQL_CONN_STRING avec api de connexion
# 3 paramètres: micado[true|false], domaine[$EQAMMDOM], type_bdd[LECT|MAJ]
# ----------------------------------------------------------------------
set_conn_strings() {

  declare fct_name=${FUNCNAME[0]}
  msg "$fct_name:Debut execution:$*" 7 # DEBUG
  _fct_is_exec $fct_name || return 0 # Test si fonction est "executable"

  local domaine=$1
  local micado=$2
  local type_bdd=$3
  local type_instance=$([[ "$domaine" == "Z00"  ]] && echo "NAT" || echo "GEO")
  
  ## test parametres
  local domaine_liste=("XAM" "XLF" "XMH" "XPA" "XRA" "XRB" "XMY" "X00" "X33" "X35" "X44" "X75" "X77" "X78" "X86" "X97" "X98" "C01" "C02" "C03" "C04" "C05" "C06" "C00" "M00" "N00" "R00" "Z00")
  if [[ ! " ${domaine_liste[*]} " =~ " ${domaine} " ]]; then
    msg "$fct_name: ERREUR : Le domaine ${domaine} n'est pas inclu dans ${domaine_liste[@]}" 7
    return 1 #exit 1
  fi
  local type_bdd_liste=("MAJ" "LECT")
  if [[ "$micado" == "true" && ! " ${type_bdd_liste[*]} " =~ " ${type_bdd} " ]]; then
    msg "$fct_name: ERREUR : Le type_bdd ${type_bdd} n'est pas inclu dans ${type_bdd_liste[@]}" 7
    return 1 #exit 1
  fi

  ## valorisation des urls belem & micado
  if [[ "${MDB_API_CNX_ENABLED}" = "true" ]]; then
    _curl_api_connexion "" "type-instance=BEL"
    if [[ $? -eq 0 ]]; then
        export MDB_BELEM_PGSQL_CONN_STRING="postgresql://${MDB_PGUSER}@${MDB_PGHOST}:${MDB_PGPORT}/${MDB_PGBASE}"
    else 
        msg "$fct_name: ERREUR : appel api connexion BELEM" 7
        return 1
    fi
    if [[ "${micado}" = "true" ]]; then
        if [[ $type_instance == "NAT" ]]; then
            _curl_api_connexion "" "type-bdd=${type_bdd}&type-instance=${type_instance}"
            if [[ $? -eq 0 ]]; then
                export MDB_MICADO_PGSQL_CONN_STRING="postgresql://${MDB_PGUSER}@${MDB_PGHOST}:${MDB_PGPORT}/${MDB_PGBASE}"
            else
                msg "$fct_name: ERREUR : appel api connexion NAT" 7
                return 1
            fi
        else
            _curl_api_connexion $domaine "type-bdd=${type_bdd}&type-instance=${type_instance}"
            if [[ $? -eq 0 ]]; then
                if [[ ${MDB_ETAT_COULOIR,,} == "batch" ]]; then
                    export MDB_MICADO_PGSQL_CONN_STRING="postgresql://${MDB_PGUSER}@${MDB_PGHOST}:${MDB_PGPORT}/${MDB_PGBASE}"
                else
                    msg "$fct_name: ERREUR : etat attendu <batch> / obtenu <$MDB_ETAT_COULOIR>" 7
                    return 1
                fi
            else
                msg "$fct_name: ERREUR : appel api connexion GEO" 7
                return 1
            fi
        fi
    fi
  fi
  return 0
}

_curl_api_connexion() {
    declare fct_name=${FUNCNAME[0]}
    local domaine=$1
    local query_string=$2
    # le domaine est précisé, on a besoin d'un couloir pour appeler l'api de connexion
    # on appelle l'api en mode couloir
    if [[ $domaine != "" ]]; then
        local api_couloir_curl="http://${MDB_API_HOST}:${MDB_API_PORT}/medocdbapi/api/couloirs?domaine=${domaine}"
        local api_couloir_json="api_couloir.json"
        # appel à l'api pour récupérer le couloir
        local http_code_couloir=$(curl -o ${api_couloir_json} -w '%{response_code}' --silent ${api_couloir_curl})
        if [[ $http_code_couloir -eq 200 ]]; then
            export MDB_COULOIR=$(jq  -r '.[].code' ${api_couloir_json})
            export MDB_ETAT_COULOIR=$(jq  -r '.[].etat' ${api_couloir_json})
            export MDB_DATMAJ=$(jq  -r '.[].datmaj' ${api_couloir_json})
            #mise à jour de la query de l'api de connexion avec le couloir
            query_string="${query_string}&couloir=${MDB_COULOIR}"
        else
            msg "$fct_name: ERREUR : appel API couloir - http_code = $http_code_couloir" 7
            return 1
        fi
    fi
    # on appelle l'api en mode connexion
    local api_connexion_curl="http://${MDB_API_HOST}:${MDB_API_PORT}/medocdbapi/api/connexion?${query_string}"
    local api_connexion_json="retour_api.json"
    local http_code_connexion=$(curl -o ${api_connexion_json} -w '%{response_code}' --silent ${api_connexion_curl})
    if [[ $http_code_connexion -eq 200 ]]; then
        export MDB_PGUSER=$(jq  -r '.user' ${api_connexion_json})
        export MDB_PGHOST=$(jq  -r '.host' ${api_connexion_json})
        export MDB_PGPORT=$(jq  -r '.port' ${api_connexion_json})
        export MDB_PGBASE=$(jq  -r '.dbname' ${api_connexion_json})
    else
        msg "$fct_name: ERREUR : appel API connexion - http_code = $http_code_connexion" 7
        return 1
    fi
    return 0
}

exec_pre_phases() {
    local fct_name=${FUNCNAME[0]}
    local ret=0
    msg "$fct_name:Debut execution:$*" 7
    
    local job_domaine=$1
    local job_use_appli_bdd=$2
    local job_type_bdd=$3

    # Exécution de pre_job
    script_prepost "pre_job_${JOBNAME}"
    ret=$?
    if [[ ! $ret -eq 0 ]]; then
        msg "$fct_name : ERREUR script_prepost = ${ret}" 7 # DEBUG
        return 1
    fi

    set_conn_strings ${job_domaine} ${job_use_appli_bdd} ${job_type_bdd}
    ret=$?
    if [[ ! $ret -eq 0 ]]; then
        msg "$fct_name : ERREUR set_conn_strings = ${ret}" 7 # DEBUG
        return 1
    fi
    # Début du job
    deb_job
    ret=$?
    if [[ ! $ret -eq 0 ]]; then
        msg "$fct_name : ERREUR deb_job = ${ret}" 7 # DEBUG
        return 1
    fi
    return 0
}

exec_post_phases() {
    local fct_name=${FUNCNAME[0]}
    local ret=0
    msg "$fct_name:Debut execution:$*" 7

    # fin du job
    fin_job
    ret=$?
    if [[ ! $ret -eq 0 ]]; then
        msg "$fct_name : ERREUR fin_job = ${ret}" 7 # DEBUG
        return 1
    fi
    # exécution du post job
    script_prepost "post_job_${JOBNAME}"
    ret=$?
    if [[ ! $ret -eq 0 ]]; then
        msg "$fct_name : ERREUR script_prepost = ${ret}" 7 # DEBUG
        return 1
    fi
    return 0
}

# FIN DU FICHIER DES FONCTIONS "medoc_fct.sh"
