//
//  BBAnimationModel.swift
//  BatteryBoi
//
//  Created by Joe Barbour on 12/5/23.
//

import Foundation

enum AnimationState {
    case waiting
    case playing
    case complete
    case paused
    
}

enum AnimationControls {
    case play
    case reset
    
}

enum AnimationEasingType {
    case linear
    case easein
    case easeout
    case bounce
    
}

struct AnimationPadding:Equatable {
    var top:CGFloat = 0.0
    var leading:CGFloat = 0.0
    var trailing:CGFloat = 0.0
    var bottom:CGFloat = 0.0
    
}

struct AnimationKeyframeObject:Equatable {
    var width:CGFloat?
    var height:CGFloat?
    var opacity:CGFloat = 1.0
    var blur:CGFloat = 0.0
    var radius:CGFloat = 0.0
    var scale:CGFloat = 1.0
    var rotate:CGFloat = 0.0
    var duration:CGFloat
    var delay:CGFloat
    var padding:AnimationPadding
    var easing:AnimationEasingType
    
    init(_ duration: CGFloat, delay: CGFloat = 0.0, easing: AnimationEasingType = .linear, width: CGFloat? = nil, height: CGFloat? = nil, opacity: CGFloat = 1.0, blur: CGFloat = 0.0, radius: CGFloat = 0.0, scale: CGFloat = 1.0, rotate: CGFloat = 0.0, padding:AnimationPadding? = nil) {
        self.width = width
        self.height = height
        self.opacity = opacity
        self.blur = blur
        self.radius = radius
        self.scale = scale
        self.rotate = rotate
        self.duration = duration
        self.delay = delay
        self.easing = easing
        self.padding = padding ?? .init()
        
    }

}

struct AnimationObject:Equatable {
    static func == (lhs: AnimationObject, rhs: AnimationObject) -> Bool {
        return lhs.id == rhs.id
        
    }
    
    var loop:Int
    var keyframes:[AnimationKeyframeObject]
    var id:String?
    var autoplay:Bool

    init(_ keyframes:[AnimationKeyframeObject], loop:Int = 1, easing:AnimationEasingType = .linear, id:String? = nil, autoplay:Bool = true) {
        self.loop = loop
        self.keyframes = keyframes
        self.id = id ?? UUID().uuidString
        self.autoplay = autoplay
        
    }
    
}
