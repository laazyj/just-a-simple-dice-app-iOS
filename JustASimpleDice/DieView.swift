import SwiftUI

struct DieView: View {
    let value: Int

    var body: some View {
        GeometryReader { geometry in
            let side = min(geometry.size.width, geometry.size.height)
            ZStack {
                RoundedRectangle(cornerRadius: side * 0.18, style: .continuous)
                    .fill(.white)
                    .shadow(color: .black.opacity(0.35), radius: side * 0.06, y: side * 0.04)
                ForEach(Array(Self.pipPositions(for: value).enumerated()), id: \.offset) { _, pip in
                    Circle()
                        .fill(.black)
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
