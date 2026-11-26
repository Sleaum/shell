# Tests unitaires Bats — mdb-shell-conf

Guide pour lancer, lire et écrire les tests unitaires des fonctions de `lib/medoc_fct.sh` avec [Bats](https://github.com/bats-core/bats-core) (Bash Automated Testing System).

---

## Sommaire

1. [En bref](#1-en-bref)
2. [Lancer les tests](#2-lancer-les-tests)
3. [Organisation du répertoire](#3-organisation-du-répertoire)
4. [Anatomie d'un test](#4-anatomie-dun-test)
5. [Assertions disponibles](#5-assertions-disponibles)
6. [Pièges spécifiques à medoc_fct.sh](#6-pièges-spécifiques-à-medoc_fctsh)
7. [Bouchonner une commande (logger, curl…)](#7-bouchonner-une-commande-logger-curl)
8. [Tests marqués BUG](#8-tests-marqués-bug)
9. [Déboguer un test](#9-déboguer-un-test)
10. [Intégration GitLab CI](#10-intégration-gitlab-ci)
11. [Ajouter un nouveau fichier de tests](#11-ajouter-un-nouveau-fichier-de-tests)
12. [Mettre à jour Bats](#12-mettre-à-jour-bats)

---

## 1. En bref

- Bats est **embarqué dans le dépôt** (`tests_unit/bats/`) : rien à installer, aucun accès Internet nécessaire, même version sur la VM et en CI.
- Un fichier `.bats` contient des blocs `@test "description" { ... }`. Chaque bloc est un test indépendant, exécuté dans son **propre processus**.
- Un test **réussit si aucune commande de son bloc n'échoue**. Bats fonctionne en `set -e` : la première commande en erreur fait échouer le test.
- Le répertoire est volontairement **hors de `tests/`** : `launch_rpmbuild.sh` et le `.spec` copient `tests/*` dans le RPM `mdb-shell-conf-tests`, et les tests unitaires n'ont rien à faire sur un serveur.

---

## 2. Lancer les tests

Depuis la racine de `mdb-shell-conf` :

```bash
# Tous les tests
tests_unit/bats/bin/bats tests_unit/

# Un seul fichier
tests_unit/bats/bin/bats tests_unit/medoc_fct_fichiers.bats

# Seulement les tests dont le nom contient "file_copy" (expression régulière)
tests_unit/bats/bin/bats -f file_copy tests_unit/

# Afficher la sortie des tests en échec de façon lisible
tests_unit/bats/bin/bats --print-output-on-failure tests_unit/

# Format TAP (une ligne par test, pratique pour grep)
tests_unit/bats/bin/bats --formatter tap tests_unit/
```

### Lire le résultat

```
 ✓ file_copy copie le fichier
 ✗ file_clear vide le fichier
   (in test file tests_unit/medoc_fct_fichiers.bats, line 182)
     `assert_file_empty "$DATA/in.txt"' failed
 - BUG file_delete -p -r supprime un répertoire (skipped: BUG : ...)

83 tests, 1 failure, 8 skipped
```

| Symbole | Signification |
|---|---|
| `✓` / `ok` | test réussi |
| `✗` / `not ok` | test en échec : fichier, ligne et assertion fautive sont indiqués |
| `-` / `# skip` | test volontairement ignoré (voir [§8](#8-tests-marqués-bug)) |

Le code retour de `bats` vaut `0` si tout est vert, `1` sinon : c'est ce qui fait échouer le job CI.

### Prérequis

- `bash` ≥ 4.3 (`declare -n` est utilisé par `medoc_fct.sh`)
- `jq` pour `medoc_fct_config.bats` ; sans `jq`, ces tests sont ignorés, pas en échec

---

## 3. Organisation du répertoire

```
tests_unit/
├── README.md                    ce guide
├── common.bash                  initialisation commune à tous les tests
├── medoc_fct_utilitaires.bats   msg, _cr_test, _cr_max, _max_min, _fct_is_exec…
├── medoc_fct_fichiers.bats      file_exist, file_copy, file_cat, file_delete…
├── medoc_fct_config.bats        load_dom_config, set_conn_strings, dom_config.json
├── fixtures/                    données de test (JSON domaine, réponses API)
├── bats/                        bats-core 1.11.1 (moteur)
└── test_helper/
    ├── bats-support/            dépendance de bats-assert
    ├── bats-assert/             assert_success, assert_output…
    └── bats-file/               assert_file_exists, assert_file_empty…
```

### Ce que fait `common.bash`

Chaque fichier `.bats` commence par :

```bash
setup() {
    load common
    _common_setup
}
```

`_common_setup` est exécutée **avant chaque test** et :

1. charge les librairies d'assertions ;
2. place un bouchon `logger` en tête du `PATH` ;
3. source `medoc_var.sh`, `medoc_log.sh` puis `medoc_fct.sh`, dans l'ordre des JOBs ;
4. neutralise l'environnement de production :
   - suppression de `LD_PRELOAD` ;
   - `LC_COLLATE=C` ;
   - `MDB_LOG` et `MDB_TEMP` redirigés vers un dossier temporaire ;
5. initialise les variables normalement posées par `deb_job` : `SEV`, `CR_MAX`, `CR_MAX_*`, `OLDIFS`, `FCT_EXEC`…

Variables mises à disposition des tests :

| Variable | Contenu |
|---|---|
| `$LIB_DIR` | chemin absolu de `lib/` |
| `$FIXTURES` | chemin absolu de `tests_unit/fixtures/` |
| `$DATA` | dossier de travail vide, propre à chaque test |
| `$STUB_DIR` | dossier des bouchons, en tête du `PATH` |
| `$BATS_TEST_TMPDIR` | dossier temporaire Bats du test (supprimé ensuite) |

---

## 4. Anatomie d'un test

```bash
@test "file_copy copie le fichier" {
    # Préparation (Arrange)
    printf 'l1\nl2\n' > "$DATA/in.txt"

    # Exécution (Act) : run capture le code retour et la sortie
    run file_copy -i "$DATA/in.txt" -o "$DATA/out.txt"

    # Vérifications (Assert)
    assert_success
    assert_files_equal "$DATA/in.txt" "$DATA/out.txt"
    assert_output --partial "Nombre de lignes dans le fichier SORTIE"
}
```

### `run` : la commande clé

`run commande args…` exécute la commande **sans faire échouer le test**, puis remplit trois variables :

| Variable | Contenu |
|---|---|
| `$status` | code retour |
| `$output` | stdout et stderr mélangés |
| `${lines[@]}` | `$output` découpé ligne par ligne |

```bash
run _cr_test SHELL 5 1
assert_equal "$status" 3
assert_equal "${lines[0]}" "..."     # première ligne
```

### Les fonctions spéciales

| Fonction | Quand elle s'exécute |
|---|---|
| `setup()` | avant **chaque** test du fichier |
| `teardown()` | après **chaque** test, même en échec |
| `setup_file()` | une seule fois, avant le premier test du fichier |
| `teardown_file()` | une seule fois, après le dernier test du fichier |

Ici, le nettoyage est inutile : tout est écrit dans `$BATS_TEST_TMPDIR`, que Bats supprime lui-même.

### Conventions de nommage

- **Nom du test** : `"<fonction> : <situation> -> <résultat attendu>"`, par exemple `"file_copy : entrée = sortie -> SEV 3, rien n'est exécuté"`.
- **Préfixe `BUG`** pour un test qui décrit un bug connu, `A VERIFIER` pour un comportement douteux.
- **Un fichier `.bats` par famille de fonctions**, nommé `medoc_<module>_<famille>.bats`.

---

## 5. Assertions disponibles

### bats-assert (sur `$status` / `$output`, après un `run`)

| Assertion | Vérifie que… |
|---|---|
| `assert_success` | `$status` = 0 |
| `assert_failure` | `$status` ≠ 0 |
| `assert_equal "$status" 3` | deux valeurs sont égales (code retour précis) |
| `assert_output "texte"` | la sortie est **exactement** `texte` |
| `assert_output --partial "txt"` | la sortie **contient** `txt` |
| `assert_output --regexp '^[0-9]{4}-'` | la sortie correspond à l'expression régulière |
| `refute_output --partial "txt"` | la sortie ne contient **pas** `txt` |
| `assert_line --index 0 "txt"` | la ligne n° 0 vaut `txt` |
| `assert_line --partial "txt"` | au moins une ligne contient `txt` |
| `assert [ -n "$VAR" ]` | une expression quelconque est vraie |
| `refute [ -z "$VAR" ]` | une expression quelconque est fausse |

### bats-file (sur le système de fichiers)

| Assertion | Vérifie que… |
|---|---|
| `assert_file_exists f` / `assert_file_not_exists f` | le fichier existe / n'existe pas |
| `assert_dir_exists d` / `assert_dir_not_exists d` | le répertoire existe / n'existe pas |
| `assert_file_empty f` / `assert_file_not_empty f` | le fichier est vide / non vide |
| `assert_files_equal f1 f2` | les deux fichiers ont le même contenu |
| `assert_file_contains f 'regex'` | le fichier contient la regex |
| `assert_file_executable f` | le fichier est exécutable |

En cas d'échec, les assertions affichent la valeur attendue et la valeur obtenue :

```
-- values do not equal --
expected : 3
actual   : 6
--
```

Documentation complète : [bats-assert](https://github.com/bats-core/bats-assert), [bats-file](https://github.com/bats-core/bats-file).

---

## 6. Pièges spécifiques à `medoc_fct.sh`

### `run` s'exécute dans un sous-shell : les variables globales sont perdues

Les fonctions MedocDB communiquent beaucoup par variables globales : `SEV`, `CR_MAX`, `NIV_MSG`, les `export` de `file_assign` ou `load_dom_config`… Après un `run`, ces variables **ne sont pas modifiées** dans le test.

```bash
# ❌ CR_MAX vaut toujours 0 : _cr_max a tourné dans un sous-shell
run _cr_max 3
assert_equal "$CR_MAX" 3

# ✅ Appel direct : la fonction modifie le shell du test
_cr_max 3
assert_equal "$CR_MAX" 3
```

| Pour tester… | Utiliser |
|---|---|
| le code retour ou la sortie | `run fonction …` |
| une variable globale ou un `export` | un appel direct `fonction …` |

### Appel direct d'une fonction qui renvoie un code non nul

Bats est en `set -e` : un appel direct qui renvoie autre chose que 0 fait échouer le test immédiatement. Ajouter `|| true` :

```bash
_cr_test COBOL 8 "$CR_MAX_COB" || true   # renvoie 4, on veut juste lire SEV
assert_equal "$SEV" 4
```

### Fonctions qui font `exit`

`gestion_exit_ops` et `load_dom_config` (en mode API, sur erreur HTTP) font un `exit`. Les appeler **uniquement avec `run`**, sinon c'est le test entier qui s'arrête :

```bash
run gestion_exit_ops 4
assert_equal "$status" 1
```

### Fonctions débrayables (`FCT_EXEC`)

`FCT_EXEC` est remis à vide avant chaque test : toutes les fonctions sont exécutables. Pour tester le comportement d'une fonction débrayée :

```bash
FCT_EXEC[file_copy]=false
run file_copy -i "$DATA/in.txt" -o "$DATA/out.txt"
assert_file_not_exists "$DATA/out.txt"
```

### Niveau de log

`MDB_LOG_LEVEL=6` (INFO) par défaut dans les tests : les messages INFO et plus graves apparaissent dans `$output`, les messages DEBUG non. Pour vérifier un message DEBUG, poser `MDB_LOG_LEVEL=7` dans le test.

### Chemins de production

Ne jamais écrire dans `/medocdb`, `/var/log/medocdb`… Toujours utiliser `$DATA` ou `$BATS_TEST_TMPDIR`. Si une fonction utilise un chemin global (`MDB_BATCHS`, `MDB_CONFIG`…), le surcharger dans le test :

```bash
MDB_BATCHS="$DATA/batchs"
mkdir -p "$MDB_BATCHS"
```

---

## 7. Bouchonner une commande (logger, curl…)

Principe : créer un faux exécutable du même nom dans `$STUB_DIR`, qui est en tête du `PATH`. Il est utilisé à la place du vrai, y compris dans les sous-processus (`xargs bash -c …`).

### Exemple : `logger` (déjà en place dans `common.bash`)

Le bouchon enregistre ses arguments dans `$BATS_TEST_TMPDIR/logger.calls` :

```bash
@test "msg envoie à logger quand le niveau est < NIV_LOGGER" {
    NIV_LOGGER=6
    LOGGER="logger -t $JOBNAME --sd-param composant="
    msg "alerte" 3
    run cat "$BATS_TEST_TMPDIR/logger.calls"
    assert_output --partial "alerte"
}
```

### Exemple : `curl` piloté par variables (voir `medoc_fct_config.bats`)

Le bouchon renvoie le contenu de `fixtures/` selon l'URL appelée et un code HTTP réglable :

```bash
@test "set_conn_strings : API connexion en erreur HTTP -> 1" {
    MDB_API_CNX_ENABLED=true
    export CURL_HTTP_CODE=503     # lu par le bouchon curl
    run set_conn_strings X77 true MAJ
    assert_failure
}
```

### Bouchonner une fonction plutôt qu'une commande

Pour un seul test, on peut simplement redéfinir la fonction :

```bash
@test "exemple : _curl_api_connexion en échec" {
    _curl_api_connexion() { return 1; }
    MDB_API_CNX_ENABLED=true
    run set_conn_strings X77 false
    assert_failure
}
```

La redéfinition ne vaut que pour ce test : chaque test repart d'un `setup` propre.

---

## 8. Tests marqués BUG

Certains tests décrivent le **comportement attendu** d'une fonction aujourd'hui boguée. Ils sont désactivés par `skip`, qui en donne la raison :

```bash
@test "BUG _max_min compare des nombres et non des chaînes (9 < 10)" {
    skip "BUG : [[ \$var > \$ret_val ]] compare en ordre alphabétique -> max(9,10)=9. Utiliser (( var > ret_val ))"
    run _max_min max 9 10
    assert_equal "$status" 10
}
```

**Cycle de vie :**

1. Le bug est constaté : on écrit le test attendu et on ajoute `skip "BUG : explication"`. Le pipeline reste vert et le bug est visible dans chaque rapport.
2. On corrige `lib/medoc_fct.sh`.
3. On **supprime la ligne `skip`** et on retire le préfixe `BUG` du nom.
4. Le test passe et protège désormais contre une régression.

Lister les bugs en attente :

```bash
grep -n 'skip "BUG' tests_unit/*.bats
```

---

## 9. Déboguer un test

| Besoin | Commande ou astuce |
|---|---|
| Voir la sortie d'un test en échec | `bats --print-output-on-failure …` |
| Voir la sortie même des tests réussis | `bats --show-output-of-passing-tests …` |
| Voir chaque commande exécutée | `bats --trace …` |
| Afficher une valeur pendant un test | `echo "# SEV=$SEV" >&3` (le descripteur 3 s'affiche toujours) |
| Garder les fichiers temporaires | `bats --no-tempdir-cleanup …` (le chemin est affiché à la fin) |
| Lancer un seul test | `bats -f "nom exact du test" fichier.bats` |

Exemple :

```bash
@test "investigation" {
    run file_copy -i "$DATA/in.txt" -o "$DATA/out.txt"
    echo "# status=$status" >&3
    echo "# output=$output" >&3
    assert_success
}
```

---

## 10. Intégration GitLab CI

Le job `unit-tests` (stage `test`) tourne **avant** `rpmbuild`. Si un test échoue, le job est rouge et le RPM n'est ni construit ni publié.

```yaml
unit-tests:
  stage: test
  image: docker-nexus.kubemedoc.nubo.dgfip/medocdb/mdb-rl8-rpmbuild:latest
  script:
    - tests_unit/bats/bin/bats tests_unit/
```

Les résultats se lisent dans le **log du job** : une ligne `ok` / `not ok` par test, `# skip` pour les tests ignorés.

### Rapport JUnit (désactivé)

La forge DGFiP refuse l'envoi d'artefacts depuis les jobs (`405 Method Not Allowed` à l'upload), ce qui fait échouer le job même quand tous les tests passent. Le rapport JUnit est donc désactivé. Si les artefacts sont un jour autorisés, il suffit de remplacer le `script` et d'ajouter :

```yaml
  script:
    - tests_unit/bats/bin/bats --report-formatter junit --output . tests_unit/
  artifacts:
    when: always
    reports:
      junit: report.xml
```

Le détail des tests apparaîtra alors dans l'onglet **Tests** du pipeline et dans la merge request.

### jq

Si `jq` est absent de l'image RL8, les 17 tests de `medoc_fct_config.bats` apparaissent comme `# skip jq absent de cette machine`. Pour les activer, ajouter `jq` à l'image, ou un `before_script: - dnf install -y jq` si le dépôt de paquets est accessible.

---

## 11. Ajouter un nouveau fichier de tests

1. Créer `tests_unit/medoc_<module>_<famille>.bats` :

   ```bash
   #!/usr/bin/env bats
   # Tests de <fonctions> de lib/<fichier>.sh

   setup() {
       load common
       _common_setup
       # préparation propre à ce fichier
   }

   @test "<fonction> : <situation> -> <résultat attendu>" {
       run <fonction> <args>
       assert_success
   }
   ```

2. Si des données sont nécessaires, les placer dans `tests_unit/fixtures/`.
3. Lancer `tests_unit/bats/bin/bats tests_unit/` en local avant de pousser.

Le job CI prend automatiquement en compte tout fichier `*.bats` de `tests_unit/`.

### Ce qui se teste bien… et moins bien

| Se teste bien en unitaire | Relève plutôt des tests d'intégration (`tests/`) |
|---|---|
| contrôles de paramètres, codes retour, `SEV` / `CR_MAX` | exécution réelle d'un programme COBOL (`exec_prog`) |
| opérations sur fichiers dans un dossier temporaire | GCSORT réel (`exec_sort`) |
| lecture de config JSON, appels API bouchonnés | connexion PostgreSQL réelle |
| format et filtrage des messages (`msg`) | enchaînement complet `deb_job` → phases → `fin_job` |

---

## 12. Mettre à jour Bats

Versions embarquées : **bats-core 1.11.1**, bats-support 0.3.0, bats-assert 2.1.0, bats-file 0.4.0. Les licences (MIT / CC0) sont dans chaque dossier.

Depuis une machine ayant accès à GitHub :

```bash
cd tests_unit
rm -rf bats test_helper/bats-*
git clone --depth 1 -b vX.Y.Z https://github.com/bats-core/bats-core          bats
git clone --depth 1 -b vX.Y.Z https://github.com/bats-core/bats-support test_helper/bats-support
git clone --depth 1 -b vX.Y.Z https://github.com/bats-core/bats-assert  test_helper/bats-assert
git clone --depth 1 -b vX.Y.Z https://github.com/bats-core/bats-file    test_helper/bats-file
rm -rf bats/.git test_helper/*/.git
cd .. && tests_unit/bats/bin/bats tests_unit/    # vérifier que tout passe
```

Puis commiter le tout dans une merge request dédiée.
