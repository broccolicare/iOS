import SwiftUI

struct DoctorHomeView: View {
    @Environment(\.appTheme) private var theme
    @EnvironmentObject private var authVM: AuthGlobalViewModel
    @EnvironmentObject private var router: Router
    
    // Sample data for appointments
    @State private var todaysAppointments: [DoctorAppointment] = [
        DoctorAppointment(
            id: 1,
            patientName: "Sophia Carter",
            patientAvatar: "patient-avatar-1",
            startTime: "10:00 AM",
            endTime: "10:30 AM",
            status: .pending
        ),
        DoctorAppointment(
            id: 2,
            patientName: "James Gulliver",
            patientAvatar: "patient-avatar-2",
            startTime: "12:00 PM",
            endTime: "12:30 PM",
            status: .pending
        )
    ]
    
    @State private var scheduledAppointments: [DoctorAppointment] = [
        DoctorAppointment(
            id: 3,
            patientName: "Marc Maddison",
            patientAvatar: "patient-avatar-3",
            startTime: "12:00 PM",
            endTime: "12:30 PM",
            status: .scheduled
        ),
        DoctorAppointment(
            id: 4,
            patientName: "Anni Wilmer",
            patientAvatar: "patient-avatar-4",
            startTime: "02:00 PM",
            endTime: "02:30 PM",
            status: .scheduled
        )
    ]
    
    var body: some View {
        NavigationView {
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
                    Button(action: {}) {
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
                                TodayAppointmentCard(appointment: appointment, theme: theme) {
                                    // Accept action
                                    acceptAppointment(appointment)
                                } onReject: {
                                    // Reject action
                                    rejectAppointment(appointment)
                                }
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
                        if scheduledAppointments.isEmpty {
                            NoAppointmentView(message: "No scheduled appointments")
                                .listRowInsets(EdgeInsets(top: 20, leading: 16, bottom: 20, trailing: 16))
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                        } else {
                            ForEach(scheduledAppointments) { appointment in
                                ScheduledAppointmentCard(appointment: appointment, theme: theme) {
                                    // Start call action
                                    startCall(appointment)
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
                .navigationBarHidden(true)
            }
            .navigationViewStyle(StackNavigationViewStyle())
        }
    }
    
    private func acceptAppointment(_ appointment: DoctorAppointment) {
        // Move to scheduled appointments
        if let index = todaysAppointments.firstIndex(where: { $0.id == appointment.id }) {
            var updatedAppointment = appointment
            updatedAppointment.status = .scheduled
            todaysAppointments.remove(at: index)
            scheduledAppointments.append(updatedAppointment)
        }
    }
    
    private func rejectAppointment(_ appointment: DoctorAppointment) {
        // Remove from today's appointments
        todaysAppointments.removeAll { $0.id == appointment.id }
    }
    
    private func startCall(_ appointment: DoctorAppointment) {
        // Navigate to video call
        print("Starting call with \(appointment.patientName)")
    }
}

#Preview {
    DoctorHomeView()
        .appTheme(AppTheme.default)
}
