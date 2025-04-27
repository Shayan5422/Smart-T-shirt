import requests
import sys
import argparse

# URL of the deployed backend
BACKEND_URL = "https://smart-t-shirt.onrender.com"

VALID_MODES = ['normal', 'abnormal', 'stopped']

def set_backend_mode(mode):
    """Sends a POST request to the backend to set the generation mode."""
    if mode not in VALID_MODES:
        print(f"Error: Invalid mode '{mode}'. Choose from: {', '.join(VALID_MODES)}")
        sys.exit(1)

    url = f"{BACKEND_URL}/set_mode/{mode}"
    
    try:
        print(f"Sending request to set mode to '{mode}' at {url}...")
        response = requests.post(url)
        response.raise_for_status() # Raise an exception for bad status codes (4xx or 5xx)
        
        # Check if the response contains JSON
        if 'application/json' in response.headers.get('Content-Type', ''):
            response_data = response.json()
            print(f"Success: Backend responded with status '{response_data.get('status', 'N/A')}', new mode is '{response_data.get('new_mode', 'N/A')}'")
        else:
             print(f"Success: Received non-JSON response (Status code: {response.status_code})")
             # Optionally print response text if needed for debugging
             # print(f"Response text: {response.text}")

    except requests.exceptions.RequestException as e:
        print(f"Error connecting to backend: {e}")
        sys.exit(1)
    except Exception as e:
        print(f"An unexpected error occurred: {e}")
        sys.exit(1)

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Control the ECG data generation mode of the backend.")
    parser.add_argument(
        "mode", 
        choices=VALID_MODES, 
        help="The desired mode to set the backend to."
    )
    
    args = parser.parse_args()
    set_backend_mode(args.mode) 