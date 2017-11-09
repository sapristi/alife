
// for the menu tab selection
$('.menu .item').tab();

// for the accordion
$('#mol_name_display').accordion();

// viewmodel
var initVM = function() {
    self.placeVM = new PlaceViewModel();
    self.pnetVM = new PNetViewModel(placeVM);
    self.bactVM = new BactViewModel(pnetVM);
    masterVM =	{
	placeVM : self.placeVM,
	bactVM : self.bactVM,
	pnetVM : self.pnetVM
    }

    ko.applyBindings(masterVM);
    bactVM.init_data();
};

initVM();

