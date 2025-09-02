//
//  OnboardingView.swift
//  Misha Pdf Scan
//
//  Created by mac air on 9/1/25.
//
import SwiftUI

struct OnboardingView: View {
    @State private var index = 0
    let pages: [OnboardingPage]
    let onFinish: () -> Void

    var body: some View {
        VStack {
            TabView(selection: $index) {
                ForEach(Array(pages.enumerated()), id: \.offset) { i, p in
                    OnboardingSlideView(page: p).tag(i)
                }
            }
            .tabViewStyle(.page)
            .indexViewStyle(.page(backgroundDisplayMode: .always))

            HStack {
                Button("Пропустить") { onFinish() }
                Spacer()
                Button(index < pages.count - 1 ? "Далее" : "Начать") {
                    if index < pages.count - 1 { index += 1 } else { onFinish() }
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
        }
    }
}
