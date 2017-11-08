

// * taskviewmodel
// Main taskview

function BactViewModel(nodeVM) {
    var self = this;
    self.nodeVM = nodeVM;


// ** variables
    self.connect_uri = 'http://localhost:1512/sim_commands/';
    self.mols = ko.observableArray();
    self.selected_mol = ko.observable(-1);
    
    self.current_mol_name = ko.computed(
	function() {
	    if (self.selected_mol() >= 0
		&& self.selected_mol() < self.mols().length)
	    {return self.mols()[self.selected_mol()]["mol_name"]}
	    else {return ""}
	});
    
    
// ** examine a molecule
    self.examine = function(data){

        display_prot_graph = function(data) {
            
            var prot_cy = make_prot_graph(
                data["data"]["prot"],
                document.getElementById('prot_cy'));
            prot_cy.layout({name:"circle"}).run()
        }
        display_pnet_graph = function(data) {
            var pnet_cy = make_pnet_graph(
                data["data"]["pnet"],
                document.getElementById('pnet_cy'),
		nodeVM);

	    
            pnet_cy.layout({name:"cose"}).run();
        }
        
        utils.ajax(
            self.connect_uri,
            'GET',
            {command:"pnet_from_mol",
             mol_desc:data.mol_name,
	     container: "bacterie"}
        ).done(display_pnet_graph);

	utils.ajax(
            self.connect_uri,
            'GET',
            {command:"prot_from_mol",
             mol_desc:data.mol_name,
	     container: "bacterie"}
        ).done(display_prot_graph);
	    
	$('#mol_name_display').accordion('refresh');
    }
    
// ** update_bact
    self.update = function() {
	self.mols.removeAll();
	
        bact_data = function(data) {
            mols_data = data.data["molecules list"];
            for (var i = 0; i < mols_data.length; i++) {
                self.mols.push(
                    {
                        mol_name : mols_data[i]["mol"],
                        mol_number : mols_data[i]["nb"],
                        status : ko.observable("")
                    });
            }
        }
        
        utils.ajax(
            self.connect_uri,
            'GET',
            {command:"get_bact_elements"}
        ).done(bact_data);
    }

// ** init_data
    self.init_data = function() {
        self.update();
    }

// ** mol_select   
    self.mol_select = function(index) {
	if (self.selected_mol() != -1
	    && self.selected_mol() < self.mols().length) {
	    self.mols()[self.selected_mol()]["status"]("")
	}
	self.mols()[index]["status"]("active");
	self.selected_mol(index);
	
	self.examine(self.mols()[index])
    }
}


