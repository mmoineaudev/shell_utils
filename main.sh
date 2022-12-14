#!/bin/bash
######################################
#
# Template shell pour porvoir coder avec plusieurs fichiers dépendants facilement
# L'arborescence cible est dans l'état :
# ./[le point d'entrée]
# ./lib/[les dépendances]
#
######################################

######################################
# Imports
######################################
BASEDIR=$(dirname "$0")
ls ./lib | grep ".sh"
# Déclaration des noms de fichiers dans le répertoire des dépendances 
IMPORTS=( ) # l'ordre d'import n'importe pas, une fois les fichiers sourcés chacunes des fonctions appelées depuis $0 peut utiliser chacune des dépendances, 
# attention à la surcharge de noms de variables !
echo -n "Saisissez la liste des dépendances que vous souhaitez utiliser
format attendu : style.sh lib1 lib2
>"
read -r IMPORTS
echo -e "\e[91m ${IMPORTS[@]} \e[0m"

# Import des fonctions et variables de ces fichiers avec arrêt du script en cas d'erreur
for dependancy in ${IMPORTS[@]}; do
    echo -n "Importing ${BASEDIR}/lib/${dependancy}"
    source ${BASEDIR}/lib/${dependancy}
    status="$?"
    if [ $status -ne "0" ]; then
        echo -e "\e[91m ${BASEDIR}/lib/${dependancy} could not be sourced !
        Stopping $0. \e[0m"
        exit 1
    fi
    echo "... Status : [${status}]"
done

# Pour vérifier quelles fonctions sont accessibles : 
print_avalaible_functions() {
    print_title "Fonctions disponibles"
    VAR=()
    VAR+=$(declare -F)
    print "${VAR//'declare -f'/}"
    print_separator
}
######################################

print_avalaible_functions

# bonjour, ceci est une modif complétement legit 

print "Entrez une fonction et éventuellement ses arguments :"
read -p "> " FUNCTION

echo "$FUNCTION"

${FUNCTION}

exit_ok