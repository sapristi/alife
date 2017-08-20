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
            
    def disconnect(self):
        self.s.close()




class Application(tk.Frame):
    def __init__(self, master=None, nc=None):
        tk.Frame.__init__(self, master)
        self.root = master
        self.pack()
        self.nc = nc
        self.createWidgets()

    def createWidgets(self):
        tk.Button(self.button_frame, text="connect", command=self.connect)
