import serial
import argparse
import serial.tools.list_ports

def program(
        text_hex  : str,
        data_hex : str,
        baudrate  : int,
        dev       : str,
        ):

    ser = serial.Serial(dev, baudrate, timeout=100)

    with open(text_hex, 'r') as f:
        text_lines = f.readlines()

    with open(data_hex, 'r') as f:
        data_lines = f.readlines()

    text_bytes = b''
    for line in text_lines:
        line = line.strip()
        
        if line.startswith('@') or line == '':
            continue
        
        words = line.split()
        for word in words:
            byte_data = bytes.fromhex(word)
            byte_data = bytearray(byte_data)
            byte_data.reverse()
            text_bytes += byte_data

    data_bytes = b''
    for line in data_lines:
        line = line.strip()
        
        if line.startswith('@') or line == '':
            continue
        
        words = line.split()
        for word in words:
            byte_data = bytes.fromhex(word)
            byte_data = bytearray(byte_data)
            byte_data.reverse()
            data_bytes += byte_data

    num_text_bytes = len(text_bytes).to_bytes(4, byteorder='little')
    num_data_bytes = (len(data_bytes)).to_bytes(4, byteorder='little')

    
    print("-----------------------------------------------------")
    print(f"----- Programming {dev} at baudrate {baudrate} ---")

    ser.write(num_text_bytes)
    ser.write(text_bytes)

    ser.write(num_data_bytes)
    ser.write(data_bytes)

    print(f"------------ Finished programming ------------------")
    print(f"----- Bytes written: Text {len(text_bytes)}, Data: {len(data_bytes)} --------")
    print("-----------------------------------------------------")

def getport(dev):
    ports = serial.tools.list_ports.comports()
    port_names = [port.device for port in ports]
    
    default_port = port_names[0]
    if dev in port_names:
        default_port = dev
    elif "/dev/ttyUSB0" in port_names:
        default_port = "/dev/ttyUSB0"
        
    print(f"Available ports:")
    for index,port in enumerate(port_names):
        print(f"{index+1}: {port}", end="")
        if port == default_port:
            print(" (default)", end="")
            
        print()
        
    input_port = input(f"Enter port number (default {default_port}): ")
    try:
        port = port_names[int(input_port)-1]
    except:
        port = default_port
        
    print(f"Selected port: {port}")
    return port
        
    

def main():
    parser = argparse.ArgumentParser(
            prog='UART programmer',
            description='Programs the PupinChip Lite over bootloader')

    parser.add_argument('--text-hex', type=str, required=True, help='Hext file of TEXT section')
    parser.add_argument('--data-hex', type=str, required=True, help='Hext file of DATA section')
    parser.add_argument('--baudrate', type=int, default=115200, help='Baudrate of the UART bootloader')
    parser.add_argument('--dev', type=str, required=True, help='Path to the UART device e.g. /dev/ttyUSB0')

    args = parser.parse_args()

    dev = getport(args.dev)

    program(
            text_hex=args.text_hex,
            data_hex=args.data_hex,
            baudrate=args.baudrate,
            dev=dev,
            )

if __name__ == "__main__":
    main()
