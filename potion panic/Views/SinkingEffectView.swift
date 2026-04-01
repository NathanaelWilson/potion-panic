import SwiftUI

// Struct ini menampung data sementara untuk efek tenggelam
struct SinkingEffectItem: Identifiable {
    let id = UUID() // Unik agar ForEach bisa melacaknya
    let ingredient: Ingredient // Bahan apa yang tercebur
    let position: CGPoint // Di mana item tersebut tercebur (area kuali)
}

struct SinkingEffectView: View {
    let item: SinkingEffectItem
    @State private var isSinking: Bool = false
        
    var body: some View {

        Image(item.ingredient.imageName) // Sesuaikan dengan cara kamu memanggil gambar
            .resizable()
            .frame(width: 70, height: 70) // Sesuaikan ukuran aslinya
            
            // --- LOGIKA VISUAL TENGGELAM INI SANGAT JUICY ---
            .scaleEffect(isSinking ? 0.2 : 1.0) // Mengecil seolah tenggelam jauh
            .offset(y: isSinking ? 20 : 0)      // Turun masuk ke dalam cairan
            .opacity(isSinking ? 0.0 : 1.0)     // Perlahan menghilang
            // --------------------------------------------------
            
            .position(item.position) // Ditempatkan di lokasi drop
            
            .onAppear {
                // Begitu View ini muncul, langsung jalankan animasinya
                withAnimation(.easeIn(duration: 0.3)) {
                    isSinking = true
                }
            }
    }
}
