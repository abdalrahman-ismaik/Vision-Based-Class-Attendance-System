"""
Fix remaining RetinaFace shape arithmetic issue at line 518
"""

file_path = r"C:\Users\4bais\AppData\Local\Programs\Python\Python311\Lib\site-packages\retinaface\model\retinaface_model.py"

with open(file_path, 'r', encoding='utf-8') as f:
    lines = f.readlines()

# Find and fix the problematic section around line 518
# Looking for the pattern starting at line 516
for i in range(len(lines)):
    if i >= 515 and i <= 520:
        if 'x1_shape = keras.ops.shape(ssh_m2_red_up)' in lines[i]:
            print(f"Found at line {i+1}: {lines[i].strip()}")
            # Replace the 5-line block
            if i+4 < len(lines):
                original_block = ''.join(lines[i:i+5])
                print(f"\nOriginal block:\n{original_block}")
                
                # Replace with Lambda layer version
                new_block = '''    # Center crop ssh_m2_red_up to match ssh_m1_red_conv_relu dimensions
    from tensorflow.keras.layers import Lambda
    crop1 = Lambda(lambda x: tf.image.resize_with_crop_or_pad(x[0], tf.shape(x[1])[1], tf.shape(x[1])[2]), name="crop1")([ssh_m2_red_up, ssh_m1_red_conv_relu])
'''
                lines[i:i+5] = [new_block]
                print(f"\nReplaced with:\n{new_block}")
                break

# Write back
with open(file_path, 'w', encoding='utf-8') as f:
    f.writelines(lines)

print("\n✓ Fixed line 518 shape arithmetic issue")
