//
//  Untitled.swift
//  MusicKitApp
//
//  Created by Phil Wright on 4/17/25.
//

import UIKit
import MusicKit

class SongTableViewCell: UITableViewCell {
    
    // MARK: - UI Elements
    
    private let containerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .secondarySystemGroupedBackground
        view.layer.cornerRadius = 12
        view.clipsToBounds = true
        return view
    }()
    
    private let iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        
        // Default music icon
        let configuration = UIImage.SymbolConfiguration(pointSize: 24, weight: .regular)
        imageView.image = UIImage(systemName: "music.note", withConfiguration: configuration)
        imageView.tintColor = .systemBlue
        
        return imageView
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        label.textColor = .label
        label.numberOfLines = 1
        return label
    }()
    
    private let artistLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        label.textColor = .secondaryLabel
        label.numberOfLines = 1
        return label
    }()
    
    private let albumLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 12, weight: .regular)
        label.textColor = .tertiaryLabel
        label.numberOfLines = 1
        return label
    }()
    
    private let durationLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.monospacedDigitSystemFont(ofSize: 14, weight: .regular)
        label.textColor = .secondaryLabel
        label.textAlignment = .right
        return label
    }()
    
    // MARK: - Initialization
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupCell()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        titleLabel.text = nil
        artistLabel.text = nil
        albumLabel.text = nil
        durationLabel.text = nil
    }
    
    // MARK: - Setup
    
    private func setupCell() {
        backgroundColor = .clear
        selectionStyle = .none
        
        // Add container view to cell content view
        contentView.addSubview(containerView)
        
        // Add subviews to container
        containerView.addSubview(iconImageView)
        containerView.addSubview(titleLabel)
        containerView.addSubview(artistLabel)
        containerView.addSubview(albumLabel)
        containerView.addSubview(durationLabel)
        
        // Setup constraints
        NSLayoutConstraint.activate([
            // Container view
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 6),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -6),
            
            // Icon image view
            iconImageView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            iconImageView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 32),
            iconImageView.heightAnchor.constraint(equalToConstant: 32),
            
            // Title label
            titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 12),
            titleLabel.leadingAnchor.constraint(equalTo: iconImageView.trailingAnchor, constant: 12),
            titleLabel.trailingAnchor.constraint(equalTo: durationLabel.leadingAnchor, constant: -8),
            
            // Artist label
            artistLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 2),
            artistLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            artistLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            
            // Album label
            albumLabel.topAnchor.constraint(equalTo: artistLabel.bottomAnchor, constant: 2),
            albumLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            albumLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            albumLabel.bottomAnchor.constraint(lessThanOrEqualTo: containerView.bottomAnchor, constant: -12),
            
            // Duration label
            durationLabel.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            durationLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            durationLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 40)
        ])
        
        // Add visual effect when pressed
        let interactionView = UIView()
        interactionView.translatesAutoresizingMaskIntoConstraints = false
        interactionView.backgroundColor = .systemGray6.withAlphaComponent(0.0)
        interactionView.isUserInteractionEnabled = false
        
        containerView.insertSubview(interactionView, at: 0)
        
        NSLayoutConstraint.activate([
            interactionView.topAnchor.constraint(equalTo: containerView.topAnchor),
            interactionView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            interactionView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            interactionView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])
        
        self.selectedBackgroundView = interactionView
    }
    
    // MARK: - Configure
    
    func configure(with song: Song) {
        titleLabel.text = song.title
        artistLabel.text = song.artistName
        albumLabel.text = song.albumTitle
        
        // Format duration
        if let duration = song.duration {
            durationLabel.text = formatDuration(duration)
        } else {
            durationLabel.text = "--:--"
        }
        
        // Set a context menu
        setupContextMenu(for: song)
    }
    
    // MARK: - Helper Methods
    
    private func formatDuration(_ timeInterval: TimeInterval) -> String {
        let minutes = Int(timeInterval / 60)
        let seconds = Int(timeInterval.truncatingRemainder(dividingBy: 60))
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    // MARK: - Context Menu
    
    private func setupContextMenu(for song: Song) {
        let interaction = UIContextMenuInteraction(delegate: self)
        containerView.addInteraction(interaction)
        containerView.isUserInteractionEnabled = true
    }
    
    // MARK: - Selection Handling
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        if animated {
            UIView.animate(withDuration: 0.1, animations: {
                self.containerView.backgroundColor = selected ?
                    .tertiarySystemFill : .secondarySystemGroupedBackground
            })
        } else {
            containerView.backgroundColor = selected ?
                .tertiarySystemFill : .secondarySystemGroupedBackground
        }
    }
    
    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        
        if animated {
            UIView.animate(withDuration: 0.1, animations: {
                self.containerView.backgroundColor = highlighted ?
                    .tertiarySystemFill : .secondarySystemGroupedBackground
            })
        } else {
            containerView.backgroundColor = highlighted ?
                .tertiarySystemFill : .secondarySystemGroupedBackground
        }
    }
}

// MARK: - UIContextMenuInteractionDelegate

extension SongTableViewCell: UIContextMenuInteractionDelegate {
    func contextMenuInteraction(_ interaction: UIContextMenuInteraction, configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration? {
        
        // Get the song from the cell somehow - we'd need to store it as a property
        // For now, let's just create a generic menu
        
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { _ in
            let playAction = UIAction(
                title: "Play Now",
                image: UIImage(systemName: "play.fill"),
                handler: { [weak self] _ in
                    // Handle play action
                    print("Play action selected")
                }
            )
            
            let addToQueueAction = UIAction(
                title: "Add to Queue",
                image: UIImage(systemName: "text.badge.plus"),
                handler: { [weak self] _ in
                    // Handle queue action
                    print("Add to queue action selected")
                }
            )
            
            let viewAlbumAction = UIAction(
                title: "View Album",
                image: UIImage(systemName: "square.stack"),
                handler: { [weak self] _ in
                    // Handle view album action
                    print("View album action selected")
                }
            )
            
            return UIMenu(title: "", children: [playAction, addToQueueAction, viewAlbumAction])
        }
    }
}

