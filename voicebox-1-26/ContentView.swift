 //
//  ContentView.swift
//  voicebox-1-26
//
//  Created by Matthew Fang on 1/26/26.
//

import SwiftUI

struct ContentView: View {
    
    @State var compassService: CompassService = CompassService()
    
    @State private var counter = 0
    
    var body: some View {
        VStack {
            Text(String(compassService.heading))
            Button {
                compassService.isStarted ? compassService.stop() : compassService.start()
            } label: {
                Text("start compass!~")
            }
            
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Hello, world!")
            Button {
                print("hello world")
                counter += 1
            } label: {
                Text("press for haptics!")
            }
            .sensoryFeedback(.impact(weight: .heavy, intensity: 1), trigger: counter)
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
