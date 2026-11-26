#!/usr/bin/env bats
# Tests des fonctions utilitaires de lib/medoc_fct.sh :
# _trim, _date_utc, _max_min, msg, _fct_is_exec, _0_fct_init,
# _cr_max, _cr_test, gestion_exit_ops, _analyze_args

setup() {
    load common
    _common_setup
}

# --------------------------------------------------------------- _trim
@test "_trim supprime les espaces avant et après" {
    run _trim "   abc def   "
    assert_success
    assert_output "abc def"
}

@test "_trim d'une chaîne vide renvoie une chaîne vide" {
    run _trim ""
    assert_output ""
}

# ----------------------------------------------------------- _date_utc
@test "_date_utc renvoie une date ISO-8601 UTC à la milliseconde" {
    run _date_utc
    assert_success
    assert_output --regexp '^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}\.[0-9]{3}Z$'
}

# ------------------------------------------------------------ _max_min
@test "_max_min max renvoie la valeur la plus haute en code retour" {
    run _max_min max 0 3 1
    assert_equal "$status" 3
}

@test "_max_min min renvoie la valeur la plus basse en code retour" {
    run _max_min min 5 2 7
    assert_equal "$status" 2
}

@test "_max_min sans opérateur se comporte comme max" {
    run _max_min 1 4 2
    assert_equal "$status" 4
}

@test "BUG _max_min compare des nombres et non des chaînes (9 < 10)" {
    skip "BUG : [[ \$var > \$ret_val ]] compare en ordre alphabétique -> max(9,10)=9. Utiliser (( var > ret_val ))"
    run _max_min max 9 10
    assert_equal "$status" 10
}

# ----------------------------------------------------------------- msg
@test "msg affiche date|NIVEAU|libellé" {
    run msg "mon message" 6
    assert_success
    assert_output --regexp '^[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2}\|INFO\|mon message$'
}

@test "msg utilise INFO (6) par défaut" {
    run msg "sans niveau"
    assert_output --partial "|INFO|sans niveau"
}

@test "msg n'affiche pas un message plus verbeux que MDB_LOG_LEVEL" {
    MDB_LOG_LEVEL=3
    run msg "debug caché" 7
    assert_success
    assert_output ""
}

@test "msg affiche un message de niveau égal ou inférieur à MDB_LOG_LEVEL" {
    MDB_LOG_LEVEL=3
    run msg "erreur visible" 3
    assert_output --partial "|ERROR|erreur visible"
}

@test "msg envoie à logger quand le niveau est < NIV_LOGGER" {
    NIV_LOGGER=6
    LOGGER="logger -t $JOBNAME --sd-param composant="
    msg "alerte" 3
    assert_file_exists "$BATS_TEST_TMPDIR/logger.calls"
    run cat "$BATS_TEST_TMPDIR/logger.calls"
    assert_output --partial "alerte"
}

@test "msg n'envoie rien à logger si LOGGER est vide" {
    NIV_LOGGER=6
    LOGGER=""
    msg "rien" 3
    assert_file_not_exists "$BATS_TEST_TMPDIR/logger.calls"
}

# -------------------------------------------------------- _fct_is_exec
@test "_fct_is_exec : une fonction absente de FCT_EXEC est exécutable" {
    run _fct_is_exec file_copy
    assert_success
}

@test "_fct_is_exec : une fonction à false n'est pas exécutable" {
    FCT_EXEC[file_copy]=false
    run _fct_is_exec file_copy
    assert_failure
}

@test "_fct_is_exec remet SEV à 0 pour une fonction débrayée" {
    FCT_EXEC[file_copy]=false
    SEV=5
    _fct_is_exec file_copy || true
    assert_equal "$SEV" 0
}

# --------------------------------------------------------- _0_fct_init
@test "_0_fct_init sans FCT_EXEC_LIST active les fonctions fichiers" {
    unset FCT_EXEC_LIST
    MDB_API_CNX_ENABLED=false
    _0_fct_init
    assert_equal "${FCT_EXEC[file_copy]}" "true"
    assert_equal "${FCT_EXEC[_bdd_cnx]}" "false"
}

@test "BUG _0_fct_init applique FCT_EXEC_LIST (tir à blanc)" {
    skip "BUG : eval \$FCT_EXEC_LIST fait un 'declare -A' LOCAL à la fonction -> ignoré si le JOB est lancé dans un processus fils (bash JOB.sh). Sans impact avec medocdb_scripts_exec.sh qui source les JOBs. Corriger avec : eval \"\${FCT_EXEC_LIST/declare -A/declare -gA}\""
    declare -A tmp=([file_copy]=false)
    FCT_EXEC_LIST="$(declare -p tmp | sed 's/ tmp=/ FCT_EXEC=/')"
    _0_fct_init
    assert_equal "${FCT_EXEC[file_copy]}" "false"
}

# ------------------------------------------------------------- _cr_max
@test "_cr_max conserve le code retour le plus élevé" {
    _cr_max 3
    _cr_max 1
    assert_equal "$CR_MAX" 3
}

@test "_cr_max positionne NIV_MSG à ERROR (3) pour un CR de 3" {
    _cr_max 3
    assert_equal "$NIV_MSG" 3
}

@test "_cr_max positionne NIV_MSG à CRITICAL (2) pour un CR > 3" {
    _cr_max 4
    assert_equal "$NIV_MSG" 2
}

# ------------------------------------------------------------ _cr_test
@test "_cr_test : CR <= CR max autorisé -> SEV = CR, CR_MAX inchangé" {
    _cr_test COBOL 4 "$CR_MAX_COB" || true
    assert_equal "$SEV" 4
    assert_equal "$CR_MAX" 0
}

@test "_cr_test : SHELL au-delà du max -> SEV 3 (USER ERROR)" {
    run _cr_test SHELL 5 1
    assert_equal "$status" 3
}

@test "_cr_test : COBOL au-delà du max -> SEV 4 (SYSTEM ERROR)" {
    _cr_test COBOL 8 "$CR_MAX_COB" || true
    assert_equal "$SEV" 4
    assert_equal "$CR_MAX" 4
}

@test "_cr_test : GCSORT au-delà du max -> SEV 4" {
    run _cr_test GCSORT 16 "$CR_MAX_SRT"
    assert_equal "$status" 4
}

@test "_cr_test : type inconnu au-delà du max -> SEV 6 (SYSTEM CRASH)" {
    run _cr_test COPY 2 1
    assert_equal "$status" 6
}

@test "_cr_test : DELETE force le code retour à 0" {
    run _cr_test DELETE 127 1
    assert_success
}

@test "_cr_test remonte les lignes d'erreur de FIC_LOG" {
    echo "ABORT programme XYZ" >> "$FIC_LOG"
    run _cr_test COBOL 12 "$CR_MAX_COB"
    assert_output --partial "ABORT programme XYZ"
}

# ---------------------------------------------------- gestion_exit_ops
@test "gestion_exit_ops 0 ne quitte pas" {
    run gestion_exit_ops 0
    assert_success
}

@test "gestion_exit_ops non nul quitte avec 1" {
    run gestion_exit_ops 4
    assert_equal "$status" 1
}

# ------------------------------------------------------- _analyze_args
@test "_analyze_args positionne la variable si l'argument est présent" {
    JOB_PARAM_EXEC="-x -debug"
    unset COB_SET_DEBUG
    _analyze_args COB_SET_DEBUG Y -debug
    assert_equal "$COB_SET_DEBUG" "Y"
}

@test "_analyze_args ne positionne rien si l'argument est absent" {
    JOB_PARAM_EXEC="-x -y"
    unset COB_SET_DEBUG
    _analyze_args COB_SET_DEBUG Y -debug
    assert_equal "${COB_SET_DEBUG:-}" ""
}

@test "BUG _analyze_args ne doit pas accepter une correspondance partielle" {
    skip "BUG : [[ \"\$argToSearch\" =~ \"\$arg\" ]] -> '-d' ou 'e' active le mode debug. Utiliser [[ \"\$arg\" == \"\$argToSearch\" ]]"
    JOB_PARAM_EXEC="-d"
    unset COB_SET_DEBUG
    _analyze_args COB_SET_DEBUG Y -debug
    assert_equal "${COB_SET_DEBUG:-}" ""
}
