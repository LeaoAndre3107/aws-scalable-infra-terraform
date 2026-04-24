const http = require('http');
const os = require('os');

const PORT = 3000;

const server = http.createServer((req, res) => {
  res.writeHead(200, { 'Content-Type': 'text/html' });
  res.end(`
    <html>
      <body style="font-family: Arial; text-align: center; padding: 50px;">
        <h1>Hello from Docker!</h1>
        <p>Hostname: <strong>${os.hostname()}</strong></p>
        <p>Plataforma: <strong>${os.platform()}</strong></p>
      </body>
    </html>
  `);
});

server.listen(PORT, () => {
  console.log(`Servidor rodando na porta ${PORT}`);
});