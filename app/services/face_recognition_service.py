"""Face recognition and identification service."""
from __future__ import annotations

import json
import logging
import os
import pickle
import time
from dataclasses import dataclass
from pathlib import Path
from typing import Dict, List, Optional, Tuple

try:
    import cv2
    import numpy as np
    from sklearn.svm import SVC
    from sklearn.preprocessing import LabelEncoder
except ImportError:
    cv2 = None
    np = None
    SVC = None
    LabelEncoder = None

from app.config import Settings

LOGGER = logging.getLogger("echo.face_recognition")


@dataclass
class FaceData:
    name: str
    encoding: np.ndarray
    confidence: float
    last_seen: float
    image_path: Optional[str] = None


@dataclass
class FaceDetection:
    name: str
    confidence: float
    bounding_box: Tuple[int, int, int, int]  # x, y, w, h
    timestamp: float


class FaceRecognitionService:
    def __init__(self, settings: Settings) -> None:
        self._settings = settings
        self._face_cascade = None
        self._known_faces: Dict[str, FaceData] = {}
        self._face_encodings: List[np.ndarray] = []
        self._face_names: List[str] = []
        self._classifier: Optional[SVC] = None
        self._label_encoder: Optional[LabelEncoder] = None
        self._data_dir = settings.data_dir / "faces"
        self._data_dir.mkdir(parents=True, exist_ok=True)
        
        if cv2 is not None:
            self._initialize_face_detection()
            self._load_known_faces()

    def _initialize_face_detection(self) -> None:
        """Initialize OpenCV face detection."""
        try:
            # Try to load Haar cascade for face detection
            cascade_path = cv2.data.haarcascades + 'haarcascade_frontalface_default.xml'
            self._face_cascade = cv2.CascadeClassifier(cascade_path)
            
            if self._face_cascade.empty():
                LOGGER.warning("Could not load face cascade classifier")
                self._face_cascade = None
            else:
                LOGGER.info("Face detection initialized")
        except Exception as exc:
            LOGGER.warning("Failed to initialize face detection: %s", exc)
            self._face_cascade = None

    def detect_faces(self, image: np.ndarray) -> List[FaceDetection]:
        """Detect faces in an image and return bounding boxes."""
        if self._face_cascade is None or image is None:
            return []
        
        try:
            gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
            faces = self._face_cascade.detectMultiScale(
                gray,
                scaleFactor=1.1,
                minNeighbors=5,
                minSize=(30, 30)
            )
            
            detections = []
            for (x, y, w, h) in faces:
                # Extract face region
                face_region = image[y:y+h, x:x+w]
                
                # Try to recognize the face
                name, confidence = self._recognize_face(face_region)
                
                detections.append(FaceDetection(
                    name=name,
                    confidence=confidence,
                    bounding_box=(x, y, w, h),
                    timestamp=time.time()
                ))
            
            return detections
            
        except Exception as exc:
            LOGGER.exception("Error detecting faces: %s", exc)
            return []

    def _recognize_face(self, face_image: np.ndarray) -> Tuple[str, float]:
        """Recognize a face and return name and confidence."""
        if not self._known_faces or self._classifier is None:
            return "Unknown", 0.0
        
        try:
            # Extract face encoding (simplified - in real implementation, use face_recognition library)
            face_encoding = self._extract_face_encoding(face_image)
            if face_encoding is None:
                return "Unknown", 0.0
            
            # Predict using trained classifier
            prediction = self._classifier.predict([face_encoding])
            confidence = max(self._classifier.predict_proba([face_encoding])[0])
            
            name = self._label_encoder.inverse_transform(prediction)[0]
            return name, confidence
            
        except Exception as exc:
            LOGGER.exception("Error recognizing face: %s", exc)
            return "Unknown", 0.0

    def _extract_face_encoding(self, face_image: np.ndarray) -> Optional[np.ndarray]:
        """Extract face encoding from face image."""
        # This is a simplified version - in production, use face_recognition library
        try:
            # Resize to standard size
            face_resized = cv2.resize(face_image, (64, 64))
            # Convert to grayscale
            face_gray = cv2.cvtColor(face_resized, cv2.COLOR_BGR2GRAY)
            # Flatten to 1D array
            return face_gray.flatten()
        except Exception as exc:
            LOGGER.exception("Error extracting face encoding: %s", exc)
            return None

    def add_face(self, name: str, face_image: np.ndarray, confidence_threshold: float = 0.8) -> bool:
        """Add a new face to the known faces database."""
        try:
            face_encoding = self._extract_face_encoding(face_image)
            if face_encoding is None:
                return False
            
            # Save face image
            face_filename = f"{name}_{int(time.time())}.jpg"
            face_path = self._data_dir / face_filename
            cv2.imwrite(str(face_path), face_image)
            
            # Add to known faces
            face_data = FaceData(
                name=name,
                encoding=face_encoding,
                confidence=1.0,
                last_seen=time.time(),
                image_path=str(face_path)
            )
            
            self._known_faces[name] = face_data
            self._face_encodings.append(face_encoding)
            self._face_names.append(name)
            
            # Retrain classifier
            self._train_classifier()
            
            # Save to disk
            self._save_known_faces()
            
            LOGGER.info("Added face for %s", name)
            return True
            
        except Exception as exc:
            LOGGER.exception("Error adding face for %s: %s", name, exc)
            return False

    def _train_classifier(self) -> None:
        """Train the face recognition classifier."""
        if not self._face_encodings or not self._face_names:
            return
        
        try:
            self._label_encoder = LabelEncoder()
            encoded_labels = self._label_encoder.fit_transform(self._face_names)
            
            self._classifier = SVC(kernel='linear', probability=True)
            self._classifier.fit(self._face_encodings, encoded_labels)
            
            LOGGER.info("Face classifier trained with %d faces", len(self._face_encodings))
            
        except Exception as exc:
            LOGGER.exception("Error training face classifier: %s", exc)

    def get_known_faces(self) -> List[Dict[str, any]]:
        """Get list of known faces."""
        return [
            {
                "name": face_data.name,
                "last_seen": face_data.last_seen,
                "confidence": face_data.confidence,
                "image_path": face_data.image_path
            }
            for face_data in self._known_faces.values()
        ]

    def remove_face(self, name: str) -> bool:
        """Remove a face from the known faces database."""
        try:
            if name not in self._known_faces:
                return False
            
            # Remove from data structures
            face_data = self._known_faces.pop(name)
            
            # Remove from lists
            if name in self._face_names:
                idx = self._face_names.index(name)
                self._face_names.pop(idx)
                if idx < len(self._face_encodings):
                    self._face_encodings.pop(idx)
            
            # Remove image file
            if face_data.image_path and Path(face_data.image_path).exists():
                Path(face_data.image_path).unlink()
            
            # Retrain classifier
            if self._face_encodings:
                self._train_classifier()
            else:
                self._classifier = None
                self._label_encoder = None
            
            # Save to disk
            self._save_known_faces()
            
            LOGGER.info("Removed face for %s", name)
            return True
            
        except Exception as exc:
            LOGGER.exception("Error removing face for %s: %s", name, exc)
            return False

    def _load_known_faces(self) -> None:
        """Load known faces from disk."""
        try:
            faces_file = self._data_dir / "known_faces.json"
            if not faces_file.exists():
                return
            
            with open(faces_file, 'r') as f:
                data = json.load(f)
            
            for name, face_info in data.items():
                face_data = FaceData(
                    name=name,
                    encoding=np.array(face_info['encoding']),
                    confidence=face_info['confidence'],
                    last_seen=face_info['last_seen'],
                    image_path=face_info.get('image_path')
                )
                self._known_faces[name] = face_data
                self._face_encodings.append(face_data.encoding)
                self._face_names.append(name)
            
            if self._face_encodings:
                self._train_classifier()
            
            LOGGER.info("Loaded %d known faces", len(self._known_faces))
            
        except Exception as exc:
            LOGGER.exception("Error loading known faces: %s", exc)

    def _save_known_faces(self) -> None:
        """Save known faces to disk."""
        try:
            faces_file = self._data_dir / "known_faces.json"
            data = {}
            
            for name, face_data in self._known_faces.items():
                data[name] = {
                    'encoding': face_data.encoding.tolist(),
                    'confidence': face_data.confidence,
                    'last_seen': face_data.last_seen,
                    'image_path': face_data.image_path
                }
            
            with open(faces_file, 'w') as f:
                json.dump(data, f, indent=2)
            
            LOGGER.info("Saved %d known faces", len(self._known_faces))
            
        except Exception as exc:
            LOGGER.exception("Error saving known faces: %s", exc)

    def update_face_last_seen(self, name: str) -> None:
        """Update the last seen timestamp for a face."""
        if name in self._known_faces:
            self._known_faces[name].last_seen = time.time()
            self._save_known_faces()
