#!/bin/bash
# A creuser curl -k -H "X-Redmine-API-Key: bbcf9b9ec691d0040d10e8e3b4c7b827be0524c0" https://redmine.altair.recouv/issues/676223 -x fqdn-acoss.cipam.ext.sopra:8000 | egrep "(<title>|<div class=\"label\">Statut:</div><div class=\"value\">)"
# Paramètres

RAZ_STYLE="\e[0m"
BLUE_STYLE="\e[0;49;96m"
PURPLE_STYLE="\e[1;40;35m"
RED_STYLE="\e[91m"
GREEN_STYLE="\e[38;5;82m"
UDERLINE_STYLE="\e[4m"
PROMPT_STYLE="\e[0;49;92m"
TICKET_STYLE="\e[7;41;97m"
ORANGE_STYLE="\e[0;40;93m"
separator_char=';'
DATE=$(date +"%Y_%m_%d")
NAMING="SDETI_suivi_activite"
FILE="${DATE}_${NAMING}.csv"
# Variables
ACTIVITIES=(
    'PRISE DE Co. - FORMATION           '
    'INTEGRATION- 1. Lot                '
#    'INTEGRATION- 2.Phase de tests      '
#    'INTEGRATION- 3. Lot SNV2           '
#    'EDITIQUE - Offre de service        '
    'RT                                 '
#    'CSTRAT Projet                      '
    'Tickets SUPPORT C1 & C2            '
#    'Nouv appli: prise co, intég 1er lot'
#    'Activités sur DEVIS                '
#    'Diffusion TELEDEP                  '
#    'SUPPORT ALM niveaux 1,2 & 3        '
    'INCUBATION                         '
#    'SUPERVISION hors Lot               '
    'Capitalisation/wiki                '
    'Réunion interne                    '
)

# Affichage
print_title() {
    echo -ne ${BLUE_STYLE}
    echo " __   __  _______  __   __  _______ "
    echo "|  |_|  ||       ||  |_|  ||       |"
    echo "|       ||    ___||       ||   _   |"
    echo "|       ||   |___ |       ||  | |  |"
    echo "|       ||    ___||       ||  |_|  |"
    echo "| ||_|| ||   |___ | ||_|| ||       |"
    echo "|_|   |_||_______||_|   |_||_______|"
    echo -e ${RAZ_STYLE}
    
}
# ecris dans le fichier créé quotidiennement
write() {
    echo $1 >> ${FILE}
}
# Affichage en mode regex, pas de sauts de ligne à la fin
prompt() {
    echo -ne "${PROMPT_STYLE}"
    echo -ne "$1"
    echo -e "${RAZ_STYLE}"
}
print_separator() {
    ## Affiche un séparateurte
    echo -e "  ${UDERLINE_STYLE}                                                ${RAZ_STYLE}"
    echo
}
# Permet la lecture et l'affichage d'un ${FILE} écrit par ce script
read_from_file() {
    # on passe le file en paramètre pour pouvoir lire ceux des jours précédents
    SELECTED_FILE=$1
    while IFS= read -r line
    do
        # par contre c'est long je sais pas bien pourquoi
        
        # variables intermédiaires pour la présentation
        display_num_ticket=$(echo $line | cut -f1 -d"${separator_char}")
        display_temps_passe=$(echo $line | cut -f2 -d"${separator_char}")
        display_activity=$(echo $line | cut -f3 -d"${separator_char}")
        display_timestamp_and_comment=$(echo $line | cut -f4 -d"${separator_char}")        
        echo -e "
#${TICKET_STYLE} ${display_num_ticket} ${RAZ_STYLE} ${BLUE_STYLE} ${display_timestamp_and_comment} ${RAZ_STYLE}
${ORANGE_STYLE} ${display_temps_passe} ${RAZ_STYLE} ${RED_STYLE} ${display_activity}${RAZ_STYLE}"

    done < "${SELECTED_FILE}"
    
}
# récupère un input utilisateur, écrit dans le ${FILE} à la fin
read_ticket() {
    TEMPS_PASSE=
    prompt "Saisissez un numéro de ticket redmine ( Autres sinon ):"
    read TICKET
    prompt "Saisissez une application (ou laissez vide):"
    read APPLI
    # Rajoutez ici les noms d'applis que vous utilisez [ echo -e "${ORANGE_STYLE}--> NOM_APPLI_1 ${RAZ_STYLE}"]
    prompt "Liste des activités :\n"
    # On affiche la liste d'activités
    for i in $(seq 0 ${#ACTIVITIES[@]}); do
        if [[ ${ACTIVITIES[$i]} ]]; then
            echo -e "  ${BLUE_STYLE} n° $i : ${ACTIVITIES[$i]} ${RAZ_STYLE}"
        fi
    done
    prompt "Saisissez un numéro d'activité :"
    read ACTIVITY_INDEX
    prompt "Saisissez si vous le souhaitez un commentaire ( \\\\n pour faire un saut de ligne):"
    read comment
    prompt "Saisissez un temps passé (en proportion de journée, format [0:1].[0:9]) :"
    read TEMPS_PASSE
    prompt "KANBAN : TODO DOING DONE"
    read KANBAN
    write " ${TICKET} ${separator_char} ${TEMPS_PASSE} ${KANBAN} ${separator_char} ${ACTIVITIES[${ACTIVITY_INDEX}]} ${APPLI}${separator_char} [$(date +%H:%M)] ${comment}"
}

# Affiche le titre
print_title
# récupère les noms des fichiers précédement créés
ls *${NAMING}*
prompt "Entrez un nom de fichier pour consulter les actions des jours précédents, rien sinon :"
read -r PREVIOUS_FILES
# si c'est vide on ne rentre pas dans le for
for selected_file in ${PREVIOUS_FILES[@]}; do
    prompt "${selected_file}\ntri par ticket :"
    sort ${selected_file} > temp.${selected_file}
    read_from_file temp.${selected_file}
    OK=
    prompt "Appuyez sur entrée..."
    rm -f temp.${selected_file}
    read OK
done

while :; do
    clear
    print_title
    prompt "Affichage de ${FILE}\n"
    read_from_file ${FILE}
    read_ticket
done
