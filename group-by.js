var fs = require('fs');

var fileName = process.argv[2];
var setores ={};
var strAll = '';
fs.readFile(fileName, 'utf8', function (err,data) {
  if (err) {
    return console.log(err);
  }
  var lines = data.split('\n');
  lines.forEach(function(line){
  	if(line !== ''){

		
	  	
	  	var jsonline = JSON.parse(line);
	  	
	  	
	  	

	  	if(jsonline.properties.setor !== null){
	  		
		  	if(setores[jsonline.properties.setor]){
		  		if(jsonline.properties.population != null){
			  		setores[jsonline.properties.setor] += jsonline.properties.population;
			  	}else{
			  		setores[jsonline.properties.setor] += 1;
			  	}
		  	}else{
		  		if(jsonline.properties.population == null){
		  			setores[jsonline.properties.setor] = 1;
		  		}else{
		  			setores[jsonline.properties.setor] = jsonline.properties.population;
		  		}
		  	}
	  	}
  	}
  });

  for(var ix in setores){
  	var obj = {
  		setor:ix,
  		population:setores[ix]
  	}
  	var str = JSON.stringify(obj);
  	console.log(str);
  }

});