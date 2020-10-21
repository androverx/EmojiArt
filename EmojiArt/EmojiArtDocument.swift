//
//  EmojiArtDocument.swift
//  EmojiArt
//
//  Created by Andrey Mosolov on 06.10.2020.
//

//VIEW-MODEL

import SwiftUI
import Combine

class EmojiArtDocument: ObservableObject, Hashable, Identifiable {
    static func == (lhs: EmojiArtDocument, rhs: EmojiArtDocument) -> Bool {
        lhs.id == rhs.id
    }
 
    var id: UUID
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static let palette: String = "🐶🐱🐭🐹🐰🦊🐻"
    
    /*@Published  workaroud property wrapper problem
    private var emojiArt: EmojiArt { //= EmojiArt() {
        willSet {
            objectWillChange.send()
        }
        didSet {
            //print("json: \(emojiArt.json?.utf8 ?? "nil")")
            UserDefaults.standard.set(emojiArt.json, forKey: EmojiArtDocment.untitled)
        }
    }*/
    
    @Published private var emojiArt: EmojiArt
    
    //private static let untitled = "EmojiArtDocument.Untitled"
    
    private var autosaveCancelleble: AnyCancellable?
    
    init(id: UUID? = nil) {
        self.id = id ?? UUID()
        let defaultsKey = "EmojiArtDocument.\(self.id.uuidString)"
        emojiArt = EmojiArt.init(json: UserDefaults.standard.data(forKey: defaultsKey)) ?? EmojiArt()
        fetchBackgroundImageData()
        autosaveCancelleble = $emojiArt.sink { emojiArt in
            UserDefaults.standard.set(emojiArt.json, forKey: defaultsKey)
        }
    }
    
    //file system
    var url: URL? {
        didSet {
            self.save(self.emojiArt)
        }
    }
    
    init(url: URL) {
        self.id = UUID()
        self.url = url
        self.emojiArt = EmojiArt(json: try? Data(contentsOf: url)) ?? EmojiArt()
        fetchBackgroundImageData()
        autosaveCancelleble = $emojiArt.sink { emojiArt in
            self.save(emojiArt)
        }
    }
    
    private func save(_ emojiArt: EmojiArt) {
        if url != nil {
            try? emojiArt.json?.write(to: url!)
        }
    }
    
    @Published var steadyStatePanOffset: CGSize = .zero
    @Published var steadyStateZoomScale: CGFloat = 1.0
    @Published private(set) var backgroundImage: UIImage?
    
    var emojis: [EmojiArt.Emoji] {emojiArt.emojis}
    
    //MARK: intents
    func addEmoji (_ emoji: String, at location: CGPoint, size: CGFloat) {
        emojiArt.addEmoji(emoji, x: Int(location.x), y: Int(location.y), size: Int(size))
    }
    
    func moveEmoji (_ emoji: EmojiArt.Emoji, by offset: CGSize) {
        if let index = emojiArt.emojis.firstIndex(matching: emoji) {
            emojiArt.emojis[index].x += Int(offset.width)
            emojiArt.emojis[index].y += Int(offset.height)
        }
    }
    
    func scaleEmoji(_ emoji: EmojiArt.Emoji, by scale: CGFloat) {
        if let index = emojiArt.emojis.firstIndex(matching: emoji) {
            emojiArt.emojis[index].size = Int((CGFloat(emojiArt.emojis[index].size) * scale).rounded(.toNearestOrEven))
        }
    }
    
    var backgroundURL: URL? {
        set {
            emojiArt.backgroundURL = newValue?.imageURL
            fetchBackgroundImageData()
        }
        get {
            emojiArt.backgroundURL
        }
    }
    
    private var fetchImageCancellable: AnyCancellable?
    private func fetchBackgroundImageData() {
        backgroundImage = nil
        if let url = self.emojiArt.backgroundURL {
            fetchImageCancellable?.cancel()
            let session = URLSession.shared
            let publisher  = session.dataTaskPublisher(for: url).map { data, urlResponse in UIImage(data: data) }
            .receive(on: DispatchQueue.main)
            .replaceError(with: nil)
            
             fetchImageCancellable = publisher.assign(to: \.backgroundImage, on: self)
            /*
            DispatchQueue.global(qos: .userInitiated ).async {
                if let imageData = try? Data(contentsOf: url) { //before we use URLSession alternative
                    DispatchQueue.main.async {
                        if url == self.emojiArt.backgroundURL { //fix - loading only what we need in last attempt, ignore old url if user didn't wait for download
                            self.backgroundImage = UIImage(data: imageData)
                        }
                       
                    }
                }
            }
           */
        }
    }
}


extension EmojiArt.Emoji {
    var fontSize: CGFloat {
        CGFloat(self.size)
    }
    
    var location: CGPoint {
        CGPoint(x: self.x, y: self.y)
    }
}
