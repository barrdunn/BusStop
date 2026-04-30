import SwiftUI

struct ContentView: View {

    @EnvironmentObject var router: Router

    var body: some View {
        TabView(selection: $router.selectedTab) {
            FolderListView()
                .tabItem {
                    Label("Items", systemImage: "list.bullet")
                }
                .tag(Router.Tab.list)

            StudyView()
                .tabItem {
                    Label("Study", systemImage: "rectangle.on.rectangle.angled")
                }
                .tag(Router.Tab.study)

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
                .tag(Router.Tab.settings)
        }
    }
}
