import requests
import json
import tkinter as tk
import os

from graph_generators import ProtGraph, PetriGraph

class ProtSynthFrame(tk.Frame):
    def __init__(self, root, host):
        tk.Frame.__init__(self, root)
        self.root = root
        self.host = host
        self.pack()
        self.temp_dir = "tempdir"
        self.instance_name = "synthWindow"

        
        if not os.path.exists(self.temp_dir):
            os.makedirs(self.temp_dir)

            
        self.createWidgets()
        
        self.root.title("Proteine Synthesis")

        
    def createWidgets(self):
        texts_frame = tk.Frame(self)
        texts_frame.grid(row=0, column = 0)
        images_frame = tk.Frame(self)
        images_frame.grid(row=0, column = 1)
        buttons_frame = tk.Frame(self)
        buttons_frame.grid(row=1, column = 0)

        # texts_frame
        self.mol_text = tk.Text(texts_frame, height = 5)
        from_mol_button = tk.Button(texts_frame, text = "→", command = self.from_mol)

        self.prot_text = tk.Text(texts_frame, height = 10)
        from_prot_button = tk.Button(texts_frame, text = "→", command = self.from_prot)

        self.mol_text.grid(row = 0, column = 0)
        from_mol_button.grid(row = 0, column = 1)
        self.prot_text.grid(row = 1, column = 0)
        from_prot_button.grid(row = 1, column = 1)
        

        # images_frame                        
        self.petriImage_cv = tk.Canvas(images_frame)
        self.protImage_cv = tk.Canvas(images_frame)
        self.petriImage_cv.grid(row = 1, column = 0)
        self.protImage_cv.grid(row = 0, column = 0)
        
        #buttons_frame
        add_mol_button = tk.Button(buttons_frame,  text = "Add mol to bactery", command = self.add_mol)
        gen_graphs_button = tk.Button(buttons_frame,  text = "Gen graphs", command = self.gen_graphs)
        save_button = tk.Button(buttons_frame,  text = "Save", command = self.save)
        load_button = tk.Button(buttons_frame,  text = "Load", command = self.load)
        add_mol_button.grid(column = 0, row = 0)
        gen_graphs_button.grid(column = 1, row = 0)
        save_button.grid(column = 2, row = 0)
        load_button.grid(column = 3, row = 0)
        
    def from_mol(self):
        mol_desc = self.mol_text.get("1.0", tk.END).strip("\n")
        mol_desc_json = json.dumps(mol_desc)

        req = {"command" : "gen from mol",
               "data" : mol_desc_json}
        r = requests.get(self.host.req_adress, params = req)
        data = r.json()["data"]
        self.prot_text.delete("1.0", tk.END)
        self.prot_text.insert("1.0", msg["data"]["prot"])
        self.setup_graphs(data["prot"], data["pnet"])
        
    def from_prot(self):
        prot_desc = self.prot_text.get("1.0", tk.END).strip("\n")
        req = {"command" : "gen from prot",
               "data" : prot_desc}

        data = r.json()["data"]
        self.prot_text.delete("1.0", tk.END)
        self.prot_text.insert("1.0", msg["data"]["prot"])
        self.setup_graphs(msg["data"]["prot"], msg["data"]["pnet"])

    def gen_graphs(self):
        mol_desc = self.mol_text.get("1.0", tk.END).strip("\n")
        self.host.nc.send_request(
            json.dumps({"command" : "pnet of mol",
                        "return target" : self.instance_name,
                        "data" : mol_desc}
            ))


    def setup_graphs(self, prot_data, pnet_data):
        prot_graph = ProtGraph(prot_data)
        prot_graph.render(
            filename=self.temp_dir + "/" + "synth_prot_image")

        self.protImage_img = tk.PhotoImage(
            file=self.temp_dir + "/" + "synth_prot_image.gif")
        self.protImage_cv.config(
            width = self.protImage_img.width(),
            height = self.protImage_img.height())
        self.protImage_cv.create_image(0,0,anchor="nw", image=self.protImage_img)
        
        
        petri_graph = PetriGraph(pnet_data)
        petri_graph.render(
            filename=self.temp_dir + "/" + "synth_petri_image")
        print("petri graph generated")
        self.petriImage_img = tk.PhotoImage(
            file=self.temp_dir + "/" + "synth_petri_image.gif")
        self.petriImage_cv.config(
            width = self.petriImage_img.width(),
            height = self.petriImage_img.height())
        self.petriImage_cv.create_image(0,0,anchor="nw", image=self.petriImage_img)

        
    def add_mol(self):
        print("todo")
    
    def save(self):
        print("todo")

    def load(self):
        print("todo")
