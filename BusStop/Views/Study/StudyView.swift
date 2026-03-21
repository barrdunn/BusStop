import SwiftUI

struct StudyView: View {
    
    @EnvironmentObject var settings: SettingsManager
    
    @ObservedObject var customStore = CustomItemsStore.shared
    
    private var items: [MemoryItem] {
        MemoryItemsData.resolved(breakDown: settings.breakDownItems, includeStabilized: settings.includeStabilized, custom: customStore.items)
    }
    
    @State private var shuffled: [MemoryItem] = []
    @State private var currentIndex: Int = 0
    @State private var showAnswer: Bool = false
    @State private var flipDegrees: Double = 0
    @State private var shuffleAngle: Double = 0
    @State private var shuffleMode: Bool = false
    
    @State private var dragOffset: CGSize = .zero
    @State private var isDragging: Bool = false
    @State private var animatingSwipe: Bool = false
    @State private var swipeDirection: CGFloat = 0
    
    var body: some View {
        VStack(spacing: 0) {
            if shuffled.isEmpty {
                Spacer()
                ProgressView()
                Spacer()
            } else {
                HStack(alignment: .center) {
                    Text("Study")
                        .font(.largeTitle.bold())
                    
                    Spacer()
                    
                    Button { toggleShuffle() } label: {
                        Image(systemName: "shuffle")
                            .font(.title2)
                            .foregroundStyle(shuffleMode ? .blue : .secondary)
                            .rotationEffect(.degrees(shuffleAngle))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 50)
                
                cardView
                    .padding(.horizontal, 20)
                
                Spacer()
            }
        }
        .onAppear {
            if shuffled.isEmpty { reshuffle() }
        }
        .onChange(of: settings.breakDownItems) { _, _ in reshuffle() }
        .onChange(of: settings.includeStabilized) { _, _ in reshuffle() }
    }
    
    // MARK: - Card
    
    private var currentItem: MemoryItem { shuffled[currentIndex] }
    
    private var cardView: some View {
        GeometryReader { geo in
            ZStack {
                answerSide
                    .rotation3DEffect(.degrees(flipDegrees + 180), axis: (x: 0, y: 1, z: 0))
                    .opacity(showAnswer ? 1 : 0)
                    .allowsHitTesting(showAnswer)
                
                promptSide
                    .rotation3DEffect(.degrees(flipDegrees), axis: (x: 0, y: 1, z: 0))
                    .opacity(showAnswer ? 0 : 1)
                    .allowsHitTesting(!showAnswer)
            }
            .offset(x: dragOffset.width, y: dragOffset.height)
            .rotationEffect(.degrees(Double(dragOffset.width) / 20), anchor: .bottom)
            .frame(width: geo.size.width, height: geo.size.height)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 10)
                    .onChanged { value in
                        if !isDragging {
                            if abs(value.translation.width) > abs(value.translation.height) {
                                isDragging = true
                            } else {
                                return
                            }
                        }
                        dragOffset = value.translation
                    }
                    .onEnded { value in
                        if !isDragging {
                            isDragging = false
                            return
                        }
                        isDragging = false
                        
                        let threshold: CGFloat = 80
                        let velocity = value.predictedEndTranslation.width
                        
                        if abs(value.translation.width) > threshold || abs(velocity) > 300 {
                            let direction: CGFloat = value.translation.width > 0 ? 1 : -1
                            swipeOut(direction: direction, lastY: value.translation.height)
                        } else {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                dragOffset = .zero
                            }
                        }
                    }
            )
            .onTapGesture { flipCard() }
        }
        .frame(maxHeight: 500)
    }
    
    private var promptSide: some View {
        VStack(spacing: 12) {
            Spacer()
            
            Text(currentItem.title)
                .font(.title2.bold())
                .multilineTextAlignment(.center)
            
            if !currentItem.reference.isEmpty {
                Text(currentItem.reference)
                    .font(.subheadline)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
            }
            
            Spacer()
            
            Text("Tap to flip · Swipe for next")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(20)
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemBackground))
                .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
        }
    }
    
    private var answerSide: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 8) {
                Text(currentItem.title)
                    .font(.headline)
                
                Text(currentItem.body)
                    .font(.body)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
            .padding(.top, 20)
            
            Spacer()
            
            Text("Tap to flip · Swipe for next")
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity)
                .padding(.bottom, 12)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemBackground))
                .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
        }
    }
    
    // MARK: - Swipe
    
    private func swipeOut(direction: CGFloat, lastY: CGFloat) {
        animatingSwipe = true
        swipeDirection = direction
        
        let screenWidth = UIScreen.main.bounds.width
        let exitX = direction * (screenWidth + 100)
        let yRatio = dragOffset.width != 0 ? lastY / abs(dragOffset.width) : 0
        let exitY = abs(exitX) * yRatio
        
        withAnimation(.easeIn(duration: 0.15)) {
            dragOffset = CGSize(width: exitX, height: exitY)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            if shuffleMode {
                goRandom()
            } else if direction < 0 {
                currentIndex = currentIndex < shuffled.count - 1 ? currentIndex + 1 : 0
            } else {
                currentIndex = currentIndex > 0 ? currentIndex - 1 : shuffled.count - 1
            }
            
            resetFlip()
            animatingSwipe = false
            
            dragOffset = CGSize(width: -swipeDirection * (screenWidth + 100), height: 0)
            
            withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                dragOffset = .zero
            }
        }
    }
    
    // MARK: - Actions
    
    private func flipCard() {
        let targetDegrees: Double = showAnswer ? 0 : 180
        withAnimation(.easeInOut(duration: 0.4)) {
            flipDegrees = targetDegrees
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            showAnswer.toggle()
        }
    }
    
    private func resetFlip() {
        flipDegrees = 0
        showAnswer = false
    }
    
    private func goRandom() {
        guard shuffled.count > 1 else { return }
        var next = currentIndex
        while next == currentIndex {
            next = Int.random(in: 0..<shuffled.count)
        }
        currentIndex = next
    }
    
    private func toggleShuffle() {
        shuffleMode.toggle()
        withAnimation(.easeInOut(duration: 0.4)) {
            shuffleAngle += 360
        }
        if shuffleMode {
            if showAnswer {
                withAnimation(.easeInOut(duration: 0.3)) {
                    flipDegrees = 0
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    showAnswer = false
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                    shuffled = items.shuffled()
                    currentIndex = 0
                    resetFlip()
                }
            } else {
                shuffled = items.shuffled()
                currentIndex = 0
                resetFlip()
            }
        }
    }
    
    private func reshuffle() {
        shuffled = items.shuffled()
        currentIndex = 0
        resetFlip()
        shuffleMode = false
    }
}

struct SwipeEffects: ViewModifier {
    let offset: CGFloat
    let active: Bool
    
    func body(content: Content) -> some View {
        if active {
            content
                .scaleEffect(1.0 - min(abs(offset) / 2000, 0.08))
        } else {
            content
        }
    }
}
