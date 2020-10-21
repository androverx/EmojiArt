//
//  EmojiArtDocumentView.swift
//  EmojiArt
//
//  Created by Andrey Mosolov on 06.10.2020.
//

//VIEW

import SwiftUI

struct EmojiArtDocumentView: View {
    @ObservedObject var document: EmojiArtDocument
    
    @State private var chosenPalette: String = ""
    
    init(document: EmojiArtDocument) {
        self.document = document
        _chosenPalette = State(wrappedValue: self.document.defaultPalette) //instead of .onAppear
    }
    
    var body: some View {
        VStack {
            HStack{
                PaletteChoser(document: document, chosenPalette: $chosenPalette)
                ScrollView(.horizontal) {
                    HStack{
                        ForEach(chosenPalette.map {String($0)}, id: \.self )  {emoji in
                            Text(emoji)
                                .font(Font.system(size: defaultEmojiSize))
                                .onDrag {return NSItemProvider(object: emoji as NSString) }
                        }
                    }
                }
                //.onAppear { self.chosenPalette = self.document.defaultPalette }
                //.layoutPriority(1)
            }
            //.padding(.horizontal)
            
            //Rectangle().foregroundColor(.white).overlay(Image(uiImage: self.document.backgroundImage))
            GeometryReader() {geometry in
                ZStack {
                    Color.white.overlay(
                        OptionalImage(uiImage: self.document.backgroundImage)
                            .scaleEffect(zoomScale)
                            .offset(self.panOffset)
                    )
                    .gesture(self.doubleTapToZoom(in: geometry.size))
                    
                   //onDrop was there
                    if self.isLoading {
                        Image(systemName: "timer").imageScale(.large).spinning()
                    } else {
                        ForEach(self.document.emojis) { emoji in
                            Text(emoji.text)
                                .font(animatableWithSize: emoji.fontSize * zoomScale)//(self.font(for: emoji))
                                .position(self.position(for: emoji, in: geometry.size))
                        }
                    }
                    
                }
                .clipped()
                .gesture(self.panGesture())
                .gesture(self.zoomGesture())
                //now ondrop there
                .edgesIgnoringSafeArea([.horizontal, .bottom])
                .onReceive(self.document.$backgroundImage) { image in
                    zoomToFit(image, in: geometry.size)
                }
                    
                .onDrop(of: ["public.image", "public.text"], isTargeted: nil, perform: { providers, location in
                    var location = geometry.convert(location, from: . global)
                    location = CGPoint (x: location.x - geometry.size.width/2, y: location.y - geometry.size.height/2)
                    location = CGPoint (x: location.x - self.panOffset.width, y: location.y - self.panOffset.height)
                    location = CGPoint (x: location.x / zoomScale, y: location.y / zoomScale)
                    return self.drop (providers: providers, at: location )
                    })
                .navigationBarItems(leading: pickImage, trailing: Button(action: {
                    if let url = UIPasteboard.general.url, url != self.document.backgroundURL  {
                        //self.document.backgroundURL = url
                        confirmBackgorundPaste = true
                    } else {
                        self.explainBackgorundPaste = true
                    }
                }, label: {
                    Image(systemName: "doc.on.clipboard").imageScale(.large)
                        .alert(isPresented: self.$explainBackgorundPaste, content: {
                        Alert(title: Text("Paste background"),
                              message: Text("Copy the URL of an image to the clipboard first"),
                              dismissButton: .default(Text("OK")))
                    })
                }))
                
            }
            .zIndex(-1)
            
        }
        .alert(isPresented: self.$confirmBackgorundPaste) {
            Alert(title: Text("Paste background"),
                  message: Text("Replace your background with \(UIPasteboard.general.url?.absoluteString ?? "nothing")?."),
                  primaryButton: .default(Text("OK")) {
                        self.document.backgroundURL = UIPasteboard.general.url
                  },
                  secondaryButton: .cancel())
        }
    }
    
    @State private var showImagePicker = false
    @State private var imagePickerSourceType = UIImagePickerController.SourceType.photoLibrary
    
    private var pickImage: some View {
        HStack{
            Image(systemName: "photo").imageScale(.large).foregroundColor(.accentColor).onTapGesture{
                self.imagePickerSourceType = .photoLibrary
                self.showImagePicker = true
            }
            if UIImagePickerController.isSourceTypeAvailable(.camera) {
                Image(systemName: "camera").imageScale(.large).foregroundColor(.accentColor).onTapGesture{
                    self.imagePickerSourceType = .camera
                    self.showImagePicker = true
                }
            }
        }
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(sourceType: imagePickerSourceType) { image in
                if image != nil {
                    DispatchQueue.main.async {
                        self.document.backgroundURL = image!.storeInFilesystem()
                    }
                }
                self.showImagePicker = false
            }
        }
    }
    
    @State private var explainBackgorundPaste = false
    @State private var confirmBackgorundPaste = false
    
    var isLoading: Bool {
        document.backgroundURL != nil && document.backgroundImage == nil
    }
    
    //PanOffset
    @GestureState private var gesturePanOffset: CGSize = .zero
    
    private var panOffset: CGSize {
        (document.steadyStatePanOffset + gesturePanOffset) * zoomScale
    }
    
    private func panGesture() -> some Gesture {
        DragGesture()
            .updating($gesturePanOffset) { latestDragGestureValue, gesturePanOffset, transaction in
                gesturePanOffset = latestDragGestureValue.translation / self.zoomScale
            }
            .onEnded { finalDragGestureValue in
                document.steadyStatePanOffset = document.steadyStatePanOffset + (finalDragGestureValue.translation / zoomScale)
            }
    }
    
    //Zoom
    private func zoomGesture() -> some Gesture {
        MagnificationGesture()
            .updating($gestureZoomScale){ latestGestureScale, ourGestureStateInOut, transaction in
                ourGestureStateInOut = latestGestureScale
            }
            .onEnded { finalGestureScale in
                self.document.steadyStateZoomScale *= finalGestureScale
            }
    }
    
    private func doubleTapToZoom(in size: CGSize) -> some Gesture {
        TapGesture(count: 2)
            .onEnded {
                withAnimation(.easeInOut(duration: 1)) {
                    self.zoomToFit(self.document.backgroundImage , in: size)
                }
            }
    }
    
    
    @GestureState private var gestureZoomScale: CGFloat = 1.0
    
    private var zoomScale: CGFloat {
        document.steadyStateZoomScale * gestureZoomScale
    }
    
    private func zoomToFit (_ image: UIImage?, in size:CGSize) {
        if let image = image, image.size.width > 0 , image.size.height > 0, size.width > 0, size.height > 0 {
            let hZoom = size.width / image.size.width
            let vZoom = size.height / image.size.height
            document.steadyStatePanOffset = CGSize.zero
            document.steadyStateZoomScale = min(hZoom, vZoom)
        }
    }
    
    /* replaced with - animatableWithSize
    private func font(for emoji: EmojiArt.Emoji) -> Font {
        Font.system(size: emoji.fontSize * zoomScale)
    }
 */
    
    private func position (for emoji: EmojiArt.Emoji, in size: CGSize) -> CGPoint {
        var location = emoji.location
        location = CGPoint(x: location.x * zoomScale, y: location.y * zoomScale)
        location = CGPoint(x: location.x + size.width/2, y: location.y + size.height/2)
        location = CGPoint (x: location.x + self.panOffset.width, y: location.y + self.panOffset.height)
        return location
    }
    
    private func drop(providers: [NSItemProvider], at location: CGPoint ) -> Bool {
        print("try drop")
        var found = providers.loadFirstObject(ofType: URL.self) { url in
            print("dropped \(url)")
            self.document.backgroundURL = url
        }
        
        if !found {
            found = providers.loadFirstObject(ofType: String.self) { string in
                document.addEmoji(string, at: location, size: self.defaultEmojiSize)
            }
        }
        return found
    }
    
    private let defaultEmojiSize: CGFloat = 40
}



/*
extension String: Identifiable {
    public var id: String {return self}
}
 */
