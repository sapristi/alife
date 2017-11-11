

// * taskviewmodel
// Main taskview

function BactViewModel(pnetVM, protVM) {
    var self = this;

// ** variables
    self.mols = ko.observableArray();
    self.selected_mol = ko.observable(-1);
    self.pnet_show = ko.observable(true);
    self.pnetVM = pnetVM;
    self.protVM = protVM;
    
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
        mols_data = data.data["molecules list"];
        for (var i = 0; i < mols_data.length; i++) {
            self.mols.push(
                {
                    mol_name : mols_data[i]["mol"],
                    mol_number : mols_data[i]["nb"],
                    status : ko.observable("")
                });
        }
    };
    
    self.update = function() {
        utils.ajax_get(
            {command:"get_bact_elements"}
        ).done(self.set_bact_data);
    };

    
    self.eval_reactions = function() {
        utils.ajax_get(
            {command:"make_reactions"}
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

}


