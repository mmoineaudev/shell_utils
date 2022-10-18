#!/bin/bash
# Le développeur shell, toujours en recherche de la solution la plus ergonomique
# mélangea le smartphone et l'ipod, et cela fit un... smartphone

##############
# présentation 
RAZ_STYLE="\e[0m"
BLUE_STYLE="\e[0;49;96m"
PURPLE_STYLE="\e[1;40;35m"
RED_STYLE="\e[91m"
GREEN_STYLE="\e[38;5;82m"
UDERLINE_STYLE="\e[4m"
PROMPT_STYLE="\e[0;49;92m"
B_and_N_STYLE="\e[30mBlack\e[107m"
ORANGE_STYLE="\e[0;40;93m"
##############
# MEMOISATION
INDEX=0
MENU=(
    "Une option"
    "Une autre option"
    "C, la réponse C"
    "C'est vraiment star wars"
)
MAX_INDEX=${#MENU[@]}
print_title() {
    echo -ne ${BLUE_STYLE}
    echo -e '      ______ _____   _____  ____  _   _  ____  __  __ _____ _____  '
    echo -e ' |  ____|  __ \ / ____|/ __ \| \ | |/ __ \|  \/  |_   _/ ____| '
    echo -e ' | |__  | |__) | |  __| |  | |  \| | |  | | \  / | | || |      '
    echo -e ' |  __| |  _  /| | |_ | |  | | . ` | |  | | |\/| | | || |      '
    echo -e ' | |____| | \ \| |__| | |__| | |\  | |__| | |  | |_| || |____  '
    echo -e ' |______|_|__\_\\_____|\____/|_|_\_|\____/|_|  |_|_____\_____| '
    echo -e '  / ____|__   __| |  | |  ____|  ____|                         '
    echo -e ' | (___    | |  | |  | | |__  | |__                            '
    echo -e '  \___ \   | |  | |  | |  __| |  __|                           '
    echo -e '  ____) |  | |  | |__| | |    | |                              '
    echo -e ' |_____/   |_|   \____/|_|    |_|                              '
    echo -e ${RAZ_STYLE}

}
print_menu_item() {
    BALISE_ENTRANTE=$1
    MESSAGE=$2
    OPTION_NUMBER=$3
    BALISE_FERMANTE=${RAZ_STYLE}
    echo -ne "${BALISE_ENTRANTE} [${OPTION_NUMBER}] "
    echo -ne "${MESSAGE}"
    echo -e "${BALISE_FERMANTE}"
}
print_menu() {
    for i in $(seq 0 $((${#MENU[@]}-1))); do 
        if [[ $i == $INDEX ]]; then 
            print_menu_item "${GREEN_STYLE}" "${MENU[$i]}" $i
        else 
            print_menu_item "${ORANGE_STYLE}" "${MENU[$i]}" $i
        fi
    done
    echo
    echo -e "${BLUE_STYLE}    \$_ ${MENU[$INDEX]} ${RAZ_STYLE}"
}
read_input() {
    echo -e "Appuyez sur s ou z pour vous déplacer, entrée pour sélectionner : "
    read -p ": " COMMAND
    if [[ ${COMMAND} == "z" ]]; then
        if [[ ${INDEX} > 0 ]]; then 
            INDEX=$(($INDEX - 1))
        fi
    elif [[ ${COMMAND} == "s" ]]; then
        if [[ ${INDEX} < $((${MAX_INDEX}-1)) ]]; then 
            INDEX=$(($INDEX + 1))
        fi
    elif [[ ${COMMAND} == "" ]]; then 
        # on pourrait avoir des commandes dans un tableau de même taille : ${MENU_COMMANDS[$INDEX]}
        echo "Lancement de ${MENU[$INDEX]}"
        sleep 2
    fi
}

clear
while :; do
    print_title
    print_menu
    read_input
    clear
done