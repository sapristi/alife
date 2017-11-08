// * taskviewmodel
// Main taskview

function BactViewModel() {
    var self = this;
    
// ** variables
    self.connect_uri = 'http://localhost:1512/sim_commands/';
    self.mols = ko.observableArray();
    self.selected_mol = -1;
    
// ** ajax request
    self.ajax = function(uri, method, data) {
        var request = {
            url: uri,
            dataType: 'json',
            data: data,
            crossDomain: true,
            success : function(json) {
                console.log(json);
            },
            error: function(jqXHR) {
                console.log("ajax error " + jqXHR.status);
            }
        };
        return $.ajax(request);
    }
    
// ** examine a molecule
    self.examine = function(data){

        exam_mol = function(data) {
            
            // var prot_cy = make_prot_graph(
            //     data["data"]["prot"],
            //     document.getElementById('prot_cy'));
            // prot_cy.layout({name:"circle"}).run()
            
            var pnet_cy = make_pnet_graph(
                data["data"]["pnet"],
                document.getElementById('pnet_cy'));
            pnet_cy.layout({name:"breadthfirst"}).run()
            
        }
        
        self.ajax(
            self.connect_uri,
            'GET',
            {command:"pnet_from_mol",
             mol_desc:data.mol_name,
	     container: "bacterie"}
        ).done(exam_mol);
    }
    
// ** update_bact
    self.update = function() {
        
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
        
        self.ajax(
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
	if (self.selected_mol != -1) {
	    self.mols()[self.selected_mol]["status"]("")
	}
	self.mols()[index]["status"]("active");
	self.selected_mol = index;
	
	self.examine(self.mols()[index])
    }
}

ko.applyBindings(new BactViewModel());


