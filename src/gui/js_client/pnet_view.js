function PlaceViewModel() {
    var self = this;
    var data;
    self.active = ko.observable(false);

    self.place_extensions = ko.observableArray([]);
    self.token_state = ko.observable();
    self.token_m1 = ko.observable("");
    self.token_m2 = ko.observable("");
    self.token_edit_checkbox = ko.observable(false);
    
    self.is_occupied = ko.computed(
	function ()
	{return (self.token_state() == "occupied_token");});
    self.disable = function() {self.active(false);};
    
    self.token_mol_disp = ko.computed(function() {
	if (self.is_occupied())
	{return utils.string_rev(self.token_m1())
	 + "<font style='color:red'>⮞</font>" + self.token_m2();}
	else {return "";}
    });
    
    self.token_edit_view = ko.computed( function() {
	return (self.token_edit_checkbox() && self.active());
    });
    
    self.enable = function(place_data) {
	data = place_data;
	if (data.token == "no token")
	{ self.token_state("no_token");}
	else {
	    if (data.token.is_empty)
	    {self.token_state("empty_token");}
	    else
	    {self.token_state("occupied_token");
	     self.token_m1(data.token.mol_1);
	     self.token_m2(data.token.mol_2);
	     
	     console.log(data.token.mol_1);
	     
	    }
	}

	self.place_extensions(data.extensions); 
	self.active(true);
    };
};

function TransitionViewModel() {
    var self = this;
    self.active = ko.observable(false);
    self.enable = function() {
	self.active(true);
    };
    self.disable = function() {
	self.active(false);
    };
}


function PNetViewModel(placeVM, transitionVM) {
    var self = this;
    //dummy initialisation
    self.pnet_data =
	{places : [],
	 transitions: [],
	 launchables:[]
	}
    var pnet_cy;
    
    self.initialised = ko.observable(false);
    self.active = ko.observable(true);
    self.change = ko.observable(false);
    
    self.enable = function () {
	self.active(true);self.display_cy_graph()};
    self.disable = function() {
	self.active(false);
    };
	
    
    self.place_nb = ko.computed( function() {
	self.change();
	return "Number of places : " + self.pnet_data.places.length;
    });
    self.transition_nb = ko.computed( function() {
	self.change();
	return "Number of transitions : " + self.pnet_data.transitions.length;
    });
    self.launchable_transition_nb = ko.computed( function() {
	self.change();
	return "Number of launchable transitions : " + self.pnet_data.launchables.length;
    });

    self.display_cy_graph = function() {
	if (self.active() && self.initialised)
	{
	    pnet_cy = make_pnet_graph(
		self.pnet_data,
		document.getElementById('pnet_cy'),
		self);
	    
            pnet_cy.layout({name:"cose"}).run();
	}
    };

    self.set_data = function(mol_desc) {
	
	
        utils.ajax(
            {command: "pnet_from_mol",
             mol_desc: mol_desc,
	     container: "bacterie"}
        ).done(
	    function (data)
	    {self.pnet_data = data.data.pnet;
	     self.change(!self.change());
	     self.initialised(true);
	     self.display_cy_graph();
	    });
    }

    
    
 // *** functions called by the cy graph
    self.set_node_selected = function(node_data) {
	console.log("node selected");
	console.log(node_data);
	if (node_data.type == "place") {
	    placeVM.enable(node_data);
	    transitionVM.disable();
	} else if (node_data.type = "transition") {
	    transitionVM.enable();
	    placeVM.disable();
	}
    };
    self.set_node_unselected = function() {
	placeVM.disable();
	transitionVM.disable();
    };
};



