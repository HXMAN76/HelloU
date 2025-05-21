# HelloU Package Maintenance Guide

## Overview

This document describes the structure of the HelloU Debian package and provides guidance for maintainers on how to build, maintain, and update the package.

## Package Structure

The HelloU package follows standard Debian packaging conventions:

```
hellou-1.0.0/
├── DEBIAN/
│   ├── control          # Package metadata
│   ├── copyright        # Copyright and licensing information
│   ├── changelog.Debian # Package changelog
│   ├── postinst         # Post-installation script
│   ├── postrm           # Post-removal script
│   ├── preinst          # Pre-installation script
│   ├── prerm            # Pre-removal script
│   └── conffiles        # List of configuration files
├── etc/
│   ├── hellou/          # Configuration directory
│   │   └── config.ini   # Main configuration file
│   └── pam.d/           # PAM configuration directory
├── lib/
│   └── systemd/
│       └── system/
│           └── face-unlock.service # Systemd service file
├── usr/
│   ├── bin/             # Executable files
│   │   ├── hellou
│   │   └── uninstall-hellou
│   ├── lib/
│   │   └── python3/
│   │       └── dist-packages/
│   │           └── hellou/  # Python package
│   │               ├── dlib_face_module.py
│   │               ├── face_recognition_module.py
│   │               ├── pam_service.py
│   │               └── paths.py
│   └── share/
│       ├── doc/
│       │   └── hellou/  # Documentation
│       │       ├── changelog.Debian.gz
│       │       └── copyright
│       └── man/
│           └── man1/   # Man pages
│               ├── hellou.1.gz
│               └── uninstall-hellou.1.gz
└── var/
    └── lib/
        └── hellou/     # Data directory
            └── users/  # User face data
```

## Building the Package

To build a fresh package:

1. Clone the repository:
   ```
   git clone https://github.com/HXMAN76/HelloU.git
   cd HelloU
   ```

2. Run the package build script:
   ```
   sudo ./fix-package-ultimate.sh
   ```

3. The script will create `hellou-fixed-1.0.0-final.deb` in the current directory.

## Package Improvements

The following changes were made to improve the original package:

1. **Directory Structure**:
   - Moved Python code from `/opt/hellou` to `/usr/lib/python3/dist-packages/hellou`
   - Moved systemd service from `/etc/systemd/system` to `/lib/systemd/system`
   - Created proper man pages in `/usr/share/man/man1`
   - Added documentation in `/usr/share/doc/hellou`

2. **File Ownership and Permissions**:
   - Set all files to be owned by root:root
   - Set appropriate permissions on configuration and data files
   - Used non-recursive permission settings for better security

3. **Naming Conventions**:
   - Renamed scripts to match Debian conventions (removed .sh extensions)
   - Used consistent naming throughout the package

4. **PAM Integration**:
   - Improved PAM configuration handling
   - Added proper backup and restore functionality
   - Fixed module path references

5. **Metadata**:
   - Added proper copyright file
   - Added detailed changelog
   - Improved package description and dependencies

## Updating the Package

When a new version is released:

1. Update the version numbers in:
   - `DEBIAN/control`
   - `DEBIAN/changelog.Debian`
   - Update any scripts that reference version numbers

2. Make necessary modifications to the codebase

3. Update the `fix-package-ultimate.sh` script if the package structure changes

4. Build the new package:
   ```
   sudo ./fix-package-ultimate.sh
   ```

## Testing the Package

After building, test the package in a clean environment:

1. Install the package:
   ```
   sudo dpkg -i hellou-fixed-1.0.0-final.deb
   ```

2. Verify functionality:
   ```
   hellou test
   ```

3. Check systemd service:
   ```
   systemctl status face-unlock
   ```

4. Check PAM integration:
   ```
   sudo hellou doctor
   ```

## Common Maintenance Tasks

### Adding Dependencies

To add new dependencies:

1. Update `DEBIAN/control` file
2. Update `requirements.txt` for Python dependencies
3. Update installation scripts if special handling is needed

### Modifying Configuration Files

Configuration files are marked in `DEBIAN/conffiles`. When modifying:

1. Ensure they are properly backed up in pre-removal scripts
2. Use proper templates if configuration files need to be generated
3. Maintain backward compatibility when possible

### Troubleshooting

Common issues and solutions:

1. **PAM Integration Fails**:
   - Check paths in `modules/pam_service.py`
   - Verify PAM configuration backups in `/etc/pam.d.bak`

2. **Systemd Service Issues**:
   - Check service file permissions and location
   - Verify Python paths in service file

3. **Package Installation Errors**:
   - Run with `dpkg -i --debug=77777` for detailed output
   - Check installation scripts for errors

## Resources

- [Debian Policy Manual](https://www.debian.org/doc/debian-policy/)
- [Debian New Maintainers' Guide](https://www.debian.org/doc/manuals/maint-guide/)
- [Python Packaging for Debian](https://wiki.debian.org/Python/Packaging)

## Contact

For questions or issues:
- GitHub: https://github.com/HXMAN76/HelloU/issues
- Email: support@hellou.example.com

---

Document version: 1.0
Last updated: May 21, 2025
