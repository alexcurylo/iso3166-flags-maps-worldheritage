// @copyright Trollwerks Inc.

import Foundation

struct TWHS: Codable {

    let name: String
    private let id_no: Int
    private let iso: String
    private let submitted: String
    private let category: String

    var siteID: Int {
        return id_no
    }

    var countries: String {
        guard !iso.isEmpty else {
            print("no countries for TWHS \(siteID): \(name)")
            return ""
        }
        return iso
    }

    static var sitelist: [TWHS] {
        return sitesFromJSON(file: "tentative") ??
            { assertionFailure("No TWHS sites!"); return [] }()
    }

    private static func sitesFromJSON(file: String) -> [TWHS]? {
        guard let path = Bundle.main.path(forResource: file, ofType: "json"),
            let data = try? Data(contentsOf: URL(fileURLWithPath: path)) else {
                return nil
        }

        do {
            let sites = try JSONDecoder().decode([TWHS].self, from: data)
            return sorted(array: sites)
        } catch DecodingError.dataCorrupted(let context) {
            print(context.debugDescription)
        } catch DecodingError.keyNotFound(let key, let context) {
            print("Key '\(key)' not Found")
            print("Debug Description:", context.debugDescription)
        } catch DecodingError.valueNotFound(let value, let context) {
            print("Value '\(value)' not Found")
            print("Debug Description:", context.debugDescription)
        } catch DecodingError.typeMismatch(let type, let context)  {
            print("Type '\(type)' mismatch")
            print("Debug Description:", context.debugDescription)
        } catch {
            print("error: ", error)
        }
        
        return nil
    }

    private static func sorted(array jsonArray: [TWHS]) -> [TWHS] {
        let array = jsonArray.sorted { (lhs, rhs) in
            lhs.name < rhs.name
        }

        // Should match http://whc.unesco.org/en/tentativelists/
        assert(array.count == 1695, "Should be 1695 TWHS on 2018.07.08")
        
        return array
    }
}
