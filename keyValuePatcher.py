#!/usr/bin/env python3

#|#     BSD 3-Clause License
#|#
#|#     Copyright (c) 2026, Gussak<https://github.com/Gussak>
#|#
#|#     Redistribution and use in source and binary forms, with or without
#|#     modification, are permitted provided that the following conditions are met:
#|#
#|#     1. Redistributions of source code must retain the above copyright notice, this
#|#      list of conditions and the following disclaimer.
#|#
#|#     2. Redistributions in binary form must reproduce the above copyright notice,
#|#      this list of conditions and the following disclaimer in the documentation
#|#      and/or other materials provided with the distribution.
#|#
#|#     3. Neither the name of the copyright holder nor the names of its
#|#      contributors may be used to endorse or promote products derived from
#|#      this software without specific prior written permission.
#|#
#|#     THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
#|#     AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
#|#     IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
#|#     DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
#|#     FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
#|#     DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
#|#     SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
#|#     CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
#|#     OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
#|#     OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

"""
KeyValue Patcher for Dark Messiah .qct files

Generates and applies patches for Valve KeyValue configuration files.
Supports automatic injection of missing configuration blocks.

Supports duplicate keys (e.g., 'prop_physics', 'load_file') that can
appear multiple times. When patching, duplicate keys are APPENDED instead
of overwritten.

Patch files store keys and values WITHOUT double quotes (raw form).
Applied files maintain standard format with quotes around keys/values.

Example usage:
    ./keyValuePatcher.py create base.qct modded.qct -o weapon_tweak.kvpatch.json
    ./keyValuePatcher.py apply target.qct weapon_tweak.kvpatch.json
    ./keyValuePatcher.py apply target.qct weapon_tweak.kvpatch.json --append-missing
    ./keyValuePatcher.py apply target.qct weapon_tweak.kvpatch.json --prettify
"""

import argparse
import json
import os
import re
import sys
import traceback
from collections import defaultdict
from typing import Dict, Tuple, List, Optional, Any

# ==========================================
# CONFIGURATION & CONSTANTS
# ==========================================
NESTING_OPEN = os.getenv("KEYVALUE_NESTING_OPEN", "{")
NESTING_CLOSE = os.getenv("KEYVALUE_NESTING_CLOSE", "}")
LINE_ENDING = os.getenv("KEYVALUE_LINE_ENDING", '\r\n')
DEBUG = os.getenv("KEYVALUE_DEBUG", 'n').lower() in ('y', 'yes', '1', 'true')

# Duplicate key detection
DUPLICATE_KEYS = os.getenv("KEYVALUE_DUPLICATE_KEYS", "prop_physics,load_file").split(",")
DUPLICATE_KEYS = [key.strip() for key in DUPLICATE_KEYS if key.strip()]

# Verbosity level constants with clear names
VERBOSE_SILENT = 0
VERBOSE_FIXED_STUFF = 10           # Show auto-corrected lines
VERBOSE_BUG_TRACKING = 20          # Show diagnostic tracking info
VERBOSE_HELPER_DATA = 30           # Show detailed helper data
VERBOSE_FULL = 1000                # Show everything

# Compiled regex patterns for reuse
KV_PATTERN = re.compile(r'^("[^"]*")\s+("[^"]*")$')
BLOCK_PATTERN = re.compile(r'^\s*"?([^"\s//]+)"?\s*$')
BLOCK_PATTERN_EXTENDED = re.compile(r'^\s*"?([^"\s//{}]+)"?\s*$')
VALUE_REPLACEMENT_PATTERN = re.compile(r'(\s*"[^"]+"\s+)("[^"]*")(.*)')


def get_verbosity_level() -> int:
        """
        Parses KEYVALUE_VERBOSE environment variable into an integer level.
        
        Valid values:
          - 'false', '0': VERBOSE_SILENT (0)
          - 'true', '1': VERBOSE_FIXED_STUFF (10)
          - Any integer: that exact level
        
        Returns:
                Verbosity level as integer, defaults to VERBOSE_SILENT
        """
        val = os.environ.get("KEYVALUE_VERBOSE", "").strip().lower()
        if not val or val in ("false", "0"):
                return VERBOSE_SILENT
        if val in ("true", "1"):
                return VERBOSE_FIXED_STUFF
        try:
                return int(val)
        except ValueError:
                return VERBOSE_SILENT


VERBOSE_LEVEL = get_verbosity_level()


# ==========================================
# LOGGING ABSTRACTION
# ==========================================

class Logger:
        """Centralizes all logging to avoid scattered print() calls."""
        
        @staticmethod
        def diagnostic(message: str) -> None:
                """Log diagnostic information (VERBOSE_FULL)."""
                if VERBOSE_LEVEL >= VERBOSE_FULL:
                        print(f"[DIAGNOSTIC] {message}")
        
        @staticmethod
        def debug(message: str) -> None:
                """Log debug information (VERBOSE_HELPER_DATA)."""
                if VERBOSE_LEVEL >= VERBOSE_HELPER_DATA:
                        print(f"[DEBUG] {message}")
        
        @staticmethod
        def info(message: str) -> None:
                """Log informational message."""
                print(message)
        
        @staticmethod
        def warning(message: str) -> None:
                """Log warning to stderr."""
                print(f"[WARNING] {message}", file=sys.stderr)
        
        @staticmethod
        def error(message: str) -> None:
                """Log error to stderr."""
                print(f"[ERROR] {message}", file=sys.stderr)
        
        @staticmethod
        def fixed(file_path: str, line_num: int, original: str, fixed: str) -> None:
                """Log auto-fixed line (VERBOSE_FIXED_STUFF)."""
                if VERBOSE_LEVEL >= VERBOSE_FIXED_STUFF:
                        print(f"{file_path}:{line_num}:")
                        print(f"  Original: {original}")
                        print(f"  Fixed:    {fixed}")


# ==========================================
# CUSTOM EXCEPTIONS
# ==========================================

class ValidationError(Exception):
        """Raised when a line cannot be validated."""
        
        def __init__(self, file_path: str, line_num: int, line_content: str, message: str):
                self.file_path = file_path
                self.line_num = line_num
                self.line_content = line_content
                self.message = message
                super().__init__(f"{file_path}:{line_num}: {message}\nContent: {line_content}")


class ConfigError(Exception):
        """Raised for configuration parsing errors."""
        pass


# ==========================================
# HELPER FUNCTIONS
# ==========================================

def is_duplicate_key(key: str) -> bool:
        """
        Check if a key is marked as a duplicate key.
        
        Duplicate keys can appear multiple times and should be appended
        rather than overwritten during patching.
        
        Args:
                key: Key name to check
                
        Returns:
                True if key is in the duplicate keys list
        """
        return key in DUPLICATE_KEYS


def strip_inline_comment(line: str) -> str:
        """
        Remove inline comments safely for clean regex evaluation.
        
        Args:
                line: Input line that may contain inline comments
                
        Returns:
                Line with inline comments stripped and whitespace trimmed
        """
        if "//" in line:
                return line.split("//", 1)[0].strip()
        return line.strip()


def strip_quotes(text: str) -> str:
        """
        Remove surrounding double quotes from text.
        
        Args:
                text: Text that may be surrounded by quotes
                
        Returns:
                Text without surrounding quotes
        """
        if text.startswith('"') and text.endswith('"'):
                return text[1:-1]
        return text


def extract_inline_comment(line: str) -> str:
        """
        Extract the inline comment from a line (everything from // onward).
        
        Args:
                line: Raw line that may contain an inline comment
                
        Returns:
                Comment string including the '//' prefix, or empty string if none present
        """
        if "//" in line:
                comment_part = line.split("//", 1)[1].rstrip('\r\n').rstrip()
                return "//" + comment_part
        return ""


def set_inline_comment(line: str, comment: str) -> str:
        """
        Set or replace the inline comment on a line, preserving its line ending.
        
        Strips any existing inline comment, then appends the new one separated by
        two spaces.  Passing an empty string removes the comment entirely.
        
        Args:
                line: Original line (may or may not already have an inline comment)
                comment: New comment string, should start with '//'
                
        Returns:
                Line with the new inline comment, using LINE_ENDING as the line terminator
        """
        base = line.rstrip('\r\n')
        if "//" in base:
                base = base.split("//", 1)[0].rstrip()
        if comment:
                return base + "  " + comment + LINE_ENDING
        return base + LINE_ENDING


def clean_and_validate_for_kv(file_path: str, line_num: int, line: str) -> str:
        """
        Validate and clean a key-value line to match expected format.
        
        Expected format: "<key>" "<value>"
        
        Attempts automatic cleanup:
        1. Check if already valid
        2. Strip excess characters (quotes, semicolons, commas)
        3. Reconstruct if exactly 2 parts remain
        4. Raise ValidationError if cleanup fails
        
        Args:
                file_path: Path to file being processed
                line_num: Line number in file
                line: Raw line to validate
                
        Returns:
                Cleaned line matching KV_PATTERN
                
        Raises:
                ValidationError: If line cannot be fixed or is empty
        """
        # 1. Strip whitespace and handle comments/empty lines
        clean = line.strip()
        if not clean or clean.startswith('//'):
                Logger.diagnostic(f"Empty or fully commented line at {file_path}:{line_num}")
                return ""
        
        if '//' in clean:
                clean = clean.split('//', 1)[0].strip()
        
        # 2. Check if it already matches perfectly
        if KV_PATTERN.match(clean):
                Logger.diagnostic(f"Line is valid: {clean}")
                return clean
        
        # 3. AUTO-CLEANING ATTEMPT
        raw_text = clean.strip('" ;,')
        parts = [p.strip('" ;,') for p in re.split(r'[\s",;]+', raw_text) if p]
        
        # 4. RETRY if we isolated exactly two valid parts
        if len(parts) == 2:
                reconstructed = f'"{parts[0]}" "{parts[1]}"'
                Logger.fixed(file_path, line_num, line, reconstructed)
                return reconstructed
        
        # 5. UNRECOVERABLE
        raise ValidationError(
                file_path, line_num, line,
                f"Cannot fix: found {len(parts)} parts instead of 2"
        )


def parse_qct_to_dict(file_path: str) -> Dict[str, Any]:
        """
        Parse a Valve KeyValues .qct file into a nested Python dictionary.
        
        Handles:
        - Nested block structures with { } braces
        - Inline comments (//)
        - Key-value pairs in format: "<key>" "<value>"
        - Duplicate keys: stored as lists instead of overwriting
        
        Keys and values are stored WITHOUT surrounding quotes.
        Duplicate keys (e.g., 'prop_physics') are stored as lists of values.
        
        Args:
                file_path: Path to .qct file to parse
                
        Returns:
                Nested dictionary representing the file structure
                
        Raises:
                ConfigError: If file cannot be read or contains unrecoverable syntax errors
        """
        try:
                with open(file_path, 'r', encoding='utf-8', errors='ignore', newline='') as f:
                        lines = f.readlines()
        except IOError as e:
                raise ConfigError(f"Cannot read file {file_path}: {e}")
        
        if not lines:
                Logger.warning(f"Empty file: {file_path}")
                return {}
        
        root: Dict[str, Any] = {}
        stack: List[Dict[str, Any]] = [root]
        last_block_key: Optional[str] = None
        
        for line_num, line in enumerate(lines, 1):
                stripped = line.strip()
                if not stripped or stripped.startswith("//"):
                        continue
                
                clean_line = strip_inline_comment(line)
                if not clean_line:
                        continue
                
                if clean_line == NESTING_OPEN:
                        if last_block_key is not None:
                                new_block: Dict[str, Any] = {}
                                stack[-1][last_block_key] = new_block
                                stack.append(new_block)
                                last_block_key = None
                        continue
                
                if clean_line == NESTING_CLOSE:
                        if len(stack) > 1:
                                stack.pop()
                        continue
                
                block_match = BLOCK_PATTERN.match(clean_line)
                if block_match:
                        last_block_key = strip_quotes(block_match.group(1))
                        continue
                
                try:
                        clean_line_for_kv = clean_and_validate_for_kv(file_path, line_num, clean_line)
                except ValidationError as e:
                        Logger.error(f"Validation failed at {file_path}:{line_num}")
                        Logger.error(str(e))
                        print("[STACK TRACE]", file=sys.stderr)
                        traceback.print_exc(file=sys.stderr)
                        sys.exit(2)
                
                if not clean_line_for_kv:
                        continue
                
                kv_match = KV_PATTERN.match(clean_line_for_kv)
                if kv_match:
                        key = strip_quotes(kv_match.group(1))
                        val = strip_quotes(kv_match.group(2))
                        
                        # Handle duplicate keys by storing as list
                        if is_duplicate_key(key):
                                if key not in stack[-1]:
                                        stack[-1][key] = []
                                if not isinstance(stack[-1][key], list):
                                        stack[-1][key] = [stack[-1][key]]
                                stack[-1][key].append(val)
                        else:
                                stack[-1][key] = val
                        
                        last_block_key = None
                        continue
        
        return root


def parse_qct_comments(file_path: str) -> Dict[str, str]:
        """
        Parse a .qct file and return a flat dict mapping dot-paths to inline comments.
        
        Captures inline comments (// ...) that appear on the same line as a key-value
        pair or a block name.  The path convention mirrors flatten_dict:
          - Key-value line  →  path is the full dot-notation key path
          - Block name line →  path is the full dot-notation block path (resolved when
                               the opening '{' is encountered)
        
        Only paths that actually carry an inline comment are included in the result.
        
        Args:
                file_path: Path to the .qct file to parse
                
        Returns:
                Dict mapping dot-notation paths to their inline comment strings
                (e.g. {"weapons.sword.damage": "// buffed for balance"})
                
        Raises:
                ConfigError: If the file cannot be read
        """
        try:
                with open(file_path, 'r', encoding='utf-8', errors='ignore', newline='') as f:
                        lines = f.readlines()
        except IOError as e:
                raise ConfigError(f"Cannot read file {file_path}: {e}")
        
        result: Dict[str, str] = {}
        stack: List[str] = []
        last_block_key: Optional[str] = None
        last_block_comment: str = ""
        duplicate_counts: Dict[str, int] = defaultdict(int)
        
        for line in lines:
                stripped = line.strip()
                if not stripped or stripped.startswith("//"):
                        continue
                
                inline_comment = extract_inline_comment(line)
                clean_line = strip_inline_comment(line)
                if not clean_line:
                        continue
                
                if clean_line == NESTING_OPEN:
                        if last_block_key is not None:
                                stack.append(last_block_key)
                                if last_block_comment:
                                        result[".".join(stack)] = last_block_comment
                                last_block_key = None
                                last_block_comment = ""
                        continue
                
                if clean_line == NESTING_CLOSE:
                        if stack:
                                stack.pop()
                        last_block_key = None
                        last_block_comment = ""
                        continue
                
                block_match = BLOCK_PATTERN.match(clean_line)
                if block_match:
                        last_block_key = strip_quotes(block_match.group(1))
                        last_block_comment = inline_comment
                        continue
                
                kv_match = KV_PATTERN.match(clean_line)
                if kv_match:
                        key = strip_quotes(kv_match.group(1))
                        if is_duplicate_key(key):
                                full_path_base = ".".join(stack + [key])
                                idx = duplicate_counts[full_path_base]
                                full_path = f"{full_path_base}.{idx}"
                                duplicate_counts[full_path_base] += 1
                        else:
                                full_path = ".".join(stack + [key])
                        if inline_comment:
                                result[full_path] = inline_comment
                        last_block_key = None
                        last_block_comment = ""
        
        return result


def flatten_dict(d: Dict[str, Any], current_path: str = "", 
                                 result: Optional[Dict[str, Any]] = None) -> Dict[str, Any]:
        """
        Flatten a nested dictionary into dot-notated absolute paths.
        
        Example:
                {"weapons": {"sword": {"damage": "10"}}}
                ->
                {"weapons.sword.damage": "10"}
        
        Duplicate keys (stored as lists) are handled specially:
        - They are expanded into indexed paths like "path.key.0", "path.key.1", etc.
        
        Args:
                d: Dictionary to flatten
                current_path: Current path prefix (used recursively)
                result: Accumulator dictionary (used recursively)
                
        Returns:
                Flattened dictionary with dot-notation keys (keys/values have no quotes)
        """
        if result is None:
                result = {}
        for key, value in d.items():
                new_path = f"{current_path}.{key}" if current_path else key
                if isinstance(value, dict):
                        flatten_dict(value, new_path, result)
                elif isinstance(value, list):
                        # Duplicate key: store as indexed entries
                        for idx, item in enumerate(value):
                                indexed_path = f"{new_path}.{idx}"
                                result[indexed_path] = item
                else:
                        result[new_path] = value
        return result


def find_block_structure(lines: List[str]) -> Tuple[Dict[Tuple, int], Dict[Tuple, int]]:
        """
        Scan file once to identify block positions (start/end indices).
        
        Args:
                lines: List of file lines
                
        Returns:
                Tuple of (open_braces, close_braces) where keys are block paths as tuples
        """
        current_stack: List[str] = []
        last_block_key: Optional[str] = None
        open_braces: Dict[Tuple, int] = {}
        close_braces: Dict[Tuple, int] = {}
        
        for idx, line in enumerate(lines):
                stripped = line.strip()
                if not stripped or stripped.startswith("//"):
                        continue
                
                clean_line = strip_inline_comment(line)
                if not clean_line:
                        continue
                
                if clean_line == NESTING_OPEN:
                        if last_block_key is not None:
                                current_stack.append(last_block_key)
                                open_braces[tuple(current_stack)] = idx
                                last_block_key = None
                        continue
                
                if clean_line == NESTING_CLOSE:
                        if current_stack:
                                close_braces[tuple(current_stack)] = idx
                                current_stack.pop()
                        continue
                
                block_match = BLOCK_PATTERN_EXTENDED.match(clean_line)
                if block_match:
                        last_block_key = strip_quotes(block_match.group(1))
                else:
                        last_block_key = None
        
        return open_braces, close_braces


def append_nested_missing(lines: List[str], 
                                                  missing_patches: Dict[str, str]) -> List[str]:
        """
        Inject missing configurations by tracking structural depth.
        
        Groups patches by parent hierarchy and inserts them at appropriate
        locations without index corruption.
        
        Inserts keys and values WITH surrounding quotes (as required by format).
        The input missing_patches dict contains unquoted values.
        
        Args:
                lines: File lines to modify
                missing_patches: Dict of full_path -> unquoted_value for missing items
                
        Returns:
                Modified lines list with patches injected
        """
        # Group missing properties by their parent blocks
        grouped_patches: Dict[Tuple, List[Tuple[str, str]]] = defaultdict(list)
        for full_path, new_value in missing_patches.items():
                parts = full_path.split('.')
                target_hierarchy = tuple(parts[:-1])
                key_name = parts[-1]
                grouped_patches[target_hierarchy].append((key_name, new_value))
        
        # Scan block structure once outside the loop
        open_braces, close_braces = find_block_structure(lines)
        
        # Process group entries systematically
        for target_hierarchy, items in grouped_patches.items():
                # Find deepest matching block
                matched_depth = 0
                for depth in range(len(target_hierarchy), 0, -1):
                        check_path = target_hierarchy[:depth]
                        if check_path in open_braces and check_path in close_braces:
                                matched_depth = depth
                                break
                
                new_lines: List[str] = []
                if matched_depth == 0:
                        # No existing structure; create from scratch
                        insert_idx = len(lines)
                        for i, part in enumerate(target_hierarchy):
                                tabs = "\t" * i
                                new_lines.append(f'{tabs}"{part}"{LINE_ENDING}')
                                new_lines.append(f'{tabs}{{{LINE_ENDING}')
                        
                        final_tabs = "\t" * len(target_hierarchy)
                        for key_name, new_value in items:
                                new_lines.append(f'{final_tabs}"{key_name}"\t\t"{new_value}"{LINE_ENDING}')
                        
                        for i in range(len(target_hierarchy) - 1, -1, -1):
                                tabs = "\t" * i
                                new_lines.append(f'{tabs}}}{LINE_ENDING}')
                else:
                        # Extend existing structure
                        matched_path = target_hierarchy[:matched_depth]
                        missing_structure = target_hierarchy[matched_depth:]
                        insert_idx = close_braces[matched_path]
                        base_tabs = len(matched_path)
                        
                        for i, part in enumerate(missing_structure):
                                tabs = "\t" * (base_tabs + i)
                                new_lines.append(f'{tabs}"{part}"{LINE_ENDING}')
                                new_lines.append(f'{tabs}{{{LINE_ENDING}')
                        
                        final_tabs = "\t" * (base_tabs + len(missing_structure))
                        for key_name, new_value in items:
                                new_lines.append(f'{final_tabs}"{key_name}"\t\t"{new_value}"{LINE_ENDING}')
                        
                        for i in range(len(missing_structure) - 1, -1, -1):
                                tabs = "\t" * (base_tabs + i)
                                new_lines.append(f'{tabs}}}{LINE_ENDING}')
                
                lines[insert_idx:insert_idx] = new_lines
        
        return lines


def prettify_output(lines: List[str]) -> List[str]:
        """
        Prettify output by fixing indentation to match nesting depth.
        
        Scans the file to determine proper nesting depth and adjusts tab
        indentation for all lines accordingly.
        
        Args:
                lines: File lines to prettify
                
        Returns:
                Prettified lines with correct indentation
        """
        prettified: List[str] = []
        depth = 0
        
        for line in lines:
                stripped = line.strip()
                
                # Skip empty lines and preserve them as-is
                if not stripped:
                        prettified.append(line)
                        continue
                
                # Handle closing braces - decrease depth before writing
                if stripped == NESTING_CLOSE:
                        if depth > 0:
                                depth -= 1
                        proper_indent = "\t" * depth
                        prettified.append(f'{proper_indent}}}{LINE_ENDING}')
                        continue
                
                # Handle opening braces
                if stripped == NESTING_OPEN:
                        proper_indent = "\t" * depth
                        prettified.append(f'{proper_indent}{{{LINE_ENDING}')
                        depth += 1
                        continue
                
                # Regular line (key-value or block name)
                proper_indent = "\t" * depth
                # Preserve the content but fix the indentation
                prettified.append(f'{proper_indent}{stripped}{LINE_ENDING}')
        
        return prettified


# ==========================================
# COMMAND IMPLEMENTATIONS
# ==========================================

def handle_create(args) -> None:
        """
        Generate a patch JSON file by comparing original and modified configs.
        
        Identifies all key-value pairs that differ between two files and
        saves them to a JSON patch file. Keys and values in the patch file
        are stored WITHOUT surrounding quotes.
        
        Duplicate keys are expanded with indices (e.g., "prop_physics.0", "prop_physics.1").
        """
        if not os.path.exists(args.original):
                Logger.error(f"Original file not found: {args.original}")
                sys.exit(2)
        if not os.path.exists(args.modified):
                Logger.error(f"Modified file not found: {args.modified}")
                sys.exit(2)
        
        try:
                Logger.info(f"Parsing original: {args.original}")
                orig_tree = flatten_dict(parse_qct_to_dict(args.original))
                
                Logger.info(f"Parsing modified: {args.modified}")
                mod_tree = flatten_dict(parse_qct_to_dict(args.modified))
        except ConfigError as e:
                Logger.error(str(e))
                sys.exit(2)
        
        patch_data: Dict[str, str] = {}
        for path, mod_value in mod_tree.items():
                if path not in orig_tree or orig_tree[path] != mod_value:
                        patch_data[path] = mod_value
        
        orig_comments = parse_qct_comments(args.original)
        mod_comments = parse_qct_comments(args.modified)
        
        comment_patch: Dict[str, str] = {}
        for path, mod_comment in mod_comments.items():
                orig_comment = orig_comments.get(path, "")
                if mod_comment != orig_comment:
                        comment_patch[path] = mod_comment
        
        output_destination = args.output
        if output_destination == "patch.json" or output_destination.startswith("patch.json"):
                output_destination = args.modified + ".kvpatch.json"
        
        output_patch: Dict[str, Any] = dict(patch_data)
        if comment_patch:
                output_patch["__comments__"] = comment_patch
        
        try:
                with open(output_destination, 'w', encoding='utf-8', newline='') as f:
                        json.dump(output_patch, f, indent=4)
                        f.write(LINE_ENDING)
        except IOError as e:
                Logger.error(f"Failed to write output: {e}")
                sys.exit(2)
        
        total_changes = len(patch_data) + len(comment_patch)
        Logger.info(f"\nSuccess! Found {len(patch_data)} value change(s) and {len(comment_patch)} comment change(s).")
        Logger.info(f"Patch file: {output_destination}")
        Logger.info(f"Note: Keys and values in patch are stored without quotes.")
        Logger.info(f"Note: Duplicate keys are expanded with indices (e.g., prop_physics.0)")
        sys.exit(1 if total_changes > 0 else 0)


def handle_apply(args) -> None:
        """
        Apply a patch JSON file onto a target config file.
        
        Attempts to find and update all keys specified in the patch.
        Can optionally inject missing keys if --append-missing is enabled.
        Can optionally prettify output if --prettify is enabled.
        
        The patch file contains unquoted keys/values, but they are applied
        with proper quotes to the target file.
        
        For duplicate keys: instead of overwriting, new values are APPENDED
        after the existing ones.
        """
        if not os.path.exists(args.target):
                Logger.error(f"Target file not found: {args.target}")
                sys.exit(2)
        if not os.path.exists(args.patch):
                Logger.error(f"Patch file not found: {args.patch}")
                sys.exit(2)
        
        try:
                with open(args.patch, 'r', encoding='utf-8') as f:
                        patches = json.load(f)
        except json.JSONDecodeError as e:
                Logger.error(f"Invalid JSON in patch file: {e}")
                sys.exit(2)
        except IOError as e:
                Logger.error(f"Failed to read patch file: {e}")
                sys.exit(2)
        
        if not isinstance(patches, dict):
                Logger.error("Patch file must contain a JSON object")
                sys.exit(2)
        
        comment_patches: Dict[str, str] = patches.get("__comments__", {})
        patches = {k: v for k, v in patches.items() if k != "__comments__"}
        
        try:
                with open(args.target, 'r', encoding='utf-8', errors='ignore', newline='') as f:
                        lines = f.readlines()
        except IOError as e:
                Logger.error(f"Failed to read target file: {e}")
                sys.exit(2)
        
        current_stack: List[str] = []
        output_lines: List[str] = []
        applied_keys: set = set()
        duplicate_keys_found: Dict[str, int] = defaultdict(int)  # Track duplicate key counts
        last_block_key: Optional[str] = None
        
        Logger.info(f"Applying patches from '{args.patch}' onto '{args.target}'...")
        Logger.info(f"Duplicate keys to append (not overwrite): {', '.join(DUPLICATE_KEYS)}")
        
        if VERBOSE_LEVEL >= VERBOSE_HELPER_DATA:
                Logger.debug(f"Patches to apply: {patches}")
        
        for line_num, line in enumerate(lines, 1):
                # Normalize line endings
                line = line.rstrip('\r\n') + LINE_ENDING
                stripped = line.strip()
                
                if stripped == NESTING_OPEN:
                        if last_block_key is not None:
                                current_stack.append(last_block_key)
                                Logger.debug(f"Opened block: {'.'.join(current_stack)}")
                                last_block_key = None
                        output_lines.append(line)
                        continue
                
                elif stripped == NESTING_CLOSE:
                        if current_stack:
                                current_stack.pop()
                                Logger.debug(f"Closed block, now at: {'.'.join(current_stack)}")
                        output_lines.append(line)
                        continue
                
                if not stripped or stripped.startswith("//"):
                        output_lines.append(line)
                        continue
                
                clean_line = strip_inline_comment(stripped)
                
                block_match = BLOCK_PATTERN.match(clean_line)
                if block_match:
                        last_block_key = strip_quotes(block_match.group(1))
                        Logger.debug(f"Detected block key: {last_block_key}")
                        block_path = ".".join(current_stack + [last_block_key])
                        if block_path in comment_patches:
                                line = set_inline_comment(line, comment_patches[block_path])
                else:
                        try:
                                clean_line_for_kv = clean_and_validate_for_kv(args.target, line_num, clean_line)
                        except ValidationError as e:
                                Logger.warning(f"Skipping invalid line {line_num}: {e.message}")
                                output_lines.append(line)
                                continue
                        
                        if not clean_line_for_kv:
                                output_lines.append(line)
                                continue
                        
                        kv_match = KV_PATTERN.match(clean_line_for_kv)
                        if kv_match:
                                key_with_quotes = kv_match.group(1)
                                key = strip_quotes(key_with_quotes)
                                val_with_quotes = kv_match.group(2)
                                
                                full_path = ".".join(current_stack + [key])
                                
                                # Check if this is a duplicate key
                                if is_duplicate_key(key):
                                        # For duplicate keys, look for indexed patches (e.g., "path.prop_physics.0")
                                        dup_index = duplicate_keys_found[full_path]
                                        indexed_path = f"{full_path}.{dup_index}"
                                        duplicate_keys_found[full_path] += 1
                                        
                                        if indexed_path in patches:
                                                new_val = patches[indexed_path]
                                                try:
                                                        line = VALUE_REPLACEMENT_PATTERN.sub(
                                                                lambda m: f'{m.group(1)}"{new_val}"{m.group(3)}',
                                                                line,
                                                                count=1
                                                        )
                                                        applied_keys.add(indexed_path)
                                                        Logger.debug(f"Patched (duplicate): {indexed_path} = {new_val}")
                                                except Exception as e:
                                                        Logger.warning(f"Failed to patch {indexed_path}: {e}")
                                        else:
                                                if VERBOSE_LEVEL >= VERBOSE_BUG_TRACKING:
                                                        Logger.debug(f"Indexed key not in patch: {indexed_path}")
                                        if indexed_path in comment_patches:
                                                line = set_inline_comment(line, comment_patches[indexed_path])
                                else:
                                        # Normal key: standard patching
                                        if full_path in patches:
                                                new_val = patches[full_path]
                                                try:
                                                        line = VALUE_REPLACEMENT_PATTERN.sub(
                                                                lambda m: f'{m.group(1)}"{new_val}"{m.group(3)}',
                                                                line,
                                                                count=1
                                                        )
                                                        applied_keys.add(full_path)
                                                        Logger.debug(f"Patched: {full_path} = {new_val}")
                                                except Exception as e:
                                                        Logger.warning(f"Failed to patch {full_path}: {e}")
                                        else:
                                                if VERBOSE_LEVEL >= VERBOSE_BUG_TRACKING:
                                                        Logger.debug(f"Key not in patch: {full_path}")
                                        if full_path in comment_patches:
                                                line = set_inline_comment(line, comment_patches[full_path])
                                
                                last_block_key = None
                
                output_lines.append(line)
        
        requested_keys = set(patches.keys())
        missing_keys = requested_keys - applied_keys
        
        # Print summary
        print("\n" + "="*60)
        print("PATCH EXECUTION SUMMARY")
        print("="*60)
        print(f"Total requested updates: {len(requested_keys):3d}")
        print(f"Successfully modified:   {len(applied_keys):3d}")
        print(f"Missing items:           {len(missing_keys):3d}")
        print("="*60)
        
        if len(applied_keys) == 0:
                Logger.warning("No items were successfully patched!")
                Logger.warning("This may indicate:")
                Logger.warning("  - Target file structure differs from expected")
                Logger.warning("  - Syntax issues in target file")
                Logger.warning("  - Incompatible patch file")
        
        if missing_keys:
                print(f"\nMissing items ({len(missing_keys)}):")
                for key in sorted(missing_keys):
                        print(f"  - {key}")
                
                if args.append_missing:
                        Logger.info("\nInjecting missing options...")
                        missing_patches_dict = {k: patches[k] for k in missing_keys}
                        try:
                                output_lines = append_nested_missing(output_lines, missing_patches_dict)
                                Logger.info(f"Successfully appended {len(missing_keys)} missing options.")
                        except Exception as e:
                                Logger.error(f"Failed to append missing options: {e}")
                                sys.exit(2)
                else:
                        Logger.error("Operation aborted. Use --append-missing to inject missing keys.")
                        sys.exit(2)
        
        # Apply prettification if requested
        if args.prettify:
                Logger.info("Prettifying output formatting...")
                output_lines = prettify_output(output_lines)
                Logger.info("Output prettified with correct indentation.")
        
        output_destination = args.output if args.output else args.target
        try:
                with open(output_destination, 'w', encoding='utf-8', newline='') as f:
                        f.writelines(output_lines)
        except IOError as e:
                Logger.error(f"Failed to write output file: {e}")
                sys.exit(2)
        
        Logger.info(f"\nPatching complete. Output: {output_destination}")


# ==========================================
# MAIN INTERFACE & SUBCOMMAND ROUTING
# ==========================================

if __name__ == "__main__":
        parser = argparse.ArgumentParser(
                description="Unified Windows-Compatible Patcher for Dark Messiah .qct files.",
                epilog="""
Examples:
  %(prog)s create base.qct modded.qct -o weapon_tweak.kvpatch.json
  %(prog)s apply target.qct weapon_tweak.kvpatch.json
  %(prog)s apply target.qct weapon_tweak.kvpatch.json --append-missing
  %(prog)s apply target.qct weapon_tweak.kvpatch.json --prettify

Note:
  - Patch files store keys and values WITHOUT quotes
  - Applied files maintain proper format with quoted keys/values
  - Duplicate keys (prop_physics, load_file) are appended, not overwritten
  - Use --prettify to fix indentation to match nesting depth
  - Set KEYVALUE_DUPLICATE_KEYS env var to customize: "key1,key2,key3"
                """,
                formatter_class=argparse.RawDescriptionHelpFormatter
        )
        subparsers = parser.add_subparsers(dest="command", required=True, help="Subcommands")

        # 'create' subcommand
        parser_create = subparsers.add_parser(
                "create",
                help="Generate a JSON patch by comparing two .qct files"
        )
        parser_create.add_argument("original", help="Path to original/vanilla .qct file")
        parser_create.add_argument("modified", help="Path to your modified .qct file")
        parser_create.add_argument(
                "-o", "--output",
                default="patch.json",
                help="Output patch JSON file (default: <modified>.kvpatch.json)"
        )
        parser_create.set_defaults(func=handle_create)

        # 'apply' subcommand
        parser_apply = subparsers.add_parser(
                "apply",
                help="Apply a JSON patch to a .qct file"
        )
        parser_apply.add_argument("target", help="The .qct file to modify")
        parser_apply.add_argument("patch", help="The .kvpatch.json patch file to apply")
        parser_apply.add_argument(
                "-o", "--output",
                help="Output file (default: overwrite target)"
        )
        parser_apply.add_argument(
                "-a", "--append-missing",
                action="store_true",
                help="Inject missing keys instead of failing"
        )
        parser_apply.add_argument(
                "-p", "--prettify",
                action="store_true",
                help="Prettify output by fixing indentation to match nesting depth"
        )
        parser_apply.set_defaults(func=handle_apply)
        
        args = parser.parse_args()
        args.func(args)
