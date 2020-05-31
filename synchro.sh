#!/usr/bin/env bash

# ---------------------------
# Projet final de LO14
# Pour P20
#----------------------------

arbreA=""
arbreB=""
trap cancelSync INT

cancelSync() {
	printf "\n INTERRUPTION VOLONTAIRE DE L'UTILISATEUR \n"
	 rm log_temp
		exit 1
}

#fonction qui compare les fichiers
compareFiles() {

	estdDansB=$(echo $1 | grep -c "arbreB")

	if [[ estDansB -ne 0 ]]; then
	{
		local eq_arbre="${1/$arbreB/$arbreA}"
	}
else
	{
		local eq_arbre="${1/$arbreA/$arbreB}"
	}
fi

	local result=""

	if [[ -f $eq_arbre ]]; then
		#le fichier existe et est un fichier
		#echo "le fichier existe et est un fichier"

		#teste si les 2 fichiers sont identiques (métadonnées)
		if [[ "$(stat -c '%A%s%y' "$1")" == "$(stat -c '%A%s%y' "$eq_arbre")" ]]; then
			#echo "le fichier existe, est un fichier et est identique à celui de l'arbre B (meta)"
			#TODO comparaison du contenu du fichier et verif avec le journal
			result="ok"
		else
			#echo "le fichier existe, est un fichier mais ses meta sont différentes de celui de l'arbre B (meta)"

			result="conflit;meta_diff"

		fi

	elif [[ -d $eq_arbre ]]; then
		#le fichier existe mais est un dossier
		#echo "ERREUR - le fichier est un dossier !"
		result="conflit;est_dossier"
	else
		#le fichier n'existe pas
		#echo "ERREUR - fichier inexistant !"
		result="conflit;inexistant"
	fi

	#on trouve quel est le fichier conforme au journal

	local conformiteCourant=$(log_compare "$entry")
	local conformiteAutre=$(log_compare "$eq_arbre")
	#echo "confA: $conformiteA confB: $conformiteB"

	if [[ "$conformiteCourant" == "1" ]] && [[ "$conformiteAutre" == "2" ]]; then
		#le fichier p/A est conforme
		result+=";a"
	elif [[ "$conformiteCourant" == "2" ]] && [[ "$conformiteAutre" == "1" ]]; then
		#le fichier p/B est conforme
		result+=";b"
	elif  [[ [["$conformiteCourant" == "2"]] && [["$conformiteAutre" == "2"]] ]]; then
		result+=";journal_incorrect"
	fi

	echo $result
}

#fonction qui compare les dossiers
compareFolders() {

	estdDansB=$(echo $1 | grep -c "arbreB")

		if [[ estDansB -ne 0 ]]; then
		{
			local eq_arbre="${1/$arbreB/$arbreA}"
		}
	else
		{
			local eq_arbre="${1/$arbreA/$arbreB}"
		}
	fi

	local result=""

	if [[ -d $eq_arbre ]]; then
		#le dossier existe et est un dossier

		#teste si les 2 dossiers sont identiques (métadonnées)
		if [[ "$(stat -c '%A%s%y' "$1")" == "$(stat -c '%A%s%y' "$eq_arbre")" ]]; then
			result="ok"
		else
			result="conflit;meta_diff"
		fi

	elif [[ -f $eq_arbre ]]; then
		#le dossier existe mais est un fichier
		result="conflit;est_fichier"
	else
		#le dossier n'existe pas
		result="conflit;inexistant"
	fi

	#on trouve quel est le dossier conforme au journal

	local conformiteCourant=$(log_compare "$entry")
	local conformiteAutre=$(log_compare "$eq_arbre")
	#echo "confA: $conformiteA confB: $conformiteB"

	if [[ "$conformiteCourant" == "1" ]] && [[ "$conformiteAutre" == "2" ]]; then
		#le dossier p/A est conforme
		result+=";a"
	elif [[ "$conformiteCourant" == "2" ]] && [[ "$conformiteAutre" == "1" ]]; then
		#le dossier p/B est conforme
		result+=";b"
	elif [[ "$conformiteCourant" == "0" ]] || [[ [["$conformiteCourant" == "2"]] && [["$conformiteAutre" == "2"]] ]]; then
		result+=";journal_incorrect"
	fi

	echo $result
}

#fonction de parcours de l'arbreA récursive
walk(){
	local indent="${2:-0}"
	#pour chaque élément du répertoire
	for entry in "$1"/*; do

			estDansB=$(echo $entry | grep -c 'arbreB')

				recherche=1

				if [[ estDansB -ne 0 ]]; then
				{
					local eq_arbre="${1/$arbreB/$arbreA}"
					rechercheLog=$(log_compare "$entry")

					if [ rechercheLog -eq 1 ] || [ rechercheLog -eq 1 ] ; then
						{
							echo "recherche est 0 "
						$recherche=0
					}
					fi
				}
			else
				{
					local eq_arbre="${1/$arbreA/$arbreB}"
				}
			fi

			if [ $recherche -eq 1 ] ; then
					{
	        #si c'est un fichier on affiche son chemin
	        if [[ -f "$entry" ]]; then
	            printf "%*sF - %s\n" $indent '' "$entry"
				#teste la présence de conflits
				local compResult=$(compareFiles "$entry")
				if [[ $compResult == *"conflit"* ]]; then

					echo "$compResult"
					#teste la présence d'un conflit de métadonnées
					if [[ $compResult == *"meta_diff"* ]]; then

						handleFileMetaConflict $compResult $entry $eq_arbre

					#teste la présence d'un conflit fichier/dossier
					elif [[ $compResult == *"est_dossier"* ]]; then

						handleFileNotFileConflict $compResult $entry $eq_arbre

					#teste la présence d'un conflit dû à un fichier/dossier inexistant
					elif [[ $compResult == *"inexistant"* ]]; then

						handleFileNotExistingConflict $compResult $entry $eq_arbre

					fi
				else
						log_write $entry
				fi
			#s'il s'agit d'un dossier, on affiche et on descend dedans
			elif [[ -d "$entry" ]]; then
				printf "%*sD - %s\n" $indent '' "$entry"
				#teste la présence de conflits
				local compResult=$(compareFolders "$entry")

				if [[ $compResult == *"conflit"* ]]; then

					echo "$compResult"
					#teste la présence d'un conflit de métadonnées
					if [[ $compResult == *"meta_diff"* ]]; then

						handleFolderMetaConflict $compResult $entry $eq_arbre

					#teste la présence d'un conflit fichier/dossier
					elif [[ $compResult == *"est_fichier"* ]]; then

						handleFolderNotFolderConflict $compResult $entry $eq_arbre

					#teste la présence d'un conflit dû à un dossier inexistant
					elif [[ $compResult == *"inexistant"* ]]; then

						handleFolderNotExistingConflict $compResult $entry $eq_arbre
					fi
				else
					log_write $entry
				fi
				walk "$entry" $((indent+4))
			fi
		}
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
# FONCTIONS DE GESTION DES CONFLITS
#----------------------------

#gère les conflits liées aux métadonnées des fichiers
#prend en paramètre le résultat de la comparaison et les deux éléments comparés
handleFileMetaConflict() {

	local compResult=$1
	local entry=$2
	local eq_arbreB=$3

	#si le fichier conforme est celui de l'arbre A
	if [[ "${1##*;}" == "a" ]]; then
		#synchronize le fichier non conforme avec les données du fichier conforme
		synchroReftoFile "$entry" "$eq_arbreB"
		log_write $entry
	#si le fichier conforme est celui de l'arbre B
	elif [[ "${1##*;}" == "b" ]]; then
		#synchronize le fichier non conforme avec les données du fichier conforme
		synchroReftoFile "$eq_arbreB" "$entry"
		log_write $eq_arbreB
	elif [[ "${1##*;}" == "journal_incorrect" ]]; then
		#conflit fallacieux
		log_conflict_management handleFileMetaConflict $compResult $entry $eq_arbreB
	else
		echo "ERREUR - la comparaison a échoué"
	fi
}

#gère les conflits fichier/dossier
#prend en paramètre le résultat de la comparaison et les deux éléments comparés
handleFileNotFileConflict() {

	local compResult=$1
	local entry=$2
	local eq_arbreB=$3

	#si l'élément conforme est celui de l'arbre A
	if [[ "${compResult##*;}" == "a" ]]; then
		#remplace le dossier de l'arbre B par le fichier de l'arbre A
		synchroFolderAndFile "$eq_arbreB" "$entry" 1
		log_write $entry
	#si l'élément conforme est celui de l'arbre B
	elif [[ "${compResult##*;}" == "b" ]]; then
		#remplace le fichier de l'arbre A par le dossier de l'arbre B
		synchroFolderAndFile "$eq_arbreB" "$entry" 2
		log_write $entry
	elif [[ "${compResult##*;}" == "journal_incorrect" ]]; then
		#conflit fallacieux
		log_conflict_management handleFileNotFileConflict $compResult $entry $eq_arbreB
	else
		echo "ERREUR - la comparaison a échoué"
	fi

}

handleFileNotExistingConflict() {

	local compResult=$1
	local entry=$2
	local eq_arbreB=$3

	#si le fichier conforme est celui de l'arbre A
	if [[ "${compResult##*;}" == "a" ]]; then
		#synchronize le fichier non conforme avec les données du fichier conforme
		synchroReftoFile "$entry" "$eq_arbreB"
		log_write $entry
	#si le fichier conforme est celui de l'arbre B
	elif [[ "${compResult##*;}" == "b" ]]; then
		#supprime le fichier de l'arbre A
		rm -f -r "$entry"
	elif [[ "${compResult##*;}" == "journal_incorrect" ]]; then
		#conflit fallacieux
		log_conflict_management handleFileNotExistingConflict $compResult $entry $eq_arbreB
	else
		echo "ERREUR - la comparaison a échoué"
	fi

}

handleFolderMetaConflict() {

	local compResult=$1
	local entry=$2
	local eq_arbreB=$3

	#si le dossier conforme est celui de l'arbre A
	if [[ "${compResult##*;}" == "a" ]]; then
		#synchronize le dossier non conforme avec les données du dossier conforme
		synchroReftoFolder "$entry" "$eq_arbreB"
		log_write $entry
	#si le dossier conforme est celui de l'arbre B
	elif [[ "${compResult##*;}" == "b" ]]; then
		#synchronize le dossier non conforme avec les données du dossier conforme
		synchroReftoFolder "$eq_arbreB" "$entry"
		log_write $eq_arbreB
	elif [[ "${compResult##*;}" == "journal_incorrect" ]]; then
		#conflit fallacieux
		log_conflict_management handleFolderMetaConflict $compResult $entry $eq_arbreB
	else
		echo "ERREUR - la comparaison a échoué"
	fi
}

#gère les conflits fichier/dossier
#prend en paramètre le résultat de la comparaison et les deux éléments comparés
handleFolderNotFolderConflict() {

	local compResult=$1
	local entry=$2
	local eq_arbreB=$3

	#si l'élément conforme est celui de l'arbre A
	if [[ "${compResult##*;}" == "a" ]]; then
		#remplace le fichier de l'arbre B par le dossier de l'arbre A
		synchroFolderAndFile "$entry" "$eq_arbreB" 2
		log_write $entry
	#si l'élément conforme est celui de l'arbre B
	elif [[ "${compResult##*;}" == "b" ]]; then
		#remplace le dossier de l'arbre A par le fichier de l'arbre B
		synchroFolderAndFile "$entry" "$eq_arbreB" 1
		log_write $entry
	elif [[ "${compResult##*;}" == "journal_incorrect" ]]; then
		#conflit fallacieux
		log_conflict_management handleFolderNotFolderConflict $compResult $entry $eq_arbreB
	else
		echo "ERREUR - la comparaison a échoué"
	fi

}

handleFolderNotExistingConflict() {

	local compResult=$1
	local entry=$2
	local eq_arbreB=$3

	#si le dossier conforme est celui de l'arbre A
	if [[ "${compResult##*;}" == "a" ]]; then
		#crée le dossier dans l'arbreB
		synchroReftoFolder "$entry" "$eq_arbreB"
		log_write $entry
	#si le dossier conforme est celui de l'arbre B
	elif [[ "${compResult##*;}" == "b" ]]; then
		#supprime le dossier de l'arbre A
		rm -f -r "$entry"
	elif [[ "${compResult##*;}" == "journal_incorrect" ]]; then
		#conflit fallacieux
		log_conflict_management handleFolderNotExistingConflict $compResult $entry $eq_arbreB
	else
		echo "ERREUR - la comparaison a échoué"
	fi

}


# ---------------------------
# FONCTIONS DE SYNCHRO
#----------------------------

#fonction qui synchronise un fichier avec les données d'un fichier de référence (crée au passage les dossiers parents manquants)
synchroReftoFile() {
	mkdir -p "$(dirname $2)" && cp --preserve "$1" "$2"
}

#fonction qui transforme un dossier en un fichier en appliquant les metadonnées de référence (et vice-versa) (crée au passage les dossiers parents manquants)
#arg1 = dossier
#arg2 = fichier
#arg3 = 1 ou 2 : sens de l'opération (dossier vers fichier ou fichier vers dossier)
synchroFolderAndFile() {
	#echo "le dauphin"
	if [[ $3 -eq 1 ]]; then
		rmdir --ignore-fail-on-non-empty "$1" #on supprime le dossier
		mkdir -p "$(dirname $1)" && cp --preserve "$2" "$1" #on copie le fichier à sa place
	elif [[ $3 -eq 2 ]]; then
		rm -f "$2" #on supprime le fichier
		mkdir -p "$(dirname $2)" && cp -r --preserve "$1" "$2" #on copie le dossier à sa place
	fi
}

#fonction qui synchronise les métadonnées d'un dossier avec celle d'un dossier de référence (crée au passage les dossiers parents manquants)
synchroReftoFolder() {
	mkdir -p "$2"
	chmod --reference="$1" "$2"
    chown --reference="$1" "$2"
    touch --reference="$1" "$2"
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
#prend en paramètre la fonction a appeler pour résoudre le conflit (une fois la sélection faite)
#mais aussi les 3 arguments de cette fonction (résultat de comparaison, fichier A et équivalent B)
log_conflict_management()			#Fonction permettant la création d'un menu de gestion des conflits
{

	local compResult=$2
	local entry=$3
	local eq_arbreB=$4

	#echo "entry: $entry"
	#echo "eq_arbreB: $eq_arbreB"

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
							#appel de la fonction qui gère le conflit, en précisant que A est conforme
							$1 "${compResult/journal_incorrect/a}" "$entry" "$eq_arbreB"
							break
							;;
					"Synchronisation selon l'arbre B")
							#appel de la fonction qui gère le conflit, en précisant que B est conforme
							$1 "${compResult/journal_incorrect/b}" "$entry" "$eq_arbreB"
							break
							;;
					"Annuler l'opération en cours (pas de sync)")
							cancelSync
							;;
					*) echo "Saisie invalide, recommencez $REPLY";;
			esac
	done
}

recuperation_arbres()
{
		arbreA=$(sed '1q;d' log_file)
		arbreB=$(sed '2q;d' log_file)

		echo $arbreA >> log_temp
		echo $arbreB >> log_temp
}

menu_choix_arbre()
{
		printf "\t ================================ Première utilisation ================================\n"
		printf "Merci pour votre première utilisation de cet outil de synchronisation \n"
		printf "Merci d'entrer le premier dossier que vous souhaitez synchroniser : (Adresse absolue) \n"
		read arbreA
		while [[ ! -d $arbreA ]]; do
				echo "Vous n'avez pas entré une adresse valide, recommencez : "
				read arbreA
	done

		printf "Merci d'entrer le deuxième dossier que vous souhaitez synchroniser : (Adresse absolue) \n"
		read arbreB
		while [[ ! -d $arbreB ]]; do
				echo "Vous n'avez pas entré une adresse valide, recommencez : "
				read arbreB
	done
				echo "$arbreA" >> log_temp
				echo "$arbreB" >> log_temp
				echo "" >> log_file
}
# ---------------------------
# BOUCLE PRINCIPALE
#----------------------------

# on test si le programme a déjà tourné (pour le choix des branches )
if [[ ! -f log_file ]]; then
	menu_choix_arbre
else
	recuperation_arbres
fi
clear
echo "Synchronisation ..."
#lance la boucle
walk "$arbreA"
walk "$arbreB"
log_merge
