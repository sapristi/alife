

import tkinter as tk


from graphviz import Digraph


class Application(tk.Frame):
    def __init__(self, master=None, nc=None):
        tk.Frame.__init__(self, master)
        self.root = master
        self.pack()
        self.nc = nc
        self.createWidgets()
        
        
    
    def createWidgets(self):

        
        
        #canvas pour dessiner
        petriImage_frame = tk.LabelFrame(self, text = "Petri net")
        self.petriImage_cv = tk.Canvas(petriImage_frame)
        self.petriImage_cv.pack()

        molImage_frame = tk.LabelFrame(self, text = "molecule")
        self.molImage_cv = tk.Canvas(molImage_frame)
        self.molImage_cv.pack()
        
        # texte pour changer la molécule
        molDesc_frame = tk.LabelFrame(self, text = "molecule text description")
        self.molDesc_text = tk.Text(molDesc_frame)
        self.molDesc_text.pack()
        
        molDesc_frame.grid(row = 0, column = 0)
        molImage_frame.grid(row = 0, column = 1)
        petriImage_frame.grid(row = 1, column = 1)
        
    def quit_program(self):
        root.destroy()


root = tk.Tk()
app = Application(root)
app.master.title("Molécule") 

app.mainloop()
