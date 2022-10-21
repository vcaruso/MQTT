//
//  TagView.swift
//  MQTT
//
//  Created by Vincenzo Caruso on 20/10/22.
//

import SwiftUI

struct TagView: View {
    @EnvironmentObject var mqttPozzi: MqttPozzi
    var pozzo: [Pozzo]
        
    var body: some View {
    
        List{
            ForEach(mqttPozzi.mqttTag, id:\.tagId){ tag in
                VStack(alignment:.leading){
                    Text("\(tag.timeStamp?.formatted() ?? "")")
                    Text("\(tag.value ?? 0) - \(tag.mqttKey ?? "")")
                }
            }
        }.onAppear(){
            mqttPozzi.subscribe(pozzi: pozzo)
        }
        
    }
}

struct TagView_Previews: PreviewProvider {
    static var previews: some View {
        TagView(pozzo: [])
    }
}
