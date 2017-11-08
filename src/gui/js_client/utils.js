var utils = {
    ajax : function(uri, method, data) {
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
}
