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

// Smart Lookup: Tries PID first, falls back to Class Name matching for apps like gnome-terminal
Window find_window_universal(Display* display, Atom client_list_atom, Atom pid_atom, pid_t target_pid, const std::string& fallback_class) {
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

		// Target lookup code snippet
		XClassHint chint;
		XWMHints* wmhints;
		Atom wm_role_atom = XInternAtom(display, "WM_WINDOW_ROLE", False);

		// Loop through your open X11 windows array...
		for (unsigned long i = 0; i < num_windows; ++i) {
				// 1. Try your lightning-fast PID lookup method first
				if (get_window_pid(display, windows[i], pid_atom) == (unsigned long)target_pid) {
						found_window = windows[i];
						break;
				}

				// 2. Fallback: Check for your custom unique window role property string
				unsigned char* role_data = nullptr;
				unsigned long role_len = 0;
				Atom actual_type;
				int actual_format;
				unsigned long bytes_after;

				if (XGetWindowProperty(display, windows[i], wm_role_atom, 0, 1024, False,
															 XA_STRING, &actual_type, &actual_format,
															 &role_len, &bytes_after, &role_data) == Success && role_data) {
						
						std::string_view current_role(reinterpret_cast<char*>(role_data), role_len);
						if (current_role == custom_unique_role_string) {
								found_window = windows[i];
								XFree(role_data);
								break;
						}
						XFree(role_data);
				}
		}

    //for (unsigned long i = 0; i < num_windows; ++i) {
        //// Strategy 1: Fast PID lookup
        //if (get_window_pid(display, windows[i], pid_atom) == (unsigned long)target_pid) {
            //found_window = windows[i];
            //break;
        //}

        //// Strategy 2: Fallback Class Name parsing for DBus / Client-Server applications
        //XClassHint chint;
        //if (XGetClassInstanceHint(display, windows[i], &chint) != 0) {
            //std::string_view res_class(chint.res_class ? chint.res_class : "");
            //std::string_view res_name(chint.res_name ? chint.res_name : "");

            //// If the window class contains "gnome-terminal" or matches our executable name
            //if (res_class.find(fallback_class) != std::string_view::npos || 
                //res_name.find(fallback_class) != std::string_view::npos) {
                //found_window = windows[i];
                //if (chint.res_name) XFree(chint.res_name);
                //if (chint.res_class) XFree(chint.res_class);
                //break;
            //}

            //if (chint.res_name) XFree(chint.res_name);
            //if (chint.res_class) XFree(chint.res_class);
        //}
    //}

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
        return 0; // Ignore missing or closed temporary windows quietly
    }
    return 0;
}

int main(int argc, char* argv[]) {
    if (argc < 2) {
        std::fprintf(stderr, "Usage: %s <command> [args...]\n", argv[0]);
        return 1;
    }

    // Save the executable name string (e.g. "gnome-terminal") to use as fallback criteria
    std::string app_name = argv[1];
    size_t last_slash = app_name.find_last_of("/");
    if (last_slash != std::string::npos) {
        app_name = app_name.substr(last_slash + 1);
    }

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

    Window target_win = 0;
    std::printf("[INFO] Tracking execution (PID: %d)...\n", pid);

    while (true) {
        // Freeze process to trap initialization steps
        kill(pid, SIGSTOP);

        // Run lookup passing both PID and string fallback details
        target_win = find_window_universal(display, client_list_atom, pid_atom, pid, app_name);

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
