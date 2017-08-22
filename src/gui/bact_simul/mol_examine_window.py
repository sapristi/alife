
import json
import tkinter as tk


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

                
class MolFrame(tk.Frame):
    def __init__(self, root, mol_desc, host):
        tk.Frame.__init__(self, root)
        self.root = root
        self.host = host
        self.pack()
        self.mol_desc = mol_desc

        self.host.nc.send_request(
            json.dumps({"command" : "give prot desc",
                        "return target" : mol_desc["name"],
                        "data" : mol_desc["mol_json"]}
            ))
                                                   
        mol_graph = MolGraph(mol_desc["mol_json"])
        mol_graph.render(filename=mol_desc["name"]+"_mol_image")
        self.createWidgets()
        
        self.root.title("Molécule " + mol_desc["name"])
        

    def recv_msg(self, json_msg):
        purpose = json_msg["purpose"]
        data = json_msg["data"]
        if purpose == "prot desc":
            print("received proteine description")
            petri_graph = PetriGraph(data)
            petri_graph.render(filename=self.mol_desc["name"]+"_petri_image")
            print("petri graph generated")
            self.petriImage_img = tk.PhotoImage(file=self.mol_desc["name"]+"_petri_image.gif")
            self.petriImage_cv.config(width=self.petriImage_img.width(), height = self.petriImage_img.height())
            self.petriImage_cv.create_image(0,0,anchor="nw", image=self.petriImage_img)
            
        
    def createWidgets(self):
        
        #canvas pour dessiner
        petriImage_frame = tk.LabelFrame(self, text = "Petri net")
        self.petriImage_cv = tk.Canvas(petriImage_frame)
        self.petriImage_cv.pack()

        molImage_frame = tk.LabelFrame(self, text = "molecule")
        self.molImage_img = tk.PhotoImage(file=self.mol_desc["name"]+"_mol_image.gif")
        self.molImage_cv = tk.Canvas(molImage_frame, width=self.molImage_img.width(), height = self.molImage_img.height())
        self.molImage_cv.pack()
        self.molImage_cv.create_image(0,0,anchor="nw", image=self.molImage_img)
        # texte pour changer la molécule
        molDesc_frame = tk.LabelFrame(self, text = "molecule text description")
        self.molDesc_text = tk.Text(molDesc_frame)
        self.molDesc_text.insert("1.0", json.dumps(self.mol_desc["mol_json"]))
        self.molDesc_text.pack()
        
        molDesc_frame.grid(row = 1, column = 0)
        molImage_frame.grid(row = 0, column = 0)
        petriImage_frame.grid(row = 1, column = 1)

        
    def quit_program(self):
        root.destroy()

if __name__ == "__main__":
    root = tk.Tk()
    app = Application(root)
    app.master.title("Molécule") 
    
    app.mainloop()
