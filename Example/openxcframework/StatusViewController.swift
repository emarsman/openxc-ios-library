
//  Created by Tim Buick on 2016-08-04.
//  Copyright (c) 2016 Ford Motor Company Licensed under the BSD license.

import UIKit
import openXCiOSFramework

// TODO: ToDo - Work on removing the warnings

class StatusViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    // UI Labels
    @IBOutlet weak var actConLab: UILabel!
    @IBOutlet weak var msgRvcdLab: UILabel!
    @IBOutlet weak var verLab: UILabel!
    @IBOutlet weak var devidLab: UILabel!
    @IBOutlet weak var platformLab: UILabel!
    @IBOutlet weak var throughputLab: UILabel!
    @IBOutlet weak var averageMessageLab: UILabel!
    @IBOutlet weak var NetworkImg: UIImageView!
    
    fileprivate var troughputLoop: Timer!
    // scan/connect button
    @IBOutlet weak var searchBtn: UIButton!
    // disconnect button
    @IBOutlet weak var disconnectBtn: UIButton!
    // REstart Trace button
    @IBOutlet weak var restartTraceBtn: UIButton!
    // Trace Split button
    @IBOutlet weak var splitTraceBtn: UIButton!
    // Trace Split button
    @IBOutlet weak var startStopBtn: UIButton!
    // table for holding/showing discovered VIs
    @IBOutlet weak var peripheralTable: UITableView!
    
    // the VM
    var vm: VehicleManager!
    var cm: Command!
    var tfm: TraceFileManager!
    var bm: BluetoothManager!
    
    // timer for UI counter updates
    var timer: Timer!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.disconnectBtn.isHidden = true
        self.splitTraceBtn.isHidden = true
        self.startStopBtn.isHidden = true

        // change tab bar text colors
        UITabBarItem.appearance().setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.gray], for:UIControl.State())
        UITabBarItem.appearance().setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.white], for:.selected)
        
        
        // instantiate the VM
        vm = VehicleManager.sharedInstance
        cm = Command.sharedInstance
        tfm = TraceFileManager.sharedInstance
        bm = BluetoothManager.sharedInstance
        
        // setup the status callback, and the command response callback
        vm.setManagerCallbackTarget(self, action: StatusViewController.manager_status_updates)
        
        // setup the status callback, and the command response callback
        vm.setCommandDefaultTarget(self, action: StatusViewController.handle_cmd_response)
        // turn on debug output
        vm.setManagerDebug(true)


    }
    func traceCheck(){
        let traceSinkOn = UserDefaults.standard.bool(forKey: "traceOutputOn")
             // update UI if necessary
             if (traceSinkOn && bm.isBleConnected){
                 self.startStopBtn.isHidden = false
                 self.startStopBtn.isSelected = true
             }else{
                 self.splitTraceBtn.isHidden = true
                 self.startStopBtn.isHidden = true
             }
              let traceDisableLoopOn = UserDefaults.standard.bool(forKey: "disableTraceLoopOn")
             if (traceDisableLoopOn ){
                  self.restartTraceBtn.isHidden = false
             }else{
                  self.restartTraceBtn.isHidden = true
             }
    }
    func bluetoothCheck(){
        if (bm.isBleConnected) {
                 DispatchQueue.main.async {
                     self.disconnectBtn.isHidden = false
                     self.NetworkImg.isHidden = true
                    
                 }
             }
             else
             {
                 self.disconnectBtn.isHidden = true
                 self.searchBtn.isEnabled = true
                 self.NetworkImg.isHidden = true
                 self.actConLab.text = "---"
                 self.msgRvcdLab.text = "---"
                 self.searchBtn.setTitle("SEARCH FOR BLE VI",for:UIControl.State())
             }
    }
    func networkCheck(){
        if (!vm.isNetworkConnected){
                      if let name = (UserDefaults.standard.value(forKey: "networkHostName") as? String) {
                          if let port = (UserDefaults.standard.value(forKey: "networkPortName") as? String){
                              self.networkDataFetch(hostName: name ,PortName: port )
                          }
                          
                      }else{
                          DispatchQueue.main.async {
                              self.actConLab.text = ""
                              self.verLab.text = "---"
                              self.devidLab.text = "---"
                              self.platformLab.text = "---"
                              self.msgRvcdLab.text = "---"
                              self.searchBtn.setTitle(wifiNotConnected,for:UIControl.State())
                              self.searchBtn.isEnabled = false
                              let alertController = UIAlertController(title: "", message:
                                  "please check the host adress", preferredStyle: UIAlertController.Style.alert)
                              alertController.addAction(UIAlertAction(title: "Dismiss", style: UIAlertAction.Style.default,handler: nil))
                              self.present(alertController, animated: true, completion: nil)
                          }
                          
                      }
                      
                      
                  }else{
                      timer = Timer.scheduledTimer(timeInterval: 0.25, target: self, selector: #selector(StatusViewController.msgRxdUpdate(_:)), userInfo: nil, repeats: true)
                      DispatchQueue.main.async {
                          self.NetworkImg.isHidden = false
                          self.actConLab.text = ""
                          self.verLab.text = "---"
                          self.devidLab.text = "---"
                          self.platformLab.text = "---"
                          //self.msgRvcdLab.text = "---"
                          self.searchBtn.setTitle("WIFI  CONNECTED",for:UIControl.State())
                          self.searchBtn.isEnabled = false
                      }
                  }
    }
    func prerecordTraceFile(){
        if let traceFileName = UserDefaults.standard.value(forKey: "traceInputFilename") as? NSString{
                      timer = Timer.scheduledTimer(timeInterval: 0.25, target: self, selector: #selector(StatusViewController.msgRxdUpdate(_:)), userInfo: nil, repeats: true)
                      if(!vm.isTraceFileConnected){
                          tfm.enableTraceFileSource(traceFileName)
                          self.searchBtn.isEnabled = false
                          DispatchQueue.main.async {
                              self.actConLab.text = "✅"
                              self.searchBtn.setTitle("Trace File Playing",for:UIControl.State())
                              self.verLab.text = "---"
                              self.devidLab.text = "---"
                              self.platformLab.text = "---"
                          }
                      }else{
                          
                          DispatchQueue.main.async {
                              self.actConLab.text = "✅"
                              self.searchBtn.setTitle("Trace File Playing",for:UIControl.State())
                          }
                      }
                  }
    }
    override func viewDidAppear(_ animated: Bool) {
       
        self.traceCheck()
        
        if let name = (UserDefaults.standard.value(forKey: "vehicleInterface") as? String) {
            if name == "Bluetooth"{
                self.bluetoothCheck()
            }
            
            if (bm.isBleConnected && !UserDefaults.standard.bool(forKey: "throughputOn")) {
                DispatchQueue.main.async {
                    self.throughputLab.text = "off"
                    self.averageMessageLab.text = "off"
                }
                vm.setThroughput(false)
            }else{
                
                if bm.isBleConnected && UserDefaults.standard.bool(forKey: "throughputOn"){
                        vm.setThroughput(true)
                        troughputLoop = Timer.scheduledTimer(timeInterval: 5.0, target:self, selector:#selector(calculateThroughput), userInfo: nil, repeats:true)
                }
                print(UserDefaults.standard.bool(forKey: "throughputOn"))
                
            }
            if name == "Network"{
                self.networkCheck()
                return
            }
            
            
            if name == "None"{
                DispatchQueue.main.async {
                    self.actConLab.text = "---"
                    self.msgRvcdLab.text = "---"
                    self.verLab.text = "---"
                    self.devidLab.text = "---"
                    self.platformLab.text = "---"
                    self.searchBtn.setTitle("None",for:UIControl.State())
                    self.searchBtn.isEnabled = false
                }
                return
            }
            
            if name == "Pre-recorded Tracefile"{
                self.prerecordTraceFile()
                return
            }
        }
        
        // check to see if a trace input file has been set up
        
    }
    //ranjan added code for Network data
    func networkDataFetch(hostName:String,PortName:String)  {
        // networkData.text = name as String
        
        //let ip  = hostName
        let port  = Int(PortName)
        if(hostName != "" && PortName != ""){
            NetworkDataManager.sharedInstance.connect(ip:hostName, portvalue: port!, completionHandler: { (success) in
                print(success)
                if(success){
                    self.timer = Timer.scheduledTimer(timeInterval: 0.25, target: self, selector: #selector(StatusViewController.msgRxdUpdate(_:)), userInfo: nil, repeats: true)
                    if self.bm.messageCount > 0{
                        UserDefaults.standard.set(hostName, forKey:"networkHostName")
                        UserDefaults.standard.set(PortName, forKey:"networkPortName")
                        DispatchQueue.main.async {
                            
                            self.NetworkImg.isHidden = true
                            self.actConLab.text = ""
                            self.verLab.text = "---"
                            self.devidLab.text = "---"
                            self.platformLab.text = "---"
                            self.searchBtn.setTitle("WIFI CONNECTED",for:UIControl.State())
                            self.searchBtn.isEnabled = false
                        }
                    }
                    //self.callBack()
                }else{
                    DispatchQueue.main.async {
                        self.actConLab.text = ""
                        self.verLab.text = "---"
                        self.devidLab.text = "---"
                        self.platformLab.text = "---"
                        self.msgRvcdLab.text = "---"
                        self.searchBtn.setTitle(wifiNotConnected,for:UIControl.State())
                        self.searchBtn.isEnabled = false
                        let alertController = UIAlertController(title: "", message:
                            "error ocured in connection", preferredStyle: UIAlertController.Style.alert)
                        alertController.addAction(UIAlertAction(title: "Dismiss", style: UIAlertAction.Style.default,handler: nil))
                        self.present(alertController, animated: true, completion: nil)
                    }
                    
                }
            })
        }
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @objc func calculateThroughput(){
        if (bm.isBleConnected && UserDefaults.standard.bool(forKey: "throughputOn")){
           
            let value = bm.calculateThroughput()
            let arrOfStr = value.split(separator: ".")
            
            self.throughputLab.text! = String(arrOfStr[0])
            self.averageMessageLab.text! = String(arrOfStr[1])
        }else{
            if (bm.isBleConnected){
            self.throughputLab.text = "off"
            self.averageMessageLab.text = "off"
            troughputLoop.invalidate()
            }else{
                self.throughputLab.text = "---"
                self.averageMessageLab.text = "---"
                troughputLoop.invalidate()
            }
        }
        
    }
    @objc func powerDrop(){
        AlertHandling.sharedInstance.showToast(controller: self, message: "BLE Power Droped", seconds: 3)
    }
    @objc func networkDrop(){
        AlertHandling.sharedInstance.showToast(controller: self, message: "Network Connection Droped", seconds: 3)
    }
    
    // this function is called when the scan button is hit
    @IBAction func searchHit(_ sender: UIButton) {
        
        // make sure we're not already connected first
        if (bm.connectionState==VehicleManagerConnectionState.notConnected) {
            
            // start a timer to update the UI with the total received messages
            timer = Timer.scheduledTimer(timeInterval: 0.25, target: self, selector: #selector(StatusViewController.msgRxdUpdate(_:)), userInfo: nil, repeats: true)
            
           
            self.updateStatus()
            
            // check to see if a trace output file has been configured
            if UserDefaults.standard.bool(forKey: "traceOutputOn") && !vm.isTraceFileConnected {
                if let name = UserDefaults.standard.value(forKey: "traceOutputFilename") as? NSString {
                        let value = tfm.enableTraceFileSink(name)
                    print(value)
                }else{
                    let alertController = UIAlertController (title: "Setting", message: "Please Disable pre record tracefile in data source", preferredStyle: .alert)
                    alertController.addAction(UIAlertAction(title: "Dismiss", style: UIAlertAction.Style.default,handler: nil))
                    self.present(alertController, animated: true, completion: nil)
                }
            }
            
            
            // start the VI scan
            bm.scan(completionHandler:{(success) in
                
                // update the UI
                if(!success){
                    self.updateBleStatus()

                }
                DispatchQueue.main.async {
                    self.actConLab.text = "❓"
                    self.searchBtn.setTitle("SCANNING",for:UIControl.State())
                }
                
            })
            
        }
    }
    func updateStatus(){
        // check to see if the config is set for autoconnect mode
                   bm.setAutoconnect(false)
                   if UserDefaults.standard.bool(forKey: "autoConnectOn") {
                       bm.setAutoconnect(true)
                   }
                   vm.setThroughput(false)
                   if  UserDefaults.standard.bool(forKey: "throughputOn"){
                       //print(UserDefaults.standard.bool(forKey: "throughputOn"))
                       vm.setThroughput(true)
                       troughputLoop = Timer.scheduledTimer(timeInterval: 5.0, target:self, selector:#selector(calculateThroughput), userInfo: nil, repeats:true)
                   }
                   // check to see if the config is set for protobuf mode
                   self.vm.setProtobufMode(false)
                   if UserDefaults.standard.bool(forKey: "protobufOn") {
                       self.vm.setProtobufMode(true)
                   }
                   
    }
    func updateBleStatus(){
        let alertController = UIAlertController (title: "Setting", message: "Please enable Bluetooth", preferredStyle: .alert)
                           let url = URL(string: "App-Prefs:root=Bluetooth")
                           let settingsAction = UIAlertAction(title: "Settings", style: .default) { (_) -> Void in
                               guard URL(string: UIApplication.openSettingsURLString) != nil else {
                                   return
                               }
                               
                               if UIApplication.shared.canOpenURL(url!) {
                                   if #available(iOS 10.0, *) {
                                       UIApplication.shared.open(url!, completionHandler: { (success) in
                                           print("Settings opened: \(success)") // Prints true
                                           
                                       })
                                   } else {
                                       // Fallback on earlier versions
                                   }
                               }
                           }
                           alertController.addAction(settingsAction)
                           let cancelAction = UIAlertAction(title: "Cancel", style: .default, handler: nil)
                           alertController.addAction(cancelAction)
                           
                           self.present(alertController, animated: true, completion: nil)
    }
    // this function receives all status updates from the VM
    func manager_status_updates(_ rsp:NSDictionary) {
        let traceSinkOn = UserDefaults.standard.bool(forKey: "traceOutputOn")
        // extract the status message
        let status = rsp.object(forKey: "status") as! Int
        let msg = VehicleManagerStatusMessage(rawValue: status)
        if (bm.isBleConnected && !UserDefaults.standard.bool(forKey: "throughputOn")) {
            DispatchQueue.main.async {
                self.throughputLab.text = "off"
                self.averageMessageLab.text = "off"
            }
        }
        // show/reload the table showing detected VIs
        if msg==VehicleManagerStatusMessage.c5DETECTED {
            DispatchQueue.main.async {
                self.peripheralTable.isHidden = false
                self.peripheralTable.reloadData()
            }
        }
        
        // update the UI showing connected VI
        if msg==VehicleManagerStatusMessage.c5CONNECTED {
            
            vm.setCommandDefaultTarget(self, action: StatusViewController.handle_cmd_response)
            DispatchQueue.main.async {
                if (traceSinkOn){
                    self.splitTraceBtn.isHidden = false
                    self.startStopBtn.isHidden = false
                    self.startStopBtn.isSelected = true
                }
                self.disconnectBtn.isHidden = false
                self.peripheralTable.isHidden = true
                self.actConLab.text = "✅"
                self.NetworkImg.isHidden = true
                self.searchBtn.setTitle("BLE VI CONNECTED",for:UIControl.State())
                
            }
        }
        if (vm.isNetworkConnected) {
            DispatchQueue.main.async {
                self.peripheralTable.isHidden = true
                self.actConLab.text = ""
                self.NetworkImg.isHidden = false
                self.searchBtn.setTitle("WIFI CONNECTED",for:UIControl.State())
                self.searchBtn.isEnabled = false
                
            }
        }
        if msg==VehicleManagerStatusMessage.networkDISCONNECTED  && !vm.isTraceFileConnected && UserDefaults.standard.bool(forKey: "networkDropChange") {
                    networkDrop()
            
                DispatchQueue.main.async {
                    self.actConLab.text = ""
                    self.verLab.text = "---"
                    self.devidLab.text = "---"
                    self.platformLab.text = "---"
                    self.msgRvcdLab.text = "---"
                    self.searchBtn.setTitle("WIFI NOT CONNECTED",for:UIControl.State())
                    self.searchBtn.isEnabled = false
                }
        }
        // update the UI showing disconnected VI
        if msg==VehicleManagerStatusMessage.c5DISCONNECTED && !vm.isTraceFileConnected && UserDefaults.standard.bool(forKey: "powerDropChange") {
            self.powerDrop()
            self.updateUi()
        }
        
        // when we see that notify is on, we can send the command requests
        // for version and device id, one after the other
        if msg==VehicleManagerStatusMessage.c5NOTIFYON {
            
            let delayTime = DispatchTime.now() + Double(Int64(0.25 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
            DispatchQueue.main.asyncAfter(deadline: delayTime) {
                let cmd = VehicleCommandRequest()
                cmd.command = .version
                self.cm.sendCommand(cmd)
            }
            
            let delayTime2 = DispatchTime.now() + Double(Int64(0.5 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
            DispatchQueue.main.asyncAfter(deadline: delayTime2) {
                let cmd = VehicleCommandRequest()
                cmd.command = .device_id
                self.cm.sendCommand(cmd)
            }
            let delayTime3 = DispatchTime.now() + Double(Int64(0.5 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
            DispatchQueue.main.asyncAfter(deadline: delayTime3) {
                let cmd = VehicleCommandRequest()
                cmd.command = .platform
                self.cm.sendCommand(cmd)
            }
        }
        
    }
    
    // this function handles all command responses
    func handle_cmd_response(_ rsp:NSDictionary) {
        
        
        // extract the command response message
        let cr = rsp.object(forKey: "vehiclemessage") as! VehicleCommandResponse
        
        // update the UI depending on the command type- version,device_id works for JSON mode, not in protobuf - TODO
        
        var cvc:CommandsViewController?
            DispatchQueue.main.async {
               let vcCount = self.tabBarController?.viewControllers?.count
                      cvc = self.tabBarController?.viewControllers?[vcCount!-1] as! CommandsViewController?
           }
        
        if cr.command_response.isEqual(to: "version") || cr.command_response.isEqual(to: ".version") {
            DispatchQueue.main.async {
                self.verLab.text = cr.message as String
            }
            cvc?.versionResp = String(cr.message)
        }
        if cr.command_response.isEqual(to: "device_id") || cr.command_response.isEqual(to: ".deviceId") || cr.command_response.isEqual(to: ".deviceid"){
            DispatchQueue.main.async {
                self.devidLab.text = cr.message as String
            }
            cvc?.deviceIdResp = String(cr.message)
            
        }
        if cr.command_response.isEqual(to: "platform") || cr.command_response.isEqual(to: ".platform") {
            
            DispatchQueue.main.async {
                self.platformLab.text = cr.message as String
            }
            cvc?.platformResp = String(cr.message)
            
        }
    }
    
    
    // this function is called by the timer, it updates the UI
    @objc func msgRxdUpdate(_ t:Timer) {
        if bm.connectionState == VehicleManagerConnectionState.operational || vm.isNetworkConnected || vm.isTraceFileConnected{
            
            DispatchQueue.main.async {
                self.msgRvcdLab.text = String(self.bm.messageCount)
            }
        }
    }
    // this function is called when the slit trace button is hit
    @IBAction func onClickStartstop(_ sender: UIButton) {
        if (startStopBtn.isSelected) {
            startStopBtn.isSelected = false
            tfm.traceFilesinkEnabled = false
            
        } else {
            startStopBtn.isSelected = true
             tfm.traceFilesinkEnabled = true
        }
    }
     // this function is called when the slit trace button is hit
    @IBAction func onClickSplit(_ sender: UIButton) {
        tfm.disableTraceFileSink()
        if let name = UserDefaults.standard.value(forKey: "traceOutputFilename") as? NSString ,!vm.isTraceFileConnected == true {
            
                tfm.enableTraceFileSink(name)
        }
    }
    
    // this function is called when the disconnect button is hit
    @IBAction func disconnectHit(_ sender: UIButton) {
        
        print(" in disconnect")
        print(bm.connectionState as Any)
        
        // make sure we're not already connected first
        if (bm.isBleConnected) {
            bm.disconnect()
            self.updateUi()
           
        }
    }
    
    func updateUi() {
               DispatchQueue.main.async {
                       self.actConLab.text = "---"
                       self.msgRvcdLab.text = "---"
                       self.verLab.text = "---"
                       self.devidLab.text = "---"
                       self.platformLab.text = "---"
                       self.searchBtn.setTitle("SEARCH FOR BLE VI",for:UIControl.State())
                       self.disconnectBtn.isHidden = true
                       self.splitTraceBtn.isHidden = true
                       self.startStopBtn.isHidden = true
                       self.throughputLab.text = "---"
                       self.averageMessageLab.text = "---"
                       
                   }
    }
    // this function is called when the Restart trace button is hit
    @IBAction func restartTraceHit(_ sender: UIButton) {
                tfm.traceFileRestart()
    }
    // table view delegate functions
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // how many VIs have been discovered
        
        tableView.dataSource = self
        
        let count = bm.discoveredVI().count
        return count
        
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        
        // grab a cell
        var cell:UITableViewCell? = tableView.dequeueReusableCell(withIdentifier: "cell") as UITableViewCell?
        if (cell == nil) {
            cell = UITableViewCell(style: UITableViewCell.CellStyle.value1, reuseIdentifier: "cell")
        }
        
        // grab the name of the VI for this row
        let p = bm.discoveredVI()[indexPath.row] as String
        
        // display the name of the VI
        cell!.textLabel?.text = p
        cell!.textLabel?.font = UIFont(name:"Arial", size: 14.0)
        cell!.textLabel?.textColor = UIColor.lightGray
        
        return cell!
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        // if a row is selected, connect to the selected VI
        let p = bm.discoveredVI()[indexPath.row] as String
        bm.connect(p)
        
    }
}

