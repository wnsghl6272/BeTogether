import SwiftUI

struct MBTIManualInputView: View {
    @EnvironmentObject var userSession: UserSessionViewModel
    
    // Sliders: 0 = Left (E/S/T/J), 1 = Right (I/N/F/P)
    // Actually standard MBTI is E vs I, S vs N, T vs F, J vs P
    // Let's toggle between two states.
    @State private var ei: Double = 0 // 0: E, 1: I
    @State private var ns: Double = 0 // 0: N, 1: S (Note: N is commonly first in acronym but S often depicted left. Let's follow image: N left, S right)
    // Wait, typical ordering is E-I, S-N, T-F, J-P.
    // Image says:
    // E (Extrovert) --- O O O O --- I (Introvert)
    // N (Intuitive) --- O O O O --- S (Observant)
    // F (Feeling)   --- O O O O --- T (Thinking)
    // P (Perceiving)--- O O O O --- J (Judging)
    
    @State private var eiValue: Double = 0.5
    @State private var nsValue: Double = 0.5
    @State private var ftValue: Double = 0.5
    @State private var pjValue: Double = 0.5
    
    var mbtiResult: String {
        let eOrI = eiValue < 0.5 ? "E" : "I"
        let nOrS = nsValue < 0.5 ? "N" : "S"
        let fOrT = ftValue < 0.5 ? "F" : "T"
        let pOrJ = pjValue < 0.5 ? "P" : "J"
        return "\(eOrI)\(nOrS)\(fOrT)\(pOrJ)"
    }
    
    var body: some View {
        ZStack {
            Color.btIvory.edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 30) {
                // Header
                VStack(spacing: 10) {
                    Text("What is your")
                        .font(.btHeader)
                        .foregroundColor(.black)
                    Text("personality type?")
                        .font(.btHeader)
                        .foregroundColor(.black)
                }
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, 30)
                .padding(.top, 50)
                
                // Sliders
                VStack(spacing: 25) {
                    mbtiSlider(left: "E", leftDesc: "Extrovert", right: "I", rightDesc: "Introvert", value: $eiValue)
                    mbtiSlider(left: "N", leftDesc: "Intuitive", right: "S", rightDesc: "Observant", value: $nsValue)
                    mbtiSlider(left: "F", leftDesc: "Feeling", right: "T", rightDesc: "Thinking", value: $ftValue)
                    mbtiSlider(left: "P", leftDesc: "Perceiving", right: "J", rightDesc: "Judging", value: $pjValue)
                }
                .padding(.horizontal, 30)
                
                Spacer()
                
                // Complete Button
                BTButton(title: "Complete Setup", action: {
                    userSession.mbtiResult = mbtiResult
                    userSession.advanceToNextStep()
                }, isDisabled: eiValue == 0.5 || nsValue == 0.5 || ftValue == 0.5 || pjValue == 0.5)
                .padding(.horizontal, 40)
                
                // Don't know link
                Button(action: {
                    userSession.startMBTITest()
                }) {
                    Text("Don't know your personality type?")
                        .font(.btBody)
                        .foregroundColor(.gray)
                        .underline()
                }
                .padding(.bottom, 20)
            }
        }
    }
    
    func mbtiSlider(left: String, leftDesc: String, right: String, rightDesc: String, value: Binding<Double>) -> some View {
        VStack(spacing: 5) {
            HStack {
                Text(left)
                    .font(.btButton)
                    .foregroundColor(value.wrappedValue < 0.5 ? .btTeal : .gray.opacity(0.5))
                Spacer()
                Text(right)
                    .font(.btButton)
                    .foregroundColor(value.wrappedValue > 0.5 ? .btTeal : .gray.opacity(0.5))
            }
            
            Slider(value: value, in: 0...1, step: 0.33) // 4 steps: 0, 0.33, 0.66, 1
                .accentColor(.btTeal)
            
            HStack {
                Text(leftDesc)
                    .font(.caption)
                    .foregroundColor(.gray)
                Spacer()
                Text(rightDesc)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
    }
}

#Preview {
    MBTIManualInputView()
        .environmentObject(UserSessionViewModel())
}
