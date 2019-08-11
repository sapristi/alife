Vue.component('mol-vue', {
    props: ["mol"],
    methods: {
        compile: function() {
            this.$parent.set_mol(this.mol);
        },
        restore: function() {
            this.mol = this.$parent.mol;
        },
        send: function() {
            this.$root.$emit("send", this.mol);
        }
    }
});


Vue.component('prot-vue', {
    props: ["prot"],
    methods: {
        compile: function() {
            this.$parent.set_prot(this.prot);
        },
        restore: function() {
            this.prot = this.$parent.prot;
        },
        send: function () {this.$root.$emit("send");}    },
    mounted: function() {
        this.$root.$on('insert_into_prot', acid => {
            console.log(acid);
            utils.insertAtCursor($("#molbuilder_prot_text"), acid);
        });
    }
});

Vue.component('cytoscape-vue', {
    props: ["pnet", "pnet_cy"],
    methods: {
        display_cy_graph() {
            this.pnet_cy = make_pnet_graph(
                this.pnet,
                document.getElementById('molbuilder_pnet_cy'),
                this);
            this.pnet_cy.update(this.pnet);
            this.pnet_cy.run();
        }
    },
    watch: {
        pnet: function(pnet) {console.log("Pnet changed;");
                              this.display_cy_graph();}
    }
});


Vue.component('acid-selection-vue', {
    data: function () {return {acid_examples: []};},
    created: function() {
        utils.ajax('GET', "/api/utils/acids").done(
	          data => {
                console.log(this.acid_examples);
                console.log("Created: ", this);
                this.acid_examples = data.data;
                console.log(this.acid_examples);
          	});
    },
    methods: {
        send_acid: function(acid) {this.$root.$emit('insert_into_prot', JSON.stringify(acid));}
    }
});

molbuilder_vue = new Vue ({
    data: function () { return {mol: "", prot: "", pnet: null};},
    methods: {
        set_mol : function(mol) {
            this.mol = mol;
            this.set_data_from_mol();
        },
        set_prot: function(prot) {
            this.prot = prot;
            utils.ajax(
                'POST', "/api/utils/build/from_prot", JSON.parse(this.prot.replace("\n", ""))
            ).done(
	              data => {
                    this.mol = data.mol;
                    this.pnet = data.pnet;
                });
        },
        set_data_from_mol() {
            utils.ajax(
                'POST', "/api/utils/build/from_mol",JSON.stringify(this.mol)
            ).done(
    	          data => {
                    this.pnet = data.pnet;
                    this.prot = JSON.stringify(data.prot).replace(/],/g, "],\n");
    	          });
        },
        send_to_sandbox(mol) {
            if (mol == "") {console.log("nothing to send"); return;}
            console.log("Sending ", mol);
            var bc_chan = new BroadcastChannel("to_sandbox");
            bc_chan.postMessage({
                command : "add mol",
                data : mol
            });
            bc_chan.close();
        }
    },
    el: "#main_vue",
    events: {
        set_mol: function(mol){
            console.log("Set mol event:", mol);
        }
    },
    created: function () {
        this.$on("send", mol => {
            if (mol == undefined) {mol = this.mol;}
            this.send_to_sandbox(mol);});
        this.bc_receive = new BroadcastChannel("to_molbuilder");
        var self = this;
        this.bc_receive.onmessage = function(msg) {
            console.log("Received", msg);
            switch (msg.data.command) {
            case "set mol":
                self.set_mol(msg.data.data);
                break;
            default : console.log("did not recognize command", msg.data.command);
            }
        };

    }
});
 

