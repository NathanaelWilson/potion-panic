import Foundation
import AVFoundation

class SoundManager {
    static let shared = SoundManager()
    
    private var bgmPlayer: AVAudioPlayer?
    private var sfxPlayer: AVAudioPlayer?
    
    // Fungsi untuk memutar musik latar (Looping terus menerus)
    func playBGM(soundName: String, type: String = "mp3", loops: Int = -1) {
        guard let url = Bundle.main.url(forResource: soundName, withExtension: type) else {
            print("Error: File BGM \(soundName).\(type) tidak ditemukan!")
            return
        }
            
        do {
            bgmPlayer = try AVAudioPlayer(contentsOf: url)
                // Di sini kita masukkan parameter loops-nya
            bgmPlayer?.numberOfLoops = loops
            bgmPlayer?.volume = 0.5
            bgmPlayer?.play()
        } catch {
            print("Error: Gagal memutar BGM. \(error.localizedDescription)")
        }
    }
    
    // Fungsi untuk mematikan BGM (Misal saat Game Over)
    func stopBGM() {
        bgmPlayer?.stop()
    }
    
    // Fungsi untuk memutar efek suara (Bunyi sekali saja)
    func playSFX(soundName: String, type: String = "mp3") {
        guard let url = Bundle.main.url(forResource: soundName, withExtension: type) else {
            print("Error: File SFX \(soundName).\(type) tidak ditemukan!")
            return
        }
        
        do {
            sfxPlayer = try AVAudioPlayer(contentsOf: url)
            sfxPlayer?.volume = 0.2 // Volume SFX full
            sfxPlayer?.play()
        } catch {
            print("Error: Gagal memutar SFX. \(error.localizedDescription)")
        }
    }
}
