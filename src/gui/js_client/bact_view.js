

// * taskviewmodel
// Main taskview

function BactViewModel(pnetVM) {
    var self = this;

// ** variables
    self.pnetVM = pnetVM;
    
    self.inert_mols = ko.observableArray();
    self.active_mols = ko.observableArray();
    
    self.selected_mol_index = ko.observable();

    self.mol_quantity_input = ko.observable(0);
    self.reactions_number_input = ko.observable(1);
    
    self.current_mol_name = ko.computed(
	function() {
	    if (self.selected_mol_index() in self.inert_mols())
	    {return self.mols()[self.selected_mol_index()]["mol_name"]}
	    else {return ""}
	});
    
    
    
// ** update_bact
    self.set_bact_data = function(data){
	self.active_mols.removeAll();
	self.inert_mols.removeAll();
        inert_mols_data = data.data.inert_mols;
        active_mols_data = data.data.active_mols;
        for (var i = 0; i < inert_mols_data.length; i++) {
            self.inert_mols.push(
                {
                    mol_name : inert_mols_data[i]["mol"],
                    mol_number : inert_mols_data[i]["nb"],
                    status : ko.observable("")
                });
        }
	
        for (var i = 0; i < active_mols_data.length; i++) {
            self.active_mols.push(
                {
                    mol_name : active_mols_data[i]["mol"],
                    mol_number : active_mols_data[i]["nb"],
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

    
    self.next_reactions = function(n) {
        utils.ajax_get(
            {command:"next_reactions",
	     n : self.reactions_number_input,
	     container:"bactery"}
        ).done(self.set_bact_data);
    };
    self.next_reaction = function() {
        utils.ajax_get(
            {command:"next_reactions",
	     n:1,
	     container:"bactery"}
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

	    var mol_name = self.mols()[index].mol_name
            self.pnetVM.initialise(mol_name);
	}
    };



// ** Hooks for the bact managing buttons
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

    
    self.reset_bactery = function () {
        utils.ajax_get(
            {command:"reset_bactery",
	     container:"bactery"}
        ).done(self.set_bact_data);

    }
    
    
    self.href_for_save_bactery_local = ko.computed (function() {
	var data = [];
	var textFile;
        for (var i = 0; i < self.inert_mols().length; i++) {
	    data.push(
                {
		    mol : self.inert_mols()[i]["mol_name"],
		    nb : self.inert_mols()[i]["mol_number"]
                });
        }

	var str_data = JSON.stringify(data);
	var raw_data = new Blob([str_data], {type: 'text/plain'});
	if (textFile !== null) {
	    window.URL.revokeObjectURL(textFile);
	}
	
	textFile = window.URL.createObjectURL(raw_data);
	return textFile;
    });

    
    self.load_bact_file = function(evt) {
	var file = evt.target.files[0];
	var reader = new FileReader();
	
        reader.onload = function(e) {
	    
	    utils.ajax_get(
            {command:"set_bactery",
	     container:"bactery",
	     bact_desc : reader.result}
        ).done(self.set_bact_data);
        }
	
	reader.readAsText(file);
	
    }
    document.getElementById('bact_load').addEventListener('change', self.load_bact_file, false);
}


