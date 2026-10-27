import sys, os
from http.server import HTTPServer, SimpleHTTPRequestHandler

class NoCacheHandler(SimpleHTTPRequestHandler):
    def end_headers(self):
        self.send_header("Cache-Control", "no-cache, no-store, must-revalidate")
        self.send_header("Pragma", "no-cache")
        self.send_header("Expires", "0")
        super().end_headers()

if __name__ == "__main__":
    port = int(sys.argv[1]) if len(sys.argv) > 1 else 8080
    web_dir = sys.argv[2] if len(sys.argv) > 2 else "build/web"
    os.chdir(web_dir)
    print(f"Serving {web_dir} on 0.0.0.0:{port} with No-Cache headers...")
    server = HTTPServer(("0.0.0.0", port), NoCacheHandler)
    server.serve_forever()
