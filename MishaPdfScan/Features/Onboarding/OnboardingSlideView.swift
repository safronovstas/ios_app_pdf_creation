//
//  OnboardingSlideView.swift
//  Misha Pdf Scan
//
//  Created by mac air on 9/1/25.
//
import SwiftUI

struct OnboardingSlideView: View {
    let page: OnboardingPage
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: page.systemImage)
                .resizable()
                .scaledToFit()
                .frame(height: 160)
                .padding(.top, 40)

            Text(page.title)
                .font(.title).bold()

            Text(page.subtitle)
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal)

            Spacer()
        }
        .padding()
    }
}

#if DEBUG
struct OnboardingSlideView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingSlideView(page: .init(title: "Scan documents", subtitle: "Auto crop and alignment", systemImage: "camera.viewfinder"))
            .previewLayout(.sizeThatFits)
    }
}
#endif
