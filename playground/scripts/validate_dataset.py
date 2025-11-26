"""
Dataset Validator and Preparation Tool
Checks your dataset before fine-tuning and provides recommendations
"""

import os
from PIL import Image
import numpy as np
from collections import defaultdict


def validate_dataset(data_dir):
    """
    Validate dataset structure and quality
    
    Args:
        data_dir: Path to dataset directory
    """
    
    print("="*60)
    print("Dataset Validation Report")
    print("="*60)
    print(f"Dataset directory: {data_dir}\n")
    
    if not os.path.exists(data_dir):
        print(f"❌ ERROR: Directory not found: {data_dir}")
        return False
    
    # Get all subdirectories (classes)
    classes = [d for d in os.listdir(data_dir) 
               if os.path.isdir(os.path.join(data_dir, d))]
    
    if len(classes) == 0:
        print("❌ ERROR: No subdirectories found!")
        print("\nExpected structure:")
        print("  data_dir/")
        print("    person1/")
        print("      img1.jpg")
        print("    person2/")
        print("      img1.jpg")
        return False
    
    print(f"✓ Found {len(classes)} classes (people)\n")
    
    # Analyze each class
    class_stats = {}
    total_images = 0
    image_sizes = []
    issues = []
    
    for class_name in sorted(classes):
        class_dir = os.path.join(data_dir, class_name)
        
        # Get all image files
        images = [f for f in os.listdir(class_dir) 
                 if f.lower().endswith(('.png', '.jpg', '.jpeg', '.bmp'))]
        
        num_images = len(images)
        total_images += num_images
        
        class_stats[class_name] = {
            'num_images': num_images,
            'images': images,
            'sizes': []
        }
        
        # Check each image
        for img_name in images:
            img_path = os.path.join(class_dir, img_name)
            try:
                img = Image.open(img_path)
                width, height = img.size
                class_stats[class_name]['sizes'].append((width, height))
                image_sizes.append((width, height))
                
                # Check for issues
                if width < 50 or height < 50:
                    issues.append(f"⚠️  {class_name}/{img_name}: Very small ({width}x{height})")
                elif width < 100 or height < 100:
                    issues.append(f"⚠️  {class_name}/{img_name}: Small ({width}x{height})")
                
            except Exception as e:
                issues.append(f"❌ {class_name}/{img_name}: Cannot read - {str(e)}")
        
        # Warn about low image count
        if num_images < 3:
            issues.append(f"⚠️  {class_name}: Only {num_images} image(s) - recommend at least 3-5")
    
    # Print statistics
    print("Class Distribution:")
    print("-" * 60)
    print(f"{'Class Name':<30} {'Images':<10} {'Avg Size'}")
    print("-" * 60)
    
    for class_name in sorted(classes):
        stats = class_stats[class_name]
        num_images = stats['num_images']
        
        if stats['sizes']:
            avg_width = int(np.mean([s[0] for s in stats['sizes']]))
            avg_height = int(np.mean([s[1] for s in stats['sizes']]))
            avg_size = f"{avg_width}x{avg_height}"
        else:
            avg_size = "N/A"
        
        # Status indicator
        if num_images >= 5:
            status = "✓"
        elif num_images >= 3:
            status = "⚠️"
        else:
            status = "❌"
        
        print(f"{status} {class_name:<28} {num_images:<10} {avg_size}")
    
    print("-" * 60)
    print(f"Total: {len(classes)} classes, {total_images} images\n")
    
    # Overall statistics
    print("Dataset Statistics:")
    print("-" * 60)
    
    images_per_class = [stats['num_images'] for stats in class_stats.values()]
    print(f"  Average images per class: {np.mean(images_per_class):.1f}")
    print(f"  Min images per class: {min(images_per_class)}")
    print(f"  Max images per class: {max(images_per_class)}")
    
    if image_sizes:
        widths = [s[0] for s in image_sizes]
        heights = [s[1] for s in image_sizes]
        print(f"\n  Average image size: {int(np.mean(widths))}x{int(np.mean(heights))}")
        print(f"  Min image size: {min(widths)}x{min(heights)}")
        print(f"  Max image size: {max(widths)}x{max(heights)}")
    
    # Print issues
    if issues:
        print("\n" + "="*60)
        print("⚠️  Issues Found:")
        print("="*60)
        for issue in issues:
            print(issue)
    
    # Recommendations
    print("\n" + "="*60)
    print("📋 Recommendations:")
    print("="*60)
    
    # Check if dataset is too small
    if len(classes) < 5:
        print("⚠️  Small dataset (<5 classes)")
        print("   - Consider collecting more people for better generalization")
    
    # Check if too imbalanced
    if max(images_per_class) > 3 * min(images_per_class):
        print("⚠️  Imbalanced dataset")
        print("   - Try to have similar number of images per person")
        print(f"   - Current range: {min(images_per_class)}-{max(images_per_class)} images")
    
    # Check average images per class
    avg_images = np.mean(images_per_class)
    if avg_images < 3:
        print("❌ Insufficient images per person")
        print("   - Minimum recommended: 3-5 images per person")
        print("   - More images = better results")
    elif avg_images < 5:
        print("⚠️  Low number of images per person")
        print("   - Recommended: 5-10 images per person for good results")
        print("   - Use FREEZE_BACKBONE=True for training")
    elif avg_images < 10:
        print("✓ Good number of images per person")
        print("   - Can use FREEZE_BACKBONE=True (faster)")
        print("   - Or try FREEZE_BACKBONE=False (more accurate)")
    else:
        print("✓ Excellent dataset!")
        print("   - Recommended: FREEZE_BACKBONE=False for best results")
        print("   - Can use full fine-tuning")
    
    # Training recommendations
    print("\n📝 Suggested Training Configuration:")
    print("-" * 60)
    
    if avg_images < 5:
        print("  FREEZE_BACKBONE = True")
        print("  NUM_EPOCHS = 30")
        print("  BATCH_SIZE = 8")
        print("  LEARNING_RATE = 0.001")
    elif avg_images < 10:
        print("  FREEZE_BACKBONE = True  # or False for better results")
        print("  NUM_EPOCHS = 50")
        print("  BATCH_SIZE = 16")
        print("  LEARNING_RATE = 0.001  # or 0.0001 if unfreezing")
    else:
        print("  FREEZE_BACKBONE = False")
        print("  NUM_EPOCHS = 100")
        print("  BATCH_SIZE = 16")
        print("  LEARNING_RATE = 0.0001")
    
    # Split recommendation
    train_size = int(0.8 * total_images)
    val_size = total_images - train_size
    print(f"\n  Expected split (80/20):")
    print(f"    Training: ~{train_size} images")
    print(f"    Validation: ~{val_size} images")
    
    if val_size < len(classes):
        print("\n  ⚠️  Warning: Validation set might not have samples from all classes")
        print("     Consider collecting more images")
    
    print("\n" + "="*60)
    
    # Final verdict
    if not issues or all("⚠️" in issue for issue in issues):
        print("✅ Dataset is ready for fine-tuning!")
    else:
        print("⚠️  Please address the issues above before training")
    
    print("="*60)
    
    return len([i for i in issues if i.startswith("❌")]) == 0


def show_sample_images(data_dir, num_samples=3):
    """Show sample images from each class"""
    
    try:
        import matplotlib.pyplot as plt
        from matplotlib.patches import Rectangle
        
        classes = sorted([d for d in os.listdir(data_dir) 
                         if os.path.isdir(os.path.join(data_dir, d))])
        
        print(f"\nDisplaying {num_samples} sample images from each class...")
        
        for class_name in classes[:5]:  # Show first 5 classes max
            class_dir = os.path.join(data_dir, class_name)
            images = [f for f in os.listdir(class_dir) 
                     if f.lower().endswith(('.png', '.jpg', '.jpeg', '.bmp'))]
            
            samples = images[:min(num_samples, len(images))]
            
            fig, axes = plt.subplots(1, len(samples), figsize=(4*len(samples), 4))
            if len(samples) == 1:
                axes = [axes]
            
            fig.suptitle(f'Class: {class_name}', fontsize=14, weight='bold')
            
            for i, img_name in enumerate(samples):
                img_path = os.path.join(class_dir, img_name)
                img = Image.open(img_path)
                
                axes[i].imshow(img)
                axes[i].axis('off')
                axes[i].set_title(f'{img.size[0]}x{img.size[1]}', fontsize=10)
            
            plt.tight_layout()
            plt.show()
            
    except ImportError:
        print("⚠️  Matplotlib not available - skipping visualization")


def main():
    """Main function"""
    
    # Configuration
    DATA_DIR = '../backend/uploads/students'  # Change this to your dataset path
    
    # Validate dataset
    is_valid = validate_dataset(DATA_DIR)
    
    # Optionally show sample images
    # show_sample_images(DATA_DIR, num_samples=3)
    
    if is_valid:
        print("\n✅ You can now run: python fine_tune_facenet.py")
    else:
        print("\n⚠️  Please fix the issues before training")


if __name__ == "__main__":
    main()
