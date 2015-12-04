

misc_library: 	src/misc_library.ml
		ocamlc Random.cma -c src/misc_library.ml
		mv src/misc_library.cmo src/misc_library.cmi build
		ocamlc -a build/misc_library.cmo -o build/misc_library.cma


molecule:	src/molecule.ml
		ocamlc -I build build/misc_library.cma -c src/molecule.ml
		mv src/molecule.cmo src/molecule.cmi build
		ocamlc -a build/molecule.cmo -o build/molecule.cma

proteine : 	src/proteine.ml	
		ocamlc -I build build/misc_library.cma build/molecule.cma -c src/proteine.ml
		mv src/proteine.cmo src/proteine.cmi build