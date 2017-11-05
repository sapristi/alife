import requests
import json
import tkinter as tk
import os

from graph_generators import PetriGraph

class PNetFrame(tk.Frame):
    def __init__(self, root, mol_desc, host, name):
        tk.Frame.__init__(self, root)
        self.root = root
        self.host = host
        self.pack()
        self.mol_desc = mol_desc
        self.temp_dir = "tempdir"
        self.name = name
        
        self.pnet_data = None
        if not os.path.exists(self.temp_dir):
            os.makedirs(self.temp_dir)
            

        
        self.createWidgets()
        self.root.title("PNet simul " + self.mol_desc)

        self.init_data()
        
    def init_data(self):
        req = {"command" : "give prot desc for simul",
               "data" : self.mol_desc}
        r = requests.get(self.host.req_adress, params = req)
        self.pnet_data = r.json()["data"]
        self.setup_graphs(self.pnet_data,self.name)

            
            
           
    # trigger transition from server
    def launch_transition(self):
        trans_id = self.transition_svar.get()
        if trans_id == "...":
            trans_id = "-1"

        req = {"command" : "launch transition",
               "mol_desc" : self.mol_desc,
               "trans_id" : trans_id }
        r = requests.get(self.host.req_adress, params = req)
        data = r.json()["data"]
        self.pnet_data["places"] = data["places"]
        self.pnet_data["launchables"] = data["launchables"]
        self.setup_graphs(self.pnet_data,self.name)

            
    def createWidgets(self):
        petriImage_frame = tk.LabelFrame(self, text = "Petri net")
        self.petriImage_cv = tk.Canvas(petriImage_frame)
        self.petriImage_cv.pack()

        petriImage_frame.grid(row=0, column=0)

        
        #boutons gestion simuls
        button_frame = tk.Frame(self)
        self.launch_trans_b = tk.Button(button_frame, text = "launch transition", command = self.launch_transition)
        self.launch_trans_b.pack(side="top")
        
        self.transition_svar = tk.StringVar(button_frame)
        self.transition_svar.set("...")
        self.select_trans_l = tk.OptionMenu(button_frame, self.transition_svar, "...")
        self.select_trans_l.pack(side="bottom")
        button_frame.grid(row=1, column=0)


        self.tokens_frame = tk.LabelFrame(self, text = "Tokens")
        self.tokens_frame.grid(row=0, column=1)

    def examine_token(self):
        print("todo")
        
    def update_launchables(self, new_launchables):
        self.select_trans_l['menu'].delete(0,'end')
        if len(new_launchables) > 0:
            for i in new_launchables:
                self.select_trans_l['menu'].add_command(label=str(i), command=tk._setit(self.transition_svar, str(i)))
            self.transition_svar.set(new_launchables[0])
        else:
            self.transition_svar.set("...")


    
    def setup_graphs(self, pnet_data, name):
            
        self.update_launchables(self.pnet_data['launchables'])
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


        for child in self.tokens_frame.winfo_children():
            child.pack_forget()
            child.destroy()
            
        places = self.pnet_data["places"]
        tokens = [place["token"] for place in places if place["token"] != "no token"]
        
        for token in tokens:
            t_frame = self.make_token_frame(self.tokens_frame, token["id"], None, None)
            t_frame.pack()

        
    def make_token_frame(self, root, tid, mol1 = None, mol2 = None):
        tframe = tk.Frame(root)
        id_label = tk.Label(tframe, text = "id : " + str(tid))
        id_label.grid(row = 0, column = 0)
        if not mol1 == None:
            mol1_label = tk.Label(tframe, text = mol1)
            mol2_label = tk.Label(tframe, text = mol2)
            mol1_label.grid(row=0, column = 1)
            mol1_label.grid(row=1, column = 2)
        else:
            nomol_label = tk.Label(tframe, text = "Empty token")
            nomol_label.grid(row = 0, column = 1)
        return tframe
