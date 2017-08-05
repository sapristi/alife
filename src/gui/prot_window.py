# * ProtGraph class

# Simple window used to display the petri net associated with a proteine
class ProtGraph(Digraph):

    def __init__(self, desc):
        Digraph.__init__(self, format = "gif")
        self.desc = desc

        temp_place = None
        # crée les nœuds correspondant aux places, et des arcs entre celles-ci
        for i, val in enumerate(desc["places"]):
            self.node('p'+str(i), "{place" + str(val["id"]) + "|" + str(val["token"]) + "}", shape="record")

            if i>0:
                self.edge('p'+str(i-1), 'p'+str(i), constraint = "false")
            
        # ajoute les nœuds correspondant aux transitions, et les arcs correspondants 
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


class ProtWindow():
    def __init__(self, prot_desc, master=None, host=None):
        tk.Frame.__init__(self, master)
        self.prot_desc = prot_desc
        self.root = master
        self.pack()
        self.nc = nc
        self.createWidgets()
        self.graph = None
        self.graph_image = None
        self.graph_data = None
        self.draw_graph()
        
    # updates the drop down menu to select transitions to launch
    def update_launchables(self, new_launchables):
        self.select_trans_l['menu'].delete(0,'end')
        if len(new_launchables) > 0:
            for i in new_launchables:
                self.select_trans_l['menu'].add_command(label=str(i), command=tk._setit(self.next_transition_to_launch, str(i)))
            self.next_transition_to_launch.set(new_launchables[0])
        else:
            self.next_transition_to_launch.set("...")

            
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
        self.image_frame = tk.Frame(self)
        self.text_frame = tk.Frame(self)

        #canvas pour dessiner
        self.cv = tk.Canvas(self.image_frame)
        self.cv.pack(side='right')

        # texte pour changer la molécule
        self.text = tk.Text(self.text_frame)
        self.text.pack()
        
        #pack final
        self.image_frame.pack(side="bottom")
        self.text_frame.pack(side= "top")
        
    def close_window(self):
        root.destroy()
