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
                Button("onboarding.skip") { onFinish() }
                Spacer()
                Button(index < pages.count - 1 ? String(localized: "onboarding.next") : String(localized: "onboarding.start")) {
                    if index < pages.count - 1 { index += 1 } else { onFinish() }
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
        }
    }
}

#if DEBUG
struct OnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        let pages: [OnboardingPage] = [
            .init(title: "Welcome", subtitle: "Scan documents easily.", systemImage: "camera.viewfinder"),
            .init(title: "Import", subtitle: "Pick photos from library.", systemImage: "photo.on.rectangle"),
            .init(title: "Edit", subtitle: "Rotate and crop.", systemImage: "doc.richtext")
        ]
        return OnboardingView(pages: pages, onFinish: {})
    }
}
#endif
