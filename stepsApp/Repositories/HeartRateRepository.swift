//
//  HeartRateRepository.swift
//  stepsApp
//
//  Created by Jesus Cruz Suárez on 5/08/24.
//

import Foundation

final class HeartRateRepository {
    private let heartRateDataSource: HeartRateDataSource
    
    init(heartRateDataSource: HeartRateDataSource) {
        self.heartRateDataSource = heartRateDataSource
    }
    
    func registerHeartRate(heartRate: HeartRateModel, completion: @escaping (Result<HeartRateModel, Error>) -> Void) {
        heartRateDataSource.registerHeartRate(heartRate: heartRate, completion: completion)
    }
}
