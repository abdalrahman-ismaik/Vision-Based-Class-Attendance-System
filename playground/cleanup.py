"""Clean up and retrain classifier"""
import os
import shutil

# Clean up old processed_faces
processed_dir = "../backend/processed_faces"
for item in os.listdir(processed_dir):
    item_path = os.path.join(processed_dir, item)
    if os.path.isdir(item_path):
        if not item.startswith("FP"):  # Keep only FP* students
            continue
        # Check if has embeddings
        embeddings_path = os.path.join(item_path, "embeddings.npy")
        if not os.path.exists(embeddings_path):
            print(f"Removing {item} (no embeddings)")
            shutil.rmtree(item_path)
        else:
            print(f"Keeping {item} (has embeddings)")

print("\n✅ Cleanup complete!")
print("\n💡 Now manually trigger processing for each student:")
print("   Use POST /api/students/{student_id}/process")
