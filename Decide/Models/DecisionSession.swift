import Foundation

struct DecisionSession: Identifiable {
    let id = UUID()
    let question: String
    let options: [String]
}
