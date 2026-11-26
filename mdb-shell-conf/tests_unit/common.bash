# ---------------------------------------------------------------------------
# Initialisation commune à tous les tests unitaires Bats de mdb-shell-conf
# Appel : dans chaque fichier .bats ->  setup() { load common; _common_setup; }
# ---------------------------------------------------------------------------

_common_setup() {
    load "test_helper/bats-support/load"
    load "test_helper/bats-assert/load"
    load "test_helper/bats-file/load"

    LIB_DIR="$(cd "$BATS_TEST_DIRNAME/../lib" && pwd)"
    FIXTURES="$BATS_TEST_DIRNAME/fixtures"

    # --- Bouchons (stubs) : prioritaires dans le PATH -----------------------
    # logger : on n'écrit jamais dans le vrai syslog pendant les tests
    STUB_DIR="$BATS_TEST_TMPDIR/bin"
    mkdir -p "$STUB_DIR"
    cat > "$STUB_DIR/logger" <<EOF
#!/bin/bash
echo "\$*" >> "$BATS_TEST_TMPDIR/logger.calls"
EOF
    chmod +x "$STUB_DIR/logger"
    PATH="$STUB_DIR:$PATH"

    # --- Chargement des librairies, dans l'ordre des JOBs ------------------
    # (le warning setlocale sur fr_EB.iso88591 est filtré, le reste de stderr est conservé)
    source "$LIB_DIR/medoc_var.sh" 2> "$BATS_TEST_TMPDIR/medoc_var.err"
    grep -v "setlocale" "$BATS_TEST_TMPDIR/medoc_var.err" >&2 || true
    source "$LIB_DIR/medoc_log.sh"
    source "$LIB_DIR/medoc_fct.sh"

    # --- Neutralisation de l'environnement "prod" de medoc_var.sh ----------
    unset LD_PRELOAD                 # librairies absentes hors serveur MedocDB
    export LC_COLLATE=C              # fr_EB.iso88591 n'existe pas hors serveur
    export MDB_LOG="$BATS_TEST_TMPDIR/log"
    export MDB_TEMP="$BATS_TEST_TMPDIR/temp"
    export MDB_TMP="$MDB_TEMP"
    export DATA="$BATS_TEST_TMPDIR/data"   # répertoire de travail des tests
    mkdir -p "$MDB_LOG" "$MDB_TEMP" "$DATA"

    export JOBNAME="BATS_TEST"
    FIC_LOG="$MDB_LOG/${JOBNAME}.log"
    : > "$FIC_LOG"

    # --- Variables normalement posées par deb_job / _0_var_init ------------
    VTOM_EXEC=true                   # pas de couleurs -> sorties comparables
    MDB_LOG_LEVEL=6                  # INFO
    MDB_LOGGER_LEVEL=0               # aucun envoi logger depuis msg()
    _msg
    LOGGER=""
    OLDIFS=$IFS
    quote='"'
    TIME_EXE=""
    INIT_FILE=": >"                  # commande de vidage utilisée par file_clear

    SEV=0
    CR_MAX=0
    CR_MAX_COB=7
    CR_MAX_SRT=4
    CR_MAX_SQL=0
    CR_MAX_SHL=1
    CR_MAX_JOB=1
    MDB_ERR_LOG="ANORMALE|ERROR|FATAL|CRITIC|ABORT|DATAERR|refusé|échoué|failed"

    # Toutes les fonctions sont "exécutables" par défaut
    declare -gA FCT_EXEC=()
}
