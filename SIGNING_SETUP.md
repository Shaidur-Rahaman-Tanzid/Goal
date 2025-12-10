# GOAL App - Production Signing Setup

## Current Issue
Your app is currently signed with the debug key, but Play Store expects the production key with fingerprint:
**SHA1: B0:87:60:C5:98:7A:1F:50:00:76:08:BE:90:D3:E4:09:24:A7:B8:AB**

## Solution: Download Your Upload Key from Play Console

Since you've already uploaded a version with a specific key, you need to use the SAME key. Here's how:

### Option 1: Use Existing Upload Key (Recommended)

1. **Locate your existing upload keystore file** (upload-keystore.jks)
   - Check your previous development machine
   - Check backup locations
   - Check email if you sent it to yourself

2. **Copy the keystore to your project:**
   ```powershell
   Copy-Item "path\to\your\upload-keystore.jks" "e:\test_projects\android\app\upload-keystore.jks"
   ```

3. **Update key.properties with YOUR actual passwords:**
   Edit `e:\test_projects\android\key.properties`:
   ```
   storePassword=YOUR_ACTUAL_STORE_PASSWORD
   keyPassword=YOUR_ACTUAL_KEY_PASSWORD
   keyAlias=upload
   storeFile=upload-keystore.jks
   ```

4. **Build the AAB:**
   ```powershell
   cd e:\test_projects
   flutter build appbundle
   ```

### Option 2: If You Lost the Key - Use Play App Signing

If you can't find your original key:

1. **Go to Play Console** → Your App → Setup → App Integrity
2. **Enroll in Play App Signing** (if not already)
3. **Reset your upload key:**
   - Generate a new upload key
   - Request Google to accept the new key

### Generate New Upload Key (if resetting)

```powershell
cd e:\test_projects\android\app
keytool -genkeypair -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

You'll be prompted for:
- Keystore password (create a strong password)
- Key password (can be same as keystore password)
- Your name, organization, etc.

**IMPORTANT:** Write down these passwords securely!

### Verify Key Fingerprint

To check if your key matches:
```powershell
keytool -list -v -keystore e:\test_projects\android\app\upload-keystore.jks -alias upload
```

Look for the SHA1 fingerprint and compare with Play Console.

## Current Configuration Status

✅ Build configuration updated to use production signing
✅ key.properties file created (you need to add real passwords)
✅ Version bumped to 1.0.2+2
❌ Upload keystore file needed (upload-keystore.jks)
❌ Real passwords needed in key.properties

## Next Steps

1. Find or generate your upload keystore
2. Update key.properties with real passwords
3. Run: `flutter build appbundle`
4. Upload the new AAB to Play Console
