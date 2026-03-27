import Foundation
import ARKit

class BlinkManager: NSObject, ARSessionDelegate {
    private var session = ARSession()
    
    // Closure (Fungsi jembatan) untuk memberitahu ViewModel saat pemain berkedip
    var onBlinkDetected: (() -> Void)?
    
    // Variabel "Debounce" agar 1 kedipan tidak terbaca 10 kali
    private var isCurrentlyBlinking = false
    
    func start() {
        // Cek apakah HP mendukung Face Tracking (Butuh iPhone X ke atas dengan FaceID)
        guard ARFaceTrackingConfiguration.isSupported else {
            print("Face tracking tidak didukung di perangkat/simulator ini.")
            return
        }
        
        let config = ARFaceTrackingConfiguration()
        session.delegate = self
        session.run(config, options: [.resetTracking, .removeExistingAnchors])
    }
    
    func stop() {
        session.pause()
    }
    
    // Fungsi ini dipanggil puluhan kali per detik oleh kamera Apple
    func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
        // Cari wajah pemain
        guard let faceAnchor = anchors.compactMap({ $0 as? ARFaceAnchor }).first else { return }
        
        // Ambil nilai kedipan mata kiri dan kanan (0.0 = terbuka, 1.0 = tertutup)
        let leftBlink = faceAnchor.blendShapes[.eyeBlinkLeft]?.floatValue ?? 0.0
        let rightBlink = faceAnchor.blendShapes[.eyeBlinkRight]?.floatValue ?? 0.0
        
        // Threshold (Ambang batas): 0.8 berarti mata tertutup 80%
        let blinkThreshold: Float = 0.8
        
        if leftBlink > blinkThreshold && rightBlink > blinkThreshold {
            // Jika mata tertutup DAN belum terhitung berkedip
            if !isCurrentlyBlinking {
                isCurrentlyBlinking = true
                
                // Panggil hukuman di Main Thread (Karena ARKit berjalan di Background Thread)
                DispatchQueue.main.async {
                    self.onBlinkDetected?()
                }
            }
        } else if leftBlink < 0.3 && rightBlink < 0.3 {
            // Jika mata sudah terbuka lebar kembali, reset statusnya
            // Siap untuk mendeteksi kedipan berikutnya!
            isCurrentlyBlinking = false
        }
    }
}
