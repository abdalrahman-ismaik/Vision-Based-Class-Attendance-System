# Vision‑based Class Attendance Demo

This project demonstrates a simple vision‑based class attendance system.
It uses OpenCV for face detection, a user‑provided model for face
embedding, and cosine similarity to match against a gallery of
enrolled students.  The code is designed to be easy to integrate
with your own face recognition model.

## Directory structure

```
attendance_demo/
├── __init__.py
├── custom_embedder.py         # Implement your model here
├── detector.py                # Haar cascade face detector
├── gallery_utils.py           # Gallery loading and matching
├── gallery/
│   ├── __init__.py
│   └── enroll.py             # Script to build the gallery
├── realtime_demo.py           # Run the attendance demo with OpenCV
├── server.py                  # Optional Flask web server
├── templates/
│   └── index.html            # Web UI template
├── requirements.txt           # Python dependencies
└── README.md                  # This file
```

## Installation

Create a Python virtual environment and install the requirements:

```
python -m venv venv
source venv/bin/activate
pip install -r attendance_demo/requirements.txt
```

Note: The demo uses OpenCV's built‑in Haar cascade for face detection.
For production use, consider replacing this with a more accurate
detector (e.g. RetinaFace, MediaPipe Face Detection, or YOLOv8‑face).

## Enrolment

Prepare a directory of enrolment images organised by person.  Each
subdirectory name should be the label (e.g. student name or ID) and
contain one or more images of that person.  For example:

```
enroll_images/
├── alice/
│   ├── alice1.jpg
│   └── alice2.jpg
└── bob/
    ├── bob1.jpg
    └── bob2.jpg
```

Run the enrolment script to create a gallery file:

```
python -m attendance_demo.gallery.enroll --images_dir enroll_images --output attendance_demo/gallery.npz
```

This will detect faces, compute embeddings using your model
(``custom_embedder.embed_face``), and save them to
``attendance_demo/gallery.npz``.  If you see warnings about missing
faces, ensure your enrolment images are clear and front‑facing.

## Implementing your face model

Open ``attendance_demo/custom_embedder.py`` and replace the body of
``embed_face`` with code that runs your trained model and returns a
one‑dimensional NumPy array representing the face embedding.  See the
docstring in that file for detailed instructions.  The provided
placeholder flattens the image and is **not** suitable for
recognition.

## Running the real‑time demo

After building the gallery and implementing your model, you can run
the demo from a webcam or video file:

```
python -m attendance_demo.realtime_demo --gallery attendance_demo/gallery.npz --video_source 0 --display
```

Use ``--video_source`` to specify a camera index (``0`` by default)
or a path/URL to a video file or RTSP stream.  The ``--display``
flag shows the annotated video in a window.  You can also save the
annotated output to a file using ``--save output.mp4``.

## Running the web server

To expose the video stream via a web interface, run the Flask
server:

```
python -m attendance_demo.server --gallery attendance_demo/gallery.npz --video_source 0 --host 0.0.0.0 --port 5000
```

Open a browser and navigate to ``http://<host>:<port>/`` to view
the live stream.  The server annotates each frame on the fly.

## Notes

* The system currently uses a very simple Haar cascade for face
  detection.  For improved accuracy, consider replacing
  ``FaceDetector`` with a modern detector (e.g. RetinaFace, YOLOv8).
* Matching uses cosine similarity with a fixed threshold (default
  0.35).  You may need to tune this threshold based on your model's
  embedding properties and desired trade‑off between false accepts and
  false rejects.
* Real‑time performance will depend on your model's inference speed
  and the detection method.  If your model is slow, you might run
  detection and recognition on every nth frame or incorporate a
  tracking algorithm to avoid redundant computations.

Feel free to extend and modify the code to suit your project's
requirements.