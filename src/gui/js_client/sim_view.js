
function SimViewModel () {
    var self = this;
    self.pnetVM = new PNetViewModel();
    self.bactVM = new BactViewModel(self.pnetVM);
    self.bactVM.init_data();
}
