
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

This project includes a webserver, written in OCaml, as well as a web client, written in Rescript.

<a id="org7fc668f"></a>

# Setting up

You will need a working OCaml developping environment, 
ideally set-up with opam. Dune is used as a build system.


<a id="orga9e77e6"></a>

## OCaml libs dependancies

See output of `dune build`

<a id="org195421f"></a>

## Building and running

Running `dune build @local_install` will output the `yaacs_server` binary as well as the client and some data into the `./dist` directory. You can then launch the program with 

```bash
cd ./dist
./yaacs_server
```

By default, the server will be accessible on `http://localhost:1512`.

Run `./yaacs_server --help` to see available options.

### Build the server

Run `dune build`

### Build the client

Rune `dune build @client`

## Dev mode for the client

 * Run `yarn install` from the root dir to install the dependancies.
 * Run `bsb -make-world -w` to build rescript files into javascript (watch mode)
 * From `.src/gui/client`, run `yarn server` to serve the built files
 * Run the server
