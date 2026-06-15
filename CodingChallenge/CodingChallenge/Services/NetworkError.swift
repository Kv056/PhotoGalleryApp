//
//  PhotoDTO.swift
//  CodingChallenge
//
//  Created by Kirtan on 6/14/26.
//

import Foundation

enum NetworkError: LocalizedError {
    case invalidURL
    case requestFailed(statusCode: Int)
    case decodingFailed
    case noData
    case noInternet

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "The request URL is invalid."
        case .requestFailed(let statusCode):
            return "The server returned an error (status \(statusCode))."
        case .decodingFailed:
            return "Unable to read the server response."
        case .noData:
            return "No data was received from the server."
        case .noInternet:
            return "No internet connection is available."
        }
    }
}

enum RepositoryError: LocalizedError {
    case saveFailed
    case fetchFailed
    case deleteFailed
    case notFound

    var errorDescription: String? {
        switch self {
        case .saveFailed:
            return "Unable to save photos locally."
        case .fetchFailed:
            return "Unable to load photos from local storage."
        case .deleteFailed:
            return "Unable to delete the photo."
        case .notFound:
            return "The photo could not be found."
        }
    }
}
