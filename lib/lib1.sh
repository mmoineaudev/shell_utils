#!/bin/bash



send_file_via_scp() {
    print_title "Envoyer un fichier depuis $(hostname) via SCP (ssh) vers un serveur distant"
    echo -ne "${print_STYLE} Entrez le chemin absolu du fichier/dossier DESTINATION (exemple /home/hawai):${RAZ_STYLE}"
    remote_folder=
    read remote_folder
    echo -ne "${print_STYLE} Entrez l'IP ou le nom de domaine du serveur DESTINATION (exemple carbone.cve.recouv):${RAZ_STYLE}"
    remote_host=
    read remote_host
    echo -ne "${print_STYLE} Entrez l'username du serveur DESTINATION (exemple CNP):${RAZ_STYLE}"
    username=
    read username
    echo -ne "${print_STYLE} Entrez le chemin absolu du fichier/dossier à envoyer (exemple /home/hawai/dumps):${RAZ_STYLE}"
    LOCAL_FILE_OR_FOLDER=
    read LOCAL_FILE_OR_FOLDER
    echo -e "${print_STYLE} Appuyez sur entrée pour lancer la commande : ${RAZ_STYLE}"
    read -p "scp -r ${LOCAL_FILE_OR_FOLDER} ${username}@${remote_host}:${remote_folder}" ok
    scp -r ${LOCAL_FILE_OR_FOLDER} ${username}@${remote_host}:${remote_folder}
    echo -e "${print_STYLE} CR=$? ${RAZ_STYLE}"
}
get_file_via_scp() {
    print_title "Récupérer un fichier d'un serveur distant vers $(hostname) via SCP (ssh)"
    echo -ne "${print_STYLE} Entrez l'IP ou le nom de domaine du serveur SOURCE (exemple carbone.cve.recouv):${RAZ_STYLE}"
    remote_host=
    read remote_host
    echo -ne "${print_STYLE} Entrez le chemin absolu du fichier/dossier dans ${remote_host} (exemple /home/hawai):${RAZ_STYLE}"
    remote_folder=
    read remote_folder
    echo -ne "${print_STYLE} Entrez l'username du serveur ${remote_host} (exemple CNP):${RAZ_STYLE}"
    username=
    read username
    echo -ne "${print_STYLE} Entrez le chemin absolu du fichier/dossier DESTINATION dans $(hostname) (exemple /home/hawai/dumps):${RAZ_STYLE}"
    LOCAL_FILE_OR_FOLDER=
    read LOCAL_FILE_OR_FOLDER
    echo -e "${print_STYLE} Appuyez sur entrée pour lancer la commande : ${RAZ_STYLE}"
    read -p "scp -r ${username}@${remote_host}:${remote_folder} ${LOCAL_FILE_OR_FOLDER}" ok
    scp -r ${username}@${remote_host}:${remote_folder} ${LOCAL_FILE_OR_FOLDER}
    echo -e "${print_STYLE} CR=$? ${RAZ_STYLE}"
}

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
    print_separator
    cd ${PWD_COPY} # si on rappelle PWD en fait il change de répertoire
}