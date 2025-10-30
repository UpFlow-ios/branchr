# ☁️ Branchr Phase 13 – Cloud & Cross-Device Sync (iCloud + Watch Support)

**Objective:**  
Enable Branchr to automatically back up and sync:
- ✅ ride history (distance, duration, calories)
- ✅ active mode (Ride, Camp, Study, Caravan)
- ✅ AI preferences / voice assistant settings
- ✅ achievements & stats  

across **iPhone, iPad, and Apple Watch** using **CloudKit + App Groups**.

---

## ⚙️ Core Features
1. **RideCloudSyncService.swift** – handles iCloud push/pull via CloudKit  
2. **UserPreferenceSyncManager.swift** – syncs ModeManager and AI settings through App Groups  
3. **CloudStatusBannerView.swift** – small UI banner showing sync status  
4. **Apple Watch Companion** – base WCSession bridge for mode updates  

---

## 📂 Folder Structure

~/Documents/branchr/
│
├── Services/
│   ├── RideCloudSyncService.swift
│   ├── UserPreferenceSyncManager.swift
│   └── WatchConnectivityService.swift
│
└── Views/
└── CloudStatusBannerView.swift

---

## 🧱 1️⃣ RideCloudSyncService.swift
Handles storing and fetching rides from CloudKit.

```swift
import Foundation
import CloudKit
import Combine

final class RideCloudSyncService: ObservableObject {
    static let shared = RideCloudSyncService()
    private let container = CKContainer.default()
    private let privateDB = CKContainer.default().privateCloudDatabase
    
    @Published var isSyncing = false
    @Published var lastSync: Date? = nil
    
    func uploadRide(distance: Double, duration: TimeInterval, calories: Double) {
        let record = CKRecord(recordType: "Ride")
        record["distance"] = distance
        record["duration"] = duration
        record["calories"] = calories
        record["date"] = Date()
        
        isSyncing = true
        privateDB.save(record) { [weak self] _, error in
            DispatchQueue.main.async {
                self?.isSyncing = false
                if let error = error {
                    print("❌ Ride upload failed: \(error.localizedDescription)")
                } else {
                    self?.lastSync = Date()
                    print("☁️ Ride synced to iCloud")
                }
            }
        }
    }
    
    func fetchRides(completion: @escaping ([CKRecord]) -> Void) {
        let query = CKQuery(recordType: "Ride", predicate: NSPredicate(value: true))
        privateDB.perform(query, inZoneWith: nil) { results, error in
            if let results = results {
                completion(results)
            } else {
                print("⚠️ Fetch error: \(error?.localizedDescription ?? "Unknown")")
                completion([])
            }
        }
    }
}
```

## 🧱 2️⃣ UserPreferenceSyncManager.swift

Keeps ModeManager and AI preferences consistent via App Groups.

```swift
import Foundation

final class UserPreferenceSyncManager {
    static let shared = UserPreferenceSyncManager()
    private let defaults = UserDefaults(suiteName: "group.com.joedormond.branchr")!
    
    func savePreferences(mode: BranchrMode, aiVoice: String) {
        defaults.set(mode.rawValue, forKey: "activeMode")
        defaults.set(aiVoice, forKey: "aiVoice")
        defaults.synchronize()
        print("💾 Preferences synced to App Group")
    }
    
    func loadPreferences() -> (BranchrMode, String) {
        let modeRaw = defaults.string(forKey: "activeMode") ?? BranchrMode.ride.rawValue
        let mode = BranchrMode(rawValue: modeRaw) ?? .ride
        let aiVoice = defaults.string(forKey: "aiVoice") ?? "coach"
        return (mode, aiVoice)
    }
}
```

## 🧱 3️⃣ WatchConnectivityService.swift

Bridges iPhone ↔ Watch via WCSession.

```swift
import Foundation
import WatchConnectivity

final class WatchConnectivityService: NSObject, WCSessionDelegate, ObservableObject {
    static let shared = WatchConnectivityService()
    
    override init() {
        super.init()
        if WCSession.isSupported() {
            WCSession.default.delegate = self
            WCSession.default.activate()
        }
    }
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        print("⌚ Watch session activated: \(activationState.rawValue)")
    }
    
    func sendModeUpdate(_ mode: BranchrMode) {
        guard WCSession.default.isReachable else { return }
        WCSession.default.sendMessage(["mode": mode.rawValue], replyHandler: nil)
        print("📡 Mode sent to watch: \(mode.rawValue)")
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        if let modeStr = message["mode"] as? String,
           let mode = BranchrMode(rawValue: modeStr) {
            ModeManager.shared.setMode(mode)
            print("⌚ Mode received from watch: \(modeStr)")
        }
    }
}
```

## 🧱 4️⃣ CloudStatusBannerView.swift

UI indicator for sync status.

```swift
import SwiftUI

struct CloudStatusBannerView: View {
    @ObservedObject var syncService = RideCloudSyncService.shared
    
    var body: some View {
        HStack {
            if syncService.isSyncing {
                ProgressView().tint(.white)
                Text("Syncing to iCloud…")
                    .font(.caption)
                    .foregroundColor(.white)
            } else {
                Image(systemName: "icloud.and.arrow.up")
                    .foregroundColor(.white)
                Text("Last sync: \(syncService.lastSync?.formatted(date: .abbreviated, time: .shortened) ?? "Never")")
                    .font(.caption)
                    .foregroundColor(.white)
            }
            Spacer()
        }
        .padding(8)
        .background(.blue.opacity(0.7))
        .cornerRadius(10)
        .padding(.horizontal)
    }
}
```

---

## 🧩 Info.plist Additions

```xml
<key>NSUbiquitousContainers</key>
<dict>
  <key>iCloud.com.joedormond.branchr</key>
  <dict>
    <key>NSUbiquitousContainerIsDocumentScopePublic</key><true/>
    <key>NSUbiquitousContainerName</key><string>Branchr Cloud</string>
  </dict>
</dict>
<key>UIBackgroundModes</key>
<array>
  <string>remote-notification</string>
  <string>fetch</string>
</array>
```

## ⚙️ Build Steps
1. **Enable iCloud**
   • In Xcode ▸ Project ▸ Signing & Capabilities ▸ + Capability ▸ iCloud (Storage + CloudKit)
2. **Add App Group**
   • group.com.joedormond.branchr

3. **Clean and Build**
   Product ▸ Clean Build Folder (⇧⌘K)
   Product ▸ Build (⌘B)
   Product ▸ Run (⌘R)

4. **Watch the console:**
   • "☁️ Ride synced to iCloud"
   • "💾 Preferences synced to App Group"
   • "📡 Mode sent to watch: Ride"

---

## 🧪 Testing Checklist

✅ Run on real device with iCloud signed in
✅ Toggle modes – see updates on another device
✅ Record a ride – fetch on iPad (simulator OK)
✅ Watch mode update logs mirror iPhone

---

## ✅ Success Criteria
• iCloud Drive + CloudKit sync rides and preferences
• App Group keeps voice AI settings shared
• Apple Watch receives mode updates instantly
• Build = 0 errors, 0 warnings

After build success, commit:

```bash
git add .
git commit -m "Phase 13 – Cloud & Cross-Device Sync (iCloud + Watch integration)"
git push
```

🚀 **Next Phase**

Next up is Phase 14 – Advanced AI & Machine Learning Integration!
