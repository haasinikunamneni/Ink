import SwiftUI

struct ContentView: View {
    @EnvironmentObject var store: JournalStore
    @FocusState private var todayFieldFocused: Bool

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 30) {
                dateHeader

                UpcomingBoxView()
                    .environmentObject(store)

                TodayPageView(isFocused: $todayFieldFocused)
                    .environmentObject(store)
            }
            .padding(36)
            .frame(maxWidth: .infinity, alignment: .topLeading)
        }
        .scrollIndicators(.automatic)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(backgroundColor)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
                todayFieldFocused = true
            }
        }
    }

    private var backgroundColor: Color {
        store.settings.theme == .trueBlack ? Color.black : Color(white: 0.07)
    }

    private var dateHeader: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(DateFormatting.weekday(for: Date()))
                .font(.custom(store.settings.fontName, size: 15))
                .foregroundColor(.white.opacity(0.5))
            Text(DateFormatting.longDate(for: Date()))
                .font(.custom(store.settings.fontName, size: 26))
                .foregroundColor(.white.opacity(0.92))
        }
    }
}
