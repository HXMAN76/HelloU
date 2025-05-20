"""Path configuration for the face-unlock system."""
import os
import sys

# Detect if we're running from an installed package or development environment
if os.path.exists('/usr/lib/hellou'):
    # Installed system paths
    CONFIG_DIR = '/etc/hellou'
    MODULES_DIR = '/usr/lib/hellou'
    DATA_DIR = '/var/lib/hellou'
    LOG_FILE = '/var/log/hellou.log'
else:
    # Development paths - relative to project root
    PROJECT_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    CONFIG_DIR = os.path.join(PROJECT_ROOT, 'config')
    MODULES_DIR = os.path.join(PROJECT_ROOT, 'modules')
    DATA_DIR = os.path.join(PROJECT_ROOT, 'data')
    LOG_FILE = os.path.join(PROJECT_ROOT, 'face_unlock.log')

# Common paths
CONFIG_FILE = os.path.join(CONFIG_DIR, 'config.ini')
MODELS_DIR = os.path.join(DATA_DIR, 'models')
USERS_DIR = os.path.join(DATA_DIR, 'users')
PAM_MODULE = os.path.join(MODULES_DIR, 'pam_service.py')
