#!/bin/bash

# Poc pour faisabilité d'atteindre l'écosystème acoss via la vm, directement,en ssh

init() {
    # Paramètres d'affichage ################################## https://misc.flogisoft.com/bash/tip_colors_and_formatting
    export RAZ_STYLE="\e[0m"
    export PROMPT_STYLE="\e[0;49;92m"
    export ORANGE_STYLE="\e[0;40;93m"
}
init
echo -ne "${PROMPT_STYLE}Saisissez l'emplacement de la clé privée (format unix):${RAZ_STYLE}"
read -p " " PRIVATE_KEY

echo -ne "${PROMPT_STYLE}Saisissez l'user :${RAZ_STYLE}"
read -p " " USER

echo -ne "${PROMPT_STYLE}Saisissez le remote :${RAZ_STYLE}"
read -p " " HOST

# Credit : Steven Spielberg pour l'appelation désormais connue "& tee"
ssh ${USER}@${HOST} -i ${PRIVATE_KEY} |& tee $0.log
