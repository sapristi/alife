const cytoscape = require('cytoscape');

const cola = require('cytoscape-cola');
cytoscape.use( cola )

let cxtmenu = require('cytoscape-cxtmenu');
cytoscape.use( cxtmenu );


// from http://www.mulinblog.com/a-color-palette-optimized-for-data-visualization/
const pnet_colors = {
    place : "#82bbe3",         // blue
    place_sel : "#2f8dd0",     // deep blue
    trans : "#c89dc8",         // deep purple
    trans_sel : "#a35ca3",     // purple
    trans_launch: "#f17cb0",      // pink
    trans_sel_launch : "#e71875", // deep pink
    token : "#b2912f",        // brown
    trans_type : "#faa43a",    // orange
    trans_type_sel : "#f15854", // red
    extension : "#60BD68"     // green
}


export const pnet_style= [
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
	          label : ele => ele._private.data.label
        }
    },
    {
        selector : '.arc.move',
        style: {
	          "mid-target-arrow-shape" : "circle",
	          label : ele => ele._private.data.label
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
	          label : ele => ele._private.data.label
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


export const cola_layout_conf = {
	  name:"cola",
	  padding:10,
	  avoidOverlap:false,
	  edgeLength : function(edge) {
        return (edge.hasClass("extension"))
            ? 35 : 70
	  },
	  infinite : true,
	  fit : false
};

window.cola_layout_conf = cola_layout_conf

export const coseblk_layout_conf = {
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

export const setup_pnet_cy = function(elements, eventHandler) {
    const cy = cytoscape(
	      {
	          style:pnet_style,
            elements,
	          userZoomingEnabled:true,
	          wheelSensitivity:0.2
	      });

    const select_edges = (node) => {
        node.incomers('edge')
	          .forEach(edge => edge.select())
	      node.outgoers('edge')
	          .forEach(edge => edge.select())
    }

    cy.on('select', '.place,.transition', function(evt){
    	  eventHandler(evt.target.data().node_type);
	      select_edges(evt.target)
    })

    cy.on('unselect', 'node', function(evt){
    	  eventHandler(["NoNode"]);
    })

    const layout = cy.layout(cola_layout_conf);

    // cy.contextMenus({
	  //     menuItems: [
	  //         {
		//             id:"start",
		//             content:"start",
    //             tooltipText: 'select all edges',
    //             coreAsWell: true,
		//             onClickFunction : function(event) {
		//                 layout.run();
		//             }
	  //         },
	  //         {
		//             id:"stop",
		//             content:"stop",
    //             tooltipText: 'select all edges',
    //             coreAsWell: true,
		//             onClickFunction : function(event) {
		//                 layout.stop();
		//             }
	  //         },
	  //     ]});

    const update_pnet = function(cy, pnet) {

	      for (var i = 0;i < pnet.places.length;i++){
		        if (pnet.places[i].token == null) {
		            cy.$("#p"+i).removeClass("withToken");
		        } else {
		            cy.$("#p"+i).addClass("withToken");
		        }
	      }

	      for (var i = 0; i < pnet.transitions.length;i++) {
		        if (pnet.transitions[i].launchable) {
		            cy.$("#t"+i).addClass("launchable");
		        }else {
		            cy.$("#t"+i).removeClass("launchable");
		        }
	      }
	  }

    const replace_elements = (cy, newElements) => {
        cy.elements().remove()
        cy.add(newElements)
        const layout = cy.layout(cola_layout_conf)
        return layout
    }

    const res = {
        cy: cy,
        layout: layout,
        update_pnet: update_pnet,
        replace_elements: replace_elements
    }
    window.cy_wrapper = res;
    return res
}
