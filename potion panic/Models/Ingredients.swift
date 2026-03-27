import SwiftUI
import Foundation

enum Ingredient: Int, CaseIterable, Identifiable {
    case mushroom = 1
    case flower = 2
    case pufferFish = 3
    case chickenFoot = 4
    case goldenCarrot = 5
    case spiderEye = 6
    
    var id: Int {
        return self.rawValue
    }
    
    var dummyColor: Color {
        switch self {
        case .mushroom:
            return .red
        case .flower:
            return .green
        case .pufferFish:
            return .yellow
        case .chickenFoot:
            return .blue
        case .goldenCarrot:
            return .pink
        case .spiderEye:
            return .purple
        }
    }
    
    var imageName: String {
        switch self {
        case .mushroom:
            return "mushroom"
        case .flower:
            return "flower"
        case .pufferFish:
            return "pufferfish"
        case .chickenFoot:
            return "chicken_foot"
        case .goldenCarrot:
            return "golden_carrot"
        case .spiderEye:
            return "spider_eye"
        }
    }
    
}
