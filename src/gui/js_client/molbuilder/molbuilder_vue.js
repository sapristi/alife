Vue.component('mol-vue', {
    props: ["mol"],
    methods: {
        compile: function() {
            this.$parent.set_mol(this.mol);
        },
        restore: function() {
            this.mol = this.$parent.mol;
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
        send: function () {}    },
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
                              this.display_cy_graph()}
    }
});


Vue.component('acid-selection-vue', {
    data: function () {return {acid_examples: []}},
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
        send_acid: function(acid) {this.$root.$emit('insert_into_prot', JSON.stringify(acid))}
    }
});

molbuilder_vue = new Vue ({
    data: function () { return {mol: "", prot: "", pnet: null}},
    methods: {
        set_mol : function(mol) {
            this.mol = mol;
            this.set_data_from_mol();
        },
        set_prot: function(prot) {
            this.prot = prot;
            utils.ajax_get(
                {command: "build_all_from_prot",
	               target: "general",
	               prot_desc : JSON.stringify(this.prot_obj)}
	          ).done(
	              data => {
                    this.mol = data.data.mol;
                    this.pnet = data.data.pnet;
                });
        },
        set_data_from_mol() {
            utils.ajax_get(
                {command: "build_all_from_mol",
                 mol_desc: this.mol,
    	           target: "general"}
            ).done(
    	          data => {
                    this.pnet = data.data.pnet;
                    this.prot = JSON.stringify(data.data.prot).replace(/],/g, "],\n")
    	          });
        }
    },
    el: "#main_vue",
    events: {
        set_mol: function(mol){
            console.log("Set mol event:", mol);
        }
    },
});
 

