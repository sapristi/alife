function PlaceViewModel() {
    var self = this;
    var data;
    self.token_state = ko.observable();
    self.token_edit = ko.observable(false);
    
    
    self.set_data = function(place_data) {
	data = place_data;
	if (data.token == "no token")
	{ self.token_state("no_token");}
	else {
	    if (data.token.mol == "empty")
	    {self.token_state("empty_token");}
	    else
	     {self.token_state("occupied_token");}
	}
    }
    self.is_occupied = ko.computed(
	function ()
	{return (self.token_state() == "occupied_token");});
    self.edit_enabled_class = ko.computed(
	function ()
	{if (self.token_edit())  {return ""}
	 else {return "disabled"}});
};

function PNetViewModel(placeVM) {
    var self = this;
    var pnet_data;
    var pnet_cy;
    
    self.place_selected = ko.observable(false);
    self.current_node = ko.observable()

    var display_cy_graph = function() {
	pnet_cy = make_pnet_graph(
            pnet_data,
            document.getElementById('pnet_cy'),
	    self);
	    
        pnet_cy.layout({name:"cose"}).run();
    }
    
    self.set_data = function(data) {
	pnet_data = data;
	display_cy_graph();
    }

    self.set_node_selected = function(node_data) {
	console.log("node selected");
	self.place_selected(true);
	placeVM.set_data(node_data);}
    self.set_node_unselected = function() {
	self.place_selected(false);
    }
      
};


