//
//  ViewController.swift
//  SongRepoApp
//
//  Created by Phil Wright on 4/18/25.
//
//
//  ViewController.swift
//  SongRepoApp
//
//  Created by Phil Wright on 4/18/25.
//

import UIKit
import MusicKit

class ViewController: UIViewController {

    let songManager = SongRepositoryManager.shared

    let searchTerm = "Queen" // Example search term

    private var songs: [Song] = [] {
        didSet {
            updateUI()
        }
    }

    // MARK: - Properties

    private let tableView: UITableView = {
        let table = UITableView(frame: .zero, style: .insetGrouped) // Using insetGrouped for modern look
        table.translatesAutoresizingMaskIntoConstraints = false
        table.register(SongTableViewCell.self, forCellReuseIdentifier: "SongTableViewCell")

        table.backgroundColor = .systemGroupedBackground
        table.separatorStyle = .none // Remove separators for custom cells
        table.rowHeight = UITableView.automaticDimension // Dynamic sizing
        table.estimatedRowHeight = 80
        return table
    }()

    private let statusLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textAlignment = .center
        label.text = "Loading Songs..."
        label.textColor = .secondaryLabel
        label.font = UIFont.systemFont(ofSize: 17, weight: .medium)
        label.numberOfLines = 0
        return label
    }()

    private let activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.translatesAutoresizingMaskIntoConstraints = false
        indicator.hidesWhenStopped = true
        indicator.color = .systemBlue
        return indicator
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        setupUI()

        // Request authorization when the view loads
        requestMusicAuthorization()
    }

    private func setupUI() {
        view.backgroundColor = .white

        view.addSubview(tableView)
        view.addSubview(statusLabel)
        view.addSubview(activityIndicator)

        tableView.delegate = self
        tableView.dataSource = self

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),

            statusLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            statusLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            statusLabel.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 20),
            statusLabel.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -20),

            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.bottomAnchor.constraint(equalTo: statusLabel.topAnchor, constant: -16)
        ])

        updateUI()
    }

    private func updateUI() {
        if songs.isEmpty {
            statusLabel.isHidden = false
            activityIndicator.startAnimating()
            tableView.isHidden = true
        } else {
            statusLabel.isHidden = true
            activityIndicator.stopAnimating()
            tableView.isHidden = false
            tableView.reloadData()
        }
    }

    private func restart() {
        // In this context, "restart" likely means reloading the data in the UI.
        // Since the `songs` property is updated in `searchAndLoadSongs`,
        // the `didSet` observer will call `updateUI`, which reloads the table view.
        // No additional action might be needed here unless you have other UI elements to refresh.
        print("UI updated after loading songs.")
    }

    private func requestMusicAuthorization() {
        Task {
            let authStatus = await MusicAuthorization.request()
            if authStatus == .authorized {
                // Once authorized, you can search for songs
                await searchAndLoadSongs()
            } else {
                print("Music authorization failed: \(authStatus)")
                await MainActor.run {
                    statusLabel.text = "Music library access was not authorized.\nPlease check your privacy settings."
                    activityIndicator.stopAnimating()
                }
                // Handle unauthorized state, perhaps show a message to the user
            }
        }
    }

    private func searchAndLoadSongs() async {
        await MainActor.run {
            statusLabel.text = "Searching for Songs..."
            activityIndicator.startAnimating()
        }
        do {
            // Search for songs
            let fetchedSongs = try await songManager.searchSongs(term: searchTerm)

            // Update the local songs array, which will trigger UI update
            await MainActor.run {
                print("Found \(fetchedSongs.count) songs matching '\(searchTerm)'")
                songs = fetchedSongs
                // The didSet observer on 'songs' will call updateUI()
            }
        } catch {
            print("Error searching for songs: \(error)")
            await MainActor.run {
                statusLabel.text = "Error loading songs.\nPlease try again later."
                activityIndicator.stopAnimating()
            }
        }
    }

    // Example function to load a specific song by ID
    private func loadSongByID(_ id: MusicItemID) async {
        do {
            // Request a specific song by ID
            let request = MusicCatalogResourceRequest<Song>(matching: \.id, equalTo: id)
            let response = try await request.response()

            if let song = response.items.first {
                // Add to repository
                songManager.addSong(song)
                print("Added song: \(song.title) to repository")
                // Optionally update UI if needed after loading a single song
                if songs.contains(where: { $0.id == song.id }) == false {
                    await MainActor.run {
                        songs.append(song)
                    }
                }
            }
        } catch {
            print("Error loading song: \(error)")
        }
    }

    // Example function to add a song to recently played
    @IBAction func markSongAsPlayed(_ sender: Any) {
        // This could be connected to a button tap
        if let song = songs.first { // Use the local 'songs' array
            songManager.addToRecentlyPlayed(song)
            print("Marked song as recently played: \(song.title)")
        }
    }

    // Example function to add a song to favorites
    @IBAction func addSongToFavorites(_ sender: Any) {
        if let song = songs.first { // Use the local 'songs' array
            songManager.addToFavorites(song)
            print("Added song to favorites: \(song.title)")
        }
    }
}

extension ViewController: UITableViewDelegate, UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return songs.count // Use the local 'songs' array
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "SongTableViewCell", for: indexPath) as? SongTableViewCell else {
            fatalError("Could not dequeue SongTableViewCell")
        }
        let song = songs[indexPath.row]
        cell.configure(with: song)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedSong = songs[indexPath.row]
        print("Selected song: \(selectedSong.title)")
        // Here you can handle the selection, e.g., play the song or show details
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
}
