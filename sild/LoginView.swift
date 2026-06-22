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

    var body: some View {
        VStack(spacing: 20) {
            Text("Sild")
                .font(.largeTitle)
                .fontWeight(.semibold)

            VStack(spacing: 12) {
                TextField("Kasutajanimi", text: $username)
                    .textContentType(.username)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .textFieldStyle(.roundedBorder)

                SecureField("Parool", text: $password)
                    .textContentType(.password)
                    .textFieldStyle(.roundedBorder)
            }

            if let errorMessage {
                Text(errorMessage)
                    .font(.callout)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
            }

            Button(action: submit) {
                HStack {
                    if isSubmitting {
                        ProgressView()
                    }
                    Text("Logi sisse")
                        .fontWeight(.medium)
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(!canSubmit)
        }
        .padding(24)
        .frame(maxWidth: 360)
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
    let auth = AuthService()
    return LoginView().environment(auth)
}
