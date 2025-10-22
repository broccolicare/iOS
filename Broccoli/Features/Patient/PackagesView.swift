import SwiftUI

struct PackagesView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Image(systemName: "shippingbox")
                    .font(.system(size: 48))
                    .foregroundStyle(.tint)
                    .padding(.top, 32)
                Text("Packages")
                    .font(.largeTitle)
                    .bold()
                Text("This is a placeholder screen for packages and deliveries.")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)
                Spacer()
            }
            .navigationTitle("Packages")
        }
    }
}

#Preview {
    PackagesView()
}
