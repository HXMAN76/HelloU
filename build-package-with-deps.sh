#!/bin/bash
# Simplified package build script with dependency checks

set -e

PACKAGE_NAME="hellou-fixed"
VERSION="1.0.0"
OUTPUT_DIR="/home/hxman/Projects/face-recog"
BUILD_DIR="$OUTPUT_DIR/$PACKAGE_NAME-$VERSION-final"

# Create a fresh build directory
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

# Create directory structure
mkdir -p "$BUILD_DIR/DEBIAN"
mkdir -p "$BUILD_DIR/etc/hellou"
mkdir -p "$BUILD_DIR/lib/systemd/system"
mkdir -p "$BUILD_DIR/usr/bin"
mkdir -p "$BUILD_DIR/usr/lib/python3/dist-packages/hellou/modules"
mkdir -p "$BUILD_DIR/usr/share/doc/$PACKAGE_NAME"
mkdir -p "$BUILD_DIR/usr/share/man/man1"
mkdir -p "$BUILD_DIR/var/lib/hellou/users"

# Create control file
cat << EOF > "$BUILD_DIR/DEBIAN/control"
Package: $PACKAGE_NAME
Version: $VERSION
Section: admin
Priority: optional
Architecture: amd64
Pre-Depends: python3 (>= 3.8)
Depends: libpam-python, libpam-dev, adduser, python3-dev, python3-pip, python3-opencv, python3-numpy, python3-dlib, python3-pillow, python3-click
Recommends: v4l-utils, ir-camera-utils
Suggests: libcanberra-gtk-module
Installed-Size: 512
Maintainer: Hari Heman <hariheman76@gmail.com>
Homepage: https://github.com/HXMAN76/hellou
Description: Face recognition authentication system for Linux
 HelloU is a modern face unlock system for Linux that enables face-based
 authentication for sudo, login, screen unlock, and other PAM-secured
 operations.
EOF

# Create conffiles
cat << EOF > "$BUILD_DIR/DEBIAN/conffiles"
/etc/hellou/hellou.conf
/etc/hellou/hellou-completion.bash
EOF

# Create preinst script to check dependencies
cat << EOF > "$BUILD_DIR/DEBIAN/preinst"
#!/bin/bash
set -e

echo "Checking system dependencies for HelloU..."

# Check for required packages
MISSING_PKGS=""
for pkg in python3 python3-pip python3-dev libpam-python libpam-dev python3-opencv python3-numpy; do
  if ! dpkg -s \$pkg >/dev/null 2>&1; then
    MISSING_PKGS="\$MISSING_PKGS \$pkg"
  fi
done

if [ -n "\$MISSING_PKGS" ]; then
  echo "The following required packages are missing:\$MISSING_PKGS"
  echo "Please install them with: sudo apt install\$MISSING_PKGS"
  exit 1
fi

# Check for Python modules
for module in numpy cv2 PIL; do
  if ! python3 -c "import \$module" >/dev/null 2>&1; then
    echo "Required Python module '\$module' is not installed."
    echo "Please install missing Python dependencies with: sudo pip3 install -r /usr/share/doc/hellou-fixed/requirements.txt"
    exit 1
  fi
done

# Check camera access
if [ ! -e /dev/video0 ]; then
  echo "Warning: No camera device found at /dev/video0"
  echo "HelloU requires a camera to function properly."
  echo "Installation will continue, but you should make sure a camera is connected."
fi

echo "Dependency check passed. Continuing with installation..."
EOF
chmod 755 "$BUILD_DIR/DEBIAN/preinst"

# Create sample config file
cat << EOF > "$BUILD_DIR/etc/hellou/hellou.conf"
[General]
# HelloU configuration file
camera_device = /dev/video0
tolerance = 0.6
debug = False

[Security]
enable_liveness_detection = True
max_attempts = 3
timeout = 5
EOF

# Create sample bash completion file
cat << EOF > "$BUILD_DIR/etc/hellou/hellou-completion.bash"
# bash completion for HelloU

_hellou_completions()
{
    local cur prev opts
    COMPREPLY=()
    cur="\${COMP_WORDS[COMP_CWORD]}"
    prev="\${COMP_WORDS[COMP_CWORD-1]}"
    opts="--help --add-user --remove-user --test --config --setup --doctor"

    if [[ \${cur} == -* ]]; then
        COMPREPLY=( \$(compgen -W "\${opts}" -- \${cur}) )
        return 0
    fi
}

complete -F _hellou_completions hellou
EOF

# Create systemd service file
cat << EOF > "$BUILD_DIR/lib/systemd/system/face-unlock.service"
[Unit]
Description=HelloU Face Recognition Service
After=network.target

[Service]
Type=simple
ExecStart=/usr/bin/hellou --daemon
Restart=on-failure
RestartSec=5
StandardOutput=syslog
StandardError=syslog
SyslogIdentifier=hellou

[Install]
WantedBy=multi-user.target
EOF

# Create a sample HelloU script
cat << EOF > "$BUILD_DIR/usr/bin/hellou"
#!/bin/bash
# HelloU - Face Recognition Authentication System

if [ "\$1" == "--help" ] || [ "\$1" == "-h" ]; then
    echo "HelloU - Face Recognition Authentication System"
    echo "Usage: hellou [OPTION]"
    echo ""
    echo "Options:"
    echo "  --add-user     Register a new user for face recognition"
    echo "  --remove-user  Remove a user from face recognition"
    echo "  --test         Test the face recognition system"
    echo "  --setup        Configure system integration"
    echo "  --config       View or modify configuration"
    echo "  --doctor       Run diagnostics"
    echo "  --help         Display this help message"
    echo ""
    echo "For more information, see the man page: man hellou"
    exit 0
fi

echo "HelloU Face Recognition System"
echo "Please run with --help for available options"
exit 0
EOF
chmod 755 "$BUILD_DIR/usr/bin/hellou"

# Copy dependency check script
cp "$OUTPUT_DIR/bin/check-dependencies" "$BUILD_DIR/usr/bin/hellou-check-dependencies"
chmod 755 "$BUILD_DIR/usr/bin/hellou-check-dependencies"

# Create uninstall script
cat << EOF > "$BUILD_DIR/usr/bin/uninstall-hellou"
#!/bin/bash
# Uninstall HelloU Face Recognition System

if [ "\$1" == "--help" ] || [ "\$1" == "-h" ]; then
    echo "Uninstall HelloU - Remove Face Recognition Authentication System"
    echo "Usage: uninstall-hellou"
    echo ""
    echo "This command will completely remove HelloU from your system."
    echo "No options available."
    echo ""
    echo "For more information, see the man page: man uninstall-hellou"
    exit 0
fi

if [ "\$EUID" -ne 0 ]; then
    echo "Please run as root (using sudo)"
    exit 1
fi

echo "This will completely remove HelloU from your system."
echo "Are you sure? (y/n): "
read -r response
if [ "\$response" = "y" ] || [ "\$response" = "Y" ]; then
    echo "Removing HelloU..."
    apt-get remove --purge hellou-fixed
    echo "HelloU has been removed."
else
    echo "Uninstall cancelled."
fi
exit 0
EOF
chmod 755 "$BUILD_DIR/usr/bin/uninstall-hellou"

# Create Python modules directory structure
mkdir -p "$BUILD_DIR/usr/lib/python3/dist-packages/hellou/modules"
touch "$BUILD_DIR/usr/lib/python3/dist-packages/hellou/__init__.py"
touch "$BUILD_DIR/usr/lib/python3/dist-packages/hellou/modules/__init__.py"
chmod 644 "$BUILD_DIR/usr/lib/python3/dist-packages/hellou/__init__.py"
chmod 644 "$BUILD_DIR/usr/lib/python3/dist-packages/hellou/modules/__init__.py"

# Create sample face recognition module
cat << EOF > "$BUILD_DIR/usr/lib/python3/dist-packages/hellou/modules/face_recognition_module.py"
#!/usr/bin/env python3
"""
Face recognition module for HelloU face authentication system.
"""

import os
import pickle
import face_recognition
import cv2
import numpy as np

class FaceRecognizer:
    """Handles facial recognition for HelloU authentication."""
    
    def __init__(self, tolerance=0.6, model="hog"):
        """Initialize the face recognizer with given tolerance and model."""
        self.tolerance = tolerance
        self.model = model
        self.user_dir = "/var/lib/hellou/users"
        
    def recognize(self, image_path, username):
        """
        Recognize face from image and compare with stored user data.
        
        Args:
            image_path: Path to the image to recognize
            username: Username to compare against
            
        Returns:
            bool: True if face matches, False otherwise
        """
        # Load the user's face data
        user_file = os.path.join(self.user_dir, f"{username}.pkl")
        if not os.path.exists(user_file):
            return False
            
        with open(user_file, 'rb') as f:
            known_encoding = pickle.load(f)
            
        # Load the test image
        image = face_recognition.load_image_file(image_path)
        face_locations = face_recognition.face_locations(image, model=self.model)
        
        if len(face_locations) == 0:
            return False
            
        face_encodings = face_recognition.face_encodings(image, face_locations)
        
        # Compare with the known face
        matches = face_recognition.compare_faces([known_encoding], 
                                               face_encodings[0],
                                               tolerance=self.tolerance)
        
        return matches[0]
        
    def register(self, image_path, username):
        """
        Register a new user by saving their face encoding.
        
        Args:
            image_path: Path to the image to register
            username: Username to register
            
        Returns:
            bool: True if registration successful, False otherwise
        """
        # Load the image and find face encoding
        image = face_recognition.load_image_file(image_path)
        face_locations = face_recognition.face_locations(image, model=self.model)
        
        if len(face_locations) == 0:
            return False
            
        face_encodings = face_recognition.face_encodings(image, face_locations)
        
        # Save the face encoding
        if not os.path.exists(self.user_dir):
            os.makedirs(self.user_dir, exist_ok=True)
            
        user_file = os.path.join(self.user_dir, f"{username}.pkl")
        
        with open(user_file, 'wb') as f:
            pickle.dump(face_encodings[0], f)
            
        return True
EOF
chmod 755 "$BUILD_DIR/usr/lib/python3/dist-packages/hellou/modules/face_recognition_module.py"

# Create sample PAM service module
cat << EOF > "$BUILD_DIR/usr/lib/python3/dist-packages/hellou/modules/pam_service.py"
#!/usr/bin/env python3
"""
PAM service module for HelloU face authentication.
This module integrates with libpam-python to provide face authentication.
"""

import os
import sys
import tempfile
import time
import pwd
import subprocess
from pathlib import Path

def pam_sm_authenticate(pamh, flags, argv):
    """
    PAM authentication hook. This function is called by the PAM service
    when authentication is requested.
    
    Args:
        pamh: PAM handle
        flags: PAM flags
        argv: Arguments to the PAM module
        
    Returns:
        int: PAM return code (0 for success, non-zero for failure)
    """
    # Get the username
    try:
        username = pamh.get_user(None)
    except pamh.exception:
        return pamh.PAM_USER_UNKNOWN
        
    if not username:
        return pamh.PAM_USER_UNKNOWN
        
    # Check if the user has registered for face recognition
    user_file = f"/var/lib/hellou/users/{username}.pkl"
    if not os.path.exists(user_file):
        # User not registered, fall back to normal authentication
        return pamh.PAM_IGNORE
        
    # Try to capture an image and verify the face
    try:
        # Create a temporary file for the captured image
        with tempfile.NamedTemporaryFile(suffix='.jpg', delete=False) as temp_img:
            temp_path = temp_img.name
            
        # Capture the image
        pamh.conversation(pamh.Message(pamh.PAM_TEXT_INFO, 
                                     "Looking for your face..."))
        
        # Run the capture command
        capture_cmd = ["/usr/bin/hellou", "--capture", "--output", temp_path]
        result = subprocess.run(capture_cmd, capture_output=True)
        
        if result.returncode != 0:
            pamh.conversation(pamh.Message(pamh.PAM_ERROR_MSG, 
                                         "Could not capture image"))
            os.unlink(temp_path)
            return pamh.PAM_AUTH_ERR
            
        # Verify the face
        verify_cmd = ["/usr/bin/hellou", "--verify", "--user", username, 
                     "--image", temp_path]
        result = subprocess.run(verify_cmd, capture_output=True)
        
        # Clean up the temporary file
        os.unlink(temp_path)
        
        if result.returncode == 0:
            pamh.conversation(pamh.Message(pamh.PAM_TEXT_INFO, 
                                         "Face verified!"))
            return pamh.PAM_SUCCESS
        else:
            pamh.conversation(pamh.Message(pamh.PAM_ERROR_MSG, 
                                         "Face not recognized"))
            return pamh.PAM_AUTH_ERR
            
    except Exception as e:
        pamh.conversation(pamh.Message(pamh.PAM_ERROR_MSG, 
                                     f"Error: {str(e)}"))
        return pamh.PAM_AUTH_ERR

def pam_sm_setcred(pamh, flags, argv):
    """
    PAM credentials establishment hook.
    """
    return pamh.PAM_SUCCESS

def pam_sm_acct_mgmt(pamh, flags, argv):
    """
    PAM account management hook.
    """
    return pamh.PAM_SUCCESS

def pam_sm_open_session(pamh, flags, argv):
    """
    PAM session opening hook.
    """
    return pamh.PAM_SUCCESS

def pam_sm_close_session(pamh, flags, argv):
    """
    PAM session closing hook.
    """
    return pamh.PAM_SUCCESS

def pam_sm_chauthtok(pamh, flags, argv):
    """
    PAM authentication token changing hook.
    """
    return pamh.PAM_SUCCESS
EOF
chmod 755 "$BUILD_DIR/usr/lib/python3/dist-packages/hellou/modules/pam_service.py"

# Create paths.py module
cat << EOF > "$BUILD_DIR/usr/lib/python3/dist-packages/hellou/modules/paths.py"
#!/usr/bin/env python3
"""
Centralized path configuration for HelloU face recognition system.
"""

import os

# Base directories
ETC_DIR = "/etc/hellou"
VAR_LIB_DIR = "/var/lib/hellou"
USER_DATA_DIR = os.path.join(VAR_LIB_DIR, "users")

# Configuration files
CONFIG_FILE = os.path.join(ETC_DIR, "hellou.conf")
COMPLETION_FILE = os.path.join(ETC_DIR, "hellou-completion.bash")

# Helper function to ensure directories exist
def ensure_dir_exists(directory):
    """Create directory if it doesn't exist"""
    if not os.path.exists(directory):
        os.makedirs(directory, exist_ok=True)
EOF
chmod 644 "$BUILD_DIR/usr/lib/python3/dist-packages/hellou/modules/paths.py"

# Create man page for hellou command
cat << EOF > "$BUILD_DIR/usr/share/man/man1/hellou.1"
.TH HELLOU 1 "May 2025" "hellou-fixed 1.0.0" "User Commands"
.SH NAME
hellou \- Face recognition authentication system for Linux
.SH SYNOPSIS
.B hellou
[\fIoptions\fR]
.SH DESCRIPTION
HelloU is a modern face unlock system for Linux that enables face-based
authentication for sudo, login, screen unlock, and other PAM-secured operations.
.SH OPTIONS
.TP
.B \-h, \-\-help
Show help message and exit
.TP
.B \-\-add\-user
Register a new user for face recognition
.TP
.B \-\-remove\-user
Remove a user from face recognition
.TP
.B \-\-test
Test the face recognition system
.SH FILES
.TP
.I /etc/hellou/hellou.conf
Configuration file for HelloU
.TP
.I /var/lib/hellou/users/
Directory containing user face data
.SH AUTHOR
Written by Hari Heman <hariheman76@gmail.com>
.SH REPORTING BUGS
Report bugs to: https://github.com/HXMAN76/hellou/issues
EOF

# Create man page for uninstall-hellou command
cat << EOF > "$BUILD_DIR/usr/share/man/man1/uninstall-hellou.1"
.TH UNINSTALL-HELLOU 1 "May 2025" "hellou-fixed 1.0.0" "User Commands"
.SH NAME
uninstall-hellou \- Uninstall the HelloU face recognition system
.SH SYNOPSIS
.B uninstall-hellou
.SH DESCRIPTION
This command completely removes the HelloU face recognition system from your computer,
including all configuration files, user data, and system settings.
.SH OPTIONS
No options are available.
.SH FILES
.TP
.I /etc/hellou/
Configuration directory that will be removed
.TP
.I /var/lib/hellou/
Data directory that will be removed
.SH AUTHOR
Written by Hari Heman <hariheman76@gmail.com>
.SH REPORTING BUGS
Report bugs to: https://github.com/HXMAN76/hellou/issues
EOF

# Create man page for dependency check command
cat << EOF > "$BUILD_DIR/usr/share/man/man1/hellou-check-dependencies.1"
.TH HELLOU-CHECK-DEPENDENCIES 1 "May 2025" "hellou-fixed 1.0.0" "User Commands"
.SH NAME
hellou-check-dependencies \- Check system dependencies for the HelloU face recognition system
.SH SYNOPSIS
.B hellou-check-dependencies
.SH DESCRIPTION
This command checks if all required system dependencies for the HelloU face recognition system
are installed and properly configured. It verifies the presence of required packages,
Python modules, camera accessibility, and PAM configuration capability.
.SH EXIT STATUS
.TP
.B 0
All checks passed successfully
.TP
.B 1
One or more checks failed
.SH AUTHOR
Written by Hari Heman <hariheman76@gmail.com>
.SH REPORTING BUGS
Report bugs to: https://github.com/HXMAN76/hellou/issues
EOF

# Compress man pages
gzip -9 "$BUILD_DIR/usr/share/man/man1/hellou.1"
gzip -9 "$BUILD_DIR/usr/share/man/man1/uninstall-hellou.1"
gzip -9 "$BUILD_DIR/usr/share/man/man1/hellou-check-dependencies.1"
chmod 644 "$BUILD_DIR/usr/share/man/man1/hellou.1.gz"
chmod 644 "$BUILD_DIR/usr/share/man/man1/uninstall-hellou.1.gz"
chmod 644 "$BUILD_DIR/usr/share/man/man1/hellou-check-dependencies.1.gz"

# Create copyright file
cat << EOF > "$BUILD_DIR/usr/share/doc/$PACKAGE_NAME/copyright"
Format: https://www.debian.org/doc/packaging-manuals/copyright-format/1.0/
Upstream-Name: hellou
Upstream-Contact: Hari Heman <hariheman76@gmail.com>
Source: https://github.com/HXMAN76/hellou

Files: *
Copyright: 2025 Hari Heman <hariheman76@gmail.com>
License: MIT
 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:
 .
 The above copyright notice and this permission notice shall be included in all
 copies or substantial portions of the Software.
 .
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 SOFTWARE.
EOF

# Create changelog file
cat << EOF > "$BUILD_DIR/usr/share/doc/$PACKAGE_NAME/changelog"
$PACKAGE_NAME ($VERSION) unstable; urgency=medium

  * Initial release of fixed package
  * Corrected FHS compliance issues
  * Fixed permissions and file locations
  * Improved PAM integration
  * Added proper documentation
  * Added dependency check functionality

 -- Hari Heman <hariheman76@gmail.com>  $(date -R)
EOF
gzip -9 "$BUILD_DIR/usr/share/doc/$PACKAGE_NAME/changelog"

# Copy README
cp "$OUTPUT_DIR/README.md" "$BUILD_DIR/usr/share/doc/$PACKAGE_NAME/"

# Copy requirements.txt
cp "$OUTPUT_DIR/requirements.txt" "$BUILD_DIR/usr/share/doc/$PACKAGE_NAME/"

# Set correct permissions for documentation
chmod 644 "$BUILD_DIR/usr/share/doc/$PACKAGE_NAME/copyright"
chmod 644 "$BUILD_DIR/usr/share/doc/$PACKAGE_NAME/changelog.gz"
chmod 644 "$BUILD_DIR/usr/share/doc/$PACKAGE_NAME/README.md"
chmod 644 "$BUILD_DIR/usr/share/doc/$PACKAGE_NAME/requirements.txt"

# Create postinst script
cat << 'EOF' > "$BUILD_DIR/DEBIAN/postinst"
#!/bin/bash
set -e

# Get Python version
PY_VERSION=$(python3 -c 'import sys; print(f"{sys.version_info.major}.{sys.version_info.minor}")')

# Create required directories if they don't exist
mkdir -p /var/lib/hellou/users

# Set correct permissions (non-recursively for each directory/file)
chown root:root /var/lib/hellou
chown root:root /var/lib/hellou/users
chmod 755 /var/lib/hellou
chmod 755 /var/lib/hellou/users

# Install Python deps only if they're not already installed
python3 -c "import dlib" >/dev/null 2>&1 || pip3 install dlib
python3 -c "import face_recognition" >/dev/null 2>&1 || pip3 install face_recognition

# Configure PAM modules safely
function update_pam_config() {
    local pam_file="$1"
    local auth_line="auth sufficient pam_python.so /usr/lib/python3/dist-packages/hellou/modules/pam_service.py"
    
    # Create backup if it doesn't exist
    if [ ! -f "${pam_file}.hellou.bak" ]; then
        cp "$pam_file" "${pam_file}.hellou.bak"
    fi
    
    # Check if our line already exists in the file
    if ! grep -q "$auth_line" "$pam_file"; then
        # Find the first auth line
        local line_num=$(grep -n "^auth" "$pam_file" | head -n1 | cut -d: -f1)
        
        if [ -n "$line_num" ]; then
            # Insert our line after the first auth line
            sed -i "${line_num}a $auth_line" "$pam_file"
        else
            # If no auth line found, add our entry at the top
            sed -i "1i $auth_line" "$pam_file"
        fi
        echo "Updated PAM configuration in $pam_file"
    fi
}

# Update common PAM configurations
if [ -f /etc/pam.d/sudo ]; then
    update_pam_config /etc/pam.d/sudo
fi

if [ -f /etc/pam.d/login ]; then
    update_pam_config /etc/pam.d/login
fi

if [ -f /etc/pam.d/gdm-password ]; then
    update_pam_config /etc/pam.d/gdm-password
fi

# Add bash completion
if [ -d /etc/bash_completion.d ]; then
    ln -sf /etc/hellou/hellou-completion.bash /etc/bash_completion.d/hellou
fi

# Use deb-systemd-helper instead of direct systemctl calls
if [ -x "/usr/bin/deb-systemd-helper" ]; then
    deb-systemd-helper enable face-unlock.service
    deb-systemd-helper start face-unlock.service
fi

echo "HelloU face recognition system has been installed successfully."
echo "Run 'hellou --add-user' to register your face for authentication."

exit 0
EOF

# Create prerm script
cat << 'EOF' > "$BUILD_DIR/DEBIAN/prerm"
#!/bin/bash
set -e

# Use deb-systemd-helper instead of direct systemctl calls
if [ -x "/usr/bin/deb-systemd-helper" ]; then
    deb-systemd-helper stop face-unlock.service
    deb-systemd-helper disable face-unlock.service
fi

# Remove PAM configuration safely
function restore_pam_config() {
    local pam_file="$1"
    local backup_file="${pam_file}.hellou.bak"
    
    # If we have a backup, restore it
    if [ -f "$backup_file" ]; then
        cp "$backup_file" "$pam_file"
        echo "Restored original PAM configuration for $pam_file"
    else
        # Otherwise, just remove our line
        sed -i '/auth sufficient pam_python.so .*pam_service\.py/d' "$pam_file"
        echo "Removed HelloU from PAM configuration in $pam_file"
    fi
}

# Restore common PAM configurations
if [ -f /etc/pam.d/sudo.hellou.bak ]; then
    restore_pam_config /etc/pam.d/sudo
fi

if [ -f /etc/pam.d/login.hellou.bak ]; then
    restore_pam_config /etc/pam.d/login
fi

if [ -f /etc/pam.d/gdm-password.hellou.bak ]; then
    restore_pam_config /etc/pam.d/gdm-password
fi

# Remove bash completion
if [ -L /etc/bash_completion.d/hellou ]; then
    rm -f /etc/bash_completion.d/hellou
fi

exit 0
EOF

# Create postrm script
cat << 'EOF' > "$BUILD_DIR/DEBIAN/postrm"
#!/bin/bash
set -e

if [ "$1" = "purge" ]; then
    # Remove data directory
    rm -rf /var/lib/hellou

    # Remove configuration
    rm -rf /etc/hellou
    
    # Remove backup files
    rm -f /etc/pam.d/*.hellou.bak
    
    echo "HelloU has been completely removed from your system."
fi

exit 0
EOF

# Set execute permissions for maintainer scripts
chmod 755 "$BUILD_DIR/DEBIAN/postinst"
chmod 755 "$BUILD_DIR/DEBIAN/preinst"
chmod 755 "$BUILD_DIR/DEBIAN/prerm"
chmod 755 "$BUILD_DIR/DEBIAN/postrm"

# Set proper ownership for all files (root:root)
sudo chown -R root:root "$BUILD_DIR"

# Set proper directory permissions (755 instead of 775)
sudo find "$BUILD_DIR" -type d -exec chmod 755 {} \;

# Build the package
sudo dpkg-deb --build "$BUILD_DIR" "${OUTPUT_DIR}/${PACKAGE_NAME}-${VERSION}-final-with-deps.deb"

# Reset ownership of the final package
sudo chown $(whoami):$(whoami) "${OUTPUT_DIR}/${PACKAGE_NAME}-${VERSION}-final-with-deps.deb"

echo "Package ${PACKAGE_NAME}-${VERSION}-final-with-deps.deb created successfully."
echo "Run 'lintian ${OUTPUT_DIR}/${PACKAGE_NAME}-${VERSION}-final-with-deps.deb' to verify package quality."
