import socket
import sys
import select
import json

import tkinter as tk


from graphviz import Digraph

class DotGraph(Digraph):
    def __init__(self, desc):
        Digraph.__init__(self, format = "gif")
        for i, val in enumerate(desc["places"]):
            self.node('p'+str(i), "{"+val["type"][0] + "|" + val["token"] + "}", shape="record")

        for i, val in enumerate(desc["transitions"]):
            tname = 't'+str(i)
            self.node(tname)
            for valbis in val["dep_places"]:
                self.edge('p'+str(valbis[0]), tname)

            for valbis in val["arr_places"]:
                self.edge(tname, 'p'+str(valbis[0]))
        
        
class NetworkClient:
    
    def __init__(self):
        self.HOST = 'wololo'    # The remote host
        self.PORT = 1512              # The same port as used by the serverk
        self.s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)

    def connect(self):
        self.s.connect((self.HOST, self.PORT))
        self.s.setblocking(0)

    def get_initial_data(self) :
        self.s.send("gibinitdata\n".encode('utf-8'))
        data = self.s.recv(4096)
        return data

    def get_dot_desc(self) :
        self.s.send("gibdotdata\n".encode('utf-8'))
        data = self.s.recv(4096)
        return data


    def get_answer(self) :
        ready = select.select([self.s], [], [], 0)
        if ready[0]:
            data = self.s.recv(4096)
            print('Received', repr(data))
            sys.stdout.flush()

    
    def disconnect(self):
        self.s.close()


class Application(tk.Frame):
    def __init__(self, master=None, nc=None):
        tk.Frame.__init__(self, master)
        self.pack()
        self.createWidgets()
        self.nc = nc
        self.graph = None
        self.graph_image = None

    def createWidgets(self):
        self.button_frame = tk.Frame(self)
        self.image_frame = tk.Frame(self)

        self.get_dot_b = tk.Button(self.button_frame)
        self.get_dot_b["text"] = "connect"
        self.get_dot_b["command"] = self.connect
        self.get_dot_b.pack(side="top")
        
        self.init_b = tk.Button(self.button_frame)
        self.init_b["text"] = "init"
        self.init_b["command"] = self.init_data
        self.init_b.pack(side="top")

        self.print_dot_b = tk.Button(self.button_frame)
        self.print_dot_b["text"] = "draw_graph"
        self.print_dot_b["command"] = self.draw_graph
        self.print_dot_b.pack(side="top")

        self.cv = tk.Canvas(self.image_frame)
        self.cv.pack(side='right')
        
        self.QUIT = tk.Button(self.button_frame, text="QUIT", fg="red", command=self.quit_program)
        self.QUIT.pack(side="bottom")

        self.button_frame.pack(side="left")
        self.image_frame.pack(side="right")
        

    def connect(self):
        self.nc.connect()
        
    def init_data(self):
        data = self.nc.get_initial_data()
        s = data.decode('utf-8')
        print("initialised with " + s)
        self.graph = DotGraph(json.loads(s))


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

def recv_msg():
    client.get_answer()
    root.after(20, recv_msg)

#root.after(20, recv_msg)

app.mainloop()




class Poubelle:
    HOST = 'wololo'    # The remote host
    PORT = 1512              # The same port as used by the serverk
    s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)

    def prout ():
        s.connect((HOST, PORT))
        #s.setblocking(0)
        to_send = "sqdd"
        while not (to_send == "") :
            to_send = input()
            print("trying to send", to_send)
            s.send((to_send + "\n").encode('utf-8'))
            
            #    ready = select.select([s], [], [], 2)
            #    if ready[0]:
            data = s.recv(4096)
            print('Received', repr(data))
            sys.stdout.flush()

        s.close()
