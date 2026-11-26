#!/usr/bin/env bats
# Tests des fonctions "fichiers" de lib/medoc_fct.sh :
# file_exist, file_assign, _fic_ctrl, _fic_in_out,
# file_copy, file_rename, file_cat, file_clear, file_delete

setup() {
    load common
    _common_setup
    printf 'l1\nl2\nl3\n' > "$DATA/in.txt"
    printf 'l4\n'         > "$DATA/in2.txt"
}

# ---------------------------------------------------------- file_exist
@test "file_exist : fichier existant -> vrai" {
    run file_exist "$DATA/in.txt"
    assert_success
}

@test "file_exist : fichier absent -> faux" {
    run file_exist "$DATA/absent.txt"
    assert_failure
}

@test "file_exist sans argument -> faux" {
    run file_exist
    assert_failure
}

@test "file_exist d : répertoire existant -> vrai" {
    run file_exist "$DATA" d
    assert_success
}

@test "file_exist s : fichier vide -> faux" {
    : > "$DATA/vide.txt"
    run file_exist "$DATA/vide.txt" s
    assert_failure
}

@test "file_exist s : fichier non vide -> vrai" {
    run file_exist "$DATA/in.txt" s
    assert_success
}

@test "file_exist : type invalide -> faux + message ERROR" {
    run file_exist "$DATA/in.txt" x
    assert_failure
    assert_output --partial "parametre 2 invalide"
}

@test "BUG file_exist : type invalide ne doit pas provoquer d'erreur bash" {
    skip "BUG : 'return false' -> 'numeric argument required'. Remplacer par 'return 1'"
    run file_exist "$DATA/in.txt" x
    refute_output --partial "numeric argument required"
}

@test "file_exist débrayée (FCT_EXEC=false) renvoie vrai sans tester" {
    FCT_EXEC[file_exist]=false
    run file_exist "$DATA/absent.txt"
    assert_success
}

# --------------------------------------------------------- file_assign
@test "file_assign exporte IFN=EFN" {
    file_assign MONIFN "$DATA/in.txt"
    assert_equal "$MONIFN" "$DATA/in.txt"
    run bash -c 'echo $MONIFN'
    assert_output "$DATA/in.txt"
}

@test "file_assign sans EFN -> SEV 3" {
    run file_assign MONIFN
    assert_equal "$status" 3
    assert_output --partial "usage :file_assign"
}

# ----------------------------------------------- _fic_ctrl / _fic_in_out
@test "_fic_ctrl entree : fichier absent -> 3" {
    run _fic_ctrl "$DATA/absent.txt" entree
    assert_equal "$status" 3
}

@test "_fic_ctrl sortie : répertoire existant -> 0" {
    run _fic_ctrl "$DATA/sortie.txt" sortie
    assert_success
}

@test "_fic_ctrl sortie : répertoire absent -> 3" {
    run _fic_ctrl "$DATA/inexistant/sortie.txt" sortie
    assert_equal "$status" 3
}

@test "_fic_ctrl : nom vide -> 3" {
    run _fic_ctrl "" entree
    assert_equal "$status" 3
}

@test "_fic_in_out : fichiers identiques -> SEV 3" {
    run _fic_in_out "$DATA/in.txt" "$DATA/in.txt"
    assert_equal "$status" 3
    assert_output --partial "fichiers identiques"
}

@test "_fic_in_out : fichiers différents -> 0" {
    run _fic_in_out "$DATA/in.txt" "$DATA/out.txt"
    assert_success
}

# ----------------------------------------------------------- file_copy
@test "file_copy copie le fichier" {
    run file_copy -i "$DATA/in.txt" -o "$DATA/out.txt"
    assert_success
    assert_files_equal "$DATA/in.txt" "$DATA/out.txt"
    assert_output --partial "Nombre de lignes dans le fichier SORTIE:$DATA/out.txt=3"
}

@test "file_copy : entrée = sortie -> SEV 3, rien n'est exécuté" {
    run file_copy -i "$DATA/in.txt" -o "$DATA/in.txt"
    assert_equal "$status" 3
    refute_output --partial "en cours..."
}

@test "file_copy : option inconnue -> SEV 3 + usage" {
    run file_copy -z
    assert_equal "$status" 3
    assert_output --partial "usage :file_copy"
}

@test "file_copy débrayée : la commande cp n'est pas lancée" {
    FCT_EXEC[file_copy]=false
    run file_copy -i "$DATA/in.txt" -o "$DATA/out.txt"
    assert_file_not_exists "$DATA/out.txt"
}

@test "BUG file_copy : entrée absente -> SEV 3 sans lancer cp" {
    skip "BUG : SEV=\$(_max_min ...) capte la sortie (vide) au lieu du code retour -> le contrôle est ignoré et cp est lancé"
    run file_copy -i "$DATA/absent.txt" -o "$DATA/out.txt"
    assert_equal "$status" 3
    refute_output --partial "cannot stat"
}

# --------------------------------------------------------- file_rename
@test "file_rename renomme le fichier" {
    run file_rename -i "$DATA/in.txt" -o "$DATA/renomme.txt"
    assert_success
    assert_file_not_exists "$DATA/in.txt"
    assert_file_exists "$DATA/renomme.txt"
}

@test "BUG file_rename : répertoire de sortie absent -> SEV 3 sans lancer mv" {
    skip "BUG : même cause que file_copy (SEV=\$(_max_min ...))"
    run file_rename -i "$DATA/in.txt" -o "$DATA/inexistant/x.txt"
    assert_equal "$status" 3
    assert_file_exists "$DATA/in.txt"
}

# ------------------------------------------------------------ file_cat
@test "file_cat concatène plusieurs fichiers à la suite de la sortie" {
    echo "l0" > "$DATA/cat.txt"
    run file_cat -i "$DATA/in.txt, $DATA/in2.txt" -o "$DATA/cat.txt"
    assert_success
    run cat "$DATA/cat.txt"
    assert_output "$(printf 'l0\nl1\nl2\nl3\nl4')"
}

@test "file_cat restaure IFS après traitement" {
    file_cat -i "$DATA/in.txt" -o "$DATA/cat.txt"
    assert_equal "$IFS" "$OLDIFS"
}

@test "file_cat ignore une entrée identique à la sortie" {
    cp "$DATA/in.txt" "$DATA/cat.txt"
    run file_cat -i "$DATA/cat.txt" -o "$DATA/cat.txt"
    assert_output --partial "fichiers identiques"
    run cat "$DATA/cat.txt"
    assert_output "$(printf 'l1\nl2\nl3')"
}

# ---------------------------------------------------------- file_clear
@test "file_clear vide le fichier" {
    run file_clear -o "$DATA/in.txt"
    assert_success
    assert_file_empty "$DATA/in.txt"
}

@test "file_clear sans -o -> erreur (SEV 6 car _cr_test ne connaît pas le type CLEAR)" {
    run file_clear
    assert_equal "$status" 6
    assert_output --partial "Aucun fichier valide"
}

@test "A VERIFIER file_clear sans INIT_FILE ne doit pas exécuter le fichier" {
    skip "INIT_FILE n'est défini nulle part dans ce dépôt : s'il est vide, file_clear fait eval \" \$outfile\" et EXÉCUTE le fichier"
    unset INIT_FILE
    run file_clear -o "$DATA/in.txt"
    assert_file_empty "$DATA/in.txt"
}

# --------------------------------------------------------- file_delete
@test "file_delete supprime le fichier" {
    run file_delete -o "$DATA/in.txt"
    assert_success
    assert_file_not_exists "$DATA/in.txt"
}

@test "file_delete : fichier absent -> NOTICE et succès" {
    run file_delete -o "$DATA/absent.txt"
    assert_success
    assert_output --partial "Fichier inexistant"
}

@test "BUG file_delete -p -r supprime un répertoire" {
    skip "BUG : file_exist \"\$outfile\" teste -f par défaut -> un répertoire est vu comme 'Fichier inexistant' et n'est jamais supprimé"
    mkdir -p "$DATA/rep/sous"
    run file_delete -o "$DATA/rep" -p "-r"
    assert_success
    assert_dir_not_exists "$DATA/rep"
}
