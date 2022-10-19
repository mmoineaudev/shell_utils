#!/bin/bash
############################################################################################
# prérequis : chmod + x A.K.T.sh
# Lancement : ./A.K.T.sh
# Script utilitaire à destination des intégrateurs, acteurs de la supervisions et gestion des envs
# Wiki confluence : https://confluence.constellation.soprasteria.com/pages/viewpage.action?pageId=434540360
# Mode facile : déployez le script sur le serveur ou vous voulez effectuer les actions
# Mode moins facile mais plus rapide : utilisez les commandes ssh pour naviguer dans la plateforme
#
# NB : utilisez au maximum les copier coller lors de l'execution de ce script (surlignage pour copier, clic
#      droit pour coller) afin de minimiser les erreurs de saisies et augmenter le conffort et la vitesse d'utilisation
#
# Ce script doit dans certains cas être lancé en sudo pour pouvoir agir sur certaines parties du système
# ma suggestion est de le lancer en normal, et si des erreurs de droits apparaissent, relancer en sudo
#
# Vous pouvez également consulter : http://cnp69ginintegv2dev.giin.recouv/cch/outilsSDIT/php/infra.php
# ce site contient des outils réalisés côté acoss
#
# Visualiser les alertes (notamment disque) nagios : http://cnp69ginintegv2dev.giin.recouv/cch/outilsSDIT/index.php http://cnp69ginintegv2dev.giin.recouv/cch/nagios_summary/nagios_summary.htm
############################################################################################
# Todolist
#
# [PRIORITE 3]
# Enlever la réplication des bases -> pas trouvé de solution évidente dans les 300+ règles hawai
# UPDATE : procedure reprise:
# Désinstallation du streaming entre les BDD, sur le master :
# -> hawai open_os_hawai clean_streaming
# sur le slave :
# -> hawai open_os_hawai clean_streaming
# redémarrage de Postgres (sur le master+ le slave)
# -> service postgresql start
# creation base vide sur le sgbd master + slave 
# -> hawai open_os_hawai cfe_empty_base
############################################################################################
# 
# Boite à idée #############################################################################
# iconv -f from -t to # conversions de formats
# df -i # pour les inodes, un peu overkill
############################### Paramètres #################################################
# On met les paramètres du script dans une fonction, la bonne pratique serait sans doute
# de séparer les fonctions utilitaires, "métier" et les paramètres dans des fichiers différents,
# mais ça empêcherait les devs notepad de lire le script facilement
doc() {
    ## Ne fait rien, permet juste aux commentaires souhaités d'apparaîte dans les commandes lancées en no_run
    unused=
}
init() {
    set echo-control-characters off
    doc '######################### ( à faire évoluer en fonction des besoins ) ######################'
    export HAWAI_LOGS_AGENTS='/hawai/logs/agents/'
    export CACHE_YUM='/var/cache/yum/'
    export CRON_D='/etc/cron.d/*'
    export SQL_APPLICATIVE_SCRIPTS='/hawai/composants/*/bases/*/sql/'
    export HWI_INSTALL='/hawai/system/hwi_install'
    export APPLICATION_PROPERTIES="${HWI_INSTALL}/applications/"
    export HAWAI_PROPS='/hawai/system/config/hawai.properties'

    # ne surtout pas supprimer cette propertie essentielle
    export A_DEJA_PRIS_UN_CAFE=0
    # Paramètres d'affichage ################################## https://misc.flogisoft.com/bash/tip_colors_and_formatting
    export RAZ_STYLE="\e[0m"
    export BLUE_STYLE="\e[0;49;96m"
    export PURPLE_STYLE="\e[1;40;35m"
    export RED_STYLE="\e[91m"
    export GREEN_STYLE="\e[38;5;82m"
    export UDERLINE_STYLE="\e[4m"
    export PROMPT_STYLE="\e[0;49;92m"
    export B_and_N_STYLE="\e[30mBlack\e[107m"
    export ORANGE_STYLE="\e[0;40;93m"
    # benef
    export selected_log=
}

################################ FONCTIONS ##################################################
######################### ( ne pas changer l'ordre ) ########################################
# C'est un langage interprété, pour se servir d'une fonction il faut qu'elle soit écrite plus
# haut, du coup la partie intéressante est tout en bas de ce script
#############################################################################################

no_run() {
    ##Permet d'affichier l'implémentation d'une fonction shell
    FUNTION_NAME=$1
    # On met en noir sur blanc pour.... pouvoir copier coller dans teams/mails et autres joyeuses microsofteries
    echo -ne "${B_and_N_STYLE}"
    type $FUNTION_NAME
    echo -e ${RAZ_STYLE}
}

wait_for_user_confirmation() {
    OK=
    read OK
}

print_separator() {
    ## Affiche un séparateur
    echo -e "  ${UDERLINE_STYLE}                                                ${RAZ_STYLE}"
    echo
}

print_title() {
    ## Affiche un titre, prends le titre en paramètre
    print_separator
    echo -e " ${PROMPT_STYLE}         $1         $RAZ_STYLE "
    print_separator
}
display_warning_if_root() {
    itIsNotWhoYouAreThatCountsItIsWhatYouCouldBe=$(whoami)
    if [[ $itIsNotWhoYouAreThatCountsItIsWhatYouCouldBe == "root" ]]; then
        print_title " $RED_STYLE /!\\ ${RAZ_STYLE} Ce script dispose des droits super utilisateur $RED_STYLE /!\\ ${RAZ_STYLE} "
    fi
}
# Fonctions utilitaires

# ah, j'avais oublié de l'ajouter celle là... Un peu tard
# Mais ça laisse l'opportunité de faire de la qualimétrie plus tard
print() {
    echo -e "${PROMPT_STYLE} $1 ${RAZ_STYLE}"
}
print_no_newline() {
    echo -ne "${PROMPT_STYLE} $1 ${RAZ_STYLE}"
}
# pour normaliser l'affichage menu, prends deux paramètres, le numéro de l'item, et le label
print_menu_item() {
    if [[ $2 ]]; then 
        echo -e "${ORANGE_STYLE} $1 \t ${BLUE_STYLE} -->  $2 ${RAZ_STYLE}"
    else 
        echo -e "${ORANGE_STYLE} --> $1 ${RAZ_STYLE}"
    fi
}

exit_ok() {
    doc "pour quitter le script"
    echo "Bonne journée !"
    exit 0
}

print_again() {
    doc "pour réafficher le menu"
    print "Appuyez sur entrée "
    PROMPT_AGAIN=
    read PROMPT_AGAIN
    if [[ $PROMPT_AGAIN ]]; then
        # un shortcut pour les connaisseurs, si on appuie sur une touche avant "entrée" ça nettoie l'écran, mais ça marche pas avec espace
        clear
    fi
}
get_installed_apps() {
    doc "Récupère et affiche les rpm qui matchent 'hawai-apps-' ainsi que les dates d'installation"
    sudo rpm -qa | grep -i hawai-apps- | while read package; do rpm -qi $package | head -n 4; done
}
ready_steady_go() {
    doc "Phrase random qui s'affiche au lancement du script"
    messages_pour_la_posterite=("${ORANGE_STYLE}    - Valeur agile : Il vaut mieux accorder de l'importance aux individus et leurs interactions plutôt qu'aux processus et aux outils ; ${RAZ_STYLE}" "${ORANGE_STYLE}    - Valeur agile : Il vaut mieux accorder de l'importance à un logiciel fonctionnel plutôt qu'à une documentation exhaustive ; ${RAZ_STYLE}" "${ORANGE_STYLE}    - Valeur agile : Il vaut mieux accorder de l'importance à la collaboration avec les clients plutôt qu'à la négociation contractuelle ; ${RAZ_STYLE}" "${ORANGE_STYLE}    - Valeur agile : Il vaut mieux accorder de l'importance à l'adaptation au changement plutôt qu'à l'exécution d'un plan. ${RAZ_STYLE}" "${ORANGE_STYLE}    - Principe agile : Notre plus haute priorité est de satisfaire le client en livrant rapidement et régulièrement des fonctionnalités à grande valeur ajoutée. ${RAZ_STYLE}" "${ORANGE_STYLE}    - Principe agile : Accueillez positivement les changements de besoins, même tard dans le projet. Les processus Agiles exploitent le changement pour donner un avantage compétitif au client. ${RAZ_STYLE}" "${ORANGE_STYLE}    - Principe agile : Livrez fréquemment un logiciel fonctionnel, dans des cycles de quelques semaines à quelques mois, avec une préférence pour les plus courts. ${RAZ_STYLE}" "${ORANGE_STYLE}    - Principe agile : Les utilisateurs ou leurs représentants et les développeurs doivent travailler ensemble quotidiennement tout au long du projet. ${RAZ_STYLE}" "${ORANGE_STYLE}    - Principe agile : Réalisez les projets avec des personnes motivées. Fournissez-leur l'environnement et le soutien dont elles ont besoin et faites-leur confiance pour atteindre les objectifs fixés. ${RAZ_STYLE}" "${ORANGE_STYLE}    - Principe agile : La méthode la plus simple et la plus efficace pour transmettre de l'information à l'équipe de développement et à l'intérieur de celle-ci est le dialogue en face à face. ${RAZ_STYLE}" "${ORANGE_STYLE}    - Principe agile : Un logiciel fonctionnel est la principale mesure de progression d'un projet. ${RAZ_STYLE}" "${ORANGE_STYLE}    - Principe agile : Les processus agiles encouragent un rythme de développement soutenable. Ensemble, les commanditaires, les développeurs et les utilisateurs devraient être capables de maintenir indéfiniment un rythme constant. ${RAZ_STYLE}" "${ORANGE_STYLE}    - Principe agile : Une attention continue à l'excellence technique et à un bon design. ${RAZ_STYLE}" "${ORANGE_STYLE}    - Principe agile : La simplicité - c'est-à-dire l'art de minimiser la quantité de travail inutile – est essentielle. ${RAZ_STYLE}" "${ORANGE_STYLE}    - Principe agile : Les meilleures architectures, spécifications et conceptions émergent d'équipes auto-organisées. ${RAZ_STYLE}" "${ORANGE_STYLE}    - Principe agile : À intervalles réguliers, l'équipe réfléchit aux moyens possibles de devenir plus efficace. Puis elle s'adapte et modifie son fonctionnement en conséquence. ${RAZ_STYLE}" "${ORANGE_STYLE}    - Word est un logiciel très lourd et peu adapté à de la documentation technique. Powerpoint, OneNote et Paint non plus.  ${RAZ_STYLE}" "${ORANGE_STYLE}    - Une équipe avec des contraintes de planning et des obligations de résultat ne peut PAS se permettre de ne pas prendre le temps d'en gagner. ${RAZ_STYLE}" "${ORANGE_STYLE}    - Travaillez à être fiers de ce que vous faites. ${RAZ_STYLE}" "${ORANGE_STYLE}    - Hâtez-vous lentement, et, sans perdre courage, Vingt fois sur le métier remettez votre ouvrage : Polissez-le sans cesse et le repolissez ; Ajoutez quelquefois, et souvent effacez. - Nicolas Boileau${RAZ_STYLE}" "${ORANGE_STYLE}    - \"On a toujours fait comme ça\" est une phrase dangereuse et non recevable, qui peut empêcher une civilisation de sortir du moyen-âge. ${RAZ_STYLE}" "${ORANGE_STYLE}    - Prenez du recul, cherchez des redondances, des actions inutiles, parlez-en, la fatigue et l'ennui ne sont pas des états d'esprit productifs. ${RAZ_STYLE}" "${ORANGE_STYLE}    - Un processus n'a de sens que s'il est remis en question, adapté à son contexte, et apporte une valeur ajoutée. ${RAZ_STYLE}" "${ORANGE_STYLE}    - Avant de lancer toute commande, tout script, vérifiez les encodings... Windows est partout, ses utilisateurs nombreux, et ils font planter des serveurs depuis 20 ans. ${RAZ_STYLE}" "${ORANGE_STYLE}    - Ne confiez pas à un humain le travail d'une machine - Agent Smith, Matrix I ${RAZ_STYLE}" "${ORANGE_STYLE}    - Cherchez des objectifs plus nobles et valorisants que la seule complétude des tâches... Pensez à l'humain, la planète, le futur, votre santé et celle des autres. ${RAZ_STYLE}" "${ORANGE_STYLE}    - Quoi qu'il arrive, on ne peut pas attaquer une personne sur son travail, on peut au mieux tenter de comprendre ses contraintes. ${RAZ_STYLE}" "${ORANGE_STYLE}    - Les vraies innovations proviennent du croisement de sujets distincts. Toute personne est suceptible d'avoir une solution meilleure que toutes les autres, peu importe son métier. ${RAZ_STYLE}" "${ORANGE_STYLE}    - La résistance au changement est un phénomène sociologique qui a déjà tué énormément de personnes, d'organisations, de sociétés. ${RAZ_STYLE}" "${ORANGE_STYLE}    - C'est au pied du mur qu'on voit le mieux le mur. ${RAZ_STYLE}" "${ORANGE_STYLE}    - Il vaut mieux une vraie croyante qu'une fausse septique. ${RAZ_STYLE}" "${ORANGE_STYLE}    - Les moulins... C'était mieux à vent. ${RAZ_STYLE}" "${ORANGE_STYLE}    - Le jour où Microsoft vendra quelque chose qui ne plante pas, ça sera sûrement un clou. ${RAZ_STYLE}" "${ORANGE_STYLE}    - Si le ski alpin, qui a le beurre et la confiture ? ${RAZ_STYLE}" "${ORANGE_STYLE}    - Si Gibraltar est un détroit, qui sont les deux autres ? ${RAZ_STYLE}" "${ORANGE_STYLE}    - L'expérience est l'addition de nos erreurs. ${RAZ_STYLE}" "${ORANGE_STYLE}    - On est pas là pour être ici ${RAZ_STYLE}" "${ORANGE_STYLE}    - $(date) ? C'est l'heure de la petite sieste avant d'aller dormir... ${RAZ_STYLE}" "${RED_STYLE}    - Avez-vous rempli votre suivi ? ${RAZ_STYLE}" "${ORANGE_STYLE}    - Avez-vous essayé de redémarrer la box ? ${RAZ_STYLE}" "${ORANGE_STYLE}    - Non, $0 ne peut pas réparer votre imprimante. ${RAZ_STYLE}" "${ORANGE_STYLE}    - ...${RAZ_STYLE}" "${ORANGE_STYLE}    - Tester c'est douter${RAZ_STYLE}" "${ORANGE_STYLE}    - Corriger c'est capituler${RAZ_STYLE}" "${ORANGE_STYLE}    - Pas d'accès, pas d'action.${RAZ_STYLE}")
    echo -e ${messages_pour_la_posterite[$(($RANDOM % ${#messages_pour_la_posterite[@]}))]}
}

# Fonctions de monitoring ##################################

htop_but_custom_and_usable_in_ssh() {
    doc "un htop utilisable sur tout environnement, mais... pas dynamique"
    print_title "RAM disponible [$(cat /proc/meminfo | head -n 2)]"
    doc "le retour de la commande s'autoignore"
    sudo ps -eo "%U %t %C %p %x %c %a" --forest | egrep -v "(bash -c init|$0)"
}

multi_folder_display_weight_and_sort_by_update_date() {
    doc "Affiche le poids et date de modification des fichiers"
    echo "Vous pouvez lister autant d'arborescences que vous souhaitez séparées par un espace"
    print "Arborescence(s)/fichier(s) :"
    read TO_BE_SEARCHED
    ls -lath ${TO_BE_SEARCHED}
}

global_disk_use() {
    doc "Affiche l'état des partitions"
    df -hP
}

private_method_find_biggest_files_under_path() {
    doc "Liste les N plus grands fichiers d une arborescence, récursivement"
    ROOT_PATH=$1
    LIMIT=$2
    du -ah ${ROOT_PATH} | grep -v "/$" | sort -rh | head -n ${LIMIT}
}

public_method_display_biggest_files_under_path() {
    doc "Appelle private_method_find_biggest_files_under_path avec des paramètres saisis par l'utilisateur"
    echo -ne "${PROMPT_STYLE} Quelle arborescence souhaitez-vous observer : ${RAZ_STYLE}"
    ROOT_PATH=
    read ROOT_PATH
    echo -ne "${PROMPT_STYLE} Combien de résultat max : ${RAZ_STYLE}"
    LIMIT=
    read LIMIT
    private_method_find_biggest_files_under_path ${ROOT_PATH} ${LIMIT}
}

look_for_lost_dumps_and_temp_files() {
    doc "Cherche le système dans la mesure des droits disponibles pour faire remonter des extensions de fichiers temporaires"
    nommages_recherches="(dump|save|temp|old|wip)"
    print_title "Recherche des fichiers dont le nom contient ${nommages_recherches}"

    print_menu_item " Arborescence /hawai/ : "
    private_method_find_biggest_files_under_path "/hawai/" 1000 | egrep -i ${nommages_recherches}
    print_menu_item " Arborescence /home/ : "
    private_method_find_biggest_files_under_path "/home/" 1000 | egrep -i ${nommages_recherches}
    print_menu_item " Arborescence /tmp/ : "
    private_method_find_biggest_files_under_path "/tmp/" 1000 | egrep -i ${nommages_recherches}

}

display_yum_cache() {
    doc "liste le cache yum qui contient les derniers rpm téléchargés : il peut vite faire déborder sa partition si trop de rpm sont installés"
    doc "on affiche que les rpm car ce sont normalement les plus lourds"
    doc "on peut néamoins appeler public_method_display_biggest_files_under_path pour vérifier cette arborescence"
    print_separator
    for cacheYumDir in $(ls $CACHE_YUM); do
        echo -e "${BLUE_STYLE} ${CACHE_YUM}${cacheYumDir} $(ls -lathR ${CACHE_YUM}${cacheYumDir} | grep rpm | wc -l) 'fichier(s)' ${RAZ_STYLE}"
        ls -R ${CACHE_YUM}${cacheYumDir} | grep rpm | sort
        print_separator
    done
}
coffee() {
    doc "cette fonction est absolument essentielle au fonctionnement de la solution"
    if [[ $A_DEJA_PRIS_UN_CAFE == '1' ]]; then
        echo -e "${RED_STYLE}[FATAL]${RAZ_STYLE} : un mail vient d'être envoyé au pilotage."
        sleep 3
        echo -e "${RED_STYLE}Posez ce café tout de suite.${RAZ_STYLE}"
        A_DEJA_PRIS_UN_CAFE=0 # Dédicace à rayan
    fi
    if [[ $A_DEJA_PRIS_UN_CAFE == '0' ]]; then
        STARTTIME=$(date +%s%N)
        echo "Encore au café ? Bon, d'accord, j'attends là"
        sleep 1
        echo -ne "."
        sleep 1
        echo -ne "."
        sleep 1
        echo -ne "."
        echo
        echo
        echo
        echo -e "${BLUE_STYLE}"
        echo '         _nnnn_'
        echo '        dGGGGMMb'
        echo '       @p~qp~~qMb'
        echo -e "       M|${ORANGE_STYLE}@${BLUE_STYLE}||${ORANGE_STYLE}@${BLUE_STYLE}) M|"
        echo '       @,----.JM|'
        echo -e "      JS^${ORANGE_STYLE}\\__/${BLUE_STYLE}  qKL"
        echo '     dZP        qKRb'
        echo '    dZP          qKKb'
        echo '   fZP            SMMb'
        echo '   HZM            MMMM'
        echo '   FqM            MMMM'
        echo ' __| ".        |\dS"qML'
        echo ' |    `.       | `  \Zq'
        echo '_)      \.___.,|     .`'
        echo '\____   )MMMMMP|   .`'
        echo '     `-`       `--`'
        echo -e "${RAZ_STYLE}"
        echo -e "Mais reviens vite !"
        read ok
        ENDTIME=$(date +%s%N)
        DURATION=$(((ENDTIME - STARTTIME) / 1000000000))
        echo "Ce café n'a pris que ${DURATION} secondes... Ré-essayez de battre votre record plus tard !"
        # nous sachons
        A_DEJA_PRIS_UN_CAFE=1
    fi
}

# au final ca n'est pas un script, juste une documentation 
# un genre de tutoriel interactif
how_to_import_hawai_dump() {
    doc "ce tutoriel sera peut être scripté un jour, mais n'étant pas à l'aise avec les suppressions de bases automatiques, ça ne sera pas fait par moi"
    print "Ce script est un tutoriel interactif : il ne fait AUCUNE action sur les machines, il donne juste les étapes à suivre et écrit la structure de votre commentaire redmine, dans lequel vous devrez ajouter vos logs d'exécution."
    print "Appuyez sur entrée à chaque fin d'étape pour afficher la suivante."
    print "Saisissez le hostname du serveur moniteur de la plateforme (sans le .giin.recouv) :"
    MONITEUR=
    read -p "Moniteur : " MONITEUR
    print "Saisissez le nom de l'application, qui est normalement aussi le nom de la base (exemple licorn, syncnav ...) :"
    APPLI=
    read -p "Application : " APPLI
    print "Saisissez le nom du fichier dump :"
    DUMPFILE=
    read -p "Fichier dump : " DUMPFILE
    print_separator
    print "h1.  Processus de restoration de dumps en hawai v6"
    echo # sinon ça affiche pas le titre dans redmine
    doc "Dans la pratique le moyen le plus rapide de faire l'action suivante est dans ce script..."
    print "h2.  Dans http://${MONITEUR}.giin.recouv:1000/hwi-services/ : stopper les Apache et Tomcat"
    wait_for_user_confirmation
    print "h2.  Dans http://${MONITEUR}.giin.recouv:1000/hwi-sgbd/ : onglet \"Gestion cluster\", désengager les serveurs esclaves"
    wait_for_user_confirmation
    print "h2.  exécuter la target hawai de suppression de la base : hawai ${APPLI}_empty_base , 'entrée' puis 'n'"
    wait_for_user_confirmation
    print "h2. exécutez les commande suivantes l'une après l'autre : "

    echo -e "${RED_STYLE} /!\\ CES COMMANDES N'AFFICHENT RIEN ET NE FINISSENT JAMAIS SI ON UTILISE UN CHEMIN ABSOLU DANS LE NOM DE DUMP...${RAZ_STYLE}"

    print "<pre>"
    echo -e "${BLUE_STYLE} cd [path] ${RAZ_STYLE}"
    echo -e "${BLUE_STYLE} sudo su ${RAZ_STYLE}"
    print "# Si le dump est de taille modérée :"
    echo -e "${BLUE_STYLE} pg_restore -U postgres -Fc -v -d ${APPLI} ${DUMPFILE} ${RAZ_STYLE}"
    print "# Si le dump est très gros :"
    echo -e "${BLUE_STYLE} nohup pg_restore -U postgres -Fc -v -d ${APPLI} ${DUMPFILE} & ${RAZ_STYLE}"
    print "# Si le dump est sous la forme d'un dossier contenant plusieurs fichiers :"
    echo -e "${BLUE_STYLE} pg_restore -U postgres -v -d ${APPLI} -Fd [dossier] ${RAZ_STYLE}"

    print "# Contrôle du code retour"
    echo -e "${BLUE_STYLE} echo \"CR=[\$?]\" ${RAZ_STYLE}"
    print "</pre>"

    print "Assurez vous de voir apparaître dans la log des tables, séquences, index et contraintes : "
    echo -e "${RED_STYLE} si une erreur de type 'pg_restore: [custom archiver] could not read from input file: end of file' apparaît, le dump est corrompu et vous devez vous en procurer un autre. ${RAZ_STYLE}"
    wait_for_user_confirmation
    print "h2. Au terme de la manipulation, relancez les serveurs Apache et Tomcat, réengagez les serveurs esclaves"
    print_separator
    print "Fin de la procédure"
}

display_cron_tasks() {
    doc "Affiche les crontask sous ${CRON_D} , fichier par fichier"
    echo "Utilisateur courant : $(whoami)"
    print_separator
    for cronfile in $(ls ${CRON_D}); do
        echo -e "$PROMPT_STYLE ${cronfile} $RAZ_STYLE"
        cat ${cronfile}
        print_separator
    done
}

list_and_cat_app_properties() {
    doc "Permet de lister puis d'affichier un fichier.properties de son choix"
    ls -lathR ${APPLICATION_PROPERTIES}*/*.properties
    print "Choississez un fichier pour l'ouvrir, laisser vide sinon : "
    read -p " --> " ARBORESCENCE_VERS_UN_PROPERTIES
    echo "[cat ${ARBORESCENCE_VERS_UN_PROPERTIES}] :"
    cat ${ARBORESCENCE_VERS_UN_PROPERTIES}
    print_separator
    print "L'URL http://cnp69ginintegv2dev.cer69.recouv/cch/properties_summary/properties_summary.htm permet de consulter les fichiers properties de plusieurs couloirs en même temps"
    # on reset la variable
    NOM_TOKEN=
    # echo -ne "${PROMPT_STYLE}[j'ai jamais réussi à faire marcher ça mais à priori la commande est bonne] Si vous souhaitez savoir quelles target réinstaller en cas de modification d'un token, renseignez ici la clé du token, laisser vide sinon : ${NOM_TOKEN}${RAZ_STYLE}"
    # read ${NOM_TOKEN}
    # if [[ ${NOM_TOKEN} ]]; then
    #     doc "TODO test et eventuellement mise en forme"
    #     token_target --token "${NOM_TOKEN}"
    # fi
}

count_error_debug_warn_fatal_in_agents_logs() {
    doc "comme son nom l'indique"
    EXIT_count_error_debug_warn_fatal_in_agents_logs=
    #find ${HAWAI_LOGS_AGENTS} -type f | xargs -r ls -lath | egrep -v "(.zip|.gz)"
    ########################################################
    print_separator
    EXPLOITABLE_LOGS=( $(find ${HAWAI_LOGS_AGENTS} -type f | egrep -v "(.zip|.gz)" ) ) 
    print_separator
    for EXPLOITABLE_LOG in ${EXPLOITABLE_LOGS[@]}; do
        ls -tlh --color=auto ${EXPLOITABLE_LOG} 
        count_log_occurences_by_log_level ${EXPLOITABLE_LOG}
    done 
    print_separator
    ########################################################
}

list_all_agents_s_logs() {
    doc "Affiche des compteurs sur les logs, et liste tous les fichiers sous ${HAWAI_LOGS_AGENTS}"

    count_error_debug_warn_fatal_in_agents_logs
    
    print "Selectionnez un fichier log pour analyse, vide sinon: "
    selected_log=
    read selected_log
    if [[ $selected_log ]]; then
        print "Entrez un pattern (un|deux|trois) pour rechercher une occurence de mot dans ce log logs, vide sinon: "
        DO_SEARCH=
        read DO_SEARCH
        if [[ $DO_SEARCH ]]; then
            # on remet a vide au cas ou
            egrep --color=always -Ril "${DO_SEARCH}" ${selected_log} | egrep --color=always -rin "${DO_SEARCH}" ${selected_log}
        fi
    fi

    print "Entrez 'y' pour lister tous les fichiers sous ${HAWAI_LOGS_AGENTS}, vide sinon: "
    # on remet a vide au cas ou
    DO_LIST=
    read DO_LIST
    if [[ $DO_LIST ]]; then
        find ${HAWAI_LOGS_AGENTS} -type f | xargs -r ls -lath
        
    fi
    print " Entrez un chemin pour consulter un fichier ou laissez vide : "
    # on remet a vide au cas ou
    LOG_PATH_TO_BE_TAILED=
    read LOG_PATH_TO_BE_TAILED
    if [[ $LOG_PATH_TO_BE_TAILED ]]; then
        ls -lath ${LOG_PATH_TO_BE_TAILED}
        # on remet a vide au cas ou
        HOW_MANY_LINES=
        print " combien de lignes voulez-vous consulter (tail) : "
        read HOW_MANY_LINES
        tail -n ${HOW_MANY_LINES} ${LOG_PATH_TO_BE_TAILED}
        print_separator
    fi
}
create_dump_and_place_it_whereever_you_want() {
    doc "Permet de créer un dump de manière interactive"
    echo "Utilisateur courant : $(whoami)"
    print_title "Vérification des espaces disques :"
    global_disk_use
    print_separator
    psql -U postgres -c \\l 
    print " Renseignez le nom de BASE (exemple licorn): "
    read BASE_NAME
    print " Renseignez un suffixe (numéro de ticket, libelé quelconque, sans espace ni caractères spéciaux), ou laissez vide: "
    read SUFFIXE_DUMP
    echo "Choisissez l'emplacement de création du dump : "
    echo "Chemins féquemment utilisés : /hawai/data/ /hawai/sauvegarde/bases/"
    print " Dossier cible ( /!\\ doit terminer par / ): "
    read TARGET_FOLDER
    print_title "Création d'un dump de la base $BASE_NAME sous $TARGET_FOLDER"
    # le -v est censé être facultatif, on peut l'enlever pour raccourcir le log, mais c'est la seule manière de
    # voir l'avancement et de s'assurer que tout a été traité
    YN=
    print "Lancer la commande [ [...]pg_dump -U postgres ${BASE_NAME} -Fc -v -f ${TARGET_FOLDER}backup_${BASE_NAME}_$(date +"%Y_%m_%d")${SUFFIXE_DUMP}.dump] ? (y/n)"
    read YN
    if [[ $YN == 'y' ]]; then
        print_separator
        /hawai/composants/postgresql/bin/pg_dump -U postgres ${BASE_NAME} -Fc -v -f ${TARGET_FOLDER}backup_${BASE_NAME}_$(date +"%Y_%m_%d")${SUFFIXE_DUMP}.dump
        echo -e "${GREEN_STYLE}CR = [$?]${RAZ_STYLE} ${RED_STYLE}(s'il est a autre chose que 0 le dump est certainement mal formé)${RAZ_STYLE}"
        print_separator
        ls -lath ${TARGET_FOLDER}backup_${BASE_NAME}_*${SUFFIXE_DUMP}.dump
    fi
}

# select_and_delete() {
#     echo "Utilisateur courant : $(whoami)"
#     doc "on valorise a vide pour pouvoir relancer la fonction sans récupérer la condition de sortie du lancement précédent"
#     EXIT_select_and_delete=
#     while [ ! ${EXIT_select_and_delete} ]; do
#         echo -ne "${PROMPT_STYLE} Sélectionner le fichier à supprimer, ou laisser vide : ${RAZ_STYLE}"
#         read FICHIER
#         doc "on confirme que le fichier existe, affiche le poids et la date de modification"
#         ls -lath "$FICHIER"
#         doc "on prévient l'utilisateur qu'on utilise -I et qu'une confirmation explicite sera demandée"
#         echo -e " $RED_STYLE /!\ Entrez 'y' pour confirmer la suppression de $FICHIER $RAZ_STYLE "
#         sudo rm -rfi $FICHIER
#         doc "on permet la suppression de plusieurs fichiers sans retourner au menu"
#         echo -ne "${PROMPT_STYLE} appuyez sur entrée pour continuer la saisie, ou sur n'importe quelle touche + entrée pour quitter : ${RAZ_STYLE}"
#         read EXIT_select_and_delete
#     done
# }
create_sgbd_hawai_sauvegarde_base_mounting_point() {
    doc "Réutilisation / industrialisation du https://innersource.soprasteria.com/acoss/sdit/sdit_utils/-/blob/master/Shell_utils/InitPointDeMontageNTFSauvegarde.sh "
    # Rappel : ce code est prévu pour les point de montage SGBD qui contiennent les dumps webmin
    if [ $(whoami) != "root" ]; then
        # on lance pas ça en ssh, c'est tout, car ça touche a un serveur sur lequel il y a trop de backup a perdre pour prendre le risque
        echo "$0 doit avoir les droits root, utilisateur actuel $(whoami)"
        exit 2
    fi
    doc "Normes client, ça normalement on ne le touche jamais"
    # au final c'est plus simple de ne pas factoriser les variables, c'est pas très bon pour la maintenabilité,
    # mais si on regarde init(), on se rends compte que les passer en ssh ça demande un peu de compexité...
    # a voir si on remonte toutes les déclarations dans le init par la suite
    CHEMIN_ABSOLU_MONTAGE_TEMPORAIRE=/hawai/montage_temp
    CHEMIN_ABSOLU_MONTAGE_FINAL=/hawai/sauvegarde/bases
    RACINE_DES_BACKUPS=/data/intnat/sauvegardes/sauvegardes_dumps

    print "liste des serveurs \"Cible\" connus du script : "
    echo -e "${BLUE_STYLE} cnp31ginbalance.cer31.recouv ${RAZ_STYLE}"
    echo -e "${BLUE_STYLE} cnp69balance.cer69.recouv ${RAZ_STYLE}"
    print "Renseignez le nom du serveur \"cible\" du point de montage : "
    read NOM_SERVEUR_DISTANT
    if [[ $NOM_SERVEUR_DISTANT == "cnp31ginbalance.cer31.recouv" ]]; then
        ADDR_SERVEUR_DISTANT=10.206.57.39
    elif [[ $NOM_SERVEUR_DISTANT == "cnp69balance.cer69.recouv" ]]; then
        ADDR_SERVEUR_DISTANT=10.203.48.133
    fi
    echo -e "${BLUE_STYLE} L'adresse du serveur distant est ${ADDR_SERVEUR_DISTANT} ${RAZ_STYLE}"
    print "Renseignez le couloir de la plateforme : "
    echo -ne "${BLUE_STYLE} Valeur dans la liste : C01 C02 C03 C04 C05 C06 C07 C08 : ${RAZ_STYLE}"
    read COULOIR
    print "Nom de la plateforme (comme dans superPutty C0? - [ ${RED_STYLE} PLATEFORME ${RAZ_STYLE}${PROMPT_STYLE} ]) "
    read PLATEFORME
    doc "Mini astuce ici, on a besoin du numéro de serveur sgbd, c'est le dernier char du hostname"
    NUM_BDD="bd${var: -1}"
    print "Renseignez le nom de l'application : "
    # En minucule, sans espace en fin, utilisée pour crée la commande `hawai [APPLICATION]_backup_base`
    read APPLICATION
    doc "On remet ce qui doit être en maj en maj et en min en min"
    COULOIR=${COULOIR^^}
    PLATEFORME=${PLATEFORME^^}
    #num bdd ça sert a rien mais c'est de la prog defensive, ça porte l'info que c'est attendu en minuscule, for the future
    NUM_BDD=${NUM_BDD,,}
    APPLICATION=${APPLICATION,,}
    print_title "Relecture des paramètres"
    print_menu_item " COULOIR : ${COULOIR}"
    print_menu_item " PLATEFORME : ${PLATEFORME}"
    print_menu_item " NUM_BDD : ${NUM_BDD}"
    print_menu_item " APPLICATION : ${APPLICATION}"
    # Prérequis
    print_separator
    echo -e "${RED_STYLE} On vérifie que le dossier contenant les dumps générés par la base est vide avant de procéder au montage ${RAZ_STYLE}"
    echo -e "$BLUE_STYLE} ls ${CHEMIN_ABSOLU_MONTAGE_FINAL} : ${RAZ_STYLE}"
    ls ${CHEMIN_ABSOLU_MONTAGE_FINAL}
    echo -ne "${RED_STYLE} Si le dossier contient des dumps, vous devez les déplacer dans une autre session shell. Appuyez sur entrée une fois le ${CHEMIN_ABSOLU_MONTAGE_FINAL} vide. ${RAZ_STYLE} "
    #On remet a 0 au cas ou
    OK=
    read OK
    # Création du montage temporaire : on accède au serveur cible a un point existant plus haut dans l'aborescence
    # comme ça on peut créer l'arborescence du point de montage si elle n'existe pas a partir du temporaire
    # a la fin, on supprimera le temporaire
    print_title "Création d'un point de montage temporaire"
    mkdir -p ${CHEMIN_ABSOLU_MONTAGE_TEMPORAIRE}
    ls ${CHEMIN_ABSOLU_MONTAGE_TEMPORAIRE}
    echo -e "${BLUE_STYLE} Création d'un point de montage vers le serveur distant ${NOM_SERVEUR_DISTANT} : ${RAZ_STYLE}"
    print "Appuyez sur entrée pour exécuter 'mount ${NOM_SERVEUR_DISTANT}:/ ${CHEMIN_ABSOLU_MONTAGE_TEMPORAIRE}' "
    #On remet a 0 au cas ou
    OK=
    read OK
    mount ${NOM_SERVEUR_DISTANT}:/ ${CHEMIN_ABSOLU_MONTAGE_TEMPORAIRE}
    echo -ne "${BLUE_STYLE} Norme d'arborescence attendue [COULOIR]/[PLATEFORME]/[bdx] : ${RAZ_STYLE}"
    ARBORESCENCE=${RACINE_DES_BACKUPS}/${COULOIR}/${PLATEFORME}/${NUM_BDD}
    echo -e "${ARBORESCENCE}"
    print "Appuyez sur entrée pour exécuter 'mkdir -p ${CHEMIN_ABSOLU_MONTAGE_TEMPORAIRE}/${ARBORESCENCE}' "
    #On remet à 0 au cas ou
    OK=
    read OK
    mkdir -p ${CHEMIN_ABSOLU_MONTAGE_TEMPORAIRE}/${ARBORESCENCE}
    ls ${CHEMIN_ABSOLU_MONTAGE_TEMPORAIRE}/${ARBORESCENCE}
    # le fstab est appelé systématiquement au démarage du serveur, et lors de la commande mount -a : on décrit le point de montage dans ce fichier pour le rendre persistant dans le temps
    print_title "Ajout d\'une ligne au /etc/fstab pour permettre le montage automatique "
    echo -e "${B_and_N_STYLE} ${NOM_SERVEUR_DISTANT}:${ARBORESCENCE} ${CHEMIN_ABSOLU_MONTAGE_FINAL} nfs rw,intr,addr=${ADDR_SERVEUR_DISTANT} 0 0 ${RAZ_STYLE}"
    print "Appuyez sur entrée pour ajouter cette ligne au /etc/fstab "
    #On remet à 0 au cas ou
    OK=
    read OK
    echo "${NOM_SERVEUR_DISTANT}:${ARBORESCENCE} ${CHEMIN_ABSOLU_MONTAGE_FINAL} nfs rw,intr,addr=${ADDR_SERVEUR_DISTANT}" 0 0 >>/etc/fstab
    print "Vérifiez le fstab"
    cat /etc/fstab
    print_separator
    print "Appuyez sur entrée pour procéder au montage du ${CHEMIN_ABSOLU_MONTAGE_FINAL} sur ${ARBORESCENCE} "
    echo "mount -a :"
    mount -a
    print "Code retour du montage : $? "
    doc "On supprime le montage temporaire"
    umount ${NOM_SERVEUR_DISTANT}:/ ${CHEMIN_ABSOLU_MONTAGE_TEMPORAIRE}
    rmdir ${CHEMIN_ABSOLU_MONTAGE_TEMPORAIRE}

    print "L'opération est terminée, vous pouvez relancer la rotation des dumps via la commande (non géré par ce script) :"
    echo -e "${B_and_N_STYLE} hawai ${APPLICATION}_backup_base ${RAZ_STYLE}"
}

# note a toute personne qui fait des nommages, si j'avais appelé ça CPAFACSSMAMA ça serait moins clair, la ok, c'est un peu long...
# ... c'est pas grave
check_partitions_and_fstab_and_create_sgbd_save_mountpoint_and_mount_all() {
    doc "Permet de vérifier l'état des partitions, et de relancer mount -a si certaines ne sont pas montées"
    # on vérifie les partitions
    global_disk_use
    echo -ne "${PROMPT_STYLE} Un point de montage est-il manquant ? (y/n)${RAZ_STYLE}"
    YN=
    read YN
    doc "On fait plusieurs confirmations pour être sûr"
    if [[ $YN == 'y' ]]; then
        print_title "cat /etc/fstab"
        doc "On vérifie le fichier qui contient les points de montage normalement chargés au démarrage du serveur"
        cat /etc/fstab
        print_separator
        doc "on remet a 0 YN pour ne pas creer 1000 variables"
        YN=
        echo -e "${RED_STYLE}Si vous répondez 'n' à la question suivante, le script vous proposera de créer le point de montage${RAZ_STYLE}"
        echo -ne "${PROMPT_STYLE} le fstab contient-il le point de montage, correctement renseigné ? (y/n)${RAZ_STYLE}"
        read YN
        if [[ $YN == 'y' ]]; then
            YN=
            echo -ne "${RED_STYLE} Lancer [ mount -a ] ? (y/n)${RAZ_STYLE}"
            read YN
            if [[ $YN == 'y' ]]; then
                mount -a
                doc "On rappelle cette même fonction pour permettre à l'utilisateur de relancer"
                check_partitions_and_fstab_and_create_sgbd_save_mountpoint_and_mount_all
            fi
        fi
        doc "si non on crée le point de montage"
        if [[ $YN == 'n' ]]; then
            YN=
            create_sgbd_hawai_sauvegarde_base_mounting_point
        fi
    else 
        print "Cool, tout va bien alors."
    fi

}

count_log_occurences_by_log_level() {
    doc "Factorisation des compteurs, ça ne fait que compter des lignes et les classer par debug/warn/err
    utile pour certains tests alm : on peut notamment le lancer avant et après une action pour savoir si des 
    erreurs sont apparues ou non sans lire le log"
    logfile=$1
    NB_LINES=$(cat ${logfile} | wc -l)
    NB_DEBUG=
    NB_WARN=
    NB_ERR=
    NB_FATAL=
    NB_GRAVE=
    if [[ ${NB_LINES} -gt 0 ]]; then
        echo -ne "${PROMPT_STYLE} Nombre de lignes : ${NB_LINES}"
        NB_DEBUG=$(cat ${logfile} | grep -i "debug" | wc -l)
        if [[ ${NB_DEBUG} -gt 0 ]]; then
            echo -ne "${PROMPT_STYLE} debug : ${NB_DEBUG}"
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


display_plateforme_accessibles_ip() {
    doc "permet d'accéder aux logs apache et tomcat s'ils existent, et de remonter les lignes en erreur ou de les tail -f (et de redémarrer les services ?)"
    # certains appels ssh sont en erreur : on ne s'intéresse qu'à ceux qu'on peut accéder
    HOSTNAME=$(ssh hawai@$1 hostname 2>/dev/null)
    if [[ $HOSTNAME ]]; then
        IP="$1"

        # Colonne 1 IP
        echo -ne "  "
        echo -ne "${PROMPT_STYLE} "
        echo -ne $IP
        echo -ne ${RAZ_STYLE}
        echo -ne "  |  "
        # colonne 2 hostname complet
        echo -ne "${B_and_N_STYLE} "
        echo -ne ${HOSTNAME}
        echo -ne " ${RAZ_STYLE}"
        echo
    fi
}
tail_apache_and_tomcat_logs() {
    doc "Renverra des erreurs pour les serveurs qui n'ont pas de apache ou de tomcat, mais fondamentalement on veut pouvoir lancer la commande sur n'importe quel serveur"
    # Ces path là ne sont pas exportés parce qu'ils ne servent qu'ici, et pour pas polluer plus l'import des fonctions via ssh
    APACHE_ACCESS='/hawai/logs/apache/access.log'
    APACHE_ERROR='/hawai/logs/apache/error.log'
    TOMCAT_CATALINA='/hawai/logs/tomcat/logs/catalina.out'
    print_separator
    echo -e "$BLUE_STYLE $APACHE_ACCESS $RAZ_STYLE"
    if [[ $(ls $APACHE_ACCESS | wc -l) -ne 0 ]]; then
        echo -ne "${PROMPT_STYLE} # Combien de lignes du log ${APACHE_ACCESS} souhaitez-vous afficher ?${RAZ_STYLE}"
        read TAIL_N_APACHE_ACCESS
        tail -n ${TAIL_N_APACHE_ACCESS} $APACHE_ACCESS
        count_log_occurences_by_log_level $APACHE_ACCESS
    fi
    print_separator
    echo -e "$BLUE_STYLE $TOMCAT_CATALINA $RAZ_STYLE"
    if [[ $(ls $TOMCAT_CATALINA | wc -l) -ne 0 ]]; then
        echo -ne "${PROMPT_STYLE} # Combien de lignes du log ${TOMCAT_CATALINA} souhaitez-vous afficher ?${RAZ_STYLE}"
        read TAIL_N_TOMCAT_CATALINA
        tail -n ${TAIL_N_TOMCAT_CATALINA} $TOMCAT_CATALINA
        count_log_occurences_by_log_level $TOMCAT_CATALINA
    fi
    print_separator
    echo -e "$BLUE_STYLE $APACHE_ERROR $RAZ_STYLE"
    if [[ $(ls $APACHE_ERROR | wc -l) -ne 0 ]]; then
        echo -ne "${PROMPT_STYLE} # Combien de lignes du log ${APACHE_ERROR} souhaitez-vous afficher ?${RAZ_STYLE}"
        read TAIL_N_APACHE_ERROR
        tail -n ${TAIL_N_APACHE_ERROR} $APACHE_ERROR
        count_log_occurences_by_log_level $APACHE_ERROR
    fi
}

stop_apache() {
    sudo service httpd stop
    sudo service httpd status
}
stop_tomcat() {
    sudo service tomcat stop
    sudo service tomcat status
}
stop_and_clean_tomcat() {
    sudo service tomcat stopandclean
    sudo service tomcat status
}
start_apache() {
    doc "si vous mettez 'log' en paramètre ça permet de tail les logs des serveurs web"
    sudo service httpd start
    sudo service httpd status
    if [[ $1 == "log" ]]; then
        tail_apache_and_tomcat_logs    
    fi
}
start_tomcat() {
    doc "si vous mettez 'log' en paramètre ça permet de tail les logs des serveurs web"
    sudo service tomcat start
    sudo service tomcat status
    if [[ $1 == "log" ]]; then
        tail_apache_and_tomcat_logs    
    fi
}
frequent_sql_request(){
    doc "A alimenter avec des requetes sql fréquentes"
    #print_menu_item "Label fonctionnel" "requête;"
    #print_menu_item "Monitoring de session" "SELECT * || ' sessions ouvertes ' as nb_sessions_ouvertes FROM pg_stat_activity;"
}

connect_psql() {
    doc "Permet de se connecter en bdd"
    doc "on vérifie quand même que on est sur un serveur bdd"
    psql -U postgres -c "SELECT count(*) || ' sessions ouvertes ' as nb_sessions_ouvertes FROM pg_stat_activity;"  
    psql -V
    print "Saisissez un nom d'utilisateur (postgres, ou user applicatif) : "
    read user_name
    echo -ne "${BLUE_STYLE}"
    print_separator
    echo -ne "${BLUE_STYLE}"
    psql -U ${user_name} -c '\l'
    print_separator
    echo -ne "${RAZ_STYLE}"
    print "Saisissez un nom de base, ou laissez vide : "
    read bdd_name
    SUFFIXE=
    if [[ $bdd_name ]]; then
        SUFFIXE="-d ${bdd_name}"
    fi
    print "Rappel des commandes postgres : "
    print_menu_item 'Connexion à une bdd              :' '\\c dbname [username]'
    print_menu_item 'Lister les bdd                   :' '\l  '
    print_menu_item 'Lister les schémas               :' '\dn  '
    print_menu_item 'Lister les tables                :' '\dt ou "SELECT table_name FROM information_schema;"'
    print_menu_item 'Décrire la structure d une table :' '\d table '
    print_menu_item 'historique des commandes         :' '\s  '
    print_menu_item 'formatage (just do it plz)       :' '\x (...sinon les résultats de requêtes sont ILLISIBLES)'
    print "Appuyez sur entrée pour vous connecter en BDD"
    frequent_sql_request
    psql -U ${user_name} ${SUFFIXE}
    echo -e "${RAZ_STYLE}"
}

send_file_via_scp() {
    doc "Petit guide pour envoyer un fichier"
    print_title "Envoyer un fichier depuis $(hostname) via SCP (ssh) vers un serveur distant"
    echo -ne "${PROMPT_STYLE} Entrez le chemin absolu du fichier/dossier DESTINATION (exemple /home/hawai):${RAZ_STYLE}"
    remote_folder=
    read remote_folder
    echo -ne "${PROMPT_STYLE} Entrez l'IP ou le nom de domaine du serveur DESTINATION (exemple carbone.cve.recouv):${RAZ_STYLE}"
    remote_host=
    read remote_host
    echo -ne "${PROMPT_STYLE} Entrez l'username du serveur DESTINATION (exemple CNP):${RAZ_STYLE}"
    username=
    read username
    echo -ne "${PROMPT_STYLE} Entrez le chemin absolu du fichier/dossier à envoyer (exemple /home/hawai/dumps):${RAZ_STYLE}"
    LOCAL_FILE_OR_FOLDER=
    read LOCAL_FILE_OR_FOLDER
    echo -e "${PROMPT_STYLE} Appuyez sur entrée pour lancer la commande : ${RAZ_STYLE}"
    read -p "scp -r ${LOCAL_FILE_OR_FOLDER} ${username}@${remote_host}:${remote_folder}" ok
    scp -r ${LOCAL_FILE_OR_FOLDER} ${username}@${remote_host}:${remote_folder}
    echo -e "${PROMPT_STYLE} CR=$? ${RAZ_STYLE}"
}
get_file_via_scp() {
    doc "Petit guide pour récupérer un fichier"
    print_title "Récupérer un fichier d'un serveur distant vers $(hostname) via SCP (ssh)"
    echo -ne "${PROMPT_STYLE} Entrez l'IP ou le nom de domaine du serveur SOURCE (exemple carbone.cve.recouv):${RAZ_STYLE}"
    remote_host=
    read remote_host
    echo -ne "${PROMPT_STYLE} Entrez le chemin absolu du fichier/dossier dans ${remote_host} (exemple /home/hawai):${RAZ_STYLE}"
    remote_folder=
    read remote_folder
    echo -ne "${PROMPT_STYLE} Entrez l'username du serveur ${remote_host} (exemple CNP):${RAZ_STYLE}"
    username=
    read username
    echo -ne "${PROMPT_STYLE} Entrez le chemin absolu du fichier/dossier DESTINATION dans $(hostname) (exemple /home/hawai/dumps):${RAZ_STYLE}"
    LOCAL_FILE_OR_FOLDER=
    read LOCAL_FILE_OR_FOLDER
    echo -e "${PROMPT_STYLE} Appuyez sur entrée pour lancer la commande : ${RAZ_STYLE}"
    read -p "scp -r ${username}@${remote_host}:${remote_folder} ${LOCAL_FILE_OR_FOLDER}" ok
    scp -r ${username}@${remote_host}:${remote_folder} ${LOCAL_FILE_OR_FOLDER}
    echo -e "${PROMPT_STYLE} CR=$? ${RAZ_STYLE}"
}

find_word_in_files() {
    doc "Cherche des occurences de mots dans toute l'arborescence souhaitée"
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

verify_line_termination_and_formats() {
    # Christophe was here
    FILES_EXTENSIONS_TO_BE_CHECKED='.sh|.sql'
    print "Saisissez une arborescence dans laquelle vérifier les encodings des ${FILES_EXTENSIONS_TO_BE_CHECKED}"
    read ARBORESCENCE_SOUHAITEE
    doc "on met tout en sudo car on veut tout voir"
    sudo find ${ARBORESCENCE_SOUHAITEE} -exec file {} \; | sudo grep "CRLF" | sudo egrep ${FILES_EXTENSIONS_TO_BE_CHECKED}
}

verify_line_termination_and_formats_alm() {
    # Christophe was here
    doc "fait partie de la campagne de conformité, check le ${HWI_INSTALL}"
    find ${HWI_INSTALL} -exec file {} \; |grep "CRLF" |egrep '.sh|.sql'
}

export_all_funtions_ssh() {
    doc "Il y a pas de bonnes ou de mauvaises solution, la bonne on la fait elle marche, la mauvaise, on la fait,... elle marche quoi, mais c'est pas pareil
    plus sérieusement, pour que la solution tienne en un seul fichier on doit lister manuellement les noms de fonctions a mettre a disposition des serveurs atteints en ssh
    on ne peut pas copier le fichier entier car ca exécuterait la boucle... Tout mettre là a au moins le mérite d'être explicite"
    echo "$(typeset -f init)
$(typeset -f no_run)
$(typeset -f doc)
$(typeset -f print_separator)
$(typeset -f count_log_occurences_by_log_level)
$(typeset -f print_title)
$(typeset -f ready_steady_go)
$(typeset -f display_warning_if_root)
$(typeset -f exit_ok)
$(typeset -f print_again)
$(typeset -f print)
$(typeset -f htop_but_custom_and_usable_in_ssh)
$(typeset -f multi_folder_display_weight_and_sort_by_update_date)
$(typeset -f global_disk_use)
$(typeset -f send_file_via_scp)
$(typeset -f get_file_via_scp)
$(typeset -f private_method_find_biggest_files_under_path)
$(typeset -f public_method_display_biggest_files_under_path)
$(typeset -f get_installed_apps)
$(typeset -f look_for_lost_dumps_and_temp_files)
$(typeset -f display_yum_cache)
$(typeset -f coffee)
$(typeset -f display_cron_tasks)
$(typeset -f list_and_cat_app_properties)
$(typeset -f list_all_agents_s_logs)
$(typeset -f create_dump_and_place_it_whereever_you_want)
$(typeset -f stop_apache)
$(typeset -f print_menu_item)
$(typeset -f connect_psql)
$(typeset -f stop_tomcat)
$(typeset -f stop_and_clean_tomcat)
$(typeset -f start_apache)
$(typeset -f start_tomcat)
$(typeset -f find_word_in_files)
$(typeset -f create_sgbd_hawai_sauvegarde_base_mounting_point)
$(typeset -f check_partitions_and_fstab_and_create_sgbd_save_mountpoint_and_mount_all)
$(typeset -f count_error_debug_warn_fatal_in_agents_logs)
$(typeset -f display_plateforme_accessibles_ip)
$(typeset -f verify_line_termination_and_formats_alm)
$(typeset -f verify_line_termination_and_formats)
$(typeset -f tail_apache_and_tomcat_logs)"
}
ssh_menu_display() ( # c'est pour la nested function qu'on mets des () ( code ), ça fait un sous shell
    # c'est fou
    doc "Affiche les commandes qu'on veut explicitement mettre à disposition en ssh"
    VERBOSE_OFF=$1
    # nested function en shell 
    inner_print_menu_item() {
        # si c'est vide, on affiche les descriptions
        if [[ -z $VERBOSE_OFF ]]; then # si la verbose n'est pas off
            echo -e "${BLUE_STYLE} [ # ${ORANGE_STYLE} $1 \n\t${BLUE_STYLE} $2 ] ${RAZ_STYLE}"
        else # sinon la version courte 
            echo -e "${ORANGE_STYLE} --> $1 ${RAZ_STYLE}"
        fi
    }
    doc "Options de noms de fonctions, on les récupère dynamiquement dans le script pour les pousser dans le bash récepteur de la commande ssh
        On peut utiliser même celles qui ne sont pas dans cette liste, cf export_all_funtions_ssh"
    print_title "Fonctions disponibles en ssh :"
    inner_print_menu_item "check_partitions_and_fstab_and_create_sgbd_save_mountpoint_and_mount_all " " Vérifie que les points de montage sont positionnés et montés, permet de les relancer si besoin, spoiler si vous essayez en shh de créer un point de montage ça marchera pas, pour raison de sécurité"
    inner_print_menu_item "connect_psql ${RAZ_STYLE} $RED_STYLE Se connecter en base, un peu overkill en ssh"
    inner_print_menu_item "count_error_debug_warn_fatal_in_agents_logs " " Affiche les logs, compte les occurence des niveaux de log sur le fichier de votre choix"
    inner_print_menu_item "count_log_occurences_by_log_level " " Prends en paramètre un log, compte les occurences par niveau de log"
    inner_print_menu_item "create_dump_and_place_it_whereever_you_want " " Créée un dump, le place où vous voulez"
    inner_print_menu_item "display_cron_tasks " " Consulter les crontask"
    inner_print_menu_item "display_yum_cache " " Vérifier le cache yum"
    inner_print_menu_item "find_word_in_files " " Cherche un mot dans une arborescence de fichier"
    inner_print_menu_item "get_file_via_scp " " Recevoir un fichier/dossier via SCP"
    inner_print_menu_item "get_installed_apps " " Permet d'avoir des informations sur les rpm livrés installés"
    inner_print_menu_item "global_disk_use " " Afficher l'usage du disque et les partitions"
    inner_print_menu_item "htop_but_custom_and_usable_in_ssh  " " Visualiser les processus"
    inner_print_menu_item "list_all_agents_s_logs " " Liste les logs des agents"
    inner_print_menu_item "list_and_cat_app_properties " " Liste les [appli].properties et permet de cat celui qu'on veut"
    inner_print_menu_item "look_for_lost_dumps_and_temp_files " " Retrouve les fichiers temporaires & dumps sous /hawai"
    inner_print_menu_item "multi_folder_display_weight_and_sort_by_update_date " " Consulter la date de modification d'un ou plusieurs fichiers"
    inner_print_menu_item "public_method_display_biggest_files_under_path " " Afficher les N plus gros fichiers sous l'arborescence souhaitée"
    inner_print_menu_item "send_file_via_scp " " Envoyer un fichier/dossier via SCP"
    inner_print_menu_item "start_apache [log] #pour afficher les logs " " Démarre un serveur apache s'il est présent sur la machine"
    inner_print_menu_item "start_tomcat [log] #pour afficher les logs " " Démarre un serveur tomcat s'il est présent sur la machine"
    inner_print_menu_item "stop_and_clean_tomcat " " Stop & clean un tomcat (et affiche les logs)"
    inner_print_menu_item "stop_apache " " Stoppe un apache (et affiche les logs)"
    inner_print_menu_item "stop_tomcat " " Stoppe un tomcat (et affiche les logs)"
    inner_print_menu_item "tail_apache_and_tomcat_logs " " Permet d'accéder à la fois aux logs tomcat et apache s'ils existent"
    inner_print_menu_item "verify_line_termination_and_formats " " Commande alm pour vérifier les encodings de n'importe quelle arborescence"
    inner_print_menu_item "verify_line_termination_and_formats_alm " " Commande alm pour vérifier les encodings de ${HWI_INSTALL}"
    inner_print_menu_item "yum clean all " " Pour hawai > 4 on peut yum clean all (cf #647845), sinon contournement : display_yum_cache ; select_and_delete"
    print_separator
)

multi_ssh_command() {
    doc "On accède aux IP des autres serveurs de la plateforme
    A lancer préférentiellement sur le monitor, les autres n'ont pas forcément les ip"
    # On sortira IP d'ici quand il servira ailleurs
    IPs=$(cat ${HAWAI_PROPS} | grep 'ip=')
    doc "On affiche la liste des serveurs accessibles"
    print_title "Serveurs accessibles en ssh depuis $(hostname)"
    for unformatted in ${IPs[@]}; do
        display_plateforme_accessibles_ip ${unformatted:3:20}
    done
    doc "On selectionne une liste d'ip"
    echo -ne "${PROMPT_STYLE} Saisir la liste d'IPs à requêter, séparées par des espaces, ou ALL pour sélectionner tous les serveurs ${RAZ_STYLE}"
    read -r -p " : " IPs_A_REQUETTER
    if [[ ${IPs_A_REQUETTER[0]} == "ALL" ]]; then
        echo -e "${BLUE_STYLE}Certains sont innaccessibles, pas d'impact en théorie mais il faut savoir que les commandes vers ces serveurs sont 2>/dv/null, et donc non affichées${RAZ_STYLE}"
        # remplace ip= par du vide
        IPs_A_REQUETTER=(${IPs//ip=/ })
    fi
    for correct_ip in ${IPs_A_REQUETTER[@]}; do
        ssh hawai@$correct_ip hostname 2>/dev/null
    done
    ssh_menu_display_verbose_off=
    echo -ne "${PROMPT_STYLE} Entrez y pour afficher la version courte du menu, vide sinon : ${RAZ_STYLE}"
    read ssh_menu_display_verbose_off
    while :; do
        doc "On affiche les commandes"
        ssh_menu_display ${ssh_menu_display_verbose_off} # le paramètre permet d'afficher le format long du menu 
        # par précaution, on reset command
        ssh_command=
        doc "On écrit la commande souhaitée"
        echo -ne "$PROMPT_STYLE Entrez un nom de fonction fonction (ou une commande shell)$RAZ_STYLE"
        read -p " : " ssh_command
        doc "On est sur la partie la plus rigolote du code : 
        En ssh on ouvre un shell chez le remote, mais ce shell n'a pas les variables d'env
        ni les fonctions, du coup que faire pour pouvoir lancer des fonctions dans un autre shell, 
        aussi dynamiquement que possible ?
        On exporte les déclarations et contenu des fonctions avec export_all_funtions_ssh
        et on cree une fonction qui contient les paramètres, afin de l'exécuter après l'import des 
        fonctions dans le bash remote
        On exporte les déclarations et contenu des fonctions avec export_all_funtions_ssh
        NB, si on observe le contenu de l'export, on se rends compte que c'est le conten
        post interprétation par le shell : les ; sont déjà positionnés"
        # cat will receive the definition of the function as a text and $() will execute it
        # in the current shell which will become a defined function in the remote shell.
        # Finally the function can be executed.
        for correct_ip in ${IPs_A_REQUETTER[@]}; do
            print_separator
            ssh hawai@${correct_ip} hostname 2>/dev/null
            doc "Le -t permet d'avoir une remontée dynamique, et de lancer des commandes qui en ont besoin (psql, htop, etc)"
            ssh -t hawai@${correct_ip} "$(export_all_funtions_ssh) ; init ; $ssh_command " 2>/dev/null
        done
        doc "plus sérieusement, pour que la solution tienne en un seul fichier on fot lister manuellement les noms de fonctions a mettre a disposition des serveurs atteints en ssh"
        # doc "Condition de sortie de la boucle"
        # YN=
        # echo -ne "Saississez y pour quitter la fonction, laisser vide sinon :"
        # read YN
        # if [[ $YN ]]; then
        #     break
        # fi
    done

}

################################# Boucle principale ##################################
######################################################################################

clear
## On charge les chemins
init

echo
echo -e "${BLUE_STYLE}   _ _ ___________________________________________ _ _ _ _ ${RAZ_STYLE}"
echo -e "${BLUE_STYLE}   _ _ ____________________   ______ __________ ${RAZ_STYLE}"
echo -e "${BLUE_STYLE}   _ _ ________________    |  ___  //_/___  __/ ${RAZ_STYLE}"
echo -e "${BLUE_STYLE}   _ _ _______________  /| |  __  ,<   __  /    ${RAZ_STYLE}"
echo -e "${BLUE_STYLE}   _ _ ______________  ___ |___  /| |___  /__   ${RAZ_STYLE}"
echo -e "${BLUE_STYLE}   _ _ _____________/_/  |_|(_)_/ |_|(_)_/_(_)  ${RAZ_STYLE}"
echo -e "${BLUE_STYLE}   _ _ ___________________________________________ _ _ _ _ ${RAZ_STYLE}"
ready_steady_go
echo -e "${BLUE_STYLE}          $(date) ${RAZ_STYLE}"
echo

doc "Pour lister les paths utilisés par le script, ctrl+c puis tapez [ grep \"='/\" $0 ] "
display_warning_if_root
while :; do
    echo -e " ${UDERLINE_STYLE}Commande| Type d'action|n°|   Cible    | Description${RAZ_STYLE}"
    echo -e " ${BOLD_STYLE}   1    | SUPERVISION  |1 |    ${GREEN_STYLE}TOUS${RAZ_STYLE}    | Afficher l'usage du disque et les partitions${RAZ_STYLE}"
    echo -e " ${BOLD_STYLE}   2    | SUPERVISION  |2 |    ${PURPLE_STYLE}SGBD${RAZ_STYLE}    | Recherche de fichiers dump/temporaires en dehors du point de montage${RAZ_STYLE}"
    echo -e " ${BOLD_STYLE}   3    | SUPERVISION  |3 |    ${BLUE_STYLE}AGENT${RAZ_STYLE}   | Consulter les fichiers logs des agents${RAZ_STYLE}"
    echo -e " ${BOLD_STYLE}   4    | SUPERVISION  |4 |    ${GREEN_STYLE}TOUS${RAZ_STYLE}    | Afficher les N plus gros fichiers sous l'arborescence souhaitée${RAZ_STYLE}"
    echo -e " ${BOLD_STYLE}   5    | SUPERVISION  |5 |    ${GREEN_STYLE}TOUS${RAZ_STYLE}    | Vérifier le cache yum${RAZ_STYLE}"
    echo -e " ${BOLD_STYLE}   6    | SUPERVISION  |6 |    ${GREEN_STYLE}TOUS${RAZ_STYLE}    | Consulter la date de modification d'un ou plusieurs fichiers${RAZ_STYLE}"
    echo -e " ${BOLD_STYLE}   7    | SUPERVISION  |7 |    ${GREEN_STYLE}TOUS${RAZ_STYLE}    | Consulter les crontask${RAZ_STYLE}"
    echo -e " ${BOLD_STYLE}   8    | SUPERVISION  |8 |    ${GREEN_STYLE}TOUS${RAZ_STYLE}    | Visualiser les processus en cours${RAZ_STYLE}"
    echo -e " ${BOLD_STYLE}   9    | INSTALLATION |9 |    ${BLUE_STYLE}AGENT${RAZ_STYLE}   | Accéder aux fichiers [ appli.properties ] de la plateforme${RAZ_STYLE}"
    echo -e " ${BOLD_STYLE}   10   | SAUVEGARDE   |10|    ${PURPLE_STYLE}SGBD${RAZ_STYLE}    | Créer un dump${RAZ_STYLE}"
    echo -e " ${BOLD_STYLE}   11   | MAINTENANCE  |11| ${PURPLE_STYLE}SGBD${RAZ_STYLE}/${BLUE_STYLE}AGENT${RAZ_STYLE} | Relancer/créer un point de montage de sauvegarde de dumps${RAZ_STYLE}"
    echo -e " ${BOLD_STYLE}   12   | SQL_CLIENT   |12|   ${PURPLE_STYLE}SGBD${RAZ_STYLE}     | Se connecter en CLI au SGBD${RAZ_STYLE}"
    echo -e " ${BOLD_STYLE}   13   | SSH          |13|  ${ORANGE_STYLE}MONITEUR${RAZ_STYLE}  | ${RED_STYLE}Accéder à plusieurs serveurs de la plateforme (ssh)${RAZ_STYLE}"
    echo -e " ${BOLD_STYLE}   14   | SSH(SCP)     |14|    ${GREEN_STYLE}TOUS${RAZ_STYLE}    | Envoyer un fichier/dossier via SCP (ssh)"
    echo -e " ${BOLD_STYLE}   15   | SSH(SCP)     |15|    ${GREEN_STYLE}TOUS${RAZ_STYLE}    | Recevoir un fichier/dossier via SCP (ssh)"
    echo -e " ${BOLD_STYLE}   16   | SUPERVISION  |16|    ${GREEN_STYLE}TOUS${RAZ_STYLE}    | Voir les versions et dates d'installation des rpm livrés (hawai-apps)"
    echo -e " ${BOLD_STYLE}   17   | SUPERVISION  |17|    ${GREEN_STYLE}TOUS${RAZ_STYLE}    | Rechercher un mot dans une arborescence de fichier"
    echo -e " ${BOLD_STYLE}   18   | INSTALLATION |18|    ${GREEN_STYLE}TOUS${RAZ_STYLE}    | Aide à l'import de dump"
    echo -e " ${BOLD_STYLE}   19   | SUPERVISION  |19|    ${GREEN_STYLE}TOUS${RAZ_STYLE}    | Vérification des encodings et formats dans une arborescence"
    echo -e " ${BOLD_STYLE}  café${RAZ_STYLE}   Le coffee-timer dont vous avez toujours rêvé"
    echo -e " ${BOLD_STYLE}  exit${RAZ_STYLE}   Quitter le script"
    echo -e " ${BOLD_STYLE}  clean${RAZ_STYLE}  Supprimer ce script (pour laisser le serveur propre)"
    echo -e " ${BOLD_STYLE}  meteo${RAZ_STYLE}  "
    print_separator
    echo "Pour voir l'implémentation d'une option, tapez 'NORUN' devant le numéro de commande"
    echo "Exemple : NORUN3"
    echo -ne "${PROMPT_STYLE} Entrez un numéro de commande : ${RAZ_STYLE} "

    # par précaution, on reset command
    command=
    read -r -p " " command
    case $command in
    1) global_disk_use ;;
    2) look_for_lost_dumps_and_temp_files ;;
    3) list_all_agents_s_logs ;;
    4) public_method_display_biggest_files_under_path ;;
    5) display_yum_cache ;;
    6) multi_folder_display_weight_and_sort_by_update_date ;;
    7) display_cron_tasks ;;
    8) htop_but_custom_and_usable_in_ssh ;;
    9) list_and_cat_app_properties ;;
    10) create_dump_and_place_it_whereever_you_want ;;
    11) check_partitions_and_fstab_and_create_sgbd_save_mountpoint_and_mount_all ;;
    12) connect_psql ;;
    13) multi_ssh_command ;;
    14) send_file_via_scp ;;
    15) get_file_via_scp ;;
    16) get_installed_apps ;;
    17) find_word_in_files ;;
    18) how_to_import_hawai_dump ;;
    19) verify_line_termination_and_formats ;;
    NORUN1) no_run global_disk_use ;;
    NORUN2) no_run look_for_lost_dumps_and_temp_files ;;
    NORUN3) no_run list_all_agents_s_logs ;;
    NORUN4) no_run public_method_display_biggest_files_under_path ;;
    NORUN5) no_run display_yum_cache ;;
    NORUN6) no_run multi_folder_display_weight_and_sort_by_update_date ;;
    NORUN7) no_run display_cron_tasks ;;
    NORUN8) no_run htop_but_custom_and_usable_in_ssh ;;
    NORUN9) no_run list_and_cat_app_properties ;;
    NORUN10) no_run create_dump_and_place_it_whereever_you_want ;;
    NORUN11) no_run check_partitions_and_fstab_and_create_sgbd_save_mountpoint_and_mount_all ;;
    NORUN12) no_run connect_psql ;;
    NORUN13) no_run multi_ssh_command ;;
    NORUN14) no_run send_file_via_scp ;;
    NORUN15) no_run get_file_via_scp ;;
    NORUN16) no_run get_installed_apps ;;
    NORUN17) no_run find_word_in_files ;;
    NORUN18) no_run how_to_import_hawai_dump ;;
    NORUN19) no_run verify_line_termination_and_formats ;;
    meteo)
        echo -ne "${PROMPT_STYLE} # Saisissez une ville : ${RAZ_STYLE}"
        read VILLE 
        curl -s "wttr.in/${VILLE}?m3" 
    ;;
    café) coffee ;;
    clean)
        rm -i $0
        break
        ;;
    exit) break ;;
    *) print_title "Merci de saisir une commande dans la plage des valeurs prévues" ;;
    esac
    print_again
done

######################################################################################
exit_ok
