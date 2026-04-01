import SwiftUI

struct RectPreferenceKey: PreferenceKey {
    typealias Value = CGRect
    static var defaultValue = CGRect.zero
    static func reduce(value: inout CGRect, nextValue: () -> CGRect) {
        value = nextValue()
    }
}

struct GameView: View {
    @StateObject private var viewModel = GameViewModel()
    
    @State private var cauldronFrame: CGRect = .zero
    @State private var visibleItemsCount: Int = 0
    @State private var isWitchFloating: Bool = false
    @State private var spawnTimer: Timer?
    
    // animasi text waktu
    @State private var floatingTimeOffset: CGFloat = 0
    @State private var floatingTimeOpacity: Double = 0
    
    // berubah
    @State private var sinkingItems: [SinkingEffectItem] = []
    
    var body: some View {
        ZStack {
            
            Image("witch_hut")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
            
            Color.black.opacity(0.2)
                .ignoresSafeArea()
            
            VStack {
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.black.opacity(0.8),
                        Color.black.opacity(0.4),
                        Color.clear
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 180)
                .ignoresSafeArea(edges: .top)
                
                Spacer()
            }
            VStack {
                // --- (Timer Utama & Skor) ---
                HStack {
                    ZStack(alignment: .topLeading) {
                        
                        // Timer Asli & Jam Pasir
                        HStack(spacing: 6) {
                            Image(systemName: "hourglass")
                                .font(.system(size: 25, weight: .bold))
                                .foregroundColor(viewModel.timeLeft < 30 ? .red : .white)
                                .scaleEffect(viewModel.timeLeft < 30 ? 1.1 : 1.0)
                                .animation(viewModel.timeLeft < 30 ? .easeInOut(duration: 0.5).repeatForever() : .default, value: viewModel.timeLeft < 30)
                            
                            Text("\(viewModel.timeLeft)d")
                                .font(.system(size: 30, weight: .bold, design: .rounded))
                                .foregroundColor(viewModel.timeLeft < 30 ? .red : .white)
                        }
                        
                        Text(viewModel.timeModifierText)
                            .font(.system(size: 28, weight: .heavy, design: .rounded))
                            .foregroundColor(viewModel.timeModifierColor)
                            .shadow(color: .black, radius: 2, x: 0, y: 2)
                            .offset(x: 40, y: floatingTimeOffset)
                            .opacity(floatingTimeOpacity)
                    }
                    Spacer()
                    
                    Text("Potion: \(viewModel.score)")
                        .font(.title2)
                        .foregroundColor(.white)
                        .bold()
                }
                .padding(.horizontal, 30)
                .padding(.top, 45)
                
                .onChange(of: viewModel.timeModifierTrigger) {
                    var transaction = Transaction()
                    transaction.disablesAnimations = true
                    withTransaction(transaction) {
                        floatingTimeOffset = 0
                        floatingTimeOpacity = 1.0
                    }

                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                        withAnimation(.easeOut(duration: 1.2)) {
                            floatingTimeOffset = -50
                            floatingTimeOpacity = 0.0
                        }
                    }
                }
                
                // Grid 8 ingredients
                VStack(spacing: 5) {
                    // Bar Waktu 10 Detik
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 5).fill(Color.gray.opacity(0.3))
                            RoundedRectangle(cornerRadius: 5)
                                .fill(Double(viewModel.potionTimeLeft) <= (viewModel.maxPotionTime * 0.3) ? Color.red : Color.yellow)
                                .frame(width: geo.size.width * (CGFloat(viewModel.potionTimeLeft) / CGFloat(viewModel.maxPotionTime)))
                                .animation(.linear(duration: 1.0), value: viewModel.potionTimeLeft)
                        }
                    }
                    .frame(width: 300, height: 10)
                    .padding(.bottom, 5)
                    
                    // Grid Kotak
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                        ForEach(0..<8, id: \.self) { index in
                            if index < visibleItemsCount {
                                SequenceBoxView(
                                    ingredient: viewModel.currentSequence.indices.contains(index) ? viewModel.currentSequence[index] : .mushroom,
                                    isActive: index == viewModel.currentIndex,
                                    isCompleted: index < viewModel.currentIndex
                                )
                                // Efek animasi pop-in saat muncul
                                .transition(.scale.combined(with: .opacity))
                            } else {
                                // Placeholder transparan agar ukuran grid tidak melompat-lompat
                                Color.clear.frame(height: 60)
                            }
                        }
                    }
                    .frame(width: 300)
                }
                .padding(.top, 10)

                
                // AREA DRAG & DROP (6 ingredients & Cauldron)
                GeometryReader { geometry in
                    ZStack {
                        ZStack {
                            Image(viewModel.currentWitchImage)
                                .resizable()
                                .scaledToFit()
                                .frame(height: 580)
                                .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 10)
                                .id(viewModel.currentWitchImage)
                                .transition(.scale(scale: 0.85).combined(with: .opacity))
                            
                            if let message = viewModel.witchMessage {
                                VStack(spacing: 0) {
                                    Text(message)
                                        .font(.system(size: 18, weight: .bold, design: .rounded))
                                        .foregroundColor(.black)
                                        .padding(.horizontal, 15)
                                        .padding(.vertical, 10)
                                        .background(Color.white)
                                        .cornerRadius(15)
                                        .shadow(color: .black.opacity(0.2), radius: 5, x: 0, y: 5)
                                    
                                    Image(systemName: "arrowtriangle.down.fill")
                                        .foregroundColor(.white)
                                        .font(.title3)
                                        .offset(x:-30, y: -4)
                                }

                                .offset(x: 45, y: -190)
                                .transition(.scale(scale: 0.5).combined(with: .opacity))
                                .zIndex(2)
                            }
                        }
                        .offset(y: isWitchFloating ? -3 : 3)
                        .onAppear {
                            restartFloating()
                        }
                        
                        .onChange(of: viewModel.currentWitchImage) {
                            restartFloating()
                        }
                        
                        
                        
                        Image("cauldron")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 270, height: 270)
                            .shadow(color: .green.opacity(0.4), radius: 25, x: 0, y: 10)
                        
                        .background(GeometryReader { gp in
                            Color.clear.preference(key: RectPreferenceKey.self, value: gp.frame(in: .global))
                        })
                        .position(x: geometry.size.width / 2, y: geometry.size.height * 0.8)
                
                        
                        // 6 INGREDIENTS // berubah
                        DraggableIngredientView(ingredient: .pufferFish, viewModel: viewModel, cauldronFrame: cauldronFrame) { droppedIngredient, dropLocation in
                            SoundManager.shared.playSFX(soundName: "splash")
                            let newSinkingItem = SinkingEffectItem(ingredient: .pufferFish, position: dropLocation)
                            sinkingItems.append(newSinkingItem)
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                                sinkingItems.removeAll { $0.id == newSinkingItem.id }
                            }
                        }
                            .position(x: geometry.size.width * 0.16, y: geometry.size.height * 0.14) // Kiri Atas
                            .saturation(viewModel.isSpawning ? 0.0 : 1.0)
                        
                        DraggableIngredientView(ingredient: .spiderEye, viewModel: viewModel, cauldronFrame: cauldronFrame) { droppedIngredient, dropLocation in
                            SoundManager.shared.playSFX(soundName: "splash")
                            let newSinkingItem = SinkingEffectItem(ingredient: .spiderEye, position: dropLocation)
                            sinkingItems.append(newSinkingItem)
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                                sinkingItems.removeAll { $0.id == newSinkingItem.id }
                            }
                        }
                            .position(x: geometry.size.width * 0.05, y: geometry.size.height * 0.4) // Kiri Tengah
                            .saturation(viewModel.isSpawning ? 0.0 : 1.0)
                        
                        DraggableIngredientView(ingredient: .mushroom, viewModel: viewModel, cauldronFrame: cauldronFrame) { droppedIngredient, dropLocation in
                            SoundManager.shared.playSFX(soundName: "splash")
                            let newSinkingItem = SinkingEffectItem(ingredient: .mushroom, position: dropLocation)
                            sinkingItems.append(newSinkingItem)
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                                sinkingItems.removeAll { $0.id == newSinkingItem.id }
                            }
                        }
                            .position(x: geometry.size.width * 0.12, y: geometry.size.height * 0.7) // Kiri Bawah
                            .saturation(viewModel.isSpawning ? 0.0 : 1.0)
                        
                        DraggableIngredientView(ingredient: .chickenFoot, viewModel: viewModel, cauldronFrame: cauldronFrame) { droppedIngredient, dropLocation in
                            SoundManager.shared.playSFX(soundName: "splash")
                            let newSinkingItem = SinkingEffectItem(ingredient: .chickenFoot, position: dropLocation)
                            sinkingItems.append(newSinkingItem)
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                                sinkingItems.removeAll { $0.id == newSinkingItem.id }
                            }
                        }
                            .position(x: geometry.size.width * 0.95, y: geometry.size.height * 0.15) // Kanan Atas
                            .saturation(viewModel.isSpawning ? 0.0 : 1.0)
                        
                        DraggableIngredientView(ingredient: .goldenCarrot, viewModel: viewModel, cauldronFrame: cauldronFrame) { droppedIngredient, dropLocation in
                            SoundManager.shared.playSFX(soundName: "splash")
                            let newSinkingItem = SinkingEffectItem(ingredient: .goldenCarrot, position: dropLocation)
                            sinkingItems.append(newSinkingItem)
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                                sinkingItems.removeAll { $0.id == newSinkingItem.id }
                            }
                        }
                            .position(x: geometry.size.width * 0.88, y: geometry.size.height * 0.48) // Kanan Tengah
                            .saturation(viewModel.isSpawning ? 0.0 : 1.0)
                        
                        DraggableIngredientView(ingredient: .flower, viewModel: viewModel, cauldronFrame: cauldronFrame) { droppedIngredient, dropLocation in
                            SoundManager.shared.playSFX(soundName: "splash")
                            let newSinkingItem = SinkingEffectItem(ingredient: .flower, position: dropLocation)
                            sinkingItems.append(newSinkingItem)
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                                sinkingItems.removeAll { $0.id == newSinkingItem.id }
                            }
                        }
                            .position(x: geometry.size.width * 0.93, y: geometry.size.height * 0.76) // Kanan Bawah
                            .saturation(viewModel.isSpawning ? 0.0 : 1.0)
                    }
                    
                }
                .padding(.horizontal, 10)
                .padding(.bottom, 20)
            }
            
            // berubah
            ForEach(sinkingItems) { item in
                SinkingEffectView(item: item)
            }
            .ignoresSafeArea()
            .allowsHitTesting(false)
            
            // explosion
            if viewModel.showExplosion {
                Image("exploded_potion")
                    .resizable()
                    .ignoresSafeArea()
  
                    .transition(
                        .scale(scale: 0.1)
                        .combined(with: .opacity)
                    )
                    
                    .zIndex(10)
            }
            
            // countdown
            if viewModel.showCountdown {
                ZStack {
                    Color.black.opacity(0.7)
                        .ignoresSafeArea()
                    
                    Text(viewModel.countdownText)
                        .font(.system(size: 55, weight: .black, design: .rounded))
                        .foregroundColor(viewModel.countdownText == "BREW!" ? .green : .orange)
                        .shadow(color: .black, radius: 5, x: 0, y: 5)
                        .id(viewModel.countdownText)
                        .transition(.scale(scale: 0.5).combined(with: .opacity))
                }
                .zIndex(3)
            }
            
            if viewModel.showNarrative {
                ZStack {
                    // Latar belakang hitam pekat
                    Color.black.ignoresSafeArea()
                        .opacity(0.7)
                    // Teks Narasi
                    Text(viewModel.narrativeText)
                        // Font serif (seperti Times New Roman) memberikan kesan klasik/puisi yang dalam
                        .font(.system(size: 28, weight: .medium, design: .serif))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                        
                        // Modifier .id memaksa efek fade-in fade-out saat teks berganti
                        .id(viewModel.narrativeText)
                        .transition(.opacity)
                }
                .zIndex(2) // Berada di atas elemen game
            }
            
            if viewModel.isGameOver {
                GameOverView(viewModel: viewModel)
                    .zIndex(2)
            }
        }
        
        //
        .onPreferenceChange(RectPreferenceKey.self) { frame in
            self.cauldronFrame = frame
        }
        .onChange(of: viewModel.currentSequence) {
            if !viewModel.showCountdown {
                startSequenceAppearanceAnimation()
            }
        }
        .onAppear {
            viewModel.blinkManager.start()
            viewModel.startNewGame()
        }
        .onDisappear {
            viewModel.blinkManager.stop()
        }
    }
    
    private func startSequenceAppearanceAnimation() {
        spawnTimer?.invalidate()
        spawnTimer = nil
        
        visibleItemsCount = 0
        viewModel.isSpawning = true
        
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            visibleItemsCount = 1
        }
        
        // Timer lokal yang berjalan setiap 0.3 detik
        spawnTimer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: true) { timer in
            guard viewModel.timeLeft > 0 else {
                timer.invalidate()
                self.spawnTimer = nil
                return
            }
            
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                visibleItemsCount += 1
            }
                 
            // Kalau sudah 8 kotak muncul, matikan timer
            if visibleItemsCount >= 8 {
                timer.invalidate()
                self.spawnTimer = nil
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.48) {
                    guard viewModel.timeLeft > 0 else { return }
                    viewModel.isSpawning = false
                    SoundManager.shared.playBGM(soundName: "drag-and-drop", loops: 3)
                }
            }
        }
    }
    
    private func restartFloating() {
        // Matikan animasi sejenak
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) {
            isWitchFloating = false
        }
    
        if viewModel.currentExpression == .fainting || viewModel.currentExpression == .passedOut {
            return
        }
        
        // Nyalakan lagi
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                self.isWitchFloating = true
            }
        }
    }
}

struct SequenceBoxView: View {
    var ingredient: Ingredient
    var isActive: Bool
    var isCompleted: Bool
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.brown.opacity(0.9))
                .frame(height: 60)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(isActive ? Color.white : Color.clear, lineWidth: 4)
                        .shadow(color: isActive ? Color.white : Color.clear, radius: 5)
                )
            
            Image(ingredient.imageName)
                .resizable()
                .scaledToFit()
                .frame(width: 50, height: 50)
                .shadow(color: .black.opacity(0.3), radius: 5, x: 0, y: 5)
        }
        .opacity(isCompleted ? 0.0 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isCompleted)
        .animation(.easeInOut(duration: 0.2), value: isActive)
    }
}

struct DraggableIngredientView: View {
    var ingredient: Ingredient
    @ObservedObject var viewModel: GameViewModel
    var cauldronFrame: CGRect
    
    @State private var dragOffset: CGSize = .zero
    let onSuccessfulDrop: (Ingredient, CGPoint) -> Void
    
    private var isDropEnabled: Bool {
        !viewModel.isSpawning && viewModel.timeLeft > 0 && !viewModel.isGameOver
    }
    
    var body: some View {
        Image(ingredient.imageName)
            .resizable()
            .scaledToFit()
            .frame(width: 70, height: 70)
            .shadow(color: .black.opacity(0.3), radius: 5, x: 0, y: 5)
        .offset(dragOffset)
        .gesture(
            DragGesture(coordinateSpace: .global)
                .onChanged { value in
                    guard isDropEnabled else { return }
                    dragOffset = value.translation
                }
                .onEnded { value in
                    guard isDropEnabled else {
                        dragOffset = .zero
                        return
                    }
                    
                    let finalGlobalLocation = value.location
                    let tolerantCauldronFrame = cauldronFrame.insetBy(dx: -40, dy: -40)

                    if tolerantCauldronFrame.contains(finalGlobalLocation) {
                        let targetLiquidPoint = CGPoint(
                            x: cauldronFrame.midX,
                            y: cauldronFrame.midY - 80
                        )
                        onSuccessfulDrop(ingredient, targetLiquidPoint)
                        viewModel.handleDrop(ingredient: ingredient)
                    }
                    
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        dragOffset = .zero
                    }
                }
        )
        .allowsHitTesting(isDropEnabled)
        .zIndex(dragOffset == .zero ? 0 : 1)
    }
}

// MARK: - Layar Game Over
struct GameOverView: View {
    @ObservedObject var viewModel: GameViewModel
    
    var body: some View {
        ZStack {
            // Overlay Hitam
            Color.black.opacity(0.8)
                .ignoresSafeArea()
            
            // Kotak Pop-up
            VStack(spacing: 20) {
                ZStack(alignment: .bottom) {
                    Image("end_screen")
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: 320)
                        .shadow(color: .green.opacity(0.3), radius: 20, x: 0, y: 0)
                    
                    Text("Potions Brewed: \(viewModel.score)")
                        .font(.system(size: 22, weight: .heavy, design: .rounded))
                        .foregroundColor(.white)
                        .padding(.bottom, 28)
                }
                
                VStack(spacing: 15) {
                    Button(action: {
                        viewModel.startNewGame()
                    }) {
                        Text("PLAY AGAIN")
                            .font(.headline)
                            .fontWeight(.heavy)
                            .foregroundColor(.white)
                            .frame(maxWidth: 220)
                            .padding(.vertical, 15)
                            .background(
                                LinearGradient(gradient: Gradient(colors: [Color.orange, Color.red]), startPoint: .top, endPoint: .bottom)
                            )
                            .cornerRadius(20)
                            .shadow(color: .orange.opacity(0.5), radius: 10, x: 0, y: 5)
                    }
                }
                .padding(.top, 10)
                
            }
            .transition(.scale(scale: 0.8).combined(with: .opacity))
        }
    }
}

#Preview {
    GameView()
}
