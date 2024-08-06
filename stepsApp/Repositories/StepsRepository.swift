//
//  repository.swift
//  stepsApp
//
//  Created by Jesus Cruz Suárez on 5/08/24.
//

import Foundation

final class StepsRepository {
    private let stepsDataSource: StepsDataSource
    
    init(stepsDataSource: StepsDataSource) {
        self.stepsDataSource = stepsDataSource
    }
    
    func registerSteps(steps: StepsModel, completion: @escaping (Result<StepsModel, Error>) -> Void) {
        stepsDataSource.registerSteps(steps: steps, completion: completion)
    }
}
