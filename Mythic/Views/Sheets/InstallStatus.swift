//
//  InstallStatus.swift
//  Mythic
//
//  Created by Esiayo Alegbe on 3/12/2023.
//

// MARK: - Copyright
// Copyright © 2023 blackxfiied, Jecta

// This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program. If not, see http://www.gnu.org/licenses/.

// You can fold these comments by pressing [⌃ ⇧ ⌘ ◀︎], unfold with [⌃ ⇧ ⌘ ▶︎]

import SwiftUI
import Foundation
import Charts // TODO: TODO

// MARK: - InstallStatusView Struct
/// A view displaying the installation status of a game.

struct InstallStatusView: View {
    // MARK: - Binding Variables
    @Binding var isPresented: Bool
    @ObservedObject private var variables: VariableManager = .shared
    
    // MARK: - Body
    var body: some View {
        VStack {
            if let installingGame: Game = variables.getVariable("installing") {
                Text("Installing \(installingGame.title)...")
                    .font(.title)
            } else {
                Text("Installing [unknown]...")
                    .font(.title)
                Text("You probably left this open while installing. Your install has finished.") // FIXME: turn isPresented off when install finished, so this wont happen
                    .foregroundStyle(.placeholder)
            }
            
            if let installStatus: [String: [String: Any]] = VariableManager.shared.getVariable("installStatus") { // TODO: create MiB to MB function
                GroupBox {
                    Text("Progress: \(Int((installStatus["progress"])?["percentage"] as? Double ?? 0))% (\((installStatus["progress"])?["downloaded"] as? Int ?? 0)/\((installStatus["progress"])?["total"] as? Int ?? 0) objects)")
                    Text("Downloaded \((installStatus["download"])?["downloaded"] as? Double ?? 0) MiB, Written \((installStatus["download"])?["written"] as? Double ?? 0) MiB.") // TODO: if above 1 GiB, show up as GiB instead of MiB
                    Text("Elapsed: \("\((installStatus["progress"])?["runtime"] ?? "[Wnknown]")"), ETA: \("\((installStatus["progress"])?["eta"] ?? "[Wnknown]")")")
                }
                .fixedSize()
            }
            
            // MARK: Close Button
            Button("Close") { isPresented = false }
                .buttonStyle(.borderedProminent)
                .foregroundStyle(.accent)
        }
        .padding()
    }
}

// MARK: - Preview
#Preview {
    InstallStatusView(isPresented: .constant(true))
}
