
// semantic-ui 
$('#tab_menu .item').tab();
$('#mol_name_display').accordion();
$('.ui.dropdown').dropdown();


// viewmodel
var initVM = function() {
    
    self.simVM = new SimViewModel();
    self.molbuilderVM = new MolBuilderViewModel ();
    self.molbuilderVM.init_setup();
    
    masterVM =	{
	simVM : self.simVM,
	molbuilderVM : self.molbuilderVM
    }

    ko.applyBindings(masterVM);
};

initVM();

