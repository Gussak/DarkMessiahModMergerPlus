#!/usr/bin/env python3

#WIP AI code

import sys
import os

def extract_lmp_entities():
    # Check if the user provided the input file argument
    if len(sys.argv) < 2:
        print("Usage: python3 extract.py <path_to_lmp_file>")
        sys.exit(1)

    input_file = sys.argv[1]

    # Verify the file exists
    if not os.path.isfile(input_file):
        print(f"Error: The file '{input_file}' does not exist.")
        sys.exit(1)

    # Generate an output filename based on the input name
    base_name, _ = os.path.splitext(input_file)
    output_file = f"{base_name}_extracted.txt"

    try:
        with open(input_file, "rb") as f:
            # Skip the 20-byte Valve lump header
            data = f.read()[20:]
            
            # Split at the first null terminator to isolate the text block from binary padding
            text_bytes = data.split(b'\x00')[0]
            
            # Decode the raw bytes into a readable text string
            text_data = text_bytes.decode('utf-8', errors='ignore')

        with open(output_file, "w", encoding="utf-8") as out:
            out.write(text_data)

        print(f"Success! Clean entity text extracted to: {output_file}")
        
    except Exception as e:
        print(f"An error occurred while processing the file: {e}")

if __name__ == "__main__":
    extract_lmp_entities()
