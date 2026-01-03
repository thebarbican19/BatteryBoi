import Foundation

public enum CameraPermissionState: String, Codable, Hashable {
    case allowed
    case denied
    case restricted
    case undetermined
    case unknown

    var title: String {
        switch self {
            case .allowed: return "Allowed"
            case .denied: return "Denied"
            case .restricted: return "Restricted"
            case .undetermined: return "Not Determined"
            case .unknown: return "Unknown"
        }
    }
}

public enum CameraDetectionMethod: String, Codable, Hashable {
    case avfoundation
    case lsof
    case unavailable

    var description: String {
        switch self {
            case .avfoundation: return "AVFoundation"
            case .lsof: return "lsof (Fallback)"
            case .unavailable: return "Unavailable"
        }
    }
}
