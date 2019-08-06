

var utils = {

    ajax : function(method, path, payload) {
	      console.log(`${method} : ${path} with payload: `);
	      console.log(payload);
        
        var connect_uri = window.location.origin +  path;
        
        var request = {
            url: connect_uri,
            datatype: 'json',
            data: JSON.stringify(payload),
            method: method,
            success: function(json) {
                console.log("received ;");
                console.log(json)
            },
            error: function(jqXHR) {
                console.log("ajax error " + jqXHR.status + " from sending :");
		            console.log(payload, "to", connect_uri);
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
