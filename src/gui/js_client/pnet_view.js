



function PNetViewModel() {
    var self = this;
    var pnet_data;
    
    var current_node = ko.observable()
    
    self.update_data = function(data)
    {self.pnet_data = data;
     console.log(data);}

}


function NodeViewModel() {
    var self=this;
    var data;
    
    self.update_data = function(data)
    {self.pnet_data = data;
     console.log(data);}
}
