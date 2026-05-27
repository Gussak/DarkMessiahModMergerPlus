#!/usr/bin/env python3

# BSD 3-Clause License
#
# Copyright (c) 2026, Gussak<https://github.com/Gussak>
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# 1. Redistributions of source code must retain the above copyright notice, this
#  list of conditions and the following disclaimer.
#
# 2. Redistributions in binary form must reproduce the above copyright notice,
#  this list of conditions and the following disclaimer in the documentation
#  and/or other materials provided with the distribution.
#
# 3. Neither the name of the copyright holder nor the names of its
#  contributors may be used to endorse or promote products derived from
#  this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
# CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
# OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

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
import inspect
import json
import os
import re
import sys
import traceback
from collections import defaultdict
from typing import Dict, Tuple, List, Optional, Any
from enum import Flag, auto

# ==========================================
# CONFIGURATION & CONSTANTS
# ==========================================
FUN_CHARS = "❌ ✖ ✗ ✔ ☑ ✅ ⚙️ ⚠ ⟳ 🔒 ★ ☆ ✦ ✺ ☼ ☾ ➤ ▶ ◀ ⬆ ⬇ ⤓ ⮀ ∞ ∑ √ π Ω ₿ € █ ▒ ─ │ ┌" # these didnt show in geany: ⏻ ⮌
NESTING_OPEN = os.getenv("KEYVALUE_NESTING_OPEN", "{")
NESTING_CLOSE = os.getenv("KEYVALUE_NESTING_CLOSE", "}")
LINE_ENDING = os.getenv("KEYVALUE_LINE_ENDING", "\r\n")
DEBUG = os.getenv('KEYVALUE_DEBUG', 'n').lower() in ('y', 'yes', '1', 'true')

# Duplicate key detection
DUPLICATE_KEYS = os.getenv("KEYVALUE_DUPLICATE_KEYS", "prop_physics,load_file").split(",")
DUPLICATE_KEYS = [key.strip() for key in DUPLICATE_KEYS if key.strip()]

# Dominant multi-keys: like duplicate keys but when a patch is applied, all
# existing occurrences in the same block are erased and replaced exclusively
# by the values from the patch.
DOMINANT_MULTI_KEYS = os.getenv("KEYVALUE_DOMINANT_MULTI_KEYS", "prop_physics").split(",")
DOMINANT_MULTI_KEYS = [key.strip() for key in DOMINANT_MULTI_KEYS if key.strip()]

# Keys that should only be appended if their exact value does not already exist
# in the target block. Useful for preventing duplicate entries like language packs.
DUPLICATE_KEYS_WITHOUT_DUP_VALUES = os.getenv(
    "KEYVALUE_DUPLICATE_KEYS_WITHOUT_DUP_VALUES", "load_file"
).split(",")
DUPLICATE_KEYS_WITHOUT_DUP_VALUES = [
    key.strip() for key in DUPLICATE_KEYS_WITHOUT_DUP_VALUES if key.strip()
]

# 1. Automate masks using sequential bit-shifting behind the scenes
class LogConfig(Flag): #only append new options, do not organize (or will have to update the comments..)
        SILENT           = 0
        ERRORS_CORRECTED = auto()  # 1  (1 << 0) Show auto-corrected lines
        BUG_TRACKING     = auto()  # 2  (1 << 1) Show diagnostic tracking info, running extra code just to help on debug
        DEBUG            = auto()  # 4  (1 << 2) Show detailed helper debug data
        SHOW_MISSING     = auto()  # show missing keys even if already appending them

# --- Define your custom FULL set here ---
# Mix your preferred default flags using the bitwise OR mixer
FULL_SET = LogConfig.ERRORS_CORRECTED | LogConfig.BUG_TRACKING | LogConfig.DEBUG | LogConfig.SHOW_MISSING

# Use Bitwise OR (|=) to combine environment strings into your state
def set_verbosity_from_env():
        global verbosity
        verbosity = LogConfig.SILENT
        env_str = os.environ.get("KEYVALUE_VERBOSE_OPTIONS", "")  # ex.: export KEYVALUE_VERBOSE_OPTIONS="ERRORS_CORRECTED,BUG_TRACKING"
        if env_str:
                options = [opt.strip().upper() for opt in env_str.split(",")]
                for opt in options:
                        # 1. Intercept the custom 'FULL' string manually
                        if opt == "FULL":
                                verbosity |= FULL_SET
                        # 2. Otherwise look it up in the standard enum
                        elif opt in LogConfig.__members__:
                                verbosity |= LogConfig[opt]  # Bitwise OR sets the bit
                        else:
                                print(f"Warning: Unknown log option ignored: {opt}")

set_verbosity_from_env()

def verify_flags(flags_to_check: LogConfig) -> bool:
        """Returns True if AT LEAST ONE of the specified flags is active."""
        return bool(verbosity & flags_to_check)

# Use Bitwise XOR (^=) whenever you need live toggling
def toggle_flag(flag: LogConfig):
        global verbosity
        verbosity ^= flag  # Flips the state of the target bit

# Compiled regex patterns for reuse
KV_PATTERN = re.compile(r'^("[^"]*")\s+("[^"]*")$')
BLOCK_PATTERN = re.compile(r'^\s*"?([^"\s//0-9]+)"?\s*$') #this prevents numbers in block names
BLOCK_PATTERN_EXTENDED = re.compile(r'^\s*"?([^"\s//{}0-9]+)"?\s*$') #this prevents numbers in block names
VALUE_REPLACEMENT_PATTERN = re.compile(r'(\s*"[^"]+"\s+)("[^"]*")(.*)')

def strip_line_ending(line: str) -> str:
        """Strip all trailing CR and LF characters from a line."""
        return line.rstrip("\r\n").rstrip("\n").rstrip("\r")


# ==========================================
# LOGGING ABSTRACTION
# ==========================================


class Logger:
        """Centralizes all logging to avoid scattered print() calls."""
        
        @staticmethod
        def ln(): #TODO let a call stack depth be determined like -1 -2 -3
                """Returns the line number of the caller."""
                return inspect.currentframe().f_back.f_back.f_lineno

        @staticmethod
        def diagnostic(message: str) -> None:
                """Log diagnostic information (BUG_TRACKING)."""
                if verify_flags(LogConfig.BUG_TRACKING):
                        print(f"[DIAGNOSTIC:{Logger.ln()}] {message}")

        @staticmethod
        def debug(message: str) -> None:
                """Log debug information (DEBUG)."""
                if verify_flags(LogConfig.DEBUG):
                        print(f"[DEBUG:{Logger.ln()}] {message}")

        @staticmethod
        def info(message: str) -> None:
                """Log informational message."""
                print(message)

        @staticmethod
        def warning(message: str) -> None:
                """Log warning to stderr."""
                print(f"[WARNING:{Logger.ln()}] {message}", file=sys.stderr)

        @staticmethod
        def error(message: str) -> None:
                """Log error to stderr."""
                print(f"[ERROR:{Logger.ln()}] {message}", file=sys.stderr)

        @staticmethod
        def fixed(file_path: str, line_num: int, original: str, fixed: str) -> None:
                """Log auto-fixed line (ERRORS_CORRECTED)."""
                if verify_flags(LogConfig.ERRORS_CORRECTED):
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
        rather than overwritten during patching.  Dominant multi-keys are
        also treated as duplicate keys so they receive indexed patch paths.

        Args:
                        key: Key name to check

        Returns:
                        True if key is in the duplicate or dominant keys list
        """
        return key in DUPLICATE_KEYS or key in DOMINANT_MULTI_KEYS


def is_dominant_key(key: str) -> bool:
        """
        Check if a key is marked as a dominant multi-key.

        Dominant keys behave like duplicate keys during patch creation
        (they get indexed paths), but during patch application ALL existing
        occurrences in the same block are erased and replaced solely by
        the values from the patch.

        Args:
                        key: Key name to check

        Returns:
                        True if key is in the dominant multi-keys list
        """
        return key in DOMINANT_MULTI_KEYS


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
                comment_part = strip_line_ending(line.split("//", 1)[1]).rstrip()
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
        base = line.rstrip("\r\n").rstrip("\n").rstrip("\r")
        if "//" in base:
                base = base.split("//", 1)[0].rstrip()
        if comment:
                return base + "  " + comment + LINE_ENDING
        return base + LINE_ENDING

def parse_key_value(line: str) -> tuple[str, str] | None:
        """Parses a line to extract a key and value using regular expressions.

        Supports:
        - Quoted or unquoted keys (no spaces/quotes allowed if unquoted)
        - Quoted or unquoted values (can be empty if quoted)
        - Leading and trailing whitespace
        """
        # 1. Define modular, self-documenting sub-patterns
        QUOTED_STR = r'"([^"]*)"'  # Captures inside ""; allows empty strings
        NO_SPACE_STR = r"([^\s\"]+)"  # Captures non-space, non-quote characters

        # 2. Assemble the final pattern using semantic names
        KEY_PART = f"(?:{QUOTED_STR}|{NO_SPACE_STR})"
        VALUE_PART = f"(?:{QUOTED_STR}|{NO_SPACE_STR})"

        # The middle \s+ ensures a space or tab MUST separate key and value
        FULL_PATTERN = f"^\s*{KEY_PART}\s+{VALUE_PART}\s*$"

        # 3. Match against the line
        match = re.match(FULL_PATTERN, line)

        if match:
                # Directly map the conceptual capture groups to their numbers
                quoted_key = match.group(1)
                unquoted_key = match.group(2)
                quoted_value = match.group(3)
                unquoted_value = match.group(4)

                # Resolve which group successfully captured data
                key = quoted_key or unquoted_key
                value = quoted_value if quoted_value is not None else unquoted_value

                return key, value

        return None


def sc_parse_key_value():
        test_cases = [
                "   key-with+chars_ 10   ",  # Unquoted special key, unquoted value, padding
                '"my-key" "some value"',  # Quoted key, quoted value with spaces
                'simple_key ""',  # Unquoted key, empty quoted value
                '   "spaced key"   "another value"   ',  # Quoted key with spaces, padded
                "invalid_line_no_value",  # Invalid: Missing value component (Fails ❌)
                "key too many unquoted words",  # Invalid: Unquoted spaces break the pattern
        ]

        print("--- Running Key-Value Parser Tests ---\n")
        for i, test in enumerate(test_cases, 1):
                result = parse_key_value(test)
                print(f"Test {i}: Input -> {repr(test)}")
                if result:
                        key, value = result
                        print(f"        Result -> Key: '{key}' | Value: '{value}'")
                else:
                        print("        Result -> ❌ No match found (Invalid syntax)")
                print("-" * 40)

def handle_selftests(args) -> None:
        sc_parse_key_value()

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
        if not clean or clean.startswith("//"):
                Logger.diagnostic(f"Empty or fully commented line at {file_path}:{line_num}")
                return ""

        if "//" in clean:
                clean = clean.split("//", 1)[0].strip()

        # 2. Check if it already matches perfectly
        if KV_PATTERN.match(clean):
                Logger.diagnostic(f"Line is valid: {clean}")
                return clean

        # 3. AUTO-CLEANING ATTEMPT
        result = parse_key_value(clean)
        if verify_flags(LogConfig.DEBUG):
                Logger.debug(f"{clean} #{result}")
        if result:
                key, value = result
                reconstructed = f'"{key}" "{value}"'
                Logger.fixed(file_path, line_num, line, reconstructed)
                return reconstructed

        # Second try: no quotes present — split on whitespace/commas/semicolons.
        # Only safe when neither key nor value contains spaces.
        raw_text = clean.strip('" ;,')
        parts = [p.strip('" ;,') for p in re.split(r'[\s",;]+', raw_text) if p]

        # 4. RETRY if we isolated exactly two valid parts
        if len(parts) == 2:
                reconstructed = f'"{parts[0]}" "{parts[1]}"'
                Logger.fixed(file_path, line_num, line, reconstructed)
                return reconstructed

        # 5. UNRECOVERABLE
        raise ValidationError(
                file_path, line_num, line, f"Cannot fix: found {len(parts)} parts instead of 2\n{file_path}:{line_num}: {line}"
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
                with open(file_path, "r", encoding="utf-8", errors="ignore", newline="") as f:
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
                        clean_line_for_kv = clean_and_validate_for_kv(
                                file_path, line_num, clean_line
                        )
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

        # Warn when the file ends with unclosed blocks — the parsed tree may be
        # incomplete because values inside those blocks are still accessible but
        # the hierarchy was never properly terminated.
        if len(stack) > 1:
                Logger.warning(
                        f"File ended with {len(stack) - 1} unclosed block(s) — "
                        "parsed tree may be incomplete."
                )

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
                with open(file_path, "r", encoding="utf-8", errors="ignore", newline="") as f:
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


def flatten_dict(
        d: Dict[str, Any], current_path: str = "", result: Optional[Dict[str, Any]] = None
) -> Dict[str, Any]:
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

        # Warn when the file ends with unclosed blocks — close_braces will be
        # missing entries for these levels, which may affect missing-key injection.
        if current_stack:
                Logger.warning(
                        f"Block structure scan: {len(current_stack)} unclosed block(s) at end of file: "
                        + " > ".join(current_stack)
                )

        return open_braces, close_braces


def _value_exists_in_scope(
    lines: List[str], target_hierarchy: Tuple[str, ...], key_name: str, value_to_check: str
) -> bool:
    """
    Scan `lines` to determine if a specific key-value pair already exists
    within the block scope defined by `target_hierarchy`.
    
    Returns True if the exact combination is found, False otherwise.
    """
    current_stack: List[str] = []
    last_block_key: Optional[str] = None
    # Root scope matches when current_stack is empty
    in_target_block = len(target_hierarchy) == 0

    for line in lines:
        stripped = line.strip()
        if not stripped or stripped.startswith("//"):
            continue
        clean = strip_inline_comment(stripped).strip()

        if clean == NESTING_OPEN:
            if last_block_key is not None:
                current_stack.append(last_block_key)
                if tuple(current_stack) == target_hierarchy:
                    in_target_block = True
                last_block_key = None
            continue

        if clean == NESTING_CLOSE:
            if current_stack:
                if tuple(current_stack) == target_hierarchy:
                    in_target_block = False
                current_stack.pop()
            continue

        block_match = BLOCK_PATTERN.match(clean)
        if block_match:
            last_block_key = strip_quotes(block_match.group(1))
            continue

        if in_target_block:
            kv_match = KV_PATTERN.match(clean)
            if kv_match:
                k = strip_quotes(kv_match.group(1))
                v = strip_quotes(kv_match.group(2))
                if k == key_name and v == value_to_check:
                    return True
    return False


def append_nested_missing(
        lines: List[str], missing_patches: Dict[str, str]
) -> List[str]:
        """
        Inject missing configurations by tracking structural depth.
        
        ── NEW ── Automatically skips appending keys listed in 
        DUPLICATE_KEYS_WITHOUT_DUP_VALUES if their exact value already 
        exists in the target block.
        """
        grouped_patches: Dict[Tuple, List[Tuple[str, str]]] = defaultdict(list)
        for full_path, new_value in missing_patches.items():
                parts = full_path.split(".")

                # Detect indexed duplicate keys and collapse to base key
                if len(parts) >= 2 and parts[-1].isdigit() and parts[-2] in DUPLICATE_KEYS:
                        target_hierarchy = tuple(parts[:-2])
                        key_name = parts[-2]
                else:
                        target_hierarchy = tuple(parts[:-1])
                        key_name = parts[-1]

                grouped_patches[target_hierarchy].append((key_name, new_value))

        open_braces, close_braces = find_block_structure(lines)

        for target_hierarchy, items in grouped_patches.items():
                # ── NEW: Filter out values that already exist in the target block ──
                filtered_items = []
                for key_name, new_value in items:
                        if key_name in DUPLICATE_KEYS_WITHOUT_DUP_VALUES:
                                if _value_exists_in_scope(lines, target_hierarchy, key_name, new_value):
                                        Logger.debug(
                                                f"Skipped append (value exists in scope): "
                                                f"{key_name} = {new_value}"
                                        )
                                        continue
                        filtered_items.append((key_name, new_value))

                # If all items were filtered out, skip block creation/injection for this hierarchy
                if not filtered_items:
                        continue

                # Find deepest matching block
                matched_depth = 0
                for depth in range(len(target_hierarchy), 0, -1):
                        check_path = target_hierarchy[:depth]
                        if check_path in open_braces and check_path in close_braces:
                                matched_depth = depth
                                break

                new_lines: List[str] = []
                if matched_depth == 0:
                        insert_idx = len(lines)
                        for i, part in enumerate(target_hierarchy):
                                tabs = "\t" * i
                                new_lines.append(f'{tabs}"{part}"{LINE_ENDING}')
                                new_lines.append(f"{tabs}{{{LINE_ENDING}")

                        final_tabs = "\t" * len(target_hierarchy)
                        for key_name, new_value in filtered_items:  # ── NEW: use filtered ──
                                new_lines.append(
                                        f'{final_tabs}"{key_name}"\t\t"{new_value}"{LINE_ENDING}'
                                )

                        for i in range(len(target_hierarchy) - 1, -1, -1):
                                tabs = "\t" * i
                                new_lines.append(f"{tabs}}}{LINE_ENDING}")
                else:
                        matched_path = target_hierarchy[:matched_depth]
                        missing_structure = target_hierarchy[matched_depth:]
                        insert_idx = close_braces[matched_path]
                        base_tabs = len(matched_path)

                        for i, part in enumerate(missing_structure):
                                tabs = "\t" * (base_tabs + i)
                                new_lines.append(f'{tabs}"{part}"{LINE_ENDING}')
                                new_lines.append(f"{tabs}{{{LINE_ENDING}")

                        final_tabs = "\t" * (base_tabs + len(missing_structure))
                        for key_name, new_value in filtered_items:  # ── NEW: use filtered ──
                                new_lines.append(
                                        f'{final_tabs}"{key_name}"\t\t"{new_value}"{LINE_ENDING}'
                                )

                        for i in range(len(missing_structure) - 1, -1, -1):
                                tabs = "\t" * (base_tabs + i)
                                new_lines.append(f"{tabs}}}{LINE_ENDING}")

                lines[insert_idx:insert_idx] = new_lines
                open_braces, close_braces = find_block_structure(lines)

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
                        prettified.append(f"{proper_indent}}}{LINE_ENDING}")
                        continue

                # Handle opening braces
                if stripped == NESTING_OPEN:
                        proper_indent = "\t" * depth
                        prettified.append(f"{proper_indent}{{{LINE_ENDING}")
                        depth += 1
                        continue

                # Regular line (key-value or block name)
                proper_indent = "\t" * depth
                # Preserve the content but fix the indentation
                prettified.append(f"{proper_indent}{stripped}{LINE_ENDING}")

        return prettified


# ==========================================
# COMMAND IMPLEMENTATIONS
# ==========================================


def _filter_nondom_dup_to_new_only(
        patch_data: Dict[str, str],
        orig_tree: Dict[str, Any],
        mod_tree: Dict[str, Any],
) -> Dict[str, str]:
        """
        For non-dominant duplicate keys, replace index-matched diff entries with
        only the values that are genuinely absent from the original file.

        The standard diff compares by position (prop_physics.0 vs prop_physics.0).
        That produces false "changes" when entries were reordered, and includes
        existing values when the mod file just added new ones at the end.

        This function re-computes those entries as a value-set difference so the
        patch only carries truly new values.  They are assigned indices starting
        after the last original occurrence so that 'apply' treats them as missing
        and appends them without touching what is already there.

        Dominant duplicate keys are intentionally left alone — their erase-and-
        replace semantics are handled separately during apply.
        """
        # Discover all non-dominant dup base paths that appear in the patch
        dup_bases: Dict[str, str] = {}  # base_path -> bare_key_name
        for path in patch_data:
                parts = path.split(".")
                if len(parts) >= 2 and parts[-1].isdigit():
                        bare_key = parts[-2]
                        if is_duplicate_key(bare_key) and not is_dominant_key(bare_key):
                                base = ".".join(parts[:-1])
                                dup_bases[base] = bare_key

        for base, bare_key in dup_bases.items():
                # Collect original value list for this base path
                orig_values: List[str] = []
                idx = 0
                while f"{base}.{idx}" in orig_tree:
                        orig_values.append(orig_tree[f"{base}.{idx}"])
                        idx += 1

                # Collect modified value list for this base path
                mod_values: List[str] = []
                idx = 0
                while f"{base}.{idx}" in mod_tree:
                        mod_values.append(mod_tree[f"{base}.{idx}"])
                        idx += 1

                # Values present in mod but absent from orig (by value, not index)
                orig_value_set = set(orig_values)
                new_values = [v for v in mod_values if v not in orig_value_set]

                # Remove all existing indexed entries for this base from the patch
                for p in [k for k in patch_data if k.startswith(base + ".") and k.split(".")[-1].isdigit()]:
                        del patch_data[p]

                # Re-add only the new values, indexed after the last original entry
                for i, val in enumerate(new_values):
                        patch_data[f"{base}.{len(orig_values) + i}"] = val

                Logger.debug(
                        f"Non-dominant dup '{bare_key}' at '{base}': "
                        f"{len(orig_values)} original, {len(mod_values)} modified, "
                        f"{len(new_values)} new → patch entries added"
                )

        return patch_data


def handle_create(args) -> None:
        """
        Generate a patch JSON file by comparing original and modified configs.

        Identifies all key-value pairs that differ between two files and
        saves them to a JSON patch file. Keys and values in the patch file
        are stored WITHOUT surrounding quotes.

        Non-dominant duplicate keys (e.g. load_file) include only values that
        are genuinely new compared to the original, so applying the patch appends
        them without touching existing occurrences.
        Dominant duplicate keys are expanded with indices (e.g., "prop_physics.0").
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

        # For non-dominant duplicate keys, keep only values absent from the original
        # so that applying the patch appends them instead of overwriting in place.
        patch_data = _filter_nondom_dup_to_new_only(patch_data, orig_tree, mod_tree)

        orig_comments = parse_qct_comments(args.original)
        mod_comments = parse_qct_comments(args.modified)

        comment_patch: Dict[str, str] = {}
        for path, mod_comment in mod_comments.items():
                orig_comment = orig_comments.get(path, "")
                if mod_comment != orig_comment:
                        comment_patch[path] = mod_comment

        output_destination = args.output
        if output_destination == "patch.json" or output_destination.startswith(
                "patch.json"
        ):
                output_destination = args.modified + ".kvpatch.json"

        output_patch: Dict[str, Any] = dict(patch_data)
        if comment_patch:
                output_patch["__comments__"] = comment_patch

        try:
                with open(output_destination, "w", encoding="utf-8", newline="") as f:
                        json.dump(output_patch, f, indent=4)
                        f.write(LINE_ENDING)
        except IOError as e:
                Logger.error(f"Failed to write output: {e}")
                sys.exit(2)

        total_changes = len(patch_data) + len(comment_patch)
        Logger.info(
                f"\nSuccess! Found {len(patch_data)} value change(s) and {len(comment_patch)} comment change(s)."
        )
        Logger.info(f"Patch file:\n '{output_destination}'")
        Logger.info(f"Note: Keys and values in patch are stored without quotes.")
        Logger.info(
                f"Note: Duplicate keys are expanded with indices (e.g., prop_physics.0)"
        )
        sys.exit(1 if total_changes > 0 else 0)


def _patch_duplicate_key(
        line: str,
        key: str,
        full_path: str,
        patches: Dict[str, Any],
        comment_patches: Dict[str, str],
        applied_keys: set,
        duplicate_keys_found: Dict[str, int],
        dominant_has_patches: set,
        dominant_inserted: set,
) -> Tuple[str, List[str], bool]:
        """
        Process a duplicate or dominant key line.

        For dominant keys whose base path has patch entries, builds replacement
        lines (erasing the original) and signals the caller to skip appending
        the original.  For regular duplicate keys, patches the line in-place.

        Args:
                        line:                 The raw source line (newline-normalised).
                        key:                  The bare key name (quotes stripped).
                        full_path:            Dot-path of this key in the current block.
                        patches:              Flat dot-path -> new-value mapping.
                        comment_patches:      Flat dot-path -> comment string mapping.
                        applied_keys:         Set updated in-place with patched paths.
                        duplicate_keys_found: Counter updated in-place per duplicate occurrence.
                        dominant_has_patches: Pre-computed set of dominant base paths with patch entries.
                        dominant_inserted:    Set updated in-place once a dominant base path is written.

        Returns:
                        Tuple of (modified_line, extra_lines, should_skip).
                        extra_lines  -- Replacement lines to extend into output (dominant case only).
                        should_skip  -- True when the original line must NOT be appended to output.
        """
        # ── Dominant key: erase originals, insert all patch values at first hit
        if is_dominant_key(key) and full_path in dominant_has_patches:
                extra_lines: List[str] = []
                if full_path not in dominant_inserted:
                        indent_str = line[: len(line) - len(line.lstrip())]
                        dom_idx = 0
                        while f"{full_path}.{dom_idx}" in patches:
                                ipath = f"{full_path}.{dom_idx}"
                                new_val = patches[ipath]
                                new_dom_line = (
                                        f'{indent_str}"{key}"            "{new_val}"{LINE_ENDING}'
                                )
                                if ipath in comment_patches:
                                        new_dom_line = set_inline_comment(
                                                new_dom_line, comment_patches[ipath]
                                        )
                                extra_lines.append(new_dom_line)
                                applied_keys.add(ipath)
                                Logger.debug(f"Patched (dominant, inserted): {ipath} = {new_val}")
                                dom_idx += 1
                        dominant_inserted.add(full_path)
                else:
                        Logger.debug(
                                f"Dominant key erased (already inserted at this path): {full_path}"
                        )
                return line, extra_lines, True  # skip original line

        # ── Regular duplicate key: index and patch in-place
        dup_index = duplicate_keys_found[full_path]
        indexed_path = f"{full_path}.{dup_index}"
        duplicate_keys_found[full_path] += 1

        # FIX: Non-dominant duplicates should ALWAYS be appended, never replaced in-place.
        # We skip index-based matching here and defer to the auto-append logic in handle_apply.
        if not is_dominant_key(key):
            pass
        elif indexed_path in patches:
                new_val = patches[indexed_path]
                try:
                        line = VALUE_REPLACEMENT_PATTERN.sub(
                                lambda m: f'{m.group(1)}"{new_val}"{m.group(3)}', line, count=1
                        )
                        applied_keys.add(indexed_path)
                        Logger.debug(f"Patched (duplicate): {indexed_path} = {new_val}")
                except Exception as e:
                        Logger.warning(f"Failed to patch {indexed_path}: {e}")
        else:
                if verify_flags(LogConfig.BUG_TRACKING):
                        Logger.debug(f"Indexed key not in patch: {indexed_path}")
        if indexed_path in comment_patches:
                line = set_inline_comment(line, comment_patches[indexed_path])

        return line, [], False  # append original (now patched) line


def _patch_normal_key(
        line: str,
        full_path: str,
        patches: Dict[str, Any],
        comment_patches: Dict[str, str],
        applied_keys: set,
) -> str:
        """
        Process a regular (non-duplicate) key line.

        If the key's dot-path exists in the patch, replaces its value in the
        line.  If a comment patch exists, appends or updates the inline comment.

        Args:
                        line:            The raw source line (newline-normalised).
                        full_path:       Dot-path of this key in the current block.
                        patches:         Flat dot-path -> new-value mapping.
                        comment_patches: Flat dot-path -> comment string mapping.
                        applied_keys:    Set updated in-place with patched paths.

        Returns:
                        The (potentially patched) line.
        """
        if full_path in patches:
                new_val = patches[full_path]
                try:
                        line = VALUE_REPLACEMENT_PATTERN.sub(
                                lambda m: f'{m.group(1)}"{new_val}"{m.group(3)}', line, count=1
                        )
                        applied_keys.add(full_path)
                        Logger.debug(f"Patched: {full_path} = {new_val}")
                except Exception as e:
                        Logger.warning(f"Failed to patch {full_path}: {e}")
        else:
                if verify_flags(LogConfig.BUG_TRACKING):
                        Logger.debug(f"Key not in patch: {full_path}")
        if full_path in comment_patches:
                line = set_inline_comment(line, comment_patches[full_path])
        return line


def _apply_patches_to_lines(
        lines: List[str],
        patches: Dict[str, Any],
        comment_patches: Dict[str, str],
        target_path: str,
) -> Tuple[List[str], set]:
        """
        Walk every line of a target file and apply value and comment patches.

        Handles block-structure tracking, duplicate key indexing, dominant key
        replacement (erase-all-then-insert), and inline comment updates.

        Args:
                        lines:           Raw lines from the target file.
                        patches:         Flat dot-path -> new-value dict (no __comments__).
                        comment_patches: Flat dot-path -> comment string dict.
                        target_path:     File path used only for validation error messages.

        Returns:
                        Tuple of (output_lines, applied_keys).
        """
        current_stack: List[str] = []
        output_lines: List[str] = []
        applied_keys: set = set()
        duplicate_keys_found: Dict[str, int] = defaultdict(int)
        last_block_key: Optional[str] = None

        # Pre-compute dominant key base paths that have patch entries.
        # e.g. patch key "block.prop_physics.0" -> base path "block.prop_physics"
        dominant_has_patches: set = set()
        for _patch_path in patches:
                _parts = _patch_path.split(".")
                if len(_parts) >= 2 and is_dominant_key(_parts[-2]):
                        dominant_has_patches.add(".".join(_parts[:-1]))

        dominant_inserted: set = set()  # base paths whose patch values were already written

        for line_num, line in enumerate(lines, 1):
                # Normalize line endings
                line = strip_line_ending(line) + LINE_ENDING
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
                                clean_line_for_kv = clean_and_validate_for_kv(
                                        target_path, line_num, clean_line
                                )
                        except ValidationError as e:
                                Logger.warning(f"Skipping invalid line {line_num}: {e.message}")
                                output_lines.append(line)
                                continue

                        if not clean_line_for_kv:
                                output_lines.append(line)
                                continue

                        kv_match = KV_PATTERN.match(clean_line_for_kv)
                        if kv_match:
                                key = strip_quotes(kv_match.group(1))
                                full_path = ".".join(current_stack + [key])
                                last_block_key = None

                                if is_duplicate_key(key):
                                        line, extra_lines, skip = _patch_duplicate_key(
                                                line,
                                                key,
                                                full_path,
                                                patches,
                                                comment_patches,
                                                applied_keys,
                                                duplicate_keys_found,
                                                dominant_has_patches,
                                                dominant_inserted,
                                        )
                                        if extra_lines:
                                                output_lines.extend(extra_lines)
                                        if skip:
                                                continue
                                else:
                                        line = _patch_normal_key(
                                                line, full_path, patches, comment_patches, applied_keys
                                        )

                output_lines.append(line)

        # Auto-close any blocks the file ended without closing.
        # Each missing NESTING_CLOSE is inserted at the correct indentation depth,
        # working from the innermost unclosed block outward to the root.
        if current_stack:
                Logger.warning(
                        f"File ended with {len(current_stack)} unclosed block(s): "
                        + " > ".join(current_stack)
                )
                Logger.warning(
                        "Auto-inserting missing closing markers to restore nesting sanity."
                )
                while current_stack:
                        depth = len(current_stack) - 1  # 0-based: root block closes at col 0
                        output_lines.append(f"{'        ' * depth}{NESTING_CLOSE}{LINE_ENDING}")
                        Logger.debug(f"Auto-closed block: {'.'.join(current_stack)}")
                        current_stack.pop()

        return output_lines, applied_keys

def show_missing(missing_keys) -> None:
        print(f"\nMissing items ({len(missing_keys)}):")
        for key in sorted(missing_keys):
                print(f"  - {key}")


def handle_apply(args) -> None:
        """
        Apply a patch JSON file onto a target config file.

        Reads the patch and target, delegates line-by-line processing to
        _apply_patches_to_lines, then handles the summary, missing-key
        injection, prettification, and final write.

        The patch file contains unquoted keys/values applied with proper
        quotes to the target file.

        For duplicate keys: new values are APPENDED after existing ones.
        For dominant multi-keys: ALL originals are erased and replaced
        exclusively by the patch values.
        """
        if not os.path.exists(args.target):
                Logger.error(f"Target file not found: {args.target}")
                sys.exit(2)
        if not os.path.exists(args.patch):
                Logger.error(f"Patch file not found: {args.patch}")
                sys.exit(2)

        try:
                with open(args.patch, "r", encoding="utf-8") as f:
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
                with open(args.target, "r", encoding="utf-8", errors="ignore", newline="") as f:
                        lines = f.readlines()
        except IOError as e:
                Logger.error(f"Failed to read target file: {e}")
                sys.exit(2)

        Logger.info(f"Applying patches from '{args.patch}' onto '{args.target}'...")
        Logger.info(
                f"Duplicate keys to append (not overwrite): {', '.join(DUPLICATE_KEYS)}"
        )
        if DOMINANT_MULTI_KEYS:
                Logger.info(
                        f"Dominant multi-keys (erase originals, insert patch values): {', '.join(DOMINANT_MULTI_KEYS)}"
                )

        if verify_flags(LogConfig.DEBUG):
                Logger.debug(f"Patches to apply: {patches}")

        output_lines, applied_keys = _apply_patches_to_lines(
                lines, patches, comment_patches, args.target
        )

        requested_keys = set(patches.keys())
        missing_keys = requested_keys - applied_keys

        # Identify non-dominant duplicate keys that weren't matched in-place.
        # These use indices in the patch (e.g., ".30") but should always be appended.
        auto_append_dups = {
            k for k in missing_keys
            if len(k.split(".")) >= 2
            and k.split(".")[-1].isdigit()
            and k.split(".")[-2] in DUPLICATE_KEYS
            and k.split(".")[-2] not in DOMINANT_MULTI_KEYS
        }

        # Print summary
        print("\n" + "=" * 60)
        print("PATCH EXECUTION SUMMARY")
        print("=" * 60)
        print(f"Total requested updates: {len(requested_keys):3d}")
        print(f"Successfully modified:   {len(applied_keys):3d}")
        print(f"Missing items:     {len(missing_keys):3d}")
        print("=" * 60)

        if len(applied_keys) == 0:
                Logger.warning("No items were successfully patched!")
                Logger.warning("This may indicate:")
                Logger.warning("  - Target file structure differs from expected")
                Logger.warning("  - Syntax issues in target file")
                Logger.warning("  - Incompatible patch file")

        # Prepare combined missing patches
        auto_append_dict = {k: patches[k] for k in auto_append_dups}
        remaining_missing = missing_keys - auto_append_dups
        append_remaining = remaining_missing and args.append_missing

        if auto_append_dict or append_remaining:
                combined_patches = dict(auto_append_dict)
                if append_remaining:
                        combined_patches.update({k: patches[k] for k in remaining_missing})

                Logger.info(f"Injecting missing options ({len(auto_append_dict)} duplicate, {len(remaining_missing)} structural)...")
                try:
                        output_lines = append_nested_missing(output_lines, combined_patches)
                        applied_keys.update(combined_patches.keys())
                        Logger.info(f"Successfully appended {len(combined_patches)} missing option(s).")
                except Exception as e:
                        Logger.error(f"Failed to append missing options: {e}")
                        sys.exit(2)
        elif missing_keys:
                if verify_flags(LogConfig.SHOW_MISSING):
                        show_missing(missing_keys)
                Logger.error("Operation aborted. Use --append-missing to inject missing keys.")
                sys.exit(2)

        # Apply prettification if requested
        if args.prettify:
                Logger.info("Prettifying output formatting...")
                output_lines = prettify_output(output_lines)
                Logger.info("Output prettified with correct indentation.")

        output_destination = args.output if args.output else args.target
        try:
                with open(output_destination, "w", encoding="utf-8", newline="") as f:
                        f.writelines(output_lines)
        except IOError as e:
                Logger.error(f"Failed to write output file: {e}")
                sys.exit(2)

        Logger.info(f"\nPatching complete. Output: {output_destination}")


# ==========================================
# MAIN INTERFACE & SUBCOMMAND ROUTING
# ==========================================

if __name__ == "__main__":
        # do_all_self_sanity_checks()
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
  - Dominant multi-keys (KEYVALUE_DOMINANT_MULTI_KEYS) erase all originals and
        replace them exclusively with the patch values
  - Use --prettify to fix indentation to match nesting depth
  - Set KEYVALUE_DUPLICATE_KEYS env var to customize: "key1,key2,key3"
                                """,
                formatter_class=argparse.RawDescriptionHelpFormatter,
        )
        subparsers = parser.add_subparsers(
                dest="command", required=True, help="Subcommands"
        )

        # 'create' subcommand
        parser_create = subparsers.add_parser(
                "create", help="Generate a JSON patch by comparing two .qct files"
        )
        parser_create.add_argument("original", help="Path to original/vanilla .qct file")
        parser_create.add_argument("modified", help="Path to your modified .qct file")
        parser_create.add_argument(
                "-o",
                "--output",
                default="patch.json",
                help="Output patch JSON file (default: <modified>.kvpatch.json)",
        )
        parser_create.set_defaults(func=handle_create)

        # 'apply' subcommand
        parser_apply = subparsers.add_parser(
                "apply", help="Apply a JSON patch to a .qct file"
        )
        parser_apply.add_argument("target", help="The .qct file to modify")
        parser_apply.add_argument("patch", help="The .kvpatch.json patch file to apply")
        parser_apply.add_argument(
                "-o", "--output", help="Output file (default: overwrite target)"
        )
        parser_apply.add_argument(
                "-a",
                "--append-missing",
                action="store_true",
                help="Inject missing keys instead of failing",
        )
        parser_apply.add_argument(
                "-p",
                "--prettify",
                action="store_true",
                help="Prettify output by fixing indentation to match nesting depth",
        )
        parser_apply.set_defaults(func=handle_apply)

        # 'selftests' subcommand
        parser_selftests = subparsers.add_parser(
                "selftests", help="Sanity check (Self tests)"
        )
        parser_selftests.set_defaults(func=handle_selftests)

        args = parser.parse_args()
        args.func(args)
