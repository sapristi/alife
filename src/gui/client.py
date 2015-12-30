import socket
import sys
import select
import json

import tkinter as tk


from graphviz import Digraph


# vu qu'on peut pas vraiment mettre à jour les éléments du graphe,
# on le fait statique et on en recrée un à chaque fois
class DotGraph(Digraph):
    def __init__(self, desc):
        Digraph.__init__(self, format = "gif")
        self.desc = desc 
        for i, val in enumerate(desc["places"]):
            self.node('p'+str(i), "{"+val["type"][0] + "|" + val["token"] + "}", shape="record")

        # on crée les places et les arcs
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

        #on met les launchables en rouge
        self.update_launchables(self.desc["launchables"])
                
    def update_launchables(self, new_launchables):
        self.desc["launchables"] = new_launchables
        for i,val in enumerate(self.desc["transitions"]):
            if i in self.desc["launchables"]:
                self.node('t'+str(i), color="red")
            else:
                self.node('t'+str(i), color="black")
                
        
        
class NetworkClient:
    
    def __init__(self):
        self.HOST = 'wololo'    # The remote host
        self.PORT = 1512              # The same port as used by the serverk
        self.s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        
    def connect(self):
        self.s.connect((self.HOST, self.PORT))
        self.s.setblocking(0)
        print("connection to server established")

    def get_initial_data(self) :
        req = json.dumps({"command" : "gibinitdata"})
        print("sending request :", req)
        self.s.send((req + "\n").encode('utf-8'))
        data = self.s.recv(4096)
        return data

    def get_answer(self) :
        ready = select.select([self.s], [], [], 0)
        if ready[0]:
            data = self.s.recv(4096)
            print('Received', repr(data))
            sys.stdout.flush()

    def ask_transition_launch(self, tId):
        req = json.dumps({"command" : "launch", "arg" : tId})
        print("sending request :", req)
        self.s.send((req + "\n").encode('utf-8'))
            
    def disconnect(self):
        self.s.close()


class Application(tk.Frame):
    def __init__(self, master=None, nc=None):
        tk.Frame.__init__(self, master)
        self.root = master
        self.pack()
        self.nc = nc
        self.createWidgets()
        self.graph = None
        self.graph_image = None

    def createWidgets(self):
        self.button_frame = tk.Frame(self)
        self.simul_frame = tk.Frame(self)
        self.image_frame = tk.Frame(self)


        # boutons admin
        self.get_dot_b = tk.Button(self.button_frame, text="connect", command=self.nc.connect)
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

        
        self.var_select = tk.StringVar(self.simul_frame)
        self.var_select.set("...")
        self.select_trans_l = tk.OptionMenu(self.simul_frame, self.var_select, "...")
        self.select_trans_l.pack(side="bottom")
        
        #canvas pour dessiner
        self.cv = tk.Canvas(self.image_frame)
        self.cv.pack(side='right')
        
        
        self.button_frame.pack(side="left")
        self.simul_frame.pack(side = "left")
        self.image_frame.pack(side="right")
        
    def update_launchables(self, new_launchables):
        self.select_trans_l['menu'].delete(0,'end')
        for i in new_launchables:
            self.select_trans_l['menu'].add_command(label=str(i), command=tk._setit(self.var_select, str(i)))
        
    def init_data(self):
        data = self.nc.get_initial_data()
        s = data.decode('utf-8')
        print("received initial data :", s)
        json_data = json.loads(s)
        self.graph = DotGraph(json_data)
        self.update_launchables(json_data['launchables'])

    def recv_msg(self):
        self.nc.get_answer()
        self.root.after(20, self.recv_msg)
        
    def launch_transition(self):
        self.nc.ask_transition_launch(self.var_select.get())
        
    def draw_graph(self):
        self.graph.render(filename="temp_graph")
        self.graph_image = tk.PhotoImage(file = "temp_graph.gif")
        print("resizing canvas", "height =", self.graph_image.height(), "width = ", self.graph_image.width())
        self.cv.config(width=self.graph_image.width(), height=self.graph_image.height())
        self.cv.pack(side = "right")
        self.cv.create_image(0,0,anchor = "nw", image=self.graph_image)
        
        
    def quit_program(self):
        self.nc.disconnect()
        root.destroy()



client = NetworkClient()
root = tk.Tk()
app = Application(root, client)


app.mainloop()


