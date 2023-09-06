//
//  BBNoticeManager.swift
//  BatteryBoi
//
//  Created by Joe Barbour on 9/1/23.
//

import Foundation
import Combine
import AppKit

struct NoticeObject {
    var id:String
    var title:String
    var url:URL
    
}

class NoticeManager:ObservableObject {
    static var shared = NoticeManager()
    
    @Published var notice:NoticeObject? = nil
    
    private var updates = Set<AnyCancellable>()

    init() {
        var calendar = Calendar.current
        calendar.timeZone = TimeZone(identifier: "America/Los_Angeles")!
        
        BatteryManager.shared.$charging.removeDuplicates().sink { _ in
            
            let components = calendar.dateComponents([.day, .month], from: Date())
            
            if let day = components.day, let month = components.month {
                if month == 9 && (day > 4 && day < 10) {
                    self.noticeCreate("phunt", title: "Support BatteryBoi's Launch on Product Hunt!", url: "https://www.producthunt.com/posts/batteryboi-open-source")
                    
                }
                
            }
            
        }.store(in: &updates)
                
    }
    
    public func noticeAction() {
        if let notice = self.notice {
            NSWorkspace.shared.open(notice.url)

            UserDefaults.save(string: "sd_notice_\(notice.id)", value: true)

            self.notice = nil
            
        }
        
    }
    
    private func noticeCreate(_ id:String, title:String, url:String){
        if UserDefaults.main.object(forKey: "sd_notice_\(id)") == nil {
            if let url = URL(string: url) {
                self.notice = .init(id: id, title: title, url: url)
                
            }
            
        }
        
    }
    
}
