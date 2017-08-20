
import tkinter as tk


class Application(tk.Frame):
    def __init__(self, master=None, nc=None):
        tk.Frame.__init__(self, master)
        self.root = master
        self.pack()
        self.nc = nc
        self.createWidgets()
        
        
    
    def createWidgets(self):
        
        self.button_frame = tk.LabelFrame(self, text = "Simulation")
        self.molList_frame = tk.LabelFrame(self, text = "Liste des molécules")


        # auto-simul vs step-simul with radio buttons
        self.rbut_v = tk.IntVar()
        
        #auto simulation frame
        self.autoSimul_frame = tk.Frame(self.button_frame)
        autoSimul_rbutton = tk.Radiobutton(self.button_frame, text="Auto-simul", variable=self.rbut_v, value=1, command = self.select_autoSimul)


        nbOfRounds_label = tk.Label(self.autoSimul_frame, text = "nb of rounds")
        nbOfRounds_entry = tk.Entry(self.autoSimul_frame, width = 3)
        autoSimulLauch_button = tk.Button(self.autoSimul_frame, text = "launch", command = self.autoSimul_launch)

        nbOfRounds_label.grid(row=1, column = 0)
        nbOfRounds_entry.grid(row=1, column = 1)
        autoSimulLauch_button.grid(row=2, column = 0)

        
        autoSimul_rbutton.grid(row=0)
        self.autoSimul_frame.grid(row = 1)


        #step simulation frame

        self.stepSimul_frame = tk.Frame(self.button_frame)
        stepSimul_rbutton = tk.Radiobutton(self.button_frame, text="Step-simul", variable=self.rbut_v, value=2, command = self.select_stepSimul)
        
        stepSimulEvalCatch_button = tk.Button(self.stepSimul_frame, text = "eval catch", command = print("todo"))
        stepSimulSimulProts_button = tk.Button(self.stepSimul_frame, text = "simul prots", command = print("todo"))
        

        stepSimulEvalCatch_button.grid(row = 1)
        stepSimulSimulProts_button.grid(row = 2)

        stepSimul_rbutton.grid(row = 2)
        self.stepSimul_frame.grid(row = 3)


        #molecules list frame
        molList_listbox = tk.Listbox(self.molList_frame)
        molExamine_button = tk.Button(self.molList_frame, text = "examine", command = print("todo"))
        molList_listbox.pack()
        molExamine_button.pack()
        
        #pack final
        self.button_frame.pack(side="left")
        self.molList_frame.pack(side = "right")

        # Init rbutton selection
        self.rbut_v.set(1)
        self.select_autoSimul()

        
        
    def enable_frame(self, frame):
        for child in frame.winfo_children():
            child.configure(state='normal')

    def disable_frame(self, frame):
        for child in frame.winfo_children():
            child.configure(state='disabled')

    def select_stepSimul(self):
        self.enable_frame(self.stepSimul_frame)
        self.disable_frame(self.autoSimul_frame)
        
    def select_autoSimul(self):
        self.enable_frame(self.autoSimul_frame)
        self.disable_frame(self.stepSimul_frame)
        
    def autoSimul_launch(self):
        print("todo")

    def quit_program(self):
        root.destroy()


root = tk.Tk()
app = Application(root)
app.master.title("Bactérie") 

app.mainloop()

        
