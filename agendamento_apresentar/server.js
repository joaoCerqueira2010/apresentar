var http = require('http');
var fs = require('fs');     
var path = require('path'); 

var servidor = http.createServer(function (req, res) {

  var arquivo = path.join(__dirname, 'public', 'index.html');
  var conteudo = fs.readFileSync(arquivo);

  res.writeHead(200, { 'Content-Type': 'text/html; charset=utf-8' });
  res.end(conteudo);
});

servidor.listen(3000, function () {
  console.log('Ligado em http://localhost:3300');
});