"""Quick status check and classifier training"""
import requests
import json

BASE_URL = "http://localhost:5000/api"

print("=" * 80)
print("📊 CHECKING PROCESSING STATUS")
print("=" * 80)

# Load database to check all students
try:
    with open('../backend/database.json', 'r') as f:
        db = json.load(f)
    
    completed = 0
    pending = 0
    failed = 0
    
    for student_id, info in db.items():
        status = info.get('processing_status', 'unknown')
        name = info.get('name', student_id)
        
        if status == 'completed':
            completed += 1
            samples = info.get('num_samples_total', 'N/A')
            poses = info.get('num_poses_captured', 'N/A')
            print(f"✅ {name}: {samples} samples from {poses} poses")
        elif status == 'pending':
            pending += 1
            print(f"⏳ {name}: pending")
        elif status == 'failed':
            failed += 1
            error = info.get('processing_error', 'Unknown error')
            print(f"❌ {name}: {error}")
    
    print(f"\n📊 Summary:")
    print(f"   ✅ Completed: {completed}")
    print(f"   ⏳ Pending: {pending}")
    print(f"   ❌ Failed: {failed}")
    
    if completed > 0:
        print("\n" + "=" * 80)
        print("🧠 TRAINING CLASSIFIER")
        print("=" * 80)
        
        response = requests.post(f"{BASE_URL}/students/train-classifier")
        
        if response.status_code == 200:
            result = response.json()
            print("✅ Classifier trained successfully!")
            
            metadata = result.get('metadata', {})
            print(f"\n📊 Training Results:")
            print(f"   👥 Students: {metadata.get('n_students', 'N/A')}")
            print(f"   🔢 Embeddings: {metadata.get('n_embeddings', 'N/A')}")
            print(f"   📈 Train Accuracy: {metadata.get('train_accuracy', 0):.2%}")
            print(f"   📉 Test Accuracy: {metadata.get('test_accuracy', 0):.2%}")
            print(f"   🕐 Trained at: {metadata.get('trained_at', 'N/A')}")
            print(f"   📁 Classifier saved: {result.get('classifier_path', 'N/A')}")
        else:
            print(f"❌ Training failed: {response.status_code}")
            print(f"   {response.json()}")
    else:
        print("\n⚠️  No completed students. Cannot train classifier.")
        
except FileNotFoundError:
    print("❌ Database not found. Make sure students are registered.")
except Exception as e:
    print(f"❌ Error: {e}")
