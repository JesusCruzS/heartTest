import Foundation
import HealthKit

/// Hasta el momento lo que pude comprobar con los pasos es que cuando se detecta que esta caminando al dispositivo la informacion llega aprox entre 3 a 5 segundos

final public class ViewModel: ObservableObject {
    /// Vars
    @Published public var allMySteps: String = "0"
    @Published public var latestHeartRate: String = "0"
    
    ///HealthKit
    private let healthStore = HKHealthStore()
    private var observerQuery: HKObserverQuery?
    private var query: HKStatisticsQuery?
    private var heartRateQuery: HKObserverQuery?
    
    /// Repositories
    private let stepsRepository: StepsRepository
    private let heartRateRepository: HeartRateRepository
    
    init(stepsRepository: StepsRepository, heartRateRepository: HeartRateRepository) {
        self.stepsRepository = stepsRepository
        self.heartRateRepository = heartRateRepository
    }
    
    public func requestAccessToHealthData() {
        let readableTypes: Set<HKSampleType> = [
            HKQuantityType.quantityType(forIdentifier: .stepCount)!,
            HKQuantityType.quantityType(forIdentifier: .heartRate)!
        ]
        
        guard HKHealthStore.isHealthDataAvailable() else {
            return
        }
        
        healthStore.requestAuthorization(toShare: nil, read: readableTypes) { success, error in
            if success {
                print("Request Authorization \(success.description)")
                //self.getTodaySteps()
                self.subscribeToHeartBeatChanges()
            }
        }
    }
    
    func getTodaySteps() {
        guard let stepCountType = HKObjectType.quantityType(forIdentifier: .stepCount) else {
            print("Error: Identifier .stepAccount")
            return
        }
        
        observerQuery = HKObserverQuery(sampleType: stepCountType,
                                        predicate: nil,
                                        updateHandler: { query, completionHandler, error in
            if let error = error {
                print("Error: \(error.localizedDescription)")
                return
            }
            
            self.getMySteps()
            completionHandler()
        })
        
        observerQuery.map(healthStore.execute)
    }
    
    private func getMySteps() {
        let stepsQuantityType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
        
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)
        
        self.query = HKStatisticsQuery(quantityType: stepsQuantityType,
                                       quantitySamplePredicate: predicate,
                                       options: .cumulativeSum,
                                       completionHandler: {_, result, _ in
            guard let result = result, let sum = result.sumQuantity() else {
                DispatchQueue.main.async {
                    self.allMySteps = String(Int(0))
                }
                return
            }
            
            let stepsCount = Int(sum.doubleValue(for: HKUnit.count()))
            DispatchQueue.main.async {
                self.allMySteps = String(stepsCount)
                self.registerStepsInDatabase(stepsCount: stepsCount)
            }
        })
        
        query.map(healthStore.execute)
    }
    
    private func registerStepsInDatabase(stepsCount: Int) {
        let stepsModel = StepsModel(count: String(stepsCount), createdAt: Date())
        stepsRepository.registerSteps(steps: stepsModel) { result in
            switch result {
            case .success(let steps):
                print("Steps registered: \(steps.count) at \(steps.createdAt)")
            case .failure(let error):
                print("Failed to register steps: \(error.localizedDescription)")
            }
        }
    }
    
    //MARK: Heart rate

    public func subscribeToHeartBeatChanges() {
        // Creating the sample for the heart rate
        guard let sampleType: HKSampleType =
                HKObjectType.quantityType(forIdentifier: .heartRate) else {
            return
        }
        
        /// Creating an observer, so updates are received whenever HealthKit’s
        // heart rate data changes.
        self.heartRateQuery = HKObserverQuery.init(
            sampleType: sampleType,
            predicate: nil) { [weak self] _, completionHandler, error in
                guard error == nil else {
                    print("ERROR")
                    return
                }
                
                /// When the completion is called, an other query is executed
                /// to fetch the latest heart rate
                self?.fetchLatestHeartRateSample(completion: { sample in
                    guard let sample = sample else {
                        return
                    }
                    
                    /// The completion in called on a background thread, but we
                    /// need to update the UI on the main.
                    DispatchQueue.main.async {
                        
                        /// Converting the heart rate to bpm
                        let heartRateUnit = HKUnit(from: "count/min")
                        let heartRate = sample
                            .quantity
                            .doubleValue(for: heartRateUnit)
                        
                        /// Updating the UI with the retrieved value
                        print("Heart rate: \(heartRate)")
                        self?.latestHeartRate = "\(Int(heartRate))"
                        //self?.registerHeartRateInDatabase(heartRate: Int(heartRate))
                    }
                })
                
                completionHandler()
            }
        // Execute the observer query to start observing heart rate changes
        if let heartRateQuery = heartRateQuery {
            print("OBSERVER")
            healthStore.execute(heartRateQuery)
        }
    }
    
    public func fetchLatestHeartRateSample(
        completion: @escaping (_ sample: HKQuantitySample?) -> Void) {
            
            /// Create sample type for the heart rate
            guard let sampleType = HKObjectType
                .quantityType(forIdentifier: .heartRate) else {
                completion(nil)
                return
            }
            
            /// Predicate for specifiying start and end dates for the query
            let predicate = HKQuery
                .predicateForSamples(
                    withStart: Date.distantPast,
                    end: Date(),
                    options: .strictEndDate)
            
            /// Set sorting by date.
            let sortDescriptor = NSSortDescriptor(
                key: HKSampleSortIdentifierStartDate,
                ascending: false)
            
            /// Create the query
            let query = HKSampleQuery(
                sampleType: sampleType,
                predicate: predicate,
                limit: Int(HKObjectQueryNoLimit),
                sortDescriptors: [sortDescriptor]) { (_, results, error) in
                    
                    guard error == nil else {
                        print("Error: \(error!.localizedDescription)")
                        return
                    }
                    
                    print("results \(results)")
                    
                    completion(results?.first as? HKQuantitySample)
                }
            
            self.healthStore.execute(query)
        }
    
    private func registerHeartRateInDatabase(heartRate: Int) {
        let heartRateModel = HeartRateModel(bpm: String(heartRate), createdAt: Date())
        heartRateRepository.registerHeartRate(heartRate: heartRateModel) { result in
            switch result {
            case .success(let heartRate):
                print("Heart rate registered: \(heartRate.bpm) at \(heartRate.createdAt)")
            case .failure(let error):
                print("Failed to register heart rate: \(error.localizedDescription)")
            }
        }
    }
}
