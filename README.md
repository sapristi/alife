<div id="table-of-contents">
<h2>Table of Contents</h2>
<div id="text-table-of-contents">
<ul>
<li><a href="#sec-1">1. Setting up</a>
<ul>
<li><a href="#sec-1-1">1.1. Stuff to installlll Using opam, install</a></li>
<li><a href="#sec-1-2">1.2. Usefull stuff</a></li>
</ul>
</li>
<li><a href="#sec-2">2. Intro</a>
<ul>
<li><a href="#sec-2-1">2.1. Résumé des épisodes précédents</a></li>
<li><a href="#sec-2-2">2.2. Où l'on essaie de préparer un autre épisode</a></li>
<li><a href="#sec-2-3">2.3. Trucs importants à garder en tête</a></li>
</ul>
</li>
<li><a href="#sec-3">3. Description de ce que j'essaie de faire</a>
<ul>
<li><a href="#sec-3-1">3.1. But</a></li>
<li><a href="#sec-3-2">3.2. Mise en œuvre</a>
<ul>
<li><a href="#sec-3-2-1">3.2.1. Modèle pour les molécules et la formation du réseau de pétri</a></li>
<li><a href="#sec-3-2-2">3.2.2. Modèle pour les protéines</a></li>
</ul>
</li>
<li><a href="#sec-3-3">3.3. Processus de reflexion sur comment faire avancer le schmilblick en cours</a>
<ul>
<li><a href="#sec-3-3-1">3.3.1. Dans le fichier proteine.ml</a></li>
<li><a href="#sec-3-3-2">3.3.2. Ribosome</a></li>
<li><a href="#sec-3-3-3">3.3.3. Dans un futur lointain</a></li>
</ul>
</li>
</ul>
</li>
<li><a href="#sec-4">4. Stuff to do</a>
<ul>
<li><a href="#sec-4-1">4.1. <span class="done DONE">DONE</span> v0.0.0</a>
<ul>
<li><a href="#sec-4-1-1">4.1.1. <span class="done DONE">DONE</span> ajouter des arcs entre tous les nœuds dans le client ?</a></li>
<li><a href="#sec-4-1-2">4.1.2. <span class="done DONE">DONE</span> Clarifier les dénominations, en particulier input et output links</a></li>
<li><a href="#sec-4-1-3">4.1.3. <span class="done DONE">DONE</span> Bugs quand le client demande une transition et que ce n'est pas possible</a></li>
</ul>
</li>
<li><a href="#sec-4-2">4.2. v0.0.1</a>
<ul>
<li><a href="#sec-4-2-1">4.2.1. <span class="done DONE">DONE</span> reconstruire les types d'acides</a></li>
<li><a href="#sec-4-2-2">4.2.2. <span class="done DONE">DONE</span> définir et utiliser une convention de nommage qui sépare clairement</a></li>
<li><a href="#sec-4-2-3">4.2.3. <span class="todo TODO">TODO</span> documenter et implémenter ce qui découle de la nouvelle implémentation</a></li>
</ul>
</li>
</ul>
</li>
</ul>
</div>
</div>

# Setting up<a id="sec-1" name="sec-1"></a>

## Stuff to installlll Using opam, install<a id="sec-1-1" name="sec-1-1"></a>

-   batteries
-   ppx<sub>deriving</sub>.show
-   ppx<sub>deriving</sub>.yojson

Also requires OCaml, python3 with python3-graphviz and python3

## Usefull stuff<a id="sec-1-2" name="sec-1-2"></a>

Installed with opam :
-   merlin (completion and errors detection in emacs)
-   utop (advanced top-level)

Source files are commented using the outshine emacs mode

# Intro<a id="sec-2" name="sec-2"></a>

Du coup, on veut ici créer un programme qui réalise le rêve de
la vie artificielle :
héberger et simuler des cellules qui vont évoluer afin de recréer
la vie *in silico* (on peut toujours rêver).

## Résumé des épisodes précédents<a id="sec-2-1" name="sec-2-1"></a>

Il y a eu plusieurs essais dans ce sens : 
-   Tierra : 
    -   Le monde est un tableau unidimensionnel. Chaque case est soit vide, 
        soit contient une instruction, parmi un jeu d'instruction bien choisi.
    
    -   Les cellules sont un ensemble contigu de cases, et donc des 
        instructions qu'elles contiennent.
    
    Le jeu d'instruction permet aux cellules de lire n'importe où, mais pas 
    d'écrire à l'intérieur d'autres cellules. Les cellules se dupliquent en 
    recopiant leur code génétique vers une partie vide de la bande.
    
    -   Chaque cellule a son processeur propre, qui simule l'exécution de son code.
    
    -   Comportements apparus : spécialisation, parasitage, un peu de complexification

-   Des trucs d'Hutton : 
    -   Le monde est un tableau bidimensionnel. Le monde contient des atomes, 
        qui peuvent se déplacer plus ou moins librement.
    
    -   Les atomes ont un type donné, et un état qui peut varier au cours 
        du temps. Un jeu de réactions chimique, qui détermine si deux atomes 
        de type et d'état donné qui se rencontrent vont former une liaison. 
        Jeu de réactions chimiques bien choisi.
    
    -   Les cellules ont une membrane qui forme un cercle, et un brin d'ADN, 
        relié à ses deux extrémités à la membrane. Les cellules se dupliquent 
        de manière spontanée grâce aux réactions chimiques.
    
    -   Le monde est simulé *physiquement*, c'est à dire chaque atome 
        séparemment, et rien d'autre.
    
    -   Comportements apparus : pas grand chose, à part une légère réduction 
        de l'ADN.

En résumé, Tierra s'est montré prometteur, mais est beaucoup plus proche
d'un ordinateur que d'une cellule. On manque en particulier de capacité 
de réaction, de communication, etc&#x2026;

Hutton est très proche en quelques sorte de la biologie, mais 
ça ne marche pas très bien. Sans parler des coûts de simulation faramineux, 
ni du jeu de réactions chimiques tellement alambiqué pour que ça marche 
que c'en est un peu absurde. 

## Où l'on essaie de préparer un autre épisode<a id="sec-2-2" name="sec-2-2"></a>

Ce que j'aimerait faire, c'est un modèle qui soit à la fois proche du 
fonctionnement des ordinateurs (c'est à dire en particulier avec une 
physique très simple, sans avoir besoin de simuler des choses à un 
niveau très bas), et qui reflète le principe de fonctionnement 
d'une cellule autant qu'il est souhaitable et possible.

Une première idée à été de faire un peu comme Tierra, mais en plus 
de dimensions. Une cellule est une matrice, où les fonctions sont
des instructions qui pointent vers la suivante (contiguë). En trois
dimensions, ça peut commencer à donner des trucs assez rigolos, 
mais gérer la duplication semble devenir complexe. On perds aussi 
la bonne relation qui existait entre les cellules et l'univers.

La deuxième idée est d'utiliser des modèles complutationnels simples pour
simuler les protéines. Partant des automates, j'en suis arrivé aux réseaux
de Petri, qui me semblent assez prometteurs. 
On le décrira plus précisement par la suite.

## Trucs importants à garder en tête<a id="sec-2-3" name="sec-2-3"></a>

Les membranes, c'est la vie en plus tranquille.
La communication, c'est la vie en plus rigolo.
La vie tout court, c'est déjà pas mal.
Les ribosomes, c'est trop l'éclate.

# Description de ce que j'essaie de faire<a id="sec-3" name="sec-3"></a>

## But<a id="sec-3-1" name="sec-3-1"></a>

Le but est d'avoir un modèle unifié de molécules, qui permettent à la fois
d'avoir des molécules qui :
-   représentent de l'information (ADN)
-   puissent agir sur d'autres molécules (protéines, enzymes), et plus précisement 
    -   Découper une molécule
    -   Insérer une molécule dans une autre
    -   Lire de l'information écrite sur une molécule
-   puissent échanger de l'information (métabolites)

Enfin en vrai le but c'est de faire des **RIBOSOMES**, ne l'oublions pas.

## Mise en œuvre<a id="sec-3-2" name="sec-3-2"></a>

Le modèle proposé est d'avoir tout d'abord des molécules sous forme de liste
d'acides (aminés), chaque acide contenant soit de l'information, soit un
morceau qui permette de reconstituer les fonctionnement de la molécule : 
on veut la **replier** pour obtenir une protéine. Une fois repliée, on aurait
un truc qui ressemble fort à un réseau de Petri (plutôt un peu étendu).

Un des trucs cool, c'est qu'on peut faire des **ribosomes** ! Et donc permettre
à la duplication elle même d'évoluer.

### Modèle pour les molécules et la formation du réseau de pétri<a id="sec-3-2-1" name="sec-3-2-1"></a>

Une molécule est donc formée par une liste d'acide, dont le role va être de
-   former des place du réseau de Pétri,
-   contribuer à former des transitions du réseau
-   contenir de l'information

Après une opération de repli, on pourra attribuer à une molécule sa forme 
protéinée, un réseau de pétri (graphe biparti). Il y a plusieurs moyens 
d'organiser une molécule et la façon dont elle se replie, on va donc 
détailler et justifier un peu le processus.

1.  Différentes idées

    Tous les acides de la molécule forment une place, et se retrouvent donc 
    au même niveau. Des places particulières contiennent un arc entrant ou un
    arc sortant. Plusieurs inconvénients : 
    -   Ça limite fortement les fonctionnalités d'une protéine
    -   Un seul arc entrant ou sortant par place
    
    Du coup, il faut pouvoir ajouter des attributs à une place. Ou pourrait
    faire ça de manière interne, mais on précisera dans la partie suivante
    pourquoi on choisira ici une mméthode externe.

2.  Modèle retenu

    On fonctionnera de manière modulaire, avec les types d'acide suivants :
    -   place : correspond à une place du réseau de pétri. On pourra fournir
    
    un attribut interne pour effectuer certaines actions
    -   transition<sub>input</sub>/output : ajoute un arc sortant/entrant
    -   extension : ajoute un attribut à la place précédente dans la molécule. 
        Quelques types d'extension : 
        -   information : un morceau d'information
        -   autre ? action ?
    
    Les avantages sont les suivants : 
    -   facile à étendre
    -   du point de vue des mutations possibles, on a facilement des changements de fonctionnalité
        
        <div class="inlinetask">
        <b><span class="todo TODO">TODO</span> Un **GROS PROBLÈME**:</b><br  />
        nil</div>
    
    Que se passe-t-il si plusieurs transtions input avec la même id partent d'un même nœud, en  
    particulier pour la gestion des token ?
    Plusieurs pistes :
    -   la transition n'est pas crée
    -   seul un des arcs est pris en compte
    -   utiliser un des arcs au hasard
    -   le programme bugge

3.  Détails d'implémentation

    On part donc d'une molécule = liste d'acides.
    On parcourt la molécule pour en extraire :
    1.  d'une part la liste des nœuds, en associant à chaque nœud la liste 
        des extensions qui le suivent
    2.  d'autre part tous les arcs sont stoqués dans une liste (qui pourrait
        être remplacée par un dictionnaire) dans laquelle on stoque pour chaque
        id de transition les transitions correspondantes
    
    1.  Questions
    
        Est-ce qu'on définit un unique type extension (qui contient les transitions) ou on sépare les transitions ?
        À priori c'est pas mal de séparer puisque :
        -   les transitions font partie de la structure du réseau de pétri, au contraire des autres extensions
        -   ça permet de construire le réseau sans avoir à connaitre l'implémentation particulière des types

### Modèle pour les protéines<a id="sec-3-2-2" name="sec-3-2-2"></a>

Une protéine est donc un réseau de Pétri, c'est à dire un graphe bipartie 
(deux types de nœuds) :
-   des places, qui correspondent directement à un acide de la molécule
-   des transitions, qui sont construites implicitements à partir d'arcs 
    entrants et sortans, décrits dans la protéine

Les places contiennent des token, qui peuvent eux-même contenir une molécule 
(et de l'information, et autre ?).
Une transition peut être lancée quand toutes les places de départ de la 
transition contiennent un token, et qu'il n'y a pas de token dans les places
d'arrivée.

Les protéines doivent gérer :
1.  Le réseau de pétri, c'est à dire le déclenchement de transitions et la
    gestion des tokens qui va avec
2.  Tous les effets appliqués sur le tokens par les transitions et les extensions
3.  L'interface avec la bactérie, c'est à dire l'envoi/reception de message, et 
    l'attachement/détachement de molécules

1.  Réseau de pétri

    1.  Token et MoleculeManager
    
        Un token est soit vide, soit contient un moleculeHolder, qui est lui-même
        une interface contenant une molécule et un poiteur (entier) vers un des
        acides de la molécule, et qui permet de manipuler celle-ci : 
        -   découpage (à la position du pointeur)
        -   insertion d'une autre molécule (à la position du pointeur)
        -   déplacement du pointeur
    
    2.  Places
    
        Les places sont soit vides, soit contiennent un token. Elles gardent
        aussi en mémoire la liste des extensions associées, et implémentent 
        une interface pour gérer l'éventuel token.
        
        <div class="inlinetask">
        <b><span class="todo TODO">TODO</span> Ajouter les effets sur les tokens générés par les extensions ?</b><br  />
        nil</div>
    
    3.  Transitions
    
        Les transitions ont pour l'instant pour rôle de découper et recoller 
        des molécules. Voilà comment ça se passe :
        
        1.  Quand un token porteur passe par un arc entrant, 
            -   si le token porte une molécule et que l'arc est de type Split, 
                la molécule est coupée en deux, chaque partie est stoquée dans
                un token
            -   sinon, le token (avec l'éventuelle molécule) n'est pas modifié
        
        2.  Tous les token venant des arcs entrant sont mis dans un « pool »
            commun
        
        3.  Les token passent dans les transitions sortantes, dans un ordre
            fixe déterminé par les transitions d'arrivée : 
            -   Si deux token porteur de molécule se trouvent devant un arc de
                type Bind, la seconde molécule est insérée dans la première
            -   Sinon, un unique token passe par l'arc sortant
            -   Si il reste des token, ils sont perdus
            -   Si il n'y a pas assez de token, les places d'arrivée ne sont pas
                remplies
        
        On remarquera vite que tout ça n'a pas l'air très propre, mais en
        même temps on traite ici avec le « vivant », donc c'est un peu normal :)
        Plus sérieusement, on supposera pour l'instant que les capacités
        évolutives des bactéries ne seront pas affectées. 

## Processus de reflexion sur comment faire avancer le schmilblick en cours<a id="sec-3-3" name="sec-3-3"></a>

### Dans le fichier proteine.ml<a id="sec-3-3-1" name="sec-3-3-1"></a>

On simule l'avancement d'un réseau de Petri.

Le réseau de Petri est étendu de manière à pouvoir générer les
comportements suivants :
-   Attraper / relacher une molécule
-   Découper une molécule
-   Coller ensemble deux molécules
-   Parcourir une molécule, pour :
    -   lire les données qu'elle contient
    -   se placer au bon endroit pour la découper
-   Envoyer des messages
-   Recevoir des messages (qui vont modifier le comportement)
-   (Transmettre de l'information)

L'idée est de pouvoir associer une molécule M1 (et un emplacement de cette
molécule) à un jeton (placé sur une autre molécule M2).
Une transition de M2 pourra alors découper cette molécule M1 à l'emplacement
spécifié. Il faudra alors que deux arcs sortant associent une molécule à
leur jeton pour garder les deux parties coupées M1' et M1''. Au contraire,
si deux arcs entrants ont des jetons qui contiennent une molécule, on pourra
les recoller ensemble.

On peut aussi essayer de faire la même chose avec des morceaux d'information
associées aux jetons, je ne sais pas si c'est vraiment utile.

Pour attraper une molécule ou recevoir un message, l'idée serait d'avoir
une propriété sur les noeuds qui leur permettent de créer un jeton en
attrapant une molécule ou en recevant un message.

Une autre propriété associée aux jetons serait une énergie, mais je ne
sais pas encore bien quel rôle lui attribuer. En fait si, il faudrait que
recoller deux molécules entre elles demande de l'énergie, et que les
séparer en libère.

Pour l'instant, l'énergie sert à rien, et on la gère un peu n'importe
comment. En fait on va la virer, ce sera un peu plus propre.

Par contre, il faudrait peut-être arriver à mettre un ordre un peu plus
déterminé sur la façon dont les arcs des transitions se combinent.

### Ribosome<a id="sec-3-3-2" name="sec-3-3-2"></a>

Un ribosome est une protéine qui lit un code génétique (ADN) et construit
des protéines en fonction de l'information contenue dans l'ADN.

1.  Modèle 1

### Dans un futur lointain<a id="sec-3-3-3" name="sec-3-3-3"></a>

Pour que les bactéries puissent avoir un comportement efficace, il faudrait
qu'il y ait de l'information ambiante, qui représente plusieurs aspects du
monde alentour, que les bactéries puissent mesurer

# Stuff to do<a id="sec-4" name="sec-4"></a>

## DONE v0.0.0<a id="sec-4-1" name="sec-4-1"></a>

### DONE ajouter des arcs entre tous les nœuds dans le client ?<a id="sec-4-1-1" name="sec-4-1-1"></a>

### DONE Clarifier les dénominations, en particulier input et output links<a id="sec-4-1-2" name="sec-4-1-2"></a>

### DONE Bugs quand le client demande une transition et que ce n'est pas possible<a id="sec-4-1-3" name="sec-4-1-3"></a>

## v0.0.1<a id="sec-4-2" name="sec-4-2"></a>

### DONE reconstruire les types d'acides<a id="sec-4-2-1" name="sec-4-2-1"></a>

### DONE définir et utiliser une convention de nommage qui sépare clairement<a id="sec-4-2-2" name="sec-4-2-2"></a>

les noms de types/noms de variables/noms de modules

### TODO documenter et implémenter ce qui découle de la nouvelle implémentation<a id="sec-4-2-3" name="sec-4-2-3"></a>

des acides
