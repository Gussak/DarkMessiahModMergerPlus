#!/usr/bin/env python3

#WIP AI code

import sys
import os
import re
import json
import argparse

# Define the help text layout to show immediately on -h or --help flags
HELP_EPILOG = """
 ### AI GENERATED (still testing WIP) ###
Usage Examples:
  1. Auto-detect QCT and convert to JSON by it's side:
     python keyValueToJSON.py weapon.qct

  2. Auto-detect JSON and convert to QCT (prompts before overwriting existing files):
     python keyValueToJSON.py weapon.json

  3. Force overwrite an existing output file without prompting:
     python keyValueToJSON.py weapon.qct -f

Format Detection Notes:
  - JSON files are identified by a starting root object curly bracket '{'.
  - QCT files are parsed using Valve KeyValues patterns, removing standard '//' comments.
"""

def clean_comments(text):
    """Removes C/C++ style comments from the text."""
    return re.sub(r'//.*', '', text)

def qct_to_dict(text):
    """Parses a Valve KeyValues string into a Python dictionary."""
    cleaned = clean_comments(text)
    tokens = re.findall(r'"[^"\\]*(?:\\.[^"\\]*)*"|[{}]', cleaned)
    
    result = {}
    stack = [result]
    current_key = None
    
    for token in tokens:
        if token == '{':
            if current_key:
                new_dict = {}
                stack[-1][current_key] = new_dict
                stack.append(new_dict)
                current_key = None
        elif token == '}':
            if len(stack) > 1:
                stack.pop()
        else:
            val = token[1:-1]
            if current_key is not None:
                stack[-1][current_key] = val
                current_key = None
            else:
                current_key = val
                
    return result

def dict_to_qct(data, indent=0):
    """Recursively serializes a dictionary into a Valve KeyValues format."""
    lines = []
    space = "    " * indent
    
    for key, value in data.items():
        if isinstance(value, dict):
            lines.append(f'{space}"{key}"')
            lines.append(f'{space}{{')
            lines.append(dict_to_qct(value, indent + 1))
            lines.append(f'{space}}}')
        else:
            lines.append(f'{space}"{key}"{space} "{value}"')
            
    return "\n".join(lines)

def detect_format(content):
    """Detects if content is likely JSON or QCT."""
    stripped = content.strip()
    if not stripped:
        return None
    if stripped.startswith('{') or stripped.startswith('['):
        try:
            json.loads(stripped)
            return 'json'
        except json.JSONDecodeError:
            pass
    return 'qct'

def main():
    # Integrated strict argparse customization for clean help menu display
    parser = argparse.ArgumentParser(
        description="Convert bidirectional formats between Valve QCT (KeyValues) and JSON formats.",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=HELP_EPILOG
    )
    parser.add_argument("input_file", help="Path to the input file (supports .qct or .json structures)")
    parser.add_argument("-f", "--force", action="store_true", help="Force overwrite the target output file without safety prompts")
    args = parser.parse_args()

    if not os.path.isfile(args.input_file):
        print(f"Error: File '{args.input_file}' not found.")
        sys.exit(1)

    with open(args.input_file, 'r', encoding='utf-8') as f:
        content = f.read()

    fmt = detect_format(content)
    if not fmt:
        print("Error: Input file is empty or unreadable.")
        sys.exit(1)

    base, _ = os.path.splitext(args.input_file)
    
    if fmt == 'json':
        output_file = f"{base}.qct"
        print("Detected format: JSON. Converting to QCT...")
        try:
            data = json.loads(content)
            output_content = dict_to_qct(data)
        except Exception as e:
            print(f"Failed to parse JSON: {e}")
            sys.exit(1)
    else:
        output_file = f"{base}.json"
        print("Detected format: QCT. Converting to JSON...")
        try:
            data = qct_to_dict(content)
            output_content = json.dumps(data, indent=4)
        except Exception as e:
            print(f"Failed to parse QCT: {e}")
            sys.exit(1)

    if os.path.exists(output_file) and not args.force:
        response = input(f"Output file '{output_file}' already exists. Overwrite? (y/N): ")
        if response.lower() not in ['y', 'yes']:
            print("Operation cancelled.")
            sys.exit(0)

    with open(output_file, 'w', encoding='utf-8') as f:
        f.write(output_content)
        
    print(f"Successfully converted and saved to '{output_file}'")

if __name__ == "__main__":
    main()
