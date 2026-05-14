//
//  FloatingLettersView.swift
//  Lenscribe
//
//  Created by Ranjan Bhakta on 24/04/26.
//

import Foundation
import SwiftUI

struct FloatingLettersView: View {
    @State private var animate = false
    
    let letters = ["A", "I", "S", "C", "R", "B", "E", "X"]
    
    var body: some View {
        ZStack {
            ForEach(letters.indices, id: \.self) { i in
                    Text(letters[i])
                    .font(.title.bold())
                    .foregroundStyle(.black.opacity(0.8))
                    .offset(
                        x: animate ? CGFloat.random(in: -300...300) : 0,
                        y: animate ? CGFloat.random(in: -80...80) : 0
                    )
                    .blur(radius: animate ? 0 : 4)
                    .opacity(animate ? 1 : 0)
                    .animation(
                        .easeInOut(duration: 1.2)
                        .repeatForever(autoreverses: true)
                        .delay(Double(i) * 0.1),
                        value: animate
                    )
            }
        }
        .onAppear() {
            animate = true
        }
    }
}
