# Usage:
# make #you only need this tho
# sudo make install
# make clean

# Compiler configuration
CXX      = g++
CXXFLAGS = -O3 -Wall -Wextra -std=c++17

# Libraries and targets
LIBS     = -lX11
TARGET   = launchappminimized
SRC      = launchappminimized.cpp

# Default rule: builds the executable
all: $(TARGET)

$(TARGET): $(SRC)
	$(CXX) $(CXXFLAGS) $(SRC) -o $(TARGET) $(LIBS)

# Install rule: places the binary in a standard system execution directory
install: $(TARGET)
	install -m 755 $(TARGET) /usr/local/bin/

# Clean rule: deletes the generated binary
clean:
	rm -f $(TARGET)

.PHONY: all install clean

