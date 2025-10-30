//
//  WeightSettingsView.swift
//  branchr
//
//  Created by Joe Dormond on 10/23/25.
//

import SwiftUI

/// View for editing user weight settings
struct WeightSettingsView: View {
    
    // MARK: - Properties
    @ObservedObject var calorieCalculator: CalorieCalculator
    @Environment(\.dismiss) private var dismiss
    
    @State private var weight: Double
    @State private var isMetric: Bool = true
    
    // MARK: - Initialization
    init(calorieCalculator: CalorieCalculator) {
        self.calorieCalculator = calorieCalculator
        self._weight = State(initialValue: calorieCalculator.userWeight)
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "person.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.orange)
                    
                    Text("Weight Settings")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("Accurate weight helps calculate calories burned")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                }
                .padding(.top)
                
                // Current Weight Display
                VStack(spacing: 16) {
                    Text("Current Weight")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    HStack {
                        Text(isMetric ? calorieCalculator.formattedWeight : calorieCalculator.formattedWeightInPounds)
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Button(action: toggleUnit) {
                            Text(isMetric ? "lbs" : "kg")
                                .font(.caption)
                                .foregroundColor(.blue)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
                        }
                    }
                }
                .padding(20)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                
                // Weight Input
                VStack(spacing: 16) {
                    Text("Update Weight")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    HStack {
                        TextField("Weight", value: $weight, format: .number)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.center)
                        
                        Text(isMetric ? "kg" : "lbs")
                            .font(.body)
                            .foregroundColor(.gray)
                    }
                    
                    Text("Enter your weight for accurate calorie calculations")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                }
                .padding(20)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                
                // Calorie Impact Info
                VStack(spacing: 12) {
                    HStack {
                        Image(systemName: "info.circle")
                            .foregroundColor(.blue)
                        
                        Text("Calorie Impact")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        Spacer()
                    }
                    
                    VStack(spacing: 8) {
                        InfoRow(
                            title: "Moderate Cycling",
                            value: String(format: "%.0f cal/hr", calorieCalculator.getCalorieBurnRate(for: 5.0))
                        )
                        
                        InfoRow(
                            title: "Vigorous Cycling",
                            value: String(format: "%.0f cal/hr", calorieCalculator.getCalorieBurnRate(for: 7.0))
                        )
                        
                        InfoRow(
                            title: "Weekly Goal",
                            value: String(format: "%.0f cal", calorieCalculator.getWeeklyCalorieGoal())
                        )
                    }
                }
                .padding(20)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                
                Spacer()
            }
            .padding(.horizontal)
            .background(Color.black)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveWeight()
                    }
                    .foregroundColor(.blue)
                    .fontWeight(.semibold)
                }
            }
        }
        .onAppear {
            updateWeightDisplay()
        }
        .onChange(of: weight) { _ in
            updateWeightDisplay()
        }
    }
    
    // MARK: - Private Methods
    
    private func toggleUnit() {
        isMetric.toggle()
        updateWeightDisplay()
    }
    
    private func updateWeightDisplay() {
        if isMetric {
            // Convert from kg to lbs for display
            weight = calorieCalculator.userWeight * 2.20462
        } else {
            // Convert from lbs to kg for display
            weight = calorieCalculator.userWeight
        }
    }
    
    private func saveWeight() {
        let weightInKg: Double
        
        if isMetric {
            // Convert from lbs to kg
            weightInKg = weight / 2.20462
        } else {
            // Already in kg
            weightInKg = weight
        }
        
        calorieCalculator.updateUserWeight(weightInKg)
        dismiss()
    }
}

// MARK: - Info Row
struct InfoRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.body)
                .foregroundColor(.white)
            
            Spacer()
            
            Text(value)
                .font(.body)
                .fontWeight(.semibold)
                .foregroundColor(.orange)
        }
    }
}

// MARK: - Preview
#Preview {
    WeightSettingsView(calorieCalculator: CalorieCalculator())
        .preferredColorScheme(.dark)
}
