import SwiftUI

@main struct MyApp: App {
    @State private var showGame = false
    
    var body: some Scene {
        WindowGroup {
            Group {
                if showGame {
                    ContentView(onGoHome: {
                            showGame = false
                        })
                } else {
                    HomeView {
                        showGame = true
                    }
                }
            }
        }
    }
}
