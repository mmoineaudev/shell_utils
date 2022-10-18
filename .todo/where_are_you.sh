#!/bin/bash
# peut prendre un paramètre, ou un pattern de selection multiple 
# sous la forme 'un|deux|trois'


# Variable de présentation
RAZ_STYLE="\e[0m"
BLUE_STYLE="\e[0;49;96m"
PURPLE_STYLE="\e[1;40;35m"
RED_STYLE="\e[91m"
GREEN_STYLE="\e[38;5;82m"
PROMPT_STYLE="\e[0;49;92m"
ORANGE_STYLE="\e[0;40;93m"

PWD=$(pwd)
if [[ $1 ]]; then 
    PATTERN=$1
else
    echo -e "${BLUE_STYLE}${PWD} Bonjour,${RAZ_STYLE}"
    echo -ne "${BLUE_STYLE}Saisissez un mot, ou une liste de mot au format : mot1|mot2|mot3 
# ${RAZ_STYLE}"
    read PATTERN
fi
echo -e "${BLUE_STYLE}-------------${PROMPT_STYLE}RÉSULTATS${BLUE_STYLE}----------------${RAZ_STYLE}"

grep --color=always -Ril "${PATTERN}" | egrep --color=always -rin "${PATTERN}"
echo -e "${BLUE_STYLE}--------------------------------------${RAZ_STYLE}"
echo -e "${PROMPT_STYLE}# Fin de la recherche${RAZ_STYLE}"
read  EXIT