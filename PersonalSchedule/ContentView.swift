import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "checklist")
                .font(.system(size: 56))
                .foregroundStyle(.tint)
            Text("你好！")
                .font(.largeTitle)
            Text("Personal Schedule")
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    ContentView()
}
