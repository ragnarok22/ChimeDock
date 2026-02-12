import Combine
import CoreAudio
import Foundation

final class AudioDeviceMonitor: DeviceEventMonitor {
    let events = PassthroughSubject<DeviceEvent, Never>()

    private var knownDeviceIDs: Set<AudioDeviceID> = []
    private var isRunning = false

    private static let listenerProc: AudioObjectPropertyListenerProc = { _, _, _, clientData in
        guard let clientData else { return kAudioHardwareNoError }
        let monitor = Unmanaged<AudioDeviceMonitor>.fromOpaque(clientData).takeUnretainedValue()
        monitor.handleDevicesChanged()
        return kAudioHardwareNoError
    }

    func startMonitoring() {
        guard !isRunning else { return }
        isRunning = true

        knownDeviceIDs = Set(currentDeviceIDs())

        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDevices,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )

        let selfPtr = Unmanaged.passUnretained(self).toOpaque()
        AudioObjectAddPropertyListener(
            AudioObjectID(kAudioObjectSystemObject),
            &address,
            AudioDeviceMonitor.listenerProc,
            selfPtr
        )
    }

    func stopMonitoring() {
        guard isRunning else { return }
        isRunning = false

        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDevices,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )

        let selfPtr = Unmanaged.passUnretained(self).toOpaque()
        AudioObjectRemovePropertyListener(
            AudioObjectID(kAudioObjectSystemObject),
            &address,
            AudioDeviceMonitor.listenerProc,
            selfPtr
        )
    }

    private func handleDevicesChanged() {
        let currentIDs = Set(currentDeviceIDs())
        let added = currentIDs.subtracting(knownDeviceIDs)
        let removed = knownDeviceIDs.subtracting(currentIDs)

        for deviceID in added {
            let name = deviceName(for: deviceID) ?? "Audio Device"
            let event = DeviceEvent(type: .connected, source: .audio, deviceName: name)
            events.send(event)
        }

        for _ in removed {
            let event = DeviceEvent(type: .disconnected, source: .audio, deviceName: "Audio Device")
            events.send(event)
        }

        knownDeviceIDs = currentIDs
    }

    private func currentDeviceIDs() -> [AudioDeviceID] {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDevices,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )

        var dataSize: UInt32 = 0
        let status = AudioObjectGetPropertyDataSize(
            AudioObjectID(kAudioObjectSystemObject),
            &address,
            0, nil,
            &dataSize
        )
        guard status == noErr, dataSize > 0 else { return [] }

        let deviceCount = Int(dataSize) / MemoryLayout<AudioDeviceID>.size
        var deviceIDs = [AudioDeviceID](repeating: 0, count: deviceCount)
        AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &address,
            0, nil,
            &dataSize,
            &deviceIDs
        )

        return deviceIDs
    }

    private func deviceName(for deviceID: AudioDeviceID) -> String? {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyDeviceName,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )

        var name = [CChar](repeating: 0, count: 256)
        var dataSize = UInt32(name.count)
        let status = AudioObjectGetPropertyData(deviceID, &address, 0, nil, &dataSize, &name)
        guard status == noErr else { return nil }
        return String(cString: name)
    }

    deinit {
        stopMonitoring()
    }
}
