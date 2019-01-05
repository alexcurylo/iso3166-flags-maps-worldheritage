// @copyright Trollwerks Inc.

import Cocoa

final class WonderlistVC: NSViewController {

    struct Wonder: Codable {
        let id: Int // expect owner ID + 1...7 for wonders, 8... for finalists
        let title: String
        let url: URL
        let whs: Int?
        let twhs: Int?
        let link: URL?

        var isWonder: Bool { return (id % 100) <= 7 }
        var isFinalist: Bool { return !isWonder }
    }

    struct Wonders: Codable {
        let id: Int // expect [100, 200, 300, ...] to combine with wonder ID
        let title: String
        let url: URL
        let wonders: [Wonder]
        let finalists: [Wonder]

        var total: Int {
            return wonders.count + finalists.count
        }
    }

    var wondersCount = 0
    var finalistsCount = 0
    lazy var wondersList: [Wonders] = {
        let path = Bundle.main.path(forResource: "new7wonders", ofType: "json")
        var array: [Wonders] = []
        do {
            // swiftlint:disable:next force_unwrapping
            let data = try Data(contentsOf: URL(fileURLWithPath: path!))
            array = try JSONDecoder().decode([Wonders].self, from: data)
        } catch {
            print("Error decoding new7wonders.json", error)
        }

        assert(array.count == 3, "Should be 3 collections in 2018")
        wondersCount = array.reduce(0) { $0 + $1.wonders.count }
        finalistsCount = array.reduce(0) { $0 + $1.finalists.count }
        assert(wondersCount == 7 + 7 + 7, "Should be 21 wonders in 2018")
        assert(finalistsCount == 14 + 21 + 21, "Should be 56 finalists in 2018")
        let wondersIDs = array.map { $0.id }
        assert(Set(wondersIDs).count == array.count, "Should not have duplicate Wonders IDs")
        let wonderList: [Wonder] = array.reduce([]) { $0 + $1.wonders + $1.finalists }
        let wonderIDs = wonderList.map { $0.id }
        assert(Set(wonderIDs).count == wonderList.count, "Should not have duplicate Wonder IDs")

        return array
    }()

    struct Visit: Codable {
        let wonder: Int?
        let whs: Int?
        let twhs: Int?
        let visit: URL?
        let stay: URL?
        let eat: URL?
    }

    lazy var visits: [Visit] = {
        let path = Bundle.main.path(forResource: "visits", ofType: "json")
        var array: [Visit] = []
        do {
            // swiftlint:disable:next force_unwrapping
            let data = try Data(contentsOf: URL(fileURLWithPath: path!))
            array = try JSONDecoder().decode([Visit].self, from: data)
        } catch {
            print("Error decoding visits", error)
        }

        let ids = array.compactMap { $0.wonder }
        let duplicates = Array(Set(ids.filter { (i: Int) in ids.filter { $0 == i }.count > 1 }))
        assert(duplicates.isEmpty, "Should not have duplicate Wonder visits \(duplicates)")
        let wonderList: [Wonder] = wondersList.reduce([]) { $0 + $1.wonders + $1.finalists }
        let wonderIDs = wonderList.map { $0.id }
        let wrong = Set(ids).subtracting(wonderIDs)
        assert(wrong.isEmpty, "Should not have wrong Wonder visits \(wrong)")

        return array
    }()

    @IBOutlet private var output: NSTextView!

    var wondersVisited = 0
    var finalistsVisited = 0

    override func viewDidLoad() {
        super.viewDidLoad()

        generate(for: .wordpress)
    }

    override var representedObject: Any? {
        didSet {
            // Update the view, if already loaded.
        }
    }

    func generate(for type: Document) {
        writeHeader(for: type)
        writeWondersList()
        writeFooter(for: type)
    }

    func writeHeader(for type: Document) {
        if type == .html {
            let htmlHeader = NSAttributedString(string: """
                <!DOCTYPE html>
                <html lang="en">
                    <head>
                        <meta charset="UTF-8">
                            <title>Sitelist</title>
                    </head>
                    <body>\n
                """)
            output.textStorage?.append(htmlHeader)
        }

        let textHeader = NSAttributedString(string: """
            <p dir="ltr"><strong>The <a href="https://new7wonders.com">New7Wonders</a> Master Wonderlist</strong></p>

            <p><small>Wonders are in plain text<br />
            <i>Finalists are in italic text</i></small></p>
            \n
            """)
        output.textStorage?.append(textHeader)
    }

    func writeWondersList() {
        for wonders in wondersList {
            let listStart = NSAttributedString(string: """
                <p dir="ltr"><strong><a href="\(wonders.url)">\(wonders.title)</a>:</strong></p>
                """)
            output.textStorage?.append(listStart)

            writeWonders(in: wonders.wonders)
            writeWonders(in: wonders.finalists)

            let listEnd = NSAttributedString(string: """
                \n\n
                """)
            output.textStorage?.append(listEnd)
        }
    }

    func writeWonders(in wonders: [Wonder]) {
        guard let inItalic = wonders.first?.isFinalist else { return }

        let wondersStart = NSAttributedString(string: "<p dir=\"ltr\">" + (inItalic ? "<i>" : ""))
        output.textStorage?.append(wondersStart)

        let sortedWonders = wonders.sorted { $0.title < $1.title }
        for wonder in sortedWonders {
            let link = """
            <a href="\(wonder.url)">\(wonder.title)</a>
            """

            var mark = Visited.no.rawValue
            var blogLinks = ""
            if let visited = visits.first(where: { $0.wonder == wonder.id }) {
                if wonder.isWonder {
                    wondersVisited += 1
                } else {
                    finalistsVisited += 1
                }

                mark = Visited.yes.rawValue

                var visitLink = ""
                var stayLink = ""
                var eatLink = ""
                if let visitURL = visited.visit {
                    visitLink = " — <a href=\"\(visitURL)\">Visit</a>"
                }
                if let stayURL = visited.stay {
                    stayLink = " — <a href=\"\(stayURL)\">Stay</a>"
                }
                if let eatURL = visited.eat {
                    eatLink = " — <a href=\"\(eatURL)\">Eat</a>"
                }
                if !visitLink.isEmpty || !stayLink.isEmpty || !eatLink.isEmpty {
                    blogLinks = "<small>\(visitLink)\(stayLink)\(eatLink)</small>"
                }
            }
            let wonderLine = NSAttributedString(string: "\(mark) \(link)\(blogLinks)<br />\n")
            output.textStorage?.append(wonderLine)
        }

        let wondersEnd = NSAttributedString(string: (inItalic ? "</i>" : "") + "</p>")
        output.textStorage?.append(wondersEnd)
    }

    func writeFooter(for type: Document) {
        assert(wondersVisited == 16, "Should be 16 wonders visited (2018.05.05)")
        assert(finalistsVisited == 42, "Should be 42 finalists visited (2019.01.05)")

        let wondersPercent = String(format: "%.1f", Float(wondersVisited) / Float(wondersCount) * 100)
        let finalistsPercent = String(format: "%.1f", Float(finalistsVisited) / Float(finalistsCount) * 100)

        let total = wondersCount + finalistsCount
        let totalVisits = wondersVisited + finalistsVisited
        let totalPercent = String(format: "%.1f", Float(totalVisits) / Float(total) * 100)
        // swiftlint:disable line_length
        let textFooter = NSAttributedString(string: """
            <p dir="ltr"><small>Wonders: \(wondersVisited)/\(wondersCount) (\(wondersPercent)%) — Finalists: \(finalistsVisited)/\(finalistsCount) (\(finalistsPercent)%) — TOTAL: \(totalVisits)/\(total) (\(totalPercent)%)</small></p>\n
            """)
        // swiftlint:enable line_length
        output.textStorage?.append(textFooter)

        if type == .html {
            let htmlFooter = NSAttributedString(string: """
                    </body>
                </html>
                """)
            output.textStorage?.append(htmlFooter)
        }
    }
}
