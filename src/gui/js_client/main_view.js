
function SimViewModel (bactVM) {
    var self = this;
    self.pnet_show = ko.observable(true);
    self.mol_show = ko.observable(false);
    self.bactVM = bactVM;
    
    self.on_pnet_show = ko.computed( function () {
	if (self.pnet_show())
	{self.bactVM.pnetVM.enable();}
	else {self.bactVM.pnetVM.disable();}
    });
    self.on_mol_show = ko.computed( function () {
	if (self.mol_show())
	{self.bactVM.protVM.enable();}
	else {self.bactVM.protVM.disable();}
    });
    
}
