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
    self.is_token = ko.computed(
	function ()
	{ return (self.token_state() == "Token");});
    
    self.disable = function() {self.active(false);};
    
    self.token_mol_disp = ko.computed(function() {
	if (self.token()[0] == "Token")
	{
	    if (self.token()[1] != "" && self.token()[2] != "") {
		return utils.string_rev(self.token()[1])
		    + "<font style='color:red'>⮞</font>"
		    + self.token()[2];
	    } else {return  "No molecule in token";}
	}
	else {return "";}
    });
    
// ** observable controling display    
    self.active = ko.observable(false);
    self.token_edit_view = ko.computed( function() {
	return (self.token_edit_checkbox() && self.active());
    });

    
// ** data setup
    self.set_token_edit_state = function() {
	self.token_edit_state(self.token_state());
	if (self.is_token())
	{
	    self.token_edit_m1(utils.string_rev(self.token()[1]));
	    self.token_edit_m2(self.token()[2]);
	}
	else
	{
	    self.token_edit_m1("");
	    self.token_edit_m2("");
	}

    }
    
    self.enable = function(place_data) {
	
	self.data = place_data;
	self.token(self.data.token);
	self.token_state(self.data.token[0]);
	self.place_extensions.removeAll();
	self.place_extensions(self.data.extensions.map(extension_to_string));
	self.set_token_edit_state()
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
	var new_token;
	if (self.token_edit_state() == "Token") {
	    new_token =
		[self.token_edit_state(),
		 utils.string_rev(self.token_edit_m1()).toUpperCase(),
		 self.token_edit_m2().toUpperCase()];
	} else {
	    new_token =	[self.token_edit_state()];}
	
	
	utils.ajax_get(
            {command: "commit token edit",
	     place_id : self.data.global_id,
             token: JSON.stringify(new_token),
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

function PNetViewModel() {
    
// ** initialisation
    var self = this;
    self.pnet_data =
	{places : [],
	 transitions: [],
	 launchables:[]
	}
    var pnet_cy;
    self.placeVM = new PlaceViewModel();
    self.transitionVM = new TransitionViewModel();
    
// ** observables controlling display
    self.initialised = ko.observable(false);
    self.active = ko.observable(true);
    self.change = ko.observable(false);
    
    self.enable = function () {
	self.active(true);self.display_cy_graph()};
    self.disable = function() {
	self.active(false);
	self.placeVM.disable();
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
		self.placeVM.disable();
		self.pnet_data = data.data.pnet;
		self.change(!self.change());
		self.initialised(true);
		self.display_cy_graph();
	    });
    }

    
    
// ** functions called by the cy graph to display node data
    self.set_node_selected = function(node_data) {
	if (node_data.type == "place") {
	    self.placeVM.enable(node_data);
	    self.transitionVM.disable();
	} else if (node_data.type = "transition") {
	    self.transitionVM.enable();
	    self.placeVM.disable();
	}
    };
    self.set_node_unselected = function() {
	self.placeVM.disable();
	self.transitionVM.disable();
    };
};



