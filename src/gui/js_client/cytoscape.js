
var pnet_style= [
    {
        selector: '.place',
        style: {
            'background-color' : 'green',
            'shape' : 'ellipse'
        }
    },
    {
        selector: '.transition',
        style: {
            'shape' : 'rectangle',
            'height' : '20px'
        }
    },
    {
        selector : 'edge',
        style: {
            'curve-style' : 'bezier',
            'target-arrow-shape': 'triangle'
        }
    }
];

make_pnet_graph = function(pnet_data, container) {
    var cy = cytoscape({container:container, style:pnet_style});
    console.log(pnet_data)

    for (var i = 0;i < pnet_data["places"].length;i++){
        cy.add({
            group: "nodes",
            data: {id :"p"+i},
            classes: "place"});
    }

    for (var i = 0; i < pnet_data["transitions"].length;i++){
        var t = pnet_data["transitions"][i];
        var tname = "t" + i;

        cy.add({
            group: "nodes",
            data: { id:tname},
            classes : "transition"});
        
        var dep_places = t["dep_places"];
        var arr_places = t["arr_places"];
        
        dep_places.forEach(function(dp) {
            cy.add({
                group: "edges",
                data: {
                    source : "p"+ dp["place"],
                    target : tname,
                    directed : true}
            });
        });
        
        arr_places.forEach(function(dp) {
            cy.add({
                group: "edges",
                data: {
                    source : tname,
                    target : "p"+ dp["place"],
                    directed : true}
            });
        });
    }
    return cy;
}

