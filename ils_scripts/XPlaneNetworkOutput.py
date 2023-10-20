import socket
import datetime

# Define the IP address and port to listen on
UDP_IP = "192.168.1.58"  # Use the IP address where X-Plane is sending data
UDP_PORT = 49001  # Use the port number configured in X-Plane's Data Output settings

# Create a UDP socket
sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)

# Bind the socket to the specified IP address and port
sock.bind((UDP_IP, UDP_PORT))

print(f"Listening for X-Plane datarefs on {UDP_IP}:{UDP_PORT}...")

while True:
    current_time = datetime.datetime.now()
    formatted_time = current_time.strftime("%Y-%m-%d %H:%M:%S")
    print("System Time:", formatted_time)

    # Receive data from X-Plane (you may need to adjust the buffer size)
    data, addr = sock.recvfrom(1024)
    print("")
    
    # Process and display the received data (replace this with your logic)
    print(f"Received data from {addr}: {data.hex()}")

# Close the socket (this will not be reached in this example)
sock.close()
