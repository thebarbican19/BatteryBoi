//
//  BBHUDView.swift
//  BatteryBoi
//
//  Created by Joe Barbour on 9/12/23.
//

import SwiftUI
import SwiftData

enum HUDProgressLayout {
    case center
    case trailing

}

struct ConfidenceBadgeView: View {
    let confidence: Double
    let showLabel: Bool

    private var color: Color {
        switch confidence {
        case 0.0..<0.4: return Color.red
        case 0.4..<0.7: return Color.yellow
        case 0.7...1.0: return Color.green
        default: return Color.gray
        }
    }

    private var icon: String {
        switch confidence {
        case 0.0..<0.4: return "exclamationmark.circle.fill"
        case 0.4..<0.7: return "questionmark.circle.fill"
        case 0.7...1.0: return "checkmark.circle.fill"
        default: return "circle.fill"
        }
    }

    private var label: String {
        switch confidence {
        case 0.0..<0.4: return "Low"
        case 0.4..<0.7: return "Medium"
        case 0.7...1.0: return "High"
        default: return "Unknown"
        }
    }

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(.white)

            if showLabel == true {
                Text(label)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.white)
            }

            Text(String(format: "%.0f%%", confidence * 100))
                .font(.system(size: 9, weight: .semibold))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.8))
        .cornerRadius(6)
    }
}

struct HUDIcon: View {
    @EnvironmentObject var stats:StatsManager

    @Namespace private var animation

    var body: some View {
        VStack {
            ZStack {
                if stats.statsIcon.system == true {
                    Image(systemName: stats.statsIcon.name)
                        .resizable()
                        .aspectRatio(contentMode: .fit).matchedGeometryEffect(id: "icon", in: animation)

                }
                else {
                    Image(stats.statsIcon.name)
                        .resizable()
                        .aspectRatio(contentMode: .fit).matchedGeometryEffect(id: "icon", in: animation)
                        
                }
                
            }
            .frame(width: 28, height: 28)
            .foregroundColor(Color("BatterySubtitle"))
            .offset(y:1)
            
        }
        .frame(width:50, height: 50)
        .padding(.leading, 10)
        .padding(.trailing, 4)
        .background(Color.clear)
        
    }
    
}


struct HUDSummary: View {
    @EnvironmentObject var stats:StatsManager
    @EnvironmentObject var updates:UpdateManager
    @EnvironmentObject var window:WindowManager
    @EnvironmentObject var manager:AppManager

    @State private var title = ""
    @State private var subtitle = ""
    @State private var visible:Bool = false

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            HUDIcon()

            VStack(alignment: .leading, spacing: 6) {
                Text(self.title)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(2)

                ViewMarkdown($subtitle)

                if let device = manager.selected, let confidence = device.profile.aiConfidence, let category = device.profile.aiCategory {
                    ConfidenceBadgeView(confidence: confidence, showLabel: true)
                }

                if self.updates.available != nil {
                    UpdatePromptView()

                }

            }

            Spacer()

        }
        .blur(radius: self.visible ? 0.0 : 4.0)
        .opacity(self.visible ? 1.0 : 0.0)
        .onAppear() {
            self.title = self.stats.title
            self.subtitle = self.stats.subtitle
            self.visible = WindowManager.shared.state.visible

        }
        .onChange(of: self.stats.title) { newValue in
            self.title = newValue

        }
        .onChange(of: self.stats.subtitle) { newValue in
            self.subtitle = newValue

        }
        .onChange(of: window.state, perform: { newValue in
            withAnimation(Animation.easeOut(duration: 0.6).delay(self.visible == false ? 0.9 : 0.0)) {
                self.visible = newValue.visible

            }
          
        })
        
    }
    
}

struct HUDContainer: View {
    @EnvironmentObject var battery:BatteryManager
    @EnvironmentObject var manager:WindowManager
    @EnvironmentObject var window:WindowManager

    @State private var timeline:AnimationObject
    @State private var namespace:Namespace.ID
    @State private var animation:AnimationState = .waiting
    
    @Binding private var progress:HUDProgressLayout

    init(animation:Namespace.ID, progress:Binding<HUDProgressLayout>) {
        self._namespace = State(initialValue: animation)
        self._timeline = State(initialValue: .init([]))
        self._progress = progress

    }
    
    var body: some View {
        HStack(alignment: .center) {
            HUDSummary()

            if self.progress == .trailing {
                HUDProgress().matchedGeometryEffect(id: "progress", in: self.namespace)
                
            }
            
        }
        .timeline($timeline ,state: $animation)
        .padding(.leading, 20)
        .padding(.trailing, 10)
        .onAppear() {
            if let animation = window.state.container {
                self.timeline = animation
                
            }
            
        }
        .onChange(of: window.state, perform: { newValue in
            if let animation = newValue.container {
                self.timeline = animation
                
            }
            
            if newValue == .revealed {
                withAnimation(Animation.easeOut.delay(0.75)) {
                    self.progress = .trailing
                    
                }

            }
          
        })
        
    }
    
}

struct HUDMaskView: View {
    @EnvironmentObject var window:WindowManager

    @State private var timeline:AnimationObject
    @State private var animation:AnimationState = .waiting

    var keyframes = Array<AnimationKeyframeObject>()
    
    init() {
        self._timeline = State(initialValue: .init([]))
        
    }
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 0, style: .continuous)
                .timeline($timeline, state: $animation)
                .frame(width: 20, height: 20)
            
        }
        .onAppear() {
            if let animation = window.state.mask {
                self.timeline = animation
                
            }
          
        }
        .onChange(of: window.state, perform: { newValue in
            if let animation = newValue.mask {
                self.timeline = animation
                
            }
          
        })
        
    }

}

struct HUDGlow: View {
    @EnvironmentObject var window:WindowManager

    @State private var timeline:AnimationObject
    @State private var animation:AnimationState = .waiting

    init() {
        self._timeline = State(initialValue: .init([]))

    }
    
    var body: some View {
        Circle()
            .fill(Color("BatteryBackground"))
            .frame(width: 80, height: 80)
            .timeline($timeline, state: $animation)
            .onAppear() {
                if let animation = window.state.glow {
                    self.timeline = animation
                    
                }
              
            }
            .onChange(of: window.state, perform: { newValue in
                if let animation = newValue.glow {
                    self.timeline = animation
                    
                }
              
            })

    }
    
}

struct HUDProgress: View {
    @EnvironmentObject var window:WindowManager

    @State private var timeline:AnimationObject
    @State private var animation:AnimationState = .waiting

    init() {
        self._timeline = State(initialValue: .init([]))

    }
    
    var body: some View {
        RadialProgressContainer(true)
            .timeline($timeline, state: $animation)
            .onAppear() {
                if let animation = window.state.progress {
                    self.timeline = animation
                    
                }
              
            }
            .onChange(of: window.state, perform: { newValue in
                if let animation = newValue.progress {
                    self.timeline = animation
                    
                }
                
            })
        
    }
    
}

struct HUDView: View {
    @EnvironmentObject var window:WindowManager

    @State private var timeline:AnimationObject
    @State private var animation:AnimationState = .waiting
    @State private var progress:HUDProgressLayout = .center

    @Namespace private var namespace

    init() {
        self._timeline = State(initialValue: .init([]))

    }
    
    var body: some View {
        ZStack(alignment: .center) {
            VStack {
                if self.window.state == .detailed {
                    HUDContainer(animation: namespace, progress: $progress)
                        .matchedGeometryEffect(id: "hud", in: self.namespace)
                    
                    NavigationContainer()
                                        
                }
                else {
                    HUDContainer(animation: namespace, progress: $progress)
                        .matchedGeometryEffect(id: "hud", in: self.namespace)

                }
                
            }
               
            if progress == .center {
                HUDProgress().matchedGeometryEffect(id: "progress", in: self.namespace)

            }
            
        }
        .frame(width: 440, height: 240)
        .background(
            Color("BatteryBackground").opacity(window.opacity)

        )
        .timeline($timeline, state: $animation)
        .mask(
            HUDMaskView()

        )
        .background(
            HUDGlow()
            
        )
        .onHover(perform: { hover in
            self.window.hover = hover
            
        })
        
    }
    
}

struct HUDParent: View {
    @State var type:AppAlertTypes
    @State var device:AppDeviceObject?

    init(_ type: AppAlertTypes, device:AppDeviceObject?) {
        self._type = State(initialValue: type)
        self._device = State(initialValue: device)
        
    }
    
    var body: some View {
        if let container = CloudManager.container?.container {
            VStack {
                HUDView()

            }
            .modelContainer(container)
            .environmentObject(WindowManager.shared)
            .environmentObject(AppManager.shared)
            .environmentObject(OnboardingManager.shared)
            .environmentObject(BatteryManager.shared)
            .environmentObject(SettingsManager.shared)
            .environmentObject(UpdateManager.shared)
            .environmentObject(StatsManager.shared)
            .environmentObject(BluetoothManager.shared)
        }
        else {
            VStack {
                HUDView()

            }
            .environmentObject(WindowManager.shared)
            .environmentObject(AppManager.shared)
            .environmentObject(OnboardingManager.shared)
            .environmentObject(BatteryManager.shared)
            .environmentObject(SettingsManager.shared)
            .environmentObject(UpdateManager.shared)
            .environmentObject(StatsManager.shared)
            .environmentObject(BluetoothManager.shared)
        }

    }
    
}
