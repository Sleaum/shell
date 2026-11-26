# mdb-jobs-conf

## Infos

Image de build (cf sanctuaire) :  
```
docker-nexus.kubemedoc.nubo.dgfip/medocdb/mdb-rl8-rpmbuild:latest
```

## Processus de développement

1. créer une issue qui décrit les modifications à apporter au projet
2. créer une merge request (MR) à partir de l'issue vers la branche develop
3. se positionner sur la branche créée à l'étape 2 et faire ses développements (avec mise à jour du CHANGELOG)
4. pousser les développements sur la branche
5. tester le paquet généré à partir de la branche de travail disponible sur **[Nexus](http://nexus.kubemedoc.nubo.dgfip/#browse/browse:rpm-bsi3:composants%2Fshell%2Fmdb-shell-conf-SNAPSHOT)**
6. répéter les étapes 3 à 5 autant de fois que nécessaire
7. merge la branche de travail dans la branche develop depuis votre MR


## Processus de livraison

1. créer une MR de develop vers main
2. mettre à jour le `CHANGELOG.md` et le `launch_rpmbuild.sh` (ligne 7: `rpm_vers` au format X.Y.Z et ligne 9: `rpm_release` si besoin sinon laisser à `1`)
3. merge develop dans main depuis la MR (ce qui va déclencher le pipeline et mettre le composant sous **[Nexus](http://nexus.kubemedoc.nubo.dgfip/#browse/browse:rpm-bsi3:composants%2Fshell%2Fmdb-shell-conf)**)
4. tag la branche main 