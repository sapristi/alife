import socket
import sys
import select


import tkinter as tk


class NetworkClient:
    
    def __init__(self):
        self.HOST = 'wololo'    # The remote host
        self.PORT = 1512              # The same port as used by the serverk
        self.s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)

    def connect(self):
        self.s.connect((self.HOST, self.PORT))
        self.s.setblocking(0)


    def get_initial_data(self) :
        print('sending request')
        self.s.send("gibinitdata\n".encode('utf-8'))
        print('request send; waiting for answer')
#        data = self.s.recv(4096)
#        print('answer received')
#        return data

    def get_dot_desc(self) :
        self.s.send("gibdotdata\n".encode('utf-8'))
#        data = self.s.recv(4096)
#        return data


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
        self.nc.connect()

    def createWidgets(self):
        self.init_b = tk.Button(self)
        self.init_b["text"] = "init"
        self.init_b["command"] = self.init_data
        self.init_b.pack(side="top")

        self.get_dot_b = tk.Button(self)
        self.get_dot_b["text"] = "get_dot"
        self.get_dot_b["command"] = self.get_dot
        self.get_dot_b.pack(side="top")
        
        self.QUIT = tk.Button(self, text="QUIT", fg="red", command=self.quit_program)
        self.QUIT.pack(side="bottom")

    def init_data(self):
        self.nc.get_initial_data()

    def get_dot(self):
        self.nc.get_dot_desc()

    def quit_program(self):
        self.nc.disconnect()
        root.destroy()



client = NetworkClient()
root = tk.Tk()
app = Application(root, client)

def recv_msg():
    client.get_answer()
    root.after(20, recv_msg)

root.after(20, recv_msg)

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
