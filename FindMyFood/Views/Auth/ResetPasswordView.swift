//
//  ResetPasswordView.swift
//  FindMyFood
//
//  Created by Rithvik Dirisala on 1/20/25.
//

import SwiftUI

struct ResetPasswordView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) var dismiss
    @State private var email = ""
    @State private var isSubmitted = false

    var body: some View {
        VStack(spacing: 20) {
            Text("Reset Password")
                .font(.system(.largeTitle, design: .serif))
                .fontWeight(.bold)
                .foregroundColor(Color.accentColor)

            TextField("Enter your email", text: $email)
                .autocapitalization(.none)
                .keyboardType(.emailAddress)
                .padding()
                .background(Color(UIColor.systemGray6))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                )

            Button(action: {
                authViewModel.resetPassword(email: email) { success in
                    if success {
                        isSubmitted = true
                    }
                }
            }) {
                Text("Send Reset Link")
                    .font(.headline)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            .disabled(email.isEmpty)

            if isSubmitted {
                Text("If the email exists in our system, a password reset link has been sent.")
                    .foregroundColor(.green)
                    .font(.caption)
                    .multilineTextAlignment(.center)
            }

            Spacer()
        }
        .padding()
        .alert("Error", isPresented: $authViewModel.showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(authViewModel.error ?? "An unknown error occurred")
        }
    }
}
