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

//AI GENERATED:

// Compile with: g++ -O3 launch_universal.cpp -o launch_universal -lX11 -lstdc++fs
#include <iostream>
#include <string_view>
#include <vector>
#include <cstdio>
#include <cstdlib>
#include <fstream>
#include <filesystem>
#include <algorithm>
#include <unistd.h>
#include <signal.h>
#include <sys/types.h>
#include <X11/Xlib.h>
#include <X11/Xatom.h>
#include <X11/Xutil.h>

namespace fs = std::filesystem;

enum class LookupMode {
    PID_BASED, // Default: ultra fast, works for 95% of modern apps
    UTF8_NAME, // Manual override via --utf8
    LEGACY_NAME // Manual override via --legacy
};

// Pure C++ function to search /proc for matching commands (excluding our own PID)
bool is_process_running(const std::string& cmd_keyword) {
    pid_t my_pid = getpid();
    for (const auto& entry : fs::directory_iterator("/proc")) {
        if (!entry.is_directory()) continue;
        std::string filename = entry.path().filename().string();
        if (!std::all_of(filename.begin(), filename.end(), ::isdigit)) continue;

        pid_t pid = std::stoi(filename);
        if (pid == my_pid) continue;

        std::ifstream cmd_file(entry.path() / "cmdline", std::ios::binary);
        if (!cmd_file) continue;

        std::string cmdline((std::istreambuf_iterator<char>(cmd_file)),
                             std::istreambuf_iterator<char>());
        std::replace(cmdline.begin(), cmdline.end(), '\0', ' ');

        if (cmdline.find(cmd_keyword) != std::string::npos) {
            return true;
        }
    }
    return false;
}

// Helper to look up a window's PID property (_NET_WM_PID)
unsigned long get_window_pid(Display* display, Window win, Atom pid_atom) {
    Atom actual_type;
    int actual_format;
    unsigned long num_items = 0;
    unsigned long bytes_after;
    unsigned char* data = nullptr;
    unsigned long win_pid = 0;

    if (XGetWindowProperty(display, win, pid_atom, 0, 1, False,
                           XA_CARDINAL, &actual_type, &actual_format,
                           &num_items, &bytes_after, &data) == Success && data) {
        if (num_items > 0) {
            win_pid = *reinterpret_cast<unsigned long*>(data);
        }
        XFree(data);
    }
    return win_pid;
}

// Universal window query function
Window find_window(Display* display, Atom client_list_atom, LookupMode mode, pid_t target_pid, const std::string& target_string) {
    Window root = DefaultRootWindow(display);
    Atom actual_type;
    int actual_format;
    unsigned long num_windows = 0;
    unsigned long bytes_after;
    unsigned char* data = nullptr;

    if (XGetWindowProperty(display, root, client_list_atom, 0, 1024, False,
                           XA_WINDOW, &actual_type, &actual_format,
                           &num_windows, &bytes_after, &data) != Success || !data) {
        return 0;
    }

    Window* windows = reinterpret_cast<Window*>(data);
    Window found_window = 0;

    // Cache Atoms depending on user flag choice to protect frame timings
    Atom pid_atom = (mode == LookupMode::PID_BASED) ? XInternAtom(display, "_NET_WM_PID", False) : 0;
    Atom name_atom = 0;
    if (mode == LookupMode::UTF8_NAME) name_atom = XInternAtom(display, "_NET_WM_NAME", False);
    else if (mode == LookupMode::LEGACY_NAME) name_atom = XA_WM_NAME;

    for (unsigned long i = 0; i < num_windows; ++i) {
        if (mode == LookupMode::PID_BASED) {
            if (get_window_pid(display, windows[i], pid_atom) == (unsigned long)target_pid) {
                found_window = windows[i];
                break;
            }
        } else {
            // String properties lookup matching your ultra fast design
            unsigned char* name_data = nullptr;
            unsigned long name_len = 0;
            Atom requested_type = (mode == LookupMode::UTF8_NAME) ? XInternAtom(display, "UTF8_STRING", False) : AnyPropertyType;

            if (XGetWindowProperty(display, windows[i], name_atom, 0, 1024, False,
                                   requested_type, &actual_type, &actual_format,
                                   &name_len, &bytes_after, &name_data) == Success && name_data) {
                
                std::string_view current_title(reinterpret_cast<char*>(name_data), name_len);
                if (current_title == target_string) {
                    found_window = windows[i];
                    XFree(name_data);
                    break;
                }
                XFree(name_data);
            }
        }
    }

    XFree(data);
    return found_window;
}

// Clean native minimization
void minimize_window(Display* display, Window win) {
    Window root = DefaultRootWindow(display);
    Atom wm_change_state = XInternAtom(display, "WM_CHANGE_STATE", False);
    
    XEvent xev;
    xev.type = ClientMessage;
    xev.xclient.window = win;
    xev.xclient.message_type = wm_change_state;
    xev.xclient.format = 32;
    xev.xclient.data.l[0] = IconicState; // Fixed: Target the first index of the long array

    XSendEvent(display, root, False, SubstructureRedirectMask | SubstructureNotifyMask, &xev);
    XFlush(display);
}

int main(int argc, char* argv[]) {
    if (argc < 2) {
        std::fprintf(stderr, "Usage: %s [--utf8 name | --legacy name] <command> [args...]\n", argv[0]);
        return 1;
    }

    LookupMode mode = LookupMode::PID_BASED;
    std::string search_string = "";
    int command_start_index = 1;

    // Parse configuration flags
    std::string_view first_arg(argv[1]);
    if (first_arg == "--utf8" || first_arg == "--legacy") {
        if (argc < 4) {
            std::fprintf(stderr, "Error: Missing window name argument for mode selector.\n");
            return 1;
        }
        mode = (first_arg == "--utf8") ? LookupMode::UTF8_NAME : LookupMode::LEGACY_NAME;
        search_string = argv[2];
        command_start_index = 3;
    }

    // Safety guard checking if target binary execution phrase is running
    //std::string binary_name = argv[command_start_index];
    //if (is_process_running(binary_name)) {
        //std::fprintf(stderr, "[ERROR] App '%s' is already running.\n", binary_name.c_str());
        //return 1;
    //}

    Display* display = XOpenDisplay(nullptr);
    if (!display) return 1;
    Atom client_list_atom = XInternAtom(display, "_NET_CLIENT_LIST", False);

    // Fork and execute anything natively
    pid_t pid = fork();
    if (pid < 0) {
        std::perror("Fork failed");
        XCloseDisplay(display);
        return 1;
    }

    if (pid == 0) {
        // Child: Assemble dynamically passed user binary configurations
        std::vector<char*> exec_args;
        for (int i = command_start_index; i < argc; ++i) {
            exec_args.push_back(argv[i]);
        }
        exec_args.push_back(nullptr);

        FILE* out = std::freopen("/dev/null", "w", stdout);
        FILE* err = std::freopen("/dev/null", "w", stderr);
        (void)out; (void)err;

        execvp(exec_args[0], exec_args.data());
        std::perror("execvp failed");
        return 1;
    }

    // Parent control loop
    Window target_win = 0;
    std::printf("[INFO] Tracking execution (PID: %d)... \n", pid);

    while (true) {
        kill(pid, SIGSTOP); // Instantly trap app initialization sequence

        target_win = find_window(display, client_list_atom, mode, pid, search_string);

        if (target_win != 0) {
            std::printf("[INFO] Window 0x%08lx captured! Minimizing...\n", target_win);
            minimize_window(display, target_win);
            kill(pid, SIGCONT);
            break;
        }

        kill(pid, SIGCONT);
        usleep(100);
    }

    XCloseDisplay(display);
    return 0;
}
