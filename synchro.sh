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
						compareFiles "$entry"
          #s'il sagit d'un dossier, on affiche et on descend dedans
          elif [[ -d "$entry" ]]; then
            printf "%*sD - %s\n" $indent '' "$entry"
            walk "$entry" $((indent+4))
          fi
        done
}

#lance la boucle principale
walk "$arbreA"
