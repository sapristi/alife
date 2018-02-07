
w3.includeHTML();

// semantic-ui 
$('#tab_menu .item').tab();
$('#mol_name_display').accordion();
$('.ui.dropdown').dropdown();
//$('#left_sim_sticky').sticky({offset:100});


// viewmodel
var initVM = function() {
    var self = this;
    self.simVM = new SimViewModel();
    self.molbuilderVM = new MolBuilderViewModel (self.simVM);
    self.molbuilderVM.init_setup();
    
    masterVM =	{
	simVM : self.simVM,
	molbuilderVM : self.molbuilderVM
    }

    ko.applyBindings(masterVM);
};

initVM();

