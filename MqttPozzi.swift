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
    
    @Published var tagId: Int?
    @Published var timeStamp: Date?
    @Published var register: String?
    @Published var quality: Int?
    @Published var value: Double?
    
    var mqtt: CocoaMQTT?
    
    init(){
        let clientID = "CocoaMQTT-Pozzi" + String(ProcessInfo().processIdentifier)
        let websocket = CocoaMQTTWebSocket(uri: "/mqtt")
        mqtt = CocoaMQTT(clientID: clientID, host: "10.142.69.113", port: 1884, socket: websocket)
        if let mqtt = mqtt {
            mqtt.username = ""
            mqtt.password = ""
            mqtt.willMessage = CocoaMQTTMessage(topic: "/will", string: "dieout")
            mqtt.keepAlive = 60
            mqtt.delegate = self
            mqtt.logLevel = .off
            mqtt.connect()
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
        self.tagId = Int(values[0])
        self.register = values[1]
        self.value = Double(values[2])
        let seconds =  Double(values[3])!
        self.timeStamp = Date.init(timeIntervalSince1970: seconds - 120*60)
        self.quality = Int(values[4])
        
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
            mqtt.subscribe("/Pozzo BV1/Dati/ITBV1FI1", qos: CocoaMQTTQoS.qos1)
            
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
        self.parse(payload: message.string ?? "")
        NotificationCenter.default.post(name: name, object: self, userInfo: ["message": message.string!, "topic": message.topic, "id": id])
    }

    func mqtt(_ mqtt: CocoaMQTT, didSubscribeTopics success: NSDictionary, failed: [String]) {
        TRACE("subscribed: \(success), failed: \(failed)")
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
