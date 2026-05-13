from flask import Flask, request, jsonify
import os
import logging
from logging.handlers import RotatingFileHandler

from werkzeug.middleware.dispatcher import DispatcherMiddleware
from prometheus_client import make_wsgi_app
from prometheus_flask_exporter import PrometheusMetrics

LOG_FILE_PATH = os.getenv("", "./app/logs/app.log")
LOG_LEVEL = os.getenv("LOG_LEVEL", "INFO").upper()
PORT = int(os.getenv("PORT", 5000))
GREETING_HEADER = os.getenv("GREETING_HEADER", "Welcome to the custom app")

app = Flask(__name__)

os.makedirs(os.path.dirname(LOG_FILE_PATH), exist_ok=True)

handler = RotatingFileHandler(LOG_FILE_PATH, maxBytes=10_000_000, backupCount=5)
formatter = logging.Formatter('%(asctime)s %(levelname)s %(message)s')
handler.setFormatter(formatter)

app.logger.addHandler(handler)
app.logger.setLevel(getattr(logging, LOG_LEVEL))

app.wsgi_app = DispatcherMiddleware(app.wsgi_app, {
    '/metrics': make_wsgi_app()
})

metrics = PrometheusMetrics(app)


@app.route("/")
def home():
    return GREETING_HEADER


@app.route("/status")
def status():
    return jsonify({"status": "ok"})


@app.route("/log", methods=["POST"])
def log_message():
    data = request.get_json()
    message = data.get("message") if data else None

    if not message:
        return jsonify({"error": "Message is required"}), 400

    app.logger.info(message)

    return jsonify({"status": "logged"}), 200


@app.route("/logs")
def get_logs():
    try:
        with open(LOG_FILE_PATH, "r") as f:
            logs = f.read()
    except FileNotFoundError:
        logs = ""
    return logs


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=PORT)
