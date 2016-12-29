var fileName = process.argv[2];

var fs = require('fs');
var readline = require('readline');
var stream = require('stream');
var readableStream = fs.createReadStream(fileName);
var outstream = new stream;
outstream.readable = true;
outstream.writable = true;

var setor = {};
var cl = 0;

var rl = readline.createInterface({
    input: readableStream,
    output: outstream,
    terminal: false
});

rl.on('line', function(line) {
	if(cl > 4 && line !== ']' && line !== '}'){
    	var obj;
    	if(line.substr(line.length-1) ===','){
    		obj = JSON.parse(line.substr(0,line.length-1));
    	}else{
    		obj = JSON.parse(line);
    	}

    	if(obj.properties.CD_GEO){
        var cd_setor = obj.properties.CD_GEO.slice(0,15);
    		if(setor[cd_setor]){
	    		if(obj.properties.TOT_GERAL != null){
    				setor[cd_setor] += obj.properties.TOT_GERAL;
    			}
    		}else{
    			if(obj.properties.TOT_GERAL != null){
    				setor[cd_setor] = obj.properties.TOT_GERAL;
    			}else{
    				setor[cd_setor] = 0;
    			}
    		}
    	}
    }
    cl++;
});

rl.on('close', function() {

	for(var ix in setor){
  		var obj = {
  			setor:ix,
  			population:setor[ix]
  		}
  		var str = JSON.stringify(obj);
  		console.log(str);
  	}
});