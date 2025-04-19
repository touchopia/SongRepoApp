//
//  SongRepositoryManager.swift
//
//  SongRepoApp
//  Created by Phil Wright on 4/18/25.
//

import UIKit
import MusicKit

/// A singleton manager that provides a central repository for storing and accessing songs
class SongRepositoryManager {
    // MARK: - Singleton Instance
    static let shared = SongRepositoryManager()
    
    // MARK: - Properties
    private var songCache = [MusicItemID: Song]()
    private var recentlyPlayedSongs = [Song]()
    private var favoriteSongs = [Song]()
    private let maxRecentlyPlayedCount = 50
    
    // MARK: - Private Initialization
    private init() {
        // Private initializer for singleton pattern
        setupMusicAuthorization()
    }
    
    // MARK: - Authorization
    private func setupMusicAuthorization() {
        Task {
            let authorizationStatus = await MusicAuthorization.request()
            switch authorizationStatus {
            case .authorized:
                print("MusicKit authorization successful")
            default:
                print("MusicKit authorization not granted: \(authorizationStatus)")
            }
        }
    }
    
    // MARK: - Song Management
    
    /// Adds a song to the repository
    /// - Parameter song: The song to add to the repository
    func addSong(_ song: Song) {
        songCache[song.id] = song
    }
    
    /// Retrieves a song from the repository by its ID
    /// - Parameter id: The MusicItemID of the song to retrieve
    /// - Returns: The requested Song, if available
    func getSong(byID id: MusicItemID) -> Song? {
        return songCache[id]
    }
    
    /// Adds multiple songs to the repository
    /// - Parameter songs: An array of songs to add to the repository
    func addSongs(_ songs: [Song]) {
        for song in songs {
            //print("Attempting to add song \(song.title.uppercased()) ")
            addSong(song)
        }
    }
    
    /// Retrieves all songs stored in the repository
    /// - Returns: An array of all stored songs
    func getAllSongs() -> [Song] {
        return Array(songCache.values)
    }
    
    /// Removes a song from the repository by its ID
    /// - Parameter id: The MusicItemID of the song to remove
    /// - Returns: The removed Song, if it existed in the repository
    @discardableResult
    func removeSong(byID id: MusicItemID) -> Song? {
        return songCache.removeValue(forKey: id)
    }
    
    // MARK: - Recently Played Management
    
    /// Adds a song to the recently played list
    /// - Parameter song: The song to add to recently played
    func addToRecentlyPlayed(_ song: Song) {
        // Remove the song if it already exists to avoid duplicates
        recentlyPlayedSongs.removeAll { $0.id == song.id }
        
        // Add the song at the beginning of the array
        recentlyPlayedSongs.insert(song, at: 0)
        
        // Trim the array if it exceeds the maximum count
        if recentlyPlayedSongs.count > maxRecentlyPlayedCount {
            recentlyPlayedSongs = Array(recentlyPlayedSongs.prefix(maxRecentlyPlayedCount))
        }
    }
    
    /// Retrieves the list of recently played songs
    /// - Returns: An array of recently played songs
    func getRecentlyPlayedSongs() -> [Song] {
        return recentlyPlayedSongs
    }
    
    // MARK: - Favorites Management
    
    /// Adds a song to favorites
    /// - Parameter song: The song to add to favorites
    func addToFavorites(_ song: Song) {
        // Only add if not already in favorites
        if !favoriteSongs.contains(where: { $0.id == song.id }) {
            favoriteSongs.append(song)
        }
    }
    
    /// Removes a song from favorites
    /// - Parameter id: The ID of the song to remove from favorites
    /// - Returns: True if the song was removed, false if it wasn't in favorites
    @discardableResult
    func removeFromFavorites(id: MusicItemID) -> Bool {
        let initialCount = favoriteSongs.count
        favoriteSongs.removeAll { $0.id == id }
        return favoriteSongs.count < initialCount
    }
    
    /// Checks if a song is in the favorites list
    /// - Parameter id: The ID of the song to check
    /// - Returns: True if the song is in favorites
    func isFavorite(id: MusicItemID) -> Bool {
        return favoriteSongs.contains { $0.id == id }
    }
    
    /// Gets the list of favorite songs
    /// - Returns: An array of favorite songs
    func getFavoriteSongs() -> [Song] {
        return favoriteSongs
    }
    
    // MARK: - Search Functionality
    
    /// Searches for songs in Apple Music
    /// - Parameters:
    ///   - term: The search term
    ///   - limit: Maximum number of results to return
    /// - Returns: An array of matching songs
    func searchSongs(term: String, limit: Int = 20) async throws -> [Song] {
        var request = MusicCatalogSearchRequest(term: term, types: [Song.self])
        request.limit = limit
        
        let response = try await request.response()
        
        // Convert MusicItemCollection<Song> to [Song]
        let songs = Array(response.songs)
        
        // Add songs to our repository
        addSongs(songs)
        
        return songs
    }
}
