
function SimViewModel () {
    var self = this;
    self.pnetVM = new PNetViewModel();
    self.protVM = new ProtViewModel();
    self.bactVM = new BactViewModel(self.pnetVM, self.protVM);
    
    self.pnet_show = ko.observable(true);
    self.mol_show = ko.observable(false);
    
    self.on_pnet_show = ko.computed( function () {
	if (self.pnet_show())
	{self.pnetVM.enable();}
	else {self.pnetVM.disable();}
    });
    self.on_mol_show = ko.computed( function () {
	if (self.mol_show())
	{self.protVM.enable();}
	else {self.protVM.disable();}
    });
    
    self.bactVM.init_data();
}
