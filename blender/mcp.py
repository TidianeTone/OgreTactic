# Envoie un script Python au Blender ouvert (addon blender-mcp, port 9876).
# Usage : python mcp.py script.py
import socket, json, sys

code = open(sys.argv[1], encoding="utf-8").read()
s = socket.create_connection(("127.0.0.1", 9876), timeout=600)
s.sendall(json.dumps({"type": "execute_code", "params": {"code": code}}).encode())
buf = b""
while True:
    chunk = s.recv(1 << 20)
    if not chunk:
        break
    buf += chunk
    try:
        res = json.loads(buf.decode())
        break
    except ValueError:
        continue
if res.get("status") != "success":
    print(res.get("message", res))
    sys.exit(1)
print(res["result"].get("result", ""))
