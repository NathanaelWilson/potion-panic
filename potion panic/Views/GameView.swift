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
                // --- 1. HEADER (Timer Utama & Skor) ---
                HStack {
                    Text("\(viewModel.timeLeft)d")
                        .font(.system(size: 40, weight: .bold, design: .rounded))
                        .foregroundColor(viewModel.timeLeft < 30 ? .red : .white)
                    Spacer()
                    Text("Potion: \(viewModel.score)")
                        .font(.title2)
                        .foregroundColor(.white)
                        .bold()
                }
                .padding(.horizontal, 30)
                .padding(.top, 30)
                
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
                            // HANYA tampilkan jika index lebih kecil dari visibleItemsCount
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
                        Image(viewModel.currentExpression.rawValue)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 580)
                            .offset(y: isWitchFloating ? -3 : 3)
                            .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 10)
                            .onAppear {
                                withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                                    isWitchFloating = true
                                }
                            }
                        
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
                        
                        Image("cauldron")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 270, height: 270)
                            .shadow(color: .green.opacity(0.4), radius: 25, x: 0, y: 10)
                        
                        .background(GeometryReader { gp in
                            Color.clear.preference(key: RectPreferenceKey.self, value: gp.frame(in: .global))
                        })
                        .position(x: geometry.size.width / 2, y: geometry.size.height * 0.8)
                
                        
                        // 6 INGREDIENTS
                        DraggableIngredientView(ingredient: .pufferFish, viewModel: viewModel, cauldronFrame: cauldronFrame)
                            .position(x: geometry.size.width * 0.16, y: geometry.size.height * 0.14) // Kiri Atas
                            .disabled(viewModel.isSpawning)
                            .saturation(viewModel.isSpawning ? 0.0 : 1.0)
                        
                        DraggableIngredientView(ingredient: .spiderEye, viewModel: viewModel, cauldronFrame: cauldronFrame)
                            .position(x: geometry.size.width * 0.05, y: geometry.size.height * 0.4) // Kiri Tengah
                            .disabled(viewModel.isSpawning)
                            .saturation(viewModel.isSpawning ? 0.0 : 1.0)
                        
                        DraggableIngredientView(ingredient: .mushroom, viewModel: viewModel, cauldronFrame: cauldronFrame)
                            .position(x: geometry.size.width * 0.12, y: geometry.size.height * 0.7) // Kiri Bawah
                            .disabled(viewModel.isSpawning)
                            .saturation(viewModel.isSpawning ? 0.0 : 1.0)
                        
                        DraggableIngredientView(ingredient: .chickenFoot, viewModel: viewModel, cauldronFrame: cauldronFrame)
                            .position(x: geometry.size.width * 0.95, y: geometry.size.height * 0.15) // Kanan Atas
                            .disabled(viewModel.isSpawning)
                            .saturation(viewModel.isSpawning ? 0.0 : 1.0)
                        
                        DraggableIngredientView(ingredient: .goldenCarrot, viewModel: viewModel, cauldronFrame: cauldronFrame)
                            .position(x: geometry.size.width * 0.88, y: geometry.size.height * 0.48) // Kanan Tengah
                            .disabled(viewModel.isSpawning)
                            .saturation(viewModel.isSpawning ? 0.0 : 1.0)
                        
                        DraggableIngredientView(ingredient: .flower, viewModel: viewModel, cauldronFrame: cauldronFrame)
                            .position(x: geometry.size.width * 0.9, y: geometry.size.height * 0.8) // Kanan Bawah
                            .disabled(viewModel.isSpawning)
                            .saturation(viewModel.isSpawning ? 0.0 : 1.0)
                    }
                    
                }
                .padding(.horizontal, 10)
                .padding(.bottom, 20)
            }
            
            if viewModel.isGameOver {
                GameOverView(viewModel: viewModel)
                    .zIndex(2)
            }
        }
        .onPreferenceChange(RectPreferenceKey.self) { frame in
            self.cauldronFrame = frame
        }
        .onChange(of: viewModel.currentSequence) {
            startSequenceAppearanceAnimation()
        }
        .onAppear {
            startSequenceAppearanceAnimation()
            viewModel.blinkManager.start()
        }
        .onDisappear {
            viewModel.blinkManager.stop()
        }
    }
        
    private func startSequenceAppearanceAnimation() {
        visibleItemsCount = 0
        
        viewModel.isSpawning = true
        
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            visibleItemsCount = 1
        }
        
        // Timer lokal yang berjalan setiap 0.3 detik
        Timer.scheduledTimer(withTimeInterval: 0.3, repeats: true) { timer in
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                visibleItemsCount += 1
            }
                 
            // Kalau sudah 8 kotak muncul, matikan timer
            if visibleItemsCount >= 8 {
                timer.invalidate()
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.48) {
                    viewModel.isSpawning = false
                    SoundManager.shared.playBGM(soundName: "drag-and-drop", loops: 3)
                }
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
                    dragOffset = value.translation
                }
                .onEnded { value in
                    let finalGlobalLocation = value.location
                    let tolerantCauldronFrame = cauldronFrame.insetBy(dx: -40, dy: -40)

                    if tolerantCauldronFrame.contains(finalGlobalLocation) {
                        viewModel.handleDrop(ingredient: ingredient)
                    }
                    
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        dragOffset = .zero
                    }
                }
        )
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
