"""Test if load_state_dict with strict=False still raises on mismatches"""
import torch
from torch.nn import Module, Linear
import sys
sys.path.insert(0, r'C:\Users\4bais\Vision-Based-Class-Attendance-System\FaceNet')

from networks.models_facenet import MobileFaceNet

# Create model
model = MobileFaceNet(embedding_size=512)

# Load checkpoint
checkpoint_path = r"C:\Users\4bais\Vision-Based-Class-Attendance-System\FaceNet\mobilefacenet_arcface\best_model_epoch43_acc100.00.pth"
checkpoint = torch.load(checkpoint_path, map_location='cpu')

state_dict = checkpoint['model_state_dict']

print("Testing load_state_dict with strict=False...")
try:
    result = model.load_state_dict(state_dict, strict=False)
    print(f"✓ Success! Result: {type(result)}")
    if isinstance(result, tuple):
        missing, unexpected = result
        print(f"  Missing keys: {len(missing)}")
        print(f"  Unexpected keys: {len(unexpected)}")
except Exception as e:
    print(f"✗ Failed with error:")
    print(f"  {type(e).__name__}: {str(e)[:200]}...")
