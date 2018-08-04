
# Table of Contents

1.  [Description](#orgb5ea693)
2.  [Setting up](#orgfb35a01)
    1.  [OCaml libs dependancies](#org2787841)
    2.  [Install](#org16b46a1)
3.  [Run](#org84907c0)
4.  [Usefull stuff](#org8a5ad16)
5.  [todo](#org1e4a0e5)


<a id="orgb5ea693"></a>

# Description

YAA is an artificial chemistry, centered around petri nets.

The project also includes a webserver that can interact 
with the simulation, and a web interface


<a id="orgfb35a01"></a>

# Setting up

You will need a working OCaml developping environment, 
ideally set-up with opam.


<a id="org2787841"></a>

## OCaml libs dependancies

-   oasis
-   batteries
-   ppx_deriving_yojson
-   ocamlgraph
-   re
-   logs
-   ocamlnet

(install with opam)


<a id="org16b46a1"></a>

## Install

    oasis-setup
    make


<a id="org84907c0"></a>

# Run

`web_bact_server [-port port]`

Then visit `localhost:port`


<a id="org8a5ad16"></a>

# Usefull stuff

ocaml tools (Installed with opam) :

-   merlin (completion and errors detection in emacs)
-   utop (advanced top-level)

emacs tools (installed with melpa) : 

-   outshine / outorg
-   tuareg-mode
-   graphviz-dot mode


<a id="org1e4a0e5"></a>

# todo

-   implement a graph to manage reactions and reaction rates
-   logging system
-   errors to allow evolution
-   extended pnets and membranes

