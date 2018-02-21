
function SimViewModel () {
    var self = this;
    self.container_id = "simulation"
    self.pnetVM = new PNetViewModel(self.container_id);
    self.bactVM = new BactViewModel(self.pnetVM, self.container_id);
    self.bactVM.init_data();
}
