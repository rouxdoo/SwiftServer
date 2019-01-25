import ElementalController
import Foundation
import Dispatch
import Glibc
import FileUtils

class MainProcess {
    
    enum ElementIdentifier: Int8 {
        case brightness = 1
        case backlight = 2
        case pwr = 3
        case act = 4
        case cmd = 5
    }
    var elementalController = ElementalController()
    var systemBrightness: Float {
        get {
            let path = "/sys/class/backlight/rpi_backlight/brightness"
            do {
                let textFile = try File.read(atPath: path).components(separatedBy: .whitespacesAndNewlines).joined()
                return Float(textFile) ?? 0.0
            } catch {
                print("error reading " + path)
                return 0.0
            }
        }
        set {
            let path = "/sys/class/backlight/rpi_backlight/brightness"
            let str = String(Int(newValue))
            do {
                try File.write(string: str, toPath: path)
            } catch {
                print("error writing to " + path)
            }
        }
    }
    var systemBacklight: Float {
        get {
            let path = "/sys/class/backlight/rpi_backlight/bl_power"
            do {
                let textFile = try File.read(atPath: path).components(separatedBy: .whitespacesAndNewlines).joined()
                if textFile == "0" {
                    return 1.0
                } else {
                    return 0.0
                }
            } catch {
                print("error reading " + path)
                return 0.0
            }
        }
        set {
            let path = "/sys/class/backlight/rpi_backlight/bl_power"
            if newValue > 0.0 {
                do {
                    try File.write(string: "0", toPath: path)
                } catch {
                    print("error writing to " + path)
                }
            } else {
                do {
                    try File.write(string: "1", toPath: path)
                } catch {
                    print("error writing to " + path)
                }
            }
        }
    }
    var systemPwr: Float {
        get {
            let path = "/sys/class/leds/led1/brightness"
            do {
                let textFile = try File.read(atPath: path).components(separatedBy: .whitespacesAndNewlines).joined()
                if textFile == "0" {
                    return 0.0
                } else {
                    return 255.0
                }
            } catch {
                print("error reading " + path)
                return 0.0
            }
        }
        set {
            let path = "/sys/class/leds/led1/brightness"
            if newValue > 0.0 {
                do {
                    try File.write(string: "255", toPath: path)
                } catch {
                    print("error writing to " + path)
                }
            } else {
                do {
                    try File.write(string: "0", toPath: path)
                } catch {
                    print("error writing to " + path)
                }
            }
        }
    }
    var systemAct: Float {
        get {
            let path = "/sys/class/leds/led0/brightness"
            do {
                let textFile = try File.read(atPath: path).components(separatedBy: .whitespacesAndNewlines).joined()
                if textFile == "0" {
                    return 0.0
                } else {
                    return 255.0
                }
            } catch {
                print("error reading " + path)
                return 0.0
            }
        }
        set {
            let path = "/sys/class/leds/led0/brightness"
            if newValue > 0.0 {
                do {
                    try File.write(string: "255", toPath: path)
                } catch {
                    print("error writing to " + path)
                }
            } else {
                do {
                    try File.write(string: "0", toPath: path)
                } catch {
                    print("error writing to " + path)
                }
            }
        }
    }
    func shell(_ command: String) -> String {
        let task = Process()
        task.launchPath = "/bin/bash"
        task.arguments = ["-c", command]
        
        let pipe = Pipe()
        task.standardOutput = pipe
        task.launch()
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: String.Encoding.utf8)!
        return output
    }
    var clientDevices: [ClientDevice] = []
    func startup() {
        elementalController.setupForService(serviceName: "SwiftServer", displayName: "SwiftServer")

        elementalController.service.events.deviceDisconnected.handler = { _, device in
            let clientDevice = device as! ClientDevice
            if let idx = self.clientDevices.index(where: { $0 === clientDevice }) {
                self.clientDevices.remove(at: idx)
            }
            logDebug("Connected device count is: " + String(describing: self.clientDevices.count))
        }
        elementalController.service.events.deviceConnected.handler = { _, device in
            let clientDevice = device as! ClientDevice
            self.clientDevices.append(clientDevice)
            logDebug("Connected device count is: " + String(describing: self.clientDevices.count))
            var controlElements: [Element] = []
            
            let brightness = clientDevice.attachElement(
                Element(identifier: ElementIdentifier.brightness.rawValue,
                        displayName: "Brightness",
                        proto: .tcp,
                        dataType: .Float))
            brightness.value = self.systemBrightness
            controlElements.append(brightness)
            
            let backlight = clientDevice.attachElement(
                Element(identifier: ElementIdentifier.backlight.rawValue,
                        displayName: "Backlight",
                        proto: .tcp,
                        dataType: .Float))
            backlight.value = self.systemBacklight
            controlElements.append(backlight)
            
            let power = clientDevice.attachElement(
                Element(identifier: ElementIdentifier.pwr.rawValue,
                        displayName: "Power LED",
                        proto: .tcp,
                        dataType: .Float))
            power.value = self.systemPwr
            controlElements.append(power)
            
            let activity = clientDevice.attachElement(
                Element(identifier: ElementIdentifier.act.rawValue,
                        displayName: "Activity LED",
                        proto: .tcp,
                        dataType: .Float))
            activity.value = self.systemAct
            controlElements.append(activity)
            
            let command = clientDevice.attachElement(
                Element(identifier: ElementIdentifier.cmd.rawValue,
                        displayName: "Command",
                        proto: .tcp,
                        dataType: .String))
            
            for elem in controlElements {
                for dev in self.clientDevices {
                    do {
                        try dev.send(element: elem)
                    } catch {
                        logDebug("unable to send element to device")
                    }
                }
            }
            
            brightness.handler = { element, _ in
                self.systemBrightness = element.value as! Float
            }
            backlight.handler = { element, _ in
                self.systemBacklight = element.value as! Float
            }
            power.handler = { element, _ in
                self.systemPwr = element.value as! Float
            }
            activity.handler = { element, _ in
                self.systemAct = element.value as! Float
            }
            command.handler = { element, device in
                logDebug("Server received a command element: " + (element.value as! String))
                if element.value != nil {
                    let result = self.shell(element.value as! String)
                    do {
                        element.value = result
                        try device.send(element: element)
                    } catch {
                        logDebug("Error sending output of shell command to client")
                    }
                }
            }
        }
        do {
            try elementalController.service.publish(onPort: 0)
        } catch {
            logDebug("unable to publish element controller")
        }
    }
}
var process = MainProcess()
process.startup()
withExtendedLifetime((process)) {
    RunLoop.main.run()
}
