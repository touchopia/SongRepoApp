//
//  Untitled.swift
//  MusicKitApp
//
//  Created by Phil Wright on 4/17/25.
//

import UIKit
import MusicKit // Import MusicKit

class PlaybackViewController: UIViewController {

    // MARK: - Properties

    // The song to be played, passed from the previous view controller
    var song: Song?

    // Music player instance - using the shared player
    private let musicPlayer = ApplicationMusicPlayer.shared

    // MARK: - UI Elements

    private let artworkImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 8 // Larger rounded corners for main artwork
        return imageView
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.preferredFont(forTextStyle: .title1) // Prominent font for title
        label.textAlignment = .center
        label.numberOfLines = 0 // Allow multiple lines for long titles
        return label
    }()

    private let artistLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.preferredFont(forTextStyle: .title2) // Slightly smaller for artist
        label.textAlignment = .center
        label.textColor = .gray
        label.numberOfLines = 0 // Allow multiple lines
        return label
    }()

    private let playPauseButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        // Use system images for play/pause
        let playImage = UIImage(systemName: "play.fill", withConfiguration: UIImage.SymbolConfiguration(pointSize: 40))
        button.setImage(playImage, for: .normal)
        button.tintColor = .systemBlue // Or any color you prefer
        button.addTarget(self, action: #selector(playPauseButtonTapped), for: .touchUpInside)
        return button
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "Now Playing" // Set a title for the playback screen

        setupViews()
        configureWithSong()

        // Observe player state changes to update the play/pause button
        // We need to create a Task to observe the async stream
        Task {
            await observePlaybackState()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Optional: Pause playback when leaving this screen
        // musicPlayer.pause()
        // Or stop completely:
        // musicPlayer.stop()
    }


    // MARK: - Setup UI

    private func setupViews() {
        view.addSubview(artworkImageView)
        view.addSubview(titleLabel)
        view.addSubview(artistLabel)
        view.addSubview(playPauseButton)

        let padding: CGFloat = 20
        let artworkSize: CGFloat = view.bounds.width * 0.7 // Artwork takes up 70% of screen width

        // Set up constraints
        NSLayoutConstraint.activate([
            // Artwork Image View constraints
            artworkImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            artworkImageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: padding),
            artworkImageView.widthAnchor.constraint(equalToConstant: artworkSize),
            artworkImageView.heightAnchor.constraint(equalToConstant: artworkSize),

            // Title Label constraints
            titleLabel.topAnchor.constraint(equalTo: artworkImageView.bottomAnchor, constant: padding),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: padding),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -padding),

            // Artist Label constraints
            artistLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            artistLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: padding),
            artistLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -padding),

            // Play/Pause Button constraints
            playPauseButton.topAnchor.constraint(equalTo: artistLabel.bottomAnchor, constant: padding * 2),
            playPauseButton.centerXAnchor.constraint(equalTo: view.centerXAnchor)
            // Add constraints for other controls (progress bar, etc.) here if you add them
        ])
    }

    // MARK: - Configuration

    private func configureWithSong() {
        guard let song = song else {
            titleLabel.text = "No Song Selected"
            artistLabel.text = ""
            artworkImageView.image = UIImage(systemName: "music.note") // Placeholder
            artworkImageView.tintColor = .gray
            playPauseButton.isEnabled = false // Disable playback controls
            return
        }

        titleLabel.text = song.title
        artistLabel.text = song.artistName

        // Load artwork asynchronously using the same logic as the table view cell
        if let artwork = song.artwork, let artworkURL = artwork.url(width: Int(400), height: Int(300)) {
            Task {
                do {
                    let (data, _) = try await URLSession.shared.data(from: artworkURL)
                    if let image = UIImage(data: data) {
                        DispatchQueue.main.async {
                            self.artworkImageView.image = image
                        }
                    } else {
                        print("Could not create image from data for \(song.title)")
                        DispatchQueue.main.async {
                            self.artworkImageView.image = UIImage(systemName: "music.note") // Placeholder
                            self.artworkImageView.tintColor = .gray
                        }
                    }
                } catch {
                    print("Error loading artwork for \(song.title): \(error)")
                    DispatchQueue.main.async {
                        self.artworkImageView.image = UIImage(systemName: "music.note") // Placeholder
                        self.artworkImageView.tintColor = .gray
                    }
                }
            }
        } else {
            artworkImageView.image = UIImage(systemName: "music.note") // Placeholder
            artworkImageView.tintColor = .gray
        }

        // Start playback immediately when the view is configured
        playSong(song)
    }

    // MARK: - Playback

    private func playSong(_ song: Song) {
        Task {
            do {
                // Set the playback queue to the selected song
                musicPlayer.queue = [song]

                // Begin playback
                try await musicPlayer.play()

                print("Now playing: \(song.title)")

            } catch {
                print("Error playing song \(song.title): \(error)")
                DispatchQueue.main.async {
                    let alert = UIAlertController(title: "Playback Error", message: "Could not play \(song.title).", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                    self.present(alert, animated: true, completion: nil)
                    // Optionally update UI to show error state
                }
            }
        }
    }

    @objc private func playPauseButtonTapped() {
        Task {
            do {
                if musicPlayer.state.playbackStatus == .playing {
                    musicPlayer.pause()
                    print("Playback paused")
                } else {
                    // If paused or stopped, resume/start playback
                    try await musicPlayer.play()
                     print("Playback resumed/started")
                }
            } catch {
                print("Error toggling playback: \(error)")
                 DispatchQueue.main.async {
                    let alert = UIAlertController(title: "Playback Error", message: "Could not toggle playback.", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                    self.present(alert, animated: true, completion: nil)
                }
            }
        }
    }

    // MARK: - Player State Observation

    private func observePlaybackState() async { // Made async to await the stream
        // Observe changes to the playback status
        // musicPlayer.playbackStatusUpdates is an AsyncSequence
//        for await status in musicPlayer.state {
//            DispatchQueue.main.async {
//                // Explicitly use MusicKit.MusicPlayer.PlaybackStatus
//                self.updatePlayPauseButton(with: status)
//            }
//        }
    }

    // Explicitly use MusicKit.MusicPlayer.PlaybackStatus in the parameter type
    private func updatePlayPauseButton(with status: MusicKit.MusicPlayer.PlaybackStatus) {
        let imageName = status == .playing ? "pause.fill" : "play.fill"
        let image = UIImage(systemName: imageName, withConfiguration: UIImage.SymbolConfiguration(pointSize: 40))
        playPauseButton.setImage(image, for: .normal)
    }
}


