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

// Compile with: g++ -O3 launch_hidden.cpp -o launch_hidden -lX11 -lstdc++fs
#include <iostream>
#include <string_view>
#include <vector>
#include <cstdio>
#include <cstdlib>
#include <fstream>
#include <filesystem>
#include <algorithm> // Fixed: Required for std::all_of and std::replace
#include <unistd.h>
#include <signal.h>
#include <sys/types.h>
#include <X11/Xlib.h>
#include <X11/Xatom.h>
#include <X11/Xutil.h>

namespace fs = std::filesystem;

// Pure C++ function to search /proc for matching titles (excluding our own PID)
bool is_process_running(const std::string& title) {
    pid_t my_pid = getpid();

    for (const auto& entry : fs::directory_iterator("/proc")) {
        if (!entry.is_directory()) continue;

        std::string filename = entry.path().filename().string();
        // Check if folder name is a valid PID (all numbers)
        if (!std::all_of(filename.begin(), filename.end(), ::isdigit)) continue;

        pid_t pid = std::stoi(filename);
        if (pid == my_pid) continue; // Skip ourselves

        // Read the command line string for this PID
        std::ifstream cmd_file(entry.path() / "cmdline", std::ios::binary);
        if (!cmd_file) continue;

        std::string cmdline((std::istreambuf_iterator<char>(cmd_file)),
                             std::istreambuf_iterator<char>());

        // Linux kernels separate arguments with null bytes '\0'. 
        // We replace them with spaces to perform a clean substring match.
        std::replace(cmdline.begin(), cmdline.end(), '\0', ' ');

        if (cmdline.find(title) != std::string::npos) {
            return true;
        }
    }
    return false;
}

// Pure C++ function to send SIGKILL to matching processes (excluding our own PID)
void kill_old_instances(const std::string& title) {
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

        if (cmdline.find(title) != std::string::npos) {
            kill(pid, SIGKILL); // Natively terminate the matching process
        }
    }
}

// Core function to query X11 for our target window ID
Window find_window_id(Display* display, Atom client_list_atom, const std::string& target_title) {
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

    for (unsigned long i = 0; i < num_windows; ++i) {
        unsigned char* name_data = nullptr;
        unsigned long name_len = 0;

        if (XGetWindowProperty(display, windows[i], XA_WM_NAME, 0, 1024, False,
                               AnyPropertyType, &actual_type, &actual_format,
                               &name_len, &bytes_after, &name_data) == Success && name_data) {
            
            std::string_view current_title(reinterpret_cast<char*>(name_data), name_len);
            if (current_title == target_title) {
                found_window = windows[i];
                XFree(name_data);
                break;
            }
            XFree(name_data);
        }
    }

    XFree(data);
    return found_window;
}

// Sends an XClientMessageEvent to minimize the window cleanly
void minimize_window(Display* display, Window win) {
    Window root = DefaultRootWindow(display);
    Atom wm_change_state = XInternAtom(display, "WM_CHANGE_STATE", False);
    
    XEvent xev;
    xev.type = ClientMessage;
    xev.xclient.window = win;
    xev.xclient.message_type = wm_change_state;
    xev.xclient.format = 32;
    xev.xclient.data.l[0] = IconicState; 

    XSendEvent(display, root, False, SubstructureRedirectMask | SubstructureNotifyMask, &xev);
    XFlush(display);
}

int main(int argc, char* argv[]) {
    if (argc < 2) {
        std::fprintf(stderr, "Usage: %s <window_title> [xterm_arguments...]\n", argv[0]);
        return 1;
    }

    std::string target_title = argv[1];

    // 1. Initial process safety guards running purely in native C++
    if (is_process_running(target_title)) {
        std::fprintf(stderr, "[ERROR] strTitle='%s' must be unique but it is already running...\n", target_title.c_str());
        return 1;
    }

    kill_old_instances(target_title);

    // 2. Setup X11 parameters before branching
    Display* display = XOpenDisplay(nullptr);
    if (!display) return 1;
    Atom client_list_atom = XInternAtom(display, "_NET_CLIENT_LIST", False);

    // 3. Fork to execute the new xterm instance natively
    pid_t pid = fork();

    if (pid < 0) {
        std::perror("Fork failed");
        XCloseDisplay(display);
        return 1;
    }

    if (pid == 0) {
        // Child Process: Build xterm execution arguments array
        std::vector<char*> exec_args;
        exec_args.push_back(const_cast<char*>("xterm"));
        exec_args.push_back(const_cast<char*>("-title"));
        exec_args.push_back(const_cast<char*>(target_title.c_str()));

        for (int i = 2; i < argc; ++i) {
            exec_args.push_back(argv[i]);
        }
        exec_args.push_back(nullptr);

        FILE* out = std::freopen("/dev/null", "w", stdout);
        FILE* err = std::freopen("/dev/null", "w", stderr);
        (void)out; (void)err;

        execvp("xterm", exec_args.data());
        
        std::perror("execvp failed");
        return 1;
    }

    // Parent Process: The Hyper-Fast Control Loop
    Window target_win = 0;
    std::printf("[INFO] Spawning xterm (PID: %d), capturing window...\n", pid);

    while (true) {
        kill(pid, SIGSTOP);

        target_win = find_window_id(display, client_list_atom, target_title);

        if (target_win != 0) {
            std::printf("[INFO] Window 0x%08lx is ready. Minimizing...\n", target_win);
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
