//
//  EmojiArtDocumentView.swift
//  EmojiArt
//
//  Created by CS193p Instructor on 4/27/20.
//  Copyright © 2020 Stanford University. All rights reserved.
//

import SwiftUI

struct EmojiArtDocumentView: View {
    @ObservedObject var document: EmojiArtDocument
    
    var body: some View {
        VStack {
            
            // Emoji Palette
            ScrollView(.horizontal) {
                HStack {
                    ForEach(EmojiArtDocument.palette.map { String($0) }, id: \.self) { emoji in
                        Text(emoji)
                            .font(Font.system(size: UX.Sizes.defaultEmoji))
                            .onDrag { NSItemProvider(object: emoji as NSString) }
                    }
                }
            }
            .padding(.horizontal)
            
            // Canvas – Start
            GeometryReader { geometry in
                ZStack {
                    
                    // Image
                    Color.white.overlay(
                        OptionalImage(uiImage: self.document.backgroundImage)
                            .scaleEffect(self.wholeArtZoomScale)
                            .offset(self.panOffset)
                    )
                    .gesture(self.doubleTapToZoom(in: geometry.size))
                    .gesture(self.singleTapToDeselectAllEmojis())
                    
                    // Emojis over image
                    ForEach(self.document.emojis) { emoji in
                        EmojiView(text: emoji.text,
                                  size: emoji.fontSize * self.wholeArtZoomScale,
                                  isSelected: isEmojiSelected(emoji))
                            .position(self.getPosition(for: emoji, in: geometry.size))
                            .gesture(dragToMoveEmoji(emoji, in: geometry.size))
                            .gesture(singleTapToSelectDeselectEmoji(emoji))

                    }
                    
                }
                .clipped()
                .gesture(self.panGesture())
                .gesture(self.zoomGesture())
                .edgesIgnoringSafeArea([.horizontal, .bottom])
                .onDrop(of: ["public.image","public.text"], isTargeted: nil) { providers, location in
                    // SwiftUI bug (as of 13.4)? the location is supposed to be in our coordinate system
                    // however, the y coordinate appears to be in the global coordinate system
                    var location = CGPoint(x: location.x, y: geometry.convert(location, from: .global).y)
                    location = CGPoint(x: location.x - geometry.size.width/2, y: location.y - geometry.size.height/2)
                    location = CGPoint(x: location.x - self.panOffset.width, y: location.y - self.panOffset.height)
                    location = CGPoint(x: location.x / self.wholeArtZoomScale, y: location.y / self.wholeArtZoomScale)
                    return self.drop(providers: providers, at: location)
                }
            }
            // Canvas – End
        }
    }
    
    
    // MARK: - Selection
    
    @State private var selectedEmojis: Set<EmojiArt.Emoji> = Set()
    
    func isEmojiSelected(_ emoji: EmojiArt.Emoji) -> Bool {
        return selectedEmojis.contains(emoji)
    }
    
    func toggleSelection(emoji: EmojiArt.Emoji) {
        if selectedEmojis.contains(emoji) {
            selectedEmojis.remove(emoji)
        } else {
            selectedEmojis.insert(emoji)
        }
    }
    
    private func singleTapToSelectDeselectEmoji(_ emoji: EmojiArt.Emoji) -> some Gesture {
        TapGesture()
            .onEnded{
                toggleSelection(emoji: emoji)
            }
    }
    
    private func singleTapToDeselectAllEmojis() -> some Gesture {
        TapGesture()
            .onEnded{
                selectedEmojis.removeAll()
            }
    }
    
    // MARK: - Move emojis
    
    @GestureState private var previousTranslationOfDraggingEmoji: CGSize = .zero
        
    private func dragToMoveEmoji(_ emoji: EmojiArt.Emoji, in size: CGSize) -> some Gesture {
        DragGesture()
            .updating($previousTranslationOfDraggingEmoji){ dragValue, previousTranslationOfDraggingEmoji, transaction in
                //
                // Calculate offset for current episode of the dragging.
                let newOffset = CGSize(width:  dragValue.translation.width - previousTranslationOfDraggingEmoji.width,
                                       height: dragValue.translation.height - previousTranslationOfDraggingEmoji.height)
                //
                // Move emoji
                if selectedEmojis.contains(emoji) {
                    for selectedEmoji in selectedEmojis {
                        movePosition(for: selectedEmoji, in: size, by: newOffset)
                    }
                } else {
                    movePosition(for: emoji, in: size, by: newOffset)
                }
                //
                // Save current translation value for calculation in the next episode.
                previousTranslationOfDraggingEmoji = dragValue.translation
            }
    }
    
    // MARK: - Postion of emoji
    
    
    private func getPosition(for emoji: EmojiArt.Emoji, in size: CGSize) -> CGPoint {
        var location = emoji.location
        location = CGPoint(x: location.x * wholeArtZoomScale, y: location.y * wholeArtZoomScale)
        location = CGPoint(x: location.x + size.width/2, y: location.y + size.height/2)
        location = CGPoint(x: location.x + panOffset.width, y: location.y + panOffset.height)
        return location
    }
    
    private func movePosition(for emoji: EmojiArt.Emoji, in size: CGSize, by offset: CGSize){
        let documentOffset = CGSize(width: offset.width / wholeArtZoomScale, height: offset.height / wholeArtZoomScale)
        document.moveEmoji(emoji, by: documentOffset)
    }
    

    // MARK: - Zoom
    
    @State private var steadyStateZoomScale: CGFloat = 1.0
    @GestureState private var gestureZoomScale: CGFloat = 1.0
    
    private var wholeArtZoomScale: CGFloat {
        if selectedEmojis.isEmpty {
            return steadyStateZoomScale * gestureZoomScale
        } else {
            // If there is a selected emoji,
            // then zoomGesture change only them
            // and doesn't impact on other
            // art component.
            return steadyStateZoomScale
        }
    }
    
    private func zoomGesture() -> some Gesture {
        MagnificationGesture()
            .updating($gestureZoomScale) { latestGestureScale, gestureZoomScale, transaction in
                
                if selectedEmojis.isEmpty {
                    // Inderect affect whole document via gestureZoomScale.
                    gestureZoomScale = latestGestureScale
                } else {
                    // Direct affect only selected emoji.
                    let changeScale = latestGestureScale / gestureZoomScale
                    for emoji in selectedEmojis {
                        document.scaleEmoji(emoji, by: changeScale)
                    }
                    // Save latest scale for the next iteration of zooming.
                    gestureZoomScale = latestGestureScale
                }
                
            }
            .onEnded { finalGestureScale in
                if selectedEmojis.isEmpty {
                    self.steadyStateZoomScale *= finalGestureScale
                }
            }
    }
    
    // MARK: - Pan
    
    @State private var steadyStatePanOffset: CGSize = .zero
    @GestureState private var gesturePanOffset: CGSize = .zero
    
    private var panOffset: CGSize {
        (steadyStatePanOffset + gesturePanOffset) * wholeArtZoomScale
    }
    
    private func panGesture() -> some Gesture {
        DragGesture()
            .updating($gesturePanOffset) { latestDragGestureValue, gesturePanOffset, transaction in
                gesturePanOffset = latestDragGestureValue.translation / self.wholeArtZoomScale
            }
            .onEnded { finalDragGestureValue in
                self.steadyStatePanOffset = self.steadyStatePanOffset + (finalDragGestureValue.translation / self.wholeArtZoomScale)
            }
    }
    
    
    private func doubleTapToZoom(in size: CGSize) -> some Gesture {
        TapGesture(count: 2)
            .onEnded {
                withAnimation {
                    self.zoomToFit(self.document.backgroundImage, in: size)
                }
            }
    }
    
    private func zoomToFit(_ image: UIImage?, in size: CGSize) {
        if let image = image, image.size.width > 0, image.size.height > 0 {
            let hZoom = size.width / image.size.width
            let vZoom = size.height / image.size.height
            self.steadyStatePanOffset = .zero
            self.steadyStateZoomScale = min(hZoom, vZoom)
        }
    }
    
    
    private func drop(providers: [NSItemProvider], at location: CGPoint) -> Bool {
        var found = providers.loadFirstObject(ofType: URL.self) { url in
            self.document.setBackgroundURL(url)
        }
        if !found {
            found = providers.loadObjects(ofType: String.self) { string in
                self.document.addEmoji(string, at: location, size: UX.Sizes.defaultEmoji)
            }
        }
        return found
    }
    
}
