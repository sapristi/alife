const pnet_store = {
    namespaced: true,
    state: {
        pnet_id: null,
        pnet: null,
        mol: null,
        selected_place_index: null,
        selected_transition_index: null
    },
    mutations: {
        set(state, data) {
            state.pnet_id = data.pnet_id;
            state.pnet = data.pnet;
            state.mol = data.mol;
        },
        set_pnet(state, data) {
            state.pnet = data;
        },
        select_place(state, place_id) {
            console.log("Store placeid: ", place_id);
            state.selected_place_index = place_id;
            state.selected_transition_index = null;
        },
        select_transition(state, transition_id) {
            state.selected_transition_index = transition_id;
            state.selected_place_index = null;
        },
        unselect(state) {
            state.selected_transition_index = null;
            state.selected_place_index = null;
        },
        clear(state) {
            state.pnet_id = null;
            state.pnet = null;
            state.mol = null;
            state.selected_place_index = null;
            state.selected_transition_index = null;
        }
    },
    getters: {
        place: state => {
            if (state.pnet === null) {return null;};
            if (state.selected_place_index === null) {return null;};
            return state.pnet.places[state.selected_place_index];
        },
        transition: state => {
            if (state.pnet === null) {return null;};
            if (state.selected_transition_index === null) {return null;};
            return state.pnet.transitions[state.selected_transition_index];
        }
    }
};


Vue.component("petri-net-controls",{
    data: function () {
        return {place: null, transition: null, selected_index:null};
    },
    computed: {
        pnet: function() {return this.$store.state.pnet.pnet;},
        desc_texts: function (){
            if (this.pnet) {
                var launchables_nb = this.pnet.transitions.filter(
		                t => t.launchable).length;
                return ["Number of places :" + this.pnet.places.length,
                        "Number of transitions: "+ this.pnet.transitions.length,
                        "Number of launchable_transitions: " + launchables_nb];
            } else { return [];}
        }
    }});


Vue.component("pnet-cy", {
    computed: {
        pnet() {return this.$store.state.pnet.pnet;}
    },
    methods: {
        set_node_selected: function(node_data ){
            console.log("Selected ", node_data);
            if (node_data.type == "place") {
                this.$store.commit("pnet/select_place", node_data.index);
            } else if (node_data.type == "transition") {
                this.$store.commit("pnet/select_transition", node_data.index);
            }
        },
        set_node_unselected: function() {
            this.$store.commit("pnet/unselect");
        },
        create() {
            console.log("Creating pnet with", this.pnet);
            this.pnet_cy = new make_pnet_graph(
		            this.pnet,
		            document.getElementById('pnet_cy'),
		            this);
            this.pnet_cy.update(this.pnet);
            this.pnet_cy.run();
        },
        update() {
            console.log("Updating pnet with", this.pnet);
            this.pnet_cy.update(this.pnet);
        }
    },
    watch: {
        pnet: {immediate: true,
               handler: function(data, old_data) {
                   console.log("Pnet Cy updated with ", data);
                   if (data === null) {if (this.pnet_cy) this.pnet_cy.destroy();} 
                   else if (old_data === undefined || old_data === null) {this.create()}
                   else if (old_data.id === data.id) {this.update();}
                   else if (data != null && data != undefined) {this.create()};
               }
              }
    }
});


