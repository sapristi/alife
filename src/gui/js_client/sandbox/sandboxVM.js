
//$('#left_sim_sticky').sticky({offset:100});



function SandboxViewModel () {
    var self = this;
    self.container_id = "sandbox"
    self.pnetVM = new PNetViewModel(self.container_id);
    self.bactVM = new BactViewModel(self.pnetVM, self.container_id);
    self.bactVM.init_data();

    self.bc_receive = new BroadcastChannel("to_sandbox");
    

    self.bc_receive.onmessage = function(msg) {
        

        switch (msg.data.command) {
            case "update" :
                self.bactVM.update();
                alert("update");
                break;
            case "send data" :  
                var bc_chan = new BroadcastChannel("to_" + msg.data.target)
                bc_chan.postMessage({
                    command:"data",
                    data : "" });
                console.log("data sending to implement");
                bc_chan.close()
                break;
                
            default : console.log("did not recognize command" + msg.data.command)
        }};

    
    self.send_to_molbuilder = function(data) {
        var mol = data.current_mol_name();
        if (mol == "") {return;}

        var bc_chan = new BroadcastChannel("to_molbuilder");
        bc_chan.postMessage({
            command : "set data",
            data : mol
        });
        bc_chan.close();
        
    }
}

ko.applyBindings({
    sandboxVM : new SandboxViewModel()
})


