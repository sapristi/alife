
from graphviz import Digraph

class MolGraph(Digraph):
    def __init__(self, mol_json):
        Digraph.__init__(self, format = "gif", graph_attr = {"rankdir" : "LR"})
        for i, acid in enumerate(mol_json):

            if acid[0] == "Node":
                self.node(str(i), label = "", shape = "square")

            elif acid[0] == "TransitionInput":
                
                self.node(str(i), label = "", shape = "triangle")
                self.node(acid[1]+str(i), shape = "plaintext", label = acid[1])
                self.edge(str(i), acid[1]+str(i))
                
            elif acid[0] == "TransitionOutput":
                self.node(str(i), label = "", shape = "invtriangle")
                self.node(acid[1]+str(i), shape = "plaintext", label = acid[1])
                self.edge(acid[1]+str(i), str(i))
                
            elif acid[0] == "Extension":
                self.node(str(i), shape = "circle", label="")

            if i>0:
                self.edge(str(i-1), str(i))

class PetriGraph(Digraph):
    
    def __init__(self, desc):
        Digraph.__init__(self, format = "gif")
        self.desc = desc

        temp_place = None
        # crée les nœuds correspondant aux places, et des arcs entre celles-ci
        for i, place in enumerate(desc["places"]):
            if place["token"] == "no token":
                shape = "circle"
                label = ""
            else:
                shape = "doublecircle"
                label = str(place["token"]["id"])

            self.node('p'+str(i), label = label, shape=shape)

            
        # ajoute les nœuds correspondant aux transitions, et les arcs correspondants 
        for i, transition in enumerate(desc["transitions"]):
            if i in self.desc["launchables"]:
                color = "red"
            else :
                color = "black"
                
            tname = 't'+str(i)
            self.node(tname, color = color, shape = "rectangle")
            print(str(transition))
            for node_id, trans_t in transition["dep_places"].items():
                if trans_t[0] == "Regular_ilink":
                    label = "reg"
                elif trans_t[0] == "Split_ilink":
                    label = "split"
                elif trans_t[0] == "Filter_ilink":
                    label = "filter " + trans_t[1]
                
                self.edge('p'+str(node_id), tname, color = color, label = label)

            for node_id, trans_t in transition["arr_places"].items():
                if trans_t[0] == "Regular_olink":
                    label = "reg"
                elif trans_t[0] == "Bind_olink":
                    label = "bind"
                elif trans_t[0] == "Release_olink":
                    label = "release " + trans_t[1]
                    
                self.edge(tname, 'p'+str(node_id), color = color, label = label)
