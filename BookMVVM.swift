
import UIKit

class BookMVVM {

    public let bookModel:BookModel
    
    init(bookModel: BookModel) {
        self.bookModel = bookModel
    }

    private var likeRequest:LikeBookRequest?
    func setLike(isLike:Bool, completion: @escaping ((_ book:BookModel?, _ message:String?)->Void)) {
        let likeRequest = LikeBookRequest()
        self.likeRequest = likeRequest
        likeRequest.run(id: String(self.bookModel.id), isLike: isLike){[weak self] (book:BookModel?, _ message:String?) in
            guard let self = self else {return}
            
            self.likeRequest = nil
            completion(book, message)
        }
    }
    
    private var favoriteRequest:FavoriteBookRequest?
    func setFavorite(isFavorite:Bool, completion: @escaping ((_ isSuccess:Bool, _ message:String?)->Void)) {
        let favoriteRequest = FavoriteBookRequest()
        self.favoriteRequest = favoriteRequest
        favoriteRequest.run(id: String(self.bookModel.id), isFavorite: isFavorite){[weak self] (isSuccess:Bool, _ message:String?) in
            guard let self = self else {return}
            
            self.favoriteRequest = nil
            completion(isSuccess, message)
        }
    }
    
    func isFavoriteProcessing() -> Bool{
        return nil != self.favoriteRequest
    }
    
    private var bookmarkRequest:BookmarkRequest?
    func setBookmark(time_audio:Double? = nil, page_read:Int? = nil, completion: @escaping ((_ bookmark:BookmarkModel?, _ message:String?)->Void)) {
        let bookmarkRequest = BookmarkRequest()
        self.bookmarkRequest = bookmarkRequest
        bookmarkRequest.run(id: String(self.bookModel.id), time_audio: time_audio, page_read: page_read){[weak self] (bookmark:BookmarkModel?, _ message:String?) in
            guard let self = self else {return}
            
            self.bookmarkRequest = nil
            completion(bookmark, message)
        }
    }

    
    private var saveHistoryRequest:SaveHistoryBookRequest?
    func saveHistory(time_audio:Double? = nil, page_read:Int? = nil, read_percent:Float? = nil, audioPercent:Double? = nil, status:Bool? = nil, isAudio:Bool? = nil, completion: @escaping ((_ isSuccess:Bool, _ message:String?)->Void)) {
        if let page_read = page_read {self.bookModel.history?.pageRead = page_read}
        if let read_percent = read_percent {self.bookModel.history?.readPercent = read_percent}
        let saveHistoryRequest = SaveHistoryBookRequest()
        self.saveHistoryRequest = saveHistoryRequest
        saveHistoryRequest.run(id: String(self.bookModel.id), time_audio: time_audio, page_read: page_read, read_percent:read_percent, audioPercent:audioPercent, status: status, isAudio: isAudio){[weak self] (isSuccess:Bool, _ message:String?) in
            guard let self = self else {return}
            
            self.saveHistoryRequest = nil
            completion(isSuccess, message)
        }
    }

    private var deleteHistoryRequest:DeleteHistoryBookRequest?
    func deleteHistory(completion: @escaping ((_ isSuccess:Bool, _ message:String?)->Void)) {
        let deleteHistoryRequest = DeleteHistoryBookRequest()
        self.deleteHistoryRequest = deleteHistoryRequest
        deleteHistoryRequest.run(id: String(self.bookModel.id)){[weak self] (isSuccess:Bool, _ message:String?) in
            guard let self = self else {return}
            
            self.deleteHistoryRequest = nil
            self.bookModel.history = nil
            completion(isSuccess, message)
        }
    }
    
    private var createNoteRequest:CreateBookNoteRequest?
    func createBookNote(quote:String? = nil, comment:String, completion: @escaping ((_ note:NoteModel?, _ message:String?)->Void)) {
        let createNoteRequest = CreateBookNoteRequest()
        self.createNoteRequest = createNoteRequest
        createNoteRequest.run(bookId: String(self.bookModel.id), text: quote, comment: comment){[weak self] (note:NoteModel?, _ message:String?) in
            guard let self = self else {return}
            
            self.createNoteRequest = nil
            completion(note, message)
        }
    }
    
    private var listNotesRequest:ListBookNotesRequest?
    func getListBookNotes(completion: @escaping ((_ notes:[NoteModel]?, _ message:String?)->Void)) {
        let listNotesRequest = ListBookNotesRequest()
        self.listNotesRequest = listNotesRequest
        listNotesRequest.run(bookId: String(self.bookModel.id)){[weak self] (notes:[NoteModel]?, _ message:String?) in
            guard let self = self else {return}
            
            self.listNotesRequest = nil
            completion(notes, message)
        }
    }

    deinit {
        favoriteRequest?.cancel()
    }
    
    static public func getBooks(title:String? = nil, bookType:BooksType? = nil, category:String? = nil, ordering: BooksOrderingType? = nil, bookHistoryFilter:Set<BookHistoryFilterType>? = nil, page:Int? = nil, completion: @escaping ((_ books:[BookMVVM]?, _ pages:ResponseMetaModel?, _ message:String?)->Void)) -> ()->() {
        let booksRequest = BooksRequest()
        booksRequest.run(title: title, bookType:bookType, category:category, ordering: ordering, bookHistoryFilter:bookHistoryFilter, page:page, completion: {(books:[BookModel]?, pages:ResponseMetaModel?, message:String?) in
            if let books = books {
                print(books)
                
                let bookMVVMs = books.map({BookMVVM(bookModel: $0)})
                completion(bookMVVMs, pages, message)
            }
            else{
                completion(nil, nil, message)
            }
        })

        return {booksRequest.cancel()}
    }
    
    public func audioUrl() -> URL?{
        if loadingStorageFile?.isExistStoredAudioFile ?? false {
            return loadingStorageFile?.storedAudioFile
        }
        else if let audioFile = self.bookModel.audioFile, let audioFileURL = URL(string:audioFile) {
            return audioFileURL
        }
        
        return nil
    }
    
    func tempFolderPath() -> URL{
        return URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("books")
    }
    
    func tempFilePath() -> URL{
        return tempFolderPath().appendingPathComponent(String(self.bookModel.id))
    }
    
    var tempBookPath:URL?
    var downloadFileRequest:DownloadFileRequest?
    func loadBookTempFile(withCompletion completion: @escaping (_ path:String?, _ message:String?)->Void){
        guard let readingFile = self.bookModel.readingFile, !readingFile.isEmpty else {DispatchQueue.main.async {completion(nil, nil)}; return}

        let filePath = tempFilePath()
        downloadFileRequest?.cancel()
        downloadFileRequest = DownloadFileRequest()
        downloadFileRequest?.run(url: readingFile, path: filePath.absoluteString, completion: {[weak self](success:Bool, message:String?) in
            guard let self = self else {return}
            self.downloadFileRequest = nil
            
            if success {
                self.tempBookPath = filePath
                completion(filePath.absoluteString, message)
            }
            else{
                completion(nil, message)
            }
        })
    }
    
    func cleanTemporary() -> Bool{
        guard let tempBookPath = tempBookPath, tempBookPath == tempFilePath() else {return false}
        do {try FileManager.default.removeItem(atPath: tempBookPath.path)} catch {return false}
        return true
    }
}

extension BookMVVM: Equatable {
    static func == (lhs: BookMVVM, rhs: BookMVVM) -> Bool {
        return lhs.bookModel.id == rhs.bookModel.id
    }
}

extension BookMVVM: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(bookModel.id)
    }
}

extension BookMVVM {
    private static var downloadBooks:[BookMVVM] = { BookMVVM.restoreDownloadBooks()}()
    
    static public func getDownloadBooks(title:String? = nil, bookHistoryFilter:Set<BookHistoryFilterType>? = nil)->[BookMVVM] {
        let filteredTitleBooks = downloadBooks.filter({
            guard let title = title?.uppercased(), !title.isEmpty else {return true}
            if nil != $0.bookModel.title.uppercased().range(of: title) {return true}
            if nil != $0.bookModel.author()?.uppercased().range(of: title) {return true}
            return false
        })
        
        let filteredTypeBooks = filteredTitleBooks.filter({
            guard let bookHistoryFilter = bookHistoryFilter, !bookHistoryFilter.isEmpty else {return true}
            if nil ==  $0.loadingStorageFile?.loadingTime {
                return bookHistoryFilter.contains(.processing)
            }
            else{
                return bookHistoryFilter.contains(.finished)
            }

            let loadingStatus:LoadingStorageFile.LoadingStorageStatus = $0.loadingStorageFile?.loadingStatus ?? .undefine

            switch loadingStatus{
                case .undefine:
                    return bookHistoryFilter.contains(.notStarted)
                case .loading:
                    return bookHistoryFilter.contains(.processing)
                case .faild(_):
                    return bookHistoryFilter.contains(.finished)
                case .loaded:
                    return bookHistoryFilter.contains(.finished)
            }
            
         })
        
        return filteredTypeBooks
    }
    
    static private func restoreDownloadBooks()->[BookMVVM] {
        if let currentUserId = LoginModel.current?.user.id {
            if let data = (UserDefaults.standard.object(forKey: UserDefaultsKeys.DownloadStorage.rawValue) as? Data),
               let loadRequests = try? JSONDecoder().decode([Int: [Int:LoadingStorageFile]].self, from: data) {
                BookMVVM.loadRequests = loadRequests[currentUserId] ?? [:]
            }
            
            if let data = (UserDefaults.standard.object(forKey: UserDefaultsKeys.DownloadBookModel.rawValue) as? Data),
               let allBookModels = try? JSONDecoder().decode([Int:[BookModel]].self, from: data) {
                if let bookModels = allBookModels[currentUserId] {
                    return bookModels.map{BookMVVM(bookModel: $0)}
                }
            }
        }
        
        return []
    }
    
    static public func restoreDownloads(){
        downloadBooks = restoreDownloadBooks()
    }

    public func save(){
        if let currentUserId = LoginModel.current?.user.id {
            let downloadBookModels = type(of:self).downloadBooks.map({$0.bookModel})
            if let encoded = try? JSONEncoder().encode([currentUserId:downloadBookModels]) {
                UserDefaults.standard.set(encoded, forKey: UserDefaultsKeys.DownloadBookModel.rawValue)
                UserDefaults.standard.synchronize()
            }
        }
        
        type(of: self).saveLoadings()
    }
    
    public func isDownloads()->Bool {
        return type(of: self).downloadBooks.contains(self)
    }
    
    public func addDownloads() {
        if isDownloads() {return}
        
        type(of: self).downloadBooks.insert(self, at: 0)
        save()
        
        loadStorageContent()
    }
    
    public func removeDownloads() {
        if let index = type(of: self).downloadBooks.firstIndex(of: self) {
            type(of: self).downloadBooks.remove(at: index)
            save()
        }
        
        self.deleteStorageContent()
    }
}

extension BookMVVM {
    static private var loadRequests:[Int:LoadingStorageFile] = [:]
    
    public var loadingStorageFile:LoadingStorageFile? {get{type(of: self).loadRequests[self.bookModel.id]}}
    public func loadStorageContent() {
        if nil != loadingStorageFile {return}
        
        let loadingStorageFile = LoadingStorageFile(id:self.bookModel.id, readingFile: self.bookModel.readingFile, audioFile: self.bookModel.audioFile)
        type(of: self).loadRequests[self.bookModel.id] = loadingStorageFile
    }
    
    public func deleteStorageContent() {
        if let loadingStorageFile = loadingStorageFile {
            loadingStorageFile.cancel()
            
            if let storageAudioFilePath = loadingStorageFile.storedAudioFile?.path {
                do {try FileManager.default.removeItem(atPath: storageAudioFilePath)} catch {print("Can't remove audio file " + storageAudioFilePath)}
            }
            
            if let storageBookFilePath = loadingStorageFile.storedBookFile?.path {
                do {try FileManager.default.removeItem(atPath: storageBookFilePath)} catch {print("Can't remove epub file " + storageBookFilePath)}
            }
            
            type(of: self).loadRequests.removeValue(forKey: self.bookModel.id)
        }
    }
    
    static public func saveLoadings(){
        if let currentUserId = LoginModel.current?.user.id {
            if let encoded = try? JSONEncoder().encode([currentUserId: BookMVVM.loadRequests]) {
                UserDefaults.standard.set(encoded, forKey: UserDefaultsKeys.DownloadStorage.rawValue)
                UserDefaults.standard.synchronize()
            }
        }
    }
}


