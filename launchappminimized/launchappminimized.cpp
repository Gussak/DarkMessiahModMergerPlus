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

// This was AI GENERATED.
// What it does? Basically, tries to detect the window creation before it has a chance to be shown, and minimize it.

// Compile with: g++ -O3 launchappminimized.cpp -o launchappminimized -lX11

#include <iostream>
#include <vector>
#include <cstdio>
#include <cstdlib>
#include <string_view>
#include <chrono>
#include <unistd.h>
#include <signal.h>
#include <sys/types.h>
#include <X11/Xlib.h>
#include <X11/Xatom.h>
#include <X11/Xutil.h>

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

// Smart Lookup: Tries PID first, falls back to an exact custom Window Role match
Window find_window_universal(Display* display, Atom client_list_atom, Atom pid_atom, pid_t target_pid, const std::string& target_role) {
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
    Atom wm_role_atom = XInternAtom(display, "WM_WINDOW_ROLE", False);

    for (unsigned long i = 0; i < num_windows; ++i) {
        // Strategy 1: Try lightning-fast PID lookup first
        if (get_window_pid(display, windows[i], pid_atom) == (unsigned long)target_pid) {
            found_window = windows[i];
            break;
        }

        // Strategy 2: Fallback to verification via our unique injected role string
        unsigned char* role_data = nullptr;
        unsigned long role_len = 0;

        if (XGetWindowProperty(display, windows[i], wm_role_atom, 0, 1024, False,
                               XA_STRING, &actual_type, &actual_format,
                               &role_len, &bytes_after, &role_data) == Success && role_data) {
            
            std::string_view current_role(reinterpret_cast<char*>(role_data), role_len);
            if (current_role == target_role) {
                found_window = windows[i];
                XFree(role_data);
                break;
            }
            XFree(role_data);
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
    xev.xclient.data.l[0] = IconicState;
    XSendEvent(display, root, False, SubstructureRedirectMask | SubstructureNotifyMask, &xev);
    XFlush(display);
}

// Handle asynchronous X11 communication drops gracefully
int handle_x11_errors(Display*, XErrorEvent* error) {
    if (error->error_code == BadWindow || error->error_code == BadDrawable) {
        return 0; 
    }
    return 0;
}

int main(int argc, char* argv[]) {
    if (argc < 2) {
        std::fprintf(stderr, "Usage: %s <command> [args...]\n", argv[0]);
        return 1;
    }

    // Isolate executable name
    std::string app_name = argv[1];
    size_t last_slash = app_name.find_last_of("/");
    if (last_slash != std::string::npos) {
        app_name = app_name.substr(last_slash + 1);
    }

    // Generate a unique window role string using a microsecond timestamp string
    auto now = std::chrono::high_resolution_clock::now().time_since_epoch();
    unsigned long microseconds = std::chrono::duration_cast<std::chrono::microseconds>(now).count();
    std::string unique_role = "launch_minimized_" + std::to_string(microseconds);

    Display* display = XOpenDisplay(nullptr);
    if (!display) return 1;
    
    XSetErrorHandler(handle_x11_errors);
    
    Atom client_list_atom = XInternAtom(display, "_NET_CLIENT_LIST", False);
    Atom pid_atom = XInternAtom(display, "_NET_WM_PID", False);

    pid_t pid = fork();
    if (pid < 0) {
        std::perror("Fork failed");
        XCloseDisplay(display);
        return 1;
    }

    if (pid == 0) {
        // Child: Build argument array configurations dynamically
        std::vector<char*> exec_args;
        exec_args.push_back(argv[1]);

        // Auto-inject unique window roles specifically targeting multi-instance server managers
        std::string role_flag = "--role=" + unique_role;
        bool is_gnome_terminal = (app_name == "gnome-terminal");
        
        if (is_gnome_terminal) {
            exec_args.push_back(const_cast<char*>(role_flag.c_str()));
        }

        for (int i = 2; i < argc; ++i) {
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

    Window target_win = 0;
    std::printf("[INFO] Tracking execution (PID: %d)...\n", pid);

    while (true) {
        kill(pid, SIGSTOP); // Freeze process execution sequences

        // Check using fast PID matching or fallback to exact injected unique window role fingerprinting
        target_win = find_window_universal(display, client_list_atom, pid_atom, pid, unique_role);

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
