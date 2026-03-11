import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @Environment(\.managedObjectContext) var context
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            TaskRootView()
                .tabItem {
                    Label("Tasks", systemImage: "checklist")
                }
                .tag(0)

            ReminderRootView()
                .tabItem {
                    Label("Reminders", systemImage: "bell.fill")
                }
                .tag(1)

            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.circle.fill")
                }
                .tag(2)
        }
        .tint(Color(hex: "#60a5fa"))
        .onAppear {
            // Dark tab bar
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = UIColor(Color(hex: "#060d1a"))
            appearance.shadowColor = UIColor(Color(hex: "#0f1e35"))
            UITabBar.appearance().standardAppearance = appearance
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
    }
}
