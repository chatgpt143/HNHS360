import SwiftUI
import AppKit
import WebKit
import JavaScriptCore
import PDFKit

struct SchoolSettings: Codable, Equatable {
    var schoolName = ""
    var schoolId = ""
    var schoolHead = ""
    var schoolHeadPosition = ""
    var district = ""
    var division = "Bukidnon"
    var region = "Region X - Northern Mindanao"
    var schoolYear = "2026-2027"
    var gradeLevel = ""
    var section = ""
    var adviser = ""
    var assessmentTool = "CRLA"
    var subject = "ENGLISH"
}

struct PreAssessment: Codable, Equatable {
    var level = ""
    var bosy = ""
    var mosy = ""
    var eosy = ""
}

struct AssessmentEntry: Codable, Equatable {
    var result = ""
    var overrideLevel = ""
    var note = ""

    enum CodingKeys: String, CodingKey {
        case result, overrideLevel, note
    }

    init(result: String = "", overrideLevel: String = "", note: String = "") {
        self.result = result
        self.overrideLevel = overrideLevel
        self.note = note
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        result = try c.decodeIfPresent(String.self, forKey: .result) ?? ""
        overrideLevel = try c.decodeIfPresent(String.self, forKey: .overrideLevel) ?? ""
        note = try c.decodeIfPresent(String.self, forKey: .note) ?? ""
    }
}

struct Learner: Identifiable, Codable, Equatable {
    var id = UUID()
    var lrn = ""
    var fullName = ""
    var firstName = ""
    var middleInitial = ""
    var lastName = ""
    var nameExtension = ""
    var sex = ""
    var dateOfBirth = ""
    var pre = PreAssessment()
    var preHistory: [String: PreAssessment] = [:]
    var assessments: [String: AssessmentEntry] = [:]

    enum CodingKeys: String, CodingKey {
        case id, lrn, fullName, firstName, middleInitial, lastName, nameExtension, sex, dateOfBirth, pre, preHistory, assessments
    }

    init(
        id: UUID = UUID(),
        lrn: String = "",
        fullName: String = "",
        firstName: String = "",
        middleInitial: String = "",
        lastName: String = "",
        nameExtension: String = "",
        sex: String = "",
        dateOfBirth: String = "",
        pre: PreAssessment = PreAssessment(),
        preHistory: [String: PreAssessment] = [:],
        assessments: [String: AssessmentEntry] = [:]
    ) {
        self.id = id
        self.lrn = lrn
        self.fullName = fullName
        self.firstName = firstName
        self.middleInitial = middleInitial
        self.lastName = lastName
        self.nameExtension = nameExtension
        self.sex = sex
        self.dateOfBirth = dateOfBirth
        self.pre = pre
        self.preHistory = preHistory
        self.assessments = assessments
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        lrn = try c.decodeIfPresent(String.self, forKey: .lrn) ?? ""
        fullName = try c.decodeIfPresent(String.self, forKey: .fullName) ?? ""
        firstName = try c.decodeIfPresent(String.self, forKey: .firstName) ?? ""
        middleInitial = try c.decodeIfPresent(String.self, forKey: .middleInitial) ?? ""
        lastName = try c.decodeIfPresent(String.self, forKey: .lastName) ?? ""
        nameExtension = try c.decodeIfPresent(String.self, forKey: .nameExtension) ?? ""
        sex = try c.decodeIfPresent(String.self, forKey: .sex) ?? ""
        dateOfBirth = try c.decodeIfPresent(String.self, forKey: .dateOfBirth) ?? ""
        pre = try c.decodeIfPresent(PreAssessment.self, forKey: .pre) ?? PreAssessment()
        preHistory = try c.decodeIfPresent([String: PreAssessment].self, forKey: .preHistory) ?? [:]
        assessments = try c.decodeIfPresent([String: AssessmentEntry].self, forKey: .assessments) ?? [:]
    }

    var displayName: String {
        let mi = middleInitial.trimmingCharacters(in: .whitespacesAndNewlines)
        let ext = nameExtension.trimmingCharacters(in: .whitespacesAndNewlines)
        if !lastName.isEmpty || !firstName.isEmpty {
            var pieces: [String] = []
            if !lastName.isEmpty { pieces.append(lastName.uppercased() + ",") }
            if !firstName.isEmpty { pieces.append(firstName.uppercased()) }
            if !mi.isEmpty { pieces.append(String(mi.uppercased().prefix(1)) + ".") }
            if !ext.isEmpty { pieces.append(ext.uppercased()) }
            return pieces.joined(separator: " ")
        }
        return fullName
    }
}

struct AppData: Codable, Equatable {
    var settings = SchoolSettings()
    var assessmentTerms: [String: String] = ["PRETEST": "1ST"]
        .merging(Dictionary(uniqueKeysWithValues: (1...15).map { ("AP\($0)", "1ST") })) { current, _ in current }
    var learners: [Learner] = []
}

struct ReadingLevel: Identifiable, Hashable {
    var id: String { code }
    let code: String
    let label: String
    let area: String
}

let readingLevels: [ReadingLevel] = [
    .init(code: "LEVEL 1", label: "Orientation to Print", area: "ORAL LANGUAGE"),
    .init(code: "LEVEL 2A", label: "Letter and Initial Sound", area: "PHONOLOGICAL AWARENESS"),
    .init(code: "LEVEL 2B", label: "Letter and Initial Sound", area: "PHONOLOGICAL AWARENESS"),
    .init(code: "LEVEL 3A", label: "Letter Name Knowledge", area: "WORD RECOGNITION"),
    .init(code: "LEVEL 3B", label: "Letter Name Knowledge", area: "WORD RECOGNITION"),
    .init(code: "LEVEL 4", label: "Invented Word Reading", area: "FLUENCY"),
    .init(code: "LEVEL 5", label: "Familiar Word Reading", area: "VOCABULARY AND LISTENING COMPREHENSION"),
    .init(code: "LEVEL 6", label: "Listening Comprehension", area: "GRADED READING COMPREHENSION"),
    .init(code: "LEVEL 7", label: "Dictation", area: "GENUINE LOVE FOR READING AND WRITING")
]

let assessmentPeriods = (1...15).map { "AP\($0)" }
let terms = ["1ST", "2ND", "3RD", "4TH", "SUMMER"]
let results = ["", "READY", "NOT READY", "REVERTED", "NLS", "NLP", "TRANSFER OUT"]
let preAssessmentPeriods = ["BOSY", "MOSY", "EOSY"]

struct SF1ParsedSheet: Decodable {
    let name: String
    let rows: [[String]]
}

enum SF1ImportError: LocalizedError {
    case parserMissing
    case javascript(String)
    case noSF1Sheet
    case unreadable

    var errorDescription: String? {
        switch self {
        case .parserMissing:
            return "The SF1 spreadsheet reader is missing from this app build."
        case .javascript(let message):
            return "The SF1 file could not be read. \(message)"
        case .noSF1Sheet:
            return "No SF1 table with LRN, NAME, Sex, and BIRTH DATE columns was found."
        case .unreadable:
            return "The selected SF1 file could not be opened."
        }
    }
}

enum PrintoutType: String, CaseIterable, Identifiable {
    case classroomMonitoring = "Classroom Reading Monitoring Report"
    case pupilList = "List of Pupils"
    var id: String { rawValue }
}

func reportLevelColor(_ level: String) -> NSColor {
    switch level {
    case "LEVEL 1": return NSColor(calibratedRed: 1.0, green: 0.84, blue: 0.82, alpha: 1)
    case "LEVEL 2A": return NSColor(calibratedRed: 1.0, green: 0.90, blue: 0.72, alpha: 1)
    case "LEVEL 2B": return NSColor(calibratedRed: 1.0, green: 0.94, blue: 0.66, alpha: 1)
    case "LEVEL 3A": return NSColor(calibratedRed: 0.88, green: 0.95, blue: 0.72, alpha: 1)
    case "LEVEL 3B": return NSColor(calibratedRed: 0.79, green: 0.93, blue: 0.76, alpha: 1)
    case "LEVEL 4": return NSColor(calibratedRed: 0.75, green: 0.91, blue: 0.94, alpha: 1)
    case "LEVEL 5": return NSColor(calibratedRed: 0.80, green: 0.86, blue: 0.97, alpha: 1)
    case "LEVEL 6": return NSColor(calibratedRed: 0.84, green: 0.81, blue: 0.96, alpha: 1)
    case "LEVEL 7": return NSColor(calibratedRed: 0.92, green: 0.82, blue: 0.95, alpha: 1)
    default: return .white
    }
}


struct NativeCRMLevelRow {
    let level: String
    let area: String
    let male: Int
    let female: Int
    let total: Int
}

struct NativeProfileRow {
    let label: String
    let bosyMale: Int
    let bosyFemale: Int
    let mosyMale: Int
    let mosyFemale: Int
    let eosyMale: Int
    let eosyFemale: Int
}

struct NativePupilRow {
    let name: String
    let sex: String
    let area: String
    let level: String
}

struct NativeReportSnapshot {
    let settings: SchoolSettings
    let stage: String
    let term: String
    let keyStage: Int
    let crmRows: [NativeCRMLevelRow]
    let profileRows: [NativeProfileRow]
    let bosyTotal: Int
    let mosyTotal: Int
    let eosyTotal: Int
    let pupils: [NativePupilRow]
    let maleCount: Int
    let femaleCount: Int
    let generatedAt: String
}

final class NativeReportView: NSView {
    let type: PrintoutType
    let snapshot: NativeReportSnapshot
    let paperSize: NSSize
    let pageCount: Int
    private let pupilPageCounts: [Int]

    private let leftMargin: CGFloat = 72      // 1 inch
    private let rightMargin: CGFloat = 72     // 1 inch
    private let topMargin: CGFloat = 36       // 0.5 inch
    private let bottomMargin: CGFloat = 36    // 0.5 inch

    init(type: PrintoutType, snapshot: NativeReportSnapshot) {
        self.type = type
        self.snapshot = snapshot

        if type == .classroomMonitoring {
            self.paperSize = NSSize(width: 841.89, height: 595.28)
            self.pupilPageCounts = []
            self.pageCount = 1
        } else {
            self.paperSize = NSSize(width: 595.28, height: 841.89)
            let entryCount = snapshot.pupils.count + 2 // Male/Female group rows
            let counts = NativeReportView.makePupilPageCounts(entryCount: entryCount)
            self.pupilPageCounts = counts
            self.pageCount = max(1, counts.count)
        }

        super.init(frame: NSRect(
            x: 0,
            y: 0,
            width: paperSize.width,
            height: paperSize.height * CGFloat(pageCount)
        ))
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var isFlipped: Bool { true }

    private static func makePupilPageCounts(entryCount: Int) -> [Int] {
        guard entryCount > 0 else { return [0] }

        // With header + totals + signatures, 17 entries fit on one A4 portrait page.
        if entryCount <= 17 { return [entryCount] }

        // First page has the full report header. Continuation pages do not.
        // Capacities: first 22, middle 30, last 26 (last reserves totals/signatures).
        let pageCount: Int
        if entryCount <= 48 {
            pageCount = 2
        } else {
            pageCount = 2 + Int(ceil(Double(entryCount - 48) / 30.0))
        }

        var capacities: [Int] = []
        for i in 0..<pageCount {
            if i == 0 { capacities.append(22) }
            else if i == pageCount - 1 { capacities.append(26) }
            else { capacities.append(30) }
        }

        // Balance rows across pages so no continuation page has a huge empty lower area.
        var remaining = entryCount
        var counts: [Int] = []
        for i in 0..<pageCount {
            let pagesLeft = pageCount - i
            let balancedTarget = Int(ceil(Double(remaining) / Double(pagesLeft)))
            let value = min(capacities[i], balancedTarget)
            counts.append(value)
            remaining -= value
        }

        // If the balancing pass left rows because an earlier page hit its cap,
        // distribute them to pages that still have capacity.
        var i = pageCount - 1
        while remaining > 0 {
            if counts[i] < capacities[i] {
                counts[i] += 1
                remaining -= 1
            }
            i -= 1
            if i < 0 { i = pageCount - 1 }
        }
        return counts
    }

    private func font(_ size: CGFloat, bold: Bool = false) -> NSFont {
        let name = bold ? "Arial-BoldMT" : "Arial"
        return NSFont(name: name, size: size) ?? (bold ? .boldSystemFont(ofSize: size) : .systemFont(ofSize: size))
    }

    private func paragraph(_ alignment: NSTextAlignment) -> NSMutableParagraphStyle {
        let p = NSMutableParagraphStyle()
        p.alignment = alignment
        p.lineBreakMode = .byWordWrapping
        return p
    }

    private func drawText(
        _ text: String,
        in rect: NSRect,
        size: CGFloat = 12,
        bold: Bool = false,
        alignment: NSTextAlignment = .left,
        color: NSColor = .black,
        verticalCenter: Bool = true
    ) {
        let attrs: [NSAttributedString.Key: Any] = [
            .font: font(size, bold: bold),
            .foregroundColor: color,
            .paragraphStyle: paragraph(alignment)
        ]
        let str = NSAttributedString(string: text, attributes: attrs)
        let options: NSString.DrawingOptions = [.usesLineFragmentOrigin, .usesFontLeading]
        let measured = str.boundingRect(
            with: NSSize(width: rect.width, height: .greatestFiniteMagnitude),
            options: options
        )
        let y = verticalCenter ? rect.minY + max(0, (rect.height - measured.height) / 2) : rect.minY
        str.draw(
            with: NSRect(x: rect.minX, y: y, width: rect.width, height: max(rect.height, measured.height)),
            options: options
        )
    }

    private func stroke(_ rect: NSRect, width: CGFloat = 1.0) {
        NSColor.black.setStroke()
        let path = NSBezierPath(rect: rect)
        path.lineWidth = width
        path.stroke()
    }

    private func fill(_ rect: NSRect, color: NSColor) {
        color.setFill()
        NSBezierPath(rect: rect).fill()
    }

    private func cell(
        _ text: String,
        rect: NSRect,
        fillColor: NSColor? = nil,
        bold: Bool = false,
        alignment: NSTextAlignment = .center,
        size: CGFloat = 12,
        borderWidth: CGFloat = 1.0
    ) {
        if let fillColor { fill(rect, color: fillColor) }
        stroke(rect, width: borderWidth)
        if !text.isEmpty {
            drawText(text, in: rect.insetBy(dx: 3, dy: 2), size: size, bold: bold, alignment: alignment)
        }
    }

    private func drawImage(resource: String, ext: String, in rect: NSRect) {
        guard let url = Bundle.main.url(forResource: resource, withExtension: ext),
              let image = NSImage(contentsOf: url) else { return }

        let imageSize = image.size
        guard imageSize.width > 0, imageSize.height > 0 else { return }
        let scale = min(rect.width / imageSize.width, rect.height / imageSize.height)
        let drawSize = NSSize(width: imageSize.width * scale, height: imageSize.height * scale)
        let drawRect = NSRect(
            x: rect.midX - drawSize.width / 2,
            y: rect.midY - drawSize.height / 2,
            width: drawSize.width,
            height: drawSize.height
        )
        image.draw(
            in: drawRect,
            from: .zero,
            operation: .sourceOver,
            fraction: 1,
            respectFlipped: true,
            hints: nil
        )
    }

    private func drawHeader(pageOriginY: CGFloat, title: String) -> CGFloat {
        let x = leftMargin
        let w = paperSize.width - leftMargin - rightMargin
        var y = pageOriginY + topMargin

        // Match the Excel template: Department of Education is centered
        // independently across the printable page. Logos sit below it on
        // the left and right and never shift the center headings.
        drawText(
            "Department of Education",
            in: NSRect(x: x, y: y, width: w, height: 17),
            size: 12,
            alignment: .center
        )
        y += 18

        let landscape = paperSize.width > paperSize.height
        let logoBandH: CGFloat = landscape ? 74 : 68
        let sealSize: CGFloat = landscape ? 78 : 68
        let buligW: CGFloat = landscape ? 190 : 150
        let buligH: CGFloat = landscape ? 72 : 58

        drawImage(
            resource: "DepEdBukidnonSeal",
            ext: "jpg",
            in: NSRect(
                x: x + (landscape ? 18 : 8),
                y: y + (logoBandH - sealSize) / 2,
                width: sealSize,
                height: sealSize
            )
        )

        drawImage(
            resource: "ReportBuligLogo",
            ext: "jpg",
            in: NSRect(
                x: x + w - buligW - (landscape ? 10 : 2),
                y: y + (logoBandH - buligH) / 2,
                width: buligW,
                height: buligH
            )
        )
        y += logoBandH

        drawText(
            "BUKIDNON'S UNIFIED LITERACY AND INTERVENTION GATEWAY",
            in: NSRect(x: x, y: y, width: w, height: 16),
            size: landscape ? 12 : 10.5,
            bold: true,
            alignment: .center
        )
        y += 16

        drawText(
            "Building Up Literacy, Inspiring Growth",
            in: NSRect(x: x, y: y, width: w, height: 15),
            size: landscape ? 11.5 : 10.5,
            bold: true,
            alignment: .center
        )
        y += 15

        drawText(
            title,
            in: NSRect(x: x, y: y, width: w, height: 22),
            size: landscape ? 15 : 14,
            bold: true,
            alignment: .center
        )
        y += 25

        let rowH: CGFloat = landscape ? 22 : 24
        let widths = [w * 0.18, w * 0.32, w * 0.20, w * 0.30]
        let rows: [[String]] = [
            ["Adviser", snapshot.settings.adviser, "ASSESSMENT\nPERIOD", snapshot.stage],
            ["Grade Level", snapshot.settings.gradeLevel, "Term", snapshot.term],
            ["Section", snapshot.settings.section, "Assessment Tool", snapshot.settings.assessmentTool],
            ["", "", "SUBJECT", snapshot.settings.subject]
        ]

        for r in rows {
            var cx = x
            for i in 0..<4 {
                let isLabel = i == 0 || i == 2
                cell(
                    r[i],
                    rect: NSRect(x: cx, y: y, width: widths[i], height: rowH),
                    bold: isLabel,
                    alignment: isLabel ? .center : .left,
                    size: isLabel ? 10.2 : 12,
                    borderWidth: 1.1
                )
                cx += widths[i]
            }
            y += rowH
        }

        return y
    }

    private func drawSignatureBlock(
        pageY: CGFloat,
        y requestedY: CGFloat,
        x: CGFloat,
        width: CGFloat,
        includeDate: Bool
    ) {
        let sigW = (width - 30) / 2
        let blockHeight: CGFloat = 72
        let maxY = pageY + paperSize.height - bottomMargin - blockHeight
        let y = min(requestedY, maxY)

        drawText("Submitted by:", in: NSRect(x: x, y: y, width: sigW, height: 14), size: 10)
        drawText("Noted by:", in: NSRect(x: x + sigW + 30, y: y, width: sigW, height: 14), size: 10)

        // Small blank area specifically reserved for the actual signature.
        let nameY = y + 34
        drawText(
            snapshot.settings.adviser,
            in: NSRect(x: x, y: nameY, width: sigW, height: 16),
            size: 10.5, bold: true, alignment: .center
        )
        drawText(
            snapshot.settings.schoolHead,
            in: NSRect(x: x + sigW + 30, y: nameY, width: sigW, height: 16),
            size: 10.5, bold: true, alignment: .center
        )

        NSColor.black.setStroke()
        let lineY = nameY + 17
        let p1 = NSBezierPath()
        p1.move(to: NSPoint(x: x + 10, y: lineY))
        p1.line(to: NSPoint(x: x + sigW - 10, y: lineY))
        p1.stroke()

        let p2 = NSBezierPath()
        p2.move(to: NSPoint(x: x + sigW + 40, y: lineY))
        p2.line(to: NSPoint(x: x + sigW * 2 + 20, y: lineY))
        p2.stroke()

        drawText(
            "Class Adviser",
            in: NSRect(x: x, y: lineY + 2, width: sigW, height: 13),
            size: 9.5, alignment: .center
        )
        drawText(
            snapshot.settings.schoolHeadPosition,
            in: NSRect(x: x + sigW + 30, y: lineY + 2, width: sigW, height: 13),
            size: 9.5, alignment: .center
        )

        if includeDate {
            drawText(
                snapshot.generatedAt,
                in: NSRect(
                    x: x,
                    y: pageY + paperSize.height - bottomMargin - 14,
                    width: width,
                    height: 12
                ),
                size: 8.5,
                alignment: .right
            )
        }
    }

    private func drawCRM(pageIndex: Int) {
        let pageY = CGFloat(pageIndex) * paperSize.height
        let x = leftMargin
        let w = paperSize.width - leftMargin - rightMargin
        var y = drawHeader(pageOriginY: pageY, title: "CLASSROOM READING MONITORING REPORT") + 6

        let labelW: CGFloat = 50
        let totalW: CGFloat = 46
        let levelW = (w - labelW - totalW) / CGFloat(max(snapshot.crmRows.count, 1))
        let headerH: CGFloat = 28

        cell("", rect: NSRect(x: x, y: y, width: labelW, height: headerH),
             fillColor: NSColor(calibratedWhite: 0.85, alpha: 1))
        var cx = x + labelW
        for row in snapshot.crmRows {
            cell("", rect: NSRect(x: cx, y: y, width: levelW, height: headerH),
                 fillColor: NSColor(calibratedWhite: 0.85, alpha: 1))
            drawText(
                row.level.replacingOccurrences(of: "LEVEL", with: "Level"),
                in: NSRect(x: cx + 2, y: y + 2, width: levelW - 4, height: 12),
                size: 8.8, bold: true, alignment: .center
            )
            drawText(
                row.area.capitalized,
                in: NSRect(x: cx + 2, y: y + 14, width: levelW - 4, height: 16),
                size: 6.6, alignment: .center
            )
            cx += levelW
        }
        cell("Total", rect: NSRect(x: cx, y: y, width: totalW, height: headerH),
             fillColor: NSColor(calibratedWhite: 0.85, alpha: 1), bold: true, size: 10)
        y += headerH

        let dataH: CGFloat = 18
        let totalMale = snapshot.crmRows.reduce(0) { $0 + $1.male }
        let totalFemale = snapshot.crmRows.reduce(0) { $0 + $1.female }
        let rowDefs: [(String, [Int], Int, Bool)] = [
            ("Male", snapshot.crmRows.map { $0.male }, totalMale, false),
            ("Female", snapshot.crmRows.map { $0.female }, totalFemale, false),
            ("Total", snapshot.crmRows.map { $0.total }, totalMale + totalFemale, true)
        ]
        for def in rowDefs {
            cell(def.0, rect: NSRect(x: x, y: y, width: labelW, height: dataH),
                 bold: def.3, alignment: .left, size: 10)
            cx = x + labelW
            for v in def.1 {
                cell(String(v), rect: NSRect(x: cx, y: y, width: levelW, height: dataH),
                     bold: def.3, size: 10)
                cx += levelW
            }
            cell(String(def.2), rect: NSRect(x: cx, y: y, width: totalW, height: dataH),
                 bold: true, size: 10)
            y += dataH
        }

        y += 8

        if snapshot.keyStage > 0 {
            let groupW = w / 3
            let profileW = groupW * 0.50
            let countW = groupW * 0.25

            cell(
                "KEY STAGE \(snapshot.keyStage)",
                rect: NSRect(x: x, y: y, width: w, height: 16),
                fillColor: NSColor(calibratedWhite: 0.85, alpha: 1),
                bold: true,
                size: 10.5
            )
            y += 16

            cx = x
            for heading in ["BOSY", "MOSY", "EOSY"] {
                cell(
                    heading,
                    rect: NSRect(x: cx, y: y, width: groupW, height: 16),
                    fillColor: NSColor(calibratedWhite: 0.85, alpha: 1),
                    bold: true,
                    size: 9.5
                )
                cx += groupW
            }
            y += 16

            cx = x
            for _ in 0..<3 {
                cell("Reading Profile", rect: NSRect(x: cx, y: y, width: profileW, height: 20),
                     fillColor: NSColor(calibratedWhite: 0.85, alpha: 1), bold: true, size: 8.5)
                cx += profileW
                cell("Male", rect: NSRect(x: cx, y: y, width: countW, height: 20),
                     fillColor: NSColor(calibratedWhite: 0.85, alpha: 1), bold: true, size: 8.5)
                cx += countW
                cell("Female", rect: NSRect(x: cx, y: y, width: countW, height: 20),
                     fillColor: NSColor(calibratedWhite: 0.85, alpha: 1), bold: true, size: 8.5)
                cx += countW
            }
            y += 20

            let profileH: CGFloat = 15
            for p in snapshot.profileRows {
                let values: [(String, Int, Int)] = [
                    (p.label, p.bosyMale, p.bosyFemale),
                    (p.label, p.mosyMale, p.mosyFemale),
                    (p.label, p.eosyMale, p.eosyFemale)
                ]
                cx = x
                for v in values {
                    cell(v.0, rect: NSRect(x: cx, y: y, width: profileW, height: profileH),
                         alignment: .left, size: 9.5)
                    cx += profileW
                    cell(String(v.1), rect: NSRect(x: cx, y: y, width: countW, height: profileH), size: 10)
                    cx += countW
                    cell(String(v.2), rect: NSRect(x: cx, y: y, width: countW, height: profileH), size: 10)
                    cx += countW
                }
                y += profileH
            }

            let totals = [snapshot.bosyTotal, snapshot.mosyTotal, snapshot.eosyTotal]
            cx = x
            for total in totals {
                cell("Total", rect: NSRect(x: cx, y: y, width: profileW, height: profileH),
                     bold: true, alignment: .left, size: 10)
                cx += profileW
                cell(String(total), rect: NSRect(x: cx, y: y, width: countW * 2, height: profileH),
                     bold: true, size: 10)
                cx += countW * 2
            }
            y += profileH
        } else {
            cell(
                "Set the Grade Level in Setup. Only the applicable Key Stage is printed.",
                rect: NSRect(x: x, y: y, width: w, height: 32),
                fillColor: NSColor(calibratedRed: 1, green: 0.92, blue: 0.92, alpha: 1),
                bold: true, alignment: .left, size: 10
            )
            y += 32
        }

        drawSignatureBlock(pageY: pageY, y: y + 10, x: x, width: w, includeDate: true)
    }

    private enum ListEntry {
        case group(String)
        case pupil(Int, NativePupilRow)
    }

    private func allListEntries() -> [ListEntry] {
        var entries: [ListEntry] = []
        var maleNo = 0
        var femaleNo = 0

        entries.append(.group("MALE"))
        for p in snapshot.pupils.filter({ $0.sex == "Male" }) {
            maleNo += 1
            entries.append(.pupil(maleNo, p))
        }

        entries.append(.group("FEMALE"))
        for p in snapshot.pupils.filter({ $0.sex == "Female" }) {
            femaleNo += 1
            entries.append(.pupil(femaleNo, p))
        }
        return entries
    }

    private func drawPupilList(pageIndex: Int) {
        let pageY = CGFloat(pageIndex) * paperSize.height
        let x = leftMargin
        let w = paperSize.width - leftMargin - rightMargin

        // Full DepEd/BULIG title + class information appears on FIRST PAGE ONLY.
        var y: CGFloat
        if pageIndex == 0 {
            y = drawHeader(pageOriginY: pageY, title: "LIST OF PUPILS") + 8
        } else {
            y = pageY + topMargin
        }

        let widths: [CGFloat] = [30, 165, 92, 78, w - 30 - 165 - 92 - 78]
        let headerH: CGFloat = 28
        let headers = ["NO.", "LEARNER", "Reading Level", "Component/Level", "Color Coding"]
        var cx = x
        for i in 0..<headers.count {
            cell(
                headers[i],
                rect: NSRect(x: cx, y: y, width: widths[i], height: headerH),
                fillColor: NSColor(calibratedWhite: 0.85, alpha: 1),
                bold: true,
                size: 9
            )
            cx += widths[i]
        }
        y += headerH

        let entries = allListEntries()
        let start = pupilPageCounts.prefix(pageIndex).reduce(0, +)
        let count = pageIndex < pupilPageCounts.count ? pupilPageCounts[pageIndex] : 0
        let end = min(entries.count, start + count)
        let rowH: CGFloat = 24

        if start < end {
            for entry in entries[start..<end] {
                switch entry {
                case .group(let label):
                    cell(
                        label,
                        rect: NSRect(x: x, y: y, width: w, height: rowH),
                        fillColor: NSColor(calibratedWhite: 0.90, alpha: 1),
                        bold: true,
                        size: 11
                    )

                case .pupil(let n, let pupil):
                    // Color Coding is COLOR ONLY. No level text is printed in the color cell.
                    let values = [String(n), pupil.name, pupil.area.capitalized, pupil.level, ""]
                    cx = x
                    for i in 0..<5 {
                        let fillColor: NSColor? = i == 4 ? reportLevelColor(pupil.level) : nil
                        cell(
                            values[i],
                            rect: NSRect(x: cx, y: y, width: widths[i], height: rowH),
                            fillColor: fillColor,
                            bold: i == 1,
                            alignment: i == 1 ? .left : .center,
                            size: i == 2 ? 8.2 : 10
                        )
                        cx += widths[i]
                    }
                }
                y += rowH
            }
        }

        if pageIndex == pageCount - 1 {
            y += 8

            let summaryW = min(w * 0.72, 325)
            let labelW = summaryW * 0.48
            let countW = summaryW * 0.16
            let sexLabelW = summaryW * 0.18
            let sexCountW = summaryW - labelW - countW - sexLabelW

            cell(
                "TOTAL ENROLLMENT:",
                rect: NSRect(x: x, y: y, width: labelW, height: 22),
                bold: true, alignment: .left, size: 10
            )
            cell(
                String(snapshot.maleCount + snapshot.femaleCount),
                rect: NSRect(x: x + labelW, y: y, width: countW, height: 22),
                bold: true, size: 10
            )
            cell(
                "MALE:",
                rect: NSRect(x: x + labelW + countW, y: y, width: sexLabelW, height: 22),
                bold: true, size: 9
            )
            cell(
                String(snapshot.maleCount),
                rect: NSRect(x: x + labelW + countW + sexLabelW, y: y, width: sexCountW, height: 22),
                size: 10
            )
            y += 22

            cell(
                "FEMALE:",
                rect: NSRect(x: x + labelW + countW, y: y, width: sexLabelW, height: 22),
                bold: true, size: 9
            )
            cell(
                String(snapshot.femaleCount),
                rect: NSRect(x: x + labelW + countW + sexLabelW, y: y, width: sexCountW, height: 22),
                size: 10
            )
            y += 25

            drawSignatureBlock(pageY: pageY, y: y, x: x, width: w, includeDate: true)
        }
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        NSColor.white.setFill()
        dirtyRect.fill()

        for pageIndex in 0..<pageCount {
            let pageRect = NSRect(
                x: 0,
                y: CGFloat(pageIndex) * paperSize.height,
                width: paperSize.width,
                height: paperSize.height
            )
            guard dirtyRect.intersects(pageRect) else { continue }

            if type == .classroomMonitoring {
                drawCRM(pageIndex: pageIndex)
            } else {
                drawPupilList(pageIndex: pageIndex)
            }
        }
    }

    override func knowsPageRange(_ range: NSRangePointer) -> Bool {
        range.pointee = NSRange(location: 1, length: pageCount)
        return true
    }

    override func rectForPage(_ page: Int) -> NSRect {
        let index = max(0, min(page - 1, pageCount - 1))
        return NSRect(
            x: 0,
            y: CGFloat(index) * paperSize.height,
            width: paperSize.width,
            height: paperSize.height
        )
    }

    func pdfData() -> Data? {
        let output = PDFDocument()
        for pageIndex in 0..<pageCount {
            let rect = rectForPage(pageIndex + 1)
            let onePageData = dataWithPDF(inside: rect)
            guard let onePageDocument = PDFDocument(data: onePageData),
                  let page = onePageDocument.page(at: 0) else {
                return nil
            }
            output.insert(page, at: output.pageCount)
        }
        return output.dataRepresentation()
    }
}

@MainActor
final class AppStore: ObservableObject {
    @Published var data = AppData()
    @Published var selectedAP = "AP1"
    @Published var statusMessage = "Ready"
    private let appName = "BULIG RMS Teacher"

    init() { load(); migrateLearnerNameFields(); migratePreAssessmentHistory() }

    private var supportFolder: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let folder = base.appendingPathComponent(appName, isDirectory: true)
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        return folder
    }

    private var dataURL: URL { supportFolder.appendingPathComponent("data.json") }

    func save() {
        do {
            let encoded = try JSONEncoder.pretty.encode(data)
            try encoded.write(to: dataURL, options: .atomic)
            statusMessage = "Saved"
        } catch {
            statusMessage = "Save failed"
        }
    }

    func load() {
        guard let raw = try? Data(contentsOf: dataURL),
              let decoded = try? JSONDecoder().decode(AppData.self, from: raw) else { return }
        data = decoded
    }

    func addLearner() {
        data.learners.append(Learner())
        save()
    }

    func deleteLearners(at offsets: IndexSet) {
        data.learners.remove(atOffsets: offsets)
        save()
    }

    func keyStage() -> Int {
        guard let g = Int(data.settings.gradeLevel) else { return 0 }
        if g <= 3 { return 1 }
        if g <= 6 { return 2 }
        if g <= 10 { return 3 }
        return 4
    }

    func profileOptions() -> [String] {
        switch keyStage() {
        case 1: return ["", "Low Emerging", "High Emerging", "Developing", "Transitioning", "Grade Level Ready"]
        default: return ["", "Frustration", "Instructional", "Independent"]
        }
    }

    func schoolYearOptions() -> [String] {
        var years = Set<String>()
        if !data.settings.schoolYear.isEmpty { years.insert(data.settings.schoolYear) }
        for learner in data.learners {
            for year in learner.preHistory.keys { years.insert(year) }
        }

        let current = Calendar.current.component(.year, from: Date())
        for start in (current - 5)...(current + 5) {
            years.insert("\(start)-\(start + 1)")
        }

        return years.sorted {
            let lhs = Int($0.split(separator: "-").first ?? "") ?? 0
            let rhs = Int($1.split(separator: "-").first ?? "") ?? 0
            return lhs > rhs
        }
    }

    func preAssessment(for learner: Learner, schoolYear: String? = nil) -> PreAssessment {
        let year = schoolYear ?? data.settings.schoolYear
        if let saved = learner.preHistory[year] { return saved }
        if learner.preHistory.isEmpty && year == data.settings.schoolYear { return learner.pre }
        return PreAssessment()
    }

    private func setPreAssessment(_ value: PreAssessment, learnerID: UUID, schoolYear: String) {
        guard let index = data.learners.firstIndex(where: { $0.id == learnerID }) else { return }
        data.learners[index].preHistory[schoolYear] = value
        if schoolYear == data.settings.schoolYear {
            data.learners[index].pre = value
        }
        save()
    }

    func preLevelBinding(for learnerID: UUID, schoolYear: String) -> Binding<String> {
        Binding(
            get: {
                guard let learner = self.data.learners.first(where: { $0.id == learnerID }) else { return "" }
                return self.preAssessment(for: learner, schoolYear: schoolYear).level
            },
            set: { newValue in
                guard let learner = self.data.learners.first(where: { $0.id == learnerID }) else { return }
                var value = self.preAssessment(for: learner, schoolYear: schoolYear)
                value.level = newValue
                self.setPreAssessment(value, learnerID: learnerID, schoolYear: schoolYear)
            }
        )
    }

    func preProfileBinding(for learnerID: UUID, schoolYear: String, period: String) -> Binding<String> {
        Binding(
            get: {
                guard let learner = self.data.learners.first(where: { $0.id == learnerID }) else { return "" }
                let value = self.preAssessment(for: learner, schoolYear: schoolYear)
                switch period {
                case "MOSY": return value.mosy
                case "EOSY": return value.eosy
                default: return value.bosy
                }
            },
            set: { newValue in
                guard let learner = self.data.learners.first(where: { $0.id == learnerID }) else { return }
                var value = self.preAssessment(for: learner, schoolYear: schoolYear)
                switch period {
                case "MOSY": value.mosy = newValue
                case "EOSY": value.eosy = newValue
                default: value.bosy = newValue
                }
                self.setPreAssessment(value, learnerID: learnerID, schoolYear: schoolYear)
            }
        )
    }

    private func migratePreAssessmentHistory() {
        let year = data.settings.schoolYear
        guard !year.isEmpty else { return }

        var changed = false
        for index in data.learners.indices {
            if data.learners[index].preHistory[year] == nil {
                let legacy = data.learners[index].pre
                if !legacy.level.isEmpty || !legacy.bosy.isEmpty || !legacy.mosy.isEmpty || !legacy.eosy.isEmpty {
                    data.learners[index].preHistory[year] = legacy
                    changed = true
                }
            }
        }
        if changed { save() }
    }

    func nextLevel(_ level: String) -> String {
        guard let idx = readingLevels.firstIndex(where: { $0.code == level }) else { return level }
        return readingLevels[min(idx + 1, readingLevels.count - 1)].code
    }

    func previousLevel(_ level: String) -> String {
        guard let idx = readingLevels.firstIndex(where: { $0.code == level }) else { return level }
        return readingLevels[max(idx - 1, 0)].code
    }

    func isInactiveStatus(_ result: String) -> Bool {
        ["NLS", "NLP", "TRANSFER OUT"].contains(result)
    }

    func defaultLevelAfter(result: String, from level: String) -> String {
        guard !level.isEmpty else { return "" }
        switch result {
        case "READY":
            return nextLevel(level)
        case "REVERTED":
            return previousLevel(level)
        default:
            return level
        }
    }

    func appliedLevel(for entry: AssessmentEntry?, from level: String) -> String {
        guard let entry else { return level }
        if !entry.overrideLevel.isEmpty {
            return entry.overrideLevel
        }
        return defaultLevelAfter(result: entry.result, from: level)
    }

    func inactiveStatusBeforeAP(_ learner: Learner, ap: String) -> (period: String, status: String)? {
        guard let target = assessmentPeriods.firstIndex(of: ap), target > 0 else { return nil }
        for i in 0..<target {
            let key = assessmentPeriods[i]
            if let entry = learner.assessments[key], isInactiveStatus(entry.result) {
                return (key, entry.result)
            }
        }
        return nil
    }

    func levelBeforeAP(_ learner: Learner, ap: String) -> String {
        var level = preAssessment(for: learner).level
        guard !level.isEmpty else { return "" }
        guard let target = assessmentPeriods.firstIndex(of: ap), target > 0 else { return level }

        for i in 0..<target {
            let key = assessmentPeriods[i]
            guard let entry = learner.assessments[key] else { continue }
            level = appliedLevel(for: entry, from: level)
            if isInactiveStatus(entry.result) { break }
        }
        return level
    }

    func levelAfterAP(_ learner: Learner, ap: String) -> String {
        let before = levelBeforeAP(learner, ap: ap)
        guard inactiveStatusBeforeAP(learner, ap: ap) == nil else { return before }
        return appliedLevel(for: learner.assessments[ap], from: before)
    }

    func currentLevel(_ learner: Learner, through ap: String?) -> String {
        guard let ap else { return preAssessment(for: learner).level }
        var level = preAssessment(for: learner).level
        guard !level.isEmpty else { return "" }

        for key in assessmentPeriods {
            if let entry = learner.assessments[key] {
                level = appliedLevel(for: entry, from: level)
                if isInactiveStatus(entry.result) { break }
            }
            if key == ap { break }
        }
        return level
    }

    private func cleanedNameText(_ value: String) -> String {
        value.replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: "\r", with: " ")
            .split(whereSeparator: { $0.isWhitespace })
            .map(String.init)
            .joined(separator: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func normalizedNameExtension(_ value: String) -> String? {
        let token = value.uppercased()
            .replacingOccurrences(of: ".", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let extensions = ["JR", "SR", "I", "II", "III", "IV", "V", "VI", "VII", "VIII"]
        guard extensions.contains(token) else { return nil }
        return token
    }

    private func splitSF1Name(_ rawValue: String) -> (firstName: String, middleInitial: String, lastName: String, extensionName: String) {
        let raw = cleanedNameText(rawValue)
        guard !raw.isEmpty else { return ("", "", "", "") }

        let commaParts = raw.split(separator: ",", omittingEmptySubsequences: false)
            .map { cleanedNameText(String($0)) }

        let lastName = commaParts.first ?? ""

        // Standard SF1 header:
        // Last Name, First Name, Name Extension, Middle Name
        if commaParts.count >= 4 {
            let first = commaParts[1]
            let ext = normalizedNameExtension(commaParts[2]) ?? commaParts[2].uppercased()
            let middle = commaParts[3]
            let mi = middle.first.map { String($0).uppercased() } ?? ""
            return (first.uppercased(), mi, lastName.uppercased(), ext)
        }

        if commaParts.count == 3 {
            let first = commaParts[1]
            let third = commaParts[2]
            if let ext = normalizedNameExtension(third) {
                return (first.uppercased(), "", lastName.uppercased(), ext)
            }
            let mi = third.first.map { String($0).uppercased() } ?? ""
            return (first.uppercased(), mi, lastName.uppercased(), "")
        }

        let remainder = commaParts.count >= 2 ? commaParts.dropFirst().joined(separator: " ") : raw
        var tokens = cleanedNameText(remainder).split(separator: " ").map(String.init)
        guard !tokens.isEmpty else { return ("", "", lastName.uppercased(), "") }

        var extensionName = ""
        if let extIndex = tokens.firstIndex(where: { normalizedNameExtension($0) != nil }) {
            extensionName = normalizedNameExtension(tokens[extIndex]) ?? ""
            tokens.remove(at: extIndex)
        }

        if tokens.count == 1 {
            return (tokens[0].uppercased(), "", lastName.uppercased(), extensionName)
        }

        // In SF1, the middle name follows the first name and extension.
        // Keep all preceding words as the first name so compound first names remain intact.
        let middleName = tokens.removeLast()
        let middleInitial = middleName.first.map { String($0).uppercased() } ?? ""
        let firstName = tokens.joined(separator: " ").uppercased()
        return (firstName, middleInitial, lastName.uppercased(), extensionName)
    }

    private func canonicalFullName(firstName: String, middleInitial: String, lastName: String, extensionName: String) -> String {
        var pieces: [String] = []
        if !lastName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            pieces.append(lastName.uppercased() + ",")
        }
        if !firstName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            pieces.append(firstName.uppercased())
        }
        if !nameExtensionSafe(extensionName).isEmpty {
            pieces.append(nameExtensionSafe(extensionName))
        }
        if !middleInitial.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            pieces.append(String(middleInitial.uppercased().prefix(1)) + ".")
        }
        return pieces.joined(separator: " ")
    }

    private func nameExtensionSafe(_ value: String) -> String {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return normalizedNameExtension(trimmed) ?? trimmed.uppercased()
    }

    private func migrateLearnerNameFields() {
        var changed = false
        for index in data.learners.indices {
            let learner = data.learners[index]
            if learner.firstName.isEmpty && learner.lastName.isEmpty && !learner.fullName.isEmpty {
                let parts = splitSF1Name(learner.fullName)
                data.learners[index].firstName = parts.firstName
                data.learners[index].middleInitial = parts.middleInitial
                data.learners[index].lastName = parts.lastName
                data.learners[index].nameExtension = parts.extensionName
                changed = true
            }
        }
        if changed { save() }
    }

    func importFromClipboard() -> Int {
        guard let text = NSPasteboard.general.string(forType: .string),
              !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return 0 }
        var added = 0
        for rawLine in text.components(separatedBy: .newlines) {
            let line = rawLine.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !line.isEmpty else { continue }
            let cols = line.split(separator: "\t", omittingEmptySubsequences: false)
                .map { String($0).trimmingCharacters(in: .whitespaces) }
            guard cols.count >= 2 else { continue }
            let maybeLRN = cols[0].filter(\.isNumber)
            guard maybeLRN.count == 12 else { continue }
            if data.learners.contains(where: { $0.lrn == maybeLRN }) { continue }
            let sexRaw = cols.count > 2 ? cols[2].uppercased() : ""
            let sex = ["M", "MALE"].contains(sexRaw) ? "Male" : (["F", "FEMALE"].contains(sexRaw) ? "Female" : "")
            let dob = cols.count > 3 ? cols[3] : ""
            let nameParts = splitSF1Name(cols[1])
            data.learners.append(Learner(
                lrn: maybeLRN,
                fullName: cols[1],
                firstName: nameParts.firstName,
                middleInitial: nameParts.middleInitial,
                lastName: nameParts.lastName,
                nameExtension: nameParts.extensionName,
                sex: sex,
                dateOfBirth: dob
            ))
            added += 1
        }
        save()
        return added
    }

    private func normalizeSF1Header(_ value: String) -> String {
        value.uppercased()
            .replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: "\r", with: " ")
            .replacingOccurrences(of: "\t", with: " ")
            .replacingOccurrences(of: "  ", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func sf1HeaderColumns(in rows: [[String]]) -> (row: Int, lrn: Int, name: Int, sex: Int, birth: Int)? {
        for (rowIndex, row) in rows.enumerated() {
            var lrnColumn: Int?
            var nameColumn: Int?
            var sexColumn: Int?
            var birthColumn: Int?

            for (columnIndex, raw) in row.enumerated() {
                let value = normalizeSF1Header(raw)
                if lrnColumn == nil && value.contains("LRN") {
                    lrnColumn = columnIndex
                }
                if nameColumn == nil && (value == "NAME" || value.hasPrefix("NAME ") || value.contains("LAST NAME")) {
                    nameColumn = columnIndex
                }
                if sexColumn == nil && value.contains("SEX") {
                    sexColumn = columnIndex
                }
                if birthColumn == nil && value.contains("BIRTH") && value.contains("DATE") {
                    birthColumn = columnIndex
                }
            }

            if let lrnColumn, let nameColumn, let sexColumn, let birthColumn {
                return (rowIndex, lrnColumn, nameColumn, sexColumn, birthColumn)
            }
        }
        return nil
    }

    private func parseSpreadsheetSheets(at url: URL) throws -> [SF1ParsedSheet] {
        guard let parserURL = Bundle.main.url(forResource: "xlsx.full.min", withExtension: "js") else {
            throw SF1ImportError.parserMissing
        }
        guard let context = JSContext() else {
            throw SF1ImportError.unreadable
        }

        var javascriptError = ""
        context.exceptionHandler = { _, exception in
            javascriptError = exception?.toString() ?? "Unknown spreadsheet parsing error."
        }

        let parserScript = try String(contentsOf: parserURL, encoding: .utf8)
        context.evaluateScript(parserScript)
        if !javascriptError.isEmpty {
            throw SF1ImportError.javascript(javascriptError)
        }

        let fileData = try Data(contentsOf: url)
        context.setObject(fileData.base64EncodedString(), forKeyedSubscript: "__bulig_sf1_base64" as NSString)

        let conversionScript = """
        (function () {
          try {
            var wb = XLSX.read(__bulig_sf1_base64, { type: 'base64', cellDates: false });
            var output = wb.SheetNames.map(function (sheetName) {
              var ws = wb.Sheets[sheetName];
              var rows = XLSX.utils.sheet_to_json(ws, { header: 1, raw: false, defval: '' });
              rows = rows.map(function (row) {
                return row.map(function (value) {
                  return value == null ? '' : String(value);
                });
              });
              return { name: String(sheetName), rows: rows };
            });
            return JSON.stringify(output);
          } catch (e) {
            throw e;
          }
        })();
        """

        guard let jsonValue = context.evaluateScript(conversionScript),
              javascriptError.isEmpty,
              let json = jsonValue.toString(),
              let jsonData = json.data(using: .utf8) else {
            throw SF1ImportError.javascript(javascriptError.isEmpty ? "Invalid spreadsheet data." : javascriptError)
        }

        return try JSONDecoder().decode([SF1ParsedSheet].self, from: jsonData)
    }

    func importSF1File() -> String? {
        let panel = NSOpenPanel()
        panel.title = "Import School Form 1 (SF1)"
        panel.message = "Select the DepEd SF1 Excel file. BULIG will import LRN, learner name, sex, and birth date."
        panel.allowedFileTypes = ["xls", "xlsx", "xlsm"]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false

        guard panel.runModal() == .OK, let url = panel.url else { return nil }

        do {
            let sheets = try parseSpreadsheetSheets(at: url)

            var selectedSheet: SF1ParsedSheet?
            var header: (row: Int, lrn: Int, name: Int, sex: Int, birth: Int)?

            for sheet in sheets {
                if let found = sf1HeaderColumns(in: sheet.rows) {
                    selectedSheet = sheet
                    header = found
                    break
                }
            }

            guard let sheet = selectedSheet, let columns = header else {
                throw SF1ImportError.noSF1Sheet
            }

            var foundCount = 0
            var importedCount = 0
            var duplicateCount = 0
            var invalidCount = 0
            var seenLRNs = Set(data.learners.map { $0.lrn.filter(\.isNumber) })

            for row in sheet.rows.dropFirst(columns.row + 1) {
                func cell(_ index: Int) -> String {
                    guard index >= 0, index < row.count else { return "" }
                    return row[index].trimmingCharacters(in: .whitespacesAndNewlines)
                }

                let lrn = cell(columns.lrn).filter(\.isNumber)
                let name = cell(columns.name)
                let rawSex = cell(columns.sex).uppercased()
                let birthDate = cell(columns.birth)

                // Actual learner records in SF1 have a 12-digit LRN.
                guard !lrn.isEmpty || !name.isEmpty else { continue }
                guard lrn.count == 12 else {
                    if !name.isEmpty && !normalizeSF1Header(name).contains("TOTAL") {
                        invalidCount += 1
                    }
                    continue
                }

                foundCount += 1

                if seenLRNs.contains(lrn) {
                    duplicateCount += 1
                    continue
                }

                let sex: String
                if rawSex == "M" || rawSex == "MALE" {
                    sex = "Male"
                } else if rawSex == "F" || rawSex == "FEMALE" {
                    sex = "Female"
                } else {
                    sex = ""
                }

                let nameParts = splitSF1Name(name)
                data.learners.append(
                    Learner(
                        lrn: lrn,
                        fullName: name,
                        firstName: nameParts.firstName,
                        middleInitial: nameParts.middleInitial,
                        lastName: nameParts.lastName,
                        nameExtension: nameParts.extensionName,
                        sex: sex,
                        dateOfBirth: birthDate
                    )
                )
                seenLRNs.insert(lrn)
                importedCount += 1
            }

            save()

            var lines = [
                "SF1 import completed.",
                "Worksheet: \(sheet.name)",
                "Learners found: \(foundCount)",
                "New learners imported: \(importedCount)"
            ]
            if duplicateCount > 0 { lines.append("Existing LRNs skipped: \(duplicateCount)") }
            if invalidCount > 0 { lines.append("Rows skipped because the LRN was invalid or incomplete: \(invalidCount)") }
            return lines.joined(separator: "\n")
        } catch {
            return "SF1 import failed.\n\(error.localizedDescription)"
        }
    }

    func exportBackup() {
        let panel = NSSavePanel()
        panel.title = "Save BULIG Backup"
        panel.nameFieldStringValue = "BULIG_RMS_Backup.json"
        panel.allowedFileTypes = ["json"]
        if panel.runModal() == .OK, let url = panel.url {
            do {
                try JSONEncoder.pretty.encode(data).write(to: url, options: .atomic)
                statusMessage = "Backup saved"
            } catch {
                statusMessage = "Backup failed"
            }
        }
    }

    func restoreBackup() {
        let panel = NSOpenPanel()
        panel.title = "Restore BULIG Backup"
        panel.allowedFileTypes = ["json"]
        panel.allowsMultipleSelection = false
        guard panel.runModal() == .OK, let url = panel.url else { return }
        do {
            let decoded = try JSONDecoder().decode(AppData.self, from: Data(contentsOf: url))
            data = decoded
            save()
            statusMessage = "Backup restored"
        } catch {
            statusMessage = "Invalid backup file"
        }
    }

    func reportRows(stage: String) -> [(String, Int, Int, Int)] {
        readingLevels.map { level in
            let matches = data.learners.filter { learner in
                let current = stage == "PRETEST" ? preAssessment(for: learner).level : currentLevel(learner, through: stage)
                return current == level.code
            }
            let male = matches.filter { $0.sex == "Male" }.count
            let female = matches.filter { $0.sex == "Female" }.count
            return (level.code, male, female, male + female)
        }
    }

    func learnersForStage(_ stage: String) -> [(Learner, String)] {
        data.learners.map { learner in
            let level = stage == "PRETEST" ? preAssessment(for: learner).level : currentLevel(learner, through: stage)
            return (learner, level)
        }
    }

    func profileLabelsForCurrentKeyStage() -> [String] {
        keyStage() == 1
            ? ["Low Emerging", "High Emerging", "Developing", "Transitioning", "Grade Level Ready"]
            : ["Frustration", "Instructional", "Independent"]
    }

    func storedProfileValue(_ plain: String) -> String {
        guard keyStage() > 1 else { return plain }
        return "KS\(keyStage())_\(plain)"
    }

    func profileCount(_ profile: String, checkpoint: KeyPath<PreAssessment, String>, sex: String) -> Int {
        let target = storedProfileValue(profile)
        return data.learners.filter { learner in
            let value = preAssessment(for: learner)[keyPath: checkpoint]
            return learner.sex == sex && (value == target || value == profile)
        }.count
    }

    func reportText(stage: String) -> String {
        let s = data.settings
        var lines: [String] = []
        lines.append("BULIG RMS – TEACHER")
        lines.append("Bukidnon's Unified Literacy and Intervention Gateway")
        lines.append("")
        lines.append("School: \(s.schoolName)")
        lines.append("School ID: \(s.schoolId)    School Year: \(s.schoolYear)")
        lines.append("Grade & Section: Grade \(s.gradeLevel) – \(s.section)")
        lines.append("Adviser: \(s.adviser)    Subject: \(s.subject)")
        lines.append("Assessment: \(stage == "PRETEST" ? "PRETEST" : stage)")
        lines.append("")
        lines.append("LEVEL\tMALE\tFEMALE\tTOTAL")
        for row in reportRows(stage: stage) { lines.append("\(row.0)\t\(row.1)\t\(row.2)\t\(row.3)") }
        lines.append("")
        if keyStage() > 0 { lines.append("KEY STAGE \(keyStage()) only") }
        lines.append("TOTAL LEARNERS: \(data.learners.count)")
        return lines.joined(separator: "\n")
    }

    private func htmlEscape(_ value: String) -> String {
        value.replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "'", with: "&#39;")
    }

    private func termFor(_ stage: String) -> String {
        data.assessmentTerms[stage] ?? "1ST"
    }

    private func levelColor(_ level: String) -> String {
        switch level {
        case "LEVEL 1": return "#ffd7d2"
        case "LEVEL 2A": return "#ffe6b8"
        case "LEVEL 2B": return "#fff0a8"
        case "LEVEL 3A": return "#e1f3b8"
        case "LEVEL 3B": return "#c9ecc2"
        case "LEVEL 4": return "#bee9ef"
        case "LEVEL 5": return "#cbdcf7"
        case "LEVEL 6": return "#d6cef5"
        case "LEVEL 7": return "#ead0f2"
        default: return "#ffffff"
        }
    }

    private func reportHeaderHTML(stage: String, title: String) -> String {
        let s = data.settings
        return """
        <div class="brandrow">
          <div class="deped-mark">DepEd<br><span>Bukidnon</span></div>
          <div class="agency">
            <div>Department of Education</div>
            <div>\(htmlEscape(s.region))</div>
            <div>\(htmlEscape(s.division))</div>
            <div><b>\(htmlEscape(s.schoolName))</b></div>
          </div>
          <div><img class="bulig" src="BuligLogo.jpg"></div>
        </div>
        <div class="gateway">BUKIDNON'S UNIFIED LITERACY AND INTERVENTION GATEWAY</div>
        <div class="tagline">Building Up Literacy, Inspiring Growth</div>
        <div class="title">\(title)</div>
        <table class="meta">
          <tr><td class="label">Adviser</td><td>\(htmlEscape(s.adviser))</td><td class="label">ASSESSMENT PERIOD</td><td>\(htmlEscape(stage))</td></tr>
          <tr><td class="label">Grade Level</td><td>\(htmlEscape(s.gradeLevel))</td><td class="label">Term</td><td>\(htmlEscape(termFor(stage)))</td></tr>
          <tr><td class="label">Section</td><td>\(htmlEscape(s.section))</td><td class="label">Assessment Tool</td><td>\(htmlEscape(s.assessmentTool))</td></tr>
          <tr><td></td><td></td><td class="label">SUBJECT</td><td>\(htmlEscape(s.subject))</td></tr>
        </table>
        """
    }

    private func sharedReportCSS(landscape: Bool) -> String {
        """
        <style>
        @page { size: A4 \(landscape ? "landscape" : "portrait"); margin: 0.5in 1in; }
        * { box-sizing: border-box; }
        body { font-family: Arial, Helvetica, sans-serif; color:#000; margin:0; font-size:12pt; }
        .brandrow { display:grid; grid-template-columns: 140px 1fr 260px; align-items:center; min-height:84px; }
        .deped-mark { text-align:center; font-size:17px; font-weight:800; color:#124b91; line-height:1.1; }
        .deped-mark span { font-size:10px; color:#333; }
        .bulig { width:245px; max-height:82px; object-fit:contain; display:block; margin-left:auto; }
        .agency { text-align:center; line-height:1.25; font-family:Georgia,serif; }
        .gateway { text-align:center; font-weight:700; font-family:Georgia,serif; font-size:14px; margin-top:2px; }
        .tagline { text-align:center; font-weight:700; font-family:Georgia,serif; font-size:12px; }
        .title { text-align:center; font-weight:800; font-family:Georgia,serif; font-size:18px; margin:5px 0 15px; }
        table { border-collapse:collapse; width:100%; }
        .meta td { border:1.4px solid #000; min-height:22px; padding:4px 6px; font-size:12pt; }
        .meta .label { text-align:center; font-weight:600; width:18%; }
        .levels { margin-top:18px; table-layout:fixed; }
        .levels th,.levels td,.profile th,.profile td,.pupils th,.pupils td { border:1.35px solid #000; padding:4px 4px; text-align:center; }
        .levels th,.profile th,.pupils th { background:#d9d9d9; font-weight:700; }
        .levels .area { font-size:9pt; line-height:1.12; }
        .left { text-align:left !important; }
        .profile-title { margin-top:18px; background:#d9d9d9; border:1.35px solid #000; border-bottom:0; text-align:center; font-weight:800; font-size:13px; padding:4px; }
        .profile { table-layout:fixed; }
        .signature-row { display:grid; grid-template-columns:1fr 1fr 150px; gap:45px; margin-top:34px; align-items:end; font-size:12pt; }
        .sig { text-align:center; font-size:12pt; }
        .sig .name { border-bottom:1px solid #000; min-height:24px; padding-top:11px; font-weight:700; }
        .datebox { text-align:center; font-size:12pt; }
        .datebox .date { border-bottom:1px solid #000; padding-bottom:3px; margin-bottom:3px; }
        .group { background:#e6e6e6; font-weight:800; text-align:center !important; }
        .pupils { margin-top:18px; table-layout:fixed; font-size:12pt; }
        .pupils th:nth-child(1) { width:7%; }
        .pupils th:nth-child(2) { width:38%; }
        .pupils th:nth-child(3) { width:18%; }
        .pupils th:nth-child(4) { width:18%; }
        .pupils th:nth-child(5) { width:19%; }
        .summary { margin-top:14px; width:55%; font-size:12pt; }
        .summary td { border:1.2px solid #000; padding:4px 6px; }
        .warn { margin:18px 0; border:1px solid #b00; padding:10px; font-weight:700; color:#800; }
        </style>
        """
    }

    func classroomMonitoringHTML(stage: String) -> String {
        let rows = reportRows(stage: stage)
        let totalMale = rows.reduce(0) { $0 + $1.1 }
        let totalFemale = rows.reduce(0) { $0 + $1.2 }
        let levelHeader = readingLevels.map { level in
            "<th>\(htmlEscape(level.code.replacingOccurrences(of: "LEVEL", with: "Level")))<div class=\"area\">\(htmlEscape(level.area.capitalized))</div></th>"
        }.joined()
        let maleCells = rows.map { "<td>\($0.1)</td>" }.joined()
        let femaleCells = rows.map { "<td>\($0.2)</td>" }.joined()
        let totalCells = rows.map { "<td><b>\($0.3)</b></td>" }.joined()

        var profileHTML = ""
        if keyStage() > 0 {
            let labels = profileLabelsForCurrentKeyStage()
            let profileRows = labels.map { profile -> String in
                let bm = profileCount(profile, checkpoint: \.bosy, sex: "Male")
                let bf = profileCount(profile, checkpoint: \.bosy, sex: "Female")
                let mm = profileCount(profile, checkpoint: \.mosy, sex: "Male")
                let mf = profileCount(profile, checkpoint: \.mosy, sex: "Female")
                let em = profileCount(profile, checkpoint: \.eosy, sex: "Male")
                let ef = profileCount(profile, checkpoint: \.eosy, sex: "Female")
                return "<tr><td>\(htmlEscape(profile))</td><td>\(bm)</td><td>\(bf)</td><td>\(htmlEscape(profile))</td><td>\(mm)</td><td>\(mf)</td><td>\(htmlEscape(profile))</td><td>\(em)</td><td>\(ef)</td></tr>"
            }.joined()
            let bosyTotal = data.learners.filter { !preAssessment(for: $0).bosy.isEmpty }.count
            let mosyTotal = data.learners.filter { !preAssessment(for: $0).mosy.isEmpty }.count
            let eosyTotal = data.learners.filter { !preAssessment(for: $0).eosy.isEmpty }.count
            profileHTML = """
            <div class="profile-title">KEY STAGE \(keyStage())</div>
            <table class="profile">
              <tr><th colspan="3">BOSY</th><th colspan="3">MOSY</th><th colspan="3">EOSY</th></tr>
              <tr><th>Reading Profile</th><th>Male</th><th>Female</th><th>Reading Profile</th><th>Male</th><th>Female</th><th>Reading Profile</th><th>Male</th><th>Female</th></tr>
              \(profileRows)
              <tr><td><b>Total</b></td><td colspan="2"><b>\(bosyTotal)</b></td><td><b>Total</b></td><td colspan="2"><b>\(mosyTotal)</b></td><td><b>Total</b></td><td colspan="2"><b>\(eosyTotal)</b></td></tr>
            </table>
            """
        } else {
            profileHTML = "<div class=\"warn\">Set the Grade Level in Setup. The report prints only the applicable Key Stage table.</div>"
        }

        let date = DateFormatter.localizedString(from: Date(), dateStyle: .short, timeStyle: .short)
        return """
        <!doctype html><html><head><meta charset="utf-8">\(sharedReportCSS(landscape: true))</head><body>
        \(reportHeaderHTML(stage: stage, title: "CLASSROOM READING MONITORING REPORT"))
        <table class="levels">
          <tr><th></th>\(levelHeader)<th>Total</th></tr>
          <tr><td class="left">Male</td>\(maleCells)<td><b>\(totalMale)</b></td></tr>
          <tr><td class="left">Female</td>\(femaleCells)<td><b>\(totalFemale)</b></td></tr>
          <tr><td><b>Total</b></td>\(totalCells)<td><b>\(totalMale + totalFemale)</b></td></tr>
        </table>
        \(profileHTML)
        <div class="signature-row">
          <div class="sig"><div>Submitted by:</div><div class="name">\(htmlEscape(data.settings.adviser))</div><div>Class Adviser</div></div>
          <div class="sig"><div>Noted by:</div><div class="name">\(htmlEscape(data.settings.schoolHead))</div><div>\(htmlEscape(data.settings.schoolHeadPosition))</div></div>
          <div class="datebox"><div class="date">\(htmlEscape(date))</div><div>Date Generated</div></div>
        </div>
        </body></html>
        """
    }

    func pupilListHTML(stage: String) -> String {
        let staged = learnersForStage(stage)
        func groupRows(_ sex: String) -> String {
            var number = 0
            let rows = staged.filter { $0.0.sex == sex }.map { learner, level -> String in
                number += 1
                let info = readingLevels.first(where: { $0.code == level })
                return "<tr><td>\(number)</td><td class=\"left\">\(htmlEscape(learner.displayName))</td><td>\(htmlEscape(info?.area.capitalized ?? ""))</td><td>\(htmlEscape(level))</td><td style=\"background:\(levelColor(level))\">\(htmlEscape(level))</td></tr>"
            }.joined()
            return "<tr><td colspan=\"5\" class=\"group\">\(sex.uppercased())</td></tr>" + (rows.isEmpty ? "<tr><td colspan=\"5\">—</td></tr>" : rows)
        }
        let male = data.learners.filter { $0.sex == "Male" }.count
        let female = data.learners.filter { $0.sex == "Female" }.count
        let date = DateFormatter.localizedString(from: Date(), dateStyle: .short, timeStyle: .short)
        return """
        <!doctype html><html><head><meta charset="utf-8">\(sharedReportCSS(landscape: false))</head><body>
        \(reportHeaderHTML(stage: stage, title: "LIST OF PUPILS"))
        <table class="pupils">
          <tr><th>NO.</th><th>LEARNER</th><th>Reading Level</th><th>Component/Level</th><th>Color Coding</th></tr>
          \(groupRows("Male"))
          \(groupRows("Female"))
        </table>
        <table class="summary">
          <tr><td><b>TOTAL ENROLLMENT:</b></td><td><b>\(data.learners.count)</b></td><td><b>MALE:</b></td><td>\(male)</td></tr>
          <tr><td></td><td></td><td><b>FEMALE:</b></td><td>\(female)</td></tr>
        </table>
        <div class="signature-row">
          <div class="sig"><div>Submitted by:</div><div class="name">\(htmlEscape(data.settings.adviser))</div><div>Class Adviser</div></div>
          <div class="sig"><div>Noted by:</div><div class="name">\(htmlEscape(data.settings.schoolHead))</div><div>\(htmlEscape(data.settings.schoolHeadPosition))</div></div>
          <div class="datebox"><div class="date">\(htmlEscape(date))</div><div>Date Generated</div></div>
        </div>
        </body></html>
        """
    }

    private func nativeReportSnapshot(stage: String) -> NativeReportSnapshot {
        let crm = reportRows(stage: stage).compactMap { row -> NativeCRMLevelRow? in
            guard let info = readingLevels.first(where: { $0.code == row.0 }) else { return nil }
            return NativeCRMLevelRow(
                level: row.0,
                area: info.area,
                male: row.1,
                female: row.2,
                total: row.3
            )
        }

        let profiles = profileLabelsForCurrentKeyStage().map { label in
            NativeProfileRow(
                label: label,
                bosyMale: profileCount(label, checkpoint: \.bosy, sex: "Male"),
                bosyFemale: profileCount(label, checkpoint: \.bosy, sex: "Female"),
                mosyMale: profileCount(label, checkpoint: \.mosy, sex: "Male"),
                mosyFemale: profileCount(label, checkpoint: \.mosy, sex: "Female"),
                eosyMale: profileCount(label, checkpoint: \.eosy, sex: "Male"),
                eosyFemale: profileCount(label, checkpoint: \.eosy, sex: "Female")
            )
        }

        let pupils = learnersForStage(stage).map { learner, level -> NativePupilRow in
            let info = readingLevels.first(where: { $0.code == level })
            return NativePupilRow(
                name: learner.displayName,
                sex: learner.sex,
                area: info?.area ?? "",
                level: level
            )
        }

        let activePre = data.learners.map { preAssessment(for: $0) }

        return NativeReportSnapshot(
            settings: data.settings,
            stage: stage,
            term: termFor(stage),
            keyStage: keyStage(),
            crmRows: crm,
            profileRows: profiles,
            bosyTotal: activePre.filter { !$0.bosy.isEmpty }.count,
            mosyTotal: activePre.filter { !$0.mosy.isEmpty }.count,
            eosyTotal: activePre.filter { !$0.eosy.isEmpty }.count,
            pupils: pupils,
            maleCount: data.learners.filter { $0.sex == "Male" }.count,
            femaleCount: data.learners.filter { $0.sex == "Female" }.count,
            generatedAt: DateFormatter.localizedString(from: Date(), dateStyle: .short, timeStyle: .short)
        )
    }

    private func nativeReportView(stage: String, type: PrintoutType) -> NativeReportView {
        NativeReportView(type: type, snapshot: nativeReportSnapshot(stage: stage))
    }

    func previewReport(stage: String, type: PrintoutType) {
        let view = nativeReportView(stage: stage, type: type)
        guard let data = view.pdfData() else {
            statusMessage = "Preview failed"
            return
        }

        let temp = FileManager.default.temporaryDirectory
            .appendingPathComponent("BULIG_Report_Preview_\(UUID().uuidString).pdf")
        do {
            try data.write(to: temp, options: .atomic)
            NSWorkspace.shared.open(temp)
            statusMessage = "Preview opened"
        } catch {
            statusMessage = "Preview failed"
        }
    }

    func printReport(stage: String, type: PrintoutType) {
        let view = nativeReportView(stage: stage, type: type)
        let info = NSPrintInfo.shared.copy() as! NSPrintInfo
        info.paperSize = view.paperSize
        info.leftMargin = 0
        info.rightMargin = 0
        info.topMargin = 0
        info.bottomMargin = 0
        info.horizontalPagination = .fit
        info.verticalPagination = .automatic
        info.isHorizontallyCentered = true
        info.isVerticallyCentered = false

        let op = NSPrintOperation(view: view, printInfo: info)
        op.showsPrintPanel = true
        op.showsProgressPanel = true
        statusMessage = op.run() ? "Report sent to print" : "Printing cancelled or failed"
    }

    func savePDFReport(stage: String, type: PrintoutType) {
        let view = nativeReportView(stage: stage, type: type)
        guard let data = view.pdfData() else {
            statusMessage = "PDF generation failed"
            return
        }

        let panel = NSSavePanel()
        panel.title = "Save BULIG Report as PDF"
        let reportName = type == .classroomMonitoring ? "Classroom_Reading_Monitoring_Report" : "List_of_Pupils"
        panel.nameFieldStringValue = "BULIG_\(stage)_\(reportName).pdf"
        panel.allowedFileTypes = ["pdf"]
        guard panel.runModal() == .OK, let url = panel.url else { return }

        do {
            try data.write(to: url, options: .atomic)
            statusMessage = "PDF saved"
        } catch {
            statusMessage = "PDF save failed"
        }
    }

    func exportCSV(stage: String) {
        let panel = NSSavePanel()
        panel.title = "Export CRM Summary"
        panel.nameFieldStringValue = "BULIG_\(stage)_Summary.csv"
        panel.allowedFileTypes = ["csv"]
        guard panel.runModal() == .OK, let url = panel.url else { return }
        var csv = "Level,Male,Female,Total\n"
        for row in reportRows(stage: stage) {
            csv += "\(row.0),\(row.1),\(row.2),\(row.3)\n"
        }
        do {
            try csv.write(to: url, atomically: true, encoding: .utf8)
            statusMessage = "CSV exported"
        } catch {
            statusMessage = "Export failed"
        }
    }
}

extension JSONEncoder {
    static var pretty: JSONEncoder {
        let e = JSONEncoder()
        e.outputFormatting = [.prettyPrinted, .sortedKeys]
        return e
    }
}

enum AppPage: String, CaseIterable, Identifiable {
    case dashboard = "Dashboard"
    case setup = "Setup"
    case learners = "Learners"
    case pre = "Pre-Assessment"
    case monitoring = "Monitoring"
    case reports = "Reports"
    case backup = "Backup & Restore"
    var id: String { rawValue }
    var symbol: String {
        switch self {
        case .dashboard: return "house.fill"
        case .setup: return "gearshape.fill"
        case .learners: return "person.2.fill"
        case .pre: return "doc.text.magnifyingglass"
        case .monitoring: return "checkmark.circle.fill"
        case .reports: return "chart.bar.doc.horizontal.fill"
        case .backup: return "externaldrive.fill.badge.timemachine"
        }
    }
}

struct RootView: View {
    @StateObject var store = AppStore()
    @State private var selection: AppPage? = .dashboard

    var body: some View {
        NavigationSplitView {
            VStack(spacing: 0) {
                BrandView()
                    .padding(.top, 14)
                    .padding(.bottom, 10)
                List(AppPage.allCases, selection: $selection) { page in
                    Label(page.rawValue, systemImage: page.symbol)
                        .tag(page)
                        .padding(.vertical, 4)
                }
                .listStyle(.sidebar)
                HStack {
                    Circle().fill(Color.green).frame(width: 7, height: 7)
                    Text(store.statusMessage).font(.caption).foregroundStyle(.secondary)
                }
                .padding(12)
            }
            .frame(minWidth: 230)
        } detail: {
            Group {
                switch selection ?? .dashboard {
                case .dashboard: DashboardView(store: store)
                case .setup: SetupView(store: store)
                case .learners: LearnersView(store: store)
                case .pre: PreAssessmentView(store: store)
                case .monitoring: MonitoringView(store: store)
                case .reports: ReportsView(store: store)
                case .backup: BackupView(store: store)
                }
            }
            .frame(minWidth: 850, minHeight: 620)
            .background(Color(nsColor: .windowBackgroundColor))
        }
        .onChange(of: store.data) { _ in store.save() }
    }
}

struct BrandView: View {
    var body: some View {
        HStack(spacing: 12) {
            if let url = Bundle.main.url(forResource: "BuligLogo", withExtension: "jpg"),
               let ns = NSImage(contentsOf: url) {
                Image(nsImage: ns)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 58, height: 58)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            } else {
                Image(systemName: "book.fill").font(.largeTitle).foregroundStyle(.green)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text("BULIG RMS").font(.title2.bold())
                Text("Teacher • macOS").font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(.horizontal, 14)
    }
}

struct PageHeader: View {
    let title: String
    let subtitle: String
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.largeTitle.bold())
            Text(subtitle).foregroundStyle(.secondary)
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let symbol: String
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: symbol)
                .font(.title2)
                .foregroundStyle(.blue)
                .frame(width: 38, height: 38)
                .background(Color.blue.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            VStack(alignment: .leading) {
                Text(value).font(.title2.bold())
                Text(title).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(16)
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.05), radius: 8, y: 3)
    }
}

struct DashboardView: View {
    @ObservedObject var store: AppStore
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                PageHeader(title: "Dashboard", subtitle: "Bukidnon's Unified Literacy and Intervention Gateway")
                HStack(spacing: 14) {
                    StatCard(title: "Learners", value: "\(store.data.learners.count)", symbol: "person.2.fill")
                    StatCard(title: "Male", value: "\(store.data.learners.filter{$0.sex == "Male"}.count)", symbol: "person.fill")
                    StatCard(title: "Female", value: "\(store.data.learners.filter{$0.sex == "Female"}.count)", symbol: "person.fill")
                    StatCard(title: "Key Stage", value: store.keyStage() == 0 ? "—" : "KS \(store.keyStage())", symbol: "book.fill")
                }
                GroupBox("Current Class") {
                    Grid(alignment: .leading, horizontalSpacing: 24, verticalSpacing: 10) {
                        GridRow { Text("School").foregroundStyle(.secondary); Text(store.data.settings.schoolName.isEmpty ? "Not configured" : store.data.settings.schoolName).bold() }
                        GridRow { Text("Class").foregroundStyle(.secondary); Text("Grade \(store.data.settings.gradeLevel) – \(store.data.settings.section)").bold() }
                        GridRow { Text("Adviser").foregroundStyle(.secondary); Text(store.data.settings.adviser).bold() }
                        GridRow { Text("Assessment Tool").foregroundStyle(.secondary); Text(store.data.settings.assessmentTool).bold() }
                    }
                    .padding(8)
                }
                GroupBox("Reading Level Snapshot") {
                    VStack(spacing: 8) {
                        ForEach(readingLevels) { level in
                            HStack {
                                Text(level.code).frame(width: 90, alignment: .leading).bold()
                                Text(level.area).font(.caption).foregroundStyle(.secondary)
                                Spacer()
                                Text("\(store.data.learners.filter{$0.pre.level == level.code}.count)").monospacedDigit().bold()
                            }
                            Divider()
                        }
                    }
                    .padding(8)
                }
            }
            .padding(28)
        }
    }
}

struct SetupView: View {
    @ObservedObject var store: AppStore
    @State private var showSavedConfirmation = false
    let grades = (1...12).map(String.init)
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                PageHeader(title: "Setup", subtitle: "School and class information")
                GroupBox("School Information") {
                    Form {
                        TextField("School Name", text: $store.data.settings.schoolName)
                        TextField("School ID", text: $store.data.settings.schoolId)
                        TextField("School Head", text: $store.data.settings.schoolHead)
                        TextField("Position", text: $store.data.settings.schoolHeadPosition)
                        TextField("District", text: $store.data.settings.district)
                        TextField("Division", text: $store.data.settings.division)
                        TextField("Region", text: $store.data.settings.region)
                    }
                    .padding(8)
                }
                GroupBox("Class Information") {
                    Form {
                        TextField("School Year", text: $store.data.settings.schoolYear)
                        Picker("Grade Level", selection: $store.data.settings.gradeLevel) {
                            Text("Select").tag("")
                            ForEach(grades, id: \.self) { Text("Grade \($0)").tag($0) }
                        }
                        TextField("Section", text: $store.data.settings.section)
                        TextField("Adviser", text: $store.data.settings.adviser)
                        Picker("Assessment Tool", selection: $store.data.settings.assessmentTool) {
                            Text("CRLA").tag("CRLA")
                            Text("PHIL-IRI").tag("PHIL-IRI")
                        }
                        Picker("Subject", selection: $store.data.settings.subject) {
                            Text("ENGLISH").tag("ENGLISH")
                            Text("FILIPINO").tag("FILIPINO")
                        }
                        HStack {
                            Text("Automatic Key Stage")
                            Spacer()
                            Text(store.keyStage() == 0 ? "—" : "Key Stage \(store.keyStage())").bold()
                        }
                    }
                    .padding(8)
                }
                HStack {
                    Spacer()
                    Button("Save Setup") {
                        store.save()
                        showSavedConfirmation = true
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding(28)
        }
        .alert("Setup Saved", isPresented: $showSavedConfirmation) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("School and class information has been saved successfully.")
        }
    }
}

struct LearnersView: View {
    @ObservedObject var store: AppStore
    @State private var importMessage = ""
    @State private var showImportAlert = false
    @State private var editingLearnerID: UUID? = nil
    @State private var editLRN = ""
    @State private var editFirstName = ""
    @State private var editMiddleInitial = ""
    @State private var editLastName = ""
    @State private var editExtension = ""
    @State private var editSex = ""
    @State private var editDOB = ""
    @State private var learnerToRemove: Learner? = nil

    private func beginEdit(_ learner: Learner) {
        editingLearnerID = learner.id
        editLRN = learner.lrn
        editFirstName = learner.firstName
        editMiddleInitial = learner.middleInitial
        editLastName = learner.lastName
        editExtension = learner.nameExtension
        editSex = learner.sex
        editDOB = learner.dateOfBirth
    }

    private func saveEdit() {
        guard let id = editingLearnerID,
              let index = store.data.learners.firstIndex(where: { $0.id == id }) else { return }

        let first = editFirstName.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        let mi = String(editMiddleInitial.trimmingCharacters(in: .whitespacesAndNewlines).uppercased().prefix(1))
        let last = editLastName.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        let ext = editExtension.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()

        store.data.learners[index].lrn = editLRN.filter(\.isNumber)
        store.data.learners[index].firstName = first
        store.data.learners[index].middleInitial = mi
        store.data.learners[index].lastName = last
        store.data.learners[index].nameExtension = ext
        store.data.learners[index].fullName = [last.isEmpty ? "" : last + ",", first, ext, mi.isEmpty ? "" : mi + "."]
            .filter { !$0.isEmpty }
            .joined(separator: " ")
        store.data.learners[index].sex = editSex
        store.data.learners[index].dateOfBirth = editDOB.trimmingCharacters(in: .whitespacesAndNewlines)
        store.save()
        editingLearnerID = nil
    }

    private func removeConfirmedLearner() {
        guard let learner = learnerToRemove,
              let index = store.data.learners.firstIndex(where: { $0.id == learner.id }) else {
            learnerToRemove = nil
            return
        }
        store.data.learners.remove(at: index)
        store.save()
        learnerToRemove = nil
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            PageHeader(title: "Learners", subtitle: "Learner master list and direct SF1 import")
            HStack {
                Button { store.addLearner() } label: {
                    Label("Add Learner", systemImage: "plus")
                }
                .buttonStyle(.borderedProminent)

                Button {
                    if let message = store.importSF1File() {
                        importMessage = message + "\nNames were organized into First Name, Middle Initial, Last Name, and Extension."
                        showImportAlert = true
                    }
                } label: {
                    Label("Import SF1", systemImage: "square.and.arrow.down.on.square")
                }
                .buttonStyle(.bordered)

                Button {
                    let n = store.importFromClipboard()
                    importMessage = n > 0
                        ? "Paste import completed.\nImported \(n) learner(s).\nNames were organized into separate name fields."
                        : "No valid new learners found. Copy tab-separated SF1 rows first."
                    showImportAlert = true
                } label: {
                    Label("Paste from SF1", systemImage: "doc.on.clipboard")
                }

                Spacer()
            }

            HStack(spacing: 12) {
                HStack(spacing: 7) {
                    Image(systemName: "person.fill")
                    Text("Male")
                    Text("\(store.data.learners.filter { $0.sex == "Male" }.count)")
                        .bold()
                        .monospacedDigit()
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(Color.blue.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 9))

                HStack(spacing: 7) {
                    Image(systemName: "person.fill")
                    Text("Female")
                    Text("\(store.data.learners.filter { $0.sex == "Female" }.count)")
                        .bold()
                        .monospacedDigit()
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(Color.pink.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 9))

                HStack(spacing: 7) {
                    Image(systemName: "person.2.fill")
                    Text("Total")
                    Text("\(store.data.learners.count)")
                        .bold()
                        .monospacedDigit()
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(Color.secondary.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 9))

                Spacer()
            }

            Text("SF1 NAME is automatically separated into Last Name, First Name, Middle Initial, and Extension. You can correct any unusual name through Edit.")
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack(spacing: 10) {
                Text("Last Name").bold().frame(width: 145, alignment: .leading)
                Text("First Name").bold().frame(width: 185, alignment: .leading)
                Text("MI").bold().frame(width: 38, alignment: .leading)
                Text("Ext.").bold().frame(width: 55, alignment: .leading)
                Text("LRN").bold().frame(width: 125, alignment: .leading)
                Text("Sex").bold().frame(width: 60, alignment: .leading)
                Text("Birth Date").bold().frame(width: 95, alignment: .leading)
                Spacer()
                Text("Actions").bold().frame(width: 165, alignment: .center)
            }
            .font(.caption)
            .foregroundStyle(.secondary)
            .padding(.horizontal, 10)

            List {
                ForEach(store.data.learners) { learner in
                    HStack(spacing: 10) {
                        Text(learner.lastName.isEmpty ? "—" : learner.lastName)
                            .frame(width: 145, alignment: .leading)
                            .bold()
                        Text(learner.firstName.isEmpty ? "—" : learner.firstName)
                            .frame(width: 185, alignment: .leading)
                        Text(learner.middleInitial.isEmpty ? "—" : learner.middleInitial)
                            .frame(width: 38, alignment: .leading)
                        Text(learner.nameExtension.isEmpty ? "—" : learner.nameExtension)
                            .frame(width: 55, alignment: .leading)
                        Text(learner.lrn.isEmpty ? "—" : learner.lrn)
                            .font(.caption.monospacedDigit())
                            .frame(width: 125, alignment: .leading)
                        Text(learner.sex.isEmpty ? "—" : learner.sex)
                            .frame(width: 60, alignment: .leading)
                        Text(learner.dateOfBirth.isEmpty ? "—" : learner.dateOfBirth)
                            .frame(width: 95, alignment: .leading)

                        Spacer()

                        Button {
                            beginEdit(learner)
                        } label: {
                            Label("Edit", systemImage: "pencil")
                        }
                        .buttonStyle(.bordered)

                        Button(role: .destructive) {
                            learnerToRemove = learner
                        } label: {
                            Label("Remove", systemImage: "trash")
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding(.vertical, 6)
                }
            }
            .listStyle(.inset(alternatesRowBackgrounds: true))
        }
        .padding(28)
        .sheet(isPresented: Binding(
            get: { editingLearnerID != nil },
            set: { if !$0 { editingLearnerID = nil } }
        )) {
            VStack(alignment: .leading, spacing: 18) {
                Text("Edit Learner")
                    .font(.title2.bold())

                Form {
                    TextField("LRN", text: $editLRN)
                    TextField("First Name", text: $editFirstName)
                    TextField("Middle Initial", text: $editMiddleInitial)
                    TextField("Last Name", text: $editLastName)
                    TextField("Extension (Jr., Sr., II, III, etc.)", text: $editExtension)
                    Picker("Sex", selection: $editSex) {
                        Text("Select").tag("")
                        Text("Male").tag("Male")
                        Text("Female").tag("Female")
                    }
                    TextField("Date of Birth", text: $editDOB)
                }

                HStack {
                    Spacer()
                    Button("Cancel") {
                        editingLearnerID = nil
                    }
                    Button("Save Changes") {
                        saveEdit()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(
                        editFirstName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                        editLastName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    )
                }
            }
            .padding(24)
            .frame(width: 560, height: 430)
        }
        .alert("SF1 Import", isPresented: $showImportAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(importMessage)
        }
        .alert("Remove Learner?", isPresented: Binding(
            get: { learnerToRemove != nil },
            set: { if !$0 { learnerToRemove = nil } }
        )) {
            Button("Cancel", role: .cancel) {
                learnerToRemove = nil
            }
            Button("Remove", role: .destructive) {
                removeConfirmedLearner()
            }
        } message: {
            let name = learnerToRemove?.displayName.isEmpty == false ? learnerToRemove!.displayName : "this learner"
            Text("Remove \(name)? This will also delete the learner's pre-assessment and AP1–AP15 records.")
        }
    }
}

struct PreAssessmentView: View {
    @ObservedObject var store: AppStore
    @State private var selectedSchoolYear = ""
    @State private var selectedPeriod = "BOSY"

    private var activeSchoolYear: String {
        selectedSchoolYear.isEmpty ? store.data.settings.schoolYear : selectedSchoolYear
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            PageHeader(
                title: "Pre-Assessment",
                subtitle: "Choose the school year and encoding period, then encode only that assessment."
            )

            HStack(spacing: 18) {
                HStack(spacing: 6) {
                    Text("Automatic Key Stage:")
                        .foregroundStyle(.secondary)
                    Text(store.keyStage() == 0 ? "Select a grade level in Setup" : "Key Stage \(store.keyStage())")
                        .bold()
                }

                Spacer()

                Picker("School Year", selection: Binding(
                    get: { activeSchoolYear },
                    set: { selectedSchoolYear = $0 }
                )) {
                    ForEach(store.schoolYearOptions(), id: \.self) { year in
                        Text(year).tag(year)
                    }
                }
                .frame(width: 205)

                Picker("Encoding Period", selection: $selectedPeriod) {
                    ForEach(preAssessmentPeriods, id: \.self) { period in
                        Text(period).tag(period)
                    }
                }
                .frame(width: 185)
            }

            HStack {
                Label("\(activeSchoolYear) • \(selectedPeriod) Encoding", systemImage: "square.and.pencil")
                    .font(.headline)
                Spacer()
                Text("Only \(selectedPeriod) is shown below.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, 4)

            HStack(spacing: 12) {
                Text("Learner").bold().frame(minWidth: 280, alignment: .leading)
                Text("Initial Level").bold().frame(width: 170, alignment: .leading)
                Text("Reading Component").bold().frame(minWidth: 230, alignment: .leading)
                Text("\(selectedPeriod) Profile").bold().frame(width: 220, alignment: .leading)
            }
            .font(.caption)
            .foregroundStyle(.secondary)
            .padding(.horizontal, 10)

            List {
                ForEach(store.data.learners) { learner in
                    let pre = store.preAssessment(for: learner, schoolYear: activeSchoolYear)

                    HStack(spacing: 12) {
                        Text(learner.displayName.isEmpty ? "Unnamed learner" : learner.displayName)
                            .bold()
                            .frame(minWidth: 280, alignment: .leading)

                        Picker("Initial Level", selection: store.preLevelBinding(
                            for: learner.id,
                            schoolYear: activeSchoolYear
                        )) {
                            Text("Select Level").tag("")
                            ForEach(readingLevels) { level in
                                Text(level.code).tag(level.code)
                            }
                        }
                        .labelsHidden()
                        .frame(width: 170)

                        Text(readingLevels.first(where: { $0.code == pre.level })?.area.capitalized ?? "—")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .frame(minWidth: 230, alignment: .leading)

                        Picker(selectedPeriod, selection: store.preProfileBinding(
                            for: learner.id,
                            schoolYear: activeSchoolYear,
                            period: selectedPeriod
                        )) {
                            ForEach(store.profileOptions(), id: \.self) { option in
                                Text(option.isEmpty ? "Select \(selectedPeriod)" : option).tag(option)
                            }
                        }
                        .labelsHidden()
                        .frame(width: 220)
                    }
                    .padding(.vertical, 7)
                }
            }
            .listStyle(.inset(alternatesRowBackgrounds: true))
        }
        .padding(28)
        .onAppear {
            if selectedSchoolYear.isEmpty {
                selectedSchoolYear = store.data.settings.schoolYear
            }
        }
    }
}

struct MonitoringView: View {
    @ObservedObject var store: AppStore

    @State private var editingLearnerID: UUID? = nil
    @State private var manualLevel = ""
    @State private var manualNote = ""
    @State private var showOverrideConfirmation = false

    func resultBinding(for learnerID: UUID) -> Binding<String> {
        Binding(
            get: {
                store.data.learners.first(where: { $0.id == learnerID })?
                    .assessments[store.selectedAP]?.result ?? ""
            },
            set: { newValue in
                guard let index = store.data.learners.firstIndex(where: { $0.id == learnerID }) else { return }
                // Selecting/changing a status restores the normal automatic rule.
                // A special level is applied only when the teacher deliberately uses Edit Level.
                store.data.learners[index].assessments[store.selectedAP] = AssessmentEntry(result: newValue)
                store.save()
            }
        )
    }

    private var editingLearner: Learner? {
        guard let id = editingLearnerID else { return nil }
        return store.data.learners.first(where: { $0.id == id })
    }

    private func beginLevelEdit(_ learner: Learner) {
        editingLearnerID = learner.id
        manualLevel = store.levelAfterAP(learner, ap: store.selectedAP)
        manualNote = learner.assessments[store.selectedAP]?.note ?? ""
    }

    private func saveManualLevel() {
        guard let learner = editingLearner,
              let index = store.data.learners.firstIndex(where: { $0.id == learner.id }),
              !manualLevel.isEmpty else { return }

        var entry = store.data.learners[index].assessments[store.selectedAP] ?? AssessmentEntry()
        entry.overrideLevel = manualLevel
        entry.note = manualNote.trimmingCharacters(in: .whitespacesAndNewlines)
        store.data.learners[index].assessments[store.selectedAP] = entry
        store.save()
        editingLearnerID = nil
        showOverrideConfirmation = false
    }

    private func clearManualOverride(_ learner: Learner) {
        guard let index = store.data.learners.firstIndex(where: { $0.id == learner.id }),
              var entry = store.data.learners[index].assessments[store.selectedAP] else { return }
        entry.overrideLevel = ""
        entry.note = ""
        store.data.learners[index].assessments[store.selectedAP] = entry
        store.save()
    }

    private func statusLabel(_ status: String) -> String {
        switch status {
        case "NLS": return "NLS – No Longer in School"
        case "NLP": return "NLP – No Longer Participating"
        case "TRANSFER OUT": return "Transfer Out"
        default: return status
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            PageHeader(title: "Monitoring", subtitle: "AP1–AP15 reading progression")

            HStack(spacing: 14) {
                Picker("Assessment Period", selection: $store.selectedAP) {
                    ForEach(assessmentPeriods, id: \.self) { Text($0).tag($0) }
                }
                .frame(width: 210)

                Picker("Term", selection: Binding(
                    get: { store.data.assessmentTerms[store.selectedAP] ?? "1ST" },
                    set: { store.data.assessmentTerms[store.selectedAP] = $0; store.save() }
                )) {
                    ForEach(terms, id: \.self) { Text($0).tag($0) }
                }
                .frame(width: 150)

                Spacer()

                Text("READY +1 • NOT READY stays • REVERTED −1 • Edit Level for special cases")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 16) {
                Label("NLS: No Longer in School", systemImage: "person.crop.circle.badge.xmark")
                Label("NLP: No Longer Participating", systemImage: "person.crop.circle.badge.minus")
                Label("Transfer Out", systemImage: "arrow.right.square")
                Spacer()
            }
            .font(.caption)
            .foregroundStyle(.secondary)

            List {
                ForEach(store.data.learners) { learner in
                    let inactive = store.inactiveStatusBeforeAP(learner, ap: store.selectedAP)
                    let entry = learner.assessments[store.selectedAP]
                    let previous = store.levelBeforeAP(learner, ap: store.selectedAP)
                    let newLevel = store.levelAfterAP(learner, ap: store.selectedAP)
                    let hasOverride = !(entry?.overrideLevel ?? "").isEmpty

                    VStack(alignment: .leading, spacing: 7) {
                        HStack(spacing: 12) {
                            Text(learner.displayName.isEmpty ? "Unnamed learner" : learner.displayName)
                                .frame(minWidth: 225, alignment: .leading)
                                .bold()

                            VStack(alignment: .leading) {
                                Text("Previous").font(.caption2).foregroundStyle(.secondary)
                                Text(previous.isEmpty ? "—" : previous)
                                    .monospaced()
                            }
                            .frame(width: 105, alignment: .leading)

                            if let inactive {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(statusLabel(inactive.status))
                                        .bold()
                                    Text("Inactive since \(inactive.period)")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                                .frame(minWidth: 235, alignment: .leading)
                            } else {
                                Picker("Status", selection: resultBinding(for: learner.id)) {
                                    Text("Select Status").tag("")
                                    Text("READY").tag("READY")
                                    Text("NOT READY").tag("NOT READY")
                                    Text("REVERTED").tag("REVERTED")
                                    Divider()
                                    Text("NLS – No Longer in School").tag("NLS")
                                    Text("NLP – No Longer Participating").tag("NLP")
                                    Text("TRANSFER OUT").tag("TRANSFER OUT")
                                }
                                .frame(width: 245)

                                Image(systemName: "arrow.right")
                                    .foregroundStyle(.secondary)

                                VStack(alignment: .leading) {
                                    HStack(spacing: 5) {
                                        Text("New Level").font(.caption2).foregroundStyle(.secondary)
                                        if hasOverride {
                                            Text("MANUAL")
                                                .font(.system(size: 8, weight: .bold))
                                                .padding(.horizontal, 5)
                                                .padding(.vertical, 2)
                                                .background(Color.orange.opacity(0.15))
                                                .clipShape(Capsule())
                                        }
                                    }
                                    Text(newLevel.isEmpty ? "—" : newLevel)
                                        .monospaced()
                                        .bold()
                                }
                                .frame(width: 118, alignment: .leading)

                                Button {
                                    beginLevelEdit(learner)
                                } label: {
                                    Label("Edit Level", systemImage: "pencil")
                                }
                                .buttonStyle(.bordered)
                                .disabled(
                                    entry?.result.isEmpty != false ||
                                    store.isInactiveStatus(entry?.result ?? "")
                                )

                                if hasOverride {
                                    Button {
                                        clearManualOverride(learner)
                                    } label: {
                                        Image(systemName: "arrow.uturn.backward")
                                    }
                                    .buttonStyle(.borderless)
                                    .help("Restore automatic level")
                                }
                            }

                            Spacer()
                        }

                        if let entry, store.isInactiveStatus(entry.result), inactive == nil {
                            Text("\(statusLabel(entry.result)) starts in \(store.selectedAP). The learner's last reading level is retained, and succeeding APs will be marked inactive.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .padding(.leading, 342)
                        } else if hasOverride, let note = entry?.note, !note.isEmpty {
                            Text("Manual adjustment note: \(note)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .padding(.leading, 342)
                        }
                    }
                    .padding(.vertical, 5)
                }
            }
            .listStyle(.inset(alternatesRowBackgrounds: true))
        }
        .padding(28)
        .sheet(isPresented: Binding(
            get: { editingLearnerID != nil },
            set: { if !$0 { editingLearnerID = nil } }
        )) {
            if let learner = editingLearner {
                let previous = store.levelBeforeAP(learner, ap: store.selectedAP)
                let status = learner.assessments[store.selectedAP]?.result ?? ""
                let automatic = store.defaultLevelAfter(result: status, from: previous)

                VStack(alignment: .leading, spacing: 18) {
                    Text("Edit Reading Level")
                        .font(.title2.bold())

                    Text(learner.displayName)
                        .font(.headline)

                    Grid(alignment: .leading, horizontalSpacing: 18, verticalSpacing: 9) {
                        GridRow {
                            Text("Assessment Period").foregroundStyle(.secondary)
                            Text(store.selectedAP).bold()
                        }
                        GridRow {
                            Text("Previous Level").foregroundStyle(.secondary)
                            Text(previous.isEmpty ? "—" : previous).bold()
                        }
                        GridRow {
                            Text("Status").foregroundStyle(.secondary)
                            Text(statusLabel(status)).bold()
                        }
                        GridRow {
                            Text("Automatic Level").foregroundStyle(.secondary)
                            Text(automatic.isEmpty ? "—" : automatic).bold()
                        }
                    }

                    Divider()

                    Picker("Manual Level", selection: $manualLevel) {
                        ForEach(readingLevels) { level in
                            Text(level.code).tag(level.code)
                        }
                    }

                    TextField("Reason / Note (optional)", text: $manualNote)

                    Text("Use this only for special cases, such as a learner jumping several levels forward or reverting more than one level.")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    HStack {
                        Spacer()
                        Button("Cancel") {
                            editingLearnerID = nil
                        }
                        Button("Apply Manual Level") {
                            showOverrideConfirmation = true
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(manualLevel.isEmpty)
                    }
                }
                .padding(24)
                .frame(width: 520, height: 410)
                .alert("Confirm Manual Level Change", isPresented: $showOverrideConfirmation) {
                    Button("Cancel", role: .cancel) { }
                    Button("Confirm") {
                        saveManualLevel()
                    }
                } message: {
                    Text("\(learner.displayName)\n\(previous) → \(manualLevel)\n\nThis overrides the normal automatic progression for \(store.selectedAP).")
                }
            }
        }
    }
}

struct ReportsView: View {
    @ObservedObject var store: AppStore
    @State private var stage = "PRETEST"
    @State private var printout: PrintoutType = .classroomMonitoring

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                PageHeader(title: "Reports", subtitle: "Two official BULIG print-outs based on the Excel forms")

                HStack(spacing: 14) {
                    Picker("Print-out", selection: $printout) {
                        ForEach(PrintoutType.allCases) { item in Text(item.rawValue).tag(item) }
                    }
                    .frame(width: 330)

                    Picker("Assessment Period", selection: $stage) {
                        Text("PRETEST").tag("PRETEST")
                        ForEach(assessmentPeriods, id: \.self) { Text($0).tag($0) }
                    }
                    .frame(width: 210)

                    Spacer()
                    Button { store.previewReport(stage: stage, type: printout) } label: {
                        Label("Preview", systemImage: "eye")
                    }
                    Button { store.printReport(stage: stage, type: printout) } label: {
                        Label("Print", systemImage: "printer")
                    }
                    Button { store.savePDFReport(stage: stage, type: printout) } label: {
                        Label("Save as PDF", systemImage: "arrow.down.doc")
                    }
                    .buttonStyle(.borderedProminent)
                }

                if printout == .classroomMonitoring {
                    GroupBox("CLASSROOM READING MONITORING REPORT") {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Assessment Period").foregroundStyle(.secondary)
                                Text(stage).bold()
                                Spacer()
                                Text("Term").foregroundStyle(.secondary)
                                Text(store.data.assessmentTerms[stage] ?? "1ST").bold()
                            }
                            Grid(alignment: .leading, horizontalSpacing: 34, verticalSpacing: 8) {
                                GridRow { Text("LEVEL").bold(); Text("MALE").bold(); Text("FEMALE").bold(); Text("TOTAL").bold() }
                                Divider()
                                ForEach(store.reportRows(stage: stage), id: \.0) { row in
                                    GridRow { Text(row.0).bold(); Text("\(row.1)"); Text("\(row.2)"); Text("\(row.3)").bold() }
                                }
                            }
                            Divider()
                            if store.keyStage() > 0 {
                                Text("KEY STAGE \(store.keyStage()) ONLY").font(.headline)
                                Text("The print/PDF will include only this Key Stage table. Key Stages not applicable to Grade \(store.data.settings.gradeLevel) will not be printed.")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            } else {
                                Label("Set the Grade Level in Setup before printing.", systemImage: "exclamationmark.triangle.fill")
                                    .foregroundStyle(.orange)
                            }
                        }
                        .padding(12)
                    }
                } else {
                    GroupBox("LIST OF PUPILS") {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("The print-out follows the PRETEST LIPS / APLIST format and is printed in A4 portrait.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            HStack {
                                Text("Male").bold(); Text("\(store.data.learners.filter { $0.sex == "Male" }.count)")
                                Text("Female").bold(); Text("\(store.data.learners.filter { $0.sex == "Female" }.count)")
                                Spacer()
                                Text("Total Enrollment").bold(); Text("\(store.data.learners.count)")
                            }
                            Divider()
                            ForEach(store.learnersForStage(stage).prefix(12), id: \.0.id) { learner, level in
                                HStack {
                                    Text(learner.displayName.isEmpty ? "Unnamed learner" : learner.displayName).frame(minWidth: 300, alignment: .leading)
                                    Text(learner.sex).frame(width: 70, alignment: .leading)
                                    Text(level.isEmpty ? "—" : level).monospaced().bold()
                                }
                            }
                            if store.data.learners.count > 12 {
                                Text("… and \(store.data.learners.count - 12) more learner(s) in the printed report.")
                                    .font(.caption).foregroundStyle(.secondary)
                            }
                        }
                        .padding(12)
                    }
                }

                GroupBox("Color Legend") {
                    LazyVGrid(
                        columns: [
                            GridItem(.flexible(), spacing: 12),
                            GridItem(.flexible(), spacing: 12),
                            GridItem(.flexible(), spacing: 12)
                        ],
                        alignment: .leading,
                        spacing: 10
                    ) {
                        ForEach(readingLevels) { level in
                            HStack(spacing: 9) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color(nsColor: reportLevelColor(level.code)))
                                    .frame(width: 34, height: 22)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 4)
                                            .stroke(Color.secondary.opacity(0.45), lineWidth: 1)
                                    )
                                VStack(alignment: .leading, spacing: 1) {
                                    Text(level.code).bold()
                                    Text(level.area.capitalized)
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                    .padding(10)
                }
            }
            .padding(28)
        }
    }
}

struct BackupView: View {
    @ObservedObject var store: AppStore
    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            PageHeader(title: "Backup & Restore", subtitle: "Keep an offline copy of your BULIG data")
            HStack(spacing: 18) {
                GroupBox("Backup") {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Save school setup, learners, pre-assessment, and AP1–AP15 entries into one JSON backup file.")
                            .foregroundStyle(.secondary)
                        Button { store.exportBackup() } label: {
                            Label("Save Backup", systemImage: "square.and.arrow.down")
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                GroupBox("Restore") {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Restore a previously saved BULIG backup. The current data will be replaced by the selected backup.")
                            .foregroundStyle(.secondary)
                        Button { store.restoreBackup() } label: {
                            Label("Restore Backup", systemImage: "arrow.counterclockwise")
                        }
                    }
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            Spacer()
        }
        .padding(28)
    }
}

@main
struct BULIGRMSTeacherApp: App {
    var body: some Scene {
        WindowGroup("BULIG RMS Teacher") {
            RootView()
        }
        .defaultSize(width: 1280, height: 800)
        .commands {
            CommandGroup(replacing: .newItem) { }
            CommandGroup(after: .appInfo) {
                Divider()
                Text("BULIG RMS Teacher v0.18 • Offline macOS App")
            }
        }
    }
}
