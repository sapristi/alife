import requests
import sys
import select
import json

import logging
import http.client as http_client

import tkinter as tk


from bact_frame import BactFrame
from mol_examine_frame import MolFrame
from pnet_simul_frame import PNetFrame
from prot_synthesis_frame import ProtSynthFrame
# * NetworkClient
# Hooks between server communication and internal functions




class MainApp(tk.Frame):
    def __init__(self, master=None, nc=None):
        tk.Frame.__init__(self, master)
        self.root = master
        self.pack()
        self.req_adress = "http://127.0.0.1:1512"
        self.createWidgets()
        self.bactery_data = None
        self.bf = BactFrame(self.root, self)
        self.components = {}


    def request_init_data(self):
        req = {"command" : "gibinitdata"}
        r = requests.get(self.req_adress, params = req)
        self.bf.set_data(r.json()["data"])

    def make_reactions(self):
        req = {"command" : "make reactions"}
        r = requests.get(self.req_adress, params = req)
        self.bf.set_data(r.json()["data"])

    def examine_mol(self, mol_desc):
        molWindow = tk.Toplevel()
        name = mol_desc["mol"] + "_mol_exam"
        self.components[name] = MolFrame(molWindow, mol_desc["mol"], self, name)

    def simule_pnet(self, mol_desc):
        simulWindow = tk.Toplevel()
        name = mol_desc["mol"] + "_pnet_simul"
        self.components[name] = PNetFrame(simulWindow, mol_desc["mol"], self, name)

    def open_synth_window(self):
        synthWindow = tk.Toplevel()
        self.components["synthWindow"] = ProtSynthFrame(synthWindow, self)
    def createWidgets(self):
        tk.Button(self, text="Init", command=self.request_init_data).grid(row = 0, column = 1)
        tk.Button(self, text="Quit", command=self.quit_program).grid(row = 0, column = 2)

    def quit_program(self):
        root.destroy()




debug = False
if debug == True: 
    http_client.HTTPConnection.debuglevel = 1
    logging.basicConfig()
    logging.getLogger().setLevel(logging.DEBUG)
    requests_log = logging.getLogger("requests.packages.urllib3")
    requests_log.setLevel(logging.DEBUG)
    requests_log.propagate = True

root = tk.Tk()
app = MainApp(root)
app.master.title("Main") 

root.mainloop()
