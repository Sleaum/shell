#!/usr/bin/env bats
# Tests des fonctions de configuration / API de lib/medoc_fct.sh :
# load_dom_config, set_conn_strings, _curl_api_connexion
# curl est remplacé par un bouchon : aucun appel réseau.

setup() {
    load common
    _common_setup

    command -v jq >/dev/null || skip "jq absent de cette machine"

    # Bouchon curl piloté par variables :
    #   CURL_HTTP_CODE (défaut 200), CURL_ETAT (état du couloir, défaut BATCH)
    cat > "$STUB_DIR/curl" <<'EOF'
#!/bin/bash
echo "$*" >> "$BATS_TEST_TMPDIR/curl.calls"
out="" ; wfmt="" ; url=""
while [[ $# -gt 0 ]]; do
    case $1 in
        -o) out=$2; shift ;;
        -w) wfmt=$2; shift ;;
        -s|-k|--silent) ;;
        *)  url=$1 ;;
    esac
    shift
done
case $url in
    *get_dom_vars*)  body=$(cat "$FIXTURES/dom_config.json") ;;
    *couloirs*)      body=$(sed "s/__ETAT__/${CURL_ETAT:-BATCH}/" "$FIXTURES/api_couloir.json") ;;
    *connexion*)     body=$(cat "$FIXTURES/api_connexion.json") ;;
esac
if [[ -n $out ]]; then echo "$body" > "$out"; else echo "$body"; fi
[[ -n $wfmt ]] && echo "${CURL_HTTP_CODE:-200}"
exit 0
EOF
    chmod +x "$STUB_DIR/curl"
    export FIXTURES

    # _curl_api_connexion écrit ses fichiers json dans le répertoire courant
    cd "$BATS_TEST_TMPDIR"
}

# ----------------------------------------------------- load_dom_config
@test "load_dom_config LOCAL exporte les variables du domaine" {
    MDB_DOM_CONFIG_SOURCE=LOCAL
    MDB_DOM_FIC="$FIXTURES/dom_config.json"
    load_dom_config X77
    assert_equal "$ID_SITE" "SITE1"
    assert_equal "$NOM_TDS" "TDS77"
    assert_equal "$CANBRTDS" "6"
    run bash -c 'echo $NOM_TDS'
    assert_output "TDS77"
}

@test "load_dom_config ignore les valeurs null" {
    MDB_DOM_CONFIG_SOURCE=LOCAL
    MDB_DOM_FIC="$FIXTURES/dom_config.json"
    unset VIDE
    load_dom_config X77
    assert_equal "${VIDE:-absent}" "absent"
}

@test "load_dom_config : domaine inconnu -> 1" {
    MDB_DOM_CONFIG_SOURCE=LOCAL
    MDB_DOM_FIC="$FIXTURES/dom_config.json"
    run load_dom_config ZZZ
    assert_failure
    assert_output --partial "No config found"
}

@test "load_dom_config : fichier absent -> 1" {
    MDB_DOM_CONFIG_SOURCE=LOCAL
    MDB_DOM_FIC="$DATA/absent.json"
    run load_dom_config X77
    assert_failure
    assert_output --partial "not found"
}

@test "load_dom_config sans domaine -> 1" {
    run load_dom_config
    assert_failure
}

@test "load_dom_config API exporte les variables du domaine" {
    MDB_DOM_CONFIG_SOURCE=API
    load_dom_config C01
    assert_equal "$NOM_TDS" "M2CE"
    run cat "$BATS_TEST_TMPDIR/curl.calls"
    assert_output --partial "get_dom_vars?domaine=C01"
}

@test "load_dom_config API en erreur HTTP -> exit 1 (arrêt du JOB)" {
    MDB_DOM_CONFIG_SOURCE=API
    export CURL_HTTP_CODE=500
    run load_dom_config C01
    assert_equal "$status" 1
    assert_output --partial "HTTP/500"
}

@test "le dom_config.json livré est un JSON valide avec un DOMAINE par entrée" {
    run jq -e 'all(.[]; has("DOMAINE"))' "$LIB_DIR/dom_config.json"
    assert_success
}

@test "le dom_config.json livré n'a pas de DOMAINE en double" {
    run jq -r '.[].DOMAINE' "$LIB_DIR/dom_config.json"
    local doublons
    doublons=$(echo "$output" | sort | uniq -d)
    assert_equal "$doublons" ""
}

# ---------------------------------------------------- set_conn_strings
@test "set_conn_strings : domaine inconnu -> 1" {
    run set_conn_strings ABC true MAJ
    assert_failure
}

@test "set_conn_strings : type_bdd invalide avec micado -> 1" {
    run set_conn_strings X77 true AUTRE
    assert_failure
}

@test "set_conn_strings : API désactivée -> 0 sans appel curl" {
    MDB_API_CNX_ENABLED=false
    run set_conn_strings X77 true MAJ
    assert_success
    assert_file_not_exists "$BATS_TEST_TMPDIR/curl.calls"
}

@test "set_conn_strings GEO couloir BATCH -> chaînes BELEM et MICADO" {
    MDB_API_CNX_ENABLED=true
    unset MDB_MICADO_PGSQL_CONN_STRING MDB_BELEM_PGSQL_CONN_STRING
    set_conn_strings X77 true MAJ
    assert_equal "$MDB_BELEM_PGSQL_CONN_STRING"  "postgresql://u_medoc@pg.test:5432/base_test"
    assert_equal "$MDB_MICADO_PGSQL_CONN_STRING" "postgresql://u_medoc@pg.test:5432/base_test"
    assert_equal "$MDB_COULOIR" "C7"
    run cat "$BATS_TEST_TMPDIR/curl.calls"
    assert_output --partial "couloirs?domaine=X77"
    assert_output --partial "type-bdd=MAJ&type-instance=GEO&couloir=C7"
}

@test "set_conn_strings GEO couloir pas en état batch -> 1" {
    MDB_API_CNX_ENABLED=true
    export CURL_ETAT=ADAME
    run set_conn_strings X77 true MAJ
    assert_failure
}

@test "set_conn_strings Z00 -> instance NAT, sans appel couloir" {
    MDB_API_CNX_ENABLED=true
    set_conn_strings Z00 true LECT
    assert_equal "$MDB_MICADO_PGSQL_CONN_STRING" "postgresql://u_medoc@pg.test:5432/base_test"
    run cat "$BATS_TEST_TMPDIR/curl.calls"
    refute_output --partial "couloirs"
    assert_output --partial "type-instance=NAT"
}

@test "set_conn_strings sans micado -> seulement BELEM" {
    MDB_API_CNX_ENABLED=true
    unset MDB_MICADO_PGSQL_CONN_STRING
    set_conn_strings X77 false
    assert_equal "$MDB_BELEM_PGSQL_CONN_STRING" "postgresql://u_medoc@pg.test:5432/base_test"
    assert_equal "${MDB_MICADO_PGSQL_CONN_STRING:-}" ""
}

@test "set_conn_strings : API connexion en erreur HTTP -> 1" {
    MDB_API_CNX_ENABLED=true
    export CURL_HTTP_CODE=503
    run set_conn_strings X77 true MAJ
    assert_failure
}
