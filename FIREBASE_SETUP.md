# Firebase Setup Guide - Hướng dẫn Thiết lập Firebase

## 🔧 Cấu hình Firestore Security Rules

**ĐÂY LÀ NGUYÊN NHÂN CHÍNH GÂY ĐăNG KÝ THẤT BẠI!**

Khi bạn đăng ký, app tạo user trong Firebase Auth, nhưng **Firestore Rules** có thể không cho phép lưu dữ liệu.

### Cách sửa:

1. **Đăng nhập vào Firebase Console**: https://console.firebase.google.com
2. **Chọn project**: `roomfinanceapp`
3. **Vào Firestore Database** → **Rules**
4. **Xóa rules hiện tại** (nếu quá hạn chế)
5. **Copy-paste các rules từ file `firestore.rules`** vào editor
6. **Click "Publish"**

### Rules quan trọng:

```firestore
// Cho phép users xác thực ghi dữ liệu của chính họ
match /users/{userId} {
  allow read, write: if request.auth.uid == userId;
}
```

---

## ✅ Nếu vẫn báo lỗi:

### Bước 1: Kiểm tra Console Log

Chạy app và mở **Android Studio Logcat** hoặc **Flutter DevTools**:

```bash
flutter run
```

Tìm message có chứa:
- `❌ LỖI FIRESTORE:`
- `Permission denied`
- `PERMISSION_DENIED`

### Bước 2: Kiểm tra Firebase Initialization

Đảm bảo `firebase_options.dart` có đúng credentials:
- Verify `projectId: 'roomfinanceapp'`
- Verify `authDomain` và `storageBucket` đúng

### Bước 3: Test Registration

1. Mở app → đi tới Register
2. Nhập test email: `test@example.com`
3. Mật khẩu: `Test@123456`
4. Nhập đầy đủ thông tin khác
5. Nhấn "Tạo tài khoản"
6. **Xem console log** để tìm lỗi chi tiết

---

## 🔑 Firebase Project Details

- **Project ID**: `roomfinanceapp`
- **Auth Domain**: `roomfinanceapp.firebaseapp.com`
- **Storage Bucket**: `roomfinanceapp.firebasestorage.app`

---

## 📋 Firestore Collections Structure

```
/users/{uid}
  - uid: string
  - fullName: string
  - email: string
  - role: "member" | "head"
  - createdAt: timestamp
  - lastLoginAt: timestamp
  - avatarUrl: string (optional)
  - phone: string (optional)
  - currentRoomId: string (optional)
  - fcmToken: string (optional)

/rooms/{roomId}
  - headId: string (uid của người tạo)
  - name: string
  - code: string
  - members: array
  - createdAt: timestamp

/rooms/{roomId}/expenses/{expenseId}
  - ...

/rooms/{roomId}/payments/{paymentId}
  - ...
```

---

## 🐛 Debugging Tips

### Xem Full Error Message

Mở file [lib/services/auth_service.dart](lib/services/auth_service.dart#L21) - console sẽ print lỗi chi tiết với emoji 🔴 nếu có vấn đề.

### Common Issues:

| Lỗi | Nguyên nhân | Cách sửa |
|-----|------------|---------|
| `Permission denied` | Firestore Rules quá hạn chế | Cập nhật rules |
| `email-already-in-use` | Email đã được đăng ký | Dùng email khác |
| `weak-password` | Mật khẩu < 6 ký tự | Nhập mật khẩu dài hơn |
| User tạo nhưng vẫn về Login | Firestore write thất bại | Kiểm tra rules |

---

## 📲 Test Flow

```
1. Register → Firebase Auth tạo user ✅
           → Firestore lưu user data ✅
           → app tự chuyển sang dashboard

2. Nếu fail ở bước 2 → console log sẽ hiện: ❌ LỖI FIRESTORE
```

Hãy **check console log** và **update Firestore rules** là xong!
