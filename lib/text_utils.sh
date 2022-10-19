#!/bin/bash

#################################################### 
# Prends un chemin de fichier en paramètre
# Affiche sur une seule ligne les occurences de logs :
# * "debug"
# * "warn"
# * "(erreur|error)"
# * "fatal"
# * "grave"
LOGS_count_first_parameter_log_levels_occurences() {   
    logfile=$1
    NB_LINES=$(cat ${logfile} | wc -l)
    NB_DEBUG=
    NB_WARN=
    NB_ERR=
    NB_FATAL=
    NB_GRAVE=
    if [[ ${NB_LINES} -gt 0 ]]; then
        echo -ne "${print_STYLE} Nombre de lignes : ${NB_LINES}"
        NB_DEBUG=$(cat ${logfile} | grep -i "debug" | wc -l)
        if [[ ${NB_DEBUG} -gt 0 ]]; then
            echo -ne "${print_STYLE} debug : ${NB_DEBUG}"
        fi
        NB_WARN=$(cat ${logfile} | grep -i "warn" | wc -l)
        if [[ ${NB_WARN} -gt 0 ]]; then
            echo -ne "${PURPLE_STYLE} warn : ${NB_WARN}"
        fi
        NB_ERR=$(cat ${logfile} | egrep -i "(erreur|error)" | wc -l)
        if [[ ${NB_ERR} -gt 0 ]]; then
            echo -ne "${RED_STYLE} erreur/error : ${NB_ERR}"
        fi
        NB_FATAL=$(cat ${logfile} | grep -i "fatal" | wc -l)
        if [[ ${NB_FATAL} -gt 0 ]]; then
            echo -ne "${ORANGE_STYLE} fatal : ${NB_FATAL}"
        fi
        NB_GRAVE=$(cat ${logfile} | grep -i "grave" | wc -l)
        if [[ ${NB_GRAVE} -gt 0 ]]; then
            echo -ne "${RED_STYLE} grave : ${NB_GRAVE}"
        fi
    else  
        echo -ne "vide"
    fi  
    echo -e ${RAZ_STYLE}
}

###################################################
# Cherche des occurences de mots dans toute l'arborescence souhaitée
# Permet de chercher dans l'arborescence courantes (c'est récursif)
# Utilise l'option --color=always de manière gourmande car elle apporte
# une grande facilité de lecture
#
# Attention toutefois, dans le cas ou il y a beaucoup de fichiers en 
# sortie il faudrait la commande more qui... n'existe pas sur git bash, 
# du coup tant que je bosse sur un windows il y aura hélas pas de pagination
find_word_in_files() {
    PWD=$(pwd)
    PWD_COPY="$PWD" # c'est bizarre mais ça marche
    PATTERN_TO_SEARCH=
    PATH_TO_GO=
    print "Souhaitez vous chercher dans une arborescence en particulier ? 
    Si non la recherche se fera dans ${PWD}
    Si oui saisissez l'arborescence : ${RAZ_STYLE}"
    read PATH_TO_GO

    print "Saisissez un mot, ou une liste de mot au format : mot1|mot2|mot3 
    Que cherchez vous ? ${RAZ_STYLE}"
    read PATTERN_TO_SEARCH

    if [[ $PATH_TO_GO ]]; then
        cd ${PATH_TO_GO} 
    fi

    print_separator
    egrep --color=always -Ril "${PATTERN_TO_SEARCH}" | egrep --color=always -rin "${PATTERN_TO_SEARCH}" 
    more temp.log
    rm -f temp.log
    print_separator
    cd ${PWD_COPY} # si on rappelle PWD en fait il change de répertoire
}