
// semantic-ui 
$('#tab_menu .item').tab();
$('#mol_name_display').accordion();
$('.ui.dropdown').dropdown();


// viewmodel
var initVM = function() {
    self.pnetVM = new PNetViewModel();
    self.protVM = new ProtViewModel();
    self.bactVM = new BactViewModel(pnetVM, protVM);
    self.mainVM = new MainViewModel(bactVM);
    masterVM =	{
	bactVM : self.bactVM,
	pnetVM : self.pnetVM,
	mainVM : self.mainVM,
	protVM : self.protVM
    }

    ko.applyBindings(masterVM);
    bactVM.init_data();
};

initVM();

