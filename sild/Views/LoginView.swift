//
//  LoginView.swift
//  sild
//

import SwiftUI

struct LoginView: View {
    @Environment(AuthService.self) private var auth

    @State private var username: String = ""
    @State private var password: String = ""
    @State private var isSubmitting: Bool = false
    @State private var errorMessage: String?

    private let brand = Color(red: 35.0 / 255.0, green: 64.0 / 255.0, blue: 143.0 / 255.0)

    var body: some View {
        VStack(spacing: 20) {
            Image("ship_w")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(height: 120)
                .foregroundStyle(brand)

            Text("Merelaagri sild")
                .font(.title2)
                .fontWeight(.semibold)
                .padding(.bottom)

            VStack(spacing: 0) {
                TextField("Kasutajanimi", text: $username)
                    .textContentType(.username)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)

                Divider()

                SecureField("Parool", text: $password)
                    .textContentType(.password)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
            }
            .background(
                Color(.secondarySystemFill),
                in: .rect(cornerRadius: 22, style: .continuous)
            )
            .padding(.bottom)

            if let errorMessage {
                Text(errorMessage)
                    .font(.callout)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
            }

            Button(action: submit) {
                HStack {
                    if isSubmitting { ProgressView() }
                    Text("Logi sisse").fontWeight(.medium)
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .buttonBorderShape(.capsule)
            .controlSize(.large)
            .disabled(!canSubmit)
            .tint(brand)
        }
        .padding(24)
        .frame(maxWidth: 360)
        .offset(y: -25)
    }

    private var canSubmit: Bool {
        !isSubmitting && !username.isEmpty && !password.isEmpty
    }

    private func submit() {
        errorMessage = nil
        isSubmitting = true
        Task {
            defer { isSubmitting = false }
            do {
                try await auth.login(username: username, password: password)
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}

#Preview {
    LoginView().environment(AuthService())
}
