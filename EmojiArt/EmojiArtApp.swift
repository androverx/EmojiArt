//
//  EmojiArtApp.swift
//  EmojiArt
//
//  Created by Andrey Mosolov on 06.10.2020.
//

import SwiftUI

@main
struct EmojiArtApp: App {
    func storeView () -> some View {
        //let store = EmojiArtDocumentStore(named: "Emoji Art")
        
        //store.addDocument()
        //store.addDocument(named: "doc1")
        
        let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        
        let store = EmojiArtDocumentStore(directory: url)
        return EmojiArtDocumentChooser().environmentObject(store)
    }

    
    var body: some Scene {
        WindowGroup {
            //EmojiArtDocumentView(document: EmojiArtDocument())
            storeView()
        }
    }
}
