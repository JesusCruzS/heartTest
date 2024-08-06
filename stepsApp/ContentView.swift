import SwiftUI

struct ContentView: View {
    let stepsRepository = StepsRepository(stepsDataSource: StepsDataSource())
    let heartRateRepository = HeartRateRepository(heartRateDataSource: HeartRateDataSource())
    
    var body: some View {
        StepsView(stepsRepository: stepsRepository, heartRateRepository: heartRateRepository)
    }
}
