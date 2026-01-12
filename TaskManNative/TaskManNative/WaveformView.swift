import SwiftUI

struct WaveformView: View {
    var color: Color = .red
    var barCount: Int = 5
    
    @State private var isAnimating = false
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<barCount, id: \.self) { index in
                RoundedRectangle(cornerRadius: 2)
                    .fill(color)
                    .frame(width: 4, height: isAnimating ? CGFloat.random(in: 10...30) : 4)
                    .animation(
                        Animation.easeInOut(duration: Double.random(in: 0.3...0.6))
                            .repeatForever(autoreverses: true)
                            .delay(Double.random(in: 0...0.2)),
                        value: isAnimating
                    )
            }
        }
        .onAppear {
            isAnimating = true
        }
    }
}

#Preview {
    WaveformView()
}
