def binary_viewer(file_path):
    with open(file_path, 'rb') as file:
        byte = file.read(1)
        while byte:
            binary_representation = format(ord(byte), '08b')
            print(binary_representation, end=' ')
            byte = file.read(1)

# Usage:
binary_viewer('coeff.bin')
