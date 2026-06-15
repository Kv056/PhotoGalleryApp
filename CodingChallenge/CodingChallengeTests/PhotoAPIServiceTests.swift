//
//  CodingChallengeApp.swift
//  CodingChallenge
//

import XCTest
@testable import CodingChallenge

final class PhotoAPIServiceTests: XCTestCase {
    private let endpoint = APIConstants.makeURL(path: APIConstants.photosEndpointPath)!

    override func tearDown() {
        URLProtocolStub.requestHandler = nil
        super.tearDown()
    }

    func test_fetchPhotos_success_returnsDecodedPhotos() async throws {
        let json = PhotoTestFactory.sampleJSONArray(ids: [1, 2])
        stubResponse(statusCode: 200, body: json)

        let service = PhotoAPIService(client: APIClient(session: .stubbed()))
        let photos = try await service.fetchPhotos()

        XCTAssertEqual(photos.count, 2)
        XCTAssertEqual(photos[0].id, 1)
        XCTAssertEqual(photos[1].id, 2)
    }

    func test_fetchPhotos_httpError_throwsRequestFailed() async {
        stubResponse(statusCode: 500, body: "")

        let service = PhotoAPIService(client: APIClient(session: .stubbed()))

        do {
            _ = try await service.fetchPhotos()
            XCTFail("Expected requestFailed error")
        } catch let error as NetworkError {
            XCTAssertEqual(error, NetworkError.requestFailed(statusCode: 500))
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func test_fetchPhotos_invalidJSON_throwsDecodingFailed() async {
        stubResponse(statusCode: 200, body: "{ invalid json }")

        let service = PhotoAPIService(client: APIClient(session: .stubbed()))

        do {
            _ = try await service.fetchPhotos()
            XCTFail("Expected decodingFailed error")
        } catch let error as NetworkError {
            XCTAssertEqual(error, NetworkError.decodingFailed)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func test_fetchPhotos_nonHTTPResponse_throwsNoData() async {
        URLProtocolStub.requestHandler = { request in
            let response = URLResponse(
                url: request.url!,
                mimeType: nil,
                expectedContentLength: 0,
                textEncodingName: nil
            )
            return (response, Data())
        }

        let service = PhotoAPIService(client: APIClient(session: .stubbed()))

        do {
            _ = try await service.fetchPhotos()
            XCTFail("Expected noData error")
        } catch let error as NetworkError {
            if case .noData = error {
                XCTAssertTrue(true)
            } else {
                XCTFail("Expected noData, got \(error)")
            }
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func test_fetchPhotos_emptyArray_decodesSuccessfully() async throws {
        stubResponse(statusCode: 200, body: "[]")

        let service = PhotoAPIService(client: APIClient(session: .stubbed()))
        let photos = try await service.fetchPhotos()

        XCTAssertTrue(photos.isEmpty)
    }

    private func stubResponse(statusCode: Int, body: String) {
        let data = Data(body.utf8)
        URLProtocolStub.requestHandler = { _ in
            let response = HTTPURLResponse(
                url: self.endpoint,
                statusCode: statusCode,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, data)
        }
    }
}

extension NetworkError: Equatable {
    public static func == (lhs: NetworkError, rhs: NetworkError) -> Bool {
        switch (lhs, rhs) {
        case (.invalidURL, .invalidURL),
             (.decodingFailed, .decodingFailed),
             (.noData, .noData):
            return true
        case (.requestFailed(let lhsCode), .requestFailed(let rhsCode)):
            return lhsCode == rhsCode
        default:
            return false
        }
    }
}
