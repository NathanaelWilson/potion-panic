import Foundation
import SwiftUI
import Combine

enum WitchExpression: String {
    case regular = "regular_witch"
    case angry = "angry_witch"
    case celebrate = "celebrating_witch"
    case nervous = "nervous_witch"
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
    @Published var isSpawning: Bool = true
    
    @Published var currentSequence: [Ingredient] = []
    @Published var currentIndex: Int = 0
    
    @Published var showExplosion: Bool = false
    @Published var currentExpression: WitchExpression = .regular
    
    // Chat box
    @Published var witchMessage: String? = nil
    private var messageWorkItem: DispatchWorkItem?
    
    // blink detector
    let blinkManager = BlinkManager()
    
    private var timerCancellable: AnyCancellable?
    
    init() {
        startNewGame()
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
        
        generateNewSequence()
        startTimer()
    }
    
    func gameOver() {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                isGameOver = true
            }
            timerCancellable?.cancel()
        
        SoundManager.shared.stopBGM()
        // SoundManager.shared.playSFX(soundName: "sfx_gameover")
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
                    self.updateDefaultExpression()
                    
                    if self.timeLeft == 75 {
                        self.showWitchMessage("Keep going...")
                    } else if self.timeLeft == 50 || self.timeLeft == 20 {
                        self.showWitchMessage("Hurry up!")
                    } else if self.timeLeft == 30 {
                        self.showWitchMessage("Time is ticking...")
                    } else if self.timeLeft == 10 {
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
        timeLeft += 15
        score += 1
        
        SoundManager.shared.stopBGM()
        
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        
        self.showWitchMessage("Nice one...")
        
        withAnimation {
            self.currentExpression = .celebrate
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation {
                self.currentExpression = .regular
                self.updateDefaultExpression()
            }
        }
        
        generateNewSequence()
    }
    
    
    func handleDrop(ingredient: Ingredient) {
        guard !isGameOver && !isSpawning else { return }
        
        if ingredient == currentSequence[currentIndex] {
            currentIndex += 1
            
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
            
            if currentIndex == 8 {
                potionCompleted()
            }
        } else {
            timeLeft -= 10
            if timeLeft <= 0 {
                timeLeft = 0
                gameOver()
                return
            }
            self.showWitchMessage("Well well well...")
                    
            currentIndex = 0
            potionTimeLeft = Int(maxPotionTime)
            
            withAnimation {
                self.currentExpression = .angry
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation {
                    self.currentExpression = .regular 
                    self.updateDefaultExpression()
                }
            }
                    
//                withAnimation(.easeOut(duration: 0.1)) {
//                    showExplosion = true
//                }
                    
//                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
//                    withAnimation(.easeIn(duration: 0.3)) {
//                        self.showExplosion = false
//                    }
//                }
        
            SoundManager.shared.stopBGM()
            SoundManager.shared.playSFX(soundName: "sfx_wrong") // Ganti dengan suara ledakan jika ada
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
        guard currentExpression != .angry && currentExpression != .celebrate else { return }
        
        if timeLeft < 30 {
            currentExpression = .nervous
        } else {
            currentExpression = .regular
        }
    }
    
    func handleBlinkPenalty() {
        guard !isGameOver else { return }
        
        timeLeft -= 30
        
        if timeLeft <= 0 {
            timeLeft = 0
            gameOver()
            return
        }
        
        self.showWitchMessage("Stop blinking!")
        
        SoundManager.shared.playSFX(soundName: "sfx_wrong") // Ganti dengan efek suara horor/time-skip kalau ada!
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.error)
        
        withAnimation(.easeOut(duration: 0.1)) {
            self.showExplosion = true
            self.currentExpression = .angry
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            withAnimation(.easeIn(duration: 0.3)) {
                self.showExplosion = false
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation {
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
}
