# Photo Gallery App

An iOS photo gallery application built for the iOS Engineer technical assessment. The app fetches photos from the JSONPlaceholder API, persists them with Core Data, and supports paginated browsing, title editing, and record deletion.

## Requirements

- Xcode 15 or later
- iOS 15.0+ (Simulator or device)
- Swift 5+

## Setup

1. Clone the repository:
   ```bash
   git clone https://github.com/Kv056/PhotoGalleryApp.git
   cd CodingChallenge
   ```

2. Open `CodingChallenge.xcodeproj` in Xcode.

3. Wait for Swift Package Manager to resolve dependencies (`SDWebImageSwiftUI`).

4. Select an iOS 15+ simulator or device and run (`Cmd + R`).

No CocoaPods or manual dependency installation is required.

## Dependencies

| Package | Purpose |
|---------|---------|
| [SDWebImageSwiftUI](https://github.com/SDWebImage/SDWebImageSwiftUI) (SPM) | Async image loading and caching for thumbnails and full-size photos |

## Architecture

The app follows **MVVM** with clear separation of concerns:

```
Views (SwiftUI):PhotoListView, PhotoDetailView, PhotoRowView, EmptyStateView, PhotoPlaceholderImage
ViewModels:PhotoListViewModel, PhotoDetailViewModel
Services:PhotoAPIService (URLSession) , PhotoRepository (Core Data CRUD, sync, pagination)
Persistence:Core Data (Photo entity)
```

### Data flow

1. **Launch:** `PhotoListViewModel` calls `PhotoRepository.loadPhotosIfNeeded()`.
2. **Local first:** If Core Data is empty, fetch from the API once, then save in **batches of 50**. After the first batch is saved, the first UI page is shown while remaining batches continue saving.
3. **Display:** The list loads **30 photos per page** from Core Data. More pages load only when the user scrolls to the bottom (sentinel row), not automatically.
4. **Edit / Delete:** Changes are written to Core Data and reflected immediately in the list.

## Features

| Feature | Implementation |
|---------|----------------|
| API fetch | `URLSession` via `PhotoAPIService` |
| Image caching | SDWebImage (`WebImage`) |
| Placeholder | SF Symbol `photo` when images fail to load |
| Persistence | Core Data `Photo` entity with unique `id` constraint |
| Duplicate prevention | Upsert by `id` on save |
| List pagination | 30 items per page from Core Data |
| Initial sync | API response saved in batches of 50; first page shown early |
| Edit title | Detail screen with Save → Core Data update → list refresh |
| Delete | Swipe-to-delete or detail delete with confirmation alert |
| Error handling | Network / Core Data errors with retry; empty state when no data |
| Loading states | Full-screen loader on first sync; bottom spinner when loading more |

## Known Issues / API Behavior Notes
- The same URL, when opened in a web browser, does not display images as expected.
- This behavior was also observed during iOS integration.

## API

- **Endpoint:** `GET https://jsonplaceholder.typicode.com/photos`
- **Response:** Array of 5000 photo objects

```json
{
  "albumId": 1,
  "id": 1,
  "title": "accusamus beatae ad facilis cum similique qui sunt",
  "url": "https://via.placeholder.com/600/92c952",
  "thumbnailUrl": "https://via.placeholder.com/150/92c952"
}
```

## Core Data Model

| Attribute | Type | Notes |
|-----------|------|-------|
| `id` | Int64 | Unique constraint |
| `albumId` | Int64 | |
| `title` | String | Editable |
| `url` | String | Full-size image |
| `thumbnailUrl` | String | List thumbnail |

## Assumptions

- The API returns all 5000 records in a single JSON response; network fetch is one request.
- UI pagination (30 items) and Core Data saves (50 items per batch) are handled client-side for performance.
- **SwiftUI** is used for the UI; **SDWebImageSwiftUI** handles image caching.
- A default placeholder image (SF Symbol) is shown when image URLs fail to load.
- On re-fetch, photos are upserted by `id` so no duplicate records are created.
- Subsequent app launches load from Core Data immediately and skip the API call if data exists.

