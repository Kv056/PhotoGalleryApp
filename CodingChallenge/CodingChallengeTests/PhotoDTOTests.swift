//
//  CodingChallengeApp.swift
//  CodingChallenge
//

import XCTest
@testable import CodingChallenge

final class PhotoDTOTests: XCTestCase {
    func test_decodesPhotoFromValidJSON() throws {
        let json = PhotoTestFactory.sampleJSON(id: 42).data(using: .utf8)!
        let photo = try JSONDecoder().decode(PhotoDTO.self, from: json)

        XCTAssertEqual(photo.id, 42)
        XCTAssertEqual(photo.albumId, 1)
        XCTAssertEqual(photo.title, "Sample title")
        XCTAssertEqual(photo.url, "https://example.com/full.jpg")
        XCTAssertEqual(photo.thumbnailUrl, "https://example.com/thumb.jpg")
    }
}
