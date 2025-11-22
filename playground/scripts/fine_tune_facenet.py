"""
Fine-tune FaceNet Model on Custom Faces
Adapts the pre-trained MobileFaceNet model to your specific dataset
"""

import sys
import os
import torch
import torch.nn as nn
import torch.optim as optim
from torch.utils.data import Dataset, DataLoader
from torchvision import transforms
from PIL import Image
import numpy as np
from tqdm import tqdm
import matplotlib.pyplot as plt
from datetime import datetime
import json

# Add FaceNet directory to path
sys.path.append('../FaceNet')

from networks.models_facenet import MobileFaceNet, Arcface, CosFace


class FaceDataset(Dataset):
    """
    Custom dataset for face images organized in folders by person
    
    Expected structure:
    data_dir/
        person1/
            img1.jpg
            img2.jpg
        person2/
            img1.jpg
            img2.jpg
    """
    
    def __init__(self, root_dir, transform=None):
        self.root_dir = root_dir
        self.transform = transform
        self.samples = []
        self.class_to_idx = {}
        self.idx_to_class = {}
        
        # Load all images and labels
        self._load_dataset()
    
    def _load_dataset(self):
        """Scan directory and build dataset"""
        classes = sorted([d for d in os.listdir(self.root_dir) 
                         if os.path.isdir(os.path.join(self.root_dir, d))])
        
        if len(classes) == 0:
            raise ValueError(f"No subdirectories found in {self.root_dir}")
        
        # Create class mappings
        self.class_to_idx = {cls_name: idx for idx, cls_name in enumerate(classes)}
        self.idx_to_class = {idx: cls_name for cls_name, idx in self.class_to_idx.items()}
        
        # Load all images
        for class_name in classes:
            class_dir = os.path.join(self.root_dir, class_name)
            class_idx = self.class_to_idx[class_name]
            
            for img_name in os.listdir(class_dir):
                if img_name.lower().endswith(('.png', '.jpg', '.jpeg', '.bmp')):
                    img_path = os.path.join(class_dir, img_name)
                    self.samples.append((img_path, class_idx))
        
        print(f"✓ Loaded {len(self.samples)} images from {len(classes)} classes")
        print(f"  Classes: {list(self.class_to_idx.keys())}")
    
    def __len__(self):
        return len(self.samples)
    
    def __getitem__(self, idx):
        img_path, label = self.samples[idx]
        
        # Load image
        image = Image.open(img_path).convert('RGB')
        
        # Apply transforms
        if self.transform:
            image = self.transform(image)
        
        return image, label
    
    def get_class_distribution(self):
        """Get number of samples per class"""
        distribution = {}
        for _, label in self.samples:
            class_name = self.idx_to_class[label]
            distribution[class_name] = distribution.get(class_name, 0) + 1
        return distribution


def get_transforms(train=True, img_size=112):
    """Get data augmentation transforms"""
    
    if train:
        # Training transforms with augmentation
        transform = transforms.Compose([
            transforms.Resize((img_size, img_size)),
            transforms.RandomHorizontalFlip(p=0.5),
            transforms.ColorJitter(brightness=0.2, contrast=0.2, saturation=0.1),
            transforms.RandomRotation(degrees=10),
            transforms.ToTensor(),
            transforms.Normalize(
                mean=[0.31928780674934387, 0.2873991131782532, 0.25779902935028076],
                std=[0.19799138605594635, 0.20757903158664703, 0.21088403463363647]
            )
        ])
    else:
        # Validation transforms without augmentation
        transform = transforms.Compose([
            transforms.Resize((img_size, img_size)),
            transforms.ToTensor(),
            transforms.Normalize(
                mean=[0.31928780674934387, 0.2873991131782532, 0.25779902935028076],
                std=[0.19799138605594635, 0.20757903158664703, 0.21088403463363647]
            )
        ])
    
    return transform


def split_dataset(dataset, train_ratio=0.8, seed=42):
    """Split dataset into train and validation sets"""
    
    torch.manual_seed(seed)
    
    dataset_size = len(dataset)
    train_size = int(train_ratio * dataset_size)
    val_size = dataset_size - train_size
    
    train_dataset, val_dataset = torch.utils.data.random_split(
        dataset, [train_size, val_size]
    )
    
    print(f"✓ Dataset split: {train_size} train, {val_size} validation")
    
    return train_dataset, val_dataset


def load_pretrained_model(checkpoint_path, num_classes, device='cuda', freeze_backbone=True):
    """
    Load pre-trained model and prepare for fine-tuning
    
    Args:
        checkpoint_path: Path to pretrained checkpoint
        num_classes: Number of classes in your dataset
        device: 'cuda' or 'cpu'
        freeze_backbone: If True, only train the classifier head
    
    Returns:
        backbone, classifier
    """
    
    print(f"Loading pretrained model from: {checkpoint_path}")
    
    embedding_size = 512
    
    # Load backbone
    backbone = MobileFaceNet(embedding_size=embedding_size).to(device)
    
    # Load pretrained weights
    checkpoint = torch.load(checkpoint_path, map_location=device)
    backbone.load_state_dict(checkpoint['model_state_dict'])
    
    print(f"✓ Loaded pretrained model (epoch {checkpoint.get('epoch', 'unknown')})")
    
    # Freeze backbone if requested
    if freeze_backbone:
        print("✓ Freezing backbone weights (only training classifier)")
        for param in backbone.parameters():
            param.requires_grad = False
    else:
        print("✓ Unfreezing backbone (full fine-tuning)")
        for param in backbone.parameters():
            param.requires_grad = True
    
    # Create new classifier for your dataset
    classifier = Arcface(embedding_size=embedding_size, classnum=num_classes).to(device)
    
    print(f"✓ Created new classifier head for {num_classes} classes")
    
    return backbone, classifier


def train_one_epoch(backbone, classifier, train_loader, criterion, optimizer, device):
    """Train for one epoch"""
    
    backbone.train() if any(p.requires_grad for p in backbone.parameters()) else backbone.eval()
    classifier.train()
    
    running_loss = 0.0
    correct = 0
    total = 0
    
    pbar = tqdm(train_loader, desc="Training")
    
    for images, labels in pbar:
        images = images.to(device)
        labels = labels.to(device)
        
        # Forward pass
        embeddings = backbone(images)
        # L2 normalize embeddings
        embeddings = torch.nn.functional.normalize(embeddings, p=2, dim=1)
        
        outputs = classifier(embeddings, labels)
        loss = criterion(outputs, labels)
        
        # Backward pass
        optimizer.zero_grad()
        loss.backward()
        optimizer.step()
        
        # Statistics
        running_loss += loss.item()
        _, predicted = outputs.max(1)
        total += labels.size(0)
        correct += predicted.eq(labels).sum().item()
        
        # Update progress bar
        pbar.set_postfix({
            'loss': f'{loss.item():.4f}',
            'acc': f'{100.*correct/total:.2f}%'
        })
    
    epoch_loss = running_loss / len(train_loader)
    epoch_acc = 100. * correct / total
    
    return epoch_loss, epoch_acc


def validate(backbone, classifier, val_loader, criterion, device):
    """Validate the model"""
    
    backbone.eval()
    classifier.eval()
    
    running_loss = 0.0
    correct = 0
    total = 0
    
    with torch.no_grad():
        for images, labels in tqdm(val_loader, desc="Validation"):
            images = images.to(device)
            labels = labels.to(device)
            
            # Forward pass
            embeddings = backbone(images)
            # L2 normalize embeddings
            embeddings = torch.nn.functional.normalize(embeddings, p=2, dim=1)
            
            outputs = classifier(embeddings, labels)
            loss = criterion(outputs, labels)
            
            # Statistics
            running_loss += loss.item()
            _, predicted = outputs.max(1)
            total += labels.size(0)
            correct += predicted.eq(labels).sum().item()
    
    epoch_loss = running_loss / len(val_loader)
    epoch_acc = 100. * correct / total
    
    return epoch_loss, epoch_acc


def plot_training_history(history, output_dir):
    """Plot training and validation metrics"""
    
    fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(15, 5))
    
    # Plot loss
    ax1.plot(history['train_loss'], label='Train Loss', marker='o')
    ax1.plot(history['val_loss'], label='Val Loss', marker='s')
    ax1.set_xlabel('Epoch')
    ax1.set_ylabel('Loss')
    ax1.set_title('Training and Validation Loss')
    ax1.legend()
    ax1.grid(True)
    
    # Plot accuracy
    ax2.plot(history['train_acc'], label='Train Acc', marker='o')
    ax2.plot(history['val_acc'], label='Val Acc', marker='s')
    ax2.set_xlabel('Epoch')
    ax2.set_ylabel('Accuracy (%)')
    ax2.set_title('Training and Validation Accuracy')
    ax2.legend()
    ax2.grid(True)
    
    plt.tight_layout()
    
    output_path = os.path.join(output_dir, 'training_history.png')
    plt.savefig(output_path, dpi=150, bbox_inches='tight')
    plt.close()
    
    print(f"✓ Saved training history plot: {output_path}")


def save_checkpoint(backbone, classifier, optimizer, epoch, best_acc, output_dir, is_best=False):
    """Save model checkpoint"""
    
    checkpoint = {
        'epoch': epoch,
        'backbone_state_dict': backbone.state_dict(),
        'classifier_state_dict': classifier.state_dict(),
        'optimizer_state_dict': optimizer.state_dict(),
        'best_acc': best_acc,
    }
    
    # Save latest checkpoint
    latest_path = os.path.join(output_dir, 'latest_checkpoint.pth')
    torch.save(checkpoint, latest_path)
    
    # Save best checkpoint
    if is_best:
        best_path = os.path.join(output_dir, f'best_model_epoch{epoch}_acc{best_acc:.2f}.pth')
        torch.save(checkpoint, best_path)
        print(f"✓ Saved best model: {best_path}")


def fine_tune(
    data_dir,
    pretrained_checkpoint,
    output_dir='./fine_tuned_model',
    num_epochs=50,
    batch_size=16,
    learning_rate=0.001,
    freeze_backbone=True,
    device='cuda',
    early_stopping_patience=10
):
    """
    Fine-tune the FaceNet model on your custom dataset
    
    Args:
        data_dir: Path to dataset directory
        pretrained_checkpoint: Path to pretrained model
        output_dir: Where to save fine-tuned model
        num_epochs: Number of training epochs
        batch_size: Batch size for training
        learning_rate: Learning rate
        freeze_backbone: If True, only train classifier head
        device: 'cuda' or 'cpu'
        early_stopping_patience: Stop if no improvement for N epochs
    """
    
    # Create output directory
    os.makedirs(output_dir, exist_ok=True)
    
    print("="*60)
    print("Fine-tuning FaceNet Model")
    print("="*60)
    print(f"Data directory: {data_dir}")
    print(f"Output directory: {output_dir}")
    print(f"Device: {device}")
    print(f"Freeze backbone: {freeze_backbone}")
    print("="*60)
    
    # Load dataset
    print("\nLoading dataset...")
    dataset = FaceDataset(root_dir=data_dir, transform=None)
    
    # Show class distribution
    print("\nClass distribution:")
    for class_name, count in dataset.get_class_distribution().items():
        print(f"  {class_name}: {count} images")
    
    # Split dataset
    train_dataset, val_dataset = split_dataset(dataset, train_ratio=0.8)
    
    # Apply transforms
    train_dataset.dataset.transform = get_transforms(train=True)
    val_dataset.dataset.transform = get_transforms(train=False)
    
    # Create data loaders
    train_loader = DataLoader(train_dataset, batch_size=batch_size, shuffle=True, num_workers=4)
    val_loader = DataLoader(val_dataset, batch_size=batch_size, shuffle=False, num_workers=4)
    
    # Load pretrained model
    num_classes = len(dataset.class_to_idx)
    backbone, classifier = load_pretrained_model(
        pretrained_checkpoint, 
        num_classes, 
        device, 
        freeze_backbone=freeze_backbone
    )
    
    # Setup training
    criterion = nn.CrossEntropyLoss()
    
    # Only optimize parameters that require gradients
    params_to_optimize = []
    params_to_optimize.extend([p for p in backbone.parameters() if p.requires_grad])
    params_to_optimize.extend(classifier.parameters())
    
    optimizer = optim.Adam(params_to_optimize, lr=learning_rate, weight_decay=5e-4)
    scheduler = optim.lr_scheduler.StepLR(optimizer, step_size=10, gamma=0.5)
    
    # Training history
    history = {
        'train_loss': [],
        'train_acc': [],
        'val_loss': [],
        'val_acc': []
    }
    
    # Early stopping
    best_acc = 0.0
    patience_counter = 0
    
    print(f"\nStarting training for {num_epochs} epochs...")
    print("="*60)
    
    # Training loop
    for epoch in range(1, num_epochs + 1):
        print(f"\nEpoch {epoch}/{num_epochs}")
        print("-" * 40)
        
        # Train
        train_loss, train_acc = train_one_epoch(
            backbone, classifier, train_loader, criterion, optimizer, device
        )
        
        # Validate
        val_loss, val_acc = validate(
            backbone, classifier, val_loader, criterion, device
        )
        
        # Update learning rate
        scheduler.step()
        
        # Save history
        history['train_loss'].append(train_loss)
        history['train_acc'].append(train_acc)
        history['val_loss'].append(val_loss)
        history['val_acc'].append(val_acc)
        
        # Print epoch summary
        print(f"\nEpoch {epoch} Summary:")
        print(f"  Train Loss: {train_loss:.4f}, Train Acc: {train_acc:.2f}%")
        print(f"  Val Loss: {val_loss:.4f}, Val Acc: {val_acc:.2f}%")
        print(f"  Learning Rate: {optimizer.param_groups[0]['lr']:.6f}")
        
        # Save checkpoint
        is_best = val_acc > best_acc
        if is_best:
            best_acc = val_acc
            patience_counter = 0
            print(f"  🎉 New best accuracy: {best_acc:.2f}%")
        else:
            patience_counter += 1
        
        save_checkpoint(backbone, classifier, optimizer, epoch, best_acc, output_dir, is_best)
        
        # Early stopping
        if patience_counter >= early_stopping_patience:
            print(f"\n⚠️  Early stopping: No improvement for {early_stopping_patience} epochs")
            break
    
    # Save training history
    print("\n" + "="*60)
    print("Training completed!")
    print(f"Best validation accuracy: {best_acc:.2f}%")
    print("="*60)
    
    # Plot history
    plot_training_history(history, output_dir)
    
    # Save training config
    config = {
        'data_dir': data_dir,
        'num_classes': num_classes,
        'class_to_idx': dataset.class_to_idx,
        'idx_to_class': dataset.idx_to_class,
        'num_epochs': epoch,
        'batch_size': batch_size,
        'learning_rate': learning_rate,
        'freeze_backbone': freeze_backbone,
        'best_accuracy': best_acc,
        'final_train_acc': train_acc,
        'timestamp': datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    }
    
    config_path = os.path.join(output_dir, 'training_config.json')
    with open(config_path, 'w') as f:
        json.dump(config, f, indent=2)
    
    print(f"\n✓ Saved training config: {config_path}")
    print(f"✓ All outputs saved to: {output_dir}")
    
    return backbone, classifier, history


def main():
    """Main function"""
    
    # ============ CONFIGURATION ============
    DATA_DIR = '../backend/uploads/students'  # Your dataset directory
    PRETRAINED_CHECKPOINT = '../FaceNet/mobilefacenet_arcface/best_model_epoch43_acc100.00.pth'
    OUTPUT_DIR = './fine_tuned_model'
    
    # Training parameters
    NUM_EPOCHS = 50
    BATCH_SIZE = 16
    LEARNING_RATE = 0.001
    FREEZE_BACKBONE = True  # Set to False for full fine-tuning
    
    DEVICE = 'cuda' if torch.cuda.is_available() else 'cpu'
    EARLY_STOPPING_PATIENCE = 10
    # ======================================
    
    # Run fine-tuning
    fine_tune(
        data_dir=DATA_DIR,
        pretrained_checkpoint=PRETRAINED_CHECKPOINT,
        output_dir=OUTPUT_DIR,
        num_epochs=NUM_EPOCHS,
        batch_size=BATCH_SIZE,
        learning_rate=LEARNING_RATE,
        freeze_backbone=FREEZE_BACKBONE,
        device=DEVICE,
        early_stopping_patience=EARLY_STOPPING_PATIENCE
    )


if __name__ == "__main__":
    main()
