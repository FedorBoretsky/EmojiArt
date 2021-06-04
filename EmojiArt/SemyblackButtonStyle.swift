//
//  SemyblackButtonStyle.swift
//  EmojiArt
//
//  Created by Fedor Boretskiy on 05.06.2021.
//  Copyright © 2021 CS193p Instructor. All rights reserved.
//

import SwiftUI

struct SemiblackButtonStyle: ViewModifier {
    func body (content: Content) -> some View {
        content
            .foregroundColor(.white)
            .padding(.horizontal)
            .font(Font.body.weight(.semibold))
            .padding(11)
            .background(Capsule().fill(UX.Colors.selectionDarkBackground))
    }
}

extension View {
    func semiblackButtonStyle() -> some View {
        self.modifier(SemiblackButtonStyle())
    }
}

