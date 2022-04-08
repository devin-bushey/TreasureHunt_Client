//
//  ContentView.swift
//  Client
//
//  Created by Michael on 2022-02-24.
//

import SwiftUI

struct ContentView: View {
    @State var message = ""
    @StateObject var networkSupport = NetworkSupport(browse: true)
    @State var outgoingMessage = ""
    @State var grid : [[Tile]] = [[Tile]]()
    @State var score = 0
    
    var numColumns = 5
    var numRows = 5
    var numTreasures = 5
    
    var body: some View {
        VStack {
            if !networkSupport.connected {
                TextField("Message", text: $message)
                    .multilineTextAlignment(.center)
                
                List ($networkSupport.peers, id: \.self) {
                    $peer in
                    Button(peer.displayName) {
                        do {
                            try networkSupport.contactPeer(peerID: peer, request: Request(details: message))
                            
                        }
                        catch let error {
                            print(error)
                        }
                    }
                }
            }
            else {
                

                TextField("Message", text: $outgoingMessage)
                    .multilineTextAlignment(.center)
                    .padding()
                
                Button("Send") {
                    networkSupport.send(message: outgoingMessage)
                    outgoingMessage = ""
                }
                .padding()
                Text(networkSupport.incomingMessage)
                    .padding()
                BoardView(network: networkSupport)
   
            }
        }
        .padding()
    }



struct BoardView : View {
    
    //@Binding var message : String
    @State var network : NetworkSupport
    @State var score = 0
    @StateObject var board = Board()
    @State var foundTreasure = false
    @State var serverResponse = ""
    @State var turn = false
    
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        VStack {
            Text("Score: " + String(score))
            LazyVGrid(columns: columns, spacing: 10) {
                ForEach($board.tiles, id: \.self) { $tiles in
                    ForEach($tiles, id: \.self) { $tile in
                        Image(systemName: tile.image).onTapGesture {
                            network.send(message: tile.location)
                            let response = evaluateMessage(message: serverResponse)
                            if (response) {
                                tile.image = "face.smiling"
                                score += 1
                            }
                            else {
                                tile.image = "x.cirle"
                            }
                        }
                    }
                }
            }.allowsHitTesting(turn)
        }.onChange(of: network.incomingMessage) { newValue in
            // Handle the incoming message here.  This could be a request for the board state, or could be a move (row col)
            // Note that if the same incomingMessage is sent twice, this call will not trigger; it is only called on change
            turn = true
            serverResponse = newValue
        }
    }
    
    func evaluateMessage(message: String) -> Bool {
        turn = false
        if (message.uppercased().starts(with: "F")) {
            return true
        }
        else {
            return false
        }
    }
}

struct TileRow : View {
    let numTiles = 5
    var tiles : [Tile]
    
    var body: some View {
        
        HStack {
            
        }
        
    }
}
    
    class Board: ObservableObject {
        let boardSize = 10
        @Published var tiles:[[Tile]]
        init() {
            tiles = [[Tile]]()
            for x in 0..<boardSize {
                var tileRow = [Tile]()
                for y in 0..<boardSize {
                    tileRow.append(Tile(x: x, y: y))
                }
                tiles.append(tileRow)
            }
        }
    }
    
    struct Tile: Hashable, Identifiable {
        var id = UUID()
        var x : Int
        var y : Int
        var image : String
        var location : String
        
        init(x: Int, y: Int) {
            self.x = x
            self.y = y
            self.image = "circle.fill"
            self.location = String(self.x) + "," +  String(self.y)
        }
    }
}
