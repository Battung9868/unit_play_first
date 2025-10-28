//
//
//

import SwiftUI

struct TemporalVisualizer: View {
    
    
    let timeRemaining: Int
    let currentPhase: PreparationLayer
    let isActive: Bool
    let progress: Double
    
    
    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .stroke(lineWidth: 8)
                    .opacity(0.3)
                    .foregroundColor(Color("TimerRingBackground"))
                
                Circle()
                    .trim(from: 0.0, to: CGFloat(progress))
                    .stroke(
                        LinearGradient(
                            colors: [Color("TimerRingRound"), Color("TimerRingRest")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.5), value: progress)
                
                VStack(spacing: 8) {
                    Text(ChronologyFormatter.renderDuration(timeRemaining))
                        .font(.system(size: 48, weight: .bold, design: .monospaced))
                        .foregroundColor(isActive ? Color("PrimaryText") : Color("TimerInactiveText"))
                        .animation(.easeInOut(duration: 0.5), value: timeRemaining)
                    
                    if isActive {
                        Text(currentPhase.displayName)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Color("SecondaryText"))
                            .animation(.easeInOut(duration: 0.5), value: currentPhase)
                    }
                }
            }
            .frame(width: 200, height: 200)
        }
    }
}

struct CycleIndicator: View {
    
    
    let currentRound: Int
    let totalRounds: Int
    
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(1...totalRounds, id: \.self) { round in
                Circle()
                    .fill(round <= currentRound ? Color("Accent") : Color("TimerRingBackground"))
                    .frame(width: 12, height: 12)
                    .animation(.easeInOut(duration: 0.3), value: currentRound)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color("Background"))
                .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
        )
    }
}

struct LayerStatusBadge: View {
    
    
    let currentPhase: PreparationLayer
    let isActive: Bool
    
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: phaseIcon)
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(isActive ? Color("Accent") : Color("SecondaryText"))
            
            Text(currentPhase.displayName)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(isActive ? Color("PrimaryText") : Color("SecondaryText"))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isActive ? Color("Accent").opacity(0.1) : Color("Background"))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isActive ? Color("Accent") : Color("Border"), lineWidth: 1)
                )
        )
        .animation(.easeInOut(duration: 0.3), value: currentPhase)
        .animation(.easeInOut(duration: 0.3), value: isActive)
    }
    
    
    private var phaseIcon: String {
        switch currentPhase {
        case .foundation:
            return "leaf.fill"
        case .base:
            return "circle.fill"
        case .complement:
            return "fish.fill"
        case .interval:
            return "pause.circle.fill"
        }
    }
}


#Preview {
    VStack(spacing: 20) {
        TemporalVisualizer(
            timeRemaining: 180,
            currentPhase: .foundation,
            isActive: true,
            progress: 0.6
        )
        
        CycleIndicator(
            currentRound: 2,
            totalRounds: 3
        )
        
        LayerStatusBadge(
            currentPhase: .foundation,
            isActive: true
        )
    }
    .padding()
    .background(Color("Background"))
}
