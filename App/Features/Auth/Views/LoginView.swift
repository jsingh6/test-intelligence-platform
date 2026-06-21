import SwiftUI

// @test-ids: AUTH-001, AUTH-002, AUTH-003
struct LoginView: View {
    @EnvironmentObject var authService: AuthService
    @StateObject private var viewModel = LoginViewModel()

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()

                Text("Welcome")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                VStack(spacing: 16) {
                    TextField("Email", text: $viewModel.email)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.emailAddress)
                        .textFieldStyle(.roundedBorder)

                    SecureField("Password", text: $viewModel.password)
                        .textFieldStyle(.roundedBorder)
                }

                if let error = viewModel.errorMessage {
                    Text(error)
                        .foregroundStyle(.red)
                        .font(.caption)
                }

                Button {
                    Task { await viewModel.login(using: authService) }
                } label: {
                    if viewModel.isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                    } else {
                        Text("Log In")
                            .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(viewModel.isLoading)

                Spacer()
            }
            .padding(.horizontal, 32)
            .navigationTitle("")
        }
    }
}
