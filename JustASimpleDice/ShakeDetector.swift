import Combine
import SwiftUI
import UIKit

extension Notification.Name {
    static let deviceDidShake = Notification.Name("deviceDidShake")
}

extension UIWindow {
    override open func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        if motion == .motionShake {
            NotificationCenter.default.post(name: .deviceDidShake, object: nil)
        }
        super.motionEnded(motion, with: event)
    }
}

private struct ShakeViewModifier: ViewModifier {
    let action: @MainActor () -> Void

    func body(content: Content) -> some View {
        content.onReceive(
            NotificationCenter.default.publisher(for: .deviceDidShake)
        ) { _ in
            action()
        }
    }
}

extension View {
    func onShake(perform action: @escaping @MainActor () -> Void) -> some View {
        modifier(ShakeViewModifier(action: action))
    }
}
