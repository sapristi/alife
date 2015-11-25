molecule:	src/molecule.ml
		ocamlc -I build build/misc_library.cma -c src/molecule.ml


misc_library: 	src/misc_library.ml
		ocamlc -c src/misc_library.ml
		ocamlc -a src/misc_library.cmo -o src/misc_library.cma
