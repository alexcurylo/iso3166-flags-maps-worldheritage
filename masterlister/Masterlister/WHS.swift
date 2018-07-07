// @copyright Trollwerks Inc.

import Foundation

struct WHS: Codable {

    let iso_code: String?
    // XLS fields
    let id_no: String?
    let name_en: String?
    // XML fields
    let id_number: String?
    let site: String?

    var siteID: Int {
        guard let idString = id_number ?? id_no,
              let id = Int(idString) else {
            assertionFailure("no valid WHS ID field")
            return 0
        }
        return id
    }
    var name: String {
        guard let name = site ?? name_en  else {
            assertionFailure("no valid WHS name field")
            return "<unknown>"
        }
        return name
    }
    var countries: String {
        guard let iso_code = iso_code, !iso_code.isEmpty else {
            // expected for 148: Old City of Jerusalem and its Walls
            //print("no countries for \(siteID): \(name)")
            return ""
        }
        return iso_code
    }

    static var sitelist: [WHS] {
        return sitesFromJSON(file: "whc-en") ??
               sitesFromXLS(file: "whc-sites-2017") ??
               { assertionFailure("No sites!"); return [] }()
    }

    static func sitesFromJSON(file: String) -> [WHS]? {
        guard let path = Bundle.main.path(forResource: file, ofType: "json"),
            let data = try? Data(contentsOf: URL(fileURLWithPath: path)) else {
                return nil
        }

        do {
            let whsFile = try JSONDecoder().decode(WHSFile.self, from: data)
            let sites = whsFile.query.sites
            assert(sites.count == Int(whsFile.query.rows), "Inconsistent WHS count and rows")
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

    static func sitesFromXLS(file: String) -> [WHS]? {
        guard let path = Bundle.main.path(forResource: file, ofType: "json"),
              let data = try? Data(contentsOf: URL(fileURLWithPath: path)),
              let jsonArray = try? JSONDecoder().decode([WHS].self, from: data) else {
            return nil
        }

        return sorted(array: jsonArray)
    }

    static func sorted(array jsonArray: [WHS]) -> [WHS] {
        let array = jsonArray.sorted { (lhs, rhs) in
            lhs.name < rhs.name
        }
        assert(array.count == 1092, "Should be 1092 WHS in 2018")
        return array
    }
}

struct WHSFile: Codable {
    
    struct Query: Codable {

        let rows: String
        let columns: String
        let sites: [WHS]
 
        enum CodingKeys: String, CodingKey {
            case rows = "@rows"
            case columns = "@columns"
            case sites = "row"
        }
    }

    let query: Query
}
