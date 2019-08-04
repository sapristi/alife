Vue.component("token-edit", {
    props: ["token"],
    data: function () {return {
        token_edit_state: null,
        token_edit_m1: null,
        token_edit_m2: null};},
    watch: {
        token: {immediate: true,
                handler: function(token) {
                    console.log("Token updated with", token);
                    if (token === null) {
                        this.token_edit_state = false;
                        this.token_edit_m1 = "";
                        this.token_edit_m2 = "";
                    } else {
                        var token_str = token[1];
                        var sep = token[0];
                        this.token_edit_state = true;
                        this.token_edit_m1 = token_str.substring(0, sep);
                        this.token_edit_m2 = token_str.substring(sep, token_str.length);
                    }
                }
        }
    },
    methods: {
        commit_token: function() {
            console.log("Commit token: ", this.token_edit_state, this.token_edit_m1, this.token_edit_m2);
            var mol = this.$store.state.pnet.mol;
            var pnet_id = this.$store.state.pnet.pnet_id;
            var place_index = this.$store.state.pnet.selected_place_index;
            var token_update;
            if (this.token_edit_state === false) {token = null;}
            else {token = [this.token_edit_m1.length, this.token_edit_m1 + this.token_edit_m2];}

            utils.ajax('PUT', `/api/sandbox/mol/${mol}/pnet/${pnet_id}`,
                       ["Update_token",token,place_index]).done(
                           data => {console.log(data);}
                       );
        },
        cancel_edit: function() {
            console.log("Cancel token edit");
        }
    },
    template:`
        <div>
            <span class="big tooltiptext">
					      Use this to set a new token in the selected place.<br>
					      <span class="special-text">«No token»</span> will remove any token.<br>
					      <span class="special-text">«Token»</span> will add a token<br>
					      Text inputs are used to set the molecule present in the token.
				    </span>

            <h4 class="ui horizontal divider header">
		            Token edition
            </h4>
            <div class="ui form">
		            <div class="inline fields">
				            <div class="field">
						            <div class="ui radio checkbox">
						                <input v-bind:value="false"
							                     type="radio"
							                     name="token_edit_state_r"
                                   v-model="token_edit_state">
						                <label>No token</label>
						            </div>
				            </div>
				            <div class="field">
						            <div class="ui radio checkbox">
						                <input
							              v-bind:value="true"
							                    type="radio"
							                    name="token_edit_state_r"
                                  v-model="token_edit_state">
						                <label>Token</label>
						            </div>
				            </div>
		            </div>
		            <div v-if="token_edit_state">
				            <div class="field">
						            <textarea rows=2
                                  v-model="token_edit_m1"
							                    class="tooltip">
						                <span class="tooltiptext">test</span>
						            </textarea>
				            </div>
				            <div class="field">
						            <textarea rows=2
                                  v-model="token_edit_m2"></textarea>
				            </div>
		            </div>
		            <button class="ui primary button" v-on:click="commit_token">
				            Commit
		            </button>
		            <button class="ui button">
				            Discard
		            </button>
            </div>
        </div>`
})


Vue.component("place",{
    data: function () {return {
        token_edit_checkbox: false,
    };},
    methods: {
        token_to_str: function(token) {
            if (token === null) return "No token.";
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
        place: function () {
            return this.$store.getters["pnet/place"];
        },
        token: function() {return this.place.token;}

    },
    template: `
        <div v-if="place">
				    <!-- ****** place description-->
				    <h4 class="ui horizontal divider header">
				        Place description
				    </h4>
            
				    <!-- ******* place extensions display -->
				    <h5 class="ui header">Place extensions</h5>
				    <div class="ui bulleted list" v-if="place.extensions">
				        <div v-for="ext in place.extensions" class="item">{{extension_to_str(ext)}}</div>
				    </div>
				    <div v-else="place.extensions">No extensions</div>
            
				    <!-- ******* token display -->
				    <h5 class="ui header">Token</h5>
				    <div class="ui segment"
				         style="word-wrap:break-word">{{token_str}}
				    </div>
            
				    <!-- ******* token edit button -->
				    <div class="ui divider"></div>
				    <div class="ui toggle checkbox">
				        <input v-model="token_edit_checkbox" type="checkbox">
				        <label>Token edition</label>
				    </div>
            
				    <token-edit v-if="token_edit_checkbox" class="tooltip" v-bind:token="place.token"/>
			  </div>
`
});


