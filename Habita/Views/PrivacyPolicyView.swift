//
//  PrivacyPolicyView.swift
//  Habita
//
//  Created by 山﨑祥平 on 2025/07/13.
//

import SwiftUI

struct PrivacyPolicyView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.openURL) var openURL
    
    // GitHub PagesのURL（リポジトリ名をStreaksに仮定）
    private let privacyPolicyURL = URL(string: "https://hey-show123.github.io/Streaks/")!
    
    var body: some View {
        VStack {
            // プライバシーポリシーページを開く
            ProgressView()
                .scaleEffect(1.5)
                .padding()
        }
        .onAppear {
            // Webページを開く
            openURL(privacyPolicyURL)
            // 少し遅延してから閉じる
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                dismiss()
            }
        }
    }
} 