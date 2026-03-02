# Media Type Schema

## Domain Model Template (IdentifiableTypes.swift)
```swift
struct [TypeName]: Identifiable, Hashable {
    var id: String
    var name: String
    // ... media specific fields
    var rating: Int?
    var comment: String?
    var isCompleted: Bool? = false
}
```

## DTO Template (DTOs.swift)
```swift
struct [TypeName]DTO: Codable {
    let id: String
    let name: String
    // ... api specific fields
}
```

## Mapping Logic
- From Spotify JSON to DTO
- From DTO to Domain Model (handling DocumentReferences)
- From Domain Model to Firestore Dictionary (setData)
