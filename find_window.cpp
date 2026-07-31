//	BSD 3-Clause License
//
//	Copyright (c) 2026, Gussak<https://github.com/Gussak>
//
//	Redistribution and use in source and binary forms, with or without
//	modification, are permitted provided that the following conditions are met:
//
//	1. Redistributions of source code must retain the above copyright notice, this
//		 list of conditions and the following disclaimer.
//
//	2. Redistributions in binary form must reproduce the above copyright notice,
//		 this list of conditions and the following disclaimer in the documentation
//		 and/or other materials provided with the distribution.
//
//	3. Neither the name of the copyright holder nor the names of its
//		 contributors may be used to endorse or promote products derived from
//		 this software without specific prior written permission.
//
//	THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
//	AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
//	IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
//	DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
//	FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
//	DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
//	SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
//	CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
//	OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
//	OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

//AI GENERATED: faster than wmctrl and xdotool to search a window by name

// Compile with: g++ -O3 find_window.cpp -o find_window -lX11
#include <iostream>
#include <string_view>
#include <cstdio>
#include <cstring>
#include <X11/Xlib.h>
#include <X11/Xatom.h>

enum class SearchMode {
    BOTH,
    NEW_ONLY,
    OLD_ONLY
};

int main(int argc, char* argv[]) {
    SearchMode mode = SearchMode::BOTH;
    std::string_view target_title = "DMMM_Helpers"; // Default fallback

    // Parse options and identify the target title
    for (int i = 1; i < argc; ++i) {
        std::string_view arg(argv[i]);
        if (arg == "--newonly") {
            mode = SearchMode::NEW_ONLY;
        } else if (arg == "--oldonly") {
            mode = SearchMode::OLD_ONLY;
        } else if (arg == "--both") {
            mode = SearchMode::BOTH;
        } else {
            // If it doesn't match a flag, treat it as the target window name
            target_title = arg;
        }
    }

    // 1. Establish connection to the X Server
    Display* display = XOpenDisplay(nullptr);
    if (!display) return 1;

    Window root = DefaultRootWindow(display);
    Atom client_list_atom = XInternAtom(display, "_NET_CLIENT_LIST", False);
    Atom net_wm_name_atom = XInternAtom(display, "_NET_WM_NAME", False);
    Atom utf8_string_atom = XInternAtom(display, "UTF8_STRING", False);

    Atom actual_type;
    int actual_format;
    unsigned long num_windows = 0;
    unsigned long bytes_after;
    unsigned char* data = nullptr;

    // 2. Fetch all Window IDs in one batch call
    if (XGetWindowProperty(display, root, client_list_atom, 0, 1024, False,
                           XA_WINDOW, &actual_type, &actual_format,
                           &num_windows, &bytes_after, &data) != Success || !data) {
        XCloseDisplay(display);
        return 1;
    }

    Window* windows = reinterpret_cast<Window*>(data);
    bool found = false;

    // 3. Scan the windows array inside local memory
    for (unsigned long i = 0; i < num_windows; ++i) {
        unsigned char* name_data = nullptr;
        unsigned long name_len = 0;

        // Strategy A: Modern UTF-8 Window Name (_NET_WM_NAME)
        if (mode == SearchMode::BOTH || mode == SearchMode::NEW_ONLY) {
            if (XGetWindowProperty(display, windows[i], net_wm_name_atom, 0, 1024, False,
                                   utf8_string_atom, &actual_type, &actual_format,
                                   &name_len, &bytes_after, &name_data) == Success && name_data) {
                
                std::string_view current_title(reinterpret_cast<char*>(name_data), name_len);
                if (current_title == target_title) {
                    std::printf("0x%08lx\n", windows[i]);
                    XFree(name_data);
                    found = true;
                    break;
                }
                XFree(name_data);
            }
        }

        // Strategy B: Legacy XA_WM_NAME (Used by xterm, older apps)
        if (!found && (mode == SearchMode::BOTH || mode == SearchMode::OLD_ONLY)) {
            if (XGetWindowProperty(display, windows[i], XA_WM_NAME, 0, 1024, False,
                                   AnyPropertyType, &actual_type, &actual_format,
                                   &name_len, &bytes_after, &name_data) == Success && name_data) {
                
                std::string_view current_title(reinterpret_cast<char*>(name_data), name_len);
                if (current_title == target_title) {
                    std::printf("0x%08lx\n", windows[i]);
                    XFree(name_data);
                    found = true;
                    break;
                }
                XFree(name_data);
            }
        }
    }

    XFree(data);
    XCloseDisplay(display);
    return found ? 0 : 1;
}
