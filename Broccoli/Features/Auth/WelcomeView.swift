import SwiftUI

struct WelcomeView: View {
    @Environment(\.appTheme) private var theme
    
    var body: some View {
        NavigationView {
            ZStack (alignment: .top){
                theme.colors.background
                    .edgesIgnoringSafeArea(.all)
                
                
                // Hero area with doctor image and logo overlay
                ZStack(alignment: .topLeading) {
                    Image("WelcomeHero")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(maxWidth: .infinity)
                        .frame(height: 548) // tuned to match screenshot proportions
                        .clipped()
                        .ignoresSafeArea(edges: .top)
                    
                    Image("Logo")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 100, height: 70)
                        .padding(.leading, 20)
                }
                
                ZStack(alignment: .bottom) {
                    // ✅ Background gradient: transparent → white
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.white.opacity(0.0),
                            Color.white.opacity(0.8),
                            Color.white.opacity(1.0)
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                        
                    )
                    .frame(maxWidth: .infinity)
                    .frame(height: 300)
                    .padding(.bottom, 260)
                    .edgesIgnoringSafeArea(.bottom)
                    
                    // Card content
                    VStack(spacing: theme.spacing.lg) {
                        Spacer()
                        VStack(alignment: .center, spacing: theme.spacing.sm) {
                            HeadlineText(text: "Provide 24×7 trusted medical practitioners")
                            BodyText(text: "Get convenient, high-quality virtual care including everyday simply book your doctor or therapist.")
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, theme.spacing.lg)
                        }.padding(.bottom, theme.spacing.xxl)
                        
                        
                        // Buttons
                        VStack(spacing: theme.spacing.md) {
                            NavigationLink(destination: LoginView()) {
                                PrimaryButton(action: {}, label: {
                                    Text("Login")
                                })
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            HStack(spacing: theme.spacing.md) {
                                NavigationLink(destination: SignUpView()) {
                                    GrayOutlineButton(title:"Signup as User")
                                    
                                }
                                NavigationLink(destination: SignUpView()) {
                                    GrayOutlineButton(title:"Signup as Doctor")
                                }
                            }
                        }
                    }
                    .padding(.horizontal, theme.spacing.xl)
                    .padding(.vertical, theme.spacing.lg)
                    .background(theme.colors.surface.opacity(0.9)) // optional slight transparency
                    .cornerRadius(20)
                    .shadow(color: Color.black.opacity(0.08), radius: theme.shadowRadius, x: 0, y: 6)
                    .offset(y: -40)
                    .padding(.bottom, -40)
                }
                
            }
            .navigationBarHidden(true)
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    // Helper to compute safe top padding for devices with notch
    private func safeTopPadding() -> CGFloat {
        // Use connected scenes to find the active window scene and its key window
        let scenes = UIApplication.shared.connectedScenes
        let windowScene = scenes
            .compactMap { $0 as? UIWindowScene }
            .first { $0.activationState == .foregroundActive }
        
        let keyWindow = windowScene?.windows.first { $0.isKeyWindow }
        return keyWindow?.safeAreaInsets.top ?? 0
    }
}

#Preview {
    WelcomeView()
        .appTheme(AppTheme.default)
}
