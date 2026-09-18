import SwiftUI

// MARK: - Models (sample)
struct Banner: Identifiable { let id = UUID(); let title: String; let subtitle: String; let imageName: String }
// MARK: - Home View
struct PatientHomeView: View {
    @Environment(\.appTheme) private var theme
    @EnvironmentObject private var router: Router
    @EnvironmentObject private var authVM: AuthGlobalViewModel
    @EnvironmentObject private var appVM: AppGlobalViewModel
    @EnvironmentObject private var bookingVM: BookingGlobalViewModel
    @EnvironmentObject private var userVM: UserGlobalViewModel
    
    // screen state
    @State private var searchText: String = ""

    // Convert API BookingData to UI Appointment model
    private var appointments: [BookingData] {
        bookingVM.upcomingAppointments
    }
    
    var body: some View {
        ZStack {
            theme.colors.background.ignoresSafeArea()
            
            VStack(spacing: 0) {
                    // Nav / Greeting
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(DateHelper.greetingText())
                                .font(theme.typography.callout)
                                .foregroundStyle(theme.colors.textSecondary)
                            Text(userVM.profileData?.name ?? authVM.currentUser?.name ?? "Guest")
                                .font(theme.typography.title)
                                .foregroundStyle(theme.colors.textPrimary)
                        }
                        Spacer()
                        Button {
                            // navigate to notifications screen; if you use router:
                            router.push(.notifications)
                        } label: {
                            ZStack {
                                Circle()
                                    .fill(theme.colors.primary.opacity(0.1))
                                    .frame(width: 44, height: 44)
                                
                                Image("notification-icon").frame(width: 40, height: 40)
                                
                                // Notification badge
                                Circle()
                                    .fill(Color.red)
                                    .frame(width: 8, height: 8)
                                    .offset(x: 10, y: -10)
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
                            if !appVM.slidersData.isEmpty {
                                BannerCarousel(sliders: appVM.slidersData)
                                    .frame(height: 150)
                                    .padding(.horizontal, theme.spacing.lg)
                            }
                            
                            // 2x2 department tiles (from API)
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: theme.spacing.md) {
                                ForEach(appVM.departments) { department in
                                    Button {
                                        navigate(to: department)
                                    } label: {
                                        SmallActionTile(
                                            title: department.name,
                                            backgroundImage: "gp-image",
                                            backgroundImageUrl: department.imageUrl
                                        )
                                        .frame(height: 140)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal, theme.spacing.lg)

                            // Upcoming appointments section
                            if !appointments.isEmpty {
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
                                            AppointmentCard(booking: item)
                                                .padding(.horizontal, theme.spacing.lg)
                                        }
                                        .frame(height: 200)
                                    }.clipped()
                                }
                            }
                            
                            // bottom tiles
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: theme.spacing.md) {
                                // Commented out for now: Medical Tourism
                                // Button(action: {
                                //     router.push(.medicalTourismForm)
                                // }) {
                                //     SmallActionTile(
                                //         title: "Medical Tourism",
                                //         backgroundImage: "medical-tourism"
                                //     )
                                //     .frame(height: 130)
                                // }.buttonStyle(.plain)

                                // Commented out for now: Cure From Drug
                                // Button(action: {
                                //     router.push(.cureFromDrugForm)
                                // }) {
                                //     SmallActionTile(
                                //         title: "Cure From Drug",
                                //         backgroundImage: "cure-from-drug"
                                //     )
                                //     .frame(height: 130)
                                // }.buttonStyle(.plain)

                                Button(action: {
                                    router.push(.contactUs)
                                }) {
                                    SmallActionTile(
                                        title: "Request a service",
                                        backgroundImage: "request-service"
                                    )
                                    .frame(height: 130)
                                }.buttonStyle(.plain)
                            }
                            .padding(.horizontal, theme.spacing.lg)
                            .padding(.bottom, 150) // space for tab bar + floating chat button
                        }
                        .padding(.top, theme.spacing.lg)
                    } // ScrollView
                        .refreshable {
                            await appVM.loadSlidersData()
                            await appVM.loadDepartments()
                            await bookingVM.fetchUpcomingConfirmedAppointments()
                        }
                } // VStack
            }
            .navigationBarHidden(true)
            .task {
                // Add a small delay to let navigation settle before triggering API calls
                try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 second
                
                // Fetch data sequentially to avoid overwhelming the navigation system
                if appVM.slidersData.isEmpty {
                    await appVM.loadSlidersData()
                }
                if appVM.departments.isEmpty {
                    await appVM.loadDepartments()
                }
                await bookingVM.fetchUpcomingConfirmedAppointments()
                if userVM.profileData == nil {
                    await userVM.fetchProfileDetail()
                }
            }
    }
    
    /// General Medicine routes to the GP booking form; every other department
    /// routes to the specialist list, filtered by that department's id.
    private func navigate(to department: Department) {
        if department.slug == "general-medicine" {
            router.push(.gPAppointBookingForm)
        } else {
            router.push(.specialistList(departmentId: "\(department.id)"))
        }
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
    @EnvironmentObject private var router: Router
    @Binding var text: String
    
    var body: some View {
        Button(action: {
            router.push(.search)
        }) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(theme.colors.textSecondary)
                Text("Search for services")
                    .font(theme.typography.body)
                    .foregroundStyle(theme.colors.textSecondary)
                Spacer()
            }
            .padding(14)
            .background(theme.colors.surface)
            .cornerRadius(12)
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(theme.colors.border))
        }
        .buttonStyle(.plain)
    }
}

private struct BannerCarousel: View {
    @Environment(\.appTheme) private var theme
    let sliders: [Slider]
    @State private var index: Int = 0
    @State private var timer: Timer?
    
    var body: some View {
        TabView(selection: $index) {
            ForEach(Array(sliders.enumerated()), id: \.element.id) { idx, slider in
                ZStack(alignment: .leading) {
                    // Background with image from API
                    AsyncImage(url: URL(string: slider.imageUrl)) { phase in
                        switch phase {
                        case .empty:
                            RoundedRectangle(cornerRadius: 16)
                                .fill(LinearGradient(colors: [Color.purple.opacity(0.9), Color.blue.opacity(0.9)], startPoint: .topLeading, endPoint: .bottomTrailing))
                            ProgressView()
                                .tint(.white)
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                                .frame(height: 150)
                                .clipped()
                                .cornerRadius(16)
                        case .failure:
                            RoundedRectangle(cornerRadius: 16)
                                .fill(LinearGradient(colors: [Color.purple.opacity(0.9), Color.blue.opacity(0.9)], startPoint: .topLeading, endPoint: .bottomTrailing))
                            Image(systemName: "photo")
                                .foregroundStyle(.white.opacity(0.5))
                        @unknown default:
                            EmptyView()
                        }
                    }
                    
                    // Overlay gradient for better text visibility
                    RoundedRectangle(cornerRadius: 16)
                        .fill(LinearGradient(colors: [Color.black.opacity(0.6), Color.clear], startPoint: .leading, endPoint: .trailing))
                    
                    // Text content
                    HStack {
                        VStack(alignment: .leading, spacing: 6) {
                            if let title = slider.title {
                                Text(title)
                                    .font(theme.typography.title)
                                    .foregroundStyle(.white)
                            }
                        }
                        Spacer()
                    }
                    .padding()
                }
                .tag(idx)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .always))
        .onAppear {
            startAutoRotation()
        }
        .onDisappear {
            stopAutoRotation()
        }
        .onChange(of: index) { _ in
            // Reset timer when user manually swipes
            resetAutoRotation()
        }
    }
    
    private func startAutoRotation() {
        // Only auto-rotate if there are multiple banners
        guard sliders.count > 1 else { return }
        
        timer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { _ in
            withAnimation {
                index = (index + 1) % sliders.count
            }
        }
    }
    
    private func stopAutoRotation() {
        timer?.invalidate()
        timer = nil
    }
    
    private func resetAutoRotation() {
        stopAutoRotation()
        startAutoRotation()
    }
}


// MARK: - Preview

#Preview {
    PatientHomeView()
        .appTheme(AppTheme.default)
        .environmentObject(Router.shared)
}
