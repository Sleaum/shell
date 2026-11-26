Name:           mdb-shell-conf
Version:        %{version}
Release:        %{release}.dgfip%{dist}
Summary:        Medocdb mdb-shell-conf

License:        DGFiP
URL:            https://forge.dgfip.finances.rie.gouv.fr/dgfip/medocdb/code
Source0:        %{name}-%{version}.tar.gz

Requires:       mdb-conf
Requires:       mdb-shell-emaj
Requires:       time
Requires:       findutils
Requires:       which
Requires:	      jq
Requires:	      curl
Requires:	      gdb

%description
Librairies pour les scripts des chaines.

%prep
%setup -q
%install

mkdir -p %{buildroot}/etc/profile.d
cp lib/medoc_var.sh %{buildroot}/etc/profile.d
mkdir -p %{buildroot}/medocdb/application/scripts/lib
cp -R lib/*.sh %{buildroot}/medocdb/application/scripts/lib
mkdir -p %{buildroot}/medocdb/application/tests
cp -R tests/* %{buildroot}/medocdb/application/tests
mkdir -p %{buildroot}/medocdb/application/config
cp lib/dom_config.json %{buildroot}/medocdb/application/config

%post
chown medocdb.medocdb /medocdb/application/scripts/lib
# a supprimer lors de la finalisation des rpms de conf
if ! grep 'PATH=${PATH}:/opt/gcsort/' /home/medocdb/.bashrc
then
  echo "PATH=\${PATH}:/opt/gcsort/" >> /home/medocdb/.bashrc
fi

%files
%defattr(775,medocdb,medocdb,775)
/medocdb/application/scripts/lib/*
/etc/profile.d/medoc_var.sh
/medocdb/application/config/dom_config.json

%package tests
Summary: Medocdb mdb-shell-conf-tests
Requires: mdb-shell-conf-%{version}

%description tests
Librairies pour les tests des scripts des chaines.

%files tests
/medocdb/application/tests/*
