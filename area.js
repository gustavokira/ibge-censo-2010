var fs = require('fs');
var geojsonArea = require('@mapbox/geojson-area');

var partida = process.argv[2];
var destino = process.argv[3];
var fileName = process.argv[4];
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
	  	console.log(line);
	  	if(jsonline.properties[partida] !== null && jsonline.geometry != null){

	  		var area = geojsonArea.geometry(jsonline.geometry);
		  	areas[jsonline.properties[partida]] = area;
		  	}
	  	}
  });

  for(var ix in areas){
  	var obj = {
  		area:areas[ix]
  	}
    obj[destino] = ix;
  	var str = JSON.stringify(obj);
  	console.log(str);
  }

});