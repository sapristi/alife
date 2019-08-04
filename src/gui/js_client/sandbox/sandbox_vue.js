

Vue.component("environment", {
    props: ["env"],
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

Vue.component("mols-list", {
    props: ["mols", "columns", "mol_type"],
    data: function () {
        return {selected_mol_index: null}
    },
    template: `
        <table class="ui fixed selectable table">
			      <thead><tr>
				        <th v-for="col in columns" v-bind:class="col.css_class" >{{col.title}}</th>
			      </tr></thead>
			      <tbody>
				        <tr v-for="(mol,index) in mols" v-on:click="select(index)" v-bind:class="{ active: mol.selected }">
                    <td v-for="col in columns" v-bind:style="col.style">{{mol[col.property]}}</td>
				        </tr>
			      </tbody>
        </table>
    `,
    methods: {
        select: function(index){
            if (index === this.selected_mol_index) {
                this.mols[this.selected_mol_index].selected = false;
                this.selected_mol_index = null;
            } else {
                if (this.selected_mol_index !== null)
                    this.mols[this.selected_mol_index].selected = false;
                this.selected_mol_index = index;
                this.mols[this.selected_mol_index].selected = true;
            };
            this.$forceUpdate();
        }
    },
    watch: {
        selected_mol_index: function() {
            if (this.selected_mol_index !== null) {
                this.$root.$emit(
                    'selected_mol_' + this.mol_type,
                     this.mols[this.selected_mol_index])}
            else {this.$root.$emit('unselected_mol_'+ this.mol_type, null )}
        }
    }
});

Vue.component("inert-mols-controls",{
    props: [],
    data: function () {
        return {mol: null,
                qtt: null,
                disabled: true}
    },
    mounted: function(){
        this.$root.$on('selected_mol_inert', mol =>
            {this.mol = mol.mol; this.qtt = mol.qtt; this.disabled=false});
        this.$root.$on('unselected_mol_inert', mol_type =>
            {this.mol = null; this.qtt = null; this.disabled=true})
    }
});


Vue.component("active-mols-controls",{
    data: function () {
        return {
            mol: null,
            pnet_ids: [],
            disabled: true,
            selected_pnet: null
        }
    },
    methods: {
        init: function (mol) {
            this.mol= mol.mol;this.disabled=false;
            utils.ajax('GET', `/api/sandbox/mol/${this.mol}`
	          ).done(data => {
	              this.pnet_ids = data.data;
                this.selected_pnet = this.pnet_ids[0];
            console.log(this)});
        },
        clear: function () {
            this.mol = null; this.disabled=true; this.pnet_ids=[];
            this.selected_pnet = null;
        }
    },
    mounted: function() {
        this.$root.$on("selected_mol_active", mol => {this.init(mol);}),
        this.$root.$on("unselected_mol_active", _ => {this.clear();})
    },
    watch: {
        selected_pnet: function(val) {
            this.$root.$emit("selected_pnet", {mol: this.mol, pnet_id: this.selected_pnet});
        }
    }
});

Vue.component("petri-net", {
    data: function () {
        return {pnet: null}
    },
    methods: {
        init: function(mol, pnet_id) {
            utils.ajax('GET', `/api/sandbox/mol/${mol}/pnet/${pnet_id}`
            ).done(
                data => {console.log("pnet updated with ", data);
                         this.pnet = data.data.pnet})
        }
    },
    mounted: function() {
        this.$root.$on("selected_pnet", data => {
            if (data.pnet_id !== null) {
                this.init(data.mol, data.pnet_id);}
        else {this.pnet = null;} })
    }
});

Vue.component("petri-net-controls",{
    props: ["pnet"],
    data: function () {
        return {place: null, transition: null}
    },
    computed: {
        desc_texts: function (){
            if (this.pnet) {
                var launchables_nb = this.pnet.transitions.filter(
		                t => t.launchable).length;
                return ["Number of places :" + this.pnet.places.length,
                        "Number of transitions: "+ this.pnet.transitions.length,
                        "Number of launchable_transitions: " + launchables_nb];
            } else { return [];}
        }
    },
    mounted: function() {
        this.$root.$on("pnet_cy_node_selected", node_data => {
            if (node_data.type == "place") {
                this.place = this.pnet.places[node_data.index];
                this.transition = null;
                console.log("Sekected: ", this.place);
            } else if (node_data.type = "transition") {
                this.transition = node_data;
                this.place = null;
            }
        }),
        this.$root.$on("pnet_cy_node_unselected", _ => {
            this.place = null; this.transition = null;
        })

    }
});


Vue.component("place",{
    props: ["place"],
    data: function () {return {
        token_edit_checkbox: false,
        token_edit_state: null,
        token_edit_m1: null,
        token_edit_m2: null};},
    methods: {
        token_to_str: function(token) {
            if (token === null) return "No token."
            var mol = token[1];
	          var index = token[0];
	          if (mol != "") {
		            var mol1 = mol.substring(0, index);
		            var mol2 = mol.substring(index);
		            return mol1
		                + "<font style='color:red'>⮞</font>"
		                + mol2;
	          } else {return  "Token without molecule";}
        },
        extension_to_str: function(ext) {
            console.log("Ext to str: ", ext);
	          var ext_str = ext[0].replace(/_/g," ");
	          if (ext.length > 1)
	          {
	              if (ext_str == "Displace mol") {
		                if (ext[1][0])
		                {ext_str = ext_str + " forward";}
		                else {ext_str = ext_str + " backward";}
	              }
	              else if (ext_str == "Grab ext") {
		                var grab_patt = ext[1];
		                ext_str = ext_str + "; pattern :\n" + grab_patt;
	              }
	          }
	          return ext_str;
        },
    },
    computed: {
        token_str: function() { return this.token_to_str(this.place.token);},
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

sandbox_vue = new Vue({
    data: function (){
        return {
            env: null,
            inert_mols: [],
            active_mols: [],
            test_mols: []}
    },
    el: "#sandbox_vue",
    methods: {
        update: function () {
            utils.ajax('GET', "/api/sandbox"
            ).done(
                data =>  {
                    this.env = data.data.env;
                    this.inert_mols = data.data.bact.inert_mols;
                    this.active_mols = data.data.bact.active_mols;
                }
            );
        }
    },
    mounted: function() {
        this.update();
    },
    created: function() {
        this.inert_mols_columns= inert_mols_columns;
        this.active_mols_columns= active_mols_columns;
    }
})
