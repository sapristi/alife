
function SimViewModel () {
    var self = this;
    self.sandboxVM = "sandboxVM : missing" ;
    self.container_id = "simulation"
    // for the configuration before running
    self.config =
	    {
		reacs_config : {
		    transition_rate : ko.observable(10),
		    grab_rate : ko.observable(1),
		    break_rate : ko.observable(0.0001)},
		bact_nb : ko.observable(1),
		bact_initial_state : {
		    inert_mols : ko.observableArray(),
		    active_mols : ko.observableArray()}
	    };
    // after the simulation is launched
    self.bact_nb = ko.observable();
    self.bact_index_list = ko.computed(function () {
	var res = [];
	for (var i = 0; i <= self.bact_nb()-1; i++) {res.push(i);}
	return res});
    self.selected_bact_index = ko.observable();
    self.reac_nb_input = ko.observable();


    self.static_config = function() {
	var data = {
	    reacs_config : {
		transition_rate :
		self.config.reacs_config.transition_rate(),
		grab_rate :
		self.config.reacs_config.grab_rate(),
		break_rate :
		self.config.reacs_config.break_rate()
	    },
	    bact_nb : self.config.bact_nb(),
	    bact_initial_state : {
		inert_mols :
		self.config.bact_initial_state.inert_mols(),
		active_mols :
		self.config.bact_initial_state.active_mols()
	    }
	};
	return data;
    }
    
    self.valid_config = ko.computed(
	function() {
	    if (self.config.bact_nb()>0 &&
		self.config.reacs_config.transition_rate()>=0 &&
		self.config.reacs_config.grab_rate()>=0 &&
		self.config.reacs_config.break_rate()>=0)
	    {return "green";}
	    else {return "red";}
	});
    
    self.valid_init_state = ko.computed(
	function() {
	    if (self.config.bact_initial_state.inert_mols().length>0 ||
		self.config.bact_initial_state.active_mols().length>0)
	    {return "green";}
	    else {return "red";}
	});

    self.simulate = function() {
	utils.ajax_get(
	    {command:"simulate",
	     target:self.container_id,
	     reac_nb: self.reac_nb_input()}
	).done(function(data) {console.log(data);});}


	     
    self.commit_init = function() {
	utils.ajax_get(
	    {command:"init",
	     target:self.container_id,
	     config: JSON.stringify(self.static_config())}
	).done(function(data){
	    self.bact_nb(data.bact_nb);
	});
    };

    self.send_bact_to_sandbox= function() {
	utils.ajax_get(
	    {command:"send_bact_to_sandbox",
	     target: self.container_id,
	     bact_index : self.selected_bact_index()}
	).done(function(data){console.log(data);})
    };

    
// ** import from sandbox
    self.sandbox_import = function() {
	self.config.bact_initial_state.inert_mols(
	    self.sandboxVM.bactVM.inertMolsVM.mols_data());
	self.config.bact_initial_state.active_mols(
	    self.sandboxVM.bactVM.activeMolsVM.mols_data());
    }

// ** load and save
    self.save_sim_config = function() {
	var textFile;
	var data = self.static_config();
	var str_data = JSON.stringify(data);
	var blob_data = new Blob([str_data], {type: 'text/plain'});
	saveAs(blob_data, "config.scfg");
    };

    
    self.load_bact_file = function(evt) {
	var file = evt.target.files[0];
	var reader = new FileReader();
        reader.onload = function(e) {
	    var data = JSON.parse(reader.result);
	    self.config.bact_initial_state.inert_mols(
		data.inert_mols);
	    self.config.bact_initial_state.active_mols(
		data.active_mols);
	}
	reader.readAsText(file);
    }

    document.getElementById('sim_bact_load').addEventListener('change', self.load_bact_file, false);
    
    self.load_config_file = function(evt) {
	var file = evt.target.files[0];
	var reader = new FileReader();
        reader.onload = function(e) {
	    var data = JSON.parse(reader.result);
	    self.config.reacs_config.transition_rate(
		data.reacs_config.transition_rate);
	    self.config.reacs_config.grab_rate(
		data.reacs_config.grab_rate);
	    self.config.reacs_config.break_rate(
		data.reacs_config.break_rate);
	    self.config.bact_nb(data.bact_nb);
	    self.config.bact_initial_state.inert_mols(
		data.bact_initial_state.inert_mols);
	    self.config.bact_initial_state.active_mols(
		data.bact_initial_state.active_mols);
        }
	reader.readAsText(file);
    };
    document.getElementById('sim_cfg_load').addEventListener('change', self.load_config_file, false);

    return self;
}

var vm = SimViewModel()

ko.applyBindings({
    simVM : vm
});
