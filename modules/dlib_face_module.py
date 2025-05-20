#!/usr/bin/env python3
"""
Alternative face recognition module for the face-unlock system using dlib directly.
This avoids dependency issues with face_recognition_models.
"""

import os
import cv2
import numpy as np
import dlib
import pickle
import time
import configparser
import logging
from pathlib import Path

class FaceUnlock:
    def __init__(self, config_path=None):
        """Initialize the face unlock system with configuration."""
        self.logger = self._setup_logging()
        
        # Load configuration
        if config_path is None:
            # Find the config relative to the module location
            module_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
            config_path = os.path.join(module_dir, "config", "config.ini")
        
        self.config = self._load_config(config_path)
        self.logger.info("Face unlock system initialized")
        
        # Set up file logging after config is loaded
        self._setup_file_logging(self.config.get("system", "log_path", fallback=None))
        
        # Set up face recognition parameters
        self.device_path = self.config.get("camera", "device_path")
        self.camera_width = self.config.getint("camera", "width")
        self.camera_height = self.config.getint("camera", "height")
        self.tolerance = self.config.getfloat("recognition", "tolerance")
        
        # Path to user face encodings - resolve relative paths
        user_data_path = self.config.get("recognition", "user_data_path")
        self.user_data_path = self._get_clean_path(user_data_path)
        
        # Initialize dlib's face detector and shape predictor
        self.detector = dlib.get_frontal_face_detector()
        model_dir_config = self.config.get("recognition", "model_path")
        model_dir = self._get_clean_path(model_dir_config)
        os.makedirs(model_dir, exist_ok=True)
        
        # Shape predictor model path
        shape_predictor_path = os.path.join(model_dir, "shape_predictor_68_face_landmarks.dat")
        face_rec_model_path = os.path.join(model_dir, "dlib_face_recognition_resnet_model_v1.dat")
        
        # Check if shape predictor model exists, if not download it
        if not os.path.exists(shape_predictor_path):
            print(f"Downloading shape predictor model to {shape_predictor_path}...")
            import urllib.request
            urllib.request.urlretrieve(
                "https://github.com/davisking/dlib-models/raw/master/shape_predictor_68_face_landmarks.dat.bz2",
                shape_predictor_path + ".bz2"
            )
            # Extract the model
            import bz2
            with bz2.open(shape_predictor_path + ".bz2") as f_in, open(shape_predictor_path, 'wb') as f_out:
                f_out.write(f_in.read())
            # Remove the compressed file
            os.remove(shape_predictor_path + ".bz2")
        
        # Check if face recognition model exists, if not download it
        if not os.path.exists(face_rec_model_path):
            print(f"Downloading face recognition model to {face_rec_model_path}...")
            import urllib.request
            urllib.request.urlretrieve(
                "https://github.com/davisking/dlib-models/raw/master/dlib_face_recognition_resnet_model_v1.dat.bz2",
                face_rec_model_path + ".bz2"
            )
            # Extract the model
            import bz2
            with bz2.open(face_rec_model_path + ".bz2") as f_in, open(face_rec_model_path, 'wb') as f_out:
                f_out.write(f_in.read())
            # Remove the compressed file
            os.remove(face_rec_model_path + ".bz2")
            
        # Load models
        self.predictor = dlib.shape_predictor(shape_predictor_path)
        self.face_rec_model = dlib.face_recognition_model_v1(face_rec_model_path)
        
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
        
    def _setup_file_logging(self, log_path):
        """Set up file logging with proper path handling."""
        # Only call this after config is loaded
        if not hasattr(self, 'config'):
            return
            
        try:
            log_path = self.config.get("system", "log_path")
            
            # Clean and resolve the path
            log_path = self._get_clean_path(log_path)
                
            # Create file handler
            fh = logging.FileHandler(log_path)
            fh.setLevel(logging.INFO)
            
            # Use same formatter as console
            formatter = logging.Formatter('%(asctime)s - %(name)s - %(levelname)s - %(message)s')
            fh.setFormatter(formatter)
            
            # Add to logger
            self.logger.addHandler(fh)
            self.logger.info(f"Logging to file: {log_path}")
        except (configparser.NoSectionError, configparser.NoOptionError):
            # Log path not configured, just use console logging
            pass
    
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
        
    def _get_clean_path(self, path):
        """Strip quotes from paths and handle relative paths."""
        # Remove any quotes that might be present
        clean_path = path.strip('"\'')
        
        # Make absolute if it's a relative path
        if not os.path.isabs(clean_path):
            base_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
            clean_path = os.path.join(base_dir, clean_path)
            
        return clean_path
    
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
        """Detect faces in the given image using dlib."""
        self.logger.debug("Detecting faces in image")
        
        # Convert to RGB
        rgb_image = cv2.cvtColor(image, cv2.COLOR_BGR2RGB)
        
        # Detect faces using dlib
        faces = self.detector(rgb_image)
        
        if not faces:
            self.logger.debug("No faces detected")
            return [], []
        
        self.logger.debug(f"Detected {len(faces)} faces")
        
        # Get face descriptors (encodings)
        face_descriptors = []
        face_locations = []
        
        for face in faces:
            # Get face landmarks
            shape = self.predictor(rgb_image, face)
            
            # Compute face descriptor
            face_descriptor = self.face_rec_model.compute_face_descriptor(rgb_image, shape)
            face_descriptor = np.array(face_descriptor)
            
            # Add to our results
            face_descriptors.append(face_descriptor)
            face_locations.append((face.top(), face.right(), face.bottom(), face.left()))
        
        return face_locations, face_descriptors
    
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
    
    def verify_face(self, face_descriptor, username):
        """Verify if the detected face matches the stored user face."""
        user_encodings = self.get_user_encodings(username)
        
        if not user_encodings:
            return False
        
        # Compare face with user's stored faces
        for stored_encoding in user_encodings:
            # Calculate Euclidean distance
            distance = np.linalg.norm(face_descriptor - stored_encoding)
            
            # Check if distance is below threshold (lower = more similar)
            if distance < self.tolerance:
                return True
        
        return False
    
    def save_user_face(self, username, face_descriptors):
        """Save a user's face encodings to disk."""
        # Create directories if they don't exist
        os.makedirs(self.user_data_path, exist_ok=True)
        
        user_file = os.path.join(self.user_data_path, f"{username}.pkl")
        
        # Store face encodings
        user_data = {
            'username': username,
            'encodings': face_descriptors,
            'created_at': time.time()
        }
        
        with open(user_file, 'wb') as f:
            pickle.dump(user_data, f)
        
        self.logger.info(f"Saved face data for user: {username}")
        return True
    
    def add_user(self, username, num_samples=5):
        """Add a new user by capturing multiple face samples."""
        self.logger.info(f"Adding new user: {username}")
        
        face_descriptors = []
        samples_collected = 0
        
        print(f"Collecting {num_samples} face samples for {username}...")
        
        while samples_collected < num_samples:
            # Capture image
            image = self.capture_image()
            if image is None:
                continue
            
            # Detect faces
            face_locations, detected_descriptors = self.detect_faces(image)
            
            if not detected_descriptors:
                print("No face detected. Please position your face in front of the camera.")
                time.sleep(1)
                continue
            
            if len(detected_descriptors) > 1:
                print("Multiple faces detected. Please ensure only your face is visible.")
                time.sleep(1)
                continue
            
            # Add the descriptor
            face_descriptors.append(detected_descriptors[0])
            samples_collected += 1
            
            print(f"Sample {samples_collected}/{num_samples} captured successfully")
            time.sleep(0.5)
        
        # Save the collected face samples
        success = self.save_user_face(username, face_descriptors)
        
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
            face_locations, detected_descriptors = self.detect_faces(image)
            
            if detected_descriptors and len(detected_descriptors) > 0:
                # Use the first detected face
                if self.verify_face(detected_descriptors[0], username):
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

# If run directly, test the module
if __name__ == "__main__":
    try:
        face_unlock = FaceUnlock()
        
        # Test camera capture
        print("Testing camera capture...")
        image = face_unlock.capture_image()
        
        if image is not None:
            print("Camera test successful!")
            
            # Test face detection
            print("Testing face detection...")
            face_locations, face_descriptors = face_unlock.detect_faces(image)
            
            if face_descriptors:
                print(f"Detected {len(face_descriptors)} faces!")
                
                # Save test image if a face was found
                test_image = image.copy()
                for (top, right, bottom, left) in face_locations:
                    # Draw rectangle around the face
                    cv2.rectangle(test_image, (left, top), (right, bottom), (0, 255, 0), 2)
                
                # Use current directory for test image output
                output_path = os.path.join(os.path.dirname(os.path.dirname(__file__)), "face_detect_test.jpg")
                cv2.imwrite(output_path, test_image)
                print(f"Test image saved to '{output_path}'")
            else:
                print("No faces detected.")
        else:
            print("Camera test failed.")
    except Exception as e:
        print(f"Error during testing: {str(e)}")
