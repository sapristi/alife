// * cytoscape functions

// ** proteine

// *** proteine style
var prot_style =
    [
	{
	    selector: ".Node",
	    style: {
	    }
	},
	{
	    selector: ".TransitionInput",
	    style: {
		'shape':'polygon',
		'shape-polygon-points':'-1 0.5 1 0 -1 -0.5'
	    }
	},
	{
	    selector: ".TransitionOutput",
	    style: {
		'shape':'polygon',
		'shape-polygon-points':'1 0.5 -1 0 1 -0.5'
	    }
	},
	{
	    selector: ".Extension",
	    style: {
		'shape':'diamond'
	    }
	}
    ];

// *** proteine graph
var make_prot_graph = function(prot_data, container) {
    var cy = cytoscape({container:container, style:prot_style});
    
    for (var i = 0;i < prot_data.length;i++){
	
	cy.add({
            group: "nodes",
            data: {id:"n"+i,
		   type : prot_data[i]["atype"],
		   option : prot_data[i]["options"],
		   raw_data: prot_data[i]},
            classes: prot_data[i]["atype"]
        });
        
        if (i>0) {
            cy.add({
                group:"edges",
                data: {source: "n"+(i-1), target:"n"+i}
            });
        }
    }

    cy.on('click', 'node', function(evt){
	console.log(evt.target.data());
    });
    
    return cy;
};


// ** pnet
// *** pnet short names

// from http://www.mulinblog.com/a-color-palette-optimized-for-data-visualization/
var pnet_colors = {
    "place" : "#82bbe3",         // blue
    "place_sel" : "#2f8dd0",     // deep blue
    "trans" : "#c89dc8",         // deep purple
    "trans_sel" : "#a35ca3",     // purple
    "trans_launch": "#f17cb0",      // pink
    "trans_sel_launch" : "#e71875", // deep pink
    "token" : "#b2912f",        // brown
    "trans_type" : "#faa43a",    // orange
    "trans_type_sel" : "#f15854", // red
    "extension" : "#60BD68"     // green
}
var arcs_short_names = {
    "Regular_iarc" : "reg",
    "Split_iarc"   : "split",
    "Filter_iarc"  : "filter",
    "Filter_empty_iarc" : "filter empty",
    "Regular_oarc" : "reg",
    "Merge_oarc"   : "merge",
    "Move_oarc"    : "move"
};
var make_arc_short_name = function(arc_type) {
    var short_name = arcs_short_names[arc_type[0]];
    var args = arc_type.slice(1).reduce(
	function(a,b) {  return a + " " + String(b);},
	"");
    return short_name + " " + args;
};
// *** pnet style
var pnet_style= [
    {
	selector: ".compound",
	style : {
	    "background-opacity" : 0,
	}
    },
    {
        selector: '.place',
        style: {
            'background-color' : pnet_colors.place,
            'border-color' : pnet_colors.place,
            'shape' : 'ellipse',
	    'width' : '30px',
	    'height' : '30px',
	    'border-width' : '10px',
        }
    },
    {
        selector: '.place.withToken',
        style: {
            'background-color' : pnet_colors.token,
            'border-color' : pnet_colors.place,
        }
    },
    {
        selector: '.place:selected',
        style: {
            'background-color' : pnet_colors.place_sel,
	    'border-color' : pnet_colors.place_sel
        }
    },
    {
        selector: '.place.withToken:selected',
        style: {
            'background-color' : pnet_colors.token,
	    'border-color' : pnet_colors.place_sel
        }
    },
    {
        selector: '.transition',
        style: {
            'shape' : 'rectangle',
            'height' : '20px',
	    'background-color' : pnet_colors.trans
        }
    },
    {
        selector: '.transition:selected',
        style: {
	    'label' : 'data(label)',
	    'background-color' : pnet_colors.trans_sel
        }
    },
    {
        selector: '.transition.launchable',
        style: {
	    'background-color':pnet_colors.trans_launch
        }
    },
    {
        selector: '.transition.launchable:selected',
        style: {
	    'background-color':pnet_colors.trans_sel_launch
        }
    },
    {
        selector : '.arc',
        style: {
            'curve-style' : 'bezier',
            'target-arrow-shape': 'triangle',
	    'line-color' : pnet_colors.trans,
	    'target-arrow-color' : pnet_colors.trans,
	    "opacity" : 1,
	    "mid-source-arrow-color" : pnet_colors.trans_type,
	    "mid-target-arrow-color" : pnet_colors.trans_type
        }
    },
    {
        selector : '.arc:selected',
        style: {
	    'line-color' : pnet_colors.trans_sel,
	    'source-arrow-color' : pnet_colors.trans_sel,
	    'target-arrow-color' : pnet_colors.trans_sel,
	    "mid-source-arrow-color" : pnet_colors.trans_type_sel,
	    "mid-target-arrow-color" : pnet_colors.trans_type_sel,
	    "opacity" : 1
        }
    },
    {
        selector : '.arc.split',
        style: {
	    "mid-source-arrow-shape" : "vee",
        }
    },
    {
        selector : '.arc.merge',
        style: {
	    "mid-target-arrow-shape" : "vee"
        }
    },
    {
        selector : '.arc.filter',
        style: {
	    "mid-target-arrow-shape" : "triangle-tee",
	    "label" : function(ele) {
		return ele._private.data.args[0];}
        }
    },
    {
        selector : '.arc.move',
        style: {
	    "mid-target-arrow-shape" : "circle",
	    "label" : function(ele) {
		if (ele._private.data.args[0]) {return "↷";}
		else {return "↶";}}
        }
    },
    {
        selector : 'node.extension',
        style: {
	    "width" : "10px",
	    "height" : "10px",
	    "background-opacity" : 0
        }
    },
    {
        selector : 'edge.extension',
        style: {
	    "width" : "3px",
            'curve-style' : 'bezier',
	    'line-color' : "white",
	    'target-arrow-color' : pnet_colors.extension,
	    'source-arrow-color' : pnet_colors.extension,
        }
    },
    {
        selector : 'edge.extension.Grab_ext',
        style: {
	    "source-arrow-shape" : "triangle-tee",
	    "source-endpoint" : "outside-to-node",
        }
    },
    {
        selector : 'node.extension.Grab_ext',
        style: {
	    "label" : function(node) {
		return node._private.data.args[0];},
        }
    },
    {
        selector : 'edge.extension.Release_ext',
        style: {
	    "target-arrow-shape" : "triangle-tee",
        }
    },
    {
        selector : 'edge.extension.Init_with_token_ext',
        style: {
	    "target-arrow-shape" : "circle",
        }
    },
];
// *** layout
// called when displaying the graph
var make_cola_layout = function(cy_graph) {
    return {
	name:"cola",
	padding:10,
	avoidOverlap:false,
	edgeLength : function(edge) {
	    var res = 0;
	    if (edge.hasClass("extension")) {res = 35;}
	    else {res = 70;}
	    return res;
	},
	infinite : true,
	fit : false
    };
};

var make_coseblk_layout = function(cy_graph) {
    return {
	name : "cose-bilkent",
	nestingFactor : 0.001,
	gravity : 0,
	nodeRepulsion : 500,
	edgeElasticity : 0.1,
	idealEdgeLength: 30,
	randomize: true,
	gravityCompound:50,
	gravityRangeCompound :50,
	animate : "during",
	numIter : 100
    };
}

// *** pnet graph
var make_pnet_graph = function(pnet_data, container, eventHandler) {
    var cy = new cytoscape(
	{container:container,
	 style:pnet_style,
	 userZoomingEnabled:true,
	 wheelSensitivity:0.2
	});
        
    var selected = 0;
    
// **** places

    for (var i = 0;i < pnet_data.places.length;i++){
	var node = pnet_data.places[i];
	var node_id = "p"+i;

	// place
        cy.add({
            group: "nodes",
            data: {id :node_id,
		   type : "place",
		   index : i,
		  },
            classes: "place"});
	// extensions
	for (var j=0; j< node.extensions.length; j++) {
	    
	    var ext = node.extensions[j];
	    console.log(ext);
	    var node_ext_id = node_id + "_" + ext[0];
	    cy.add({
		group:"nodes",
		data: {id: node_ext_id,
		       type : ext[0],
		       args : ext.slice(1)
		      },
		classes : "extension " + ext[0]
	    });
	    cy.add({
		group:"edges",
		data:{
		    source : node_id,
		    target : node_ext_id,
		    type : ext[0],
		    args : ext.slice(1),
		    directed : true
		},
		classes : "extension " + ext[0] 
	    });
	}
    }

// **** transitions
    for (var i = 0; i < pnet_data.transitions.length;i++) {
        var t = pnet_data.transitions[i];
        var tname = "t" + i;

// ***** transition nodes
	
	var classes  = "transition";

	cy.add({
            group: "nodes",
            data: { id:tname,
		    label:t.id,
		    type : "transition",
		    index : i
		  },
            classes : classes});
        
// ***** transition input_arcs
        t.input_arcs.forEach(function(dp) {
	    var label = make_arc_short_name(dp.iatype);
	    var classes = "arc " + label;
            cy.add({
                group: "edges",
                data: {
                    source : "p"+ dp.source_place,
                    target : tname,
                    directed : true,
		    label: label,
		    type : dp.iatype[0],
		    args : dp.iatype.slice(1)
		},
		classes : classes
            });
        });
	
// ***** transition output_arcs
        t.output_arcs.forEach(function(dp) {
	    var label = make_arc_short_name(dp.oatype);
	    var classes = "arc " + label;
            cy.add({
                group: "edges",
                data: {
                    source : tname,
                    target : "p"+ dp.dest_place,
                    directed : true,
		    label: label,
		    type : dp.oatype[0],
		    args : dp.oatype.slice(1)
		},
		classes : classes
            });
        });

	
    }

// *** interactions
    cy.on('select', '.place, .transition', function(evt){
    	eventHandler.set_node_selected(evt.target.data());
	evt.target.incomers('edge')
	    .forEach(function(edge){edge.select();});
	evt.target.outgoers('edge')
	    .forEach(function(edge){edge.select();});
    });
    
    
    cy.on('unselect', 'node', function(evt){
    	eventHandler.set_node_unselected();
    });

    var layout = cy.layout(make_cola_layout(cy));
    cy.contextMenus({
	menuItems: [
	    {
		id:"start",
		content:"start",
                tooltipText: 'select all edges',
                coreAsWell: true,
		onClickFunction : function(event) {
		    layout.run();
		}
	    },
	    {
		id:"stop",
		content:"stop",
                tooltipText: 'select all edges',
                coreAsWell: true,
		onClickFunction : function(event) {
		    layout.stop();
		}
	    },
	]});


    var pnet_cy = {
	cy : cy,
	layout : layout,
	update : function( pnet) {
	    
	    for (var i = 0;i < pnet.places.length;i++){
		
		if (pnet.places[i].token == null) {
		    this.cy.$("#p"+i).removeClass("withToken");
		} else {
		    this.cy.$("#p"+i).addClass("withToken");
		}
	    }
	    
	    for (var i = 0; i < pnet.transitions.length;i++) {
		
		if (pnet.transitions[i].launchable) {
		    this.cy.$("#t"+i).addClass("launchable");
		}else {
		    this.cy.$("#t"+i).removeClass("launchable");
		}
	    }
	    
	},
	run : function() {
	    // this.cy.layout(make_cola_layout(this.cy)).run()
	    this.layout.run();
	}
    };
    return pnet_cy;
}

