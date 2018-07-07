// @copyright Trollwerks Inc.

import Foundation

// NB whc-en has other fields:
// historical_description, long_description
// "http_url": "http://whc.unesco.org/en/list/208",
// "image_url": "http://whc.unesco.org/uploads/sites/site_208.jpg",
struct WHS: Codable {
    let id_no: String
    let iso_code: String
    let category: String
    let region_en: String
    let date_inscribed: String
    let name_en: String
    let short_description_en: String
    let justification_en: String
    
    var id: Int {
        return Int(id_no) ?? 0
    }

    static var sitelist: [WHS] {
        return sitesFromXLS(file: "whc-sites-2017")
    }

    static func sitesFromXLS(file: String) -> [WHS]? {
        guard let path = Bundle.main.path(forResource: file, ofType: "json"),
              let data = try? Data(contentsOf: URL(fileURLWithPath: path)),
              let jsonArray = try? JSONDecoder().decode([WHS].self, from: data) else {
            return nil
        }
        let array = jsonArray.sorted { (lhs, rhs) in
            lhs.name_en < rhs.name_en
        }
        assert(array.count == 1073, "Should be 1073 WHS in 2017")
        return array
    }
}
