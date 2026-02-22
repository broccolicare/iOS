import SwiftUI

struct DoctorHomeView: View {
    @Environment(\.appTheme) private var theme
    @EnvironmentObject private var authVM: AuthGlobalViewModel
    @EnvironmentObject private var router: Router
    @EnvironmentObject private var bookingVM: BookingGlobalViewModel
    
    @State private var showActionError = false
    @State private var actionErrorMessage = ""
    
    // Convert BookingData to DoctorAppointment for Today's Appointments (Pending)
    private var todaysAppointments: [DoctorAppointment] {
        bookingVM.pendingBookings.map { booking in
            DoctorAppointment(
                id: booking.id,
                patientName: booking.user?.name ?? "Patient",
                patientAvatar: "doctor-placeholder",
                date: booking.date,
                startTime: booking.time,
                endTime: calculateEndTime(from: booking.time, duration: booking.service?.duration ?? 30),
                status: .pending
            )
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Fixed Header
            HStack(spacing: 12) {
                // Profile Image and Name - Tappable
                Button(action:{ router.push(.doctorProfile) }) {
                    HStack(spacing: 12) {
                        Circle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 50, height: 50)
                            .overlay(
                                Image("doctor-placeholder")
                            )
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(DateHelper.greetingText())
                                .font(theme.typography.regular16)
                                .foregroundStyle(theme.colors.textSecondary)
                            
                            if let user = authVM.currentUser {
                                Text(user.name)
                                    .font(theme.typography.bold28)
                                    .foregroundStyle(theme.colors.textPrimary)
                            }
                        }
                    }
                }
                .buttonStyle(PlainButtonStyle())
                
                Spacer()
                
                // Notification Bell
                Button(action: {
                    router.push(.notifications)
                }) {
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
                .padding(.horizontal, 20)
                .padding(.top, 20)
                
                // List Content with Sections
                List {
                    // Today's Appointment Section
                    Section {
                        if todaysAppointments.isEmpty {
                            NoAppointmentView(message: "No appointments for today")
                                .listRowInsets(EdgeInsets(top: 20, leading: 16, bottom: 20, trailing: 16))
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                        } else {
                            ForEach(todaysAppointments) { appointment in
                                Button(action: {
                                    // Navigate to appointment detail
                                    if let booking = bookingVM.pendingBookings.first(where: { $0.id == appointment.id }) {
                                        router.push(.appointmentDetailForDoctor(booking: booking))
                                    }
                                }) {
                                    TodayAppointmentCard(appointment: appointment, theme: theme) {
                                        // Accept action
                                        acceptAppointment(appointment)
                                    } onReject: {
                                        // Reject action
                                        rejectAppointment(appointment)
                                    }
                                }
                                .buttonStyle(.plain)
                                .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                            }
                        }
                    } header: {
                        Text("Todays Appointment")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(theme.colors.textPrimary)
                            .textCase(nil)
                    }
                    
                    // Scheduled Appointments Section
                    Section {
                        if bookingVM.myBookings.isEmpty {
                            NoAppointmentView(message: "No scheduled appointments")
                                .listRowInsets(EdgeInsets(top: 20, leading: 16, bottom: 20, trailing: 16))
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                        } else {
                            ForEach(bookingVM.myBookings) { booking in
                                ScheduledAppointmentCard(booking: booking, theme: theme) {
                                    router.push(.appointmentDetailForDoctor(booking: booking))
                                }
                                .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                            }
                        }
                    } header: {
                        Text("Scheduled Appointments")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(theme.colors.textPrimary)
                            .textCase(nil)
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .refreshable {
                    await bookingVM.fetchPendingBookingsForDoctor()
                    await bookingVM.fetchMyBookingsForDoctor()
                }
                .navigationBarHidden(true)
                .alert("Action Failed", isPresented: $showActionError) {
                    Button("OK", role: .cancel) {}
                } message: {
                    Text(actionErrorMessage)
                }
            }
            .task {
                // Add a small delay to let navigation settle before triggering API calls
                try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 second
                
                // Fetch appointments sequentially to avoid overwhelming the navigation system
                await bookingVM.fetchPendingBookingsForDoctor()
                await bookingVM.fetchMyBookingsForDoctor()
            }
    }
    
    // Helper function to calculate end time based on start time and duration
    private func calculateEndTime(from startTime: String, duration: Int) -> String {
        // Parse time in HH:mm format
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        
        guard let start = formatter.date(from: startTime) else {
            return startTime
        }
        
        // Add duration in minutes
        guard let end = Calendar.current.date(byAdding: .minute, value: duration, to: start) else {
            return startTime
        }
        
        // Format to 12-hour with AM/PM
        let displayFormatter = DateFormatter()
        displayFormatter.dateFormat = "h:mm a"
        return displayFormatter.string(from: end)
    }
    
    private func acceptAppointment(_ appointment: DoctorAppointment) {
        Task {
            let success = await bookingVM.acceptBooking(bookingId: appointment.id)
            
            if success {
                await bookingVM.refreshPendingBookings()
                await bookingVM.refreshMyBookings()
            } else {
                actionErrorMessage = bookingVM.errorMessage ?? "Failed to accept booking. Please try again."
                showActionError = true
            }
        }
    }
    
    private func rejectAppointment(_ appointment: DoctorAppointment) {
        Task {
            let success = await bookingVM.rejectBooking(bookingId: appointment.id, reason: "Rejected by doctor")
            
            if success {
                await bookingVM.refreshPendingBookings()
            } else {
                actionErrorMessage = bookingVM.errorMessage ?? "Failed to reject booking. Please try again."
                showActionError = true
            }
        }
    }
    
}

#Preview {
    DoctorHomeView()
        .appTheme(AppTheme.default)
}
