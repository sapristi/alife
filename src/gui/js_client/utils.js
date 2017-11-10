//var connect_uri = 'http://localhost:1512/sim_commands/';

var utils = {
    
    ajax : function(req_data) {
	var connect_uri = window.location.href + "sim_commands/";
	var request = {
            url: connect_uri,
            dataType: 'json',
            data: req_data,
	    method:'GET',
            success : function(json) {
                console.log(json);
            },
            error: function(jqXHR) {
                console.log("ajax error " + jqXHR.status);
            }
        };
        return $.ajax(request);
    },

    string_rev : function(s) {
	var splitString = s.split("");
	var reverseArray = splitString.reverse(); 
	var joinArray = reverseArray.join("");
	return joinArray; 
    }
}
