import uvicorn
import socket
import subprocess
import time
import requests
import os

def get_local_ip():
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    try:
        # doesn't even have to be reachable
        s.connect(('10.255.255.255', 1))
        IP = s.getsockname()[0]
    except Exception:
        IP = '127.0.0.1'
    finally:
        s.close()
    return IP

#this is temporary, we will use a better method later
def start_ngrok(port):
    try:
        # Check if ngrok is in the current directory
        ngrok_path = "./ngrok.exe" if os.name == 'nt' else "./ngrok"
        if not os.path.exists(ngrok_path):
            print("ngrok not found. Please download it from https://ngrok.com/download")
            return None
            
        # Start ngrok
        process = subprocess.Popen(
            [ngrok_path, "http", str(port)],
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE
        )
        
        # Wait for ngrok to start
        time.sleep(2)
        
        # Get the public URL
        try:
            response = requests.get("http://localhost:4040/api/tunnels")
            data = response.json()
            public_url = data["tunnels"][0]["public_url"]
            return public_url
        except:
            print("Could not get ngrok URL. Make sure ngrok is properly installed.")
            return None
            
    except Exception as e:
        print(f"Error starting ngrok: {e}")
        return None

if __name__ == "__main__":
    local_ip = get_local_ip()
    port = 8000
    
    print("\n=== Server Setup Options ===")
    print("1. Local access only (http://localhost:8000)")
    print("2. Local network access (http://{local_ip}:8000)")
    print("3. Public access via ngrok (requires ngrok)")
    
    choice = input("\nChoose an option (1-3): ")
    
    if choice == "1":
        print(f"\nServer will be accessible at: http://localhost:{port}")
    elif choice == "2":
        print(f"\nServer will be accessible at: http://{local_ip}:{port}")
        print("Note: Other devices on your local network can access this URL")
    elif choice == "3":
        public_url = start_ngrok(port)
        if public_url:
            print(f"\nServer will be accessible at: {public_url}")
            print("Share this URL with others to access your server")
        else:
            print("\nFalling back to local access only")
            print(f"Server will be accessible at: http://localhost:{port}")
    else:
        print("\nInvalid choice. Using local access only.")
        print(f"Server will be accessible at: http://localhost:{port}")
    
    print("\nPress Ctrl+C to stop the server")
    uvicorn.run("Database.server:app", host="0.0.0.0", port=port, reload=True) 