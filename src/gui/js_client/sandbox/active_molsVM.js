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
            if (new_id != undefined) {
	        self.bactVM.pnetVM.initialise(
		    self.mols()[self.selected_mol_index()].mol,
		    self.selected_pnet_id());
                }
	});
    
    self.current_mol_name = ko.computed(
	function() {
	    if (self.selected_mol_index() in self.mols())
	    {return self.mols()[self.selected_mol_index()].mol}
	    else {return ""}
	});

    
    self.update = function(active_mols_data) {
	self.mols.removeAll();
	
        for (var i = 0; i < active_mols_data.length; i++) {
            self.mols.push(
                {
                    mol : active_mols_data[i].mol,
                    qtt : active_mols_data[i].qtt,
                    status : ko.observable("")
                });
        }
    };

    
    self.update_selected_mol = function() {
        index = self.selected_mol_index();
	self.pnet_indexes.removeAll();
        
	utils.ajax_get(
	    {command : "pnet_ids_from_mol",
	     mol_desc : self.mols()[index].mol,
	     target : self.bactVM.container_id}
	).done(function(data) {
	    self.pnet_indexes(data.data);});
    }
    
    // ** mol_select   
    self.mol_select = function(index) {
        
        console.log("selected:", index, " ;previous:", self.selected_mol_index());
        
	if (self.selected_mol_index() in self.mols()) {
	    self.mols()[self.selected_mol_index()]["status"]("");
	    self.pnet_indexes.removeAll();
	}
	if (index != self.selected_mol_index())
	{
            self.selected_mol_index(index);
            self.update_selected_mol(index);
	} else {
            self.selected_mol_index(-1);
            self.bactVM.pnetVM.disable();
        }
    }

    
    
    self.remove_mol = function() {
        utils.ajax_get(
            {command:"remove_amol",
	     target:self.bactVM.container_id,
	     mol_desc:self.current_mol_name(),
             pnet_id:self.selected_pnet_id()}
        ).done(
            data => {self.bactVM.set_bact_data(data);
                self.update_selected_mol();}
        );
    }


    self.send_to_molbuilder = function() {
        var bc_chan = new BroadcastChannel("to_molbuilder");
        bc_chan.postMessage({
            command : "set data",
            data : self.mols()[self.selected_mol_index()]
        });
        bc_chan.close();
        
        console.log("bc : ");
        console.log(self.mols()[self.selected_mol_index()]);
        
    }
}
