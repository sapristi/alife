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
    
    self.disable = function() {
	self.data = {};
	self.active(false);};
    
    self.token_mol_disp = ko.computed(function() {
	if (self.token()[0] == "Token")
	{
	    var mol = self.token()[2];
	    var index = self.token()[1];
	    if (mol != "") {
		var mol1 = mol.substring(0, index);
		var mol2 = mol.substring(index);
		return mol1
		    + "<font style='color:red'>⮞</font>"
		    + mol2;
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
	    var mol = self.token()[2];
	    var index = self.token()[1];
	    var mol1 = mol.substring(0, index);
	    var mol2 = mol.substring(index);
	    self.token_edit_m1(mol1);
	    self.token_edit_m2(mol2);
	}
	else
	{
	    self.token_edit_m1("");
	    self.token_edit_m2("");
	}

    }
    
    self.enable = function(place_data) {

	
//	$('#left_sim_sticky').sticky('refresh');
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
		var grab_patt = ext[1];
		ext_str = ext_str + "; pattern :\n" + grab_patt;
	    }
	}
	return ext_str;
    };

    
// ** token edit commit
    self.get_edited_token = function () {
	
	var edited_token;
	if (self.token_edit_state() == "Token") {
	    edited_token =
		[self.token_edit_state(),
		 self.token_edit_m1().length,
		 self.token_edit_m1().toUpperCase() +
		 self.token_edit_m2().toUpperCase()];
	} else {
	    edited_token = [self.token_edit_state()];}
	return edited_token;
    }
    
};

// * transition VM

function TransitionViewModel() {
    var self = this;
    self.data = {};
    self.active = ko.observable(false);
    self.enable = function(data) {
	self.data = data;
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
	{
	    molecule : "",
	    places : [],
	    transitions: [],
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
	var launchables_nb = self.pnet_data.transitions.filter(
	    function (e) {e.launchable}).length;
	return "Number of launchable transitions : " + launchables_nb;
    });


// ** cy graph
    self.display_cy_graph = function() {
	if (self.active() && self.initialised)
	{
	    pnet_cy = new make_pnet_graph(
		self.pnet_data,
		document.getElementById('pnet_cy'),
		self);
	    update_pnet_graph(pnet_cy, self.pnet_data);
            pnet_cy.layout({name:"cose"}).run();
	}
    };

// ** data setup
    self.set_data = function(mol_desc) {
        utils.ajax_get(
            {command: "pnet_from_mol",
             mol_desc: mol_desc,
	     container: "bactery"}
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
	    self.placeVM.enable(
		self.pnet_data.places[node_data.index]);
	    self.transitionVM.disable();
	} else if (node_data.type = "transition") {
	    self.transitionVM.enable(
		self.pnet_data.transitions[node_data.index]);
	    self.placeVM.disable();
	}
    };
    self.set_node_unselected = function() {
	self.placeVM.disable();
	self.transitionVM.disable();
    };

// ** token edit commit
    self.commit_token_edit = function() {

	var token = self.placeVM.get_edited_token();
	var pindex = self.placeVM.data.index;
	
	utils.ajax_get(
            {command: "commit token edit",
	     molecule : self.pnet_data.molecule,
	     place_index : pindex,
             token: JSON.stringify(token),
	     container: "bactery"}
        ).done(
	    function (data)
	    {	
		self.pnet_data = data.data.pnet;
		update_pnet_graph(pnet_cy, self.pnet_data);
		self.change(!self.change());

	    });
    }
    
// ** transition_launch*
    self.launch_transition = function() {
	
	var tindex = self.transitionVM.data.index;
	utils.ajax_get(
	    {command: "launch_transition",
	     molecule : self.pnet_data.molecule,
	     transition_index : tindex,
	     container: "bactery"}
        ).done(
	    function (data)
	    {	
		self.pnet_data = data.data.pnet;
		update_pnet_graph(pnet_cy, self.pnet_data);
		self.change(!self.change());
		
	    });

    }

    self.global_sim_update = function() {
	utils.ajax_get(
            {command: "pnet_from_mol",
             mol_desc: self.pnet_data.molecule,
	     container: "bactery"}
        ).done(
	    function (data)
	    {	
		self.pnet_data = data.data.pnet;
		update_pnet_graph(pnet_cy, self.pnet_data);
		self.change(!self.change());
	    });
    }

};



