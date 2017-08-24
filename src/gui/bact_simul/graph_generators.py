
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
        for i, val in enumerate(desc["places"]):
            self.node('p'+str(i), "{place" + str(val["id"]) + "|" + str(val["token"]) + "}", shape="record")

            if i>0:
                self.edge('p'+str(i-1), 'p'+str(i), constraint = "false")
            
        # ajoute les nœuds correspondant aux transitions, et les arcs correspondants 
        for i, val in enumerate(desc["transitions"]):
            if i in self.desc["launchables"]:
                color = "red"
            else :
                color = "black"
            
            tname = 't'+str(i)
            self.node(tname, color = color)
            for valbis in val["dep_places"]:
                self.edge('p'+str(valbis[0]), tname, color = color)

            for valbis in val["arr_places"]:
                self.edge(tname, 'p'+str(valbis[0]), color = color)
