
import json
import tkinter as tk
import os

from graph_generators import MolGraph, PetriGraph
                
class MolFrame(tk.Frame):
    def __init__(self, root, mol_desc, host, name):
        tk.Frame.__init__(self, root)
        self.root = root
        self.host = host
        self.pack()
        self.mol_desc = mol_desc
        self.temp_dir = "tempdir"
        self.name = name
        
        if not os.path.exists(self.temp_dir):
            os.makedirs(self.temp_dir)
            
        self.host.nc.send_request(
            json.dumps({"command" : "give prot desc",
                        "return target" : self.name,
                        "data" : mol_desc["mol_json"]}
            ))
        
        self.createWidgets()
        
        self.root.title("Mol Exam " + mol_desc["name"])

            
    def recv_msg(self, json_msg):
        purpose = json_msg["purpose"]
        data = json_msg["data"]
        if purpose == "prot desc":
            print("received proteine description")
            self.setup_graphs(self.mol_desc["mol_json"],data,self.mol_desc["name"])
            
        
    def createWidgets(self):
        
        #canvas pour dessiner
        petriImage_frame = tk.LabelFrame(self, text = "Petri net")
        self.petriImage_cv = tk.Canvas(petriImage_frame)
        self.petriImage_cv.pack()

        molImage_frame = tk.LabelFrame(self, text = "molecule")
        
        self.molImage_cv = tk.Canvas(molImage_frame)
        self.molImage_cv.pack()
        
        # texte pour changer la molécule
        molDesc_frame = tk.LabelFrame(self, text = "molecule text description")
        self.molDesc_text = tk.Text(molDesc_frame)
        self.molDesc_text.insert("1.0", json.dumps(self.mol_desc["mol_json"]))
        self.molDesc_text.pack()
        
        molDesc_frame.grid(row = 1, column = 0)
        molImage_frame.grid(row = 0, column = 0)
        petriImage_frame.grid(row = 1, column = 1)

    def setup_graphs(self, mol_data, pnet_data, name):
        
        mol_graph = MolGraph(mol_data)
        mol_graph.render(
            filename=self.temp_dir + "/" + name +"_mol_image")
        self.molImage_img = tk.PhotoImage(
            file=self.temp_dir + "/" + name +"_mol_image.gif")
        self.molImage_cv.config(
            width = self.molImage_img.width(),
            height = self.molImage_img.height())
        self.molImage_cv.create_image(0,0,anchor="nw", image=self.molImage_img)
        
        
        petri_graph = PetriGraph(pnet_data)
        petri_graph.render(
            filename=self.temp_dir + "/" + name +"_petri_image")
        print("petri graph generated")
        self.petriImage_img = tk.PhotoImage(
            file=self.temp_dir + "/" + name +"_petri_image.gif")
        self.petriImage_cv.config(
            width = self.petriImage_img.width(),
            height = self.petriImage_img.height())
        self.petriImage_cv.create_image(0,0,anchor="nw", image=self.petriImage_img)
        

    def quit_program(self):
        root.destroy()

if __name__ == "__main__":
    root = tk.Tk()
    app = Application(root)
    app.master.title("Molécule") 
    
    app.mainloop()
