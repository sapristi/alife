function InertMolsVM(bactVM) {
    var self = this;
    self.bactVM = bactVM;
    
    self.mols = ko.observableArray();
    self.selected_mol_index = ko.observable();
    self.mol_quantity_input = ko.observable(0);

    self.mols_data = function() {
	trim = function(x) {
	    return {mol : x.mol,
		    qtt: x.qtt,
		    ambient:x.ambient  }};
	return self.mols().map(trim);};
    
    self.current_mol_name = ko.computed(
	function() {
	    if (self.selected_mol_index() in self.mols())
	    {return self.mols()[self.selected_mol_index()]["mol"]}
	    else {return ""}
	});

    self.update = function(inert_mols_data) {
	self.mols.removeAll();
	
        for (var i = 0; i < inert_mols_data.length; i++) {
            self.mols.push(
                {
                    mol : inert_mols_data[i]["mol"],
                    qtt : inert_mols_data[i]["qtt"],
		    ambient: inert_mols_data[i]["ambient"],
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
            {command:"remove_imol",
	     target: self.bactVM.container_id,
	     mol_desc:self.current_mol_name()}
        ).done(self.bactVM.set_bact_data);
    }
	
    self.set_mol_quantity = function() {
        utils.ajax_get(
            {command:"set_imol_quantity",
	     target: self.bactVM.container_id,
	     mol_desc:self.current_mol_name(),
	     mol_quantity : self.mol_quantity_input}
        ).done(self.bactVM.set_bact_data);
    }

    /* 
     * self.send_to_molbuilder = function(test) {
     *     console.log(test)
     *     var mol = self.current_mol_name();
     *     if (mol == "") {return;}

     *     var bc_chan = new BroadcastChannel("to_molbuilder");
     *     bc_chan.postMessage({
     *         command : "set data",
     *         data : mol
     *     });
     *     bc_chan.close();
       
     *     console.log("bc : ");
     *     console.log(mol);
     * } */
}
