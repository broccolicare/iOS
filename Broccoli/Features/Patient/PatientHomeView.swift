import SwiftUI

// MARK: - Models (sample)
struct Banner: Identifiable { let id = UUID(); let title: String; let subtitle: String; let imageName: String }
struct ServiceItem: Identifiable { let id = UUID(); let title: String; let icon: String; let color: Color }
struct Appointment: Identifiable { let id = UUID(); let doctorName: String; let specialty: String; let date: String; let time: String; let avatar: String }

// MARK: - Home View
struct PatientHomeView: View {
    @Environment(\.appTheme) private var theme
    @EnvironmentObject private var router: Router
    @EnvironmentObject private var authVM: AuthGlobalViewModel
    
    // screen state
    @State private var searchText: String = ""
    @State private var banners: [Banner] = [
        Banner(title: "Online Doctor Service", subtitle: "Frictionless access to healthcare", imageName: "person.crop.rectangle"),
        Banner(title: "Book a Specialist", subtitle: "Get consultation from experts", imageName: "stethoscope")
    ]
    @State private var services: [ServiceItem] = [
        ServiceItem(title: "GP Booking", icon: "calendar-icon", color: Color("Tile1")),
        ServiceItem(title: "Specialist", icon: "specilist-icon", color: Color("Tile2")),
        ServiceItem(title: "Nutritionists", icon: "nutritionists-icon", color: Color("Tile3")),
        ServiceItem(title: "Blood Tests", icon: "blood-test-icon", color: Color("Tile4"))
    ]
    @State private var appointments: [Appointment] = [
        Appointment(doctorName: "Dr. Ethan Carter", specialty: "General Practitioner", date: "2nd Oct, 2025", time: "12:30 PM", avatar: "person.circle"),
        Appointment(doctorName: "Dr. Laura Smith", specialty: "Dermatologist", date: "10th Oct, 2025", time: "09:00 AM", avatar: "person.circle.fill")
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                theme.colors.background.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Nav / Greeting
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(DateHelper.greetingText())
                                .font(theme.typography.callout)
                                .foregroundStyle(theme.colors.textSecondary)
                            Text(authVM.currentUser?.name ?? "Guest")
                                .font(theme.typography.title)
                                .foregroundStyle(theme.colors.textPrimary)
                        }
                        Spacer()
                        Button {
                            // navigate to notifications screen; if you use router:
                            //router.push(.profile) // example; replace with .notifications route if defined
                        } label: {
                            ZStack {
                                Circle()
                                    .fill(theme.colors.surface)
                                    .frame(width: 44, height: 44)
                                Image(systemName: "bell.fill")
                                    .foregroundStyle(theme.colors.primary)
                            }
                        }
                    }
                    .padding(.horizontal, theme.spacing.lg)
                    
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: theme.spacing.lg) {
                            // Search
                            SearchBar(text: $searchText)
                                .padding(.horizontal, theme.spacing.lg)
                            
                            // Banners carousel
                            BannerCarousel(banners: banners)
                                .frame(height: 150)
                                .padding(.horizontal, theme.spacing.lg)
                            
                            // 2x2 service tiles
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: theme.spacing.md) {
                                ForEach(services) { s in
                                    ServiceTile(item: s) {
                                        // navigate to respective screen
                                        // e.g. router.push(.specialist) or NavigationLink
                                        print("Tapped \(s.title)")
                                    }
                                }
                            }
                            .padding(.horizontal, theme.spacing.lg)
                            
                            // Upcoming appointments section
                            VStack(alignment: .leading, spacing: theme.spacing.sm) {
                                Text("Upcoming Appointments")
                                    .font(theme.typography.subtitle)
                                    .foregroundStyle(theme.colors.textPrimary)
                                    .padding(.horizontal, theme.spacing.lg)
                                
                                VerticalCarousel(items: appointments,
                                                                  visibleCount: 4,
                                                                 spacing: 12,
                                                                 scaleGap: 0.06,
                                                                 swipeThreshold: 90,
                                                                 maxRotationX: 16,
                                                                 perspective: 0.9,
                                                                  height: 160) { item in
                                    ZStack {
                                        AppointmentCard(appointment: item)
                                            .padding(.horizontal, theme.spacing.lg)
                                    }
                                    .frame(height: 200)
                                }.clipped()
                            }
                            
                            // bottom two boxes
                            HStack(spacing: theme.spacing.md) {
                                    SmallActionTile(
                                        title: "Medical Tourism",
                                        icon: "medical-tourism-icon"
                                    )
                                    .frame(height: 100)
                                    
                                    SmallActionTile(
                                        title: "Cure From Drug",
                                        icon: "cure-from-drug-icon"
                                    )
                                    .frame(height: 100)
                                }
                            .padding(.horizontal, theme.spacing.lg)
                            .padding(.bottom, 80) // space for tab bar
                        }
                        .padding(.top, theme.spacing.lg)
                    } // ScrollView
                } // VStack
            }
            .navigationBarHidden(true)
        } // NavigationStack
        .navigationViewStyle(.stack)
    }
    
    private func safeTop() -> CGFloat {
        let window = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }
        return window?.safeAreaInsets.top ?? 20
    }
    
    private func safeBottom() -> CGFloat {
        let window = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }
        return window?.safeAreaInsets.bottom ?? 0
    }
}

// MARK: - Components

private struct SearchBar: View {
    @Environment(\.appTheme) private var theme
    @Binding var text: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(theme.colors.textSecondary)
            TextField("Search for services", text: $text)
                .font(theme.typography.body)
                .foregroundStyle(theme.colors.textPrimary)
        }
        .padding(14)
        .background(theme.colors.surface)
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(theme.colors.border))
    }
}

private struct BannerCarousel: View {
    @Environment(\.appTheme) private var theme
    let banners: [Banner]
    @State private var index: Int = 0
    
    var body: some View {
        TabView(selection: $index) {
            ForEach(Array(banners.enumerated()), id: \.element.id) { idx, banner in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(LinearGradient(colors: [Color.purple.opacity(0.9), Color.blue.opacity(0.9)], startPoint: .topLeading, endPoint: .bottomTrailing))
                    HStack {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(banner.title)
                                .font(theme.typography.title)
                                .foregroundStyle(.white)
                            Text(banner.subtitle)
                                .font(theme.typography.callout)
                                .foregroundStyle(.white.opacity(0.9))
                        }
                        Spacer()
                        Image(systemName: banner.imageName)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 84, height: 84)
                            .foregroundStyle(.white.opacity(0.9))
                    }
                    .padding()
                }
                .tag(idx)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .always))
    }
}


// MARK: - Preview

#Preview {
    PatientHomeView()
        .appTheme(AppTheme.default)
        .environmentObject(Router.shared)
}
