import SwiftUI

struct AppLogoView: View {
    var body: some View {
        VStack(spacing: 10) {
            Text("Saschas LocalSync")
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .foregroundStyle(Color.yellow)
                .multilineTextAlignment(.center)

            Text("Dashboard")
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundStyle(Color(red: 0.66, green: 0.82, blue: 1.0))

            logoMark
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }

    private var logoMark: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color(red: 0.07, green: 0.18, blue: 0.45), Color(red: 0.14, green: 0.33, blue: 0.70)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 52, height: 52)

            HStack(spacing: 3) {
                Image(systemName: "externaldrive.fill")
                    .font(.system(size: 11, weight: .semibold))
                Image(systemName: "arrow.left.arrow.right")
                    .font(.system(size: 10, weight: .bold))
                Image(systemName: "iphone")
                    .font(.system(size: 11, weight: .semibold))
            }
            .foregroundStyle(Color(red: 0.84, green: 0.91, blue: 1.0))
        }
    }
}
