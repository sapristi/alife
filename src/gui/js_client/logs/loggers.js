
Vue.prototype.static = {
    log_levels: ["NoLevel", "Debug", "Trace", "Info", "Warning", "Error"],
    log_colors: {
        NoLevel: "",
        Debug: "LightGreen",
        Trace: "LightSeaGreen",
        Info: "Blue",
        Warning: "DarkOrange",
        Error: "Red"
    }
};

Vue.component('log-level-selection', {
    template: `
   <span class="display:inline">
     <select class="ui compact dropdown"
             v-model="selected_level">
       <option v-for="log_level in static.log_levels"
         :value="log_level" :key="log_level">{{log_level}}</option>
     </select>
     <button v-if="changed" class="mini ui button"
       v-on:click="sync">Sync</button>
   </span>
    `,
    props: {level: String, name: String},
    data: function() {return {
        selected_level: this.level,
        synced: true,
        log_levels: ["NoLevel", "Debug", "Trace", "Info", "Warning", "Error"]
    };},
    computed: {
        changed: function() {return this.level != this.selected_level;}
    },
    methods: {
        sync: function() {
            console.log("set:", this.name, ":", this.selected_level, " →  ", this.level);
            this.$root.$emit("set_level", {level: this.selected_level, logger: this.name});
        }
    },
    mounted: function() {$('.ui.dropdown').dropdown();}
});

Vue.component('tree-item', {
  template: `
  <div class="item" style="margin-left: 7px; border-left: 1px solid">
    <div>
      <span
        :class="{bold: isFolder}"
        @click="toggle">
        <i v-bind:class="icon.icon" v-bind:style="icon.style"></i>
        {{ item.name }}</span> - <log-level-selection :level="item.level" :name="item.name"></log-level-selection>
    </div>
    <div class="ui list" v-show="isOpen" v-if="isFolder">
      <tree-item
           class="item"
           v-for="(child, index) in item.children"
        :key="index"
        :item="child"
        @add-item="$emit('add-item', $event)"
        ></tree-item>
    </div>
  </div>

`,
  props: {
    item: Object
  },
  data: function () {
    return {
        isOpen: false
    };
  },
  computed: {
      isFolder: function () {
        return this.item.children &&
            this.item.children.length;
      },
      icon: function() {
          if (this.isFolder) {
              if (this.isOpen) {
                  return {icon: "angle down icon", style: ""};
              } else {return {icon: "angle right icon", style: ""};}
          } else {return {icon: 'circle outline icon', style: "font-size: 0.5em"};}
      }
  },
  methods: {
    toggle: function () {
      if (this.isFolder) {
          this.isOpen = !this.isOpen;
      }
    }
  }
});

Vue.component("buttons", {
    template: `
<div>
<h5 class="ui top attached header">Log reception</h5>
<div class="ui attached segment">
<table><tr><th style="margin-right:3px">OFF &nbsp; &nbsp;</th>
<th><div class="ui toggle checkbox" id="ws-checkbox"><input type="checkbox"><label></label>
</div></th>
<th>ON</th></tr>
</table>
</div>
<div class="ui attached segment">
<button class="ui button" v-on:click="clear_logs">Clear logs</button>
</div>
</div>`,
    data: function() {
        return {ws: null,
                connected: false};
    },
    methods: {
        connect() {
            this.ws = new WebSocket("ws://localhost:5000");
            this.ws.onmessage = event => {
                // console.log("Received", event.data);
                this.$root.$emit("log", event.data);
            };
            this.ws.onclose = _ => {this.connected = false;
                                    $("#ws-checkbox").checkbox("uncheck");
                                   };
            this.connected = true;
        },
        disconnect() {this.ws.close();
                      this.connected = false;},
        toggle() {if (this.connected) {this.disconnect();}
                  else {this.connect();}},
        clear_logs(){ this.$root.$emit('clear_logs'); }
     },
    computed: {
        button_message() {return (this.connected) ? "Disconnect" : "Connect";},
        button_class() {return (this.connected) ? "green ui button" : "red ui button";}
    },
    mounted() {
        $("#ws-checkbox").checkbox({
            onChecked: _ => this.connect(),
            onUnchecked: _ => this.disconnect()
        });
    }
});

Vue.component("logs-list", {
    template: `
  <table id="logs-table" style="width: 100%" class="compact">
    <thead><tr role="row">
      <th>TS</th>
      <th>Logger</th>
      <th>Level</th>
      <th>Message</th>
    </tr></thead>
  </table>
`,
    data: function() {
        return {
            table: null,
            logs_nb: 0,
            max_logs_nb: 1000
        };
    },
    methods: {
        treat_row: function(row) {
            row.level = `<span style="color:${this.static.log_colors[row.level]}">${row.level}</span>`;
            var date = moment(row.timestamp * 1000);
            row.time = date.format('HH:mm:ss.SSS');
        }
    },
    mounted: function() {
        this.$root.$on("log", log_str =>
                       {
                           if (this.logs_nb == this.max_logs_nb) {
                               var half_length = Math.floor(this.logs_nb/2);
                               slice = Array.from(new Array(half_length),
                                                  (x,i) => i+half_length);
                               this.table.rows(slice).remove().draw();
                               this.logs_nb = half_length;
                           }
                           var log = JSON.parse(log_str);
                           this.treat_row(log);
                           this.table.row.add(log).draw();
                           this.logs_nb += 1;
                       });
        this.$root.$on("clear_logs", _ =>
                       {
                           this.table.rows().remove().draw();
                       });

        this.table = $('#logs-table').DataTable({
            data: [],
            columns: [
                {data: "time", width: "10%", className: "dt-center"},
                {data: "logger_name", width: "10%", className: "dt-center"},
                {data: "level", width: "10%", className: "dt-center"},
                {data: "message"}
            ]
        });
    }
});


logs_vue = new Vue({
    el: "#logs_container",
    data: function() {
        return {
            loggers: {name: "root"},
            logs: [],
        };
    },
    methods: {
        update() {
            utils.ajax('GET', '/api/logs/tree').done(
                data => {this.loggers = data;}
            );
        }
    },
    mounted: function() {
        this.update();
        this.$on("set_level", params => utils.ajax('POST', '/api/logs/logger', params).done(
            _ => this.update()));
    }
});
