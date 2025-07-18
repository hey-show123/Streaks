//
//  HelpView.swift
//  Habita
//
//  Created by 山﨑祥平 on 2025/07/13.
//

import SwiftUI

struct HelpView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.openURL) var openURL
    
    // GitHub PagesのURL
    private let helpURL = URL(string: "https://hey-show123.github.io/Habita/help.html")!
    
    var body: some View {
        VStack {
            // ヘルプページを開く
            ProgressView()
                .scaleEffect(1.5)
                .padding()
        }
        .onAppear {
            // Webページを開く
            openURL(helpURL)
            // 少し遅延してから閉じる
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                dismiss()
            }
        }
    }
} 