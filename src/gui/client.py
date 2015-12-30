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

                
        
        
class NetworkClient:
    
    def __init__(self):
        self.HOST = 'wololo'    # The remote host
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
        self.graph = None
        self.graph_image = None
        self.graph_data = None

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
        self.nc.ask_transition_launch(self.var_select.get())

        
    # updates the drop down menu to select transitions to launch
    def update_launchables(self, new_launchables):
        self.select_trans_l['menu'].delete(0,'end')
        if len(new_launchables) > 0:
            for i in new_launchables:
                self.select_trans_l['menu'].add_command(label=str(i), command=tk._setit(self.var_select, str(i)))
            self.var_select.set(new_launchables[0])
        else:
            self.var_select.set("...")

            
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
        
        self.var_select = tk.StringVar(self.simul_frame)
        self.var_select.set("...")
        self.select_trans_l = tk.OptionMenu(self.simul_frame, self.var_select, "...")
        self.select_trans_l.pack(side="bottom")
        
        #canvas pour dessiner
        self.cv = tk.Canvas(self.image_frame)
        self.cv.pack(side='right')
        
        #pack final
        self.button_frame.pack(side="left")
        self.simul_frame.pack(side = "left")
        self.image_frame.pack(side="right")
        
    def quit_program(self):
        self.nc.disconnect()
        root.destroy()



client = NetworkClient()
root = tk.Tk()
app = Application(root, client)


app.mainloop()


