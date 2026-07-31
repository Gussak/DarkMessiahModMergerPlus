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

// Scans X11 windows strictly matching the target Process ID
Window find_window_by_pid(Display* display, Atom client_list_atom, Atom pid_atom, pid_t target_pid) {
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
        if (get_window_pid(display, windows[i], pid_atom) == (unsigned long)target_pid) {
            found_window = windows[i];
            break;
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

int main(int argc, char* argv[]) {
    if (argc < 2) {
        std::fprintf(stderr, "Usage: %s <command> [args...]\n", argv[0]);
        return 1;
    }

    // Open connection to X Server immediately to cache Atoms
    Display* display = XOpenDisplay(nullptr);
    if (!display) return 1;
    
    Atom client_list_atom = XInternAtom(display, "_NET_CLIENT_LIST", False);
    Atom pid_atom = XInternAtom(display, "_NET_WM_PID", False);

    // Fork and execute natively
    pid_t pid = fork();
    if (pid < 0) {
        std::perror("Fork failed");
        XCloseDisplay(display);
        return 1;
    }

    if (pid == 0) {
        // Child: Assemble dynamically passed user binary configurations
        std::vector<char*> exec_args;
        for (int i = 1; i < argc; ++i) {
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
    std::printf("[INFO] Tracking execution (PID: %d)...\n", pid);

    while (true) {
        kill(pid, SIGSTOP); // Instantly trap app initialization sequence

        target_win = find_window_by_pid(display, client_list_atom, pid_atom, pid);

        if (target_win != 0) {
            std::printf("[INFO] Window 0x%08lx captured! Minimizing...\n", target_win);
            minimize_window(display, target_win);
            kill(pid, SIGCONT);
            break;
        }

        kill(pid, SIGCONT);
        usleep(100); //this is microseconds, dont lower it to not mess X
    }

    XCloseDisplay(display);
    return 0;
}
