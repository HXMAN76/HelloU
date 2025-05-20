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

# Add the parent directory to the path so we can import the face recognition module
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
try:
    # Try to import the dlib-based module first (more reliable)
    from modules.dlib_face_module import FaceUnlock
except ImportError:
    # Fall back to the face_recognition module if necessary
    from modules.face_recognition_module import FaceUnlock

def log(message):
    """Log a message to syslog."""
    syslog.syslog(syslog.LOG_AUTH, f"face-unlock: {message}")

def pam_sm_authenticate(pamh, flags, argv):
    """PAM service function for authentication."""
    try:
        # Get the username
        user = pamh.get_user(None)
        if user is None:
            pamh.conversation(pamh.Message(pamh.PAM_ERROR_MSG, "Could not determine user name."))
            return pamh.PAM_USER_UNKNOWN

        # Log the authentication attempt
        log(f"Attempting face authentication for user: {user}")

        # Load configuration
        config_path = "/home/hxman/Projects/face-recog/config/config.ini"
        config = configparser.ConfigParser()
        config.read(config_path)

        # Initialize the face recognition system
        face_unlock = FaceUnlock(config_path)
        
        # Get authentication settings
        timeout = config.getint("auth", "timeout")
        max_attempts = config.getint("auth", "max_attempts")
        fallback_to_password = config.getboolean("auth", "fallback_to_password")
        
        # Attempt face authentication
        for attempt in range(max_attempts):
            # Inform the user we're starting facial recognition
            pamh.conversation(pamh.Message(pamh.PAM_TEXT_INFO, f"Looking for face... (attempt {attempt+1}/{max_attempts})"))
            
            if face_unlock.authenticate_user(user, timeout=timeout):
                log(f"Face authentication successful for user: {user}")
                return pamh.PAM_SUCCESS
            
            # Failed attempt
            if attempt < max_attempts - 1:
                pamh.conversation(pamh.Message(pamh.PAM_ERROR_MSG, "Face not recognized. Please try again."))
            else:
                pamh.conversation(pamh.Message(pamh.PAM_ERROR_MSG, "Face authentication failed."))
        
        # If we reach here, face authentication has failed
        log(f"Face authentication failed for user: {user} after {max_attempts} attempts")
        
        # Determine whether to allow password fallback
        if fallback_to_password:
            pamh.conversation(pamh.Message(pamh.PAM_TEXT_INFO, "Falling back to password authentication."))
            return pamh.PAM_AUTH_ERR  # This signals PAM to try the next module
        else:
            return pamh.PAM_AUTH_ERR
            
    except Exception as e:
        log(f"Error during face authentication: {str(e)}")
        pamh.conversation(pamh.Message(pamh.PAM_ERROR_MSG, "An error occurred during face authentication."))
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
