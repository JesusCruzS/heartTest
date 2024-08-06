//
//  DataSource.swift
//  stepsApp
//
//  Created by Jesus Cruz Suárez on 5/08/24.
//

import Foundation
import FirebaseFirestore

struct StepsModel: Codable, Identifiable {
    @DocumentID var id: String?
    let count: String
    var createdAt: Date
}

final class StepsDataSource {
    private let database = Firestore.firestore()
    private let collection = "steps"
    
    func registerSteps(steps: StepsModel, completion: @escaping (Result<StepsModel, Error>) -> Void) {
        do {
            _ = try database.collection(collection).addDocument(from: steps)
            completion(.success(steps))
        } catch {
            completion(.failure(error))
        }
    }
}
