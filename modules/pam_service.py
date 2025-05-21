#!/usr/bin/env python3
"""
PAM service module for face-unlock.
This module interfaces with the PAM system to provide face authentication.
"""

import os
import sys
import syslog
import pwd
import configparser
from pathlib import Path

# Initialize syslog for logging
syslog.openlog("HelloU-PAM", syslog.LOG_PID, syslog.LOG_AUTH)

def log(message, level=syslog.LOG_INFO):
    """Log a message to syslog."""
    syslog.syslog(level, f"HelloU: {message}")

# Ensure correct Python path
log("Setting up Python path", syslog.LOG_DEBUG)
possible_paths = [
    # Package installation paths
    '/opt/hellou/python',
    '/opt/hellou/modules',
    # Development paths
    os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
    os.path.dirname(os.path.abspath(__file__))
]

for path in possible_paths:
    if os.path.exists(path) and path not in sys.path:
        sys.path.insert(0, path)
        log(f"Added path: {path}", syslog.LOG_DEBUG)

# Try to import the face recognition module
try:
    from face_recognition_module import FaceUnlock
    log("Successfully imported face_recognition_module", syslog.LOG_DEBUG)
except ImportError as e:
    log(f"Import error: {str(e)}", syslog.LOG_ERR)
    # Try to import from modules package
    try:
        from modules.face_recognition_module import FaceUnlock
        log("Successfully imported from modules.face_recognition_module", syslog.LOG_DEBUG)
    except ImportError as e2:
        log(f"Both import methods failed: {str(e2)}", syslog.LOG_ERR)
        # Last resort - import will fail if this doesn't work
        sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
        try:
            from modules.face_recognition_module import FaceUnlock
            log("Import successful after adding path", syslog.LOG_DEBUG)
        except ImportError as e3:
            log(f"All import methods failed: {str(e3)}", syslog.LOG_ERR)

def pam_sm_authenticate(pamh, flags, argv):
    """PAM service function for authentication."""
    try:
        # Get the username
        try:
            user = pamh.get_user(None)
        except pamh.exception as e:
            log(f"Error getting username: {e}", syslog.LOG_ERR)
            user = None
            
        if user is None:
            pamh.conversation(pamh.Message(pamh.PAM_ERROR_MSG, "Could not determine user name."))
            return pamh.PAM_USER_UNKNOWN

        # Log the authentication attempt
        log(f"Attempting face authentication for user: {user}")

        # Load configuration - try multiple paths
        config_paths = [
            "/etc/hellou/hellou.conf",
            "/home/hxman/Projects/face-recog/config/config.ini",
            os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "config/config.ini")
        ]
        
        config_path = None
        for path in config_paths:
            if os.path.exists(path):
                config_path = path
                log(f"Using configuration file: {config_path}")
                break
                
        if config_path is None:
            log("Configuration file not found in any of the search paths", syslog.LOG_ERR)
            pamh.conversation(pamh.Message(pamh.PAM_ERROR_MSG, "Error: Configuration file not found."))
            return pamh.PAM_AUTH_ERR
        
        # Initialize the face recognition system
        try:
            face_unlock = FaceUnlock(config_path)
            log("Face recognition system initialized successfully")
        except Exception as fe:
            log(f"Failed to initialize FaceUnlock: {str(fe)}", syslog.LOG_ERR)
            pamh.conversation(pamh.Message(pamh.PAM_ERROR_MSG, "Error initializing face recognition system."))
            return pamh.PAM_AUTH_ERR
        
        # Get authentication settings with defaults
        try:
            config = configparser.ConfigParser()
            config.read(config_path)
            
            # Use getint with fallback for safer config reading
            timeout = config.getint("auth", "timeout", fallback=5)
            max_attempts = config.getint("auth", "max_attempts", fallback=3)
            fallback_to_password = config.getboolean("auth", "fallback_to_password", fallback=True)
            
            log(f"Authentication settings: timeout={timeout}, max_attempts={max_attempts}, fallback={fallback_to_password}")
        except Exception as ce:
            log(f"Error reading config values: {str(ce)}", syslog.LOG_ERR)
            # Safe defaults
            timeout = 5
            max_attempts = 3
            fallback_to_password = True
            log("Using default authentication settings due to config error")
            
        # Attempt face authentication
        for attempt in range(max_attempts):
            # Inform the user we're starting facial recognition
            try:
                pamh.conversation(pamh.Message(pamh.PAM_TEXT_INFO, f"Looking for face... (attempt {attempt+1}/{max_attempts})"))
            except Exception as ce:
                log(f"Error in PAM conversation: {ce}", syslog.LOG_ERR)
            
            try:
                if face_unlock.authenticate_user(user, timeout=timeout):
                    log(f"Face authentication successful for user: {user}")
                    return pamh.PAM_SUCCESS
            except Exception as ae:
                log(f"Authentication error: {str(ae)}", syslog.LOG_ERR)
                try:
                    pamh.conversation(pamh.Message(pamh.PAM_ERROR_MSG, "Error during face recognition."))
                except Exception:
                    # If conversation fails, just continue
                    pass
                    
                if not fallback_to_password:
                    return pamh.PAM_SYSTEM_ERR
                break  # Exit the loop and fall back to password
            
            # Failed attempt
            if attempt < max_attempts - 1:
                try:
                    pamh.conversation(pamh.Message(pamh.PAM_ERROR_MSG, "Face not recognized. Please try again."))
                except Exception:
                    # If conversation fails, just continue
                    pass
            else:
                try:
                    pamh.conversation(pamh.Message(pamh.PAM_ERROR_MSG, "Face authentication failed."))
                except Exception:
                    # If conversation fails, just continue
                    pass
        
        # If we reach here, face authentication has failed
        log(f"Face authentication failed for user: {user} after {max_attempts} attempts")
        
        # Determine whether to allow password fallback
        if fallback_to_password:
            try:
                pamh.conversation(pamh.Message(pamh.PAM_TEXT_INFO, "Falling back to password authentication."))
            except Exception:
                # If conversation fails, just continue
                pass
            return pamh.PAM_AUTH_ERR  # This signals PAM to try the next module
        else:
            return pamh.PAM_AUTH_ERR
            
    except Exception as e:
        log(f"Unexpected error during face authentication: {str(e)}", syslog.LOG_ERR)
        try:
            pamh.conversation(pamh.Message(pamh.PAM_ERROR_MSG, "An unexpected error occurred during face authentication."))
        except Exception:
            # If conversation fails, just continue
            pass
        return pamh.PAM_AUTH_ERR

def pam_sm_setcred(pamh, flags, argv):
    """PAM service function for setting credentials."""
    return pamh.PAM_SUCCESS

def pam_sm_acct_mgmt(pamh, flags, argv):
    """PAM service function for account management."""
    return pamh.PAM_SUCCESS

def pam_sm_open_session(pamh, flags, argv):
    """PAM service function for opening a session."""
    return pamh.PAM_SUCCESS

def pam_sm_close_session(pamh, flags, argv):
    """PAM service function for closing a session."""
    return pamh.PAM_SUCCESS

def pam_sm_chauthtok(pamh, flags, argv):
    """PAM service function for changing authentication tokens."""
    return pamh.PAM_SUCCESS
