# 🎯 Step 2: Replace Default Files - EXACT COPY-PASTE GUIDE

## 📋 **What You Need to Copy-Paste**

### **2.1: BranchrWidget.swift Content**
Copy this EXACT content and replace the default file:

```swift
//
//  BranchrWidget.swift
//  BranchrWidgetExtension
//
//  Created by Joe Dormond on 2025-10-24.
//

import WidgetKit
import SwiftUI

// MARK: - Widget Entry
struct BranchrWidgetEntry: TimelineEntry {
    let date: Date
    let mode: BranchrMode
    let distance: Double
    let duration: TimeInterval
    let calories: Double
    let isActive: Bool
}

// MARK: - Timeline Provider
struct BranchrWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> BranchrWidgetEntry {
        BranchrWidgetEntry(
            date: Date(),
            mode: .ride,
            distance: 2.4,
            duration: 800,
            calories: 120,
            isActive: true
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (BranchrWidgetEntry) -> ()) {
        let entry = BranchrWidgetEntry(
            date: Date(),
            mode: .ride,
            distance: 2.4,
            duration: 800,
            calories: 120,
            isActive: true
        )
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<BranchrWidgetEntry>) -> ()) {
        // Get current mode from App Groups
        let defaults = UserDefaults(suiteName: "group.com.joedormond.branchr")
        let modeString = defaults?.string(forKey: "branchrActiveMode") ?? "ride"
        let currentMode = BranchrMode(rawValue: modeString) ?? .ride
        
        // Create entry with current data
        let entry = BranchrWidgetEntry(
            date: Date(),
            mode: currentMode,
            distance: 2.4, // TODO: Get from ride data
            duration: 800, // TODO: Get from ride data
            calories: 120, // TODO: Get from ride data
            isActive: true
        )
        
        // Update every 10 minutes
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 10, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}

// MARK: - Widget View
struct BranchrWidgetView: View {
    var entry: BranchrWidgetProvider.Entry
    
    var body: some View {
        ZStack {
            // Dynamic background based on mode
            LinearGradient(
                colors: [
                    entry.mode.themeColor.opacity(0.8),
                    .black.opacity(0.9)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 8) {
                // Mode Icon and Name
                HStack {
                    Text(entry.mode.icon)
                        .font(.system(size: 24))
                    
                    Text(entry.mode.displayName)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    // Active indicator
                    Circle()
                        .fill(entry.isActive ? .green : .gray)
                        .frame(width: 8, height: 8)
                }
                
                // Stats
                VStack(spacing: 4) {
                    HStack {
                        Text(String(format: "%.1f mi", entry.distance))
                            .font(.caption)
                            .foregroundColor(.white)
                        
                        Text("•")
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        Text(String(format: "%d min", Int(entry.duration / 60)))
                            .font(.caption)
                            .foregroundColor(.white)
                        
                        Text("•")
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        Text(String(format: "%.0f cal", entry.calories))
                            .font(.caption)
                            .foregroundColor(.white)
                    }
                }
                
                Spacer()
            }
            .padding()
        }
    }
}

// MARK: - Widget Configuration
struct BranchrWidget: Widget {
    let kind: String = "BranchrWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: BranchrWidgetProvider()) { entry in
            BranchrWidgetView(entry: entry)
        }
        .configurationDisplayName("Branchr Status")
        .description("Shows your current Branchr mode and ride info.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - Preview
struct BranchrWidget_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            BranchrWidgetView(
                entry: BranchrWidgetEntry(
                    date: Date(),
                    mode: .ride,
                    distance: 2.4,
                    duration: 600,
                    calories: 120,
                    isActive: true
                )
            )
            .previewContext(WidgetPreviewContext(family: .systemSmall))
            .previewDisplayName("Small Widget")
            
            BranchrWidgetView(
                entry: BranchrWidgetEntry(
                    date: Date(),
                    mode: .camp,
                    distance: 5.2,
                    duration: 1200,
                    calories: 280,
                    isActive: false
                )
            )
            .previewContext(WidgetPreviewContext(family: .systemMedium))
            .previewDisplayName("Medium Widget")
        }
    }
}
```

### **2.2: BranchrWidgetBundle.swift Content**
Copy this EXACT content and replace the default file:

```swift
//
//  BranchrWidgetBundle.swift
//  BranchrWidgetExtension
//
//  Created by Joe Dormond on 2025-10-24.
//

import WidgetKit
import SwiftUI

@main
struct BranchrWidgetBundle: WidgetBundle {
    var body: some Widget {
        BranchrWidget()
    }
}
```

### **2.3: SharedModels.swift Content**
Copy this EXACT content for the new file:

```swift
//
//  SharedModels.swift
//  BranchrWidgetExtension
//
//  Created by Joe Dormond on 2025-10-24.
//

import SwiftUI

/// Defines different operational modes for Branchr.
/// This is a copy of the enum from the main app for widget access.
enum BranchrMode: String, Codable, CaseIterable {
    case ride, camp, study, caravan
    
    var displayName: String {
        switch self {
        case .ride: return "Ride Mode"
        case .camp: return "Camp Mode"
        case .study: return "Study Mode"
        case .caravan: return "Caravan Mode"
        }
    }
    
    var icon: String {
        switch self {
        case .ride: return "🚴‍♂️"
        case .camp: return "🏕️"
        case .study: return "🎓"
        case .caravan: return "🚗"
        }
    }
    
    var themeColor: Color {
        switch self {
        case .ride: return .blue
        case .camp: return .green
        case .study: return .purple
        case .caravan: return .orange
        }
    }
}
```

## 📋 **Step-by-Step Instructions**

1. **Open Xcode** with your Branchr project
2. **Find `BranchrWidgetExtension` folder** in Project Navigator
3. **Click `BranchrWidget.swift`** → Select All (Cmd+A) → Delete → Paste content from 2.1
4. **Click `BranchrWidgetBundle.swift`** → Select All (Cmd+A) → Delete → Paste content from 2.2
5. **Right-click `BranchrWidgetExtension` folder** → Add Files → Select `SharedModels.swift` → Add
6. **Verify all 3 files** are in the `BranchrWidgetExtension` target

## ✅ **Verification Checklist**
- [ ] BranchrWidget.swift contains our implementation
- [ ] BranchrWidgetBundle.swift contains our implementation  
- [ ] SharedModels.swift is added to widget target
- [ ] All files show in BranchrWidgetExtension folder
- [ ] No build errors when selecting widget scheme

**When done, let me know and we'll move to Step 3!**
