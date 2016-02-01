//
//  AppDelegate.swift
//  rainbow-osx-swift
//
//  Created by eycia on 16/1/29.
//  Copyright © 2016年 eycia. All rights reserved.
//

import Cocoa

extension String {
    struct NumberFormatter {
        static let instance = NSNumberFormatter()
    }
    var doubleValue:Double? {
        return NumberFormatter.instance.numberFromString(self)?.doubleValue
    }
    var integerValue:Int? {
        return NumberFormatter.instance.numberFromString(self)?.integerValue
    }
}

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    @IBOutlet weak var window: NSWindow!
    @IBOutlet weak var btnok: NSButton!
    @IBOutlet weak var btnClean: NSButton!
    @IBOutlet weak var lblCacheSize: NSTextField!
    @IBOutlet weak var txtD: NSTextField!
    @IBOutlet weak var txtAng: NSTextField!
    
    var statusBar = NSStatusBar.systemStatusBar()
    var statusBarItem : NSStatusItem = NSStatusItem()
    var menu: NSMenu = NSMenu()
    var menuItemSetting : NSMenuItem = NSMenuItem()
    var menuItemQuit : NSMenuItem = NSMenuItem()
    
    var ang : String = "0"
    var d : String = "4"
    
    let downloadQueue = dispatch_queue_create("downloadQueue", nil)
    
    func judgeIsAng(angS: String) -> Bool {
        if let _ = angS.doubleValue {
            return true
        }
        return false
    }
    
    func judgeIsD(dS: String) -> Bool {
        return !(dS != "1" &&  dS != "2" &&  dS != "4" &&  dS != "8" &&  dS != "16")
    }
    
    func writeConfig() {
        let dict : NSDictionary = [
            "ang" : self.ang,
            "d" : self.d,
        ]
        dict.writeToFile(NSBundle.mainBundle().resourcePath! + "/config.plist", atomically: false)
    }
    
    func download(f: Bool) {
        let task = NSTask()
        
        task.launchPath = NSBundle.mainBundle().pathForResource("rainbow-cli", ofType: "")
        
        if (f) {
            task.arguments = ["-ang", ang, "-d", d, "-f"]
        } else {
            task.arguments = ["-ang", ang, "-d", d]
        }
        
        task.launch()
        task.waitUntilExit()
    }

    func applicationDidFinishLaunching(aNotification: NSNotification) {
        self.window!.orderOut(self)
        
        var flag = false
        
        if let path = NSBundle.mainBundle().pathForResource("config", ofType: "plist") {
            if let dictionaryForPlist = NSDictionary(contentsOfFile: path){
                if let ang = dictionaryForPlist.objectForKey("ang") {
                    self.ang = ang as! String
                    if !judgeIsAng(self.ang) { flag = true }
                } else { flag = true }
            
                if let d = dictionaryForPlist.objectForKey("d") {
                    self.d = d as! String
                    if !judgeIsD(self.d) { flag = true }
                } else { flag = true }
            } else { flag = true }
        } else { flag = true }
        
        if flag {
            self.d = "4"
            self.ang = "0"
            writeConfig()
        }
        
        let countQueue = dispatch_queue_create("countQueue", nil)
        dispatch_async(countQueue) {
            while (true) {
                let cntString = self.getSize()
                dispatch_sync(dispatch_get_main_queue()) {
                    self.lblCacheSize.stringValue = cntString
                }
                NSThread.sleepForTimeInterval(60*5);
            }
        }
        
        
        let hbQueue = dispatch_queue_create("hbQueue", nil)
        dispatch_async(hbQueue) {
            dispatch_async(self.downloadQueue) {
                //第一发要强设背景
                self.download(true)
            }
            while (true) {
                dispatch_async(self.downloadQueue) {
                    self.download(false)
                }
                NSThread.sleepForTimeInterval(60*3)
            }
        }
        
    }

    func applicationWillTerminate(aNotification: NSNotification) {
        // Insert code here to tear down your application
    }

    override func awakeFromNib() {
        statusBarItem = statusBar.statusItemWithLength(-1)
        statusBarItem.menu = menu
        statusBarItem.title = "🌈"
        
        menuItemSetting.title = "设置"
        menuItemSetting.action = Selector("setWindowVisible:")
        menuItemSetting.keyEquivalent = ""
        
        menuItemQuit.title = "退出"
        menuItemQuit.action = Selector("quit:")
        
        menu.addItem(menuItemSetting)
        menu.addItem(menuItemQuit)
    }
    


    func getSize() -> String {
        /*
            based on http://stackoverflow.com/questions/32814535/how-to-get-directory-size-with-swift-on-os-x
        */
 
        let documentsDirectoryURL = NSURL.fileURLWithPath(NSBundle.mainBundle().resourcePath!+"/ep", isDirectory: true)
        
        var bool: ObjCBool = false
        if NSFileManager().fileExistsAtPath(documentsDirectoryURL.path!, isDirectory: &bool) {
            if bool.boolValue {
                let fileManager =  NSFileManager.defaultManager()
                var folderFileSizeInBytes = 0
                if let filesEnumerator = fileManager.enumeratorAtURL(documentsDirectoryURL, includingPropertiesForKeys: nil, options: [], errorHandler: {
                    (url, error) -> Bool in
                    print(url.path!)
                    print(error.localizedDescription)
                    return true
                }) {
                    while let fileURL = filesEnumerator.nextObject() as? NSURL {
                        do {
                            let attributes = try fileManager.attributesOfItemAtPath(fileURL.path!) as NSDictionary
                            folderFileSizeInBytes += attributes.fileSize().hashValue
                        } catch let error as NSError {
                            print(error.localizedDescription)
                        }
                    }
                }
                let  byteCountFormatter =  NSByteCountFormatter()
                byteCountFormatter.allowedUnits = .UseMB
                byteCountFormatter.countStyle = .File
                let folderSizeToDisplay = byteCountFormatter.stringFromByteCount(Int64(folderFileSizeInBytes))
                
                return folderSizeToDisplay
            }
        }
        
        return "缓存大小未知"
    }
    
    
    @IBAction func btnCancle(sender: NSButton) {
        self.window!.orderOut(self)
    }
    
    @IBAction func btnokPress(sender: NSButton) {
        let alert = NSAlert()
        alert.messageText = "输入有误"
        alert.addButtonWithTitle("确定")
        
        let angS = txtAng.stringValue
        let dS = txtD.stringValue
        
        if judgeIsD(dS) == false {
            alert.informativeText = "清晰度必须为1，2，4，8，16中的一个数字"
            alert.beginSheetModalForWindow(self.window, completionHandler: {  (returnCode) -> Void in })
            return
        }
        
        if judgeIsAng(angS) {
        } else {
            alert.informativeText = "旋转角度必须是一个数字"
            alert.beginSheetModalForWindow(self.window, completionHandler: {  (returnCode) -> Void in })
            return
        }
        
        self.ang = angS
        self.d = dS
        self.window!.orderOut(self)
        
        dispatch_async(downloadQueue) {
            self.download(true)
        }
        writeConfig()
    }
    
    @IBAction func btnCleanPress(sender: NSButton) {
        lblCacheSize.stringValue = getSize()
        
        dispatch_async(dispatch_get_main_queue()) {
            self.lblCacheSize.stringValue = "正在清理"
        }
        
        dispatch_async(downloadQueue) {
            do {
                try NSFileManager.defaultManager().removeItemAtPath(NSBundle.mainBundle().resourcePath! + "/ep/tmp")
            } catch _ as NSError {
            }
            let cntString = self.getSize()
            dispatch_sync(dispatch_get_main_queue()) {
                self.lblCacheSize.stringValue = cntString
            }
        }
    }
    
    func setWindowVisible(sender: AnyObject){
        txtAng.stringValue = self.ang
        txtD.stringValue = self.d
        self.window!.orderFront(self)
        NSApp.activateIgnoringOtherApps(true)
    }
    
    func quit(sender: AnyObject) {
        NSApplication.sharedApplication().terminate(self)
    }
    
}

