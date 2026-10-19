const http = require('http');
const fs = require('fs');
const path = require('path');

const PORT = 8080;
const WEB_DIR = path.join(__dirname, '..', 'build', 'web');

const MIME_TYPES = {
	'.html': 'text/html',
	'.js': 'application/javascript',
	'.wasm': 'application/wasm',
	'.pck': 'application/octet-stream',
	'.png': 'image/png',
	'.json': 'application/json',
	'.ico': 'image/x-icon'
};

const server = http.createServer((req, res) => {
	let reqPath = req.url.split('?')[0];
	if (reqPath === '/' || reqPath === '') reqPath = '/index.html';

	const filePath = path.join(WEB_DIR, reqPath);

	fs.stat(filePath, (err, stats) => {
		if (err || !stats.isFile()) {
			res.writeHead(404, { 'Content-Type': 'text/plain' });
			res.end('404 Not Found');
			return;
		}

		const ext = path.extname(filePath).toLowerCase();
		const contentType = MIME_TYPES[ext] || 'application/octet-stream';

		res.writeHead(200, {
			'Content-Type': contentType,
			'Cross-Origin-Opener-Policy': 'same-origin',
			'Cross-Origin-Embedder-Policy': 'require-corp',
			'Cache-Control': 'no-cache'
		});

		const stream = fs.createReadStream(filePath);
		stream.pipe(res);
	});
});

server.listen(PORT, '127.0.0.1', () => {
	console.log(`[Yangon Frontline Web Server] Serving http://127.0.0.1:${PORT}`);
});
