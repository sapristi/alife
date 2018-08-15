

// * taskviewmodel
// Main taskview

function BactViewModel(pnetVM, container_id) {
    var self = this;
    self.container_id = container_id
// ** variables
    self.pnetVM = pnetVM;
    self.inertMolsVM = new InertMolsVM(self);
    self.activeMolsVM = new ActiveMolsVM(self);
    
    self.reactions_number_input = ko.observable(1);
    
    
    
// ** update_bact
    self.set_bact_data = function(data){
	
	self.inertMolsVM.update(data.data.inert_mols);
	self.activeMolsVM.update(data.data.active_mols);
	
	self.pnetVM.global_sim_update();
    };
    
    self.update = function() {
        utils.ajax_get(
            {command:"get_elements",
	     target:self.container_id}
        ).done(self.set_bact_data);
    };

    
    self.next_reactions = function(n) {
        utils.ajax_get(
            {command:"next_reactions",
	     n : self.reactions_number_input,
	     target:self.container_id}
        ).done(self.set_bact_data);
    };
    self.next_reaction = function() {
        utils.ajax_get(
            {command:"next_reactions",
	     n:1,
	     target:self.container_id}
        ).done(self.set_bact_data);
    };
// ** init_data
    self.init_data = function() {
        self.update();
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

	    var mol_name = self.mols()[index].mol
            self.pnetVM.initialise(mol_name);
	}
    };



// ** Hooks for the bact managing buttons
    self.remove_mol = function() {
        utils.ajax_get(
            {command:"remove_mol",
	     target:self.container_id,
	     mol_desc:self.current_mol_name()}
        ).done(self.set_bact_data);
	
    }

    self.set_mol_quantity = function() {
        utils.ajax_get(
            {command:"set_mol_quantity",
	     target:self.container_id,
	     mol_desc:self.current_mol_name(),
	     mol_quantity : self.mol_quantity_input}
        ).done(self.set_bact_data);
	
    }

    
    self.reset_bactery = function () {
        utils.ajax_get(
            {command:"reset_bactery",
	     target:self.container_id}
        ).done(self.set_bact_data);
	
    }
    
    self.save_bactery = function() {
	var inert_mols = self.inertMolsVM.mols_data();
	var active_mols = self.activeMolsVM.mols_data();
	var data = {active_mols:active_mols,inert_mols:inert_mols};
	var str_data = JSON.stringify(data);
	var blob_data = new Blob([str_data], {type: 'text/plain'});
	saveAs(blob_data, "bact.json");
    };
    
    self.load_bact_file = function(evt) {
	var file = evt.target.files[0];
	var reader = new FileReader();
	
        reader.onload = function(e) {
	    
	    utils.ajax_get(
            {command:"set_bactery",
	     target:self.container_id,
	     bact_desc : reader.result}
        ).done(self.set_bact_data);
        }
	
	reader.readAsText(file);
	
    }
    document.getElementById('bact_load').addEventListener('change', self.load_bact_file, false);
}


