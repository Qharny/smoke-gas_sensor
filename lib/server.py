from flask import Flask, jsonify
from flask_socketio import SocketIO, emit

app = Flask(__name__)
socketio = SocketIO(app)

@app.route('/status')
def get_status():
    # This would be updated by your ESP8266
    return jsonify({"sensor_value": current_sensor_value})

@socketio.on('connect')
def handle_connect():
    print('Client connected')

if __name__ == '__main__':
    socketio.run(app, host='0.0.0.0', port=5000)