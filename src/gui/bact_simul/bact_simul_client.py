import socket
import sys
import select
import json

import tkinter as tk


from bact_window import BactFrame
from mol_examine_window import MolFrame

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

    def send_request(self, req):
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




class MainApp(tk.Frame):
    def __init__(self, master=None, nc=None):
        tk.Frame.__init__(self, master)
        self.root = master
        self.pack()
        self.nc = nc
        self.createWidgets()
        self.bactery_data = None
        self.bf = BactFrame(self.root, self)
        self.components = {}

        
    def connect(self):
        self.nc.connect()
        self.recv_msg()

    def recv_msg(self):
        answer = self.nc.get_answer()
        if not (answer == None):
            if not answer.decode('utf-8') == '': 
                json_msg = json.loads(answer.decode('utf-8'))
                target = json_msg["target"]
                purpose = json_msg["purpose"]
                data = json_msg["data"]
                
                if target == "main":
                    
                    if purpose == "bactery_init_desc":
                        print("received bactery initial description")  
                        self.init_bactery(data)
                    else:
                        print("can't understand purpose of message")

                else:
                    if target in self.components:
                        self.components[target].recv_msg(json_msg)
                    else:
                        print("can't find target for message")
                    
            
        # loop    
        self.root.after(20, self.recv_msg)


    def request_init_data(self):
        req = json.dumps({"command" : "gibinitdata", "return target" : "main"})
        self.nc.send_request(req)


    def init_bactery(self, data):
        self.bactery_data = data
        self.bf.set_data(self.bactery_data)
        print(self.bactery_data)

    def examine_mol(self, mol_desc):
        molWindow = tk.Toplevel()
        print(mol_desc["mol_json"])
        
        self.components[mol_desc["name"]] = MolFrame(molWindow, mol_desc, self)
        
        
    def createWidgets(self):
        tk.Button(self, text="Connect", command=self.connect).grid(row = 0, column = 0)
        tk.Button(self, text="Init", command=self.request_init_data).grid(row = 0, column = 1)
        tk.Button(self, text="Quit", command=self.quit_program).grid(row = 0, column = 2)

    def quit_program(self):
        root.destroy()



client = NetworkClient()
root = tk.Tk()
app = MainApp(root, client)
app.master.title("Main") 

app.mainloop()
