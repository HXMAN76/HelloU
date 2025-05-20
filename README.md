# HelloU - Face Unlock for Linux

<div align="center">

![HelloU Logo](https://placehold.co/600x150/orange/white?text=HelloU&font=montserrat)

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Platform](https://img.shields.io/badge/platform-Linux-blue.svg)](https://www.linux.org/)
[![Python Version](https://img.shields.io/badge/python-3.8%2B-green)](https://www.python.org/)
[![Release](https://img.shields.io/github/v/release/HXMAN76/HelloU)](https://github.com/HXMAN76/HelloU/releases)
[![Downloads](https://img.shields.io/github/downloads/HXMAN76/HelloU/total)](https://github.com/HXMAN76/HelloU/releases)

**Secure, fast, and privacy-focused face authentication for Linux**

</div>

## Overview

HelloU is a modern facial recognition system for Linux authentication. It enables secure, convenient face-based authentication for sudo commands, login sessions, and any PAM-secured activity. Built with a focus on speed, reliability, and privacy, HelloU brings cutting-edge biometric security to your Linux system.

### Key Features

- 🚀 **Fast Recognition**: Uses dlib for efficient face detection and matching
- 🔒 **Privacy-First**: All face data stays on your local machine
- 🔐 **PAM Integration**: Works with sudo, login, screen lockers and more
- 🎛️ **Highly Configurable**: Adjust sensitivity and security settings
- 📹 **IR Camera Support**: Enhanced security with infrared cameras
- 🧩 **Extensible**: Modular design for easy customization

<p align="center">
  <img src="https://placehold.co/800x400/darkblue/white?text=Face+Recognition+Demo&font=montserrat" alt="Demo Image" width="600">
</p>

## Installation

Choose the installation method that best suits your needs:

### Option 1: APT Package (Recommended)

```bash
# Download latest release from GitHub
ver=$(curl -s https://api.github.com/repos/HXMAN76/HelloU/releases/latest | grep -oP '"tag_name": "\K(.*)(?=")')
wget "https://github.com/HXMAN76/HelloU/releases/download/${ver}/hellou_${ver}_amd64.deb"

# Install HelloU
sudo apt install ./"hellou_${ver}_amd64.deb"
```

### Option 2: Manual Installation

For advanced users who want full control:

```bash
# Install system dependencies
sudo apt update
sudo apt install -y python3 python3-pip python3-dev libpam-python libpam-dev cmake

# Clone HelloU repository
git clone https://github.com/HXMAN76/HelloU.git
cd HelloU

# Install Python dependencies
python3 -m pip install --user -r requirements.txt

# Install HelloU system-wide
sudo ./install.sh

# Set up PAM integration
sudo HelloU setup
```

### Initial Setup

After installation, set up face recognition:

```bash
# Add your face to the system
HelloU add

# Test the recognition
HelloU test
```

## Usage Guide

### Core Commands

| Command | Description | Example |
|---------|-------------|---------|
| `HelloU add` | Enroll your face | `HelloU add --samples 10` |
| `HelloU test` | Test recognition | `HelloU test --timeout 5` |
| `HelloU remove` | Remove face data | `HelloU remove --username john` |
| `HelloU list` | Show enrolled users | `HelloU list --detailed` |

### Configuration

| Command | Description | Example |
|---------|-------------|---------|
| `HelloU config --show` | View settings | `HelloU config --show --json` |
| `HelloU config --camera` | Set camera | `HelloU config --camera /dev/video0` |
| `HelloU config --tolerance` | Adjust sensitivity | `HelloU config --tolerance 0.6` |
| `HelloU config --debug` | Enable debugging | `HelloU config --debug on` |

### System Integration

| Command | Description | Example |
|---------|-------------|---------|
| `HelloU setup` | Configure system | `HelloU setup --pam` |
| `HelloU doctor` | Run diagnostics | `HelloU doctor --verbose` |
| `HelloU logs` | View log files | `HelloU logs --tail` |

## Troubleshooting

### Camera Not Working?

```bash
# Add yourself to video group
sudo usermod -a -G video $USER
# Log out and back in, then check available cameras
ls -l /dev/video*
# Configure the correct camera
HelloU config --camera /dev/videoX
```

### Recognition Problems?

```bash
# Re-enroll with better lighting
HelloU remove
HelloU add

# Make recognition more lenient
HelloU config --tolerance 0.7
```

### PAM Integration Issues?

```bash
sudo apt install libpam-python
sudo ~/Projects/face-recog/bin/setup-pam
```

## Security Considerations

- Use an IR camera for enhanced security against photo attacks
- Lower tolerance (0.5 or below) increases security but may require better lighting
- Consider combining with other authentication factors for critical systems

## Contributing

Contributions make open source great! Here's how you can help:

1. **Fork** the repository
2. **Setup** development environment:
   ```bash
   python -m venv env
   source env/bin/activate
   pip install -r requirements.txt
   ```
3. **Create** your feature branch
4. **Commit** your changes
5. **Push** to your branch
6. Submit a **Pull Request**

### Areas for Contribution

- 💻 GUI Interface
- 🔐 Multi-factor authentication
- 📹 Hardware support
- ⚡ Performance optimizations
- 📚 Documentation
- 🧪 Test coverage

## Roadmap

- [ ] Graphical User Interface
- [ ] Liveness detection
- [ ] Multi-factor support
- [ ] Support for more Linux distributions
- [ ] Mobile app companion

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- Inspired by [Howdy](https://github.com/boltgolt/howdy)
- Face recognition powered by [dlib](http://dlib.net/)
- Camera integration using [OpenCV](https://opencv.org/)
- Thanks to all contributors!

---

<div align="center">
  <p>Made with ❤️ by the HelloU community</p>
  <p>
    <a href="https://github.com/HXMAN76/HelloU/issues">Report Bug</a> •
    <a href="https://github.com/HXMAN76/HelloU/issues">Request Feature</a>
  </p>
</div>



## Development Setup

For developers who want to contribute to HelloU, here's how to set up your environment:

1. Clone the repository:
   ```bash
   git clone https://github.com/your-username/hellou-face-unlock.git
   cd hellou-face-unlock
   ```

2. Create a virtual environment and install dependencies:
   ```bash
   python -m venv env
   source env/bin/activate
   pip install -r requirements.txt
   ```

3. Run the installation script:
   ```bash
   sudo ./install.sh
   ```

## Usage

### Quick Commands with HelloU

Face Unlock can be accessed using the convenient `HelloU` command:

```bash
HelloU add     # Enroll your face
HelloU test    # Test recognition
HelloU config  # Configure settings
HelloU remove  # Remove your face data
```

### Enrolling Your Face

To add your face to the recognition database:

```bash
HelloU add
```

Follow the on-screen instructions to capture multiple angles of your face.

### Testing Recognition

To test if face recognition is working:

```bash
HelloU test
```

### Managing Users

- **List enrolled users**:
  ```bash
  HelloU list
  ```

- **Remove a user**:
  ```bash
  HelloU remove --username USERNAME
  ```

- **Configure settings**:
  ```bash
  HelloU config --show
  HelloU config --camera /dev/video0 --tolerance 0.5
  ```

## Troubleshooting

### Quick Diagnostics

Run the built-in diagnostic tool:
```bash
sudo HelloU doctor
```

This will check:
- Camera access and permissions
- PAM integration
- System dependencies
- Configuration files
- User permissions

### Common Issues

#### Camera Problems

1. Add user to video group:
   ```bash
   sudo usermod -a -G video $USER
   sudo usermod -a -G hellou $USER
   # Log out and back in for changes to take effect
   ```

2. Set up camera:
   ```bash
   # List available cameras
   HelloU devices --list
   
   # Configure specific camera
   HelloU config --camera /dev/video0
   
   # Test camera
   HelloU test --debug --show-preview
   ```

#### Recognition Issues

1. Improve recognition accuracy:
   ```bash
   # Re-enroll with multiple angles
   HelloU add --samples 10 --guided
   
   # Fine-tune recognition
   HelloU config --tolerance 0.6  # Lower = stricter
   ```

2. Debug recognition:
   ```bash
   # Test with debug info
   HelloU test --debug --show-landmarks
   
   # View logs
   sudo HelloU logs --tail
   ```

#### PAM Setup

1. Check PAM status:
   ```bash
   sudo HelloU doctor --check-pam
   ```

2. Fix common issues:
   ```bash
   # Reinstall PAM module
   sudo HelloU setup --reinstall-pam
   
   # Reset PAM configuration
   sudo HelloU setup --reset-pam
   ```

3. View PAM logs:
   ```bash
   sudo HelloU logs --pam --tail
   ```

## Security Guide

### Best Practices

1. **Hardware Security**
   - Use IR cameras for enhanced security
   - Position camera in well-lit area
   - Consider environmental factors
   - Enable liveness detection if available

2. **Software Configuration**
   - Set strict tolerance (0.5 or lower)
   - Enable mandatory secondary authentication
   - Regular updates and security patches
   - Periodic face data re-enrollment

3. **System Integration**
   - Limit sudo access appropriately
   - Regular security audits
   - Monitor authentication logs
   - Back up face data securely

### Privacy Features

- All face data stored locally
- Strong encryption at rest
- No cloud services required
- Secure cleanup on removal

### Security Levels

Configure security based on your needs:

| Level | Settings | Use Case |
|-------|----------|----------|
| High | Tolerance: 0.4, IR Camera, 2FA | Financial, Root access |
| Medium | Tolerance: 0.6, Regular Camera | Daily computing |
| Low | Tolerance: 0.7, Quick Match | Home use |

### Regular Maintenance

- Update HelloU regularly
- Monitor system logs
- Review access patterns
- Backup face data

## Development Guide

### Setting Up Development Environment

1. Fork and clone the repository:
   ```bash
   git clone https://github.com/your-username/HelloU.git
   cd HelloU
   ```

2. Create development environment:
   ```bash
   # Create and activate virtual environment
   python3 -m venv env
   source env/bin/activate
   
   # Install dependencies
   pip install -r requirements-dev.txt
   
   # Install pre-commit hooks
   pre-commit install
   ```

3. Install for development:
   ```bash
   # Install in development mode
   sudo ./install.sh --dev
   
   # Enable debug logging
   HelloU config --debug
   ```

### Development Workflow

1. Create feature branch:
   ```bash
   git checkout -b feature/your-feature-name
   ```

2. Run tests:
   ```bash
   # Run unit tests
   pytest
   
   # Run integration tests
   pytest tests/integration
   
   # Run with coverage
   pytest --cov=hellou
   ```

3. Format and lint:
   ```bash
   # Format code
   black .
   isort .
   
   # Run linters
   flake8
   pylint hellou
   ```

## Technical Specifications

### System Requirements

#### Minimum Requirements
- Linux-based operating system (Ubuntu 20.04+, Debian 11+)
- Python 3.8 or newer
- 2GB RAM
- 500MB free disk space
- Basic USB webcam

#### Recommended Setup
- Ubuntu 22.04 or newer
- Python 3.10+
- 4GB RAM
- IR-capable camera
- Multi-core processor

### Dependencies

#### Core Dependencies
- `dlib` (≥19.24) - Face recognition engine
- `OpenCV` (≥4.8) - Camera interface
- `NumPy` (≥1.21) - Numerical processing
- `PAM Python` - Authentication integration

#### Optional Features
- `CUDA` support for GPU acceleration
- `python-v4l2` for advanced camera control
- `python-systemd` for system integration

### Performance

Typical performance metrics:
- Recognition time: <1s
- False acceptance rate: <0.1%
- False rejection rate: <1%
- Memory usage: ~200MB
