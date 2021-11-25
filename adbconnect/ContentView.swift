//
//  ContentView.swift
//  adbconnect
//
//  Created by Naman Dwivedi on 10/03/21.
//

import SwiftUI

struct ContentView: View {
    
    let adb: AdbHelper = AdbHelper()
    
    @State private var devices: [Device] = []
    
    @State private var statusMessage: String = ""
    
    var body: some View {
        DispatchQueue.global(qos: .background).async {
            devices = adb.getDevices()
        }
        return VStack {
            ScrollView(.vertical) {
                if (devices.isEmpty) {
                    NoDevicesView()
                } else {
                    ForEach(devices, id: \.id) { device in
                        DeviceActionsView(adb: adb, device: device, statusMessaage: $statusMessage, devices: $devices)
                    }
                }
            }.padding(.leading, 15).padding(.trailing, 5).padding(.top, 15)
            if (!statusMessage.isEmpty) {
                Text(statusMessage)
                    .frame(maxWidth: .infinity, alignment: .bottomTrailing)
                    .padding(.trailing, 15)
                    .font(.subheadline)
            }
        }.padding(.bottom, statusMessage.isEmpty ? 0 : 10)
       
    }
}

struct DeviceActionsView: View {
    
    var adb: AdbHelper
    var device: Device
    
    @Binding var statusMessaage: String
    @Binding var devices: [Device]
    
    @State private var deeplink: String = ""
    @State private var showAdvanced: Bool = false
    @State private var isRecordingScreen: Bool = false
    @State private var packageName: String = ""
    @State private var showAppOpt: Bool = false
    
    private func isTcpConnected() -> Bool {
        // if already connected over tcp, name would contain the port on which we connected
        return device.id.contains("5555")
    }
    
    private func chooseApk(onChoose: (String)->Void) {
        let dialog = NSOpenPanel();

        dialog.title                   = "Choose apk file to install";
        dialog.showsResizeIndicator    = true;
        dialog.showsHiddenFiles        = false;
        dialog.allowsMultipleSelection = false;
        dialog.canChooseDirectories    = false;
        dialog.allowedFileTypes        = ["apk"];

        if (dialog.runModal() ==  NSApplication.ModalResponse.OK) {
            let result = dialog.url // Pathname of the file

            if (result != nil) {
                let path: String = result!.path
                
                // path contains the file path e.g
                // /Users/ourcodeworld/Desktop/tiger.jpeg
                onChoose(path)
            }
            
        } else {
            // User clicked on "Cancel"
            return
        }
    }
    
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            
            // device info
            HStack(alignment: .top) {
                Text(device.name)
                Text("-")
                Text(device.id)
            }.frame(maxWidth: .infinity, alignment: .leading).padding(.bottom, 5)
            
            // install apk
            HStack(alignment: .top) {
                Image("WifiIcon").resizable().frame(width: 18.0, height: 18.0)
                Text("Install apk")
            }.contentShape(Rectangle())
            .onTapGesture {
                chooseApk { (p) in
                    statusMessaage = self.adb.installApk(devicedId: self.device.id, path: p)
                }
            }
            
            // screenshot
            HStack(alignment: .top) {
                Image("ScreenshotIcon").resizable().frame(width: 18.0, height: 18.0)
                Text("Take screenshot")
            }.contentShape(Rectangle())
            .onTapGesture {
                statusMessaage = "Screenshot will be saved in Desktop"
                adb.takeScreenshot(deviceId: device.id)
            }
            
            // record screen
            HStack(alignment: .top) {
                Image("RecordIcon").resizable().frame(width: 18.0, height: 18.0)
                Text(isRecordingScreen ? "Recording screen... Click to stop and save recording" : "Record screen")
            }.contentShape(Rectangle())
            .onTapGesture {
                if (isRecordingScreen) {
                    statusMessaage = "Recording will be saved in Desktop"
                    adb.stopScreenRecording(deviceId: device.id)
                    isRecordingScreen = false
                } else {
                    statusMessaage = "Started recording screen.."
                    adb.recordScreen(deviceId: device.id)
                    isRecordingScreen = true
                }
            }
            
            // open date setting
            HStack(alignment: .top) {
                Image("DateIcon").resizable().frame(width: 18.0, height: 18.0)
                Text("Open Date Setting")
            }.contentShape(Rectangle())
            .onTapGesture {
                statusMessaage = "open date & time setting"
                adb.openDateSetting(deviceId: device.id)
            }
            
            // operate app
            HStack(alignment: .top) {
                Image("AppOptIcon").resizable().frame(width: 18.0, height: 18.0)
                Text(showAppOpt ? "Hide app operate" : "Show app operate")
                    .font(showAppOpt ? Font.body.bold() : Font.body)
            }.contentShape(Rectangle())
            .onTapGesture {
                showAppOpt = !showAppOpt
            }
            if (showAppOpt) {
                HStack(alignment: .top) {
                    TextField("input package name", text: $packageName).padding(.leading, 5)
                }.padding(.leading, 20)
                
                HStack(alignment: .top) {
                    Button(action: {
                        statusMessaage = "stat app"
                        adb.openApp(deviceId: device.id, packageName: packageName)
                    }, label: {
                        Text("Start App")
                    })
                }.padding(.leading, 20)
                
                HStack(alignment: .top) {
                    Button(action: {
                        statusMessaage = "uninstall app"
                        adb.uninstallApk(deviceId: device.id, packageName: packageName)
                    }, label: {
                        Text("Uninstall App")
                    })
                }.padding(.leading, 20)
                
                HStack(alignment: .top) {
                    Button(action: {
                        statusMessaage = "restart app"
                        adb.restartApp(deviceId: device.id, packageName: packageName)
                    }, label: {
                        Text("Restart App")
                    })
                }.padding(.leading, 20)
                
                HStack(alignment: .top) {
                    Button(action: {
                        statusMessaage = "clear data and restart"
                        adb.clearDataAndStart(deviceId: device.id, packageName: packageName)
                    }, label: {
                        Text("Clear Data And Restart")
                    })
                }.padding(.leading, 20)
                
                HStack(alignment: .top) {
                    Button(action: {
                        statusMessaage = "kill app"
                        adb.killApp(deviceId: device.id, packageName: packageName)
                    }, label: {
                        Text("Kill App")
                    })
                }.padding(.leading, 20)
                
                HStack(alignment: .top) {
                    Button(action: {
                        statusMessaage = "clear app data"
                        adb.clearData(deviceId: device.id, packageName: packageName)
                    }, label: {
                        Text("Clear Data")
                    })
                }.padding(.leading, 20)
            }
            
            // advanced options
            HStack(alignment: .top) {
                Image("SettingsIcon").resizable().frame(width: 18.0, height: 18.0)
                Text(showAdvanced ? "Hide more options" : "Show more options")
                    .font(showAdvanced ? Font.body.bold() : Font.body)
            }.contentShape(Rectangle())
            .onTapGesture {
                showAdvanced = !showAdvanced
            }
            if (showAdvanced) {
                // open deeplink
                HStack(alignment: .top) {
                    Image("DeeplinkIcon").resizable().frame(width: 18.0, height: 18.0)
                    TextField("deeplink", text: $deeplink).padding(.leading, 5)
                    Button(action: {
                        statusMessaage = "Opening deeplink.."
                        adb.openDeeplink(deviceId: device.id, deeplink: deeplink)
                    }, label: {
                        Text("Open")
                    })
                }.padding(.leading, 20)
                
                // capture bugreport
                HStack(alignment: .top) {
                    Image("BugreportIcon").resizable().frame(width: 18.0, height: 18.0)
                    Text("Capture logcat")
                }.contentShape(Rectangle()).padding(.leading, 20)
                .onTapGesture {
                    statusMessaage = "Logcat saved in Desktop"
                    adb.captureBugReport(deviceId: device.id)
                }
            }
            
        }.padding(.bottom, 15)
    }
}

struct NoDevicesView: View {
    var body: some View {
        VStack {
            Text("No devices connected").frame(maxWidth: .infinity, alignment: .center).padding(.top, 20)
            Image("UsbOffIcon").resizable().frame(width: 54.0, height: 54.0, alignment: .center).padding(.top, 15)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
