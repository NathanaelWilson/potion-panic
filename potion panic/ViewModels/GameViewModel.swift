import Foundation
import SwiftUI
import Combine

enum WitchExpression: String {
    case regular = "regular_witch"
    case angry = "angry_witch"
    case celebrate = "celebrating_witch"
    case nervous = "nervous_witch"
    
    case explode = "exploded_witch"
    case fainting = "fainting_witch"
    case passedOut = "passed_out_witch"
}

class GameViewModel: ObservableObject {
    @Published var timeLeft: Int = 100
    @Published var score: Int = 0
    var maxPotionTime: Double {
            if score >= 10 {
                return 3.0 // Hardcore!
            } else if score >= 6 {
                return 5.0 // Hard
            } else if score >= 3 {
                return 7.0 // Medium
            } else {
                return 10.0 // Normal
            }
        }
    @Published var potionTimeLeft: Int = 10
    @Published var isGameOver: Bool = false
    
    // potion ingrredients
    @Published var isSpawning: Bool = true
    @Published var currentSequence: [Ingredient] = []
    @Published var currentIndex: Int = 0
    
    //explode effect
    @Published var showExplosion: Bool = false
    
    // expression
    @Published var currentExpression: WitchExpression = .regular
    
    // Chat box
    @Published var witchMessage: String? = nil
    private var messageWorkItem: DispatchWorkItem?
    
    // anticipation screen
    @Published var showCountdown: Bool = false
    @Published var countdownText: String = ""
    
    // narasi
    @Published var showNarrative: Bool = false
    @Published var narrativeText: String = ""
    
    // floating time
    @Published var timeModifierText: String = ""
    @Published var timeModifierColor: Color = .green
    @Published var timeModifierTrigger: UUID = UUID()
    
    // tutorial
    @Published var showDragTutorial: Bool = false
    
    // aging
    @Published var isYoung: Bool = true
    var currentWitchImage: String {
        if isYoung {
            return "young_" + currentExpression.rawValue
        } else {
            return currentExpression.rawValue
        }
    }
    
    // blink detector
    let blinkManager = BlinkManager()
    
    private var timerCancellable: AnyCancellable?
    
    init() {
        blinkManager.onBlinkDetected = { [weak self] in
            self?.handleBlinkPenalty()
        }
    }
    
    func generateNewSequence() {
        currentSequence = (0..<8).map { _ in
            Ingredient.allCases.randomElement()!}
        
        currentIndex = 0
        potionTimeLeft = Int(maxPotionTime)
        isSpawning = true
        
        SoundManager.shared.playBGM(soundName: "spawning", loops: -1)
    }
    
    func startNewGame() {
        timeLeft = 100
        score = 0
        isGameOver = false
        isYoung = true
        
        currentExpression = .regular
        witchMessage = nil
        
        runCountdownPhase()
    }
    
    func gameOver() {
        timerCancellable?.cancel()
        SoundManager.shared.stopBGM()
        
        // Putar efek suara Mario Game Over
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            SoundManager.shared.playBGM(soundName: "SUPER MARIO - game over", loops: 0)
        }
        
        // 2. Animasi Pingsan (Detik ke-0)
        withAnimation(.easeInOut(duration: 0.5)) {
            self.isYoung = false // Pastikan dia dalam wujud tua karena waktunya habis
            self.currentExpression = .fainting
        }
        
        // 3. Jatuh ke Lantai (Detik ke-1.0)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation(.easeIn(duration: 0.3)) {
                self.currentExpression = .passedOut
            }
        }
        
        // 4. Layar Menggelap & Teks Pertama Muncul (Detik ke-2.5)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            withAnimation(.easeInOut(duration: 0.5)) {
                self.showNarrative = true
                self.narrativeText = "Life passes in the blink of an eye."
            }
        }
        
        // 5. Ganti ke Teks Kedua (Detik ke-5.0)
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
            withAnimation(.easeInOut(duration: 0.5)) {
                self.narrativeText = "Use it well."
            }
        }
        
        // 6. Akhirnya, Tampilkan Layar Game Over Asli (Detik ke-8.0)
        DispatchQueue.main.asyncAfter(deadline: .now() + 7.0) {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                self.showNarrative = false
                self.isGameOver = true
            }
        }
    }
    
    func startTimer() {
        // buat matiin timer yang lama
        timerCancellable?.cancel()
        
        // buat timer baru
        timerCancellable = Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self else { return }
                
                if self.timeLeft > 0 {
                    self.timeLeft -= 1
                    
                    if self.isYoung && self.timeLeft <= 50 {
                        withAnimation(.easeInOut(duration: 0.5)) {
                            self.isYoung = false
                            self.currentExpression = .nervous
                        }
                        
                        // Kembali ke ekspresi normal setelah 2 detik
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                            withAnimation { self.updateDefaultExpression() }
                        }
                    } else {
                        self.updateDefaultExpression()
                    }
                    
                    if self.timeLeft == 75 {
                        self.showWitchMessage("Keep going...")
                    } else if self.timeLeft == 50 || self.timeLeft == 20 {
                        self.showWitchMessage("Hurry up!")
                    } else if self.timeLeft == 30 {
                        self.showWitchMessage("Time is ticking...")
                    } else if self.timeLeft == 6 {
                        self.showWitchMessage("Last chance!")
                    }
                    
                } else {
                    self.gameOver()
                    return
                }
                
                if !isSpawning {
                    if self.potionTimeLeft > 0 {
                        self.potionTimeLeft -= 1
                    } else if !self.isGameOver {
                        let generator = UINotificationFeedbackGenerator()
                        generator.notificationOccurred(.error)
                        
                        withAnimation(.easeInOut(duration: 0.3)) {
                            self.generateNewSequence()
                        }
                    }
                }
            
                
            }
    }
    
    private func potionCompleted() {
        SoundManager.shared.playSFX(soundName: "Mario Coin Sound - Sound Effect")
        timeLeft += 15
        score += 1
        
        self.showTimeModifier(text: "+15d", color: .green)
        
        if !isYoung && timeLeft > 50 {
            withAnimation(.easeInOut(duration: 0.5)) {
                self.isYoung = true
                self.currentExpression = .celebrate
            }
        } else {
            withAnimation {
                self.currentExpression = .celebrate
            }
        }
        
        SoundManager.shared.stopBGM()
        
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        
        self.showWitchMessage("Nice one...")
        
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation {
                self.currentExpression = .regular
                self.updateDefaultExpression()
            }
        }
        
        generateNewSequence()
    }
    
    
    func handleDrop(ingredient: Ingredient) {
        guard !isGameOver && !isSpawning && timeLeft > 0 else { return }
        guard currentIndex < currentSequence.count else { return }
        
        if ingredient == currentSequence[currentIndex] {
            currentIndex += 1
            
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
            
            if currentIndex == 8 {
                self.isSpawning = true
                potionCompleted()
            }
        } else {
            self.isSpawning = true
            timeLeft -= 10
            self.showTimeModifier(text: "-10d", color: .red)
            
            if timeLeft <= 0 {
                timeLeft = 0
                gameOver()
                return
            }
            self.showWitchMessage("Yuck! That's wrong!")
                    
            currentIndex = 0
            potionTimeLeft = Int(maxPotionTime)
            
            if isYoung && timeLeft <= 50 {
                withAnimation(.easeInOut(duration: 0.5)) {
                    isYoung = false
                }
            }
            
            withAnimation {
                self.currentExpression = .explode
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                guard self.timeLeft > 0 else { return }
                withAnimation {
                    self.currentExpression = .regular 
                    self.updateDefaultExpression()
                }
            }
                    
            withAnimation(.easeOut(duration: 0.1)) {
                showExplosion = true
            }
                
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                withAnimation(.easeIn(duration: 0.3)) {
                    self.showExplosion = false
                }
            }
        
            SoundManager.shared.stopBGM()
            SoundManager.shared.playSFX(soundName: "tnt-explosion")
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.error)
        
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation(.easeInOut(duration: 0.3)) {
                    self.generateNewSequence()
                }
            }
        }
    }
    
    func updateDefaultExpression() {
        guard timeLeft > 0 else { return }
        guard currentExpression != .angry && currentExpression != .celebrate && currentExpression != .explode else { return }
        
        if timeLeft < 30 {
            currentExpression = .nervous
        } else {
            currentExpression = .regular
        }
    }
    
    func handleBlinkPenalty() {
        guard !showCountdown && timeLeft > 0 && !isGameOver else { return }
        
        timeLeft -= 30
        self.showTimeModifier(text: "-30d", color: .red)
        
        if timeLeft <= 0 {
            timeLeft = 0
            gameOver()
            return
        }
        
        self.showWitchMessage("Stop blinking!")
        
        SoundManager.shared.playSFX(soundName: "Rubber Duck") // ganti sfx petir
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.error)
        
        withAnimation(.easeOut(duration: 0.1)) {
            self.currentExpression = .angry
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            guard self.timeLeft > 0 else { return }
            withAnimation {
                self.currentExpression = .regular
                self.updateDefaultExpression()
            }
        }
    }
    
    // CHAT BOX
    func showWitchMessage(_ text: String) {
        messageWorkItem?.cancel()
        
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            self.witchMessage = text
        }
 
        let workItem = DispatchWorkItem { [weak self] in
            withAnimation(.easeInOut(duration: 0.3)) {
                self?.witchMessage = nil
            }
        }

        messageWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0, execute: workItem)
    }
    
    func runCountdownPhase() {
        showCountdown = true
        countdownText = "Don't Blink!"
        
        SoundManager.shared.playBGM(soundName: "test-intro")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.5)) {
                self.countdownText = "BREW!"
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                withAnimation(.easeInOut(duration: 0.3)) {
                    self.showCountdown = false
                }
                self.generateNewSequence()
                self.startTimer()
                
            }
        }
        
    }
    
    func showTimeModifier(text: String, color: Color) {
        self.timeModifierText = text
        self.timeModifierColor = color
        self.timeModifierTrigger = UUID()
    }
}
