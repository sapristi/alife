


function SandboxViewModel () {
    var self = this;
    self.container_id = "sandbox"
    self.pnetVM = new PNetViewModel(self.container_id);
    self.bactVM = new BactViewModel(self.pnetVM, self.container_id);
    self.bactVM.init_data();


    self.send_to_molbuilder = function() {
        console.log("to implement with broadcast")
    }
    
    var vm = {
        sandboxVM : self
    }
        

    ko.applyBindings(vm);
}

SandboxViewModel()
