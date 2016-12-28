var fs = require('fs');
var geojsonArea = require('@mapbox/geojson-area');

var fileName = process.argv[2];
var areas = {};
var strAll = '';
fs.readFile(fileName, 'utf8', function (err,data) {
  if (err) {
    return console.log(err);
  }
  var lines = data.split('\n');
  lines.forEach(function(line){
  	if(line !== ''){

		
	  	
	  	var jsonline = JSON.parse(line);
	  	
	  	
	  	

	  	if(jsonline.properties.CD_GEOCODI !== null){
	  		var area = geojsonArea.geometry(jsonline.geometry);
		  	areas[jsonline.properties.CD_GEOCODI] = area;
		  	}
	  	}
  });

  for(var ix in areas){
  	var obj = {
  		setor:ix,
  		area:areas[ix]
  	}
  	var str = JSON.stringify(obj);
  	console.log(str);
  }

});