
# * this file
# implementation of a client for protein simulation
# communicates with a server running the simulation

# The server host a particular molecule, and this client can display it's petri net (using DotGraph), launch transitions, etc.


import socket
import sys
import select
import json

import tkinter as tk


from graphviz import Digraph

# * DotGraph class

# Used to generate the image of the petri net

# vu qu'on peut pas vraiment mettre à jour les éléments du graphe,
# on le fait statique et on en recrée un à chaque fois
class DotGraph(Digraph):
    
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

                
# * NetworkClient
# Hooks between server communication and internal functions

class NetworkClient:
    
    def __init__(self):
        self.HOST = 'Sathobi'    # The remote host
        self.PORT = 1512              # The same port as used by the serverk
        self.s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        
    def connect(self):
        self.s.connect((self.HOST, self.PORT))
        self.s.setblocking(0)
        print("connection to server established")

    def ask_initial_data(self) :
        req = json.dumps({"command" : "gibinitdata"})
        print("sending request :", req)
        self.s.send((req + "\n").encode('utf-8'))

    def ask_update_data(self) :
        req = json.dumps({"command" : "gibupdatedata"})
        print("sending request :", req)
        self.s.send((req + "\n").encode('utf-8'))        
        
    def ask_transition_launch(self, tId):
        req = json.dumps({"command" : "launch", "arg" : tId})
        print("sending request :", req)
        self.s.send((req + "\n").encode('utf-8'))

    def ask_new_mol(self, new_mol):
        req = json.dumps({"command" : "new_mol", "arg" : new_mol})
        print("sending request :", req)
        self.s.send((req + "\n").encode('utf-8'))
        
    def get_answer(self) :
        ready = select.select([self.s], [], [], 0)
        if ready[0]:
            data = self.s.recv(4096)
            print('Received', repr(data))
            return data
        return None

            
    def disconnect(self):
        self.s.close()

# * The Application
# The main program, managing tk widgets for the UI, internal state and internal functions

# ** TODO separate the interface from the program ?


class Application(tk.Frame):
    def __init__(self, master=None, nc=None):
        tk.Frame.__init__(self, master)
        self.root = master
        self.pack()
        self.nc = nc
        self.createWidgets()
        self.graph = None
        self.graph_image = None
        self.graph_data = None
#        self.bind("<Configure>", self.pack())

    
    # crée un graphe initial à partir des infos 
    def init_data(self):
        self.nc.ask_initial_data()

    def connect(self):
        self.nc.connect()
        self.recv_msg()
        
    # loop to correctly handle delays in message receiving 
    def recv_msg(self):
        answer = self.nc.get_answer()
        if not (answer == None):
            json_data = json.loads(answer.decode('utf-8'))
            if "initdata" in json_data:
                print("received init data, creating graph")
                self.graph_data = json_data["initdata"]
                self.draw_graph()
                self.text.delete("1.0", tk.END)
                self.text.insert("1.0", json.dumps(json_data["initdata"]["molecule"]))
                
            if "updatedata" in json_data:
                print("received update data, updating graph")
                self.graph_data["places"] = json_data["updatedata"]["places"]
                self.graph_data["launchables"] = json_data["updatedata"]["launchables"]
                self.draw_graph()

            if "transition_launch" in json_data:
                print("transition launch report received; updating graph")
                self.nc.ask_update_data()
                
        self.root.after(20, self.recv_msg)

    # trigger transition from server
    def launch_transition(self):
        trans_id = self.next_transition_to_launch.get()
        if trans_id == "...":
            trans_id = "-1"
        self.nc.ask_transition_launch(trans_id)

    def set_new_mol(self):
        new_mol_str = (self.text.get("1.0", tk.END)).replace("'", '"')
        new_mol_json = json.dumps(new_mol_str)
        self.nc.ask_new_mol(new_mol_str)
        
    # updates the drop down menu to select transitions to launch
    def update_launchables(self, new_launchables):
        self.select_trans_l['menu'].delete(0,'end')
        if len(new_launchables) > 0:
            for i in new_launchables:
                self.select_trans_l['menu'].add_command(label=str(i), command=tk._setit(self.next_transition_to_launch, str(i)))
            self.next_transition_to_launch.set(new_launchables[0])
        else:
            self.next_transition_to_launch.set("...")

            
    # renders the graph in the window
    def draw_graph(self):
        self.graph = DotGraph(self.graph_data)
        self.update_launchables(self.graph_data['launchables'])
        self.graph.render(filename="temp_graph")
        self.graph_image = tk.PhotoImage(file = "temp_graph.gif")
        self.cv.config(width=self.graph_image.width(), height=self.graph_image.height())
        self.cv.pack(side = "right")
        self.cv.create_image(0,0,anchor = "nw", image=self.graph_image)
        print("rendering graph image")

    def createWidgets(self):
        self.button_frame = tk.Frame(self)
        self.simul_frame = tk.Frame(self)
        self.image_frame = tk.Frame(self)
        self.text_frame = tk.Frame(self)

        # boutons admin
        self.get_dot_b = tk.Button(self.button_frame, text="connect", command=self.connect)
        self.get_dot_b.pack(side="top")
        
        self.init_b = tk.Button(self.button_frame, text="init", command = self.init_data)
        self.init_b.pack(side="top")

        self.print_dot_b = tk.Button(self.button_frame, text = "draw_graph", command = self.draw_graph)
        self.print_dot_b.pack(side="top")

        self.QUIT = tk.Button(self.button_frame, text="QUIT", fg="red", command=self.quit_program)
        self.QUIT.pack(side="bottom")

        #boutons gestion simuls
        self.launch_trans_b = tk.Button(self.simul_frame, text = "launch transition", command = self.launch_transition)
        self.launch_trans_b.pack(side="top")
        
        self.next_transition_to_launch = tk.StringVar(self.simul_frame)
        self.next_transition_to_launch.set("...")
        self.select_trans_l = tk.OptionMenu(self.simul_frame, self.next_transition_to_launch, "...")
        self.select_trans_l.pack(side="bottom")

        
        self.new_mol_b = tk.Button(self.simul_frame, text = "new mol", command = self.set_new_mol)
        self.new_mol_b.pack(side="top")

        
        #canvas pour dessiner
        self.cv = tk.Canvas(self.image_frame)
        self.cv.pack(side='right')

        # texte pour changer la molécule
        self.text = tk.Text(self.text_frame)
        self.text.pack()
        
        #pack final
        self.button_frame.pack(side="left")
        self.simul_frame.pack(side = "left")
        self.image_frame.pack(side="left")
        self.text_frame.pack(side= "right")
        
    def quit_program(self):
        self.nc.disconnect()
        root.destroy()



client = NetworkClient()
root = tk.Tk()
app = Application(root, client)


app.mainloop()
