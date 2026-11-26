#!/bin/bash

# gestion version RPM
rpm_name="mdb-shell-conf"
if [[ $CI_COMMIT_BRANCH == "" ]]
then
    rpm_vers=$CI_COMMIT_TAG
    rpm_release=1
    nexus_repo=${NEXUS_URL}/rpm-bsi3/composants/mdb-shell-conf/release/
else
    rpm_vers=$(echo $CI_COMMIT_BRANCH | tr -d "-")
    rpm_release=snapshot
    nexus_repo=${NEXUS_URL}/rpm-bsi3/composants/mdb-shell-conf/snapshot/
fi

# préparation du RPM
src_path="rpmbuild/SOURCES/"
tgz_name="${rpm_name}-${rpm_vers}"
mkdir ${rpm_name}-${rpm_vers}/
cp -r lib ${rpm_name}-${rpm_vers}/
cp -r tests ${rpm_name}-${rpm_vers}/
tar -czf ${rpm_name}-${rpm_vers}.tar.gz ${rpm_name}-${rpm_vers}
mv ${rpm_name}-${rpm_vers}.tar.gz ${src_path}
rpmbuild --define "version $rpm_vers" --define "release $rpm_release" --define "_topdir $(pwd)/rpmbuild" -ba rpmbuild/SPECS/${rpm_name}.spec
code_rpmbuild="${?}"
echo "# CODE RETOUR RPMBUILD : ${code_rpmbuild}"

# publication sur Nexus
find rpmbuild/RPMS/x86_64/ -type f -exec curl -u ${NEXUS_LOGIN}:${NEXUS_PASSWD} -T {} ${nexus_repo} \;
code_nexus="${?}"
echo "# CODE RETOUR NEXUS : ${code_nexus}"

# création du composant sur BTW lors d'un merge dans main avant de poser le tag
if [[ $CI_COMMIT_TAG != "" ]]
then
    Major=$(echo $rpm_vers | awk -F '[.]' '{print $1}')
    Minor=$(echo $rpm_vers | awk -F '[.]' '{print $2}')
    Fix=$(echo $rpm_vers | awk -F '[.]' '{print $3}')
    curl -s -X PUT 'http://btw.kubemedoc.nubo.dgfip/mac2.html?type_page=ajax&action=ajouter_version_composant_mac&format=json&nom_composant=MDB-SHELL-CONF&version_majeur='$Major'&version_mineur='$Minor'&version_correctif='$Fix'&version_release='$rpm_release'&from=BSI3'


    FORMATTED_VERSION=$(echo $rpm_vers | awk -F. '{printf "%d.%d.%d", $1, $2, $3}')
    [[ ${code_rpmbuild} -ne 0 ]] && curl -s -X PUT 'http://btw.kubemedoc.nubo.dgfip/gitflow.html?type_page=ajax&action=api_ajouter_etat&type_objet=composant&nom_objet=MDB-SHELL-CONF&version='$FORMATTED_VERSION-$rpm_release'&etape_gitflow=compilation&check_gitflow=rpm&etat_check=ko' && exit ${code_rpmbuild}
    curl -s -X PUT 'http://btw.kubemedoc.nubo.dgfip/gitflow.html?type_page=ajax&action=api_ajouter_etat&type_objet=composant&nom_objet=MDB-SHELL-CONF&version='$FORMATTED_VERSION-$rpm_release'&etape_gitflow=compilation&check_gitflow=rpm&etat_check=ok'


    [[ ${code_nexus} -ne 0 ]] && curl -s -X PUT 'http://btw.kubemedoc.nubo.dgfip/gitflow.html?type_page=ajax&action=api_ajouter_etat&type_objet=composant&nom_objet=MDB-SHELL-CONF&version='$FORMATTED_VERSION-$rpm_release'&etape_gitflow=compilation&check_gitflow=nexus&etat_check=ko' && exit ${code_nexus}
    curl -s -X PUT 'http://btw.kubemedoc.nubo.dgfip/gitflow.html?type_page=ajax&action=api_ajouter_etat&type_objet=composant&nom_objet=MDB-SHELL-CONF&version='$FORMATTED_VERSION-$rpm_release'&etape_gitflow=compilation&check_gitflow=nexus&etat_check=ok'
fi

exit 0
