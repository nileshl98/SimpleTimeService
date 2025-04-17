from flask import Flask, jsonify, request
from datetime import datetime
import socket

app = Flask(__name__)

@app.route('/')
def home():
    ip = request.remote_addr
    return jsonify({
        "timestamp": datetime.utcnow().strftime('%Y-%m-%d %H:%M:%S UTC'),
        "ip": ip
    })

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=80)
