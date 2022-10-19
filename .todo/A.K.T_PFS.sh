#!/bin/bash
############################################################################################
# prérequis : chmod + x A.K.T_PFS.sh
# Lancement : ./A.K.T_PFS.sh
# Script utilitaire à destination des intégrateurs, acteurs de la supervisions et gestion des envs
# Prévu pour l'environnement bastion
############################################################################################
# Contient plusieurs commandes de base pour consulter des namespaces kubernetes
############################################################################################
LOG_FOLDER_PREFIX="temporary_logs_"
doc() {
    ## Ne fait rien, permet juste aux commentaires souhaités d'apparaîte dans les commandes lancées en no_run
    unused=
}
init() {
    doc '######################### ( à faire évoluer en fonction des besoins ) ######################'
    # ne surtout pas supprimer cette propertie essentielle
    A_DEJA_PRIS_UN_CAFE=0
    # Paramètres d'affichage ################################## https://misc.flogisoft.com/bash/tip_colors_and_formatting
    RAZ_STYLE="\e[0m"
    BLUE_STYLE="\e[0;49;96m"
    PURPLE_STYLE="\e[1;40;35m"
    RED_STYLE="\e[91m"
    GREEN_STYLE="\e[38;5;82m"
    UDERLINE_STYLE="\e[4m"
    PROMPT_STYLE="\e[0;49;92m"
    B_and_N_STYLE="\e[30mBlack\e[107m"
    ORANGE_STYLE="\e[0;40;93m"
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

print() {
    echo -e "${RED_STYLE} # ${PROMPT_STYLE} $1 ${RAZ_STYLE}"
}
print_ko() {
    echo -e "${ORANGE_STYLE} # ${RED_STYLE} $1 ${RAZ_STYLE}"
}
# pour normaliser l'affichage menu, prends deux paramètres, le numéro de l'item, et le label
print_menu_item() {
    echo -e "${ORANGE_STYLE} $1 \t ${BLUE_STYLE} $2 ${RAZ_STYLE}"
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
exemple() {
    doc "permet d'afficher les namespaces les plus utilisés"
    print_separator
    echo -e "${BLUE_STYLE} Exemple en contexte NGA : ${RAZ_STYLE} 
    ${BLUE_STYLE}C1: \t ${PROMPT_STYLE} int-nga-c1    ${ORANGE_STYLE} int-sngi-c1 ${PURPLE_STYLE} int-idregc-c1 
    ${BLUE_STYLE}C2: \t ${PROMPT_STYLE} int-nga-c2    ${ORANGE_STYLE} int-sngi-c2 ${PURPLE_STYLE} int-idregc-c2 
    ${BLUE_STYLE}C4: \t ${PROMPT_STYLE} int-nga-clea2 ${ORANGE_STYLE} int-sngi-c4 ${PURPLE_STYLE} int-idregc-c4
    ${BLUE_STYLE}C7: \t ${PROMPT_STYLE} int-nga-c7    ${ORANGE_STYLE} int-sngi-c7 ${PURPLE_STYLE} int-idregc-c7 
    ${RAZ_STYLE}"
    print_separator

}
exit_ok() {
    print "Bonne journée !"
    exit 0
}

print_again() {
    echo -ne "${PROMPT_STYLE} Appuyez sur entrée ${RAZ_STYLE}"
    read -p " " PROMPT_AGAIN
    if [[ $PROMPT_AGAIN ]]; then
        # un shortcut pour les connaisseurs, si on appuie sur une touche avant "entrée" ça nettoie l'écran, mais ça marche pas avec espace
        clear
    fi
}

# Très important
ready_steady_go() {
    messages_pour_la_posterite=("${ORANGE_STYLE} PFS : Pour Faire Simple${RAZ_STYLE}" "${ORANGE_STYLE}    - Valeur agile : Il vaut mieux accorder de l'importance aux individus et leurs interactions plutôt qu'aux processus et aux outils ; ${RAZ_STYLE}" "${ORANGE_STYLE}    - Valeur agile : Il vaut mieux accorder de l'importance à un logiciel fonctionnel plutôt qu'à une documentation exhaustive ; ${RAZ_STYLE}" "${ORANGE_STYLE}    - Valeur agile : Il vaut mieux accorder de l'importance à la collaboration avec les clients plutôt qu'à la négociation contractuelle ; ${RAZ_STYLE}" "${ORANGE_STYLE}    - Valeur agile : Il vaut mieux accorder de l'importance à l'adaptation au changement plutôt qu'à l'exécution d'un plan. ${RAZ_STYLE}" "${ORANGE_STYLE}    - Principe agile : Notre plus haute priorité est de satisfaire le client en livrant rapidement et régulièrement des fonctionnalités à grande valeur ajoutée. ${RAZ_STYLE}" "${ORANGE_STYLE}    - Principe agile : Accueillez positivement les changements de besoins, même tard dans le projet. Les processus Agiles exploitent le changement pour donner un avantage compétitif au client. ${RAZ_STYLE}" "${ORANGE_STYLE}    - Principe agile : Livrez fréquemment un logiciel fonctionnel, dans des cycles de quelques semaines à quelques mois, avec une préférence pour les plus courts. ${RAZ_STYLE}" "${ORANGE_STYLE}    - Principe agile : Les utilisateurs ou leurs représentants et les développeurs doivent travailler ensemble quotidiennement tout au long du projet. ${RAZ_STYLE}" "${ORANGE_STYLE}    - Principe agile : Réalisez les projets avec des personnes motivées. Fournissez-leur l'environnement et le soutien dont elles ont besoin et faites-leur confiance pour atteindre les objectifs fixés. ${RAZ_STYLE}" "${ORANGE_STYLE}    - Principe agile : La méthode la plus simple et la plus efficace pour transmettre de l'information à l'équipe de développement et à l'intérieur de celle-ci est le dialogue en face à face. ${RAZ_STYLE}" "${ORANGE_STYLE}    - Principe agile : Un logiciel fonctionnel est la principale mesure de progression d'un projet. ${RAZ_STYLE}" "${ORANGE_STYLE}    - Principe agile : Les processus agiles encouragent un rythme de développement soutenable. Ensemble, les commanditaires, les développeurs et les utilisateurs devraient être capables de maintenir indéfiniment un rythme constant. ${RAZ_STYLE}" "${ORANGE_STYLE}    - Principe agile : Une attention continue à l'excellence technique et à un bon design. ${RAZ_STYLE}" "${ORANGE_STYLE}    - Principe agile : La simplicité - c'est-à-dire l'art de minimiser la quantité de travail inutile – est essentielle. ${RAZ_STYLE}" "${ORANGE_STYLE}    - Principe agile : Les meilleures architectures, spécifications et conceptions émergent d'équipes auto-organisées. ${RAZ_STYLE}" "${ORANGE_STYLE}    - Principe agile : À intervalles réguliers, l'équipe réfléchit aux moyens possibles de devenir plus efficace. Puis elle s'adapte et modifie son fonctionnement en conséquence. ${RAZ_STYLE}" "${ORANGE_STYLE}    - Word est un logiciel très lourd et peu adapté à de la documentation technique. Powerpoint, OneNote et Paint non plus.  ${RAZ_STYLE}" "${ORANGE_STYLE}    - Une équipe avec des contraintes de planning et des obligations de résultat ne peut PAS se permettre de ne pas prendre le temps d'en gagner. ${RAZ_STYLE}" "${ORANGE_STYLE}    - Travaillez à être fiers de ce que vous faites. ${RAZ_STYLE}" "${ORANGE_STYLE}    - Hâtez-vous lentement, et, sans perdre courage, Vingt fois sur le métier remettez votre ouvrage : Polissez-le sans cesse et le repolissez ; Ajoutez quelquefois, et souvent effacez. - Nicolas Boileau${RAZ_STYLE}" "${ORANGE_STYLE}    - \"On a toujours fait comme ça\" est une phrase dangereuse et non recevable, qui peut empêcher une civilisation de sortir du moyen-âge. ${RAZ_STYLE}" "${ORANGE_STYLE}    - Prenez du recul, cherchez des redondances, des actions inutiles, parlez-en, la fatigue et l'ennui ne sont pas des états d'esprit productifs. ${RAZ_STYLE}" "${ORANGE_STYLE}    - Un processus n'a de sens que s'il est remis en question, adapté à son contexte, et apporte une valeur ajoutée. ${RAZ_STYLE}" "${ORANGE_STYLE}    - Avant de lancer toute commande, tout script, vérifiez les encodings... Windows est partout, ses utilisateurs nombreux, et ils font planter des serveurs depuis 30 ans. ${RAZ_STYLE}" "${ORANGE_STYLE}    - Ne confiez pas à un humain le travail d'une machine - Agent Smith, Matrix I ${RAZ_STYLE}" "${ORANGE_STYLE}    - Cherchez des objectifs plus nobles et valorisants que la seule complétude des tâches... Pensez à l'humain, la planète, le futur, votre santé et celle des autres. ${RAZ_STYLE}" "${ORANGE_STYLE}    - Quoi qu'il arrive, on ne peut pas attaquer une personne sur son travail, on peut au mieux tenter de comprendre ses contraintes. ${RAZ_STYLE}" "${ORANGE_STYLE}    - Les vraies innovations proviennent du croisement de sujets distincts. Toute personne est suceptible d'avoir une solution meilleure que toutes les autres, peu importe son métier. ${RAZ_STYLE}" "${ORANGE_STYLE}    - La résistance au changement est un phénomène sociologique qui a déjà tué énormément de personnes, d'organisations, de sociétés. ${RAZ_STYLE}" "${ORANGE_STYLE}    - C'est au pied du mur qu'on voit le mieux le mur. ${RAZ_STYLE}" "${ORANGE_STYLE}    - Il vaut mieux une vraie croyante qu'une fausse septique. ${RAZ_STYLE}" "${ORANGE_STYLE}    - Les moulins... C'était mieux à vent. ${RAZ_STYLE}" "${ORANGE_STYLE}    - Le jour où Microsoft vendra quelque chose qui ne plante pas, ça sera sûrement un clou. ${RAZ_STYLE}" "${ORANGE_STYLE}    - Si le ski alpin, qui a le beurre et la confiture ? ${RAZ_STYLE}" "${ORANGE_STYLE}    - Si Gibraltar est un détroit, qui sont les deux autres ? ${RAZ_STYLE}" "${ORANGE_STYLE}    - L'expérience est l'addition de nos erreurs. ${RAZ_STYLE}" "${ORANGE_STYLE}    - On est pas là pour être ici ${RAZ_STYLE}" "${ORANGE_STYLE}    - $(date) ? C'est l'heure de la petite sieste avant d'aller dormir... ${RAZ_STYLE}" "${RED_STYLE}    - Avez-vous rempli votre suivi ? ${RAZ_STYLE}" "${ORANGE_STYLE}    - Avez-vous essayé de redémarrer la box ? ${RAZ_STYLE}" "${ORANGE_STYLE}    - Non, $0 ne peut pas réparer votre imprimante. ${RAZ_STYLE}" "${ORANGE_STYLE}    - ...${RAZ_STYLE}" "${ORANGE_STYLE}    - Tester c'est douter${RAZ_STYLE}" "${ORANGE_STYLE}    - Corriger c'est capituler${RAZ_STYLE}" "${ORANGE_STYLE}    - Pas d'accès, pas d'action.${RAZ_STYLE}" "${ORANGE_STYLE}    - Des mauvais outils font de mauvais artisans${RAZ_STYLE}")
    echo -e ${messages_pour_la_posterite[$(($RANDOM % ${#messages_pour_la_posterite[@]}))]}
}

# Vérifie la présence d'un fichier et l'écrit en langage humain
check_file() {
    FILE=$1
    if [ -f "$FILE" ]; then
        echo -e "${GREEN_STYLE} $FILE présent ${RAZ_STYLE}"
    else 
        echo -e "${RED_STYLE} $FILE absent ${RAZ_STYLE}"
    fi
}

# Fonctions de monitoring ##################################

coffee() {
    doc "cette fonction est absolument essentielle au fonctionnement de la solution"
    if [[ $A_DEJA_PRIS_UN_CAFE == '1' ]]; then
        echo -e "${RED_STYLE}[FATAL]${RAZ_STYLE} : un mail vient d'être envoyé au pilotage."
        sleep 3
        echo -e "${RED_STYLE}Posez ce café tout de suite.${RAZ_STYLE}"
    fi
    if [[ $A_DEJA_PRIS_UN_CAFE == '0' ]]; then
        STARTTIME=$(date +%s%N)
        echo "Encore au café ? Bon, d'accord, j'attends là"
        sleep 1
        echo -ne "."
        sleep 1
        echo -ne "."
        sleep 2
        echo -ne "."
        sleep 1
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
        echo -e "${ORANGE_STYLE}Mais reviens vite !${RAZ_STYLE}"
        read ok
        ENDTIME=$(date +%s%N)
        DURATION=$(((ENDTIME - STARTTIME) / 1000000000))
        echo "Ce café n'a pris que ${DURATION} secondes... Ré-essayez de battre votre record plus tard !"
        # nous sachons
        A_DEJA_PRIS_UN_CAFE=1
    fi
}

# Permet de se connecter en bdd sur un pod
connect_psql() { 
    print "CONNEXION A UNE BASE POSTGRES DANS UN POD PFS"
    print "Entrez le nom du namespace :"
    exemple
    NAMESPACE=
    read NAMESPACE
    print "namepace : ${NAMESPACE}"
    kubectl config set-context --current --namespace=${NAMESPACE}
    kubectl get pods -n ${NAMESPACE} --no-headers | egrep -i "(database|bdd|postgres)" | egrep -i "(running)"
    print "Entrez le nom du pod :"
    read nom_pod
    
    print "Liste des bases disponibles dans ${nom_pod}"

    kubectl exec -it ${nom_pod} -- psql -c \\l ;
    read -p "Renseignez la valeur DBNAME=" DBNAME
    print "Rappel des commandes postgres : "
    print_menu_item 'Connexion à une bdd              :' '\\c dbname [username]'
    print_menu_item 'Lister les bdd                   :' '\l  '
    print_menu_item 'Lister les schémas               :' '\dn  '
    print_menu_item 'Lister les tables                :' '\dt ou "SELECT table_name FROM information_schema;"'
    print_menu_item 'Décrire la structure d une table :' '\d table '
    print_menu_item 'historique des commandes         :' '\s  '
    print_menu_item 'formatage (just do it plz)       :' '\x (...sinon les résultats de requêtes sont ILLISIBLES)'
    kubectl exec -it ${nom_pod} -- psql -c "SELECT count(*) || ' sessions ouvertes ' as nb_sessions_ouvertes FROM pg_stat_activity;"
    print "Appuyez sur entrée pour vous connecter en BDD"
    kubectl exec -it ${nom_pod} -- psql ${DBNAME}
}

# Petit aide mémoire des commandes et des vérifs d'usage à faire en cas de nouvelle livraison pfs, 
# a destination en priorité des nouveaux entrants
autoconformite_livraison_pfs() {
    print "Prérequis : le repo doit être déjà cloné sur votre environnement bastion"
    print "Saisissez le couloir cible format C0X :" ; read COULOIR
    ARBORESCENCE_LOCALE=$(du -h | egrep "\.git$" | sed 's/\.git//g')
    print "${ARBORESCENCE_LOCALE}"
    print "Saisissez le chemin absolu vers votre repo local :" ; read PATH_TO_LOCAL
    print "Recherche du ${PATH_TO_LOCAL}"
    cd ${PATH_TO_LOCAL} ; pwd
    print "(la commande suivante ne marche que si on utilise git en http avec les ID dans la remote)"
    REMOTE=$(git remote -v)
    echo $REMOTE | cut -d '@' -f 3 
    # Retrouver le tag
    git fetch --all --tags
    print 'Le format attendu du tag est le suivant : AAMMPP_VV_II avec :'
    print '    AAMM: N° du lot sous la forme Année Mois (exemple: 2203 pour Mars 2022)'
    print '    PP: N° de l increment en production'
    print '    VV: N° de l incrément en validation'
    print '    II: N° de l incrément en intégration'
    print "Tags disponibles sur le repo :"
    git tag
    print "Saisissez le tag indiqué en DLOT, laissez vide si absent" ; read EXPECTED_TAG
    if [[ ${EXPECTED_TAG} ]]; then 
        PRESENCE_DU_TAG=$(git tag | grep ${EXPECTED_TAG} | wc -l)
        if [[ ${PRESENCE_DU_TAG} -eq 1 ]]; then 
            print "[OK] Le tag ${EXPECTED_TAG} existe."

            print "Si c'est la première livraison :"
            print "      Pour créer la branche à partir du tag :"
            echo "git checkout tags/${EXPECTED_TAG} # positionne le pointeur à l'emplacement du tag "
            echo
            echo "git checkout -b INT/${COULOIR} # crée la branche "
            print "Si la branche existe déjà : "
            echo "git checkout INT/${COULOIR} # se positionner sur la branche"
            echo "git merge ${EXPECTED_TAG}"
            print "puis"
            echo "git push -u origin INT/${COULOIR} # envoie la branche sur le gitlab"
        else 
            print_ko "[KO] Le tag indiqué en DLOT est absent : le processus demande la création d'un ticket d'anomalie"
        fi
    else 
        print_ko "[KO] Le tag indiqué en DLOT est absent : le processus demande la création d'un ticket d'anomalie"
        print "Si le tag est absent, la consigne est de contacter le RDD pour connaitre la branche de laquelle forker"
        print "Liste des branches distantes : "
        git branch -r
        print "Saisissez le nom de cette branche : " ; read IF_NO_TAG_BRANCH
        PRESENCE_DE_IF_NO_TAG_BRANCH=$(git branch -r | grep ${IF_NO_TAG_BRANCH} | wc -l)
        if [[ $PRESENCE_DE_IF_NO_TAG_BRANCH -gt 0 ]]; then 
            print "[OK] La branche ${IF_NO_TAG_BRANCH} existe."
            print "Pour créer la branche à partir de ${IF_NO_TAG_BRANCH} :"
            echo "git checkout ${IF_NO_TAG_BRANCH} # positionne le pointeur à l'emplacement du dernier commit de la branche "
            echo "git pull"
            echo "git status"
            echo
            print "Si c'est la première livraison :"
            echo "git checkout -b INT/${COULOIR} # crée la branche "
            print "Si la branche existe déjà : "
            echo "git checkout INT/${COULOIR} # se positionner sur la branche"
            echo "git merge ${IF_NO_TAG_BRANCH}"
            echo
            print "puis"
            echo "git push -u origin INT/${COULOIR} # envoie la branche sur le gitlab"
        else
            print_ko "[KO] La branche attendue n'existe pas: le processus demande la création d'un ticket d'anomalie"
        fi 
    fi 

    read -p "Appuyez sur entrée une fois les commandes de récupération des sources effectuées"


    # Verifier la présence des fichiers template

    print "Vérification de présence du deploy.sh"
    check_file "deploy.sh"
    print "Vérification de présence du env.sh.tmpl"
    check_file "env.sh.tmpl"
    print "Vérification de présence du charts_infos.sh"
    check_file "charts_infos.sh"
    print "Vérification de présence du scripts/get_keys.sh"
    check_file "scripts/get_keys.sh"
    print "Vérification de présence du scripts/set_truststore_cacerts.sh"
    check_file "scripts/set_truststore_cacerts.sh"
    print "Vérification de présence du values.yaml.tmpl"
    check_file "values.yaml.tmpl"
}
# ça l'écrit en redmine, pas sur que ça soit utile
extract_namespace_pods_state_for_redmine() {
    
    print "Renseignez le nom de l'application testée : " ; read APP_NAME
    print "Renseignez le namespace : " ; 
    exemple
    NAMESPACE=
    read NAMESPACE
    print_separator
    echo "Bonjour, "
    echo "Ci-dessous les traces des commandes de vérifications de l'exploitabilité PFS de ${APP_NAME}."
    echo 
    echo -n "h3. Pods présent dans le namespace ${NAMESPACE}"
    PODS_COUNT=$(kubectl get pods -n ${NAMESPACE} | wc -l)
    echo
    echo "<pre>"
    kubectl get pods -n ${NAMESPACE} --no-headers
    echo "</pre>"
    echo "On compte $((${PODS_COUNT}-1)) pods dans le ${NAMESPACE}."
    echo 

    ALL_PODS=( $(kubectl get pods -n ${NAMESPACE} --no-headers -o custom-columns=":metadata.name") )

    EXCLUDED_FILTER="namespace|StatefulSet|secretname|_name|username|ips|.name|_ip|iptables|type:|STATEMENTS"
    #FILTER="name|state|IP|started"
    FILTER="name|state|started"
    NB_OF_LINE_EXPECTED=3 #ca c'est un peu overkill et pas beau mais bon si on a plusieurs champs qui matchent les filtres autant ne pas avoir de doublon. 
    #Il faut le valoriser au nombre de ${FILTER}
    #Comment ça "est-ce qu'on peut avoir deux fois le meme filtre d'affilée ?" c'est une excellente question, que je vous remercie de l'avoir posé

    for pod in ${ALL_PODS[@]}; do
        echo
        echo "h3. ${pod} :"
        echo "<pre>"
        kubectl -n ${NAMESPACE} describe pods ${pod} | egrep -i ${FILTER} | egrep -iv ${EXCLUDED_FILTER} | sed -e 's/^[[:space:]]*//' | head -n ${NB_OF_LINE_EXPECTED}
        echo "</pre>"
    done
}


find_word_in_files() {
    doc "Cherche des occurences de mots dans toute l'arborescence souhaitée"
    PWD=$(pwd)
    PWD_COPY="$PWD" # c'est bizarre mais ça marche
    PATTERN_TO_SEARCH=
    PATH_TO_GO=
    print "Liste des dossiers contenant les logs précédemment créés :"
    ls -lath | grep ${LOG_FOLDER_PREFIX}
    print "Souhaitez vous chercher dans une arborescence en particulier ? 
    Si non la recherche se fera dans ${PWD}
    Si oui saisissez l'arborescence : ${RAZ_STYLE}"
    read -p " " PATH_TO_GO

    print "Saisissez un mot, ou une liste de mot au format : mot1|mot2|mot3
    exemple : erreur|error|fatal debug|warn  
    Que cherchez vous ? ${RAZ_STYLE}"
    read -p " " PATTERN_TO_SEARCH

    if [[ $PATH_TO_GO ]]; then
        cd ${PATH_TO_GO} 
    fi
    print_separator
    egrep --color=always -Ril "${PATTERN_TO_SEARCH}" | egrep --color=always -rin "${PATTERN_TO_SEARCH}" 
    print_separator
    cd ${PWD_COPY} # si on rappelle PWD en fait il change de répertoire
}

# permet de récupérer les variables d'environnement d'un pod qui concernent kafka
# au début c'était assez utile, maintenant c'est prrincipalement encore là pour
# fournir un affichage plus propre sans avoir besoin d'exclure les SSL et SECURITY qui polluent l'affichage
extract_kafka_topics_from_namespace() {
    print "Renseignez le namespace :"
    exemple
    NAMESPACE=
    read NAMESPACE
    ALL_PODS=( $(kubectl get pods -n ${NAMESPACE} --no-headers -o custom-columns=":metadata.name") )
    for pod in ${ALL_PODS[@]}; do
        # on veut un résultat sur plusieurs lignes, du coup on peut pas utiliser $()
        topics=$(kubectl -n ${NAMESPACE} exec ${pod} -- printenv 2>/dev/null | egrep -i "(TOPIC)" | egrep -vi "(SSL|SECURITY)") # c'est très moche mais on est pas là pour la perf
        if [[ $topics ]]; then
            print ${pod}
            echo -e "${ORANGE_STYLE}"
            kubectl -n ${NAMESPACE} exec ${pod} -- printenv 2>/dev/null | egrep -i "(TOPIC)" | egrep -vi "(SSL|SECURITY)" # oui oui c'est une réplication
            echo -e ${RAZ_STYLE}        
        fi
    done
}
# très puissant, mais ne prends pas plusieurs namespaces en paramètre
# car il pourrait y avoir trop de résultats pour tenir en console si on fouillait 
# de l'ordre de plusieurs centaines de pods à la fois 
extract_configuration_from_namespace() {
    print "Renseignez le namespace :"
    exemple
    NAMESPACE=
    read NAMESPACE
    print "Renseignez le(s avec des un|deux) token(s) que vous souhaitez voir : "
    read TOKENS
    ALL_PODS=( $(kubectl get pods -n ${NAMESPACE} --no-headers -o custom-columns=":metadata.name") )
    for pod in ${ALL_PODS[@]}; do
        # on veut un résultat sur plusieurs lignes, du coup on peut pas utiliser $()
        topics=$(kubectl -n ${NAMESPACE} exec ${pod} -- printenv 2>/dev/null | egrep -i "(${TOKENS})" | egrep -vi "(SSL|SECURITY)") # c'est très moche mais on est pas là pour la perf
        if [[ $topics ]]; then
            print ${pod}
            echo -e "${ORANGE_STYLE}"
            kubectl -n ${NAMESPACE} exec ${pod} -- printenv 2>/dev/null | egrep -i "(${TOKENS})" | egrep -vi "(SSL|SECURITY)" # oui oui c'est une réplication
            echo -e ${RAZ_STYLE}        
        fi
    done
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
# La fonction la plus utile de ce script
# elle permet de :
# selectionner plusieurs namespaces à la fois, suggérés préférentiellement par la commande exemple() 
# saisir une plage horaire précise pour ne considérer que les logs correspondants à l'action à analyser 
#        => préférable à utiliser directement après l'action, on pourrait modifier pour ajouter une borne 
#           haute mais ça rends l'action de consultation des logs plus fastidieuse... 
#            En règle générale, il vaut mieux observer les logs quelques minutes après qu'ils soient produits
# saisir un suffixe de nommage pour le dossier destination des logs, afin de les rendre exploitables dans le futur
# filter les logs à télécharger, seuls les logs non vides sont conservés
# afficher des compteurs sur toutes les occurences de logs grâce à count_log_occurences_by_log_level()
#
# Les logs obtenus sont consultables par occurence de log via la fonction find_word_in_files()
get_several_namespaces_logs() {
    doc "on peut supprimer les log_folders en une fois avec rm -rf ${LOG_FOLDER_PREFIX}* "
    LOG_FOLDER="${LOG_FOLDER_PREFIX}$(date +"%Y_%m_%d")" 
    # RAZ
    is_it_hope_or_madness= # j'étais vraiment content quand j'ai trouvé ça, d'où le nommage
    time_scale=
    # récupération des logs temporaires
    print "Saisissez la liste des namespaces à interroger, séparés par des espaces : "
    exemple
    read -r ALL_NAMESPACES
    print "Indiquer la durée sur laquelle vous souhaitez consulter les logs de ${ORANGE_STYLE} ${ALL_NAMESPACES[@]} ${PROMPT_STYLE} 
    -- > 15m , 30m , 1h , 6h, 2h30m :"
    read is_it_hope_or_madness 
    print "Si vous le souhaitez, ajoutez un suffixe au nom de dossier ${LOG_FOLDER}, ou laisser vide :" 
    read LOG_FOLDER_SUFFIX
    print "Récupération des logs de ${ALL_NAMESPACES[@]} "
    if [[ ${LOG_FOLDER_SUFFIX} ]]; then 
        LOG_FOLDER=${LOG_FOLDER}_${LOG_FOLDER_SUFFIX}
    fi
    print "création de ${LOG_FOLDER}"
    mkdir -p ${LOG_FOLDER}
    echo -e "${BLUE_STYLE} ----------------------------- ${RAZ_STYLE}"
    if [[ $is_it_hope_or_madness ]]; then 
        time_scale="--since=${is_it_hope_or_madness}"
        # on peut sans doute rajouter un --before= ici si besoin
    fi
    for NAMESPACE in ${ALL_NAMESPACES[@]}; do
        ALL_PODS=( $(kubectl get pods -n ${NAMESPACE} --no-headers -o custom-columns=":metadata.name") )
        for pod in ${ALL_PODS[@]}; do
            echo -e "${BLUE_STYLE} kubectl -n ${NAMESPACE} logs ${time_scale} ${pod} ${RAZ_STYLE}"
            POD_LOG_TEMP_FILE=${LOG_FOLDER}/${pod}.log
            kubectl -n ${NAMESPACE} logs ${time_scale} ${pod} > ${POD_LOG_TEMP_FILE}
            if [ -s ${POD_LOG_TEMP_FILE} ]; then 
                count_log_occurences_by_log_level ${POD_LOG_TEMP_FILE}
            else 
                rm -f ${POD_LOG_TEMP_FILE}
                echo -e "${ORANGE_STYLE} le log est vide ${RAZ_STYLE}" 
            fi
        done
    done
    echo -e "${BLUE_STYLE} ----------------------------- ${RAZ_STYLE}"
    print "Vous pouvez utiliser la recherche dans l'arborescence ${LOG_FOLDER} pour analyser ces logs"

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
echo -e "${BLUE_STYLE}   _ _ _____________/_/  |_|(_)_/ |_|(_)_/_(_)...${ORANGE_STYLE}Sur PFS !  ${RAZ_STYLE}"
echo -e "${BLUE_STYLE}   _ _ ___________________________________________ _ _ _ _ ${RAZ_STYLE}"
ready_steady_go
echo -e "${BLUE_STYLE}          $(date) ${RAZ_STYLE}"
echo

doc "Pour lister les paths utilisés par le script, ctrl+c puis tapez [ grep \"='/\" $0 ] "
display_warning_if_root
while :; do
    print_separator
    print_menu_item "n°" "Fonction"
    print_separator
    print_menu_item 1 "Obtenir les logs et compteurs, multi-namespace"
    print_menu_item 2 "Connexion postgres sur un pod"
    print_menu_item 3 "Aide à la réception de livraison"
    print_menu_item 4 "Recherche de patterns texte dans une arborescence, récursif"
    print_menu_item 5 "Extraction des topics kafka"
    print_menu_item 6 "CR redmine de statut d'un namespace"
    print_menu_item 7 "Rechercher la valeur d'un token dans les pods d'un namespace"
    print_menu_item "café "   "Le coffee-timer dont vous avez toujours rêvé"
    print_menu_item "exit "   "Quitter le script"
    print_menu_item "del "  "Supprimer ce script (pour laisser le serveur propre)"
    print_separator
    print "Pour voir l'implémentation d'une option, tapez 'NORUN' devant le numéro de commande"
    print "Exemple : NORUN3"
    print "Entrez un numéro de commande : "

    # par précaution, on reset command
    command=
    echo -ne "${BLUE_STYLE} # "
    read -r -p "" command
    echo -e "${RAZ_STYLE}"
    case $command in
    1) get_several_namespaces_logs ;;
    2) connect_psql ;;
    3) autoconformite_livraison_pfs ;;
    4) find_word_in_files ;;
    5) extract_kafka_topics_from_namespace ;;
    6) extract_namespace_pods_state_for_redmine ;;
    7) extract_configuration_from_namespace ;;
    NORUN1) no_run get_several_namespaces_logs ;;
    NORUN2) no_run connect_psql ;;
    NORUN3) no_run autoconformite_livraison_pfs ;;
    NORUN4) no_run find_word_in_files ;;
    NORUN5) no_run extract_kafka_topics_from_namespace ;;
    NORUN6) no_run extract_namespace_pods_state_for_redmine ;;
    NORUN7) no_run extract_configuration_from_namespace ;;
    café) coffee ;;
    NORUNcafé) no_run coffee ;;
    clean)
        rm -i $0
        break
        ;;
    exit) exit_ok ;;
    *) print_title "Merci de saisir une commande dans la plage des valeurs prévues" ;;
    esac
    print_again
done

# il n'y a plus rien a lire, si vous avez aimé l'histoire pensez à me sponsoriser sur tipee