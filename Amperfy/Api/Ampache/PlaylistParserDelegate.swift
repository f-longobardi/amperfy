import Foundation
import UIKit
import CoreData
import os.log

class PlaylistParserDelegate: GenericXmlParser {
    
    var playlist: Playlist?
    var libraryStorage: LibraryStorage
    
    init(libraryStorage: LibraryStorage) {
        self.libraryStorage = libraryStorage
        super.init()
    }
    
    private func resetPlaylistInCaseOfError() {
        if playlist != nil {
            os_log("Error: Playlist has been removed on server -> local id reset", log: log, type: .error)
            playlist?.id = 0
            playlist = nil
        }
    }
    
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String]) {
        buffer = ""
        
        switch(elementName) {
        case "playlist":
            guard let attributeId = attributeDict["id"] else {
                os_log("Error: Playlist could not be parsed -> id invalid", log: log, type: .error)
                resetPlaylistInCaseOfError()
                return
            }
            guard let playlistId = Int(attributeId) else {
                if attributeId.contains("smart_") {
                    os_log("Smart playlists are currently ignored: %s", log: log, type: .debug, attributeId)
                } else {
                    os_log("Playlist Ids must be Integers: %s", log: log, type: .debug, attributeId)
                }
                resetPlaylistInCaseOfError()
                return
            }
            
            if playlist != nil {
                playlist?.id = playlistId
            } else if playlistId != 0 {
                if let fetchedPlaylist = libraryStorage.getPlaylist(id: playlistId)  {
                    playlist = fetchedPlaylist
                } else {
                    playlist = libraryStorage.createPlaylist()
                    playlist?.id = playlistId
                }
            } else {
                os_log("Error: Playlist could not be parsed -> id is 0", log: log, type: .error)
            }
        default:
            break
        }
    }
    
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        switch(elementName) {
        case "name":
            playlist?.name = buffer
        case "playlist":
            playlist = nil
        default:
            break
        }
        
        buffer = ""
    }
    
}
