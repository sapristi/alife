import {ColaLayout} from './cytoscape-cola.mjs';

const register = (cytoscape) => {  cytoscape('layout', 'cola', ColaLayout);}

export {register}
