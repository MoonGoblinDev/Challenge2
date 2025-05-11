import SwiftUI

@main
struct TennisGameHostApp: App {
    var body: some Scene {
        WindowGroup {
            MainView()
                .frame(minWidth: 800, minHeight: 600)
                .onAppear {
                    // Set the default appearance
                    NSWindow.allowsAutomaticWindowTabbing = false
                    
                    // Configure the app name in menu
                    NSApplication.shared.setActivationPolicy(.regular)
                }
        }
        .windowStyle(HiddenTitleBarWindowStyle())
        .commands {
            // Add custom menu commands
            CommandGroup(replacing: .appInfo) {
                Button("About Tennis Game Host") {
                    showAboutPanel()
                }
            }
            
            // Add Help menu
            CommandGroup(replacing: .help) {
                Button("Tennis Game Host Help") {
                    showHelp()
                }
            }
        }
    }
    
    // Show custom about panel
    private func showAboutPanel() {
        let aboutPanel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 300, height: 200),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: true
        )
        
        aboutPanel.center()
        aboutPanel.title = "About Tennis Game Host"
        
        let contentView = NSHostingView(rootView: AboutView())
        aboutPanel.contentView = contentView
        
        NSApp.runModal(for: aboutPanel)
        aboutPanel.close()
    }
    
    // Show help window
    private func showHelp() {
        let helpPanel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 300),
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered,
            defer: true
        )
        
        helpPanel.center()
        helpPanel.title = "Tennis Game Host Help"
        
        let contentView = NSHostingView(rootView: HelpView())
        helpPanel.contentView = contentView
        
        NSApp.runModal(for: helpPanel)
        helpPanel.close()
    }
}

// About panel view
struct AboutView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "gamecontroller.fill")
                .font(.system(size: 48))
                .foregroundColor(.blue)
            
            Text("Tennis Game Host")
                .font(.title)
                .fontWeight(.bold)
            
            Text("Version \(Constants.appVersion)")
                .font(.subheadline)
            
            Text("© 2025 Your Company Name")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Button("Close") {
                NSApp.stopModal()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding(.top)
        }
        .frame(width: 300, height: 200)
        .padding()
    }
}

// Help view
struct HelpView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Tennis Game Host - Help Guide")
                    .font(.title)
                    .fontWeight(.bold)
                
                Group {
                    Text("Getting Started")
                        .font(.headline)
                    
                    Text("1. Click 'Start Hosting' to begin accepting connections from iPhone controllers.")
                    Text("2. Install the Tennis Controller app on iPhones.")
                    Text("3. Launch the controller app and connect to this Mac.")
                    Text("4. Once connected, player tiles will display gyroscope data in real-time.")
                }
                
                Group {
                    Text("Troubleshooting")
                        .font(.headline)
                        .padding(.top)
                    
                    Text("• Ensure Bluetooth is enabled on both Mac and iPhones.")
                    Text("• Devices should be on the same Wi-Fi network.")
                    Text("• Try restarting the host if connections fail.")
                    Text("• Make sure no firewalls are blocking MultipeerConnectivity.")
                }
                
                Group {
                    Text("System Requirements")
                        .font(.headline)
                        .padding(.top)
                    
                    Text("• macOS 12.0 or later")
                    Text("• iOS 15.0 or later for controller devices")
                    Text("• Bluetooth 5.0 recommended")
                    Text("• Wi-Fi network for optimal performance")
                }
                
                Button("Close") {
                    NSApp.stopModal()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top)
            }
            .padding()
        }
        .frame(width: 400, height: 300)
    }
}
