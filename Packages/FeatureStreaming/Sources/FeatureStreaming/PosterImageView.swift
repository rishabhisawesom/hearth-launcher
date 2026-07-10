import SwiftUI

public enum StreamingPosterService: String, Sendable {
    case netflix
    case prime
}

/// Resolves local poster PNGs under Application Support.
public enum PosterStore {
    public static func postersDirectory(for service: StreamingPosterService) -> URL? {
        guard let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            return nil
        }
        return support
            .appendingPathComponent("Hearth/posters/\(service.rawValue)", isDirectory: true)
    }

    public static func resolveLocalPoster(
        service: StreamingPosterService,
        tileID: String,
        title: String,
        localPosterName: String?
    ) -> URL? {
        guard let directory = postersDirectory(for: service) else { return nil }

        var candidates: [String] = []
        if let localPosterName, !localPosterName.isEmpty {
            candidates.append(localPosterName)
        }
        candidates.append(safeFilename(tileID))
        candidates.append(sanitizedTitle(title))

        for candidate in candidates {
            for name in filenameVariants(candidate) {
                let url = directory.appendingPathComponent(name)
                if FileManager.default.fileExists(atPath: url.path) {
                    return url
                }
            }
        }
        return nil
    }

    private static func filenameVariants(_ base: String) -> [String] {
        let trimmed = base.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }
        if trimmed.lowercased().hasSuffix(".png") {
            return [trimmed]
        }
        return ["\(trimmed).png"]
    }

    private static func safeFilename(_ raw: String) -> String {
        raw
            .replacingOccurrences(of: "://", with: "_")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: ":", with: "_")
            .replacingOccurrences(of: "?", with: "_")
            .replacingOccurrences(of: "&", with: "_")
            .replacingOccurrences(of: "=", with: "_")
            .replacingOccurrences(of: "#", with: "_")
    }

    private static func sanitizedTitle(_ title: String) -> String {
        let lowered = title.lowercased()
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-_"))
        return lowered
            .components(separatedBy: allowed.inverted)
            .filter { !$0.isEmpty }
            .joined(separator: "-")
    }
}

enum PosterImageLoader {
    static let session: URLSession = {
        let config = URLSessionConfiguration.default
        config.urlCache = URLCache(memoryCapacity: 50_000_000, diskCapacity: 200_000_000)
        config.requestCachePolicy = .returnCacheDataElseLoad
        return URLSession(configuration: config)
    }()
}

public struct PosterImageView: View {
    let service: StreamingPosterService
    let tileID: String
    let title: String
    let posterURL: URL?
    let localPosterName: String?
    var cornerRadius: CGFloat = 8
    var placeholderSystemName: String = "play.tv"

    @State private var loadedImage: NSImage?

    public init(
        service: StreamingPosterService,
        tileID: String,
        title: String,
        posterURL: URL?,
        localPosterName: String? = nil,
        cornerRadius: CGFloat = 8,
        placeholderSystemName: String = "play.tv"
    ) {
        self.service = service
        self.tileID = tileID
        self.title = title
        self.posterURL = posterURL
        self.localPosterName = localPosterName
        self.cornerRadius = cornerRadius
        self.placeholderSystemName = placeholderSystemName
    }

    public var body: some View {
        Group {
            if let loadedImage {
                Image(nsImage: loadedImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } else {
                placeholder
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
        .task(id: loadKey) {
            await loadPoster()
        }
    }

    private var loadKey: String {
        [
            service.rawValue,
            tileID,
            title,
            posterURL?.absoluteString ?? "",
            localPosterName ?? "",
        ].joined(separator: "|")
    }

    @MainActor
    private func loadPoster() async {
        loadedImage = nil

        if let localURL = PosterStore.resolveLocalPoster(
            service: service,
            tileID: tileID,
            title: title,
            localPosterName: localPosterName
        ), let image = NSImage(contentsOf: localURL) {
            loadedImage = image
            return
        }

        guard let posterURL else { return }

        if posterURL.isFileURL {
            loadedImage = NSImage(contentsOf: posterURL)
            return
        }

        guard posterURL.scheme == "http" || posterURL.scheme == "https" else { return }

        do {
            let (data, _) = try await PosterImageLoader.session.data(from: posterURL)
            loadedImage = NSImage(data: data)
        } catch {
            loadedImage = nil
        }
    }

    private var placeholder: some View {
        Image(systemName: placeholderSystemName)
            .font(.system(size: 48))
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
