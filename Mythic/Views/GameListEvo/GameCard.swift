//
//  GameListEvo.swift
//  Mythic
//
//  Created by Esiayo Alegbe on 5/3/2024.
//

import SwiftUI
import Shimmer
import SwiftyJSON
import Glur
import OSLog
import Combine

struct GameCard: View {
    @Binding var game: Game
    
    @EnvironmentObject var networkMonitor: NetworkMonitor
    @ObservedObject private var variables: VariableManager = .shared
    @ObservedObject private var gameModification: GameModification = .shared
    
    @AppStorage("minimiseOnGameLaunch") private var minimizeOnGameLaunch: Bool = false
    
    @State private var isGameSettingsSheetPresented: Bool = false
    @State private var isUninstallSheetPresented: Bool = false
    @State private var isInstallSheetPresented: Bool = false
    @State private var isStopGameModificationAlertPresented: Bool = false
    
    @State private var isLaunchErrorAlertPresented: Bool = false
    @State private var launchError: Error?
    
    @State private var hoveringOverButton: Bool = false
    @State private var animateFavouriteIcon: Bool = false
    
    var body: some View {
        RoundedRectangle(cornerRadius: 20)
            .fill(.background)
            .aspectRatio(3/4, contentMode: .fit)
            .overlay { // MARK: Image
                AsyncImage(
                    url: game.imageURL
                ) { phase in
                    switch phase {
                    case .empty:
                        RoundedRectangle(cornerRadius: 20)
                            .fill(.windowBackground)
                            .shimmering(
                                animation: .easeInOut(duration: 1)
                                    .repeatForever(autoreverses: false),
                                bandSize: 1
                            )
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(3/4, contentMode: .fill)
                            .clipShape(.rect(cornerRadius: 20))
                            .blur(radius: 20.0)
                        
                        image
                            .resizable()
                            .aspectRatio(3/4, contentMode: .fill)
                            .glur(radius: 20, offset: 0.5, interpolation: 0.7)
                            .clipShape(.rect(cornerRadius: 20))
                            .modifier(FadeInModifier())
                            .grayscale(0) // if game installed and not found
                    case .failure:
                        // fallthrough
                        RoundedRectangle(cornerRadius: 20)
                            .fill(.windowBackground)
                    @unknown default:
                        RoundedRectangle(cornerRadius: 20)
                            .fill(.windowBackground)
                    }
                }
                .overlay(alignment: .bottom) {
                    VStack {
                        // MARK: Game Title Stack
                        HStack {
                            Text(game.title)
                                .font(.bold(.title3)())
                                .padding(.leading)
                            
                            Text(game.type == .epic ? "Epic" : "Local")
                                .padding(.horizontal, 5)
                                .font(.caption)
                                .overlay( // based off .buttonStyle(.accessoryBarAction)
                                    RoundedRectangle(cornerRadius: 4)
                                        .stroke(.tertiary)
                                )
                            
                            Spacer()
                        }
                        
                        // MARK: Button Stack
                        HStack {
                            if gameModification.game == game { // MARK: View if game is being installed
                                HStack {
                                    Button {
                                        // isInstallStatusViewPresented = true
                                    } label: {
                                        if let percentage = gameModification.status?["progress"]?["percentage"] as? Double {
                                            ProgressView(value: percentage, total: 100)
                                                .progressViewStyle(.linear)
                                                .help("\(Int(percentage))% complete")
                                        } else {
                                            ProgressView()
                                                .progressViewStyle(.linear)
                                                .help("Initializing...")
                                        }
                                    }
                                    .buttonStyle(.plain)
                                    
                                    Button {
                                        isStopGameModificationAlertPresented = true
                                    } label: {
                                        Image(systemName: "xmark")
                                            .padding(5)
                                            .foregroundStyle(hoveringOverButton ? .red : .primary)
                                    }
                                    .clipShape(.circle)
                                    .help("Stop installing \"\(game.title)\"")
                                    .onHover { hovering in
                                        withAnimation(.easeInOut(duration: 0.1)) { hoveringOverButton = hovering }
                                    }
                                    .alert(isPresented: $isStopGameModificationAlertPresented) {
                                        stopGameModificationAlert(
                                            isPresented: $isStopGameModificationAlertPresented,
                                            game: game
                                        )
                                    }
                                }
                                .padding([.leading, .trailing])
                            } else if ((try? Legendary.getInstalledGames()) ?? .init()).contains(game) { // MARK: Buttons if game is installed
                                if case .windows = game.platform, !Libraries.isInstalled() {
                                    // MARK: Engine Install Button
                                    Button {
                                        _ = OnboardingEvo(fromChapter: .engineDisclaimer) // FIXME: dud
                                    } label: {
                                        Image(systemName: "arrow.down.circle.dotted")
                                            .padding(5)
                                    }
                                    .clipShape(.circle)
                                    .help("Install Mythic Engine")
                                } else if case .epic = game.type, // if verification required, FIXME: turn this block into a Legendary function
                                          let json = try? JSON(data: Data(contentsOf: URL(filePath: "\(Legendary.configLocation)/installed.json"))),
                                          let needsVerification = json[game.appName]["needs_verification"].bool, needsVerification {
                                    // MARK: Verify Button
                                    Button {
                                        Task(priority: .userInitiated) {
                                            do {
                                                try await Legendary.install(
                                                    game: game,
                                                    platform: game.platform!,
                                                    type: .repair
                                                )
                                            } catch {
                                                Logger.app.error("Error repairing \(game.title): \(error.localizedDescription)")
                                                // TODO: add repair error
                                            }
                                        }
                                    } label: {
                                        Image(systemName: "checkmark.circle.badge.questionmark")
                                            .padding(5)
                                    }
                                    .clipShape(.circle)
                                    .help("Game verification is required for \"\(game.title)\".")
                                } else {
                                    // MARK: Play Button
                                    if gameModification.launching == game {
                                        ProgressView()
                                            .controlSize(.small)
                                            .padding(5)
                                            .clipShape(.circle)
                                        
                                    } else {
                                        Button {
                                            Task(priority: .userInitiated) {
                                                do {
                                                    switch game.type {
                                                    case .epic:
                                                        try await Legendary.launch(
                                                            game: game,
                                                            bottle: Wine.allBottles![game.bottleName]!,
                                                            online: networkMonitor.isEpicAccessible
                                                        )
                                                    case .local:
                                                        try await LocalGames.launch(
                                                            game: game,
                                                            bottle: Wine.allBottles![game.bottleName]!
                                                        )
                                                    }
                                                    
                                                    if minimizeOnGameLaunch { NSApp.windows.first?.miniaturize(nil) }
                                                } catch {
                                                    launchError = error
                                                    isLaunchErrorAlertPresented = true
                                                }
                                            }
                                        } label: {
                                            Image(systemName: "play")
                                                .padding(5)
                                        }
                                        .clipShape(.circle)
                                        .help("Play \"\(game.title)\"")
                                        .alert(isPresented: $isLaunchErrorAlertPresented) {
                                            Alert(
                                                title: .init("Error launching \"\(game.title)\"."),
                                                message: .init(launchError?.localizedDescription ?? "Unknown Error.")
                                            )
                                        }
                                    }
                                }
                                
                                // MARK: Update Button
                                if case .epic = game.type, Legendary.needsUpdate(game: game) {
                                    Button {
                                        Task(priority: .userInitiated) {
                                            do {
                                                try await Legendary.install(
                                                    game: game,
                                                    platform: game.platform!,
                                                    type: .repair
                                                )
                                            } catch {
                                                Logger.app.error("Error repairing \(game.title): \(error.localizedDescription)")
                                                // TODO: add repair error
                                            }
                                        }
                                    } label: {
                                        Image(systemName: "arrow.triangle.2.circlepath")
                                            .padding(5)
                                    }
                                    .clipShape(.circle)
                                    .help("Update \"\(game.title)\"")
                                    .disabled(gameModification.game != nil)
                                }
                                
                                // MARK: Settings Button
                                Button {
                                    isGameSettingsSheetPresented = true
                                } label: {
                                    Image(systemName: "gear")
                                        .padding(5)
                                }
                                .clipShape(.circle)
                                .sheet(isPresented: $isGameSettingsSheetPresented) {
                                    GameListView.SettingsView(isPresented: $isGameSettingsSheetPresented, game: $game)
                                }
                                .help("Modify settings for \"\(game.title)\"")
                                
                                // MARK: Favourite Button
                                Button {
                                    game.isFavourited.toggle()
                                    withAnimation { animateFavouriteIcon = game.isFavourited }
                                } label: {
                                    Image(systemName: animateFavouriteIcon ? "star.fill" : "star")
                                        .padding(5)
                                }
                                .clipShape(.circle)
                                .help("Favourite \"\(game.title)\"")
                                .shadow(color: .secondary, radius: animateFavouriteIcon ? 20 : 0)
                                .symbolEffect(.bounce, value: animateFavouriteIcon)
                                .task { animateFavouriteIcon = game.isFavourited } // causes bounce on view appearance
                                
                                // MARK: Delete Button
                                Button {
                                    isUninstallSheetPresented = true
                                } label: {
                                    Image(systemName: "xmark.bin")
                                        .padding(5)
                                        .foregroundStyle(hoveringOverButton ? .red : .primary)
                                }
                                .clipShape(.circle)
                                .help("Delete \"\(game.title)\"")
                                .onHover { hovering in
                                    withAnimation(.easeInOut(duration: 0.1)) { hoveringOverButton = hovering }
                                }
                                .sheet(isPresented: $isUninstallSheetPresented) {
                                    UninstallViewEvo(game: $game, isPresented: $isUninstallSheetPresented)
                                        .padding()
                                }
                            } else {
                                Button {
                                    isInstallSheetPresented = true
                                } label: {
                                    Image(systemName: "arrow.down.to.line")
                                        .padding(5)
                                }
                                .clipShape(.circle)
                                .sheet(isPresented: $isInstallSheetPresented) {
                                    InstallViewEvo(game: $game, isPresented: $isInstallSheetPresented)
                                        .padding()
                                }
                            }
                        }
                        .padding(.bottom)
                        .disabled(false) // if game installed and not found
                    }
                }
            }
    }
}

#Preview {
    GameCard(game: .constant(placeholderGame(type: .epic)))
}
