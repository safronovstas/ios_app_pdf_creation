//
//  CameraScreen.swift
//  Misha Pdf Scan
//
//  Created by mac air on 9/1/25.
//


import SwiftUI

struct CameraScreen: View {
    @ObservedObject var camera: CameraController
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            // Превью
            CameraView(controller: camera)
                .ignoresSafeArea()

            // Верхняя панель
            VStack {
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill").font(.system(size: 28))
                    }
                    .padding()
                    Spacer()
                }
                Spacer()

                // Кнопка спуска
                Button {
                    camera.capture()
                } label: {
                    Circle().stroke(lineWidth: 6).frame(width: 80, height: 80)
                }
                .padding(.bottom, 32)
            }
            .foregroundStyle(.white)
        }
        .onAppear { camera.start() }
        .onDisappear { camera.stop() }
    }
}
