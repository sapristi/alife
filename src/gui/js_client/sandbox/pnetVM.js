// * place VM

function PlaceViewModel(pnetVM) {
// ** data initialisation
    var self = this;
    self.data = null;
    self.index = null;
    self.pnetVM = pnetVM;
    
// ** data observables
    self.place_extensions = ko.observableArray([]);
    self.token = ko.observable();
    
    self.token_edit_state = ko.observable();
    self.token_edit_m1 = ko.observable("");
    self.token_edit_m2 = ko.observable("");

    self.token_edit_checkbox = ko.observable(false);

    self.enable = function(index, data) {
	self.set_data(index, data);
	self.active(true);
    }
    
    self.disable = function() {
	self.data = null;
	self.index = null;
	self.active(false);};
    
    self.token_disp = ko.computed(function() {
	
	if (self.token() == null) {return "No token";}
	else {
	    var mol = self.token()[1];
	    var index = self.token()[0];
	    if (mol != "") {
		var mol1 = mol.substring(0, index);
		var mol2 = mol.substring(index);
		return mol1
		    + "<font style='color:red'>⮞</font>"
		    + mol2;
	    } else {return  "Token without molecule";}
	}
    });
    
// ** observable controling display    
    self.active = ko.observable(false);
    self.token_edit_view = ko.computed( function() {
	return (self.token_edit_checkbox() && self.active());
    });

    
// ** data setup
    self.set_token_edit_state = function() {
	console.log(self.token());
	if (self.token())
	{
	    self.token_edit_state("Token");
	    var mol = self.token()[1];
	    var index = self.token()[0];
	    var mol1 = mol.substring(0, index);
	    var mol2 = mol.substring(index);
	    self.token_edit_m1(mol1);
	    self.token_edit_m2(mol2);
	}
	else
	{
	    self.token_edit_state("No_token");
	    self.token_edit_m1("");
	    self.token_edit_m2("");
	}

    }
    self.set_data = function(index, place_data) {
	self.index = index;
	self.data = place_data;
	self.token(self.data.token);
	self.place_extensions.removeAll();
	self.place_extensions(self.data.extensions.map(extension_to_string));
	self.set_token_edit_state()
	self.active(true);
    }

    self.update = function() {
	if (self.index) {
	    self.set_data(self.index,
			  self.pnetVM.data().places[self.index]);
	}

    }
// ** place extensions display
   
    var extension_to_string = function(ext) {
	var ext_str = ext[0].replace(/_/g," ");
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
		[ self.token_edit_m1().length,
		  self.token_edit_m1().toUpperCase() +
		  self.token_edit_m2().toUpperCase()];
	} else {
	    edited_token = null;}
	
	return edited_token;
    }
    
};

// * transition VM

function TransitionViewModel(pnetVM) {
    var self = this;
    self.data = null;
    self.index = null;
    self.pnetVM = pnetVM;
    self.active = ko.observable(false);
    self.launchable = ko.observable(false);
    self.enable = function(index, data) {
	self.set_data(index, data);
    };
    self.disable = function() {
	self.index = null;
	self.data = null;
	self.active(false);
    };
    self.update = function() {
	if (self.index) {
	    self.set_data(self.index,
			  self.pnetVM.data().transitions[self.index]);
	}
    }
    self.set_data = function(index, data) {
	self.index = index;
	self.data = data;
	self.active(true);
	self.launchable(self.data.launchable)
    };
    
}

// * PNet VM

function PNetViewModel(container_id) {
    
// ** initialisation
    var self = this;
    
    self.container_id = container_id
    
    var pnet_cy;
    self.placeVM = new PlaceViewModel(self);
    self.transitionVM = new TransitionViewModel(self);
    
// ** observables controlling display
    self.data = ko.observable();

// ** data observables
    self.place_nb = ko.computed( function() {
	if (self.data()) {
	    return "Number of places : " + self.data().places.length;
	} else {return "";}
    });
    self.transition_nb = ko.computed( function() {
	if (self.data()) {
	    return "Number of transitions : " + self.data().transitions.length;
	} else {return "";}
    });
    self.launchable_transition_nb = ko.computed( function() {
	if (self.data()) {
	    var launchables_nb = self.data().transitions.filter(
		t => t.launchable).length;
	    return "Number of launchable transitions : " + launchables_nb;
	} else {return "";}
    });


// ** cy graph
    self.display_cy_graph = function() {
	if (self.data())
	{
	    pnet_cy = new make_pnet_graph(
		self.data(),
		document.getElementById('pnet_cy'),
		self);
	    pnet_cy.update(self.data());
            pnet_cy.run();
	}
    };
    
// ** data setup

    
    self.request_data = function (mol_desc, pnet_index, data_fun) {
        utils.ajax_get(
            {command: "pnet_from_mol",
             mol_desc: mol_desc,
	     pnet_id : pnet_index,
	     target: self.container_id}
        ).done(data_fun);
    }

    self.initialise = function(mol_desc, pnet_index) {
        self.request_data(
	    mol_desc,
	    pnet_index,
	    function(data) {
                console.log("Initialising with data", data);
		self.placeVM.disable();
		self.transitionVM.disable();
		self.data(data.data.pnet);
		self.display_cy_graph();
	    }
	);
    }
    
    self.disable = function() {self.data(null);}
    
    
// ** functions called by the cy graph to display node data
    self.set_node_selected = function(node_data) {
	if (node_data.type == "place") {
	    self.placeVM.enable(
		node_data.index,
		self.data().places[node_data.index]);
	    self.transitionVM.disable();
	} else if (node_data.type = "transition") {
	    self.transitionVM.enable(
		node_data.index,
		self.data().transitions[node_data.index]);
	    self.placeVM.disable();
	    console.log(self.data().transitions[node_data.index]);
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
	     molecule : self.data().molecule,
             pnet_id : self.data().id,
	     place_index : pindex,
             token: JSON.stringify(token),
	     target: self.container_id}
        ).done(
	    function (data)
	    {	
		self.data(data.data.pnet);
		self.placeVM.update();
		pnet_cy.update(self.data());
	    });
    }
    
// ** transition_launch*
    self.launch_transition = function() {
	
	var tindex = self.transitionVM.data.index;
	utils.ajax_get(
	    {command: "launch_transition",
	     molecule : self.data().molecule,
             pnet_id : self.data().id,
	     transition_index : tindex,
	     target: self.container_id}
        ).done(
	    function (data)
	    {	
		self.data(data.data.pnet);
		self.transitionVM.update();
		pnet_cy.update(self.data());
	    });

    }
    

    self.global_sim_update = function() {
	console.log(self.data());
	if (self.data()) {
            console.log("Updating with data", self.data());
	    self.request_data(
		self.data().molecule,
		self.data().id,
		function(data) {
		    self.data(data.data.pnet);
		    self.placeVM.update();
		    self.transitionVM.update();
		    pnet_cy.update(self.data());
		});

	}
    }

};



