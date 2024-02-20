# sed -i -n -r -e

sed '' fichier      affiche le contenu du fichier dans le terminal
sed -n 'p'          idem. -n n'affiche rien de base & p print le fichier dans un second temps
sed -n '1,3p'       print de la ligne 1 À le ligne 3 incluses. `a,b` signifie les lignes de a à b 
sed -n '1p;3p'      print ligne 1 ET(;) ligne 3. `;` signifie (puis) le résultat est un ou inclusif séquentiel (comment ça veut rien dire??). chaque partie est donc indépendante c'est pourquoi on voit la redondance du p
… -e '1,3p' -e '11,13' == '1,3p;11,13p' ou inclusif. on faite pas == car -e suivant reprend le résultat du précédent alors que ; repart du fichier d'origine mais applique la modif sur la même sortie
… '1~2p'              print lignes (1) (1+2) (1+2+2) … 

sed '/motif1/,/motif2/d' fichier affiche tout moins (d) les lignes incluses du (/)motif1(/) à(,) (/)motif2(/). le fichier n'est pas impacté seul un affichage terminal se produit
sed 's/ancien_motif/nouveau_motif/g' fichier substitution d'un motif par un autre. g pour global c'est à dire toute les occurences dans la même ligne
echo 'J’aime Debian' | sed 's/Debian/Ubuntu/g' exemple avec un flux.
echo 'J’aime Debian' | sed 's/debian/Ubuntu/gi' (i) pour Insensible à la casse
sed 'n s/I/you/N' fichier on remplace à la ligne n le motif à partir de sa N apparition
echo -e 'IIIIIII\nIIIIIII' | sed '2 s/I/i/3' modifie la ligne 2 uniquement le 3ème I
echo -e 'IIIIIII\nIIIIIII' | sed '1,2 s/I/i/3g' modifie la ligne 1 à 2 et à partir du 3ème I jusqu'à la fin de ligne
echo -e 'IIIIIII\nIIIIIII' | sed '1s/I/i/3;2s/I/i/3g' si pas 2 après le ; ça reprendrait ligne 1

sed -r regex étendues!
sed -r 's/^[0-9]{1,}\t//g' toto.txt == sel -r -e 's/^[0-9]{1,}//' -e 's/^\t//' file

sed -i   == sed ''file > file Remplace directement dans le fichier

sed '/^$/!s/$/# commentaire de fin de ligne non vide/g' toto.txt

#regex
# awk
# cron
# wc
# gcsort
# rp
# find
#xargs
#curl
