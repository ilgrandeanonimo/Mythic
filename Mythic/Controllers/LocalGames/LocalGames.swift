//
//  LocalGames.swift
//  Mythic
//
//  Created by Esiayo Alegbe on 4/10/2023.
//

// MARK: - Copyright
// Copyright © 2023 blackxfiied, Jecta

// This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program. If not, see http://www.gnu.org/licenses/.

// You can fold these comments by pressing [⌃ ⇧ ⌘ ◀︎], unfold with [⌃ ⇧ ⌘ ▶︎]

import Foundation
import OSLog

class LocalGames {
    public static let log = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "localGames")
    
    static var library: [Mythic.Game]? { // FIXME: is there a way to init it at the top
        get {
            if let library = defaults.object(forKey: "localGamesLibrary") as? Data {
                do {
                    return try PropertyListDecoder().decode(Array.self, from: library)
                } catch {
                    Logger.app.error("Unable to retrieve local game library: \(error.localizedDescription)")
                    return nil
                }
            } else {
                Logger.app.warning("Local games library does not exist, returning blank array")
                return Array()
            }
        }
        set {
            do {
                defaults.set(
                    try PropertyListEncoder().encode(newValue),
                    forKey: "localGamesLibrary"
                )
            } catch {
                Logger.app.error("Unable to set local game library: \(error.localizedDescription)")
            }
        }
    }
    
    static func launch(game: Mythic.Game, bottle: URL) async throws { // TODO: be able to tell when game is runnning
        guard let library = library,
                  library.contains(game) else { // FIXME: FIXME
                      log.error("Unable to launch local game, not installed or missing") // TODO: add alert in unified alert system
                      throw GameDoesNotExistError(game)
                  }
        
        guard Libraries.isInstalled() else { throw Libraries.NotInstalledError() }
        guard Wine.prefixExists(at: bottle) else { throw Wine.PrefixDoesNotExistError() }
        
        VariableManager.shared.setVariable("launching_\(game.title)", value: true)
        defaults.set(try PropertyListEncoder().encode(game), forKey: "recentlyPlayed")
        
        // WINEPREFIX:
        
        _ = try await Wine.command(
            args: [
                
            ],
            identifier: "launch_\(game.title)",
            prefix: Wine.defaultBottle // TODO: whichever prefix is set for it or as default
        )
        
        VariableManager.shared.setVariable("launching_\(game.title)", value: false)
    }
}