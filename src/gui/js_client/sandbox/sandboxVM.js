
//$('#left_sim_sticky').sticky({offset:100});



function SandboxViewModel () {
    var self = this;
    self.container_id = "sandbox"
    self.pnetVM = new PNetViewModel(self.container_id);
    self.bactVM = new BactViewModel(self.pnetVM, self.container_id);

    self.bc_receive = new BroadcastChannel("to_sandbox");

    
    self.env_keys = ko.observableArray();
    self.env = {
        transition_rate : ko.observable(),
        grab_rate : ko.observable(),
        break_rate : ko.observable()
    }

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
        
    };

    self.update = function() {
        utils.ajax_get(
            {command:"get_sandbox_data",
	     target:self.container_id}
        ).done(
            function(data) {
                for (var k in self.env) {
                    self.env[k](
                        data.data.env[k]);}

                self.bactVM.set_bact_data(data.data.bact);
                }
        );
    }

    
    self.commit_env = function(evt) {

        env_to_send = {}
        for (var k in self.env) {
            env_to_send[k] = parseFloat(self.env[k]());
        }
        env_to_send["random_collision_rate"] = 0;
        utils.ajax_get(
            {command:"set_environment",
	     target:self.container_id,
             env : JSON.stringify(env_to_send)
            }
        ).done(console.log("ok"));
    }


    self.save_sandbox = function() {
        
        utils.ajax_get(
            {command:"get_sandbox_data",
	     target:self.container_id}
        ).done(
            function(data) {
                str_data = JSON.stringify(data.data);
                blob_data = new Blob([str_data], {type: 'text/plain'});
                saveAs(blob_data, "sandbox.json");
            }
        );   
    }

    self.load_sandbox_file = function(evt) {
	var file = evt.target.files[0];
	var reader = new FileReader();
	
        reader.onload = function(e) {
	    
	    utils.ajax_get(
                {command:"set_sandbox",
	         target:self.container_id,
	         sandbox_desc : reader.result}
            ).done(self.set_bact_data);
        }
	
	reader.readAsText(file);
	
    }
    document.getElementById('sandbox_load').addEventListener('change', self.load_sandbox_file, false);

}

sandboxVM = new SandboxViewModel();

ko.applyBindings({
    sandboxVM : sandboxVM
})

sandboxVM.update();

