function ProtViewModel() {
    var self = this;
    var prot_cy;

    
    self.initialised = ko.observable(false);
    self.active = ko.observable(true);
    self.change = ko.observable(false);
    self.mol_name = ko.observable("");

    self.enable = function () {
	self.active(true);self.display_cy_graph()    };
    self.disable = function() {
	self.active(false);
    };

    
    self.display_cy_graph = function() {
	if (self.active() && self.initialised)
	{
	    prot_cy = make_prot_graph(
		self.prot_data,
		document.getElementById('prot_cy'),
		self);
	    
            prot_cy.layout({name:"circle"}).run();

	    $('#mol_name_display').accordion('refresh');
	}	
    };

    
    self.set_data = function(mol_desc) {
	
	utils.ajax_get(
            {command:"prot_from_mol",
             mol_desc:mol_desc,
	     container: "general"}
        ).done(
	    function(data)
	    {self.prot_data = data.data.prot;
	     self.change(!self.change());
	     self.initialised(true);
	     self.display_cy_graph();
	    });	
    }
}
