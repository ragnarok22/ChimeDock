import Combine

protocol DeviceEventMonitor {
    var events: PassthroughSubject<DeviceEvent, Never> { get }
    func startMonitoring()
    func stopMonitoring()
}
