#!/usr/bin/env bash
arbreA="tests/arbreA"
arbreB="tests/arbreB"
adresseLog="log_file"
# Projet final de LO14
# Pour P20
#Affiche la hieracrhie des sous-repoertoires
#ls -R tests/arbreA | grep ":$" | sed -e 's/:$//' -e 's/[^-][^\/]*\//--/g' -e 's/^/   /' -e 's/-/|/'
#Affiche la hieracrhie des sous-repoertoires
#ls -R tests/arbreB| grep ":$" | sed -e 's/:$//' -e 's/[^-][^\/]*\//--/g' -e 's/^/   /' -e 's/-/|/'
#find tests/arbreA
#fonction de parcours récursive
walk(){
	local indent="${2:-0}"
	#echo "$1"/*
	#pour chaque élément du répertoire
	for entry in "$1"/*; do
	#si c'est un fichier on affiche son chemin
          if [[ -f "$entry" ]]; then
            printf "%*sF - %s\n" $indent '' "$entry"
						log_write $entry
          #s'il sagit d'un dossier, on affiche et on descend dedans
          elif [[ -d "$entry" ]]; then
            printf "%*sD - %s\n" $indent '' "$entry"
            walk "$entry" $((indent+4))
						#log_write $entry
          fi
        done
				#deqdq
}
log_write()
{	
		#Si l'élément et un fichier, on ajoute f devant pour le représenter
	if [[ -f "$1" ]]; then
		printf "f %s \n" $1 >> log_temp
				#Si l'élément et un dossier, on ajoute d devant pour le représenter
	elif [[ -d "$1" ]]; then
		printf "d %s \n" $1 >> log_temp
 fi
}
walk $arbreA
#dpnne le contenu d'un seul répertoire, utile quand les fichiers ne sont pas dans le même ordre
treeDirectory=$arbreA/*
for i in "${treeDirectory[@]}"; do
  echo $i
done
