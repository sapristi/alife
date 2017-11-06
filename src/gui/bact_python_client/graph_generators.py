
from graphviz import Digraph

class ProtGraph(Digraph):
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

            
            for t in transition["dep_places"]:
                if t["type"][0] == "Regular_ilink":
                    label = "reg"
                elif t["type"][0] == "Split_ilink":
                    label = "split"
                elif t["type"][0] == "Filter_ilink":
                    label = "filter " + t["type"][1]
                
                self.edge('p'+str(t["place"]), tname, color = color, label = label)

            for t in transition["arr_places"]:
                if t["type"][0] == "Regular_olink":
                    label = "reg"
                elif t["type"][0] == "Bind_olink":
                    label = "bind"
                elif t["type"][0] == "Release_olink":
                    label = "release " + t["type"][1]
                    
                self.edge(tname, 'p'+str(t["place"]), color = color, label = label)
