var fileName = process.argv[2];

var fs = require('fs');
var readline = require('readline');
var stream = require('stream');
var readableStream = fs.createReadStream(fileName);
var outstream = new stream;
outstream.readable = true;
outstream.writable = true;

var subdis = {};
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
        var cd_sub = obj.properties.CD_GEO.slice(0,11);
        if(subdis[cd_sub]){
          if(obj.properties.TOT_GERAL != null){
            subdis[cd_sub] += obj.properties.TOT_GERAL;
          }
        }else{
          if(obj.properties.TOT_GERAL != null){
            subdis[cd_sub] = obj.properties.TOT_GERAL;
          }else{
            subdis[cd_sub] = 0;
          }
        }
      }
    }

    cl++;
});

rl.on('close', function() {

  for(var ix in subdis){
      var obj = {
        subdistrito:ix,
        population:subdis[ix]
      }
      var str = JSON.stringify(obj);
      console.log(str);
    }
});