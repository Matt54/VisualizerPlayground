//
//  CircleCursorView.swift
//  VisualizerPlayground
//
//  Created by Matt Pfeiffer on 1/13/21.
//

import SwiftUI

struct CircleCursorView: View {
    //@State private var animationAmount: CGFloat = 1
    @State var cursorColor: Color = Color.yellow
    
    var body: some View {
        GeometryReader{ geo in
            ZStack{
                Circle()
                    .fill(cursorColor)
                    .opacity(0.3)
                    .shadow(color: cursorColor, radius: geo.size.width * 0.01)
                Circle()
                    .fill(cursorColor)
                    .opacity(0.6)
                    .padding(geo.size.width * 0.05)
                Circle()
                    .fill(cursorColor)
                    .shadow(color: cursorColor, radius: geo.size.width * 0.1)
                    .padding(geo.size.width * 0.1)
                    /*.overlay(
                        Circle()
                            .stroke(cursorColor, lineWidth: geo.size.width * 0.01)
                            .scaleEffect(animationAmount)
                            .opacity(Double(2 - animationAmount))
                            .animation(
                                Animation.easeInOut(duration: 1)
                                    .repeatForever(autoreverses: false)
                            )
                    )
                    .overlay(
                        Circle()
                            .stroke(cursorColor, lineWidth: geo.size.width * 0.02)
                            .shadow(color: cursorColor, radius: geo.size.width * 0.05)
                            .scaleEffect(animationAmount * 0.8)
                            .opacity(Double(2 - animationAmount))
                            .animation(
                                Animation.easeInOut(duration: 1)
                                    .repeatForever(autoreverses: false)
                            )
                    )*/
                    /*.overlay(
                        Circle()
                            .stroke(cursorColor, lineWidth: geo.size.width * 0.005)
                            .shadow(color: cursorColor, radius: geo.size.width * 0.01)
                            .scaleEffect(animationAmount * 1.2)
                            .opacity(Double(2 - animationAmount))
                            .animation(
                                Animation.easeInOut(duration: 1)
                                    .repeatForever(autoreverses: false)
                            )
                    )*/
                /*.onAppear{
                    animationAmount = 2
                }*/
            }
        }
    }
}

struct CircleCursorView_Previews: PreviewProvider {
    static var previews: some View {
        CircleCursorView()
    }
}
