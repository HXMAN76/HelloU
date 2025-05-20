#!/usr/bin/env bash
# Installation script for face-unlock

set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Function to print colored messages
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    print_error "This script must be run as root (sudo)."
    exit 1
fi

# Detect the current user (the one who invoked sudo)
REAL_USER=${SUDO_USER:-$(whoami)}
REAL_HOME=$(eval echo ~$REAL_USER)

# Project path
PROJECT_PATH="$REAL_HOME/Projects/face-recog"

print_info "Installing face-unlock system..."
print_info "Project path: $PROJECT_PATH"

# Create necessary directories
print_info "Creating directories..."
mkdir -p "$PROJECT_PATH"/{config,modules,bin,data/models,data/users}
chown -R $REAL_USER:$REAL_USER "$PROJECT_PATH"

# Install system dependencies
print_info "Installing system dependencies..."
apt-get update
apt-get install -y python3 python3-pip python3-dev libpam-python libpam-dev cmake

# Install Python dependencies
print_info "Installing Python dependencies..."
if [ -f "requirements.txt" ]; then
    sudo -u $REAL_USER pip3 install --user -r requirements.txt
else
    sudo -u $REAL_USER pip3 install --user opencv-python numpy face_recognition dlib
fi

# Copy files to the correct locations if they exist in the current directory
if [ -f "modules/face_recognition_module.py" ]; then
    print_info "Copying face recognition module..."
    cp modules/face_recognition_module.py "$PROJECT_PATH/modules/"
    chown $REAL_USER:$REAL_USER "$PROJECT_PATH/modules/face_recognition_module.py"
fi

if [ -f "modules/pam_service.py" ]; then
    print_info "Copying PAM service module..."
    cp modules/pam_service.py "$PROJECT_PATH/modules/"
    chown $REAL_USER:$REAL_USER "$PROJECT_PATH/modules/pam_service.py"
fi

if [ -f "bin/face-unlock" ]; then
    print_info "Copying face-unlock CLI..."
    cp bin/face-unlock "$PROJECT_PATH/bin/"
    chown $REAL_USER:$REAL_USER "$PROJECT_PATH/bin/face-unlock"
    chmod +x "$PROJECT_PATH/bin/face-unlock"
fi

if [ -f "config/config.ini" ]; then
    print_info "Copying configuration file..."
    cp config/config.ini "$PROJECT_PATH/config/"
    chown $REAL_USER:$REAL_USER "$PROJECT_PATH/config/config.ini"
fi

# Create a symbolic link to the CLI
print_info "Creating symbolic links..."
ln -sf "$PROJECT_PATH/bin/face-unlock" /usr/local/bin/face-unlock
ln -sf "$PROJECT_PATH/bin/face-unlock" /usr/local/bin/HelloU
chmod +x /usr/local/bin/HelloU
print_info "Created 'HelloU' command alias for easier access."

# Add the current user to video group for camera access
print_info "Adding user to video group..."
usermod -a -G video $REAL_USER

# Set up PAM configuration
print_info "Setting up PAM configuration..."

# Function to set up PAM service
setup_pam_service() {
    local service=$1
    local pam_file="/etc/pam.d/$service"
    local pam_line="auth        sufficient    pam_python.so $PROJECT_PATH/modules/pam_service.py"
    
    if [ -f "$pam_file" ]; then
        # Check if configuration already exists
        if grep -q "$PROJECT_PATH/modules/pam_service.py" "$pam_file"; then
            print_info "PAM configuration for $service already exists."
        else
            # Backup the original file
            cp "$pam_file" "$pam_file.bak"
            
            # Add our configuration after the first auth line
            awk -v line="$pam_line" '/^auth/ && !done {print $0; print line; done=1; next} {print}' "$pam_file.bak" > "$pam_file"
            
            print_info "PAM configuration for $service installed successfully."
        fi
    else
        print_warning "PAM configuration file for $service not found."
    fi
}

# Set up PAM for common services
setup_pam_service "sudo"
setup_pam_service "login"
setup_pam_service "gdm-password"
setup_pam_service "polkit-1"

# Set up systemd service
print_info "Setting up systemd service..."
if [ -f "$PROJECT_PATH/config/face-unlock.service" ]; then
    cp "$PROJECT_PATH/config/face-unlock.service" /etc/systemd/system/
    systemctl daemon-reload
    systemctl enable face-unlock.service
    systemctl start face-unlock.service
    print_info "Systemd service installed and started."
else
    print_warning "Systemd service file not found."
fi

print_info "Installation complete!"
print_info "Please log out and log back in for group changes to take effect."
print_info "Use 'HelloU add' to register your face."
print_info "Use 'HelloU test' to test face recognition."
print_info "Use 'HelloU config' to configure the system."

echo ""
echo -e "${GREEN}==========================================${NC}"
echo -e "${GREEN}  Face Unlock System Installed!           ${NC}"
echo -e "${GREEN}==========================================${NC}"
echo ""
echo -e "${YELLOW}Quick Commands:${NC}"
echo "  HelloU add                 # Enroll your face"
echo "  HelloU test                # Test face recognition"
echo "  HelloU config --show       # Show current configuration"
echo "  HelloU remove              # Remove your face data"
echo ""
echo -e "${YELLOW}Next Steps:${NC}"
echo "  1. Log out and log back in (for video group access)"
echo "  2. Run 'HelloU add' to enroll your face"
echo "  3. Run 'HelloU test' to verify recognition works"
echo ""
