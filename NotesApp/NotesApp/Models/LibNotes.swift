import Foundation

// C API bridge for libnotes
struct LibNotes {
    
    // C structures matching Zig definitions
    struct CNote {
        let id: UInt64
        let title: UnsafePointer<CChar>
        let content: UnsafePointer<CChar>
        let created_at: UInt64
        let updated_at: UInt64
        let tags: UnsafePointer<CChar>
    }
    
    struct CNotesResult {
        let notes: UnsafeMutablePointer<CNote>?
        let count: UInt
        let error_code: Int32
        let error_message: UnsafePointer<CChar>
    }
    
    struct CSearchResult {
        let note_id: UInt64
        let rank: Double
        let snippet: UnsafePointer<CChar>
    }
    
    struct CSearchResults {
        let results: UnsafeMutablePointer<CSearchResult>?
        let count: UInt
        let error_code: Int32
        let error_message: UnsafePointer<CChar>
    }
    
    // Error codes
    static let NOTES_OK: Int32 = 0
    static let NOTES_ERROR_INVALID_PARAM: Int32 = -1
    static let NOTES_ERROR_DATABASE: Int32 = -2
    static let NOTES_ERROR_NOT_FOUND: Int32 = -3
    static let NOTES_ERROR_MEMORY: Int32 = -4
    
    // C function declarations
    @_silgen_name("notes_init")
    static func notes_init(_ dbPath: UnsafePointer<CChar>) -> Int32
    
    @_silgen_name("notes_cleanup")
    static func notes_cleanup()
    
    @_silgen_name("notes_create")
    static func notes_create(_ title: UnsafePointer<CChar>, _ content: UnsafePointer<CChar>) -> UInt64
    
    @_silgen_name("notes_get_all")
    static func notes_get_all() -> CNotesResult
    
    @_silgen_name("notes_search")
    static func notes_search(_ query: UnsafePointer<CChar>, _ limit: UInt32) -> CSearchResults
    
    @_silgen_name("notes_free_results")
    static func notes_free_results(_ results: CNotesResult)
    
    @_silgen_name("notes_free_search_results")
    static func notes_free_search_results(_ results: CSearchResults)
}