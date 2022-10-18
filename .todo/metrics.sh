#!/bin/ksh

####################################################################
## metrics.sh ##
## $1 : le nom du script a encapsuler
## $2 : les parametres de $1
## $3 : le nom du fichier de metrics
## $4 : le nom de fichier de sortie du script encapsule
# allez voir ganglia
####################################################################

## fonctions

# Mise en forme du rapport
separator() {
    echo "-----------------------------------"
}
## Verification des parametres ##

if [ $# -lt 4 ]; then
    echo "## metrics.sh ##"
    echo "## ${1} : le nom du script a encapsuler"
    echo "## ${2} : les parametres de ${1}"
    echo "## ${3} : le nom du fichier de metrics"
    echo "## ${4} : le nom de fichier de sortie du script encapsule"
    exit 1
fi

## Creation des fichiers de sortie ##

touch "$3"
echo "${1} ${2}" >>$3 # Reinitialise le fichier
touch "$4" >>$3

## Initialisation des compteurs ##

STARTTIME=$(date +%s%N)

## Affichage des caracteristiques de l'environnement ##

# echo $(hostnamectl) >> $3 # commande pour centos, renvoie No such file or directory sur windows subsytem
separator >>$3
echo "Nombre de coeurs : $(cat /proc/cpuinfo | grep -i "^processor" | wc -l) coeurs" >>$3
echo "Frequence : $(cat /proc/cpuinfo | grep -i "^cpu MHz" | awk -F": " '{print $2}' | head -1) Hz" >>$3
#echo "Utilisation des processeurs 'a froid' : $(cat <(grep 'cpu ' /proc/stat) <(sleep 1 && grep 'cpu ' /proc/stat) | awk -v RS="" '{print ($13-$2+$15-$4)*100/($13-$2+$15-$4+$16-$5) "%"}')" >> $3
echo "Memoire disponible sur la machine :" >>$3
echo "$(cat /proc/meminfo | head -n 2)" >>$3
separator >>$3
## Execution du script encapsule ##

echo "${1} ${2} starts at ${STARTTIME}"

logfile=$(mktemp)
./$1 $2 >>$4 && echo 0 >$logfile & # permet de boucler en attendant la fin d'une commande (https://unix.stackexchange.com/questions/124106/shell-script-wait-for-background-command)
## Wait for it. The [ ! -s $logfile ] is true while the file is
## empty. The -s means "check that the file is NOT empty" so ! -s
## means the opposite, check that the file IS empty. So, since
## the command above will print into the file as soon as it's finished
## this loop will run as long as  the previous command si runnning.
while [ ! -s $logfile ]; do
    #CPU_USAGE=`cat <(grep 'cpu ' /proc/stat) <(sleep 1 && grep 'cpu ' /proc/stat) | awk -v RS="" '{print ($13-$2+$15-$4)*100/($13-$2+$15-$4+$16-$5) "%"}'`
    CURRENTTIME=$(date +%s%N)
    CURRENTDURATION=$(((CURRENTTIME - STARTTIME) / 1000))
    echo "$((CURRENTDURATION / 1000)) millisecondes :" >>$3
    echo $(cat /proc/meminfo | head -n 2) >>$3
    #echo "Utilisation des processeurs : $CPU_USAGE" >> $3
    sleep 30
done

separator >>$3

## Enregistrement des compteurs ##
ENDTIME=$(date +%s%N)
DURATION=$(((ENDTIME - STARTTIME) / 1000000))
echo "Temps d'execution : ${DURATION} millisecondes" >>$3
if [ $DURATION -gt 3000 ]; then
    echo "Le script s'est execute en $((DURATION / 1000)) secondes"
else
    echo "Le script s'est execute en ${DURATION} millisecondes"
fi

exit 0
