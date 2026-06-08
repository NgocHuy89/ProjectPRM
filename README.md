# room_finance_app

A Flutter app for managing shared room finances - Ứng dụng quản lý chi tiêu chung phòng trọ.

## 🚀 Quick Start / Hướng dẫn nhanh

### 📲 If Registration Fails / Nếu Đăng ký Thất bại

**The main issue is Firestore Security Rules!**

**Vấn đề chính là Firestore Security Rules!**

👉 **Xem chi tiết tại**: [FIREBASE_SETUP.md](FIREBASE_SETUP.md)

**Quick Fix / Cách sửa nhanh:**

1. Go to https://console.firebase.google.com
2. Select project: `roomfinanceapp`
3. Go to **Firestore Database** → **Rules** tab
4. Copy rules from `firestore.rules` file
5. Paste and **Publish**

---

### ⚙️ Setup Steps

1. **Install Flutter**: https://flutter.dev/docs/get-started/install

2. **Clone & Setup**:
```bash
flutter clean
flutter pub get
```

3. **Run App**:
```bash
flutter run
```

4. **Update Firestore Rules** (See FIREBASE_SETUP.md)

---

### 📦 Firebase Configuration

- **Project ID**: `roomfinanceapp`
- **Auth Domain**: `roomfinanceapp.firebaseapp.com`
- **Database**: Cloud Firestore
- **Storage**: Firebase Storage

Current platform configs:
- ✅ Android
- ✅ iOS  
- ✅ Web
- ✅ Windows
- ✅ macOS

---

### 🐛 Debugging

Check console output for detailed error messages with emojis:
- 📝 = Starting operation
- ✅ = Success
- ❌ = Error (Lỗi)
- 💾 = Saving to Firestore
- ⚠️ = Warning

**Run with logs**:
```bash
flutter run -v
```

---

## 📋 Project Structure

```
lib/
├── main.dart              # Entry point + AuthGate
├── screens/
│   ├── auth/             # Login, Register, Forgot Password
│   ├── room/             # Create/Join Room
│   └── dashboard/        # Head & Member Dashboards
├── services/             # Firebase services
├── models/               # Data models
├── widgets/              # Reusable components
└── utils/                # Theme & helpers
```

---

## 📚 For More Info / Để biết thêm

See full setup guide: [FIREBASE_SETUP.md](FIREBASE_SETUP.md)

---

## Resources

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Firebase for Flutter](https://firebase.flutter.dev/)
- [Firestore Security Rules](https://firebase.google.com/docs/firestore/security/get-started)
