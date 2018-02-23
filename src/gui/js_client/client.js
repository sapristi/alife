
// semantic-ui 
$('#tab_menu .item').tab();
$('#mol_name_display').accordion();
$('.ui.dropdown').dropdown();
//$('#left_sim_sticky').sticky({offset:100});


// viewmodel
var initVM = function() {
    var self = this;
    self.sandboxVM = new SandboxViewModel();
    self.molbuilderVM = new MolBuilderViewModel (self.sandboxVM);
    self.molbuilderVM.init_setup();
    self.simVM = new SimViewModel(self.sandboxVM);
    
    masterVM =	{
	simVM : self.simVM,
	molbuilderVM : self.molbuilderVM,
	sandboxVM : self.sandboxVM
    }

    ko.applyBindings(masterVM);
};

initVM();

