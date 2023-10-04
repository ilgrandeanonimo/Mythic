//
//  GameInstall.swift
//  Mythic
//
//  Created by Esiayo Alegbe on 29/9/2023.
//

import SwiftUI

extension GameListView {
    struct InstallView: View {
        @Binding var isPresented: Bool
        @Binding var game: String
        @Binding var isGameListRefreshCalled: Bool
        
        var body: some View {
            VStack {
                Text(game)
                    .font(.title)
                
                Spacer()
                
                HStack {
                    Button(action: {
                        isPresented = false
                    }) {
                        Text("Close")
                    }
                }
            }
            .padding()
            .fixedSize()
        }
    }
}


#Preview {
    LibraryView()
}
