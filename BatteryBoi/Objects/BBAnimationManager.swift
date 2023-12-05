//
//  BBAnimationManager.swift
//  BatteryBoi
//
//  Created by Joe Barbour on 9/8/23.
//

import Foundation
import SwiftUI

struct AnimationModifier: ViewModifier {
    @Binding var keyframes: AnimationObject
    @Binding var state:AnimationState
    
    @State private var width:CGFloat? = nil
    @State private var height:CGFloat? = nil
    @State private var opacity:CGFloat = 1.0
    @State private var blur:CGFloat = 0.0
    @State private var radius:CGFloat = 0.0
    @State private var scale:CGFloat = 1.0
    @State private var rotate:CGFloat = 0.0

    @State private var paddingTop:CGFloat = 0.0
    @State private var paddingLeading:CGFloat = 0.0
    @State private var paddingTrailing:CGFloat = 0.0
    @State private var paddingBottom:CGFloat = 0.0

    func body(content: Content) -> some View {
        content
            .frame(width: self.width, height: self.height)
            .opacity(self.opacity)
            .cornerRadius(self.radius)
            .blur(radius:self.blur)
            .scaleEffect(self.scale)
            .rotationEffect(.degrees(self.rotate))
            .padding(.top, self.paddingTop)
            .padding(.leading, self.paddingLeading)
            .padding(.trailing, self.paddingTrailing)
            .padding(.bottom, self.paddingBottom)
            .onAppear {
                if self.keyframes.autoplay == true {
                    self.state = .playing
                    self.animate(index: 0)
                    
                }

            }
            .onChange(of: self.keyframes, perform: { newValue in
                if self.keyframes.autoplay == true {
                    self.state = .playing
                    self.animate(index: 0)

                }
                
            })
        
    }
    
    func animate(index: Int = 0) {
        if index < self.keyframes.keyframes.count {
            for _ in 0..<self.keyframes.keyframes.count {
                let current = keyframes.keyframes[index]

                if current.easing == .linear {
                    withAnimation(Animation.linear(duration: current.duration)) {
                        self.width = current.width
                        self.height = current.height
                        self.opacity = current.opacity
                        self.blur = current.blur
                        self.radius = current.radius
                        self.scale = current.scale
                        self.rotate = current.rotate
                        
                        self.paddingTop = current.padding.top
                        self.paddingLeading = current.padding.leading
                        self.paddingTrailing = current.padding.trailing
                        self.paddingBottom = current.padding.bottom

                    }

                }
                else if current.easing == .easein {
                    withAnimation(Animation.easeIn(duration: current.duration)) {
                        self.width = current.width
                        self.height = current.height
                        self.opacity = current.opacity
                        self.blur = current.blur
                        self.radius = current.radius
                        self.scale = current.scale
                        self.rotate = current.rotate

                        self.paddingTop = current.padding.top
                        self.paddingLeading = current.padding.leading
                        self.paddingTrailing = current.padding.trailing
                        self.paddingBottom = current.padding.bottom
                        
                    }

                }
                else if current.easing == .easeout {
                    withAnimation(Animation.easeOut(duration: current.duration)) {
                        self.width = current.width
                        self.height = current.height
                        self.opacity = current.opacity
                        self.blur = current.blur
                        self.radius = current.radius
                        self.scale = current.scale
                        self.rotate = current.rotate

                        self.paddingTop = current.padding.top
                        self.paddingLeading = current.padding.leading
                        self.paddingTrailing = current.padding.trailing
                        self.paddingBottom = current.padding.bottom
                        
                    }

                }
                else if current.easing == .bounce {
                    withAnimation(.interactiveSpring(response: 0.4, dampingFraction: 0.7, blendDuration: current.duration)) {
                        self.width = current.width
                        self.height = current.height
                        self.opacity = current.opacity
                        self.blur = current.blur
                        self.radius = current.radius
                        self.scale = current.scale
                        self.rotate = current.rotate

                        self.paddingTop = current.padding.top
                        self.paddingLeading = current.padding.leading
                        self.paddingTrailing = current.padding.trailing
                        self.paddingBottom = current.padding.bottom
                        
                    }

                }

                DispatchQueue.main.asyncAfter(deadline: .now() + current.duration + current.delay) {
                    self.animate(index: index + 1)

                }
                
            }
            
        }
        else {
            self.state = .complete

        }
        
    }
    
}

extension View {
    func timeline(_ animation: Binding<AnimationObject>, state:Binding<AnimationState>) -> some View {
        self.modifier(AnimationModifier(keyframes: animation, state: state))
        
    }
    
}
