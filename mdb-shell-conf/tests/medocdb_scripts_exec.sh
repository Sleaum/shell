#!/usr/bin/env bash
# ---------------------------------------------------------------------------------------------------------------
#  Nom                   : medocdb_scripts_exec.sh
#  Création              : 18 Mai 2023 - Serge Corgnet
#  Auteur                : DGFiP - Tristana
#  Version de la SFG     : 0.1
#  Objet                 : Execution "à blanc" des scripts medoc_db, c'est à dire sans EXECUTION des FONCTIONS PUBLIQUES
#  Parametres            : medocdb_scripts_exec.sh -s [-c CHAINE] [-j JOB] -m nnnn
#                        : NB : tous les parametres sont optionnels => tous les scripts sont "executés"
#                        : -c CEECA   =  tous les JOB de la chaine CEECA
#                        : -j CEECA10X.sh = le JOB CEECA10X.sh de la chaine CEECA
#                        : -s ABSENT  =        MODIFICATION DES SCRIPTS pour les CAS SPECIAUX non gérés par le generateur : exec_sed()
#                        : -s PRESENT = PAS DE MODIFICATION DES SCRIPTS pour les CAS SPECIAUX non gérés par le generateur !
#                        : -m nnnn = Nbr Max de Job à executer : 9999 par defaut )
# ---------------------------------------------------------------------------------------------------------------
# Evolution/modification :--  date  --:-qui-:------------ libelle -----------------------------------------------
#    <Motif evol>        : 2023/05/18 : SCO : Création
# modifs manuelles       : 2023/05/29 : PJH : modifs sur les scripts issus du générateur
#       var_job          : 2023/06/26 : SCO : Constitution fichiers de configuration des variables spécifiques utilisées dans chaque JOB
#       -s               : 2023/09/01 : SCO : MDB_LOG_LEVEN=n : 7=DEBUG|[6=INFO]|5=NOTICE|4=WARNING|3=ERROR|2=CRITIC|1=ALERT|0=EMERG
# ---------------------------------------------------------------------------------------------------------------

MDB_ROOTDIR="${MDB_ROOTDIR:-$HOME}"
MDB_APP="${MDB_ROOTDIR}/application"
MDB_SCRIPTS="${MDB_APP}/scripts"
MDB_SCRIPTS_LIB="${MDB_SCRIPTS}/lib"
MDB_CONFIG="${MDB_APP}/config"

# Execution Envt PJH ...
# MDB_SCRIPTS="${MDB_SCRIPTS}/chaines"
# MDB_SCRIPTS_LIB="../jobs/lib"

# ---------------------------------------------------------------------------------------------------------------
# Preparation execution des JOBs MEDOC-DB à BLANC
# ---------------------------------------------------------------------------------------------------------------
VTOM_EXEC=false
# Initialisation LOG
FIC_LOG_CHN=${FIC_LOG_CHN:-"$HOME/medocdb_scripts_exec.log"}
[[ -f ${FIC_LOG_CHN} ]]  && mv ${FIC_LOG_CHN} ${FIC_LOG_CHN}.`date "+%Y%m%d_%H%M%S"`
> ${FIC_LOG_CHN}

# Permet d'executer les scripts depuis le repertoire courant
PATH=.:$PATH

# PREPARATION "DEBRAYAGE" des FONCTIONS :
# la declaration du Tableau FCT_EXEC viendra "surcharger" celui declaré dans "medoc_fct.sh"
declare -gA FCT_EXEC=(      # -g=GLOBAL -A=ASSOCIATIF
    [exec_prog]=false
    [_path_prog]=false      # Fct Privée appelée par "exec_prog"
    [exec_sort]=false
    [exec_sql]=false
    [file_exist]=true
    [file_assign]=false
    [file_cat]=false
    [file_copy]=false
    [file_rename]=false
    [file_delete]=false
    [file_clear]=false
    [_bdd_cnx]=true
    )
# Passer le Tableau "FCT_EXEC" sous forme de variable afin d'etre lu dans "medoc_fct.sh" avec les valeurs ci-dessus !
export FCT_EXEC_LIST=$(declare -p FCT_EXEC)

# ----------------------------------------------------------------------
# Fonctions
# ----------------------------------------------------------------------
#
usage(){
    msg_log "medocdb_scripts_exec.sh -s [-c CHAINE] [-j JOB] : Si -s ABSENT => Modification des scripts pour les CAS SPECIAUX non gérés par le generateur "
    return 1
}
# suppression des espaces AVANT et APRES dans une variable
_trim(){
    echo `echo $1 | xargs`
}
# ----------------------------------------------------------------------
# Préparation affichage des Messages en fonction du "niveau" passé à msg()
#   L'affichage des messages sera conditionné par le NIVEAU de TRACES
#    export MDB_LOG_LEVEL=n  # Modifier le niveau d'affichage des messages
#      avec n = 7=DEBUG|[6=INFO]|5=NOTICE|4=WARNING|3=ERROR|2=CRITIC|1=ALERT|0=EMERG
# ----------------------------------------------------------------------
_msg() {
    # Niveau de trace par defaut pour affichage à l'ecran et ecriture dans ${FIC_LOG}
    NIV_MSG=${MDB_LOG_LEVEL:-6}              # 6=INFO
    MDB_LOG_LEVEL=${MDB_LOG_LEVEL:-$NIV_MSG} # Niveau de TRACES dans la log via 'msg()' vaut 6=INFO par defaut
    NIV_LOGGER=${MDB_LOGGER_LEVEL:-$NIV_MSG} # Niveau 'logger': NIV_LOGGER doit etre > NIV_MSG pour ecrire "/var/log/syslog"

    # Gestion des messages selon niveau (niv_msg) d'information à afficher (cf https://www.linuxtricks.fr/wiki/syslog-les-journaux-systeme-sous-linux)
    nrml=""       # niv_msg
    dbug="DEBUG." #    7
    info="INFO."  #    6
    noti="NOTIC"  #    5
    wrng="WARNG"  #    4
    erro="ERROR"  #    3
    crtc="CRITC"  #    2
    alrt="ALERT"  #    1
    emrg="EMERG"  #    0
    ukwn="UNKWN"  #    *
    # Affichage des Messages en couleur : "VTOM_EXEC=false" dans le job
    ! ${VTOM_EXEC} && {                 # si true => Lancé par VTOM en PROD => pas de message en couleur
        nrml='\033[00m'                 # white
        dbug='\033[1;34m'"DEBUG"$nrml  # blue
        info='\033[1;36m'"INFO."$nrml  # green
        noti='\033[1;32m'"NOTIC"$nrml  # green lemon
        wrng='\033[1;33m'"WARNG"$nrml  # yellow
        erro='\033[1;31m'"ERROR"$nrml  # red
        crtc='\033[7;31m'"CRITC"$nrml  # red 'HighLight'
        alrt='\033[5;31m'"ALERT"$nrml  # red 'blink'
        emrg='\033[5;31m'"EMERG"$nrml  # red 'blink'
        ukwn='\033[35m'"UNKWN"$nrml    # purple
    }
    return 0
}
# Affichage des messages + log de ce script !
msg_log() {
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

    # Affichage du message à l'ecran + Ecriture du message dans la log
    echo -e "$dh|${lib_niv}|${lib_msg}" | tee -a ${FIC_LOG_CHN}
}

# -------------------------------- exec_sed -------------------------------------
# Fonction de modification des scripts pour les CAS SPECIAUX non gérés par le generateur...
# ------------------------------------------------------------------------------------------------
exec_sed() {
    declare fct_name=${FUNCNAME[0]}
    msg_log "Debut execution $fct_name:sed sur les chaines" # INFO


    echo "souhaitez-vous MODIFIER LES SCRIPTS AVANT l'EXECUTION A BLANC ? y|[n]"
    read
    [[ ! $REPLY = "y" ]] && { msg_log " PAS DE MODIFICATION DES SCRIPTS !!!" ; return ; }

    msg_log "Modification des scripts en cours...." # INFO

    # modifs manuelles sur les scripts issus du générateur :
    for chaine in $(find ${MDB_SCRIPTS} -type f -name "*.sh"); do

      sed -i -e 's#${BK/&UCFG}SV0M#${BK}/${UCFGSV0M}#'      \
             -e 's#${BK/CLIEN}TR_#${BK}/CLIENTR_#'          \
             -e 's#${BK/&RON\!}\!#${BK}/${RON}#'            \
             -e 's/RON!/RON/g'                              \
             -e 's!&amp;!!g'                                \
             -e 's!BK/UCFG=${BK/UCFG}!UCFGSV0M=${UCFGSV0M}!'\
             -e 's!BK/CLIEN=${BK/CLIEN}!CLIENTR=!'          \
             -e 's!BK/RON=${BK/RON}!RON=!'                  \
             -e 's! 104B01! v104B01!'                       \
             -e 's! 921FTP! v921FTP!'                       \
             -e 's! 921CFT! v921CFT!'                       \
             -e 's! 921CFT! v921CFT!'                       \
             -e 's! 204FTP! v204FTP!'                       \
             -e 's! 3950MD! v3950MD!'                       \
             -e 's/&}CANOMTDS/}${CANOMTDS}/'                \
             -e 's/,=/=/'                                   \
             -e 's/,}/}/'                                   \
             -e 's/DV.//'                                   \
             -e 's/${MDB_JCL}/${MDB_TEMP}/'                 ${chaine}   # SCO 2026/06/15  cf : CFTUCAS

      # sed -i -E 'd/^  msg BK/RON=${BK/RON}$/'              \
      # sed -i -E 'd/^  msg BK/CLIEN=${BK/CLIEN}$/'          \

    done

    # CAS SPECIFIQUE
    msg_log "Debut execution $fct_name:sed sur les chaines specifiques" # INFO
    sed -i '55,56s/UCFGSV0"/UCFGSV0_1"/'     ${MDB_SCRIPTS}/EXPLOIT/MDCBC18X.sh
    sed -i '78,83s/UCFGSV0"/UCFGSV0_1"/'     ${MDB_SCRIPTS}/EXPLOIT/MDCBC18X.sh

    sed -i -E 's/!!&I}D_SITE/}${ID_SITE}/'   ${MDB_SCRIPTS}/EXPLOIT/MDIEH6RX.sh
    sed -i -E 's/!!&S}TFNMCSI/}${STFNMCSI}/' ${MDB_SCRIPTS}/EXPLOIT/MDIEH6RX.sh
    sed -i -E 's/!![IS]//g'                  ${MDB_SCRIPTS}/EXPLOIT/MDIEH6RX.sh

    sed -i -E 'd/^  msg FIC1=${FIC1}$/'      ${MDB_SCRIPTS}/EXPLOIT/MDIEH6RX.sh
    sed -i -E 'd/^  msg FIC2=${FIC2}$/'      ${MDB_SCRIPTS}/EXPLOIT/MDIEH6RX.sh

    sed -i -e 's/AND1/AND,1/g' -e 's/  (//'  ${MDB_SCRIPTS}/MDAAD/MDAAD06X.sh

    msg_log "Fin execution $fct_name:sed sur les chaines" # INFO

    # FIN modifs gcsort manuelles PJH
}

# -------------------------------- var_job -------------------------------------
# Fonction de :
# - Initialisation fichiers de configuration des variables specifiques d'un JOB autres que VTOM
# - NB : Construction d'un tableau des variables spécifiques ... pour "statisitiques" :
#      - Nombre d'Utilisation de chaque variable par JOB MEDOC-DB
# ------------------------------------------------------------------------------------------------

# VAR_EQVAL liste des variables "connues" de VTOM
VAR_VTOM="MACHINE,RON,BK,EQADOMMC,EQADOMJJ,EQAMMC_A,EQAMMDOM,EQAMMCMM,EQAMMC_C,EQANATMC,EFADOMMC,EQ__DATE,EQAAMMJJ,EQJJMMAA,EQ__MMJJ,EQANNEE4,EQJOURAA,EQJOURMM,EQJOURJJ,EQJOURQQ,EQJOURML,EQJ_1MJJ,EQJ_1QQQ,EQJ_1_MM,EQJP1_AA,EQS_1NUM,EQM_1_MM,EQM_1_AA,EQM_1DJJ,EQM_1DJM,EQANN_14,EQANN_1M,EQMDCA_1,EQMDCTRI"

# Declaration tableau associatif des Variables spécifiques utilisées dans les JOBs ( comptage des utilisations / Job )
declare -A VAR_LIST=()

var_job(){
    # traitement des variables d'un JOB
    declare job_name=$1
    msg_log "Debut analyse variables de ${JOBNAME} : en cours...."  7 # DEBUG

    # Initialisation fichier de configuration de variables
    declare VAR_CONF=${MDB_CONFIG}/${JOBNAME}.sh
    declare init_conf=true

    # Recherche des variables du JOB
    while IFS= read var
    do
        msg_log "var_job:${JOBNAME}:read var : $var" 7 # DEBUG

        # On ne traite que les VARIABLES n'appartenant pas à la liste des VARIABLES VTOM
        if ! grep -q $var <<< $VAR_VTOM; then
            msg_log "Ajout variable : $var"  7 # DEBUG

            ${init_conf} && { # Initialisation fichier au 1er passage ( si true )
                init_conf=false
                echo "# ${JOBNAME} : Configuration Variable(s) Spécifique(s)" > ${VAR_CONF}
                }
            # Ajout Variable(s) trouvée(s) dans le fichier de config du JOB
            echo "export $var='A_INITIALISER'" >> ${VAR_CONF}

            # MAJ du Compteur d'utilisation des variables : "1 à n" utilisation dans les JOBs
            declare cpt_var=${VAR_LIST[${var}]#*:}
            let "cpt_var++"
            VAR_LIST[${var}]=$cpt_var
        fi

    done <<< $(grep -e"=\${" ${job_name} | cut -d: -f2 | grep -E "^  msg" | cut -d= -f1 | sort -u | sed -e 's/  msg //' -e 's/\"//' )

    [ -v cpt_var ] && msg_log "var_job:${VAR_CONF}:créé" || msg_log "var_job:${VAR_CONF}:non créé"
    msg_log "var_job:${JOBNAME}:ok" 7 # DEBUG
}

# ------------------------------------- lanc_job -----------------------------------------------
# Lancement job  $1 -> job_name
# ------------------------------------------------------------------------------------------------
lanc_job(){
    declare job_name=$1

    [[ $nb_job_ex -ge $MAX_JOB_TO_RUN ]] && {
        msg_log "Nombre de job's executés=$nb_job_ex = MAX_JOB_TO_RUN=$MAX_JOB_TO_RUN Job's MAX" # INFO # Permet de ne lancer qu'un certain nombre de Job's max
        return 9 ; }

    echo "."
    msg_log "Debut lancement de ${job_name} : en cours...." 5 # INFO

    # ------------------------------------------------------------------
    # Execution du job avec "trap" des erreurs de syntaxe bash !
    # ------------------------------------------------------------------
    TMP_LOG=/tmp/error_shell.log
    . ${job_name} "trap" 2>${TMP_LOG}

    CR=$?

    ((nb_job_ex++))   # incrementation nombre de jobs executés

    # Recherche des erreurs dans :
    # 1 - la log des erreurs : cf ${TMP_LOG}
    declare err_lib= #`grep -v "^2023" ${TMP_LOG}`  # | grep -v "LC_COLLATE"
    # 2 - la log du job exécuté     : cf ${FIC_LOG}
    err_lib=$err_lib`grep -E "ERROR|FATAL|ABORT|DATAERR|CRITC" ${FIC_LOG} | grep -v "Type Erreur à rechercher"` #

    [[ -n ${err_lib} ]] && { echo "$err_lib" >> ${FIC_LOG_CHN}; ((nb_job_ko++)) ; msg_log "$JOBNAME executé AVEC ERREUR !:$err_lib"; } || { ((nb_job_ok++)) ; msg_log "$JOBNAME executé SANS ERREUR !"; }

    msg_log "nombre de jobs executés=${nb_job_ex}/ok=${nb_job_ok}/ko=${nb_job_ko}" # INFO

    msg_log "Fin   lancement de ${1} : terminé=$CR" # INFO
}

# -------------------------------------- MAIN -----------------------------------------
# Fonction principale :
#    Analyse des parametres passé au script
#    Inititialisation compteurs Jobs Executés/OK/KO
#    Boucle de lecture des 'job's' à executer dans chaque 'chaines'
#        -> execution de chacun d'entre eux tant que le nombre MAX de JOBs à labcés n'est pas atteint
# ------------------------------------------------------------------------------------------------
main(){
    declare fct_name=${FUNCNAME[0]}
    msg_log "Debut execution $fct_name:$0:$MDB_SCRIPTS:$*" # INFO

    # Analyse des parametres et arguments passés

    # job_modif=true : Execute la Modification des scripts issus du générateur avant de les executer
    declare chaine_name= job_name= job_modif=true

    unset OPTIND   # Obligatoire pour réentrance
    while getopts :c:j:m:s param; do
        msg_log "analyse param getopts=$OPTIND:OPTARG=${OPTARG}" #7 # DEBUG
        case $param in
            c) chaine_name=$(_trim ${OPTARG}); msg_log "chaine_name=${chaine_name}" ;;
            j) job_name=$(_trim ${OPTARG})   ; msg_log "job_name=${job_name}"   ;;
            m) MAX_JOB_TO_RUN=${OPTARG} ;      msg_log "MAX_JOB_TO_RUN=${MAX_JOB_TO_RUN}" ;;
            s) job_modif=false ;;
            *) usage; return 1 ;;
        esac
    done
    job_name=${job_name:-""} # initialisation chaine 'vide'
    msg_log "$fct_name:chaine_name=$chaine_name:job_name=$job_name:job_modif=$job_modif:MAX_JOB_TO_RUN=$MAX_JOB_TO_RUN" # INFO

    [[ ! -d $MDB_SCRIPTS ]] && msg_log "repertoire MDB_SCRIPTS=$MDB_SCRIPTS invalide" 3 && return 1 # ERROR
    msg_log "repertoire $MDB_SCRIPTS existe" 7 # DEBUG


    # Nombre MAXIMUM de job's à EXECUTER ( permet de ne pas tout lancer lors du test du programme )
    MAX_JOB_TO_RUN=${MAX_JOB_TO_RUN:-9999}
    # msg_log "Attention : nombre de JOB executés:MAX_JOB_TO_RUN=$MAX_JOB_TO_RUN" 4 # WARNING
    # msg_log "export MAX_JOB_TO_RUN=10 ou '-m 10' si vous souhaitez executer 10 JOBs seulement !" 4 # WARNING
    # msg_log "debut de l'exécution 'à blanc' des scripts MEDOCDB dans 3 secondes... ou <CTRL>C pour stopper l'execution !" 4 # WARNING
    # sleep 3

    # Modification des scripts issus du générateur..
    # $job_modif && exec_sed       # SCO 2023/09/01

    # determination "scripts_to_search"
    scripts_to_search="*.sh"
    [[ -n ${job_name} ]] && scripts_to_search="${job_name}"
    [[ -n ${chaine_name} ]] && { MDB_SCRIPTS=${MDB_SCRIPTS}/${chaine_name}; scripts_to_search="*.sh"; }
    msg_log "Analyse repertoire $MDB_SCRIPTS pour JOB = ${scripts_to_search}"

    declare -ig nb_job_ex=0   # nombre de jobs executés
    declare -ig nb_job_ok=0   # nombre de scripts OK ( SANS ERREUR )
    declare -ig nb_job_ko=0   # nombre de scripts KO ( AVEC ERREUR )

    # Boucle de recherche des scripts MEDOCDB, eventuellement en fonction des parametres -c et/ou -j
    for job_found in `find $MDB_SCRIPTS -type f -name "${scripts_to_search}" | sort  2>>${FIC_LOG_CHN}`
    do
        msg_log "-----------------------------------------------------------" 7 # DEBUG
        msg_log "Debut job : ${job_found}" 7 # DEBUG

        export JOBNAME=`basename ${job_found} | cut -f1 -d"."` # On doit definir 'JOBNAME' ici afin que la variable JOBNAME->'medoc_fct.sh' soit correcte
        unset JOBID

        # Recherche des variables autres que VTOM
        var_job "${job_found}"

        # Lancement execution "debrayée" du JOB
        lanc_job "${job_found}"
        [[ $? -eq 9 ]] && break # Nombre MAX de jobs executés atteint ( cf $MAX_JOB_TO_RUN )

        msg_log "Fin   job : ${job_found}" 7 # DEBUG
        msg_log "-----------------------------------------------------------"
    done

    # Affichage des variables trouvées en dehors de VAR_VTOM
    msg_log "..................................."
    msg_log "Variables VTOM: $VAR_VTOM"
    msg_log "Variables spécifiques.................."
    for key in "${!VAR_LIST[@]}"; do
        msg_log "${key} trouvée(s) dans ${VAR_LIST[$key]} JOB(s)"
    done

    msg_log "Fin  traitement $0 ..."
}

# execution programme principal

_msg # Applications des valeurs des messages et niveau de traces

# fct principale avec les "parametres : -c chaine -j job -m 99 -s "
main $*     # ATTENTION : ne pas ecrire 'main "$*"' sinon il n'y a qu'un seul parametre !!!

msg_log
msg_log " FIN TRAITEMENT TIR à BLANC des SCRIPTS MEDOCDB"
msg_log
msg_log "*==================================================="
msg_log " Nombre de scripts EXECUTES    : ${nb_job_ex}"
msg_log " Nombre de scripts SANS ERREUR : ${nb_job_ok}"
msg_log " Nombre de scripts AVEC ERREUR : ${nb_job_ko}"
msg_log "*==================================================="
msg_log
msg_log "Fichier log = ${FIC_LOG_CHN}"
