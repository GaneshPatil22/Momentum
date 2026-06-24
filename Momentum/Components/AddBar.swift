//
//  AddBar.swift
//  Momentum
//
//  Created by Ganesh Patil on 24/06/26.
//

import SwiftUI

struct AddBar: View {
    let placeholder: String
    @Binding var text: String
    @FocusState.Binding var isFocused: Bool
    let onSubmit: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "plus.circle.fill")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(AppColor.accent)
            TextField(placeholder, text: $text)
                .focused($isFocused)
                .submitLabel(.done)
                .onSubmit(onSubmit)
        }
        .padding(.horizontal, 15)
        .padding(.vertical, 12)
        .background(AppColor.surface2)
        .clipShape(.rect(cornerRadius: 12))
        .overlay {
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(AppColor.hairline, style: StrokeStyle(lineWidth: 1, dash: [3, 3]))
        }
    }
}
