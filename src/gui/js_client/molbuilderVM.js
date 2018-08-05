function MolBuilderViewModel (simVM) {
    var self = this;
    self.simVM = simVM;
    
    self.prot_text = ko.observable("");
    self.mol_text = ko.observable("");
    self.acid_examples = ko.observableArray();
    self.change = ko.observable(false);
    self.data = {
	pnet : "",
	prot : "",
	mol : ""
    };
    
    self.initialised = ko.observable(false);
    self.active = ko.observable(false);

    self.enable = function () {
	self.active(true);
	self.fit(); };
    self.disable = function() {
	self.active(false);
    };

    self.reset_graph_view = function() {
	self.display_cy_graph();}
    
    
    self.display_cy_graph = function() {
	
	self.pnet_cy = new make_pnet_graph(
	    self.data.pnet,
	    document.getElementById('molbuilder_pnet_cy'),
	    self);
	self.pnet_cy.update(self.data.pnet);
        self.pnet_cy.run();

	
    };

    
    self.set_data_from_mol = function(mol_desc) {
        utils.ajax_get(
            {command: "build_all_from_mol",
             mol_desc: mol_desc,
    	     target: "general"}
        ).done(
    	    function (data)
    	    {
    		self.data.pnet = data.data.pnet;
    		self.data.prot = data.data.prot;
		
    		self.prot_text(
    		    JSON.stringify(self.data.prot)
    			.replace(/],/g, "],\n"));
    		self.change(!self.change());
    		self.display_cy_graph();

    	    });
    };

    


    self.init_from_mol = function(bactVM) {
	self.data.mol = bactVM.current_mol_name();
	self.set_data_from_mol(self.data.mol);
	self.mol_text(self.data.mol);
    }


    self.init_setup = function() {
	utils.ajax_get(
            {command: "list_acids",
	     target: "general"}
	).done(
	    function (data)
	    {
		self.acid_examples(data.data);
		self.initialised(true);
	    });
    }

    self.commit_prot = function() {
	var prot = JSON.parse(self.prot_text());
	
	utils.ajax_get(
            {command: "build_all_from_prot",
	     target: "general",
	     prot_desc : JSON.stringify(prot)}
	).done(
	    function (data)
	    {
		self.data.mol = data.data.mol;
		self.mol_text(data.data.mol);
		self.data.pnet = data.data.pnet;
		self.display_cy_graph();
	    });
    }
    self.commit_mol = function() {
	var mol = (self.mol_text());
	self.set_data_from_mol(mol);
    }

    self.send_prot_to_sandbox = function() {
	utils.ajax_get(
            {command: "add_mol",
	     target: "sandbox",
	     mol_desc : self.data.mol}
	).done(
	    function (data)
	    {
		self.simVM.bactVM.set_bact_data(data);
	    });

    }
    self.send_mol_to_sandbox = function() {
	utils.ajax_get(
            {command: "add_mol",
	     target: "sandbox",
	     mol_desc : self.mol_text()}
	).done(
	    function (data)
	    {
		self.simVM.bactVM.set_bact_data(data);
	    });

    }

    
    self.insert_acid_in_prot = function(acid) {
	utils.insertAtCursor($("#molbuilder_prot_text"), JSON.stringify(acid));
	
    }

    self.set_node_selected = function(node_data) {
    };
    self.set_node_unselected = function() {
    };
}
