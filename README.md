
# Table of Contents

1.  [Description](#org4a509e6)
2.  [Setting up](#org7fc668f)
    1.  [OCaml libs dependancies](#orga9e77e6)
    2.  [Install](#org195421f)
3.  [Run](#org26734a9)
4.  [Usefull stuff](#org17caa74)


<a id="org4a509e6"></a>

# Description

YAACS is an artificial chemistry simulator, centered around petri nets.

The project also includes a webserver that can interact 
with the simulation, and a web interface


<a id="org7fc668f"></a>

# Setting up

You will need a working OCaml developping environment, 
ideally set-up with opam. Dune is used as a build system.


<a id="orga9e77e6"></a>

## OCaml libs dependancies

-   oasis
-   batteries
-   ppx<sub>deriving</sub>
-   ppx_deriving_yojson
-   ocamlgraph
-   re
-   logs
-   ocamlnet

(install with opam)


<a id="org195421f"></a>

## Install

    dune build


<a id="org26734a9"></a>

# Run

`yaacs_server [-port port]`

Then visit `localhost:port`


<a id="org17caa74"></a>

# Usefull stuff

ocaml tools (Installed with opam) :

-   merlin (completion and errors detection in emacs)
-   utop (advanced top-level)
-   dune

emacs tools (installed with melpa) : 

-   outshine / outorg
-   tuareg-mode

