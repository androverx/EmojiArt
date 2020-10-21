//
//  EmojiArt.swift
//  EmojiArt
//
//  Created by Andrey Mosolov on 06.10.2020.
//

//MODEL

import Foundation

struct EmojiArt: Codable {//Encodable, Decodable {
    var backgroundURL: URL?
    var emojis = [Emoji]()
    
    struct Emoji: Identifiable, Codable, Hashable /*Hashable for use in Set*/ {
        let text: String
        var x: Int
        var y: Int
        var size: Int
        
        let id: Int
        
        fileprivate init (text: String, x: Int, y: Int, size: Int, id: Int) {
            self.text = text
            self.x = x
            self.y = y
            self.size = size
            self.id = id
        }
    }
    
    var json: Data? {
        return try? JSONEncoder().encode(self)
    }
    
    init() {}
    
    init? (json: Data?) {
        if json != nil, let newEmojiArt = try? JSONDecoder().decode(EmojiArt.self, from: json!) {
            self = newEmojiArt
        } else {
           return nil
        }
    }
    
    private var uniqueEmojiId = 0
    
    mutating func addEmoji(_ text: String, x: Int, y: Int, size: Int) {
        uniqueEmojiId += 1
        emojis.append(Emoji(text: text, x: x, y: y, size: size, id: uniqueEmojiId))
    }
}
