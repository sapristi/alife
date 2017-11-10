
// semantic-ui 
$('.menu .item').tab();
$('#mol_name_display').accordion();
$('.ui.dropdown').dropdown();

// viewmodel
var initVM = function() {
    self.transitionVM = new TransitionViewModel();
    self.placeVM = new PlaceViewModel();
    self.pnetVM = new PNetViewModel(placeVM, transitionVM);
    self.protVM = new ProtViewModel();
    self.bactVM = new BactViewModel(pnetVM, protVM);
    self.mainVM = new MainViewModel(bactVM);
    masterVM =	{
	placeVM : self.placeVM,
	bactVM : self.bactVM,
	pnetVM : self.pnetVM,
	transitionVM : self.transitionVM,
	mainVM : self.mainVM,
	protVM : self.protVM
    }

    ko.applyBindings(masterVM);
    bactVM.init_data();
};

initVM();

