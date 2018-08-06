

var utils = {
    
    ajax_get : function(req_data) {
	console.log("sending:");
	console.log(req_data);
        
        
	var connect_uri =
            window.location.origin +
            "/sim_commands/" +
            req_data.target + "/" +
            req_data.command;
        
	var request = {
            url: connect_uri,
            dataType: 'json',
            data: req_data,
	    method:'GET',
            success : function(json) {
		console.log("received :"); 
                console.log(json);
            },
            error: function(jqXHR) {
                console.log("ajax error " + jqXHR.status + " from sending :");
		console.log(req_data);
            }
        };
        return $.ajax(request);
    },

    ajax_post : function(req_data) {
	var connect_uri = window.location.href + "sim_commands/";
	var request = {
            url: connect_uri,
            dataType: 'json',
            data: JSON.stringify(req_data),
            contentType: "application/json; charset=utf-8",
	    method:'post',
            success : function(json) {
		console.log("received :"); 
                console.log(json);
            },
            error: function(jqXHR) {
                console.log("ajax error " + jqXHR.status);
            }
        };
        return $.ajax(request);
    },
    
    string_rev : function(s) {
	if (typeof s == "undefined") {
	    return "";
	} else {
	    var splitString = s.split("");
	    var reverseArray = splitString.reverse(); 
	    var joinArray = reverseArray.join("");
	    return joinArray;
	}
    },

    

    insertAtCursor : function (field, mystring) {
	var cursorPosStart = field.prop('selectionStart');
        var cursorPosEnd = field.prop('selectionEnd');
        var v = field.val();
        var textBefore = v.substring(0,  cursorPosStart );
        var textAfter  = v.substring( cursorPosEnd, v.length );
	field.val( textBefore + mystring +textAfter );
    },
    range : function(bound) {
	return Array.apply(null, Array(bound)).map(function (_, i) {return i;});
    }
}
