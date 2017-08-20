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

    def send_request(self, request):
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




class Application(tk.Frame):
    def __init__(self, master=None, nc=None):
        tk.Frame.__init__(self, master)
        self.root = master
        self.pack()
        self.nc = nc
        self.createWidgets()
        self.bactery_data = None
        
    def connect(self):
        self.nc.connect()
        self.recv_msg()

    def recv_msg(self):
        answer = self.nc.get_answer()
        if not (answer == None):
            json_data = json.loads(answer.decode('utf-8'))

            if "bactery_init_description" in json_data:
                print("received bactery initial description")  
                self.init_bactery(json_data["bactery_init_description"])

        # loop    
        self.root.after(20, self.recv_msg)


    def request_init_data(self):
        req = json.dumps({"command" : "gibinitdata"})
        self.nc.send_request(req)


    def init_bactery(self, data):
        self.bactery_data = data
        print self.bactery_data
        
    def createWidgets(self):
        tk.Button(self, text="Connect", command=self.connect).pack()
        tk.Button(self, text="Init", command=self.connect).pack()


client = NetworkClient()
root = tk.Tk()
app = Application(root, client)
app.master.title("Main") 

app.mainloop()
