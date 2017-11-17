

// * taskviewmodel
// Main taskview

function BactViewModel(pnetVM, protVM) {
    var self = this;

// ** variables
    self.pnetVM = pnetVM;
    self.protVM = protVM;
    
    self.mols = ko.observableArray();
    self.selected_mol = ko.observable(-1);
    self.pnet_show = ko.observable(true);

    self.mol_quantity_input = ko.observable(0);
    
    self.current_mol_name = ko.computed(
	function() {
	    if (self.selected_mol() >= 0
		&& self.selected_mol() < self.mols().length)
	    {return self.mols()[self.selected_mol()]["mol_name"]}
	    else {return ""}
	});
    
    
// ** examine a molecule
    self.examine_mol = function(mol_data){
        self.pnetVM.set_data(mol_data.mol_name);
	self.protVM.set_data(mol_data.mol_name);
    }
    
// ** update_bact
    self.set_bact_data = function(data){
	self.mols.removeAll();
        mols_data = data.data;
        for (var i = 0; i < mols_data.length; i++) {
            self.mols.push(
                {
                    mol_name : mols_data[i]["mol"],
                    mol_number : mols_data[i]["nb"],
                    status : ko.observable("")
                });
        }
	self.pnetVM.global_sim_update();
    };
    
    self.update = function() {
        utils.ajax_get(
            {command:"get_elements",
	     container:"bactery"}
        ).done(self.set_bact_data);
    };

    
    self.eval_reactions = function() {
        utils.ajax_get(
            {command:"make_reactions",
	     container:"bactery"}
        ).done(self.set_bact_data);
    };
    
    self.make_sim_round = function() {
        utils.ajax_get(
            {command:"make_sim_round",
	     container:"bactery"}
        ).done(self.set_bact_data);
    };
// ** init_data
    self.init_data = function() {
        self.update();
    };

// ** mol_select   
    self.mol_select = function(index) {
	if (self.selected_mol() != -1
	    && self.selected_mol() < self.mols().length) {
	    self.mols()[self.selected_mol()]["status"]("")
	}
	self.mols()[index]["status"]("active");
	self.selected_mol(index);
	
	self.examine_mol(self.mols()[index])
    };

    self.remove_mol = function() {
        utils.ajax_get(
            {command:"remove_mol",
	     container:"bactery",
	     mol_desc:self.current_mol_name()}
        ).done(self.set_bact_data);
	
    }

    self.set_mol_quantity = function() {
        utils.ajax_get(
            {command:"set_mol_quantity",
	     container:"bactery",
	     mol_desc:self.current_mol_name(),
	     mol_quantity : self.mol_quantity_input}
        ).done(self.set_bact_data);
	
    }
    
    self.save_bactery = function() {
        utils.ajax_get(
            {command:"save_bactery",
	     container:"bactery"}
        ).done();
    }
    self.load_bactery = function () {
        utils.ajax_get(
            {command:"load_bactery",
	     container:"bactery"}
        ).done(self.set_bact_data);

    }
    
}


