import SwiftUI

struct HomeView: View {
    @State private var isGameStarted: Bool = false
    
    @AppStorage("highScore") private var highScore: Int = 0
    
    @State private var isTitleFloating: Bool = false
    
    var body: some View {
        
        if !isGameStarted {
            ZStack {
                // --- BACKGROUND ---
                Image("witch_hut")
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()
                
                // Overlay
                Color.black.opacity(0.5).ignoresSafeArea()
                
                VStack {
                    Image("title")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 380, height: 380)
                        .offset(y: isTitleFloating ? -3 : 3)
                        .shadow(color: .green.opacity(0.4), radius: 20, x: 0, y: 10)
                        .onAppear {
                            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                                isTitleFloating = true
                            }
                        }
                    
                    
                    Button(action: {
                        SoundManager.shared.playSFX(soundName: "sfx_success")
                        isGameStarted = true
                    }) {
                        Text("START")
                            .font(.system(size: 40, weight: .heavy, design: .rounded))
                            .foregroundColor(.white)
                            .padding(.horizontal, 60)
                            .padding(.vertical, 10)
                            .background(
                                LinearGradient(gradient: Gradient(colors: [Color.orange, Color.red]), startPoint: .top, endPoint: .bottom)
                            )
                            .cornerRadius(15)
                            .shadow(color: .orange.opacity(0.5), radius: 15, x: 0, y: 10)
                    }
                    .padding(.bottom, 20)
                }
            }
            .transition(.opacity)
        } else {
            GameView()
                .transition(.opacity)
        }
        
    }
}

#Preview {
    HomeView()
}
