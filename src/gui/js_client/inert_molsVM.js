function InertMolsVM(bactVM) {
    var self = this;
    self.bactVM = bactVM;
    
    self.mols = ko.observableArray();
    self.selected_mol_index = ko.observable();
    self.mol_quantity_input = ko.observable(0);

    
    self.current_mol_name = ko.computed(
	function() {
	    if (self.selected_mol_index() in self.mols())
	    {return self.mols()[self.selected_mol_index()]["mol_name"]}
	    else {return ""}
	});

    self.update = function(inert_mols_data) {
	self.mols.removeAll();
	
        for (var i = 0; i < inert_mols_data.length; i++) {
            self.mols.push(
                {
                    mol_name : inert_mols_data[i]["mol"],
                    mol_number : inert_mols_data[i]["nb"],
                    status : ko.observable("")
                });
        }
    };

// ** mol_select   
    self.mol_select = function(index) {
	if (self.selected_mol_index() in self.mols()) {
	    self.mols()[self.selected_mol_index()]["status"]("")
	}
	if (index != self.selected_mol_index())
	{
	    self.mols()[index]["status"]("active");
	    self.selected_mol_index(index);
	}
    }

    self.remove_mol = function() {
        utils.ajax_get(
            {command:"remove_mol",
	     container:"bactery",
	     mol_desc:self.current_mol_name()}
        ).done(self.bactVM.set_bact_data);
    }
	
    self.set_mol_quantity = function() {
        utils.ajax_get(
            {command:"set_mol_quantity",
	     container:"bactery",
	     mol_desc:self.current_mol_name(),
	     mol_quantity : self.mol_quantity_input}
        ).done(self.bactVM.set_bact_data);
    }
}
