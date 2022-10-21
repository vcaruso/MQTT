//
//  MqttPozzi.swift
//  MQTT
//
//  Created by Vincenzo Caruso on 19/10/22.
//

import Foundation
import CocoaMQTT
import CocoaMQTTWebSocket

protocol MqttPozziParser {
    
    
    func parse(payload: String) -> Void
    
    
    
}

class MqttPozzi: ObservableObject {
    
    @Published var mqttTag: [MqttTag] = []
    @Published var isConnected: Bool = false
    
    var mqtt: CocoaMQTT?
    
    private var pozzi: [Pozzo] = []
    
    init(){
        
    }
    
    private func unsubscribe(){
        for tag in self.mqttTag{
            if tag.isSubscripted {
               
                        mqtt?.unsubscribe(tag.mqttKey)
                        print("Unsubscribed \(tag.mqttKey)")
                    
                    
                }
            
            mqttTag.removeAll()
        }
    }
    
    func subscribe(pozzi: [Pozzo]){
        self.unsubscribe()
        self.pozzi = pozzi
        
        let clientID = "CocoaMQTT-Pozzi" + String(ProcessInfo().processIdentifier)
        let websocket = CocoaMQTTWebSocket(uri: "/mqtt")
        mqtt = CocoaMQTT(clientID: clientID, host: "10.142.69.113", port: 1884, socket: websocket)
        if let mqtt = mqtt {
            mqtt.username = ""
            mqtt.password = ""
            mqtt.willMessage = CocoaMQTTMessage(topic: "/will", string: "dieout")
            mqtt.keepAlive = 60
            mqtt.delegate = self
            mqtt.logLevel = .info
            mqtt.autoReconnect = true
            mqtt.connect()
            for pozzo in pozzi{
                for tag in pozzo.tags{
                    mqttTag.append(MqttTag(pump: pozzo, tag: tag))
                    
                }
            }
        }
        
    }
  
  
}

extension MqttPozzi: MqttPozziParser {
    
    
    
    func parse(payload: String) {
        var lines = payload.components(separatedBy: "\n")
        guard lines.count == 2 else {
            return
        }
        var values = lines[1].components(separatedBy: ";")
        guard values.count == 5 else {
            return
        }
        let tagId = Int(values[0])
        let register = values[1]
        let value = Double(values[2])
        let seconds =  Double(values[3])!
        let timeStamp = Date.init(timeIntervalSince1970: seconds - 120*60)
        let quality = Int(values[4])
        let tag = mqttTag.filter({ $0.tagId == tagId }).first
        if let tag = tag {
            if  let quality = quality, let value = value, let tagId = tagId {
                tag.update(timeStamp: timeStamp, register: register, quality: quality, value: value, tagId: tagId)
                self.objectWillChange.send()
            }
        }
        
    }
    
    
    
    
}

extension MqttPozzi: CocoaMQTTDelegate {

    // Optional ssl CocoaMQTTDelegate
    func mqtt(_ mqtt: CocoaMQTT, didReceive trust: SecTrust, completionHandler: @escaping (Bool) -> Void) {
        TRACE("trust: \(trust)")
        /// Validate the server certificate
        ///
        /// Some custom validation...
        ///
        /// if validatePassed {
        ///     completionHandler(true)
        /// } else {
        ///     completionHandler(false)
        /// }
        completionHandler(true)
    }

    func mqtt(_ mqtt: CocoaMQTT, didConnectAck ack: CocoaMQTTConnAck) {
        TRACE("ack: \(ack)")

        if ack == .accept {
            
            for pozzo in pozzi{
                for tag in pozzo.tags{
                    let path = "/Pozzo \(pozzo.name)/Dati/\(tag.name)"
                    print("Sottoscrivo \(path)")
                    
                    mqtt.subscribe(path, qos: CocoaMQTTQoS.qos2)
                       
                   
                }
            }
           
        }
    }

    func mqtt(_ mqtt: CocoaMQTT, didStateChangeTo state: CocoaMQTTConnState) {
        TRACE("new state: \(state)")
    }

    func mqtt(_ mqtt: CocoaMQTT, didPublishMessage message: CocoaMQTTMessage, id: UInt16) {
        TRACE("message: , id: \(id)")
    }

    func mqtt(_ mqtt: CocoaMQTT, didPublishAck id: UInt16) {
        TRACE("id: \(id)")
    }

    func mqtt(_ mqtt: CocoaMQTT, didReceiveMessage message: CocoaMQTTMessage, id: UInt16 ) {
        TRACE("message: , id: \(id)")

        let name = NSNotification.Name(rawValue: "MQTTMessageNotification" )
        
        DispatchQueue.main.async {
            self.parse(payload: message.string ?? "")
        }
        
        
        
        NotificationCenter.default.post(name: name, object: self, userInfo: ["message": message.string!, "topic": message.topic, "id": id])
    }

    func mqtt(_ mqtt: CocoaMQTT, didSubscribeTopics success: NSDictionary, failed: [String]) {
        TRACE("subscribed: \(success), failed: \(failed)")
        guard success.count > 0 else {
            return
        }
        let key = success.allKeys[0] as? String
        if let key = key {
            let tag = self.mqttTag.filter({$0.mqttKey == key }).first
            if let tag = tag {
                tag.isSubscripted = true
            }
        }
        
        
    }

    func mqtt(_ mqtt: CocoaMQTT, didUnsubscribeTopics topics: [String]) {
        TRACE("topic: \(topics)")
    }

    func mqttDidPing(_ mqtt: CocoaMQTT) {
        TRACE("")
    }

    func mqttDidReceivePong(_ mqtt: CocoaMQTT) {
        TRACE("")
    }

    func mqttDidDisconnect(_ mqtt: CocoaMQTT, withError err: Error?) {
        TRACE("\(err?.localizedDescription)")
    }
}

func TRACE(_ message:String) -> Void {
    
    print(message)
}
