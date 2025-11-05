# Student Registration Validation Rules

## Global Validation Rules

These validation rules are enforced throughout the HADIR application to ensure data consistency and compliance with Khalifa University standards.

### 1. Student ID Format

**Rule:** Student ID must always have the `1000` prefix followed by exactly 5 digits.

**Implementation:**
- The `1000` prefix is **fixed and displayed** in the input field
- Users only enter the **last 5 digits** (e.g., `12345`)
- Full Student ID format: `1000XXXXX` where `X` is a digit
- Example: User enters `64692` → Full Student ID becomes `100064692`

**Validation:**
- Must be exactly 5 digits (numeric only)
- No letters or special characters allowed
- Cannot be empty

**User Experience:**
```
┌─────────────────────────────────────┐
│ Student ID *                        │
│ ┌─────────────────────────────────┐ │
│ │ 1000 | 12345                    │ │ ← User enters only these 5 digits
│ └─────────────────────────────────┘ │
│ Enter the last 5 digits             │
└─────────────────────────────────────┘
```

### 2. Email Address Format

**Rule:** Email is **automatically generated** from the Student ID and **cannot be edited** by the user.

**Format:** `{FULL_STUDENT_ID}@ku.ac.ae`

**Implementation:**
- Email field is **read-only** (users cannot edit it)
- Email is auto-generated when user enters valid 5 digits
- Email updates in real-time as user types the Student ID
- Domain is always `@ku.ac.ae` (Khalifa University official domain)

**Examples:**
| Student ID Entered | Full Student ID | Generated Email |
|-------------------|-----------------|-----------------|
| 12345 | 100012345 | 100012345@ku.ac.ae |
| 64692 | 100064692 | 100064692@ku.ac.ae |
| 98765 | 100098765 | 100098765@ku.ac.ae |

**Validation:**
- Format must match: `1000\d{5}@ku\.ac\.ae`
- Automatically validated against Student ID
- Cannot be manually entered or modified

**User Experience:**
```
┌─────────────────────────────────────┐
│ Email Address *                     │
│ ┌─────────────────────────────────┐ │
│ │ 100012345@ku.ac.ae              │ │ ← Auto-generated, read-only
│ └─────────────────────────────────┘ │
│ Auto-generated from Student ID      │
└─────────────────────────────────────┘
```

## Code Implementation

### Student ID Field
```dart
TextFormField(
  controller: _studentIdController,
  decoration: InputDecoration(
    labelText: 'Student ID *',
    prefixIcon: const Icon(Icons.badge),
    prefixText: '1000',  // Fixed prefix
    border: const OutlineInputBorder(),
    helperText: 'Enter the last 5 digits (e.g., 64692)',
  ),
  keyboardType: TextInputType.number,
  maxLength: 5,  // Only 5 digits allowed
  onChanged: (value) {
    // Auto-generate email from student ID
    if (value.isNotEmpty && RegExp(r'^\d{5}$').hasMatch(value)) {
      final fullStudentId = '1000$value';
      _emailController.text = '$fullStudentId@ku.ac.ae';
    } else {
      _emailController.text = '';
    }
  },
  validator: (value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter the 5 digits after 1000';
    }
    if (!RegExp(r'^\d{5}$').hasMatch(value)) {
      return 'Please enter exactly 5 digits';
    }
    return null;
  },
)
```

### Email Field
```dart
TextFormField(
  controller: _emailController,
  decoration: const InputDecoration(
    labelText: 'Email Address *',
    prefixIcon: Icon(Icons.email),
    border: OutlineInputBorder(),
    helperText: 'Auto-generated from Student ID',
  ),
  readOnly: true,  // Users cannot edit
  style: TextStyle(color: Colors.grey[600]),  // Visual indicator
  validator: (value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter a valid student ID first';
    }
    if (!RegExp(r'^1000\d{5}@ku\.ac\.ae$').hasMatch(value)) {
      return 'Email format should be studentid@ku.ac.ae';
    }
    return null;
  },
)
```

### Full Student ID Construction
```dart
// When saving to database
final fullStudentId = '1000${_studentIdController.text}';

final student = Student(
  studentId: fullStudentId,  // Full ID with 1000 prefix
  email: _emailController.text,  // Auto-generated email
  // ... other fields
);
```

## Benefits

✅ **Data Consistency:** All student IDs follow the same format
✅ **Error Prevention:** Auto-generation prevents typos in email addresses
✅ **University Compliance:** Follows Khalifa University's ID and email standards
✅ **User-Friendly:** Reduces data entry burden
✅ **Validation:** Ensures only valid IDs and emails are accepted

## Testing

### Test Cases

1. **Valid Student ID Entry**
   - Input: `12345`
   - Expected Student ID: `100012345`
   - Expected Email: `100012345@ku.ac.ae`

2. **Invalid Student ID - Too Short**
   - Input: `1234`
   - Expected: Validation error "Please enter exactly 5 digits"

3. **Invalid Student ID - Too Long**
   - Input: `123456`
   - Expected: Input limited to 5 characters

4. **Invalid Student ID - Non-numeric**
   - Input: `12a45`
   - Expected: Only numeric input accepted

5. **Email Read-Only Enforcement**
   - Action: Attempt to edit email field
   - Expected: Field is not editable

6. **Email Auto-Generation**
   - Action: Type Student ID digits one by one
   - Expected: Email updates in real-time when 5 digits entered

## Development Mode

In development mode, mock data respects these rules:
```dart
_studentIdController.text = '12345';  // 5 digits only
_emailController.text = '100012345@ku.ac.ae';  // Auto-generated format
```

## Future Enhancements

- [ ] Add Student ID validation against university database
- [ ] Check for duplicate Student IDs before registration
- [ ] Add email verification step
- [ ] Support for guest/temporary IDs (different format)
