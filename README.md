<div id="table-of-contents">
<h2>Table of Contents</h2>
<div id="text-table-of-contents">
<ul>
<li><a href="#sec-1">1. Description</a></li>
<li><a href="#sec-2">2. Setting up</a>
<ul>
<li><a href="#sec-2-1">2.1. OCaml libs dependancies</a></li>
<li><a href="#sec-2-2">2.2. Install</a></li>
</ul>
</li>
<li><a href="#sec-3">3. Run</a></li>
<li><a href="#sec-4">4. Usefull stuff</a></li>
</ul>
</div>
</div>

# Description<a id="sec-1" name="sec-1"></a>

YAA is an artificial chemistry, centered around petri nets.

The project also includes a webserver that can interact 
with the simulation, and a web interface

# Setting up<a id="sec-2" name="sec-2"></a>

You will need a working OCaml developping environment, 
ideally set-up with opam.

## OCaml libs dependancies<a id="sec-2-1" name="sec-2-1"></a>

-   oasis
-   batteries
-   ppx_deriving_yojson
-   ocamlgraph
    
    (install with opam)

## Install<a id="sec-2-2" name="sec-2-2"></a>

    oasis-setup
    make

# Run<a id="sec-3" name="sec-3"></a>

`web_bact_server [-port port]`

Then visit `localhost:port`

# Usefull stuff<a id="sec-4" name="sec-4"></a>

ocaml tools (Installed with opam) :
-   merlin (completion and errors detection in emacs)
-   utop (advanced top-level)

emacs tools (installed with melpa) : 
-   outshine / outorg
-   tuareg-mode
-   graphviz-dot mode