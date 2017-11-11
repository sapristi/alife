// * place VM

function PlaceViewModel() {

// ** data initialisation
    var self = this;
    self.data={};

// ** data observables
    self.place_extensions = ko.observableArray([]);
    self.token_state = ko.observable();
    
    self.token_edit_state = ko.observable();
    self.token_edit_m1 = ko.observable("");
    self.token_edit_m2 = ko.observable("");

    self.token_edit_checkbox = ko.observable(false);
    self.token = ko.observableArray()

    // do not call from this file !!!
    // make the test directly with self.token_token()[0]
    self.is_occupied = ko.computed(
	function ()
	{ return (self.token_state() == "Mol_token");});
    
    self.disable = function() {self.active(false);};
    
    self.token_mol_disp = ko.computed(function() {
	if (self.token()[0] == "Mol_token")
	{
	    return utils.string_rev(self.token()[1])
		+ "<font style='color:red'>⮞</font>"
		+ self.token()[2];
	}
	else {return "";}
    });
    
// ** observable controling display    
    self.active = ko.observable(false);
    self.token_edit_view = ko.computed( function() {
	return (self.token_edit_checkbox() && self.active());
    });

    
// ** data setup
    self.enable = function(place_data) {
	
	self.data = place_data;
	self.token(self.data.token);
	self.token_state(self.data.token[0]);
	self.place_extensions.removeAll();
	self.place_extensions(self.data.extensions.map(extension_to_string)); 
	self.token_edit_state(self.token_state());
	if (self.is_occupied())
	{
	    self.token_edit_m1(utils.string_rev(self.token()[1]));
	    self.token_edit_m2(self.token()[2]);
	}
	else
	{
	    self.token_edit_m1("");
	    self.token_edit_m2("");
	}

	self.active(true);
    };

// ** place extensions display
   
    var extension_to_string = function(ext) {
	var ext_str = ext[0].slice(0, ext[0].length -4).replace(/_/g," ");
	if (ext.length > 1)
	{
	    if (ext_str == "Displace mol") {
		if (ext[1][0])
		{ext_str = ext_str + " forward";}
		else {ext_str = ext_str + " backward";}
	    }
	    else if (ext_str == "Grab") {
		var grab_patt = ext[1]["pattern"].replace(/\\/g,"");
		ext_str = ext_str + "; pattern :\n" + grab_patt;
	    }
	}
	return ext_str;
    };

    
// ** token edit commit
    self.commit_token_edit = function() {
	
	utils.ajax_post(
            {command: "commit token edit",
             token: self.token(),
	     container: "bacterie"}
        ).done(
	    function (data)
	    {
		placeVM.disable();
		self.pnet_data = data.data.pnet;
		self.change(!self.change());
		self.initialised(true);
		self.display_cy_graph();
	    });
	    
	
	utils.ajax_get(
            {command: "commit token edit",
             token: JSON.stringify(self.token()),
	     container: "bacterie"}
        ).done(
	    function (data)
	    {
		placeVM.disable();
		self.pnet_data = data.data.pnet;
		self.change(!self.change());
		self.initialised(true);
		self.display_cy_graph();
	    });
    }
    
};

// * transition VM

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

// * PNet VM

function PNetViewModel(placeVM, transitionVM) {
    
// ** initialisation
    var self = this;
    self.pnet_data =
	{places : [],
	 transitions: [],
	 launchables:[]
	}
    var pnet_cy;


// ** observables controlling display
    self.initialised = ko.observable(false);
    self.active = ko.observable(true);
    self.change = ko.observable(false);
    
    self.enable = function () {
	self.active(true);self.display_cy_graph()};
    self.disable = function() {
	self.active(false);
	placeVM.disable();
    };
	
// ** data observables
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


// ** cy graph
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

// ** data setup
    self.set_data = function(mol_desc) {
        utils.ajax_get(
            {command: "pnet_from_mol",
             mol_desc: mol_desc,
	     container: "bacterie"}
        ).done(
	    function (data)
	    {
		placeVM.disable();
		self.pnet_data = data.data.pnet;
		self.change(!self.change());
		self.initialised(true);
		self.display_cy_graph();
	    });
    }

    
    
// ** functions called by the cy graph to display node data
    self.set_node_selected = function(node_data) {
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



