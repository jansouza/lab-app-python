from flask import Flask, render_template, jsonify
import socket

app = Flask(__name__)
__version__ = '1.0.0'

    
@app.route("/")
def index():
    try:
        host_name = socket.gethostname()
        host_ip = socket.gethostbyname(host_name)
        return render_template('index.html', hostname=host_name, ip=host_ip, version=__version__)
    except Exception:
        return render_template('error.html')


@app.route("/api")
def api():
    return jsonify({'hello': 'world'})


@app.route("/health")
def health():
    return jsonify({'health': 'ok'})


@app.route("/version")
def version():
    return jsonify({'version': __version__})


if __name__ == "__main__":
    app.run(host='0.0.0.0', port=8080, debug=True)
