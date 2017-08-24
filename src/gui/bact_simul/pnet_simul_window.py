
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
            

        self.host.nc.send_request(
            json.dumps({"command" : "give prot desc",
                        "return target" : self.name,
                        "data" : mol_desc["mol_json"]}
            ))

        
        self.createWidgets()
        self.root.title("PNet simul " + mol_desc["name"])

        
    def recv_msg(self, json_msg):
        purpose = json_msg["purpose"]
        data = json_msg["data"]
        if purpose == "prot desc":
            print("received proteine description")
            self.pnet_data = data
            self.setup_graphs(self.pnet_data,self.name)

            
        if purpose == "updatedata":
            print("received update data, updating graph")
            self.pnet_data["places"] = data["places"]
            self.pnet_data["launchables"] = data["launchables"]
            self.setup_graphs(self.pnet_data,self.name)

           
    # trigger transition from server
    def launch_transition(self):
        trans_id = self.next_transition_to_launch.get()
        if trans_id == "...":
            trans_id = "-1"

        self.host.nc.send_request(
            json.dumps({"command" : "launch transition",
                        "return target" : self.name,
                        "data" :
                        { "mol" : self.mol_desc["mol_json"],
                          "trans_id" : trans_id } }
            ))


            
    def createWidgets(self):
        petriImage_frame = tk.LabelFrame(self, text = "Petri net")
        self.petriImage_cv = tk.Canvas(petriImage_frame)
        self.petriImage_cv.pack()

        petriImage_frame.pack()

        
        #boutons gestion simuls
        button_frame = tk.Frame(self)
        self.launch_trans_b = tk.Button(button_frame, text = "launch transition", command = self.launch_transition)
        self.launch_trans_b.pack(side="top")
        
        self.next_transition_to_launch = tk.StringVar(button_frame)
        self.next_transition_to_launch.set("...")
        self.select_trans_l = tk.OptionMenu(button_frame, self.next_transition_to_launch, "...")
        self.select_trans_l.pack(side="bottom")
        button_frame.pack()


        
    def update_launchables(self, new_launchables):
        self.select_trans_l['menu'].delete(0,'end')
        if len(new_launchables) > 0:
            for i in new_launchables:
                self.select_trans_l['menu'].add_command(label=str(i), command=tk._setit(self.next_transition_to_launch, str(i)))
            self.next_transition_to_launch.set(new_launchables[0])
        else:
            self.next_transition_to_launch.set("...")


    
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
