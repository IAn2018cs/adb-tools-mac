//
//  AdbHelper.swift
//  adbconnect
//
//  Created by Naman Dwivedi on 11/03/21.
//

import Foundation

class AdbHelper {
    
    let adb = Bundle.main.url(forResource: "adb", withExtension: nil)
    
    func getDevices() -> [Device] {
        let command = "devices -l | awk 'NR>1 {print $1}'"
        let devicesResult = runAdbCommand(command)
        return devicesResult
            .components(separatedBy: .newlines)
            .filter({ (id) -> Bool in
                !id.isEmpty
            })
            .map { (id) -> Device in
                Device(id: id, name: getDeviceName(deviceId: id))
            }
    }
    
    @discardableResult
    func runShellWithArgs(_ command: String) -> Int32 {
        let task = Process()
        task.launchPath = "/bin/bash"
        task.arguments = ["-c", command]
        task.launch()
        task.waitUntilExit()
        return task.terminationStatus
    }
    
    func getDeviceName(deviceId: String) -> String {
        let command = "-s " + deviceId + " shell getprop ro.product.model"
        return runAdbCommand(command)
    }
    
    func takeScreenshot(deviceId: String) {
        let time = formattedTime()
        _ = runAdbCommand("-s " + deviceId + " shell screencap -p /sdcard/screencap_adbtool.png")
        let outFile = "~/Desktop/screen" + time + ".png"
        _ = self.runAdbCommand("-s " + deviceId + " pull /sdcard/screencap_adbtool.png " + outFile)
        runShellWithArgs("open -a 'Preview.app' " + outFile)
    }
    
    func recordScreen(deviceId: String) {
        let command = "-s " + deviceId + " shell screenrecord /sdcard/screenrecord_adbtool.mp4"
        
        // run record screen in background
        DispatchQueue.global(qos: .background).async {
            _ = self.runAdbCommand(command)
        }
    }

    func stopScreenRecording(deviceId: String) {
        let time = formattedTime()
        
        // kill already running screenrecord process to stop recording
        _ = runAdbCommand("-s " + deviceId + " shell pkill -INT screenrecord")
        
        let outFile = "~/Desktop/record" + time + ".mp4"
        
        // after killing the screenrecord process,we have to for some time before pulling the file else file stays corrupted
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            _ = self.runAdbCommand("-s " + deviceId + " pull /sdcard/screenrecord_adbtool.mp4 " + outFile)
        }
    }
    
    func makeTCPConnection(deviceId: String) {
        DispatchQueue.global(qos: .background).async {
            let deviceIp = self.getDeviceIp(deviceId: deviceId);
            let tcpCommand = "-s " + deviceId + " tcpip 5555"
            _ = self.runAdbCommand(tcpCommand)
            let connectCommand = "-s " + deviceId + " connect " + deviceIp + ":5555"
            _ = self.runAdbCommand(connectCommand)
        }
    }
    
    func disconnectTCPConnection(deviceId: String) {
        DispatchQueue.global(qos: .background).async {
            _ = self.runAdbCommand("-s " + deviceId + " disconnect")
        }
    }

    func getDeviceIp(deviceId: String) -> String {
        let command = "-s " + deviceId + " shell ip route | awk '{print $9}'"
        return runAdbCommand(command)
    }
    
    func openDeeplink(deviceId: String, deeplink: String) {
        let command = "-s " + deviceId + " shell am start -a android.intent.action.VIEW -d '" + deeplink + "'"
        _ = runAdbCommand(command)
    }
    
    func installApk(devicedId: String, path: String) -> String {
        let command = "-s " + devicedId + " install '" + path + "'"
        return runAdbCommand(command)
    }
    
    func uninstallApk(deviceId: String, packageName: String) {
        let command = "-s " + deviceId + " uninstall " + packageName
        _ = runAdbCommand(command)
    }
    
    func clearData(deviceId: String, packageName: String) {
        let command = "-s " + deviceId + " shell pm clear " + packageName
        _ = runAdbCommand(command)
    }
    
    func openApp(deviceId: String, packageName: String) {
        let command = "-s " + deviceId + " shell monkey -p " + packageName + " -c android.intent.category.LAUNCHER 1"
        _ = runAdbCommand(command)
    }
    
    func killApp(deviceId: String, packageName: String) {
        let command = "-s " + deviceId + " shell am force-stop " + packageName
        _ = runAdbCommand(command)
    }
    
    func restartApp(deviceId: String, packageName: String) {
        killApp(deviceId: deviceId, packageName: packageName)
        openApp(deviceId: deviceId, packageName: packageName)
    }
    
    func clearDataAndStart(deviceId: String, packageName: String) {
        clearData(deviceId: deviceId, packageName: packageName)
        openApp(deviceId: deviceId, packageName: packageName)
    }
    
    func captureBugReport(deviceId: String) {
        let time = formattedTime()
        DispatchQueue.global(qos: .background).async {
            _ = self.runAdbCommand("-s " + deviceId + " logcat -d > ~/Desktop/logcat" + time + ".txt")
        }
    }
    
    private func formattedTime() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd-HH-mm-ss-SSS"
        let time = formatter.string(from: Date())
        return time
    }
    
    private func runAdbCommand(_ command: String) -> String {
        let task = Process()
        let pipe = Pipe()
        
        task.standardOutput = pipe
        task.standardError = pipe
        task.arguments = ["-c", "'" + adb!.path + "'" + " " + command]
        task.launchPath = "/bin/sh"
        task.launch()
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8)!.trimmingCharacters(in: .whitespacesAndNewlines)
        return output
    }
    
}

