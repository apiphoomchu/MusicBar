//
//  StatusBar.swift
//  MusicBar
//
//  Created by Wongkraiwich Chuenchomphu on 11/16/22.
//

import Foundation
import AppKit
import LaunchAtLogin

class StatusBar: NSObject {
    let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    var nowPlaying = GetNowPlaying().getNowPlaying()
    private let space = "     "
    
    private var lastTitle = ""
    private var lastArtist = ""
    private var lastImage = NSImage()
    
    override init() {
        super.init()
        Timer.scheduledTimer(timeInterval: 0.75, target: self, selector: #selector(setMedia), userInfo: nil, repeats: true)
        setupMenu()
    }
    
    @objc private func setMedia() {
        
        var songTitle: String?
        var songArtist: String?
        var image: NSImage?
        
        func checkAvailable() -> NSImage? {
            if #available(macOS 11.0, *) {
                return NSImage(systemSymbolName: "music.note", accessibilityDescription: "loading")
            } else {
                let image = NSImage(named: NSImage.Name("music.note"))
                return image?.resizedCopy(w: 15, h: 15)
            }
        }
        
        if let getNowPlaying = nowPlaying {
            getNowPlaying(DispatchQueue.main, {
                (information) in
                if let infoTitle = information["kMRMediaRemoteNowPlayingInfoTitle"] as? String {
                    songTitle = infoTitle
                }
                if let infoArtist = information["kMRMediaRemoteNowPlayingInfoArtist"] as? String {
                    songArtist = infoArtist
                }
                if let infoImageData = information["kMRMediaRemoteNowPlayingInfoArtworkData"] as? Data {
                    image = NSImage(data: infoImageData)
                }
            })
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            if(songTitle != nil) {
                if(songTitle != self.lastTitle || songArtist != self.lastArtist || image != self.lastImage) {
                    self.statusItem.length = NSStatusItem.variableLength
                    if let button = self.statusItem.button {
                        let resized = (image != nil) ? image?.resizedCopy(w: 19, h: 19) : checkAvailable()
                        let songTitleCheck = self.getSongTitle(songTitle)
                        let dashCheck = (songTitle != nil && songArtist != nil) ? " - " : ""
                        let songArtistCheck = self.getArtist(songArtist)
                        
                        let titleCombined = " " + songTitleCheck + dashCheck + songArtistCheck
                        
                        if #available(macOS 11.0, *) {
                            button.title = titleCombined
                        }
                        else {
                            let attributes = [NSAttributedString.Key.foregroundColor: NSColor.white]
                            let attributedText = NSAttributedString(string: titleCombined, attributes: attributes)
                            button.attributedTitle = attributedText
                        }
                        
                        button.image = resized
                        button.imagePosition = .imageLeft
                    }
                }
            } else {
                self.statusItem.length = 18
                if let button = self.statusItem.button {
                    button.image = checkAvailable()
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(2)) {}
            }
        }
    }
    
    func getSongTitle(_ songTitle: String?) -> String {
        var songT = songTitle
        let cutPhrase = ["(feat.", "Feat.", "(produced by", "(with"]
        songT?.cutFeat(separator: cutPhrase)
        return songT ?? "Music Not Playing"
    }
    
    func getArtist(_ songArtist: String?) -> String {
        var artistCut = songArtist
        let cutPhrase = [",", "&", "×"]
        artistCut?.cutFeat(separator: cutPhrase)
        return artistCut ?? ""
    }
    
    private func setupMenu() {
        let menu = NSMenu()
        menu.addItem(autoLaunchMenu())
        menu.addItem(NSMenuItem(title: "\(space)Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        
        statusItem.menu = menu
    }
    
    @objc func checkAction() {
        LaunchAtLogin.isEnabled = !LaunchAtLogin.isEnabled
        setupMenu()
    }
    
    func autoLaunchMenu() -> NSMenuItem {
        let enabled = LaunchAtLogin.isEnabled ? "􀆅 " : space
        let menuItem =  NSMenuItem(title: "\(enabled)Launch At Login", action: #selector(checkAction), keyEquivalent: "")
        menuItem.target = self
        return menuItem
    }
}
