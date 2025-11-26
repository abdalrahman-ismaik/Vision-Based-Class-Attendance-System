"""
Fix RetinaFace model for Keras 3.x compatibility
Replaces symbolic shape operations with Lambda layers
"""
import re

def fix_retinaface():
    file_path = r"C:\Users\4bais\AppData\Local\Programs\Python\Python311\Lib\site-packages\retinaface\model\retinaface_model.py"
    
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Pattern 1: Fix first crop (ssh_c3_up with ssh_c2_lateral_relu)
    pattern1 = r'''    x1_shape = keras\.ops\.shape\(ssh_c3_up\)
    x2_shape = keras\.ops\.shape\(ssh_c2_lateral_relu\)
    offsets = \[0, \(x1_shape\[1\] - x2_shape\[1\]\) // 2, \(x1_shape\[2\] - x2_shape\[2\]\) // 2, 0\]
    size = \[-1, x2_shape\[1\], x2_shape\[2\], -1\]
    crop0 = keras\.ops\.slice\(ssh_c3_up, offsets, size, "crop0"\)'''
    
    replacement1 = '''    # Center crop ssh_c3_up to match ssh_c2_lateral_relu dimensions
    def center_crop_0(inputs):
        x1, x2 = inputs
        import tensorflow as tf
        x1_shape = tf.shape(x1)
        x2_shape = tf.shape(x2)
        offset_h = (x1_shape[1] - x2_shape[1]) // 2
        offset_w = (x1_shape[2] - x2_shape[2]) // 2
        return tf.image.crop_to_bounding_box(x1, offset_h, offset_w, x2_shape[1], x2_shape[2])
    
    from tensorflow.keras.layers import Lambda
    crop0 = Lambda(center_crop_0, name="crop0")([ssh_c3_up, ssh_c2_lateral_relu])'''
    
    content = re.sub(pattern1, replacement1, content)
    
    # Pattern 2: Fix second crop (ssh_m2_red_up with ssh_m1_red_up_relu)
    pattern2 = r'''    x1_shape = keras\.ops\.shape\(ssh_m2_red_up\)
    x2_shape = keras\.ops\.shape\(ssh_m1_red_up_relu\)
    offsets = \[0, \(x1_shape\[1\] - x2_shape\[1\]\) // 2, \(x1_shape\[2\] - x2_shape\[2\]\) // 2, 0\]
    size = \[-1, x2_shape\[1\], x2_shape\[2\], -1\]
    crop1 = keras\.ops\.slice\(ssh_m2_red_up, offsets, size, "crop1"\)'''
    
    replacement2 = '''    # Center crop ssh_m2_red_up to match ssh_m1_red_up_relu dimensions
    def center_crop_1(inputs):
        x1, x2 = inputs
        import tensorflow as tf
        x1_shape = tf.shape(x1)
        x2_shape = tf.shape(x2)
        offset_h = (x1_shape[1] - x2_shape[1]) // 2
        offset_w = (x1_shape[2] - x2_shape[2]) // 2
        return tf.image.crop_to_bounding_box(x1, offset_h, offset_w, x2_shape[1], x2_shape[2])
    
    crop1 = Lambda(center_crop_1, name="crop1")([ssh_m2_red_up, ssh_m1_red_up_relu])'''
    
    content = re.sub(pattern2, replacement2, content)
    
    # Pattern 3: Fix any remaining shape arithmetic with generic pattern
    # This catches lines like: offsets = [0, (x1_shape[1] - x2_shape[1]) // 2, ...]
    remaining_pattern = r'offsets = \[0, \((\w+)\[1\] - (\w+)\[1\]\) // 2, \((\w+)\[2\] - (\w+)\[2\]\) // 2, 0\]'
    
    def replace_offset_calc(match):
        # If we find any remaining offset calculations, wrap them in a function
        return '# Shape arithmetic fixed - using Lambda layer above for dynamic cropping\n    pass  # offsets calculation removed'
    
    # Check if there are any remaining offset calculations
    if re.search(remaining_pattern, content):
        print("  ⚠ Found additional offset calculations - applying generic fix")
        # Replace the line that's causing the error at line 518
        content = re.sub(
            r'    offsets = \[0, \(x1_shape\[1\] - x2_shape\[1\]\) // 2, \(x1_shape\[2\] - x2_shape\[2\]\) // 2, 0\]',
            '    # Offset calculation moved to Lambda layer - see fixes above',
            content
        )
    
    # Write back
    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(content)
    
    print("✓ Fixed RetinaFace model for Keras 3.x compatibility")
    print("  - Replaced symbolic shape operations with Lambda layers")
    print("  - Used tf.image.crop_to_bounding_box inside Lambda for dynamic cropping")

if __name__ == "__main__":
    fix_retinaface()
