
function TasksViewModel() {
    var self = this;
    
    self.connect_uri = 'http://localhost:1512';
    self.bact_mols = ko.observableArray();
    self.sandbox_mols = ko.observableArray();
    
    self.ajax = function(uri, method, data) {
	var request = {
	    url: uri,
	    dataType: 'json',
	    data: data,
	    crossDomain: true,
	    success : function(json) {
		console.log(json);
	    },
	    error: function(jqXHR) {
		console.log("ajax error " + jqXHR.status);
	    }
	};
	return $.ajax(request);
    }
    
    
    self.examine = function(){

	exam_mol = function(data) {
	    
	    var prot_cy = make_prot_graph(
		data["data"]["prot"],
		document.getElementById('prot_cy'));
	    prot_cy.layout({name:"circle"}).run()
	    
	    var pnet_cy = make_pnet_graph(
		data["data"]["pnet"],
		document.getElementById('pnet_cy'));
	    pnet_cy.layout({name:"breadthfirst"}).run()
		
	}
	
	self.ajax(
	    self.connect_uri,
	    'GET',
	    {command:"give data for mol exam",
	     mol_desc:this.mol_name}
	).done(exam_mol);
    }
    
    
    self.update_bact = function() {
	
	bact_data = function(data) {
	    mols_data = data.data["molecules list"];
	    for (var i = 0; i < mols_data.length; i++) {
		self.bact_mols.push({
		    mol_name : mols_data[i]["mol"],
		    mol_number : mols_data[i]["nb"],
		    class_select_status : "item"
		});
	    }
	}
	
	self.ajax(
	    self.connect_uri,
	    'GET',
	    {command:"get_bact_elements"}
	).done(bact_data);
    }

    
    self.update_sandbox = function() {
	
	sandbox_data = function(data) {
	    mols_data = data.data["molecules list"];
	    for (var i = 0; i < mols_data.length; i++) {
		self.bact_mols.push({
		    mol_name : mols_data[i]["mol"],
		    mol_number : mols_data[i]["nb"],
		    class_select_status : "item"
		});
	    }
	}
	
	self.ajax(
	    self.connect_uri,
	    'GET',
	    {command:"get_sandbox_elements"}
	).done(sandbox_data);
    }
    
    self.init_data = function() {
	self.update_bact();
	self.update_sandbox();
    }
    
}

ko.applyBindings(new TasksViewModel());


make_prot_graph = function(prot_data, container) {
    var cy = cytoscape({container:container});
    
    for (var i = 0;i < prot_data.length;i++){
	cy.add({
	    group: "nodes",
	    data: {id:"n"+i},
	    classes: prot_data[i][0]
	});
	
	if (i>0) {
	    cy.add({
		group:"edges",
		data: {source: "n"+(i-1), target:"n"+i}
	    });
	}
//	console.log(prot_data[i]);
    }
    return cy
}


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


$('.menu .item')
  .tab()
;
