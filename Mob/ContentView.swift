//
//  ContentView.swift
//  Mob
//
//  Created by Aleksey Nizikov on 02.03.2024.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        Circle()
            .fill(.orange)
            .padding(EdgeInsets())
            .overlay(
                Image(systemName: "figure.run"))
            .font(.system(size: 144))
            .foregroundColor(.white)
        
        
        
            
            
    }
}

#Preview {
    ContentView()
}
