from flask import Flask, jsonify, request
import time
import math
import random
from datetime import datetime, timezone

app = Flask(__name__)

# --- State Management ---
# 'stopped', 'normal', 'abnormal'
generation_mode = 'stopped'
current_time_ms = int(time.time() * 1000) # Use milliseconds timestamp
phase = 0.0

# --- Data Generation Logic ---
def generate_ecg_point():
    """Generates a single ECG data point based on the current mode."""
    global current_time_ms, phase

    timestamp = datetime.now(timezone.utc).isoformat() # ISO 8601 format
    value = 0.0
    time_increment_ms = 100 # Simulate 10 data points per second

    if generation_mode == 'normal':
        # Simulate a simple sine wave pattern
        value = math.sin(phase) * 50 + 60 # Base 60mV, amplitude 50mV
        phase += 0.5
    elif generation_mode == 'abnormal':
        # Simulate occasional spikes or irregularities
        if random.random() < 0.1: # 10% chance of a spike
            value = random.uniform(130, 180)
        else:
            value = math.sin(phase) * 40 + 65 # Slightly different normal pattern
            phase += 0.45
    else: # stopped
        # Return a baseline value or indicate stopped state? Return 0 for now.
        value = 0.0 
        # Or maybe return None/empty to indicate no data? For now, just return 0.

    current_time_ms += time_increment_ms
    # Use the *calculated* next time, not real time, for consistency
    simulated_timestamp = datetime.fromtimestamp(current_time_ms / 1000.0, tz=timezone.utc).isoformat()

    return {"time": simulated_timestamp, "value": round(value, 2)}

# --- API Endpoints ---
@app.route('/status', methods=['GET'])
def get_status():
    """Returns the current data generation mode."""
    return jsonify({"mode": generation_mode})

@app.route('/set_mode/<string:mode>', methods=['POST'])
def set_mode(mode):
    """Sets the data generation mode ('normal', 'abnormal', 'stop')."""
    global generation_mode, phase, current_time_ms
    valid_modes = ['normal', 'abnormal', 'stopped'] # Changed 'stop' to 'stopped'
    if mode in valid_modes:
        if generation_mode == 'stopped' and mode != 'stopped':
             # Reset time and phase when starting generation
             current_time_ms = int(time.time() * 1000)
             phase = 0.0
        generation_mode = mode
        print(f"Generation mode set to: {generation_mode}")
        return jsonify({"status": "success", "new_mode": generation_mode}), 200
    else:
        return jsonify({"status": "error", "message": f"Invalid mode. Use one of: {', '.join(valid_modes)}"}), 400

@app.route('/data', methods=['GET'])
def get_data():
    """Generates and returns the next ECG data point."""
    if generation_mode == 'stopped':
         return jsonify([]), 200 # Return empty list if stopped
         
    data_point = generate_ecg_point()
    # Return a list containing a single data point, as iOS app might expect an array
    return jsonify([data_point])

# The following block is commented out because gunicorn will run the app
# if __name__ == '__main__':
#     # Note: For Render, you'll use gunicorn, not the Flask dev server.
#     # The port is dynamically set by Render via the $PORT environment variable
#     # Debug mode should be off in production
#     app.run(host='0.0.0.0', port=5001, debug=False) 