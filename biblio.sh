#!/usr/bin/env bash

###################################################
# Fonctions pour debogage et traitement des erreurs.
###################################################


# Pour generer des traces de debogage avec la function debug, il
# suffit de supprimer le <<#>> au debut de la ligne suivante.
#DEBUG=1

function debug {
    [[ -z $DEBUG ]] && return

    echo -n "[debug] "
    for arg in "$@"
    do
        echo -n "'$arg' "
    done
    echo ""
}

function erreur {
    msg=$1

    # A COMPLETER: Les erreurs doivent etre emises stderr... ce qui
    # n'est pas le cas pour l'instant!
    echo "*** Erreur: $msg" >&2
    echo "" >&2

    # On emet le message d'aide si commande fournie invalide.
    # Par contre, ce message doit etre emis sur stdout.
    [[ $msg =~ Commande\ inconnue ]] && aide
 
    exit 1
}


###################################################
# Fonction d'aide: fournie, pour uniformite.
###################################################

function aide {
    cat <<EOF
NOM
  $0 -- Script pour la gestion de prets de livres

SYNOPSIS
  biblio.sh [--depot=fich] commande [options-commande] [argument...]

COMMANDES
  aide           - Emet la liste des commandes
  emprunter      - Indique l'emprunt d'un livre
  emprunteur     - Emet l'emprunteur d'un livre
  emprunts       - Emet les livres empruntes par quelqu'un
  init           - Cree une nouvelle base de donnees pour gerer des livres empruntes
                   (dans './.biblio.txt' si --depot n'est pas specifie)
  indiquer_perte - Indique la perte du livre indique
  lister         - Emet l'ensemble des livres empruntes
  rapporter      - Indique le retour d'un livre
  trouver        - Trouve le titre complet d'un livre 
                   ou les titres qui contiennent la chaine
EOF
}

###################################################
# Fonctions pour manipulation du depot.
#
# Fournies pour simplifier le devoir et assurer au depart un
# fonctionnement minimal du logiciel.
###################################################

function assert_depot_existe {
    depot=$1
    [[ -f $depot ]] || erreur "Le fichier '$depot' n'existe pas!%"
}


function init {
    depot=$1
    if [[ $2 =~ --detruire ]]; then
        nb_options=1
    else
        nb_options=0
    fi

    if [[ -f $depot ]]; then
        # Depot existe deja
        if [[ $nb_options == 1 ]]; then
            # On le detruit quand --detruire est specifie.
            $( \rm -f $depot )
        else
            erreur "Le fichier '$depot' existe. Si vous voulez le detruire, utilisez 'init --detruire'."
        fi
    fi

    # On 'cree' le fichier vide.
    $( touch $depot )

    return $nb_options
}

###################################################
# Les fonctions pour les diverses commandes de l'application.
#
# A COMPLETER!
###################################################

function lister {
    if [[ $2 =~ "--inclure_perdus" ]]
    then
        awk -F% '{print $1 " :: [ " $4 " ] \"" $3 "\" " $5}' $1
        return 1
    else
        grep -v "<<PERDU>>$" $1 | awk -F% '{print $1 " :: [ " $4 " ] \"" $3 "\""}'
        return 0
    fi
}


function emprunter {
    if [[ $3 =~ "@" ]]
	then
        mail=$3
    else
        mail="@"
    fi

    echo "$2%$mail%$4%$5%" >> $1
		 
    return 4
}

function emprunteur {
    if [[ `grep -Ec "$2" "$1"` > 0 ]]
    then
        grep -E "$2" "$1" | awk -F% '{print $1}'
    else    
        erreur "Aucun livre emprunte avec le titre $2"
    fi
    return 1
}

function trouver {
    if [[ `grep -Eic "^.*%.*%.*$2.*%.*%" "$1"` > 0 ]]
    then
        grep -Ei "^.*%.*%.*$2.*%.*%" "$1" | awk -F% '{print $3}'
    else    
        erreur "Aucun livre avec le titre $2"
    fi
    return 1
}

function emprunts {
    grep -E "$2" "$1" | awk -F% '{print $3}'
    return 1
}

function rapporter {
    sed -i "/^.*%.*%$2%.*%/d" $1
    return 1
}


function indiquer_perte {
    sed -i "s/^.*%.*%$2%.*%$/&<<PERDU>>/" $1
    return 1
}

#######################################################
# Le programme principal
#######################################################

#
# Strategie utilisee pour uniformiser les appels de commande : Une
# commande est mise en oeuvre par une fonction auxiliaire. Cette
# fonction retourne comme statut le nombre d'arguments ou options
# utilisees par la commande.
#
# Ceci permet par la suite, dans l'appelant, de "shifter" les
# arguments et, donc, de verifier si des arguments superflus ont ete
# fournis.
#

# On definit le depot a utiliser.
commande=$1
if [[ $commande =~ "--depot" ]]
then
	depot=${commande#*=}
	shift
fi
depot=${depot:=.biblio.txt}  # Depot par defaut = .biblio.txt
debug "On utilise le depot suivant:", $depot


#
# On analyse la commande (= dispatcher).
#
commande=$1
shift
case $commande in
    ''|aide)
        aide
        ;;

    emprunter)
        emprunter $depot "$@"
        shift $?
        ;;

    emprunteur)
        emprunteur $depot "$@"
        shift $?
        ;;

    emprunts)
        emprunts $depot "$@"
        shift $?
        ;;

    indiquer_perte)
        indiquer_perte $depot "$@"
        shift $?
        ;;

    init)
        init $depot $1
        shift $?
        ;;

    lister)
        lister $depot "$@"
        shift $?
        ;;

    rapporter)
        rapporter $depot "$@"
        shift $?
        ;;

    trouver)
        trouver $depot "$@"
        shift $?
        ;;
    
    *) 
        erreur "Commande inconnue: '$commande'"
        ;;
esac

[[ $# == 0 ]] || erreur "Argument(s) en trop: '$@'"


