#!/usr/bin/env bash
arbreA="tests/arbreA"
arbreB="tests/arbreB"
# Projet final de LO14
# Pour P20
#Affiche la hieracrhie des sous-repoertoires
#ls -R tests/arbreA | grep ":$" | sed -e 's/:$//' -e 's/[^-][^\/]*\//--/g' -e 's/^/   /' -e 's/-/|/'
#Affiche la hieracrhie des sous-repoertoires
#ls -R tests/arbreB| grep ":$" | sed -e 's/:$//' -e 's/[^-][^\/]*\//--/g' -e 's/^/   /' -e 's/-/|/'
#find tests/arbreA

#fonction qui synchronise un fichier b avec les données d'un fichier a (crée au passage les dossiers parents manquants)
synchroAtoB() {
	mkdir -p "$(dirname $2)" && cp --preserve "$1" "$2"
}

#fonction qui compare les fichiers
compareFiles() {

	local eq_arbreB="${1/$arbreA/$arbreB}"
	local result=""

	if [[ -f $eq_arbreB ]]; then
		#le fichier existe et est un fichier
		#echo "le fichier existe et est un fichier"

		#teste si les 2 fichiers sont identiques (métadonnées)
		if [[ "$(stat -c '%A%s%y' "$1")" == "$(stat -c '%A%s%y' "$eq_arbreB")" ]]; then
			#echo "le fichier existe, est un fichier et est identique à celui de l'arbre B (meta)"
			#TODO comparaison du contenu du fichier et verif avec le journal
			result="ok"
		else
			#echo "le fichier existe, est un fichier mais ses meta sont différentes de celui de l'arbre B (meta)"
			result="conflit;meta_diff"
		fi

	elif [[ -d $eq_arbreB ]]; then
		#le fichier existe mais est un dossier
		#echo "ERREUR - le fichier est un dossier !"
		result="conflit;est_dossier"
	else
		#le fichier n'existe pas
		#echo "ERREUR - fichier inexistant !"
		result="conflit;inexistant"
	fi

	echo $result
}


#fonction de parcours de l'arbreA récursive
walk(){
	local indent="${2:-0}"
	#echo "$1"/*
	#pour chaque élément du répertoire
	for entry in "$1"/*; do
	#si c'est un fichier on affiche son chemin
          if [[ -f "$entry" ]]; then
            printf "%*sF - %s\n" $indent '' "$entry"
						log_write $entry
						#teste la présence de conflits
						if [[ $(compareFiles "$entry") == *"conflit"* ]]; then
							synchroAtoB "$entry" "${entry/$arbreA/$arbreB}"
						fi
          #s'il sagit d'un dossier, on affiche et on descend dedans
          elif [[ -d "$entry" ]]; then
            printf "%*sD - %s\n" $indent '' "$entry"
						log_write $entry
            walk "$entry" $((indent+4))
          fi
        done
}

log_write()
{
	#Si l'élément et un fichier, on ajoute f devant pour le représenter
if [[ -f "$1" ]]; then
	printf "f %s " $1  >> log_temp  #On fait précéder le nom du fichier par la mention f (pour file) pour l'identifier
			#Si l'élément et un dossier, on ajoute d devant pour le représenter
elif [[ -d "$1" ]]; then
	printf "d %s " $1 >> log_temp #idem avec un D pour directory
 fi
 echo $(stat -c '%A%s%y' $1) >> log_temp
}
log_merge()
{
	rm log_file
	cp log_temp log_file
	wait
	rm log_temp
}

#lance la boucle
walk "$arbreA"
log_merge
