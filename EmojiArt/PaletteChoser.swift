//
//  PaletteChoser.swift
//  EmojiArt
//
//  Created by Andrey Mosolov on 08.10.2020.
//

import SwiftUI

struct PaletteChoser: View {
    @ObservedObject var document: EmojiArtDocument
    
    @Binding var chosenPalette: String
    
    @State private var showPaletteEditor = false
    var body: some View {
        HStack{
            Stepper(onIncrement: {
                self.chosenPalette = self.document.palette(after: self.chosenPalette)
            }, onDecrement: {
                self.chosenPalette = self.document.palette(before: self.chosenPalette)
            }, label: {EmptyView()})
            Text(self.document.paletteNames[self.chosenPalette] ?? "")
                
            Image(systemName: "keyboard").imageScale(.large)
                .onTapGesture { self.showPaletteEditor = true }
                .sheet(isPresented: $showPaletteEditor, content: {//popover(isPresented: $showPaletteEditor, content: {
                    PaletteEditor(chosenPalette: $chosenPalette, isShowing: $showPaletteEditor)
                        .environmentObject(document)
                        .frame(minWidth: 300, minHeight: 500)
                })
        }
        .fixedSize(horizontal: true, vertical: false)
    }
}


struct PaletteEditor: View {
    @EnvironmentObject var document: EmojiArtDocument
    @Binding var chosenPalette: String
    @Binding var isShowing: Bool
    @State var paletteName: String = ""
    @State var emojisToAdd: String = ""
    
    var body: some View {
        VStack(spacing: 0){
            ZStack{
                Text("Editor").font(.headline).padding()
                HStack{
                    Spacer()
                    Button(action: {self.isShowing = false}, label: {Text("Done")}).padding()
                }
            }
            
            Divider()
            
            Form{
                Section() {
                    TextField("Palette Name", text: $paletteName, onEditingChanged: {began in
                        if !began {
                            self.document.renamePalette(chosenPalette, to: paletteName)
                        }
                    })
                    TextField("Add emoji", text: $emojisToAdd, onEditingChanged: {began in
                        if !began {
                            chosenPalette = document.addEmoji(emojisToAdd, toPalette: chosenPalette)
                            emojisToAdd = ""
                        }
                    })
                }
                Section(header: Text("Remove emoji")) {
                    //ForEach (chosenPalette.map{ String($0) }, id: \.self) { emoji in
                    Grid(chosenPalette.map{ String($0) }, id: \.self) { emoji in
                        Text(emoji)
                            .font(Font.system(size: self.fontSize))
                            .onTapGesture {
                            chosenPalette = document.removeEmoji(emoji, fromPalette: chosenPalette)
                        }
                    }
                    .frame(height: self.height)
                }
            }
            //Spacer()
        }
        .onAppear { paletteName = document.paletteNames[chosenPalette] ?? "" }
    }
    
    let fontSize: CGFloat = 40
    var height: CGFloat {
        CGFloat((chosenPalette.count - 1) / 6) * 70 + 70
    }
}


struct PaletteChoser_Previews: PreviewProvider {
    static var previews: some View {
        //PaletteChoser(document: EmojiArtDocument(), chosenPalette: Binding.constant(""))
        PaletteEditor(chosenPalette: Binding.constant(""), isShowing: Binding.constant(true)).environmentObject(EmojiArtDocument())
    }
}
