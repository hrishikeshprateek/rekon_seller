#!/usr/bin/env python3
"""
Simple CORS proxy for Flask development
Forwards requests to backend with CORS headers
Run: python3 cors-proxy.py
"""

from http.server import HTTPServer, BaseHTTPRequestHandler
import json
import urllib.request
import urllib.error
from urllib.parse import urlparse, urlencode
import sys

BACKEND_URL = 'https://mobileappsandbox.reckonsales.com:8443/reckon-biz/api/reckonpwsorder'
PROXY_PORT = 3000

class CORSProxyHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        self._handle_request('GET')

    def do_POST(self):
        self._handle_request('POST')

    def do_PUT(self):
        self._handle_request('PUT')

    def do_DELETE(self):
        self._handle_request('DELETE')

    def do_OPTIONS(self):
        """Handle preflight requests"""
        self.send_response(200)
        self._set_cors_headers()
        self.end_headers()

    def _set_cors_headers(self):
        """Add CORS headers to response"""
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS, PATCH')
        self.send_header('Access-Control-Allow-Headers', 'Content-Type, Authorization, package_name, Accept')
        self.send_header('Access-Control-Allow-Credentials', 'true')

    def _handle_request(self, method):
        """Handle incoming request and forward to backend"""
        path = self.path
        full_url = BACKEND_URL + path

        timestamp = __import__('datetime').datetime.now().isoformat()
        print(f'[{timestamp}] {method} {path} -> {full_url}')

        try:
            # Read request body if exists
            content_length = int(self.headers.get('Content-Length', 0))
            body = self.rfile.read(content_length) if content_length > 0 else b''

            # Create request to backend
            req = urllib.request.Request(
                full_url,
                data=body if body else None,
                method=method,
                headers={
                    'Content-Type': self.headers.get('Content-Type', 'application/json'),
                    'Authorization': self.headers.get('Authorization', ''),
                    'package_name': self.headers.get('package_name', ''),
                }
            )

            # Send request to backend
            with urllib.request.urlopen(req) as response:
                status_code = response.status
                response_headers = dict(response.headers)
                response_body = response.read()

            # Send response to client with CORS headers
            self.send_response(status_code)
            for header, value in response_headers.items():
                if header.lower() not in ['content-encoding']:  # Skip problematic headers
                    self.send_header(header, value)
            self._set_cors_headers()
            self.end_headers()
            self.wfile.write(response_body)

        except urllib.error.URLError as e:
            print(f'[ERROR] URLError: {e.reason}')
            self.send_response(502)
            self.send_header('Content-Type', 'application/json')
            self._set_cors_headers()
            self.end_headers()
            error_response = json.dumps({
                'success': False,
                'message': f'Proxy error: {str(e.reason)}',
                'error': str(e.reason)
            })
            self.wfile.write(error_response.encode())
        except Exception as e:
            print(f'[ERROR] Exception: {e}')
            self.send_response(500)
            self.send_header('Content-Type', 'application/json')
            self._set_cors_headers()
            self.end_headers()
            error_response = json.dumps({
                'success': False,
                'message': f'Proxy error: {str(e)}',
                'error': str(e)
            })
            self.wfile.write(error_response.encode())

    def log_message(self, format, *args):
        """Suppress default logging"""
        pass

def run_proxy():
    server_address = ('127.0.0.1', PROXY_PORT)
    httpd = HTTPServer(server_address, CORSProxyHandler)

    print("""
╔═══════════════════════════════════════════════╗
║         CORS Proxy Server Started             ║
╠═══════════════════════════════════════════════╣
║ Proxy running on: http://localhost:3000       ║
║ Forwarding to:   Backend API                  ║
║                                               ║
║ Keep this terminal open while testing!        ║
║ Press Ctrl+C to stop                          ║
╚═══════════════════════════════════════════════╝
    """)

    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        print('\n\n[INFO] Proxy stopped')
        sys.exit(0)

if __name__ == '__main__':
    run_proxy()

