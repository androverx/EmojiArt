//
//  OptionalImage.swift
//  EmojiArt
//
//  Created by Andrey Mosolov on 07.10.2020.
//

import SwiftUI

struct OptionalImage: View {
    var uiImage: UIImage?
    
    var body: some View {
        Group{
            if uiImage != nil {
                Image(uiImage: uiImage!)
            }
        }
    }
}
