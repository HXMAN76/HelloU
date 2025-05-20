#!/usr/bin/env python3
# Test all available cameras and save sample images from each
import cv2
import os

def test_cameras():
    # Create output directory if it doesn't exist
    if not os.path.exists("camera_samples"):
        os.makedirs("camera_samples")
    
    # Test each camera device
    for i in range(4):  # Checking devices 0-3
        print(f"Testing camera at /dev/video{i}...")
        cap = cv2.VideoCapture(i)
        
        if not cap.isOpened():
            print(f"  - Failed to open /dev/video{i}")
            continue
            
        # Try to get camera info
        width = cap.get(cv2.CAP_PROP_FRAME_WIDTH)
        height = cap.get(cv2.CAP_PROP_FRAME_HEIGHT)
        print(f"  - Resolution: {width}x{height}")
        
        # Try to read a frame
        ret, frame = cap.read()
        if not ret:
            print(f"  - Failed to read from /dev/video{i}")
            cap.release()
            continue
            
        # Save the image
        filename = f"camera_samples/camera_{i}.jpg"
        cv2.imwrite(filename, frame)
        print(f"  - Image saved to {filename}")
        
        # Release the camera
        cap.release()
        
    print("Testing complete. Check the 'camera_samples' directory for the images.")

if __name__ == "__main__":
    test_cameras()
