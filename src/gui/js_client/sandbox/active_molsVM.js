function ActiveMolsVM(bactVM) {
    var self = this;
    self.bactVM = bactVM;
        
    self.mols = ko.observableArray();
    self.selected_mol_index = ko.observable();

    self.pnet_indexes = ko.observableArray();
    self.selected_pnet_id = ko.observable();

    self.mols_data = function() {
	var trim = function(x) {
	    return {mol : x.mol,
		    qtt: x.qtt}};
	return self.mols().map(trim);};
    
    self.selected_pnet_id.subscribe(
	function (new_id) {
	    console.log(new_id);
	    self.bactVM.pnetVM.initialise(
		self.mols()[self.selected_mol_index()].mol,
		self.selected_pnet_id());
	});
    
    self.current_mol_name = ko.computed(
	function() {
	    if (self.selected_mol_index() in self.mols())
	    {return self.mols()[self.selected_mol_index()].mol}
	    else {return ""}
	});

    
    self.update = function(inert_mols_data) {
	self.mols.removeAll();
	
        for (var i = 0; i < inert_mols_data.length; i++) {
            self.mols.push(
                {
                    mol : inert_mols_data[i].mol,
                    qtt : inert_mols_data[i].qtt,
                    status : ko.observable("")
                });
        }
    };

// ** mol_select   
    self.mol_select = function(index) {
	if (self.selected_mol_index() in self.mols()) {
	    self.mols()[self.selected_mol_index()]["status"]("")
	    self.pnet_indexes.removeAll();
	}
	if (index != self.selected_mol_index())
	{
	    self.mols()[index]["status"]("active");
	    self.selected_mol_index(index);

	    utils.ajax_get(
		{command : "pnet_ids_from_mol",
		 mol_desc : self.mols()[index].mol,
		 target : self.bactVM.container_id}
	    ).done(function(data) {
		self.pnet_indexes(data.data);});
	    
	}
    }

    self.remove_mol = function() {
        utils.ajax_get(
            {command:"remove_mol",
	     target:self.bactVM.container_id,
	     mol_desc:self.current_mol_name()}
        ).done(self.bactVM.set_bact_data);
    }
	
    self.set_mol_quantity = function() {
        utils.ajax_get(
            {command:"set_mol_quantity",
	     target:self.bactVM.container_id,
	     mol_desc:self.current_mol_name(),
	     mol_quantity : self.mol_quantity_input}
        ).done(self.bactVM.set_bact_data);
    }
}
