#!/usr/bin/env bash

# Projet final de LO14
# Pour P20

#Affiche la hieracrhie des sous-repoertoires

ls -R tests/arbreA #| grep ":$" | sed -e 's/:$//' -e 's/[^-][^\/]*\//--/g' -e 's/^/   /' -e 's/-/|/'

#Affiche la hieracrhie des sous-repoertoires

ls -R tests/arbreB
