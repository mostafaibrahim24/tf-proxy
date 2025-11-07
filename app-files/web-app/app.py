from flask import Flask
import socket

def get_private_ip():
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    s.connect(("8.8.8.8", 80))
    ip = s.getsockname()[0]
    s.close()
    return ip

app = Flask(__name__)

@app.route('/')
def hello_world():
    ip_address = get_private_ip()
    return f'''
    <!DOCTYPE html>
    <html>
    <head><title>Flask Backend</title></head>
    <body>
        <p>Instance Private IP: <strong>{ip_address}</strong></p>
    </body>
    </html>
    '''

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)