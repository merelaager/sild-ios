//
//  SplashView.swift
//  sild
//

import SwiftUI

struct SplashView: View {
    private let background = Color(red: 35.0 / 255.0, green: 64.0 / 255.0, blue: 143.0 / 255.0)

    var body: some View {
        background
            .ignoresSafeArea()
            .overlay {
                Image("ship_w")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 218, height: 178)
                    .foregroundStyle(.white)
            }
    }
}

#Preview {
    SplashView()
}
