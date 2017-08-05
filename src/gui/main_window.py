# * this file
# Client for testing a bacteria simulation
# communicates with a server running the simulation

# The server hosts a particular bacteria. 
# We can then display molecules and the petri net of the associated
# proteine, as well run steps of the simulation


import socket
import sys
import select
import json

import tkinter as tk

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
                print("received init data")
                
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
        
    
    def createWidgets(self):
        self.button_frame = tk.Frame(self)
        self.simul_frame = tk.Frame(self)
        self.image_frame = tk.Frame(self)
        self.text_frame = tk.Frame(self)

        # boutons admin
        self.connect_b = tk.Button(self.button_frame, text="connect", command=self.connect)
        self.connect_b.pack(side="top")
        
        self.init_b = tk.Button(self.button_frame, text="init", command = self.init_data)
        self.init_b.pack(side="top")

        self.QUIT = tk.Button(self.button_frame, text="QUIT", fg="red", command=self.quit_program)
        self.QUIT.pack(side="bottom")

        #boutons gestion simuls
        self.next_step_b = tk.Button(self.simul_frame, text = "launch transition", command = self.launch_transition)
        self.next_step_b.pack(side="top")
        
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
