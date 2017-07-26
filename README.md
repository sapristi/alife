<div id="table-of-contents">
<h2>Table of Contents</h2>
<div id="text-table-of-contents">
<ul>
<li><a href="#sec-1">1. Setting up</a>
<ul>
<li><a href="#sec-1-1">1.1. Stuff to install</a></li>
<li><a href="#sec-1-2">1.2. Usefull stuff</a></li>
</ul>
</li>
<li><a href="#sec-2">2. Tasks</a>
<ul>
<li><a href="#sec-2-1">2.1. Plein de trucs</a></li>
</ul>
</li>
<li><a href="#sec-3">3. Intro</a>
<ul>
<li><a href="#sec-3-1">3.1. Résumé des épisodes précédents</a></li>
<li><a href="#sec-3-2">3.2. Où l'on essaie de préparer un autre épisode</a></li>
<li><a href="#sec-3-3">3.3. Trucs importants à garder en tête</a></li>
</ul>
</li>
<li><a href="#sec-4">4. Description de ce que j'essaie de faire</a>
<ul>
<li><a href="#sec-4-1">4.1. But</a></li>
<li><a href="#sec-4-2">4.2. Processus de reflexion sur comment faire avancer le schmilblick en cours</a>
<ul>
<li><a href="#sec-4-2-1">4.2.1. Dans le fichier molecule.ml</a></li>
<li><a href="#sec-4-2-2">4.2.2. Dans le fichier proteine.ml</a></li>
<li><a href="#sec-4-2-3">4.2.3. Dans un futur lointain</a></li>
</ul>
</li>
<li><a href="#sec-4-3">4.3. </a>
<ul>
<li><a href="#sec-4-3-1">4.3.1. Acide aminé</a></li>
<li><a href="#sec-4-3-2">4.3.2. Molécule</a></li>
</ul>
</li>
</ul>
</li>
<li><a href="#sec-5">5. Stuff to do</a>
<ul>
<li>
<ul>
<li><a href="#sec-5-0-1">5.0.1. <span class="done DONE">DONE</span> ajouter des arcs entre tous les nœuds dans le client ?</a></li>
<li><a href="#sec-5-0-2">5.0.2. <span class="done DONE">DONE</span> Clarifier les dénominations, en particulier input et output links</a></li>
<li><a href="#sec-5-0-3">5.0.3. <span class="done DONE">DONE</span> Bugs quand le client demande une transition et que ce n'est pas possible</a></li>
<li><a href="#sec-5-0-4">5.0.4. <span class="todo TODO">TODO</span> Modifier l'organistion des molécules : laisser un seul type d'acide (place) qui sera lui agrémenté de diverses options.</a></li>
</ul>
</li>
</ul>
</li>
</ul>
</div>
</div>

# Setting up<a id="sec-1" name="sec-1"></a>

## Stuff to install<a id="sec-1-1" name="sec-1-1"></a>

Using opam, install 
-   batteries
-   ppx<sub>deriving</sub>.show
-   ppx<sub>deriving</sub>.yojson

Also requires OCaml, python3 with python3-graphviz and python3-tk

## Usefull stuff<a id="sec-1-2" name="sec-1-2"></a>

Installed with opam :
-   merlin (completion and errors detection in emacs)
-   utop (advanced top-level)

Source files are commented using the outshine emacs mode

# Tasks<a id="sec-2" name="sec-2"></a>

## Plein de trucs<a id="sec-2-1" name="sec-2-1"></a>

# Intro<a id="sec-3" name="sec-3"></a>

Du coup, on veut ici créer un programme qui réalise le rêve de la vie artificielle :
héberger et simuler des cellules qui vont évoluer afin de recréer la vie *in silico* (on peut toujours rêver).

## Résumé des épisodes précédents<a id="sec-3-1" name="sec-3-1"></a>

Il y a eu plusieurs essais dans ce sens : 
-   Tierra : 
    -   Le monde est un tableau unidimensionnel. Chaque case est soit vide, soit contient une instruction, parmi un jeu d'instruction bien choisi.
    -   Les cellules sont un ensemble contigu de cases, et donc des instructions qu'elles contiennent.
        Le jeu d'instruction permet aux cellules de lire n'importe où, mais pas d'écrire à l'intérieur d'autres cellules. Les cellules se dupliquent en recopiant leur code génétique vers une partie vide de la bande.
    -   Chaque cellule a son processeur propre, qui simule l'exécution de son code.
    -   Comportements apparus : spécialisation, parasitage, un peu de complexification

-l Des trucs d'Hutton : 
-   Le monde est un tableau bidimensionnel. Le monde contient des atomes, qui peuvent se déplacer plus ou moins librement.
-   Les atomes ont un type donné, et un état qui peut varier au cours du temps. Un jeu de réactions chimique, qui détermine si deux atomes de type et d'état donné qui se rencontrent vont former une liaison. Jeu de réactions chimiques bien choisi.
-   Les cellules ont une membrane qui forme un cercle, et un brin d'ADN, relié à ses deux extrémités à la membrane. Les cellules se dupliquent de manière spontanée grâce aux réactions chimiques.
-   Le monde est simulé *physiquement*, c'est à dire chaque atome séparemment, et rien d'autre.
-   Comportements apparus : pas grand chose, à part une légère réduction de l'ADN.

En résumé, Tierra s'est montré prometteur, mais est beaucoup plus proche d'un ordinateur que d'une cellule. On manque en particulier de capacité de réaction, de communication, etc&#x2026;
Hutton est très proche en quelques sorte de la biologie, mais ça ne marche pas très bien. Sans parler des coûts de simulation faramineux, ni du jeu de réactions chimiques tellement alambiqué pour que ça marche que c'en est un peu absurde. 

## Où l'on essaie de préparer un autre épisode<a id="sec-3-2" name="sec-3-2"></a>

Ce que j'aimerait faire, c'est un modèle qui soit à la fois proche du fonctionnement des ordinateurs (c'est à dire en particulier avec une physique très simple, sans avoir besoin de simuler des choses à un niveau très bas), et qui reflète le principe de fonctionnement d'une cellule autant qu'il est souhaitable et possible.

Une première idée à été de faire un peu comme Tierra, mais en plus de dimensions. Une cellule est une matrice, où les fonctions sont des instructions qui pointent vers la suivante (contiguë). En trois dimensions, ça peut commencer à donner des trucs assez rigolos, mais gérer la duplication semble devenir complexe. On perds aussi la bonne relation qui existait entre les cellules et l'univers.

La deuxième idée est d'utiliser des modèles complutationnels simples pour simuler les protéines. Partant des automates, j'en suis arrivé aux réseaux de Petri, qui me semblent assez prometteurs. On le décrira plus précisement par la suite.

## Trucs importants à garder en tête<a id="sec-3-3" name="sec-3-3"></a>

Les membranes, c'est la vie en plus tranquille.
La communication, c'est la vie en plus rigolo.
La vie tout court, c'est déjà pas mal.
Les ribosomes, c'est trop l'éclate.

# Description de ce que j'essaie de faire<a id="sec-4" name="sec-4"></a>

## But<a id="sec-4-1" name="sec-4-1"></a>

Le but est d'avoir un modèle unifié de molécules, qui permettent à la fois d'avoir des molécules qui :
-   représentent de l'information (ADN)
-   puissent agir sur d'autres molécules (protéines, enzymes)
-   puissent échanger de l'information (métabolites)

Le modèle proposé est d'avoir tout d'abord des molécules sous forme de liste d'acides (aminés), chaque acide contenant soit de l'information, soit un morceau qui permette de reconstituer les fonctionnement de la molécule : on veut la **replier** pour obtenir une protéine. Une fois repliée, on aurait un truc qui ressemble fort à un réseau de Petri (plutôt un peu étendu).

Un des trucs cool, c'est qu'on peut faire des **ribosomes** ! Et donc permettre à la duplication elle même d'évoluer.

## Processus de reflexion sur comment faire avancer le schmilblick en cours<a id="sec-4-2" name="sec-4-2"></a>

### Dans le fichier molecule.ml<a id="sec-4-2-1" name="sec-4-2-1"></a>

On crée un type acid (aminé), qui est :
-   soit un Node Comme on le vera dans la partie suivante, un noeud doit pouvoir recevoir des messages et attraper des molécules.
-   soit un InputLink (s,d) où s représente la transition vers laquelle l'arc pointe, et d va permettre de construire la fonction de transion. 
    Le noeud associé est le noeud précédent dans la liste d'acides qui représente la molécule.
-   soit un OutputLink (s,d) **\* à compléter \***

Une molécule est donc une liste d'acides aminés.

On définit un foncteur, qui, pour des types de Node, d'InputLink et d'OutputLink donnés, permet de replier une molécule en générant les transitions qui vont bien. Les transitions générées sont du type

    type transition = 
        string * 
           (int * inputLinkType ) array * 
           (int * outputLinkType) array

Il faut donc recréer la fonction de transition derrière, et peut-être se débarasser des inputLinkType et outputLinkType (ce qui est normal vu qu'on ne les connait pas).

Le type du foncteur en entier est :

    module type MOLECULE_TYPES = 
    sig 
      type nodeType
      type inputLinkType
      type outputLinkType
    end;;
    
    
    module MolFolcding :
      functor (MolTypes : MOLECULE_TYPES) ->
        sig
          type acid =
              Node of MolTypes.nodeType
            | InputLink of string * MolTypes.inputLinkType
            | OutputLink of string * MolTypes.outputLinkType
          type molecule = acid list
          type transition_with_lists =
              string * (int * MolTypes.inputLinkType) list *
              (int * MolTypes.outputLinkType) list
          type transition =
              string * (int * MolTypes.inputLinkType) array *
              (int * MolTypes.outputLinkType) array
          val buildTransitions : molecule -> transition list
          val buildNodesList : molecule -> MolTypes.nodeType list
        end

où 

### Dans le fichier proteine.ml<a id="sec-4-2-2" name="sec-4-2-2"></a>

On simule l'avancement d'un réseau de Petri.

Le réseau de Petri est étendu de manière à pouvoir générer les comportements suivants :
-   Attraper / relacher une molécule
-   Découper une molécule
-   Coller ensemble deux molécules
-   Parcourir une molécule, pour :
    -   lire les données qu'elle contient
    -   se placer au bon endroit pour la découper
-   Envoyer des messages
-   Recevoir des messages (qui vont modifier le comportement)
-   (Transmettre de l'information)

L'idée est de pouvoir associer une molécule M1 (et un emplacement de cette molécule) à un jeton (placé sur une autre molécule M2).
Une transition de M2 pourra alors découper cette molécule M1 à l'emplacement spécifié. Il faudra alors que deux arcs sortant associent une molécule à leur jeton pour garder les deux parties coupées M1' et M1''. Au contraire, si deux arcs entrants ont des jetons qui contiennent une molécule, on pourra les recoller ensemble.

On peut aussi essayer de faire la même chose avec des morceaux d'information associées aux jetons, je ne sais pas si c'est vraiment utile.

Pour attraper une molécule ou recevoir un message, l'idée serait d'avoir une propriété sur les noeuds qui leur permettent de créer un jeton en attrapant une molécule ou en recevant un message.

Une autre propriété associée aux jetons serait une énergie, mais je ne sais pas encore bien quel rôle lui attribuer. En fait si, il faudrait que recoller deux molécules entre elles demande de l'énergie, et que les séparer en libère.

Pour l'instant, l'énergie sert à rien, et on la gère un peu n'importe comment. En fait on va la virer, ce sera un peu plus propre.

Par contre, il faudrait peut-être arriver à mettre un ordre un peu plus déterminé sur la façon dont les arcs des transitions se combinent.

### Dans un futur lointain<a id="sec-4-2-3" name="sec-4-2-3"></a>

Pour que les bactéries puissent avoir un comportement efficace, il faudrait qu'il y ait de l'information ambiante, qui représente plusieurs aspects du monde alentour, que les bactéries puissent mesurer.

## <a id="sec-4-3" name="sec-4-3"></a>

### Acide aminé<a id="sec-4-3-1" name="sec-4-3-1"></a>

Quatre types d'acides aminés :
-   Node
-   

### Molécule<a id="sec-4-3-2" name="sec-4-3-2"></a>

Dans une cellule se trouvent des molécules (liste d'acides aminés). Celles-ci peuvent être « compilées » afin de produire une forme active, qui sera capable d'effectuer des « réactions chimiques ». 

Les d

# Stuff to do<a id="sec-5" name="sec-5"></a>

### DONE ajouter des arcs entre tous les nœuds dans le client ?<a id="sec-5-0-1" name="sec-5-0-1"></a>

### DONE Clarifier les dénominations, en particulier input et output links<a id="sec-5-0-2" name="sec-5-0-2"></a>

### DONE Bugs quand le client demande une transition et que ce n'est pas possible<a id="sec-5-0-3" name="sec-5-0-3"></a>

### TODO Modifier l'organistion des molécules : laisser un seul type d'acide (place) qui sera lui agrémenté de diverses options.<a id="sec-5-0-4" name="sec-5-0-4"></a>
