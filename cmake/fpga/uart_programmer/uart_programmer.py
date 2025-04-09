import sys
import serial
import argparse
import serial.tools.list_ports

def progress_bar(progress, total, info_str, bar_length=40):
    percent = float(progress) / total
    arrow = '=' * int(round(percent * bar_length))
    spaces = ' ' * (bar_length - len(arrow))

    sys.stdout.write(f"\r[{'=' * len(arrow)}{spaces}] {int(percent * 100)}% {info_str}")
    sys.stdout.flush()

    # Add a new line when the progress reaches 100%
    if progress == total:
        sys.stdout.write('\n')

def program(
        text_hex : str,
        data_hex : str,
        baudrate : int,
        dev      : str,
        debug    : bool = False
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

    dev_baud_str = f"----- Programming {dev} at baudrate {baudrate} ---"
    str_len = len(dev_baud_str)
    print(f"{'-' * str_len}")
    print(f"----- Programming {dev} at baudrate {baudrate} ---")
    print(f"{'-' * str_len}")

    ser.write(num_text_bytes)

    sync_f = False
    text_tx_error = 0
    for idx, byte in enumerate(text_bytes):
        wbyte = byte.to_bytes(1, 'big')
        ser.write(wbyte)
        if debug:
            if not sync_f:
                # Wait for the first similar byte
                while not sync_f:
                    print(f"INFO: Waiting for synchronization... ", end="")
                    rbyte = ser.read(1)
                    print(f"Received byte: {rbyte} ?= {wbyte}")
                    if rbyte == wbyte:
                        sync_f = True
                        print(f"INFO: Synchronization success!", end="")
            else:
                rbyte = ser.read(1)
                if rbyte != wbyte:
                    text_tx_error += 1
                    print(f"ERROR: sent and received bytes mismatch!")
                    print(f"ERROR: write/read bytes: {wbyte.hex()} / {rbyte.hex()}")
                else:
                    print(f"INFO: TEXT TX {idx}/{len(text_bytes)} correct ({int(idx/len(text_bytes)*100)}%)")
        else:
            progress_bar(idx+1, len(text_bytes), 'text segment')

    ser.write(num_data_bytes)

    sync_f = False
    data_tx_error = 0
    for idx, byte in enumerate(data_bytes):
        wbyte = byte.to_bytes(1, 'big')
        ser.write(wbyte)
        if debug:
            if not sync_f:
                # Wait for the first similar byte
                while not sync_f:
                    rbyte = ser.read(1)
                    if rbyte == wbyte:
                        sync_f = True
            else:
                rbyte = ser.read(1)
                if rbyte != wbyte:
                    data_tx_error += 1
                    print(f"ERROR: sent and received bytes mismatch!")
                    print(f"ERROR: write/read bytes: {wbyte.hex()} / {rbyte.hex()}")
                else:
                    print(f"INFO: DATA TX {idx}/{len(data_bytes)} correct ({int(idx/len(data_bytes)*100)}%)")
        else:
            progress_bar(idx+1, len(data_bytes), 'data segment')

    # Find the maximum width based on the length of text_bytes and data_bytes
    text_width = len(str(len(text_bytes)))
    data_width = len(str(len(data_bytes)))

    # Calculate the width of the longest line including text labels and values
    # The part before the values: "--------- Bytes written    : Text "
    prefix_length = len("--------- Bytes written    : Text ")
    # Calculate the full width of the lines
    line_width = prefix_length + max(text_width, data_width) + len(", Data: ") + max(text_width, data_width)
    header_str = " Finished programming "
    header_pad_width = int((line_width - len(header_str)) / 2)

    # Print the header with the calculated line width
    print(f"{'-' * header_pad_width}{header_str}{'-' * header_pad_width}")

    # Print the aligned output
    print(f"--------- Bytes written    : Text {len(text_bytes):<{text_width}}, Data: {len(data_bytes):<{data_width}}")
    # Print errors only if they are actually counted
    if debug:
        print(f"--------- Bytes read errors: Text {text_tx_error:<{text_width}}, Data: {data_tx_error:<{data_width}}")

    # Print the final footer line with the same calculated width
    print(f"{'-' * line_width}")


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
    parser.add_argument('--debug', action='store_true', help='Debug enabled (read back data on the UART and check the values are matching)')

    args = parser.parse_args()

    dev = getport(args.dev)

    program(
        text_hex=args.text_hex,
        data_hex=args.data_hex,
        baudrate=args.baudrate,
        dev=dev,
        debug=args.debug
    )

if __name__ == "__main__":
    main()
