//
//  ViewController.swift
//  Masterlister
//
//  Created by Curylo, Alex (Agoda) on 7/20/17.
//  Copyright © 2017 Trollwerks Inc. All rights reserved.
//

import Cocoa

class WonderlistVC: NSViewController {

    enum Visited: String {
        case yes = "✅"
        case no = "◻️"
    }

    enum Document {
        case html
        case wordpress
    }

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
            let data = try Data(contentsOf: URL(fileURLWithPath: path!))
            array = try JSONDecoder().decode([Wonders].self, from: data)
        } catch let jsonErr {
            print("Error decoding new7wonders.json", jsonErr)
        }
        assert(array.count == 3, "Should be 3 collections in 2018")
        wondersCount = array.reduce(0) { $0 + $1.wonders.count }
        finalistsCount = array.reduce(0) { $0 + $1.finalists.count }
        assert(wondersCount == 7 + 7 + 7, "Should be 21 wonders in 2018")
        assert(finalistsCount == 14 + 21 + 21, "Should be 56 finalists in 2018")
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
            let data = try Data(contentsOf: URL(fileURLWithPath: path!))
            array = try JSONDecoder().decode([Visit].self, from: data)
        } catch let jsonErr {
            print("Error decoding visits", jsonErr)
        }
        let wonderVisits = array.compactMap({$0.wonder})
        assert(wondersCount == 7 + 7 + 7, "Should be 21 wonders in 2018")
        assert(finalistsCount == 14 + 21 + 21, "Should be 56 finalists in 2018")
        return array
    }()

    @IBOutlet var output: NSTextView!
    
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
            
            <p>Wonders are in plain text<br />
            <i>Finalists are in italic text</i></p>
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

        for wonder in wonders {
            let link = """
                <a href="\(wonder.url)">\(wonder.title)</a>
                """

            var mark = Visited.no.rawValue
            var visitLink = ""
            var stayLink = ""
            var eatLink = ""
            if let visited = visits.first(where: { $0.wonder == wonder.id }) {
                if wonder.isWonder {
                    wondersVisited = wondersVisited + 1
                } else {
                    finalistsVisited = finalistsVisited + 1
                }
                mark = Visited.yes.rawValue
                if let visitURL = visited.visit {
                    visitLink = " — <a href=\"\(visitURL)\">Visit</a>"
                }
                if let stayURL = visited.stay {
                    stayLink = " — <a href=\"\(stayURL)\">Stay</a>"
                }
                if let eatURL = visited.eat {
                    eatLink = " — <a href=\"\(eatURL)\">Eat</a>"
                }
            }
            let wonderLine = NSAttributedString(string: "\(mark) \(link)\(visitLink)\(stayLink)\(eatLink)<br />\n")
            output.textStorage?.append(wonderLine)
        }

        let wondersEnd = NSAttributedString(string: (inItalic ? "</i>" : "") + "</p>")
        output.textStorage?.append(wondersEnd)
    }

    func writeFooter(for type: Document) {
        assert(wondersVisited == 16, "Should be 16 wonders visited (2018.05.05)")
        assert(finalistsVisited == 40, "Should be 40 finalists visited (2018.05.05)")

        let wondersPercent = String(format: "%.1f", Float(wondersVisited) / Float(wondersCount) * 100)
        let finalistsPercent = String(format: "%.1f", Float(finalistsVisited) / Float(finalistsCount) * 100)

        let total = wondersCount + finalistsCount
        let totalVisits = wondersVisited + finalistsVisited
        let totalPercent = String(format: "%.1f", Float(totalVisits) / Float(total) * 100)
        let textFooter = NSAttributedString(string: """
            <p dir="ltr">Wonders: \(wondersVisited)/\(wondersCount) (\(wondersPercent)%) — Finalists: \(finalistsVisited)/\(finalistsCount) (\(finalistsPercent)%) — TOTAL: \(totalVisits)/\(total) (\(totalPercent)%)</p>\n
            """)
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

