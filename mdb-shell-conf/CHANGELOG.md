# Changelog

# [0.1.5] - 25/11/2026

- `Correctif` libelle fonc phase/endphase
- `Changement` nettoyage du code medoc_fct.sh
- `Changement` uniformisation des var d'environnement
- `Ajout` intégration mdb-shell-emaj

# [0.1.4] - 23/11/2026

- `Correctif` preload + library_path pour belem

# [0.1.3] - 19/11/2026

- `Correctif` uncomment load_dom_config
- `Correctif` ordre répertoire LD_LIBRARY_PATH
- `Correctif` test MDB_ETAT insensible à la casse

# [0.1.2] - 09/11/2026

- `Correctif` modification de la visibilité des variables
- `Correctif` comment _bdd_dcnx
- `Changement` fusion des fonctions pre et post job

# [0.1.1] - 04/11/2026

- `Correctif` ajout du TDS X77 à la liste des domaines pour l'API de connexion

# [0.1.0] - 28/10/2026

- `Changement` suppression fonction ops_fct
- `Changement` gestion de l'api de connexion

# [0.0.27] - 12/10/2026

- `Correctif` correction api_connexion

# [0.0.26] - 12/10/2026

- `Changement` CI-CD
- `Ajout` fonction api connexion
- `Ajout` fonction appel prepost fichier

# [0.0.25] - 27/08/2026

- `Changement` Modification variables api de connexion [456806]
- `Changement` Suppression /dev/tty
- `Changement` CI-CD

# [0.0.24] - 12/08/2026

- `Correctif` correction dom_config.json [457225]

# [0.0.23] - 24/06/2026

- `Ajout` fonction exec_sprog [451880]

# [0.0.22] - 02/06/2026

- `Changement` LIBRARY_PATH pour postgresql18

# [0.0.21] - 13/05/2026

- `Correctif` Debug api_connexion api_exec()
- `Correctif` Debug MDIEJ20 : sous programme utilise carte paramètre

# [0.0.20] - 07/05/2026

- `Ajout` MDIEJ20 pour cobcall

# [0.0.19] - 27/04/2026

- `Ajout` fonction gestion_exit_ops

# [0.0.18] - 01/04/2026

- `Correctif` debug api_connexion MDB_INSTANCE="NAT"
- `Correctif` api_connexion (deb_job)

# [0.0.17] - 17/02/2026

- `Changement` suppression maj_res_global in medoc_fct
- `Ajout` ops_fct

# [0.0.16] - 08/01/2026

- `Correctif` exec_prog tir_a_blanc

# [0.0.15] - 07/11/2025

- `Ajout` json config file for load_dom_config function
- `Ajout` V_DEBUG for debug mode

# [0.0.14] - 09/10/2025

- `Ajout` maj_res_globale function to emulate J_signal
- `Ajout` load_dom_config function to retrieve Domaine config

# [0.0.13] - 20/05/2025

- `Ajout` GCSORT_PATHTMP env variable

# [0.0.12] - 07/04/2025

- `Ajout` MDB_API_CNX_ENABLED Variable to Enable/Disable API

# [0.0.11] - 13/03/2025

- `Changement` exec_sort

# [0.0.10] - 05/02/2025

- `Changement` rpm mdb-conf

# [0.0.9] - 12/11/2024

- `Ajout` info application_name à la chaîne de connexion

# [0.0.8] - 05/06/2024

- `Changement` rpm de conf

# [0.0.7] - 29/04/2024

- `Correctif` medoc_var

# [0.0.6] - 03/04/2024

- `Correctif` medoc_var

# [0.0.5] - 03/04/2024

- `Correctif` medoc_var

# [0.0.4] - 03/04/2024

- `Correctif` medoc_var

# [0.0.3] - 03/04/2024

- `Ajout` requires findutils (release 2)
- `Changement` filtrage des output des log (log level)

# [0.0.2] - 30/01/2024

- `Ajout` requires sur time

# [0.0.1] - 20/12/2023

- `Changement` droits d'installation
- `Changement` renommage paquet rpm
- `Changement` renommage scripts
- `Ajout` requires mdb-conf
- `Correctif` medoc_fct.sh ${niv_msg} < ${NIV_LOGGER}

