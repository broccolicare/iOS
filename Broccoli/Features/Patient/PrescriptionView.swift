import SwiftUI

struct PrescriptionView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Image(systemName: "pills")
                    .font(.system(size: 48))
                    .foregroundStyle(.tint)
                    .padding(.top, 32)
                Text("Prescription")
                    .font(.largeTitle)
                    .bold()
                Text("This is a placeholder screen for prescriptions.")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)
                Spacer()
            }
            .navigationTitle("Prescriptions")
        }
    }
}

#Preview {
    PrescriptionView()
}
