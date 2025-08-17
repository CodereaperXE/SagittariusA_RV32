import serial
import time

def encode_uvarint(n: int) -> bytes:
    out = bytearray()
    while n >= 0x80:
        out.append((n & 0x7F) | 0x80)
        n >>= 7
    out.append(n)
    return bytes(out)


ser = serial.Serial("/dev/ttyACM0", 115200, timeout=2)
time.sleep(1)  # wait for Pico to reset

ser.write(b"w")
time.sleep(0.05)  
print(ser.read(100).decode())

ser.write(encode_uvarint(520))
time.sleep(0.05)
print(ser.read(1024).decode())
print("over")
data = b"A" * 520
ser.write(data)
time.sleep(0.1)
print(ser.read(500000))	

ser.write(b"r")
time.sleep(0.1)
print(ser.read(500000))
# ser.write(b"b")
# ser.write(b"b")
# time.sleep(0.1)
# print(ser.read(500000))

