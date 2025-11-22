"""Inspect MobileFaceNet checkpoint structure"""
import torch

checkpoint_path = r"C:\Users\4bais\Vision-Based-Class-Attendance-System\FaceNet\mobilefacenet_arcface\best_model_epoch43_acc100.00.pth"

checkpoint = torch.load(checkpoint_path, map_location='cpu')

print("Checkpoint keys:")
if isinstance(checkpoint, dict):
    print(f"  Top-level keys: {checkpoint.keys()}")
    if 'model_state_dict' in checkpoint:
        state_dict = checkpoint['model_state_dict']
    else:
        state_dict = checkpoint
else:
    state_dict = checkpoint

print("\nModel layer names (first 20):")
for i, key in enumerate(list(state_dict.keys())[:20]):
    print(f"  {key}: {state_dict[key].shape}")

print(f"\nTotal layers: {len(state_dict.keys())}")

# Check for common layer patterns
conv_layers = [k for k in state_dict.keys() if 'conv' in k]
print(f"\nConv layers: {len(conv_layers)}")
print("Conv layer patterns:")
for k in conv_layers[:5]:
    print(f"  {k}")
