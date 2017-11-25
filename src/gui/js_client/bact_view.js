

// * taskviewmodel
// Main taskview

function BactViewModel(pnetVM) {
    var self = this;

// ** variables
    self.pnetVM = pnetVM;
    
    self.mols = ko.observableArray();
    self.selected_mol_index = ko.observable();

    self.mol_quantity_input = ko.observable(0);
    
    self.current_mol_name = ko.computed(
	function() {
	    if (self.selected_mol_index() in self.mols())
	    {return self.mols()[self.selected_mol_index()]["mol_name"]}
	    else {return ""}
	});
    
    
    
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
        for (var i = 0; i < self.mols().length; i++) {
	    data.push(
                {
		    mol : self.mols()[i]["mol_name"],
		    nb : self.mols()[i]["mol_number"]
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


