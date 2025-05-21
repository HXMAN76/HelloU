#!/usr/bin/env python3
"""
Face recognition core module for the face-unlock system.
This module handles the capture, detection, and comparison of faces.
"""

import os
import cv2
import numpy as np
import pickle
import time
import configparser
import logging
from pathlib import Path

# Fix for face_recognition_models installation
try:
    import face_recognition
except ImportError as e:
    if "face_recognition_models" in str(e):
        print("Installing face_recognition_models...")
        os.system("pip install face_recognition_models")
        import face_recognition
    else:
        raise

class FaceUnlock:
    def __init__(self, config_path=None):
        """Initialize the face unlock system with configuration."""
        self.logger = self._setup_logging()
        
        # Load configuration
        if config_path is None:
            config_path = os.path.expanduser("~/Projects/face-recog/config/config.ini")
        
        self.config = self._load_config(config_path)
        self.logger.info("Face unlock system initialized")
        
        # Set up face recognition parameters
        self.device_path = self.config.get("camera", "device_path")
        self.camera_width = self.config.getint("camera", "width")
        self.camera_height = self.config.getint("camera", "height")
        self.tolerance = self.config.getfloat("recognition", "tolerance")
        self.use_hog = self.config.getboolean("recognition", "use_hog")
        
        # Path to user face encodings
        self.user_data_path = self.config.get("recognition", "user_data_path")
        
        self.logger.debug(f"Using camera at {self.device_path}")
    
    def _setup_logging(self):
        """Set up logging for the module."""
        logger = logging.getLogger("face_unlock")
        logger.setLevel(logging.INFO)
        
        # Create console handler
        ch = logging.StreamHandler()
        ch.setLevel(logging.INFO)
        
        # Create formatter
        formatter = logging.Formatter('%(asctime)s - %(name)s - %(levelname)s - %(message)s')
        ch.setFormatter(formatter)
        
        # Add handler to logger
        logger.addHandler(ch)
        
        return logger
    
    def _load_config(self, config_path):
        """Load configuration from file."""
        self.logger.debug(f"Loading configuration from {config_path}")
        
        config = configparser.ConfigParser()
        if os.path.exists(config_path):
            config.read(config_path)
        else:
            self.logger.error(f"Configuration file not found: {config_path}")
            raise FileNotFoundError(f"Configuration file not found: {config_path}")
        
        return config
    
    def capture_image(self):
        """Capture an image from the configured camera."""
        self.logger.debug("Capturing image from camera")
        
        # Extract camera device number from path
        try:
            # If path is like /dev/video0, extract the number
            if self.device_path.startswith('/dev/video'):
                device_number = int(self.device_path.replace('/dev/video', ''))
            else:
                device_number = int(self.device_path)
                
            cap = cv2.VideoCapture(device_number)
        except ValueError:
            # If path is not a number, try using the full path
            cap = cv2.VideoCapture(self.device_path)
        
        if not cap.isOpened():
            self.logger.error(f"Failed to open camera at {self.device_path}")
            return None
        
        # Set camera properties
        cap.set(cv2.CAP_PROP_FRAME_WIDTH, self.camera_width)
        cap.set(cv2.CAP_PROP_FRAME_HEIGHT, self.camera_height)
        
        # Allow camera to warm up
        time.sleep(0.5)
        
        # Capture a frame
        ret, frame = cap.read()
        cap.release()
        
        if not ret:
            self.logger.error("Failed to capture image")
            return None
        
        return frame
    
    def detect_faces(self, image):
        """Detect faces in the given image."""
        self.logger.debug("Detecting faces in image")
        
        # Convert to RGB (face_recognition uses RGB)
        rgb_image = cv2.cvtColor(image, cv2.COLOR_BGR2RGB)
        
        # Detect faces
        detection_method = "hog" if self.use_hog else "cnn"
        face_locations = face_recognition.face_locations(rgb_image, model=detection_method)
        
        if not face_locations:
            self.logger.debug("No faces detected")
            return None, None
        
        self.logger.debug(f"Detected {len(face_locations)} faces")
        
        # Get face encodings
        face_encodings = face_recognition.face_encodings(rgb_image, face_locations)
        
        return face_locations, face_encodings
    
    def get_user_encodings(self, username):
        """Get the saved face encodings for a user."""
        user_file = os.path.join(self.user_data_path, f"{username}.pkl")
        
        if not os.path.exists(user_file):
            self.logger.error(f"No face data found for user: {username}")
            return None
        
        try:
            with open(user_file, 'rb') as f:
                user_data = pickle.load(f)
                return user_data.get('encodings', [])
        except Exception as e:
            self.logger.error(f"Error loading user data: {e}")
            return None
    
    def verify_face(self, face_encoding, username):
        """Verify if the detected face matches the stored user face."""
        user_encodings = self.get_user_encodings(username)
        
        if not user_encodings:
            return False
        
        # Compare face with user's stored faces
        matches = face_recognition.compare_faces(user_encodings, face_encoding, tolerance=self.tolerance)
        
        # If any match is found, consider it a success
        return any(matches)
    
    def save_user_face(self, username, face_encodings):
        """Save a user's face encodings to disk."""
        # Create directories if they don't exist
        os.makedirs(self.user_data_path, exist_ok=True)
        
        user_file = os.path.join(self.user_data_path, f"{username}.pkl")
        
        # Store face encodings
        user_data = {
            'username': username,
            'encodings': face_encodings,
            'created_at': time.time()
        }
        
        with open(user_file, 'wb') as f:
            pickle.dump(user_data, f)
        
        self.logger.info(f"Saved face data for user: {username}")
        return True
    
    def add_user(self, username, num_samples=5):
        """Add a new user by capturing multiple face samples."""
        self.logger.info(f"Adding new user: {username}")
        
        face_encodings = []
        samples_collected = 0
        
        print(f"Collecting {num_samples} face samples for {username}...")
        
        while samples_collected < num_samples:
            # Capture image
            image = self.capture_image()
            if image is None:
                continue
            
            # Detect faces
            face_locations, detected_encodings = self.detect_faces(image)
            
            if not detected_encodings:
                print("No face detected. Please position your face in front of the camera.")
                time.sleep(1)
                continue
            
            if len(detected_encodings) > 1:
                print("Multiple faces detected. Please ensure only your face is visible.")
                time.sleep(1)
                continue
            
            # Add the encoding
            face_encodings.append(detected_encodings[0])
            samples_collected += 1
            
            print(f"Sample {samples_collected}/{num_samples} captured successfully")
            time.sleep(0.5)
        
        # Save the collected face samples
        success = self.save_user_face(username, face_encodings)
        
        if success:
            print(f"User {username} added successfully!")
            return True
        else:
            print("Failed to save user face data.")
            return False
    
    def authenticate_user(self, username, timeout=5):
        """Authenticate a user against their stored face data."""
        self.logger.info(f"Authenticating user: {username}")
        
        start_time = time.time()
        
        while time.time() - start_time < timeout:
            # Capture image
            image = self.capture_image()
            if image is None:
                continue
            
            # Detect faces
            face_locations, detected_encodings = self.detect_faces(image)
            
            if detected_encodings and len(detected_encodings) > 0:
                # Use the first detected face
                if self.verify_face(detected_encodings[0], username):
                    self.logger.info(f"Authentication successful for {username}")
                    return True
            
            # Short pause before trying again
            time.sleep(0.1)
        
        self.logger.info(f"Authentication failed for {username} (timeout)")
        return False
    
    def remove_user(self, username):
        """Remove a user's face data."""
        user_file = os.path.join(self.user_data_path, f"{username}.pkl")
        
        if os.path.exists(user_file):
            os.remove(user_file)
            self.logger.info(f"Removed face data for user: {username}")
            return True
        else:
            self.logger.error(f"No face data found for user: {username}")
            return False
    
    def run_service(self):
        """Run as a background service for PAM authentication."""
        self.logger.info("Starting HelloU face recognition service")
        
        while True:
            # Sleep to prevent high CPU usage
            time.sleep(1)
            
            # Service just needs to stay alive for PAM module to work
            # The actual authentication is handled by authenticate_user() when called by PAM
            pass

# If run directly, test the module
if __name__ == "__main__":
    face_unlock = FaceUnlock()
    
    # Test camera capture
    print("Testing camera capture...")
    image = face_unlock.capture_image()
    
    if image is not None:
        print("Camera test successful!")
        
        # Test face detection
        print("Testing face detection...")
        face_locations, face_encodings = face_unlock.detect_faces(image)
        
        if face_encodings:
            print(f"Detected {len(face_encodings)} faces!")
            
            # Save test image if a face was found
            test_image = image.copy()
            for (top, right, bottom, left) in face_locations:
                # Draw rectangle around the face
                cv2.rectangle(test_image, (left, top), (right, bottom), (0, 255, 0), 2)
            
            cv2.imwrite("face_detect_test.jpg", test_image)
            print("Test image saved to 'face_detect_test.jpg'")
        else:
            print("No faces detected.")
    else:
        print("Camera test failed.")
