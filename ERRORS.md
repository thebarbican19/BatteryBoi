# BatteryBoi Error Reference

This document provides a comprehensive reference for all error codes used in BatteryBoi's logging and error handling system.

## Error Code System

BatteryBoi uses humorous pop-culture-themed error codes with clear descriptions. Each error has:
- **Icon**: 🚨 for fatal errors, ❌ for non-fatal errors
- **Fatal Flag**: Triggers `fatalError()` in DEBUG mode only
- **Terminate Flag**: Should the app terminate when this error occurs
- **Description**: Human-readable explanation

---

## Core Error Codes (from Orrivo)

### Authentication & Access
| Code | Icon | Fatal | Description | Example Usage |
|------|------|-------|-------------|---------------|
| `floridaMan` | ❌ | No | Authentication credentials are missing | Cloud ID environment variable missing |

### Syntax & Parsing
| Code | Icon | Fatal | Description | Example Usage |
|------|------|-------|-------------|---------------|
| `soupKitchen` | 🚨 | Yes | Syntax is all wrong | Invalid command parsing, schema validation failed |
| `charlieWork` | ❌ | No | Argument parsing error | CLI argument parsing failures |

### External Services
| Code | Icon | Fatal | Description | Example Usage |
|------|------|-------|-------------|---------------|
| `deskPop` | ❌ | No | External service error | Update download failed, IOKit battery retrieval failed |

### Data Operations
| Code | Icon | Fatal | Description | Example Usage |
|------|------|-------|-------------|---------------|
| `porkSword` | 🚨 | Yes | Ingest error | Data import/ingest failures |
| `mcpoylesMilk` | 🚨 | Yes | Could not decode response data | JSON decoding failed, characteristic parsing error |
| `rickSanity` | ❌ | No | Saving data failed | CoreData save failures throughout the app |

### Validation
| Code | Icon | Fatal | Description | Example Usage |
|------|------|-------|-------------|---------------|
| `crabPeople` | 🚨 | Yes | Value invalid or not allowed | Invalid battery percentage, invalid alert type |
| `looseSeal` | ❌ | No | Validation error | Bluetooth connection validation |
| `goldenGod` | ❌ | No | Prompt validation error | LLM prompt validation (future use) |

### Resources
| Code | Icon | Fatal | Description | Example Usage |
|------|------|-------|-------------|---------------|
| `foreverUnclean` | ❌ | No | Resource not found | Device not found, alert not found, window not found |
| `milkSteak` | ❌ | No | Content could not be enriched | Content processing failures |

### System & Network
| Code | Icon | Fatal | Description | Example Usage |
|------|------|-------|-------------|---------------|
| `wickityWack` | ❌ | No | Invalid URL | Invalid appcast URL, symlink path errors |
| `funkeMobile` | ❌ | No | Directory error | Failed to create directories, file system errors |
| `dolphinDivorce` | ❌ | No | Theme/UI error | Window creation/positioning failures |

### Logging & Advanced
| Code | Icon | Fatal | Description | Example Usage |
|------|------|-------|-------------|---------------|
| `bobLoblaw` | ❌ | No | Log export error | Failed to export logs |
| `birdLaw` | ❌ | No | LLM error | AI/LLM processing errors (future use) |

---

## BatteryBoi-Specific Error Codes

### Hardware Communication
| Code | Icon | Fatal | Description | Example Usage |
|------|------|-------|-------------|---------------|
| `smcFailure` | ❌ | No | SMC communication error | SMCKit read/write failures |
| `helperDead` | ❌ | No | Privileged helper not responding | Helper tool installation failed, XPC connection dropped |

### Device Management
| Code | Icon | Fatal | Description | Example Usage |
|------|------|-------|-------------|---------------|
| `bluetoothDrain` | ❌ | No | Bluetooth scanning failure | Bluetooth manager initialization failed |
| `cloudSync` | ❌ | No | iCloud sync failure | iCloud container load failed |

---

## Usage Examples

### Basic Error Throwing

```swift
throw BBAppError(.smcFailure, message: "SMC communication error for key: TC0P", reference: "BBBatteryManager.powerReadData")
```

### Error Handling with Logging

```swift
do {
    try context.save()
}
catch {
    LogManager.shared.logError("Failed to save battery event: \(error.localizedDescription)")
    throw BBAppError(.rickSanity, message: "Core Data save failed", reference: "BBBatteryManager.powerStoreEvent")
}
```

### Non-Throwing Error Logging

```swift
if let error = error {
    LogManager.shared.logError("iCloud container failed to load: \(error.localizedDescription)")
    _ = BBAppError(.cloudSync, message: "iCloud container failed: \(error.localizedDescription)", reference: "BBCloudManager.loadPersistentStores")
}
```

---

## Error Mapping by Manager

### BBBatteryManager
- `smcFailure`: SMC read/write operations (lines 510-511)
- `rickSanity`: CoreData save failures (lines 365-366)
- `deskPop`: IOKit battery information retrieval failures
- `foreverUnclean`: Battery metrics unavailable

### BBCloudManager
- `cloudSync`: iCloud container load failures (lines 82-83)
- `funkeMobile`: Directory creation failures (line 62, 105)
- `floridaMan`: Cloud ID environment missing (line 140)
- `rickSanity`: CoreData save failures

### BBProcessManager
- `helperDead`: Privileged helper failures (lines 1014-1015)
- `charlieWork`: CLI argument parsing errors
- `soupKitchen`: Command parsing failures

### BBBluetoothManager
- `bluetoothDrain`: Bluetooth manager failures
- `looseSeal`: Connection drops
- `foreverUnclean`: Device not found
- `mcpoylesMilk`: Characteristic parsing failures
- `crabPeople`: Invalid battery percentage

### BBAppManager
- `rickSanity`: CoreData save failures (lines 332-333, 387-388)
- `funkeMobile`: Directory creation failures
- `wickityWack`: Invalid symlink paths

### BBAlertManager
- `rickSanity`: CoreData save failures (line 88)
- `foreverUnclean`: Alert entity not found (line 45)
- `crabPeople`: Invalid alert type

### BBUpdateManager
- `deskPop`: Update/appcast download failures (lines 111, 117, 200)
- `wickityWack`: Invalid appcast URL
- `foreverUnclean`: No update found

---

## Fatal Error Behavior

### In DEBUG Mode
Fatal errors trigger `fatalError()` immediately, crashing the app with the error message. This helps catch critical bugs during development.

### In RELEASE Mode
Fatal errors are logged but do NOT crash the app. They print to console with the 🚨 icon.

### Fatal Error Codes
- `soupKitchen` - Syntax errors (terminates)
- `crabPeople` - Invalid values (terminates)
- `mcpoylesMilk` - Decoding failures
- `porkSword` - Ingest errors

---

## Best Practices

1. **Always log before throwing**: Use `LogManager.shared.logError()` before throwing BBAppError
2. **Include context**: Add the reference parameter with file and method name
3. **Use appropriate error codes**: Match the error type to the situation
4. **Don't silence errors**: Replace empty catch blocks with proper logging
5. **Fatal errors are serious**: Only use for truly unrecoverable situations

---

## Testing Error Handling

### Unit Tests
See `BBAppErrorTests.swift` for comprehensive error behavior tests.

### Manual Testing
1. Check Console.app for logs with subsystem `com.batteryboi`
2. Verify fatal errors crash in DEBUG mode
3. Confirm error icons display correctly (🚨 vs ❌)
4. Test log export functionality

---

*Generated for BatteryBoi v3 - Last Updated: 2025-12-30*
