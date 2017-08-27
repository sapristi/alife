
import json
import tkinter as tk
import os

from graph_generators import MolGraph, PetriGraph

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
        self.mol_text = tk.Text(texts_frame)
        self.prot_text = tk.Text(texts_frame)
        self.mol_text.grid(row = 0, column = 0, columnspan=2)
        self.prot_text.grid(row = 2, column = 0, columnspan=2)

        prot_to_mol_button = tk.Button(texts_frame, text = "↑", command = self.prot_to_mol)
        mol_to_prot_button = tk.Button(texts_frame, text = "↓", command = self.mol_to_prot)
        prot_to_mol_button.grid(row = 1, column = 1)
        mol_to_prot_button.grid(row = 1, column = 0)

        # images_frame                        
        self.petriImage_cv = tk.Canvas(images_frame)
        self.molImage_cv = tk.Canvas(images_frame)

        #buttons_frame
        add_mol_button = tk.Button(buttons_frame,  text = "Add mol to bactery", command = self.add_mol)
        save_button = tk.Button(buttons_frame,  text = "Save", command = self.save)
        load_button = tk.Button(buttons_frame,  text = "Load", command = self.load)
        add_mol_button.grid(column = 0)
        save_button.grid(column = 1)
        load_button.grid(column = 2)
        
    def prot_to_mol(self):
        print("todo")

    def mol_to_prot(self):
        print("todo")

    def add_mol(self):
        print("todo")
    
    def save(self):
        print("todo")

    def load(self):
        print("todo")
