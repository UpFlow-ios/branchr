//
//  AutoModeDetectionService.swift
//  Branchr
//
//  Created by Joe Dormond on 2025-10-24.
//

import Foundation
import CoreMotion
import Combine

final class AutoModeDetectionService: ObservableObject {
    static let shared = AutoModeDetectionService()
    
    private let motionManager = CMMotionActivityManager()
    @Published var suggestedMode: BranchrMode? = nil
    
    func startMonitoring() {
        guard CMMotionActivityManager.isActivityAvailable() else {
            print("⚠️ Motion detection not available")
            return
        }
        
        motionManager.startActivityUpdates(to: OperationQueue.main) { [weak self] activity in
            guard let self = self, let act = activity else { return }
            
            if act.cycling {
                self.suggestedMode = .ride
            } else if act.walking {
                self.suggestedMode = .camp
            } else if act.stationary {
                self.suggestedMode = .study
            } else if act.automotive {
                self.suggestedMode = .caravan
            } else {
                self.suggestedMode = nil
            }
            
            if let mode = self.suggestedMode {
                print("🤖 Suggested mode: \(mode.rawValue.capitalized)")
            }
        }
    }
    
    func stopMonitoring() {
        motionManager.stopActivityUpdates()
        print("🛑 Mode detection stopped")
    }
}
