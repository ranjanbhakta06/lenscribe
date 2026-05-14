//
//  Settings View.swift
//  Lenscribe
//
//  Created by Ranjan Bhakta on 28/04/26.
//

import SwiftUI
import Combine

struct Settings_View: View {
    @ObservedObject var vm: ContentViewModel
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("API"),
                footer:  Text("Your API key is stored locally and never shared.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                ){
                    SecureField("Enter API Key", text: $vm.apiKey)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                   
                }
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    Settings_View(vm: ContentViewModel())
}
