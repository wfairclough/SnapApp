//
//  PreferencesView.swift
//  SnapApp
//
//  Created by Will Fairclough on 2025-07-27.
//

import SwiftUI

struct PreferencesView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image(systemName: "bolt.circle")
                    .font(.system(size: 48))
                    .foregroundColor(.blue)
                
                Text("SnapApp")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Global Shortcut Manager")
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Phase 1: Foundation")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    Text("• Basic menubar app ✓")
                        .font(.caption)
                        .foregroundColor(.green)
                    
                    Text("• Preferences window ✓")
                        .font(.caption)
                        .foregroundColor(.green)
                    
                    Text("• Coming next: Shortcut detection")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
                
                Spacer()
            }
            .padding()
            .navigationTitle("Preferences")
        }
        .frame(minWidth: 400, minHeight: 300)
    }
}

#Preview {
    PreferencesView()
}