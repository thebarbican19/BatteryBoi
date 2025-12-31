#import <Foundation/Foundation.h>

#if __has_attribute(swift_private)
#define AC_SWIFT_PRIVATE __attribute__((swift_private))
#else
#define AC_SWIFT_PRIVATE
#endif

/// The resource bundle ID.
static NSString * const ACBundleID AC_SWIFT_PRIVATE = @"com.ovatar.batteryapp";

/// The "BatteryBackground" asset catalog color resource.
static NSString * const ACColorNameBatteryBackground AC_SWIFT_PRIVATE = @"BatteryBackground";

/// The "BatteryButton" asset catalog color resource.
static NSString * const ACColorNameBatteryButton AC_SWIFT_PRIVATE = @"BatteryButton";

/// The "BatteryCharging" asset catalog color resource.
static NSString * const ACColorNameBatteryCharging AC_SWIFT_PRIVATE = @"BatteryCharging";

/// The "BatteryDefault" asset catalog color resource.
static NSString * const ACColorNameBatteryDefault AC_SWIFT_PRIVATE = @"BatteryDefault";

/// The "BatteryEfficient" asset catalog color resource.
static NSString * const ACColorNameBatteryEfficient AC_SWIFT_PRIVATE = @"BatteryEfficient";

/// The "BatteryLow" asset catalog color resource.
static NSString * const ACColorNameBatteryLow AC_SWIFT_PRIVATE = @"BatteryLow";

/// The "BatterySubtitle" asset catalog color resource.
static NSString * const ACColorNameBatterySubtitle AC_SWIFT_PRIVATE = @"BatterySubtitle";

/// The "BatteryTitle" asset catalog color resource.
static NSString * const ACColorNameBatteryTitle AC_SWIFT_PRIVATE = @"BatteryTitle";

/// The "AudioIcon" asset catalog image resource.
static NSString * const ACImageNameAudioIcon AC_SWIFT_PRIVATE = @"AudioIcon";

/// The "ChargingIcon" asset catalog image resource.
static NSString * const ACImageNameChargingIcon AC_SWIFT_PRIVATE = @"ChargingIcon";

/// The "CycleIcon" asset catalog image resource.
static NSString * const ACImageNameCycleIcon AC_SWIFT_PRIVATE = @"CycleIcon";

/// The "EfficiencyIcon" asset catalog image resource.
static NSString * const ACImageNameEfficiencyIcon AC_SWIFT_PRIVATE = @"EfficiencyIcon";

/// The "EmptyIcon" asset catalog image resource.
static NSString * const ACImageNameEmptyIcon AC_SWIFT_PRIVATE = @"EmptyIcon";

/// The "EventIcon" asset catalog image resource.
static NSString * const ACImageNameEventIcon AC_SWIFT_PRIVATE = @"EventIcon";

/// The "MuteIcon" asset catalog image resource.
static NSString * const ACImageNameMuteIcon AC_SWIFT_PRIVATE = @"MuteIcon";

/// The "OverheatIcon" asset catalog image resource.
static NSString * const ACImageNameOverheatIcon AC_SWIFT_PRIVATE = @"OverheatIcon";

/// The "PercentIcon" asset catalog image resource.
static NSString * const ACImageNamePercentIcon AC_SWIFT_PRIVATE = @"PercentIcon";

/// The "PlugIcon" asset catalog image resource.
static NSString * const ACImageNamePlugIcon AC_SWIFT_PRIVATE = @"PlugIcon";

/// The "RateIcon" asset catalog image resource.
static NSString * const ACImageNameRateIcon AC_SWIFT_PRIVATE = @"RateIcon";

/// The "TimeIcon" asset catalog image resource.
static NSString * const ACImageNameTimeIcon AC_SWIFT_PRIVATE = @"TimeIcon";

/// The "WebsiteIcon" asset catalog image resource.
static NSString * const ACImageNameWebsiteIcon AC_SWIFT_PRIVATE = @"WebsiteIcon";

#undef AC_SWIFT_PRIVATE
