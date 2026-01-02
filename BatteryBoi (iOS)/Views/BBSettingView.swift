//
//  BBSettingView.swift
//  BatteryBoi (iOS)
//
//  Created by Joe Barbour on 1/2/26.
//

import SwiftUI
import SwiftData

struct SettingContainer: View {
    @State private var showDestroySheet = false

    var body: some View {
        VStack {
            Button(role: .destructive) {
                showDestroySheet = true
            } label: {
                Label("Destroy All Data", systemImage: "trash.fill")
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.red)
                    .cornerRadius(12)
            }
            .padding()
        }
        .sheet(isPresented: $showDestroySheet) {
            DestroyDataView()
        }
    }
}

struct DestroyDataView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var isDeleting = false

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 60))
                .foregroundColor(.red)
                .padding(.top, 40)

            Text("Destroy All Data?")
                .font(.title)
                .bold()

            Text("This will permanently remove all your devices, battery history, and alert settings from iCloud and this device. This action cannot be undone.")
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
                .foregroundColor(.secondary)

            Spacer()

            if isDeleting {
                ProgressView("Destroying...")
                    .padding()
            } else {
                Button(role: .destructive) {
                    deleteData()
                } label: {
                    Text("Confirm Destroy")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(16)
                }
                .padding(.horizontal, 32)

                Button("Cancel") {
                    dismiss()
                }
                .font(.headline)
                .padding(.bottom, 40)
            }
        }
    }

    private func deleteData() {
        isDeleting = true
        
        // Use a background task to ensure it completes
        DispatchQueue.global(qos: .userInitiated).async {
            CloudManager.shared.cloudDestroyEntity(.devices)
            CloudManager.shared.cloudDestroyEntity(.events)
            CloudManager.shared.cloudDestroyEntity(.alerts)
            CloudManager.shared.cloudDestroyEntity(.push)
            CloudManager.shared.cloudDestroyEntity(.entries)
            
            DispatchQueue.main.async {
                isDeleting = false
                dismiss()
            }
        }
    }
}
