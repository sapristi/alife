open Client_types;

[@decco]
type commitProteineResponse = {
  mol: Types.Molecule.t,
  pnet: option(Types.Petri_net.t),
};

let commitProteine = (dispatch, proteine) =>
  Utils.Yaac.request(
    Fetch.Post,
    "/utils/build/from_prot",
    ~payload=proteine_encode(proteine),
    ~json_decode=commitProteineResponse_decode,
    (),
  )
  ->Promise.getOk(({mol, pnet}) => {
      dispatch(Store.MolBuilderAction(Set({mol, pnet, proteine})))
    });

[@decco]
type commitMoleculeResponse = {
  prot: proteine,
  pnet: option(Types.Petri_net.t),
};

let commitMol = (dispatch, mol) =>
  Utils.Yaac.request(
    Fetch.Post,
    "/utils/build/from_mol",
    ~payload=Types.Molecule.t_encode(mol),
    ~json_decode=commitMoleculeResponse_decode,
    (),
  )
  ->Promise.getOk(({prot, pnet}) => {
      dispatch(Store.MolBuilderAction(Set({mol, pnet, proteine: prot})))
    });
