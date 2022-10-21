//
//  MqttTag.swift
//  MQTT
//
//  Created by Vincenzo Caruso on 19/10/22.
//

import Foundation

class MqttTag: ObservableObject {
    
    @Published var tagId: Int?
    @Published var timeStamp: Date?
    @Published var register: String?
    @Published var quality: Int?
    @Published var value: Double?
    @Published var name: String
    @Published var engEnt: String
    @Published var mqttKey: String
    @Published var isSubscripted: Bool
    
    private var tag: Tag
    private var pozzo: Pozzo
    
    init(pump: Pozzo, tag: Tag){
        self.pozzo = pump
        self.isSubscripted = false
        self.name = tag.name
        self.engEnt = tag.engUnt
        self.tagId = tag.tagId
        self.tag = tag
        self.mqttKey = "/Pozzo \(pump.name)/Dati/\(tag.name)"
    }
    
    func update(timeStamp: Date, register: String, quality: Int, value: Double, tagId: Int){
        self.tagId = tagId
        self.timeStamp = timeStamp
        self.register = register
        self.quality = quality
        self.value = value
    }
    
    
    
    
}
