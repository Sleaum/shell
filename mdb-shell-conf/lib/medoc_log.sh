#!/usr/bin/env bash
# -------------------------------------------------------------------------------------------------------------
#  Nom                   : medoc_log.sh
#  Création              : 21 mars 2023 - Serge Corgnet
#  Auteur                : DGFiP - Tristana
#  Version de la SFG     : 0.1
#  Appel dans les JOBs   : . ${MDB_SCRIPTS_LIB}/medoc_log.sh    # fonctions "log" medocdb compatible "Tristana"
# -------------------------------------------------------------------------------------------------------------
#  Fonctions "affichage variables d'environnemnt MEDOC-DB" : APPELABLES PAR LES JOBs MEDOC-DB

logVTOM () {
  msg "logVTOM......................"
  msg TOM_JOB_POINT=${TOM_JOB_POINT}
  msg PHASE_NEXT=${PHASE_NEXT}
  msg PHASE_STOP=${PHASE_STOP}
}

logEQVLDATV () {
  msg "logEQVLDATV.................."
  msg EQ__DATE=${EQ__DATE}
  msg EQAAMMJJ=${EQAAMMJJ}
  msg EQJJMMAA=${EQJJMMAA}
  msg EQ__MMJJ=${EQ__MMJJ}
  msg EQANNEE4=${EQANNEE4}
  msg EQJOURAA=${EQJOURAA}
  msg EQJOURMM=${EQJOURMM}
  msg EQJOURJJ=${EQJOURJJ}
  msg EQJOURQQ=${EQJOURQQ}
  msg EQJOURML=${EQJOURML}
  msg EQJ_1MJJ=${EQJ_1MJJ}
  msg EQJ_1QQQ=${EQJ_1QQQ}
  msg EQJ_1_MM=${EQJ_1_MM}
  msg EQJP1_AA=${EQJP1_AA}
  msg EQS_1NUM=${EQS_1NUM}
  msg EQM_1_MM=${EQM_1_MM}
  msg EQM_1_AA=${EQM_1_AA}
  msg EQM_1DJJ=${EQM_1DJJ}
  msg EQM_1DJM=${EQM_1DJM}
  msg EQANN_14=${EQANN_14}
  msg EQANN_1M=${EQANN_1M}
  msg EQMDCA_1=${EQMDCA_1}
  msg EQMDCTRI=${EQMDCTRI}
}
