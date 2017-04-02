//
//  TrainFilterWindowController.swift
//  12306ForMac
//
//  Created by fancymax on 16/8/2.
//  Copyright © 2016年 fancy. All rights reserved.
//

import Cocoa

enum FilterItemType:Int {
    case Group = 0, SeatType, StartTime, TrainType, Train, FromStation, ToStation
}

enum FilterKeyType:Int {
    // single: xxx
    // multi:  O|1
    // section: 00:00~06:00
    case single = 0, multi, section
}

class FilterItem: NSObject {
    init(type:FilterItemType,key:String = "",presentation:String,isChecked:Bool = false) {
        self.type = type
        self.presentation = presentation
        self.key = key
        self.isChecked = isChecked
        
        if key.contains("|") {
            self.keyType = .multi
        }
        else if key.contains("~") {
            self.keyType = .section
        }
        else {
            self.keyType = .single
        }
    }
    let type:FilterItemType
    let key:String
    let presentation:String
    let keyType: FilterKeyType
    var isChecked:Bool
    
    func IsMatchKey(of filterItem:FilterItem) -> Bool {
        assert(self.type == .Train)
        assert(self.keyType == .multi)
        
        let trainCode = self.key.components(separatedBy: "|")[0]
        let startTime = self.key.components(separatedBy: "|")[1]
        
        if filterItem.keyType == .multi {
            let filterKeys = filterItem.key.components(separatedBy: "|")
            for filterKey in filterKeys {
                if trainCode.hasPrefix(filterKey) {
                    return true
                }
            }
        }
        else if filterItem.keyType == .single {
            if filterItem.type == .TrainType {
                if self.key.hasPrefix(filterItem.key) {
                    return true
                }
            }
            else {
                if self.key.contains(filterItem.key) {
                    return true
                }
            }
        }
        else if filterItem.keyType == .section {
            let filterKeys = filterItem.key.components(separatedBy: "~")
                if ((startTime >= filterKeys[0]) && (startTime <= filterKeys[1])) {
                    return true
                }
        }
        
        return false
    }
}

class TrainFilterWindowController: BaseWindowController {
    
    var trains:[QueryLeftNewDTO]! {
        didSet(oldValue) {
            if oldValue == nil {
                return
            }
            if oldValue.count != trains.count {
                filterItems = [FilterItem]()
                createFilterItemBy(trains!)
                trainFilterTable.reloadData()
            }
        }
    }
    
    var fromStationName = ""
    var toStationName = ""
    var trainDate = ""
    
    private(set) var trainFilterKey = ""
    private(set) var seatFilterKey = ""
    fileprivate var filterItems = [FilterItem]()
    
    @IBOutlet weak var trainFilterTable: NSTableView!
    
    override func windowDidLoad() {
        super.windowDidLoad()
        createFilterItemBy(trains!)
    }
    
    override var windowNibName: String{
        return "TrainFilterWindowController"
    }
    
    func createFilterItemBy(_ trains:[QueryLeftNewDTO]){
        filterItems.append(FilterItem(type: .Group,presentation: "席别类型"))
        filterItems.append(FilterItem(type: .SeatType,key:"9|P|4|6",presentation: "商务座|特等座|软卧|高级软卧",isChecked: false))
        filterItems.append(FilterItem(type: .SeatType,key:"M|3",presentation: "一等座|硬卧",isChecked: false))
        filterItems.append(FilterItem(type: .SeatType,key:"O|1",presentation: "二等座|硬座",isChecked: true))
        filterItems.append(FilterItem(type: .SeatType,key:"1|O",presentation: "无座",isChecked: false))
        
        filterItems.append(FilterItem(type: .Group,presentation: "出发时段"))
        for filterTime in GeneralPreferenceManager.sharedInstance.userDefindFilterTimeSpan {
            filterItems.append(FilterItem(type: .StartTime,key:filterTime,presentation: filterTime,isChecked: true))
        }
        
        filterItems.append(FilterItem(type: .Group,presentation: "车次类型"))
        var hasTrainG = false
        var hasTrainC = false
        var hasTrainD = false
        var hasTrainZ = false
        var hasTrainT = false
        var hasTrainK = false
        var hasTrainL = false
        for train in trains {
            if train.TrainCode.hasPrefix("G") {
                hasTrainG = true
                continue
            }
            if train.TrainCode.hasPrefix("C") {
                hasTrainC = true
                continue
            }
            if train.TrainCode.hasPrefix("D") {
                hasTrainD = true
                continue
            }
            if train.TrainCode.hasPrefix("Z") {
                hasTrainZ = true
                continue
            }
            if train.TrainCode.hasPrefix("T") {
                hasTrainT = true
                continue
            }
            if train.TrainCode.hasPrefix("K") {
                hasTrainK = true
                continue
            }
            let keys = ["L","Y","1","2","3","4","5","6","7","8","9"]
            for key in keys {
                if train.TrainCode.hasPrefix(key) {
                    hasTrainL = true
                    break
                }
            }
        }
        if hasTrainG {
            filterItems.append(FilterItem(type: .TrainType,key:"G",presentation: "G高铁",isChecked: true))
        }
        if hasTrainC {
            filterItems.append(FilterItem(type: .TrainType,key:"C",presentation: "C城际",isChecked: true))
        }
        if hasTrainD {
            filterItems.append(FilterItem(type: .TrainType,key:"D",presentation: "D动车",isChecked: true))
        }
        if hasTrainZ {
            filterItems.append(FilterItem(type: .TrainType,key:"Z",presentation: "Z直达",isChecked: true))
        }
        if hasTrainT {
            filterItems.append(FilterItem(type: .TrainType,key:"T",presentation: "T特快",isChecked: true))
        }
        if hasTrainK {
            filterItems.append(FilterItem(type: .TrainType,key:"K",presentation: "K快车",isChecked: true))
        }
        if hasTrainL {
            filterItems.append(FilterItem(type: .TrainType,key:"L|Y|1|2|3|4|5|6|7|8|9",presentation: "LY临客|纯数字",isChecked: true))
        }
        
        filterItems.append(FilterItem(type: .Group,presentation: "出发车站"))
        var fromStations = [String]()
        for train in trains where !fromStations.contains(train.FromStationName!) {
            fromStations.append(train.FromStationName!)
            filterItems.append(FilterItem(type: .FromStation, key: train.FromStationCode!, presentation: train.FromStationName!, isChecked: true))
        }
        
        filterItems.append(FilterItem(type: .Group,presentation: "到达车站"))
        var toStations = [String]()
        for train in trains where !toStations.contains(train.ToStationName!){
            toStations.append(train.ToStationName!)
            filterItems.append(FilterItem(type: .ToStation, key: train.ToStationCode!, presentation: train.ToStationName!, isChecked: true))
        }
        
        filterItems.append(FilterItem(type: .Group,presentation: "指定车次"))
        for train in trains {
            let key = "\(train.TrainCode!)|\(train.start_time!)|\(train.FromStationCode!)|\(train.ToStationCode!)"
            let presentation = "\(train.TrainCode!) |1\(train.start_time!)~\(train.arrive_time!)  |2\(train.FromStationName!)->\(train.ToStationName!)"
            filterItems.append(FilterItem(type: .Train, key: key, presentation: presentation, isChecked: true))
        }
    }
    
    func getFilterKey(){
        trainFilterKey = "|"
        seatFilterKey = "|"
        for item in filterItems {
            if ((item.type == .Train) && (item.isChecked)) {
                trainFilterKey += "\(item.key)|"
            }
            
            if ((item.type == .SeatType) && (item.isChecked)) {
                seatFilterKey += "\(item.presentation)|"
            }
        }
    }
    
    @IBAction func clickTrainFilterBtn(_ sender: NSButton) {
        let row = trainFilterTable.row(for: sender)
        let selectedItem = filterItems[row]

        if selectedItem.type == .Train || selectedItem.type == .SeatType {
            return
        }
        
        var changeState:Bool
        if sender.state == NSOnState {
            changeState = true
        }
        else {
            changeState = false
        }
        
        for item in filterItems where (item.type == .Train && item.isChecked != changeState) {
            //1 -> 0
            if changeState == false {
                if item.IsMatchKey(of: selectedItem) {
                    item.isChecked = changeState
                }
            }//0 -> 1
            else {
                //检查其他筛选条件
                var otherItemCanChange = true
                for filterItem in filterItems where ((filterItem.type == .FromStation) || (filterItem.type == .ToStation) || (filterItem.type == .StartTime) || (filterItem.type == .TrainType)) && (filterItem != selectedItem) {
                    
                    if filterItem.isChecked == true {
                        continue
                    }
                    
                    if item.IsMatchKey(of: filterItem) {
                        otherItemCanChange = false
                        break
                    }
                }
                //若满足其他筛选条件 则进行本次筛选判断
                if otherItemCanChange {
                    if item.IsMatchKey(of: selectedItem) {
                        item.isChecked = changeState
                    }
                }
                
            }
        }

        trainFilterTable.reloadData()
    }
    
    @IBAction func clickCancel(_ sender: AnyObject) {
        dismissWithModalResponse(NSModalResponseCancel)
    }
    
    @IBAction func clickOK(_ sender: AnyObject) {
        getFilterKey()
        dismissWithModalResponse(NSModalResponseOK)
    }
    
    deinit {
        print("TrainFilterWindowController deinit")
    }
}

// MARK: - NSTableViewDelegate / NSTableViewDataSource
extension TrainFilterWindowController:NSTableViewDelegate,NSTableViewDataSource {
    
    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
        return filterItems[row]
    }
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return filterItems.count
    }
    
    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        if filterItems[row].type == .Group {
            return 20
        }
        else{
            return 25
        }
    }
    
    func tableView(_ tableView: NSTableView, isGroupRow row: Int) -> Bool {
        if filterItems[row].type == .Group {
            return true
        }
        else {
            return false
        }
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let mainCell:NSView?
        if filterItems[row].type == .Group {
            mainCell = tableView.make(withIdentifier: "TextCell", owner: nil)
        }
        else if filterItems[row].type == .Train {
            mainCell = tableView.make(withIdentifier: "TrainInfoCell", owner: nil)
        }
        else{
            mainCell = tableView.make(withIdentifier: "MainCell", owner: nil)
        }
        if let view = mainCell?.viewWithTag(100) {
            let btn = view as! NSButton
            btn.target = self
            btn.action = #selector(TrainFilterWindowController.clickTrainFilterBtn(_:))
        }
        
        return mainCell
    }

}
