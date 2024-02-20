# sed

sed '' fichier      affiche le contenu du fichier dans le terminal
sed -n 'p'          idem. -n n'affiche rien de base & p print le fichier dans un second temps
sed -n '1,3p'       print de la ligne 1 À le ligne 3 incluses. `a,b` signifie les lignes de a à b 
sed -n '1p;3p'      print ligne 1 ET(;) ligne 3. `;` signifie (puis) le résultat est un ou inclusif séquentiel (comment ça veut rien dire??). chaque partie est donc indépendante c'est pourquoi on voit la redondance du p
… -e '1,3p' -e '11,13' == '1,3p;11,13p' ou inclusif
… '1~2p'              print lignes (1) (1+2) (1+2+2) … 

sed '/motif1/,/motif2/d' fichier affiche tout moins (d) les lignes incluses du (/)motif1(/) à(,) (/)motif2(/). le fichier n'est pas impacté seul un affichage terminal se produit
sed 's/ancien_motif/nouveau_motif/g' fichier substitution d'un motif par un autre
ou echo 'ancien_motif' | sed 's/ancien_motif/nouveau_motif/g' exemple avec un flux

#regex
# awk
# cron
# wc
# gcsort
# rp
# find
#xargs
#curl
