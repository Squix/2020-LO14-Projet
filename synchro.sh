#!/usr/bin/env bash

# ---------------------------
# Projet final de LO14
# Pour P20
#----------------------------

arbreA="tests/arbreA"
arbreB="tests/arbreB"

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

			#on trouve quel est le fichier conforme au journal

			local conformiteA=$(log_compare "$entry")
			local conformiteB=$(log_compare "$eq_arbreB")
			echo "confA: $conformiteA confB: $conformiteB"

			if [[ "$conformiteA" == "1" ]] && [[ "$conformiteB" == "2" ]]; then
				#le fichier p/A est conforme
				result="conflit;meta_diff;a"
			elif [[ "$conformiteA" == "2" ]] && [[ "$conformiteB" == "1" ]]; then
				#le fichier p/B est conforme
			  result="conflit;meta_diff;b"
			elif [[ "$conformiteA" == "0" ]] || [[ [["$conformiteA" == "2"]] && [["$conformiteB" == "2"]] ]]; then
				result="conflit;meta_diff;journal_incorrect"
			fi

			#result="$conformiteA"

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
	#pour chaque élément du répertoire
	for entry in "$1"/*; do
        	#si c'est un fichier on affiche son chemin
          if [[ -f "$entry" ]]; then
            printf "%*sF - %s\n" $indent '' "$entry"
						#log_compare $entry
						log_write $entry
						#teste la présence de conflits
						local compResult=$(compareFiles "$entry")
						if [[ $compResult == *"conflit"* ]]; then

							echo "$compResult"
							#synchroAtoB "$entry" "${entry/$arbreA/$arbreB}"
						fi
          #s'il sagit d'un dossier, on affiche et on descend dedans
          elif [[ -d "$entry" ]]; then
            printf "%*sD - %s\n" $indent '' "$entry"
						#log_compare $entry
						log_write $entry
            walk "$entry" $((indent+4))
          fi
        done
}

#génère le chemin relatif du fichier à partir de son chemin absolu
getFileRelativePath() {

	local elemName_temp=${1/$arbreA/} #supprime le chemin absolu de arbreA
	local elemName=${elemName_temp/$arbreB/} #supprime le chemin absolu de arbreB (pour que ça marche quelque soit le fichier passé en argument)
	echo "$elemName"
}

# ---------------------------
# FONCTIONS JOURNAL
#----------------------------

#écrit le fichier passé en argument dans le journal
log_write()
{

	local elemName=$(getFileRelativePath "$1")

	#Si l'élément et un fichier, on ajoute f devant pour le représenter
	if [[ -f "$1" ]]; then
		printf "f %s " $elemName  >> log_temp  #On fait précéder le nom du fichier par la mention f (pour file) pour l'identifier
	elif [[ -d "$1" ]]; then
		printf "d %s " $elemName >> log_temp #idem avec un D pour directory
	 fi
	 echo $(stat -c '%A%s%y' $1) >> log_temp  #Que l'élément soit un fichier ou un dossier, on lui indique ses meta-données
}

#se débarasse du fichier log de lecture (log_temp) pour l'injecter dans le fichier log_file
log_merge()
{
	rm log_file
	cp log_temp log_file
	wait
	rm log_temp
}

#compare les métadonnées d'un fichier passé en entrée aux métadonnées dudit fichier stockées dans le journal
log_compare()
{

		local elemName=$(getFileRelativePath "$1")

		if [[ $(grep -c "$elemName" log_file) -ne 0 ]]; then #On regarde si une ligne correspond au nom de l'élément courant
			# echo "present dans la DB"
				if [[ -f "$1" ]]; then			#Selon si l'élément courant est un fichier ou un dossier, on lui donne la même structure que celle du fichier de log
					currentFormatRecherche="f $elemName $(stat -c '%A%s%y' $1)"
				elif [[ -d "$1" ]]; then
					currentFormatRecherche="d $elemName $(stat -c '%A%s%y' $1)"
				 fi
			resultatDansBd=$(grep "$elemName " log_file) #On récupère la ligne (théoriquement unique sans retouche manuelle) complète qui correspond à l'élément courant
			if [[ "$currentFormatRecherche" == "$resultatDansBd" ]]; then
				echo "1"   #Si les meta données concordent, on renvoie 1
			else
				echo "2"		#Si les meta données ne sont pas concordes, on renvoie 2
			fi
		else	#Si aucune ligne ne correspond au fichier, on le signale
			echo "0"  #Si on ne retrouve aucune information sur l'élément dans le fichier log, on renvoie 0
		fi
}

log_conflict_management()			#Fonction permettant la création d'un menu de gestion des conflits
{
	printf "\n"
	printf "\t ================================ Alerte ================================\n"
	echo "Le journal ne correspond à aucune des 2 versions présentées, que faire ? [Tapez 1, 2 ou 3]"
	local PS3='Votre sélection: '
	local options=("Synchronisation selon l'arbre A" "Synchronisation selon l'arbre B" "Annuler l'opération en cours (pas de sync)")
	local opt
	select opt in "${options[@]}"
	do
			case $opt in
					"Synchronisation selon l'arbre A")
							return 1
							;;
					"Synchronisation selon l'arbre B")
							return 2
							;;
					"Annuler l'opération en cours (pas de sync)")
							return 0
							;;
					*) echo "Saisie invalide, recommencez $REPLY";;
			esac
	done
}

# ---------------------------
# BOUCLE PRINCIPALE
#----------------------------

#lance la boucle
#log_conflict_management
walk "$arbreA"
log_merge
