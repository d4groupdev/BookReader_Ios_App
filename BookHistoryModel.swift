
import Foundation

class BookHistoryModel : Codable {
    var id : Int!
    var bookId : Int!
    var pageRead : Int!
    var timeAudio : Double!
    var status : String!
    var readPercent : Float!
    var audioPercent : Float!
    var isAudio : Bool!
    
    enum BookHistoryModelCodingKeys : String, CodingKey {
        case id
        case bookId = "book_id"
        case pageRead = "page_read"
        case timeAudio = "time_audio"
        case status
        case readPercent = "read_percent"
        case audioPercent = "audio_percent"
        case isAudio = "is_audio"
    }
    
    required init(from decoder:Decoder) throws {
        let container = try decoder.container(keyedBy: BookHistoryModelCodingKeys.self)
        
        id = try? container.decode(Int.self, forKey: .id)
        bookId = try? container.decode(Int.self, forKey: .bookId)
        pageRead = try? container.decode(Int.self, forKey: .pageRead)
        timeAudio = try? container.decode(Double.self, forKey: .timeAudio)
        status = try? container.decode(String.self, forKey: .status)
        readPercent = try? container.decode(Float.self, forKey: .readPercent)
        audioPercent = try? container.decode(Float.self, forKey: .audioPercent)
        isAudio = try? container.decode(Bool.self, forKey: .isAudio)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: BookHistoryModelCodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encode(bookId, forKey: .bookId)
        try container.encode(pageRead, forKey: .pageRead)
        try container.encode(timeAudio, forKey: .timeAudio)
        try container.encode(status, forKey: .status)
        try container.encode(readPercent, forKey: .readPercent)
        try container.encode(audioPercent, forKey: .audioPercent)
        try container.encode(isAudio, forKey: .isAudio)
    }
}

extension BookHistoryModel: Equatable {
    static func == (lhs: BookHistoryModel, rhs: BookHistoryModel) -> Bool {
        return lhs.id == rhs.id
    }
}

extension BookHistoryModel: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
