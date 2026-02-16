import SwiftUI

// Helper for Visual Blur
struct VisualEffectBlur: UIViewRepresentable {
    var blurStyle: UIBlurEffect.Style

    func makeUIView(context: Context) -> UIVisualEffectView {
        return UIVisualEffectView(effect: UIBlurEffect(style: blurStyle))
    }

    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {
        uiView.effect = UIBlurEffect(style: blurStyle)
    }
}

// Custom Heart Shape
struct HeartShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        path.move(to: CGPoint(x: rect.midX, y: rect.maxY ))
        
        path.addCurve(to: CGPoint(x: rect.minX, y: rect.height * 0.25),
                      control1: CGPoint(x: rect.midX, y: rect.height * 0.75),
                      control2: CGPoint(x: rect.minX, y: rect.height * 0.5))
        
        path.addArc(center: CGPoint(x: rect.width * 0.25, y: rect.height * 0.25),
                    radius: rect.width * 0.25,
                    startAngle: Angle(radians: .pi),
                    endAngle: Angle(radians: 0),
                    clockwise: false)
        
        path.addArc(center: CGPoint(x: rect.width * 0.75, y: rect.height * 0.25),
                    radius: rect.width * 0.25,
                    startAngle: Angle(radians: .pi),
                    endAngle: Angle(radians: 0),
                    clockwise: false)
        
        path.addCurve(to: CGPoint(x: rect.midX, y: rect.maxY),
                      control1: CGPoint(x: rect.maxX, y: rect.height * 0.5),
                      control2: CGPoint(x: rect.midX, y: rect.height * 0.75))
        
        return path
    }
}
