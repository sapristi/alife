Vue.component("transition",{
    computed: {
        transition() {
            return this.$store.getters["pnet/transition"];
        }
    },
    methods: {
        launch() {
            var mol = this.$store.state.pnet.mol;
            var pnet_id = this.$store.state.pnet.pnet_id;
            var transition_index = this.$store.state.pnet.selected_transition_index;

            utils.ajax('PUT', `/api/sandbox/amol/${mol}/pnet/${pnet_id}`,
                       ["Launch_transition", transition_index]).done(
                           data => {this.$store.commit("pnet/set_pnet", data.data.pnet)}
                       )
        }
    },
    template: `
        <div v-if="transition">
				    <h4 class="ui horizontal divider header">
				        Transition description
				    </h4>
				    <button
				           class="ui button tooltip"
v-on:click="launch"
                v-bind:class="{primary: transition.launchable}">
				        Launch transition
				        <span class="big tooltiptext">
					          Launches the selected transition.<br>
					          <span class="special-text">Be carefull :</span><br>
					          Only  yellow (or red if selected) transitions should be launched.
				        </span>
				    </button>
			  </div>
`
})
