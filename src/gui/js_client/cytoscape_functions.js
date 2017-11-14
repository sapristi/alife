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
    ]

// *** proteine graph
make_prot_graph = function(prot_data, container) {
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
	console.log(evt.target.data())
    });
    
    return cy
}


// ** pnet

// *** pnet style
var pnet_style= [
    {
        selector: '.place',
        style: {
            'background-color' : 'blue',
            'shape' : 'ellipse',
	    'width' : '30px',
	    'height' : '30px',
	    'border-width' : '10px',
	    'border-color' : 'blue'
        }
    },
    {
        selector: '.place.withToken',
        style: {
            'background-color' : 'black'
        }
    },
    {
        selector: '.place:selected',
        style: {
            'background-color' : 'cyan',
	    'border-color' : 'cyan'
        }
    },
    {
        selector: '.place.withToken:selected',
        style: {
            'background-color' : 'black',
	    'border-color' : 'cyan'
        }
    },
    {
        selector: '.transition',
        style: {
            'shape' : 'rectangle',
            'height' : '20px',
	    'label' : 'data(label)'
        }
    },
    {
        selector: '.transition.launchable',
        style: {
	    'background-color':'orange'
        }
    },
    {
        selector: '.transition.launchable:selected',
        style: {
	    'background-color':'red'
        }
    },
    {
        selector : 'edge',
        style: {
            'curve-style' : 'bezier',
            'target-arrow-shape': 'triangle'
        }
    },
    {
        selector : 'edge:selected',
        style: {
	    'label': 'data(label)'
        }
    }
];

// *** pnet graph
make_pnet_graph = function(pnet_data, container, eventHandler) {
    var cy = new cytoscape({container:container, style:pnet_style});
        
    var selected = 0;
    
// **** places
    for (var i = 0;i < pnet_data.places.length;i++){
        cy.add({
            group: "nodes",
            data: {id :"p"+i,
		   type : "place",
		   index : i
		  },
            classes: "place"});
    }

// **** transitions
    for (var i = 0; i < pnet_data.transitions.length;i++) {
        var t = pnet_data.transitions[i];
        var tname = "t" + i;

// ***** transition nodes
	
	var classes  = "transition";
	// if (pnet_data.launchables.includes(i))
	// { classes = "transition launchable";}
	// else {classes = "transition"}

	cy.add({
            group: "nodes",
            data: { id:tname,
		    label:t.id,
		    type : "transition"
		  },
            classes : classes});
        
// ***** transition input_arcs
        t.input_arcs.forEach(function(dp) {
            cy.add({
                group: "edges",
                data: {
                    source : "p"+ dp.source_place,
                    target : tname,
                    directed : true,
		    label: dp.iatype[0]}
            });
        });
	
// ***** transition output_arcs
        t.output_arcs.forEach(function(dp) {
            cy.add({
                group: "edges",
                data: {
                    source : tname,
                    target : "p"+ dp.dest_place,
                    directed : true,
		    label: dp.oatype[0]}
            });
        });

	
    }

// *** interactions
    cy.on('select', 'node', function(evt){
    	eventHandler.set_node_selected(evt.target.data());
	evt.target.incomers('edge')
	    .forEach(function(edge){edge.select();});
	evt.target.outgoers('edge')
	    .forEach(function(edge){edge.select();});
    });
    
    
    cy.on('unselect', 'node', function(evt){
    	eventHandler.set_node_unselected();
    });
    
    return cy;
}

update_pnet_graph  = function(cy, pnet) {
    
    // **** places
    
    for (var i = 0;i < pnet.places.length;i++){
	
	if (pnet.places[i].token[0] == "No_token") {
	    cy.$("#p"+i).removeClass("withToken");
	} else {
	    cy.$("#p"+i).addClass("withToken");
	}
    }

    for (var i = 0; i < pnet.transitions.length;i++) {
	
	if (pnet.launchables.includes(i)) {
	    cy.$("#t"+i).addClass("launchable");
	}else {
	    cy.$("#t"+i).removeClass("launchable");
	}
    }

}
