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

#fonction de parcours récursive
walk() {
        local indent="${2:-0}"
        #echo "$1"/*

        #pour chaque élément du répertoire
        for entry in "$1"/*; do


          #si c'est un fichier, on affiche son chemin
          if [[ -f "$entry" ]]; then
            printf "%*sF - %s\n" $indent '' "$entry"
          #s'il sagit d'un dossier, on affiche et on descend dedans
          elif [[ -d "$entry" ]]; then
            printf "%*sD - %s\n" $indent '' "$entry"
            walk "$entry" $((indent+4))
          fi

        done
}
#walk tests/arbreA

#dpnne le contenu d'un seul répertoire, utile quand les fichiers ne sont pas dans le même ordre
treeDirectory=$arbreA/*
for i in "${treeDirectory[@]}"; do
  echo $i
done
