//
//  HeartRateDataSource.swift
//  stepsApp
//
//  Created by Jesus Cruz Suárez on 5/08/24.
//

import Foundation
import FirebaseFirestore

struct HeartRateModel: Codable, Identifiable {
    @DocumentID var id: String?
    let bpm: String
    let createdAt: Date
}

final class HeartRateDataSource {
    private let database = Firestore.firestore()
    private let collection = "heartRates"
    
    func registerHeartRate(heartRate: HeartRateModel, completion: @escaping (Result<HeartRateModel, Error>) -> Void) {
        do {
            _ = try database.collection(collection).addDocument(from: heartRate)
            completion(.success(heartRate))
        } catch {
            completion(.failure(error))
        }
    }
}

