#!/usr/bin/env python3
import http.server
import socketserver
import socket
import os
import sys

PORT = 8080
APK_PATH = "build/app/outputs/flutter-apk/app-release.apk"

if not os.path.exists(APK_PATH):
    print(f"APK introuvable : {APK_PATH}")
    print("Lance d'abord : flutter build apk --release")
    sys.exit(1)

def get_local_ip():
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    try:
        s.connect(("8.8.8.8", 80))
        return s.getsockname()[0]
    finally:
        s.close()

ip = get_local_ip()
filename = os.path.basename(APK_PATH)
url = f"http://{ip}:{PORT}/{filename}"

print(f"\n{'='*50}")
print(f"  APK disponible sur le réseau local :")
print(f"  {url}")
print(f"{'='*50}")

try:
    import qrcode
    qr = qrcode.QRCode(border=2)
    qr.add_data(url)
    qr.make(fit=True)
    print()
    qr.print_ascii(invert=True)
    print()
except ImportError:
    print("\n  (Installe qrcode pour afficher un QR code : pip3 install qrcode)")
    print(f"  Ou génère un QR code sur https://qr.io pour l'URL ci-dessus\n")

print("  Assure-toi que ton téléphone est sur le même Wi-Fi.")
print("  Active 'Sources inconnues' dans les paramètres Android.")
print("  Ctrl+C pour arrêter.\n")

os.chdir(os.path.dirname(os.path.abspath(APK_PATH)))

class Handler(http.server.SimpleHTTPRequestHandler):
    def log_message(self, format, *args):
        print(f"  [{self.address_string()}] {format % args}")

with socketserver.TCPServer(("", PORT), Handler) as httpd:
    httpd.serve_forever()
