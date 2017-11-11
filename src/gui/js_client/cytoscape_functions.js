// * cytoscape functions
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

make_pnet_graph = function(pnet_data, container, eventHandler) {
    var cy = new cytoscape({container:container, style:pnet_style});
        
    var selected = 0;
    
    for (var i = 0;i < pnet_data.places.length;i++){
	var token = pnet_data.places[i].token;
	if (token[0] == "No_token")
	{ var myclasses = "place";}
	else {var myclasses = "place withToken";}
	  
        cy.add({
            group: "nodes",
            data: {id :"p"+i,
		   token : token,
		   type : "place",
		   extensions : pnet_data.places[i].extensions,
		  },
            classes: myclasses});
    }

    for (var i = 0; i < pnet_data.transitions.length;i++) {
        var t = pnet_data.transitions[i];
        var tname = "t" + i;

        cy.add({
            group: "nodes",
            data: { id:tname,
		    type : "transition"
		  },
            classes : "transition"});
        
        var input_arcs = t.input_arcs;
        var output_arcs = t.output_arcs;
        
        input_arcs.forEach(function(dp) {
            cy.add({
                group: "edges",
                data: {
                    source : "p"+ dp.place,
                    target : tname,
                    directed : true,
		    label: dp.type[0]}
            });
        });
        
        output_arcs.forEach(function(dp) {
            cy.add({
                group: "edges",
                data: {
                    source : tname,
                    target : "p"+ dp.place,
                    directed : true,
		    label: dp.type[0]}
            });
        });
    }
    
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

