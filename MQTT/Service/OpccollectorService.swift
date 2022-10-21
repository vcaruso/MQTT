//
//  OpccollectorService.swift
//  MQTT
//
//  Created by Vincenzo Caruso on 20/10/22.
//

import Foundation

class OpccollectorService: ObservableObject {
    
    @Published var pozzi: [Pozzo] = []
    
    private let url = "http://10.142.69.113/opccollector/RealTimes/tagsstatopompe"
    
    func getTags() async throws -> Void {
        
        let urlRequest = URLRequest(url: URL(string:url)!)
        do {
            let (data, response) = try await  URLSession.shared.data(for: urlRequest)
            
            guard (response as? HTTPURLResponse)?.statusCode == 200 else {
                return
            }
            await MainActor.run {
                self.pozzi = self.parseTag(fromCsv: data)
            }
            
        }
        catch{
            print(error.localizedDescription)
            throw error
        }
    
        
        
    }
    
    private func parseTag(fromCsv csv: Data) -> [Pozzo]{
        var dict: Dictionary<String,Pozzo> = [:]
        let csv = String(data: csv, encoding: .utf8)
        if let csv = csv {
            let lines = csv.components(separatedBy: "\r\n")
            guard lines.count > 1 else {
                let pzs = Array(dict.values)
                return pzs.sorted(by: {p1,p2 in p1.name < p2.name})
            }
            
            for index in 1..<lines.count {
                
                let rawTag = lines[index].components(separatedBy: ";")
                
                guard rawTag.count == 7 else {
                    let pzs = Array(dict.values)
                    return pzs.sorted(by: {p1,p2 in p1.name < p2.name})
                }
                let pompa = rawTag[0].replacingOccurrences(of: "\"", with: "")
                //print("processo \(pompa)")
                let tag = rawTag[1].replacingOccurrences(of: "\"", with: "")
                let tagId = Int(rawTag[2])
                let pompaAcqua = Int(rawTag[3])
                let ottimizzato = Double(rawTag[4])
                let um = rawTag[5].replacingOccurrences(of: "\"", with: "")
                let synid = rawTag[6]
                if let tagId = tagId {
                    if let _ = dict[pompa]{
                        dict[pompa]?.tags.append(Tag(name: tag, engUnt: um, tagId: tagId))
                       
                    } else {
                        dict[pompa] = Pozzo(name: pompa, tags: [
                            Tag(name: tag, engUnt: um, tagId: tagId)
                        ])
                    }
                }
                
                
                
            }
            let pzs = Array(dict.values)
            return pzs.sorted(by: {p1,p2 in p1.name < p2.name})
        }
        return []
    }
    
    
}
