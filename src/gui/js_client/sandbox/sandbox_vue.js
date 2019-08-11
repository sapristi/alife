Vue.component("environment", {
    computed: {
        env() {return this.$store.state.env;}
    },
    template: `
        <div>
            <div v-for="(v,k) in this.env" class="ui list" data-bind="foreach : Object.keys(env)">
                <div class="item">
                    <div class="ui label" data-bind="text:$data">{{k}} </div>
                    <input type="text" v-model="env[k]" ata-bind="textInput : $parent.env[$data]">
                </div>
            </div>
        </div>
    `
})

Vue.component("sim-reaction-controls",{
    data: function() {return {reac_nb_input: null};},
    methods: {
        _next_reactions(n) {
            utils.ajax('POST', `/api/sandbox/reaction/next/${n}`).done(
                data => {this.$root.$emit("update");}
            );
        },
        next_reaction() {this._next_reactions(1);},
        next_reactions() {this._next_reactions(this.reac_nb_input);}
    },
    template: `
        <div class="ui fixed top sticky"
		         style="max-width:100px;position:fixed;top:100px" id="left_sim_sticky">
		        <div class="ui segment"
			           style="max-width:100px; margin-left:110px; padding-left:0px; padding-right:0">
			          <h4 class="ui horizontal divider header">Simulation ok</h4>
                
			          <button class="ui primary button tooltip"
                    v-on:click="next_reaction"
				                style="padding-left:5px;padding-right:5px">
			              Next reaction
			              <span class="tooltiptext">Evaluates the next reaction</span>
			          </button>
			          <div class="ui action input">
			              <button class="ui primary button tooltip"
                        v-on:click="next_reactions"
				                    style="padding-left:5px;padding-right:5px">
				                Next reactions
				                <span class="tooltiptext">Evaluates the next reaction</span>
			              </button>
			              <input placeholder="number"
				                   type="text"
				                   size="4"
                           v-model="reac_nb_input"/>
			          </div>
		        </div>
        </div>
`
});



Vue.component("sim-general-controls", {
    data: function () {return {selected_initial_state: null, initial_states: []};},
    mounted : function () {
        utils.ajax('GET', "/api/sandbox/state").done(
            data => {this.initial_states = data; }
        ); $('#state-dropdown')
            .dropdown()
        ;

    },
    methods: {
        load_init_state() {
            utils.ajax('PUT', `/api/sandbox/state/${this.selected_initial_state}`).done(
                data => {this.$root.$emit("update");});
            }
    },
    template: `
        <div class="ui segment">
            <select class="ui dropdown" id="state-dropdown"
                v-model="selected_initial_state">
                <option value="">Initial state</option>
                <option v-for="state_name in initial_states"
                        :value="state_name" :key="state_name">{{state_name}}</option>
            </select>
            <button class="ui primary button"
                v-on:click="load_init_state">Load state</button>
        </div>
    `

});


Vue.component("mols-list", {
    props: ["mols", "columns", "mol_type"],
    data: function () {
        return {selected_mol: null};
    },
    template: `
        <table class="ui fixed selectable table">
			      <thead><tr>
				        <th v-for="col in columns" v-bind:class="col.css_class" >{{col.title}}</th>
			      </tr></thead>
			      <tbody>
				        <tr v-for="mol in mols" v-on:click="select(mol)" v-bind:class="{ active: mol.mol == selected_mol_mol() }" :key="mol.mol">
                    <td v-for="col in columns" v-bind:style="col.style">{{mol[col.property]}}</td>
				        </tr>
			      </tbody>
        </table>
    `,
    methods: {
        select: function(mol) {
            if (this.selected_mol == null) {this.selected_mol = mol;}
            else if (mol.mol == this.selected_mol.mol) {this.selected_mol = null;}
            else {this.selected_mol = mol;}
        },
        selected_mol_mol() {
            if (this.selected_mol == null) return null;
            else return this.selected_mol.mol;
        }
    },
    watch: {
        selected_mol: function() {
            if (this.selected_mol !== null) {
                this.$store.commit('selected_mol_' + this.mol_type, this.selected_mol);
            } else {this.$store.commit('unselected_mol_'+ this.mol_type);}
        },
        mols: function() {
            if (this.selected_mol != null &&
                this.selected_mol != undefined &&
                this.mols.find(e => {return e.mol === this.selected_mol.mol;}) === undefined)
            {this.selected_mol = null;}
        }
    }
});

Vue.component("inert-mols-controls",{
    data: function () {
        return {mol: null,
                qtt: null,
                disabled: true};
    },
    computed: {
        mol_data() {return this.$store.state.selected_imol;}
    },
    watch: {
        mol_data(mol_data) {
            if (this.mol_data == null) {this.mol = null; this.qtt = null; this.disabled=true;}
            else {this.mol = this.mol_data.mol; this.qtt = this.mol_data.qtt; this.disabled=false;}
        }
    },
    mounted: function(){
        this.$root.$on('selected_mol_inert', mol =>
                       {this.mol = mol.mol; this.qtt = mol.qtt; this.disabled=false;});
        this.$root.$on('unselected_mol_inert', mol_type =>
                       {this.mol = null; this.qtt = null; this.disabled=true;});
    },
    methods: {
        remove_mol() {utils.ajax('DELETE', `/api/sandbox/imol/${this.mol}`).done(
            data => {this.$store.commit("set_imols", data.data.inert_mols);}
        );},
        set_mol_quantity() {
            utils.ajax('PUT', `/api/sandbox/imol/${this.mol}?qtt=${this.qtt}`).done(
                data=> {this.$store.commit("set_imols", data.data.inert_mols);}
            );},
        send_to_molbuilder() {this.$root.$emit("send_to_molbuilder", this.mol);}
    }
});


Vue.component("active-mols-controls",{
    data: function () {
        return {
            pnet_ids: [],
            disabled: true,
            selected_pnet: null
        };
    },
    computed: {
        mol() { var mol_raw = this.$store.state.selected_amol;
            if (mol_raw == null) {return null;} else {return mol_raw.mol;}},
        must_update() {return this.$store.state.update;}
    },
    methods: {

        update: function() {
            if (this.mol != null) {this.init();} else this.clear();
        },
        init: function () {
            this.disabled=false;
            utils.ajax('GET', `/api/sandbox/amol/${this.mol}`
	          ).done(data => {
	              this.pnet_ids = data.data;
                this.selected_pnet = this.pnet_ids[0];
                console.log(this);});
        },
        update_pnet(pnet_id) {
            console.log("Update pnet with ", pnet_id, "in", this.pnet_ids);

            if (pnet_id == null) {this.$store.commit('pnet/clear');}
            else {
                utils.ajax(
                    'GET', `/api/sandbox/amol/${this.mol}/pnet/${pnet_id}`).done(
                        data => {console.log("pnet updated with ", data);
                            this.pnet = data.data.pnet;
                            this.$store.commit('pnet/set',{
                                pnet_id: this.selected_pnet,
                                mol: this.mol,
                                pnet: data.data.pnet
                            });
                                });}
        },
        clear: function () {
             this.disabled=true; this.pnet_ids=[];
            this.selected_pnet = null;
            this.$store.commit('pnet/clear');
        },
        send_to_molbuilder() {this.$root.$emit("send_to_molbuilder", this.mol);},
        remove_mol() {
            utils.ajax('DELETE', `/api/sandbox/amol/${this.mol}/pnet/${this.selected_pnet}`).done(
                _ => {this.$store.commit("update");}
            );
        }
    },
    watch: {
        mol: function(val) { this.update(); },
        selected_pnet: function(val) {
            if (this.selected_pnet === null){this.clear();}
            else {this.update_pnet(this.selected_pnet);}
        },
        must_update() {
            console.log("pnet update required");
            this.update();
            this.update_pnet(this.selected_pnet);
        }
    }
});

Vue.component("reactant",{
    data: function() {return {mol: null, pnet_id: null};}
    
});



Vue.component("reactions", {
    data: function () {return {
        transitions: [],
        breaks: [],
        grabs: [],
        raw_data: null
    };},
    methods: {
        int_of_string (rate) {
            var res;
            if (rate.split("/").length > 1) {
                var frac = rate.split("/");
                var num = frac[0]; var det = frac[1];
                res = (parseFloat(num) / parseFloat(det));
            } else { res = parseFloat(rate);}
            return res;
        },
        update() {
            utils.ajax("GET", "/api/sandbox/reaction").done(
                data => {
                    this.transitions= data.transitions;
                    this.grabs= data.grabs;
                    this.breaks= data.breaks;
                    
                    this.raw_data = data;
                }
            );
            $('#reactions-accordion').accordion({exclusive: false});
        }
    },
    computed: {
        must_update() {console.log("reactions saw store updating");return this.$store.state.update;},
        
        total_rates() {if (this.raw_data == null) {return {transitions:0, grabs: 0, breaks: 0};}
                       
                       return {transitions: this.int_of_string(this.raw_data.env.transition_rate) * this.int_of_string(this.transitions.total),
                               grabs:  this.int_of_string(this.raw_data.env.grab_rate) * this.int_of_string(this.grabs.total),
                               breaks: this.int_of_string(this.raw_data.env.break_rate) * this.int_of_string(this.breaks.total)
                              };
                      }
    },
    mounted: function() {
        this.update();
    },
    watch: {
        must_update() {console.log("reactions update required");this.update();}
    }
});


inert_mols_columns = [
    {css_class: "thirteen wide", title: "Molecule name",
     property: "mol", style:"word-wrap:break-word"},
    {css_class: "two wide", title: "Quantity", property: "qtt"},
    {css_class: "two wide", title: "Ambient", property: "ambient"}
];

active_mols_columns =  [
    {css_class: "thirteen wide", title: "Molecule name",
     property: "mol", style:"word-wrap:break-word"},
    {css_class: "three wide", title: "Quantity", property: "qtt"}
];

const store = new Vuex.Store({
    modules: {
        pnet: pnet_store
    },
    state: {
        imols: [],
        selected_imol: null,
        
        amols: [],
        selected_amol: null,

        update: false,

        env: {}
    },
    mutations: {
        set_imols(state, imols) {state.imols = imols;},
        set_amols(state, amols) {state.amols = amols;},
        set_env(state, env) {state.env = env;},
        selected_mol_inert(state, mol) {state.selected_imol = mol;},
        unselected_mol_inert(state) {state.selected_imol = null;},
        selected_mol_active(state, mol) {state.selected_amol = mol;},
        unselected_mol_active(state) {state.selected_amol = null;},
        update(state) {state.update = !state.update;}
    }
});


sandbox_vue = new Vue({
    data: function (){
        return {
            env: null,
            inert_mols: [],
            active_mols: [],
            test_mols: []};
    },
    el: "#sandbox_vue",
    store,
    methods: {
        update: function () {
            utils.ajax('GET', "/api/sandbox"
            ).done(
                data =>  {
                    this.env = data.data.env;
                    this.inert_mols = data.data.bact.inert_mols;
                    this.active_mols = data.data.bact.active_mols;
                    this.$store.commit("set_imols", this.inert_mols);
                    this.$store.commit("set_amols", this.active_mols);
                    this.$store.commit("set_env", this.env);
                    this.$store.commit("update");
                }
            );
        },
        send_to_molbuilder: function(mol) {
            if (mol == "") {return;}
            console.log("Sending", mol, "to molbuilder");
            var bc_chan = new BroadcastChannel("to_molbuilder");
            bc_chan.postMessage({
                command : "set mol",
                data : mol
            });
            bc_chan.close();
        },
        commit_env() {
            console.log("commit env", this.env);
            utils.ajax('PUT', "/api/sandbox/environment", this.env).done(
                data => {}
            );
        },

        save_sandbox:  function() {
            
            utils.ajax('GET', "/api/sandbox"
            ).done(
                function(data) {
                    str_data = JSON.stringify(data.data);
                    blob_data = new Blob([str_data], {type: 'text/plain'});
                    saveAs(blob_data, "sandbox.json");
                }
            );   
        },

        load_sandbox_file: function(evt) {
	          var file = evt.target.files[0];
	          var reader = new FileReader();
	          
            reader.onload = function(e) {
	              utils.ajax("POST","/api/sandbox", reader.result
                          ).done();
            };
	          reader.readAsText(file);
        }
        
    },
    mounted: function() {
        this.update();
        this.$on("send_to_molbuilder", mol => this.send_to_molbuilder(mol));
        this.$on("update", _ => this.update());
    },
    created: function() {
        this.inert_mols_columns= inert_mols_columns;
        this.active_mols_columns= active_mols_columns;

        document.getElementById('sandbox_load').addEventListener('change', this.load_sandbox_file, false);

        this.bc_receive = new BroadcastChannel("to_sandbox");
        var self = this;
        this.bc_receive.onmessage = function(msg) {
            console.log("Received", msg);
            switch (msg.data.command) {
            case "update" :
                this.update();
                alert("update");
                break;
            case "add mol":
                utils.ajax('POST', `/api/sandbox/mol/${msg.data.data}`).done(
                    _ => {self.update();}
                );
            default : console.log("did not recognize command", msg.data.command);
            }
        };

    }
});
