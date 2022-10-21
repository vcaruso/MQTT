//
//  ContentView.swift
//  MQTT
//
//  Created by Vincenzo Caruso on 19/10/22.
//

import SwiftUI

struct ContentView: View {
    
    @StateObject var service = OpccollectorService()
    @StateObject var mqttPozzi = MqttPozzi()
    
    
    var body: some View {
        NavigationStack{
            List{
                ForEach(service.pozzi, id:\.name) { pozzo in
                    NavigationLink {
                        TagView(pozzo: [pozzo]).environmentObject(mqttPozzi)
                    } label: {
                        /*@START_MENU_TOKEN@*/Text(pozzo.name)/*@END_MENU_TOKEN@*/
                    }
                    
                    
                }
            }
            
        }
        .onAppear(){
            Task {
                try? await service.getTags()
                
                
                
            }
            
        }
        .padding()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
