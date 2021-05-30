//
//  EmojiView.swift
//  EmojiArt
//
//  Created by Fedor Boretskiy on 30.05.2021.
//  Copyright © 2021 CS193p Instructor. All rights reserved.
//

import SwiftUI

struct EmojiView: View {
    let text: String
    let size: CGFloat
    let isSelected: Bool
    
    var body: some View {
        Text(text)
            .font(animatableWithSize: size)
            .padding(10)
            .background(EmojiSelection().opacity(isSelected ? 1 : 0))
    }
}

fileprivate struct EmojiSelection: View {
    var body: some View {
        let shape = Circle()
        ZStack{
            // Dargen background
            shape.scale(1.66).foregroundColor(.black).opacity(0.4)
            // Size rorder
            shape.stroke(lineWidth: 2).foregroundColor(.white)
            // "Resize handle"
            shape.scale(1.18)
                .stroke(lineWidth: 2)
                .foregroundColor(.white)
                .clipShape(Rectangle())
        }
    }
}

struct EmojiView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            let bg = Color.red
            if #available(iOS 14.0, *) {
                bg.ignoresSafeArea(.all)
            } else {
                bg.edgesIgnoringSafeArea(.all)
            }
            VStack(spacing: 22) {
                EmojiView(text: "🔔", size: 10, isSelected: false)
                EmojiView(text: "⬆️", size: 40, isSelected: true)
                EmojiView(text: "🔔", size: 40, isSelected: false)
                EmojiView(text: "♥️", size: 20, isSelected: true)
                EmojiView(text: "🔔", size: 60, isSelected: true)
            }
        }
    }
}
