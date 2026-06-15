import CoreData
@testable import CodingChallenge

enum PhotoTestFactory {
    static func makeDTO(
        id: Int,
        albumId: Int = 1,
        title: String = "Test photo",
        url: String = "https://example.com/full.jpg",
        thumbnailUrl: String = "https://example.com/thumb.jpg"
    ) -> PhotoDTO {
        PhotoDTO(
            albumId: albumId,
            id: id,
            title: title,
            url: url,
            thumbnailUrl: thumbnailUrl
        )
    }

    static func makePhoto(
        in context: NSManagedObjectContext,
        id: Int64,
        albumId: Int64 = 1,
        title: String = "Test photo",
        url: String = "https://example.com/full.jpg",
        thumbnailUrl: String = "https://example.com/thumb.jpg"
    ) -> Photo {
        let photo = Photo(context: context)
        photo.id = id
        photo.albumId = albumId
        photo.title = title
        photo.url = url
        photo.thumbnailUrl = thumbnailUrl
        return photo
    }

    static func seedPhotos(in context: NSManagedObjectContext, count: Int) -> [Photo] {
        (1...count).map { index in
            makePhoto(in: context, id: Int64(index), title: "Photo \(index)")
        }
    }

    static func sampleJSON(id: Int = 1) -> String {
        """
        {
            "albumId": 1,
            "id": \(id),
            "title": "Sample title",
            "url": "https://example.com/full.jpg",
            "thumbnailUrl": "https://example.com/thumb.jpg"
        }
        """
    }

    static func sampleJSONArray(ids: [Int]) -> String {
        let objects = ids.map { sampleJSON(id: $0) }.joined(separator: ",")
        return "[\(objects)]"
    }
}
