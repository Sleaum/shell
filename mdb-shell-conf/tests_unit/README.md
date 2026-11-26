# Tests unitaires Bats — mdb-shell-conf

Tests unitaires des fonctions de `lib/medoc_fct.sh`, avec [bats-core](https://github.com/bats-core/bats-core) embarqué dans le dépôt : aucune installation ni accès réseau nécessaire.

Ce répertoire est volontairement **hors de `tests/`**, que `launch_rpmbuild.sh` et le `.spec` embarquent dans le RPM `mdb-shell-conf-tests`.

## Lancer les tests

```bash
tests_unit/bats/bin/bats tests_unit/                    # tous les tests
tests_unit/bats/bin/bats tests_unit/medoc_fct_fichiers.bats
tests_unit/bats/bin/bats -f file_copy tests_unit/       # filtre sur le nom
```

En CI, le job `unit-tests` (stage `test`) tourne avant `rpmbuild` et publie un rapport JUnit visible dans la merge request.

## Contenu

| Fichier | Fonctions testées |
|---|---|
| `medoc_fct_utilitaires.bats` | `_trim`, `_date_utc`, `_max_min`, `msg`, `_fct_is_exec`, `_0_fct_init`, `_cr_max`, `_cr_test`, `gestion_exit_ops`, `_analyze_args` |
| `medoc_fct_fichiers.bats` | `file_exist`, `file_assign`, `_fic_ctrl`, `_fic_in_out`, `file_copy`, `file_rename`, `file_cat`, `file_clear`, `file_delete` |
| `medoc_fct_config.bats` | `load_dom_config` (LOCAL et API), `set_conn_strings`, `_curl_api_connexion`, validité de `lib/dom_config.json` |
| `common.bash` | Chargement des librairies + neutralisation de l'environnement prod (chemins, `LD_PRELOAD`, locale) |
| `fixtures/` | JSON de test (config domaine, réponses API) |

`logger` et `curl` sont remplacés par des bouchons : rien n'est écrit dans syslog, aucun appel réseau. Les tests de `medoc_fct_config.bats` nécessitent `jq` et sont ignorés s'il est absent.

## Tests marqués `BUG`

Ils décrivent le comportement attendu et sont désactivés par `skip` pour que le pipeline reste vert. Une fois le bug corrigé dans `lib/`, supprimer la ligne `skip` : le test doit passer.

## Versions embarquées

bats-core 1.11.1, bats-support 0.3.0, bats-assert 2.1.0, bats-file 0.4.0 (licences dans chaque dossier).
