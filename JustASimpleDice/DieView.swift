import SwiftUI

struct DieView: View {
    let value: Int

    var body: some View {
        GeometryReader { geometry in
            let side = min(geometry.size.width, geometry.size.height)
            let face = RoundedRectangle(cornerRadius: side * 0.18, style: .continuous)
            ZStack {
                face
                    .fill(
                        LinearGradient(
                            colors: [.white, Color(white: 0.96), Color(white: 0.88)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: .black.opacity(0.35), radius: side * 0.06, y: side * 0.04)
                face
                    .strokeBorder(
                        LinearGradient(
                            colors: [.white.opacity(0.95), .black.opacity(0.12)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: side * 0.02
                    )
                face
                    .fill(
                        RadialGradient(
                            colors: [.white.opacity(0.7), .clear],
                            center: UnitPoint(x: 0.26, y: 0.2),
                            startRadius: 0,
                            endRadius: side * 0.5
                        )
                    )
                ForEach(Array(Self.pipPositions(for: value).enumerated()), id: \.offset) { _, pip in
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Color(white: 0.25), .black],
                                center: UnitPoint(x: 0.38, y: 0.32),
                                startRadius: 0,
                                endRadius: side * 0.10
                            )
                        )
                        .frame(width: side * 0.16, height: side * 0.16)
                        .position(x: pip.x * side, y: pip.y * side)
                }
            }
            .frame(width: side, height: side)
        }
        .aspectRatio(1, contentMode: .fit)
    }

    nonisolated static func pipPositions(for value: Int) -> [CGPoint] {
        let low: CGFloat = 0.26
        let mid: CGFloat = 0.5
        let high: CGFloat = 0.74
        switch value {
        case 1:
            return [CGPoint(x: mid, y: mid)]
        case 2:
            return [CGPoint(x: high, y: low), CGPoint(x: low, y: high)]
        case 3:
            return [CGPoint(x: high, y: low), CGPoint(x: mid, y: mid), CGPoint(x: low, y: high)]
        case 4:
            return [
                CGPoint(x: low, y: low), CGPoint(x: high, y: low),
                CGPoint(x: low, y: high), CGPoint(x: high, y: high),
            ]
        case 5:
            return [
                CGPoint(x: low, y: low), CGPoint(x: high, y: low),
                CGPoint(x: mid, y: mid),
                CGPoint(x: low, y: high), CGPoint(x: high, y: high),
            ]
        case 6:
            return [
                CGPoint(x: low, y: low), CGPoint(x: high, y: low),
                CGPoint(x: low, y: mid), CGPoint(x: high, y: mid),
                CGPoint(x: low, y: high), CGPoint(x: high, y: high),
            ]
        default:
            return []
        }
    }
}

#Preview {
    HStack {
        DieView(value: 3)
        DieView(value: 6)
    }
    .padding()
    .background(Color("FeltGreen"))
}
