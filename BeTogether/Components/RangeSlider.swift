import SwiftUI

struct RangeSlider: View {
    @Binding var range: ClosedRange<Double>
    let bounds: ClosedRange<Double>
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 4)
                
                Rectangle()
                    .fill(Color.btTeal)
                    .frame(width: width(for: range, in: geometry), height: 4)
                    .offset(x: offset(for: range.lowerBound, in: geometry))
                
                Circle()
                    .fill(Color.white)
                    .shadow(radius: 2)
                    .frame(width: 20, height: 20)
                    .offset(x: offset(for: range.lowerBound, in: geometry))
                    .gesture(
                        DragGesture().onChanged { value in
                            let location = value.location.x
                            let percentage = location / geometry.size.width
                            let newValue = bounds.lowerBound + (bounds.upperBound - bounds.lowerBound) * Double(percentage)
                            if newValue < range.upperBound - 1 && newValue >= bounds.lowerBound {
                                range = newValue...range.upperBound
                            }
                        }
                    )
                
                Circle()
                    .fill(Color.white)
                    .shadow(radius: 2)
                    .frame(width: 20, height: 20)
                    .offset(x: offset(for: range.upperBound, in: geometry) - 20) // -20 to center on end
                    .gesture(
                        DragGesture().onChanged { value in
                            let location = value.location.x
                            let percentage = location / geometry.size.width
                            let newValue = bounds.lowerBound + (bounds.upperBound - bounds.lowerBound) * Double(percentage)
                            if newValue > range.lowerBound + 1 && newValue <= bounds.upperBound {
                                range = range.lowerBound...newValue
                            }
                        }
                    )
            }
            .frame(height: 20)
        }
    }
    
    func width(for range: ClosedRange<Double>, in geometry: GeometryProxy) -> CGFloat {
        let total = bounds.upperBound - bounds.lowerBound
        let covered = range.upperBound - range.lowerBound
        return geometry.size.width * CGFloat(covered / total)
    }
    
    func offset(for value: Double, in geometry: GeometryProxy) -> CGFloat {
        let total = bounds.upperBound - bounds.lowerBound
        let current = value - bounds.lowerBound
        return geometry.size.width * CGFloat(current / total)
    }
}
