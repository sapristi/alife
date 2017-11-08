
// for the menu tab selection
$('.menu .item').tab();

// for the accordion
$('#mol_name_display').accordion();


//pnet viewmodel
self.nodeViewModel = new NodeViewModel();

// bact viewmodel
var bactViewModel = new BactViewModel(nodeViewModel);
ko.applyBindings(bactViewModel);
bactViewModel.init_data();


