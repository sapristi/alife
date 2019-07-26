

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

Vue.component("mol-list", {
    props: ["mols", "id", "columns"],
    data: function () {
        return {selected_mol_index: null}
    }

})

Vue.component("inert-mols-list",{
    props: ["inert_mols"],
    data: function () {
        return {selected_mol_index: null}
    },
    methods: {
        select: function(index){
            if (index === this.selected_mol_index) {
                this.inert_mols[this.selected_mol_index].selected = false;
                this.selected_mol_index = null;
            } else {
                if (this.selected_mol_index !== null)
                    this.inert_mols[this.selected_mol_index].selected = false;
                this.selected_mol_index = index;
                this.inert_mols[this.selected_mol_index].selected = true;
            };
            this.$forceUpdate();
        }
    },
    watch: {
        selected_mol_index: function() {
            if (this.selected_mol_index !== null) {
                this.$root.$emit(
                    'selected_mol',this.inert_mols[this.selected_mol_index])}
            else {this.$root.$emit('unselected_mol', null)}
        }
    }
});

Vue.component("inert-mols-controls",{
    props: [],
    data: function () {
        return {qtt: null,
                disabled: true}
    },
    mounted: function(){
        this.$root.$on('selected_mol', mol => {this.qtt = mol.qtt; this.disabled=false});
        this.$root.$on('unselected_mol', _ => {this.qtt = null; this.disabled=true})
    }
});


sandbox_vue = new Vue({
    data: function (){
        return {
            env: null,
            inert_mols: [],
            active_mols: []}
    },
    el: "#sandbox_vue",
    methods: {
        update: function () {
            utils.ajax_get(
                {command:"get_sandbox_data",
	               target:"sandbox"}
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
    }
})
