import SwiftUI
import AppKit

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
}

struct Learner: Identifiable, Codable, Equatable {
    var id = UUID()
    var lrn = ""
    var fullName = ""
    var sex = ""
    var dateOfBirth = ""
    var pre = PreAssessment()
    var assessments: [String: AssessmentEntry] = [:]
}

struct AppData: Codable, Equatable {
    var settings = SchoolSettings()
    var assessmentTerms: [String: String] = Dictionary(uniqueKeysWithValues: (1...15).map { ("AP\($0)", "1ST") })
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
let results = ["", "READY", "NOT READY", "NLP"]

@MainActor
final class AppStore: ObservableObject {
    @Published var data = AppData()
    @Published var selectedAP = "AP1"
    @Published var statusMessage = "Ready"
    private let appName = "BULIG RMS Teacher"

    init() { load() }

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

    func nextLevel(_ level: String) -> String {
        guard let idx = readingLevels.firstIndex(where: { $0.code == level }) else { return level }
        return readingLevels[min(idx + 1, readingLevels.count - 1)].code
    }

    func levelBeforeAP(_ learner: Learner, ap: String) -> String {
        var level = learner.pre.level
        guard !level.isEmpty else { return "" }
        let target = assessmentPeriods.firstIndex(of: ap) ?? 0
        if target == 0 { return level }
        for i in 0..<target {
            let key = assessmentPeriods[i]
            if learner.assessments[key]?.result == "READY" { level = nextLevel(level) }
        }
        return level
    }

    func levelAfterAP(_ learner: Learner, ap: String) -> String {
        let before = levelBeforeAP(learner, ap: ap)
        if learner.assessments[ap]?.result == "READY" { return nextLevel(before) }
        return before
    }

    func currentLevel(_ learner: Learner, through ap: String?) -> String {
        guard let ap else { return learner.pre.level }
        var level = learner.pre.level
        guard !level.isEmpty else { return "" }
        for key in assessmentPeriods {
            if learner.assessments[key]?.result == "READY" { level = nextLevel(level) }
            if key == ap { break }
        }
        return level
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
            data.learners.append(Learner(lrn: maybeLRN, fullName: cols[1], sex: sex, dateOfBirth: dob))
            added += 1
        }
        save()
        return added
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
                let current = stage == "PRETEST" ? learner.pre.level : currentLevel(learner, through: stage)
                return current == level.code
            }
            let male = matches.filter { $0.sex == "Male" }.count
            let female = matches.filter { $0.sex == "Female" }.count
            return (level.code, male, female, male + female)
        }
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
        lines.append("Assessment: \(stage == "PRETEST" ? "PRE-TEST" : stage)")
        lines.append("")
        lines.append("LEVEL\tMALE\tFEMALE\tTOTAL")
        for row in reportRows(stage: stage) {
            lines.append("\(row.0)\t\(row.1)\t\(row.2)\t\(row.3)")
        }
        lines.append("")
        lines.append("TOTAL LEARNERS: \(data.learners.count)")
        lines.append("Generated by BULIG RMS Teacher")
        return lines.joined(separator: "\n")
    }

    func printReport(stage: String) {
        let textView = NSTextView(frame: NSRect(x: 0, y: 0, width: 720, height: 900))
        textView.string = reportText(stage: stage)
        textView.font = NSFont.monospacedSystemFont(ofSize: 12, weight: .regular)
        textView.isEditable = false
        let op = NSPrintOperation(view: textView)
        op.showsPrintPanel = true
        op.showsProgressPanel = true
        op.run()
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
                    Button("Save Setup") { store.save() }.buttonStyle(.borderedProminent)
                }
            }
            .padding(28)
        }
    }
}

struct LearnersView: View {
    @ObservedObject var store: AppStore
    @State private var importMessage = ""
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            PageHeader(title: "Learners", subtitle: "Learner master list and SF1 paste import")
            HStack {
                Button { store.addLearner() } label: {
                    Label("Add Learner", systemImage: "plus")
                }
                .buttonStyle(.borderedProminent)
                Button {
                    let n = store.importFromClipboard()
                    importMessage = n > 0 ? "Imported \(n) learner(s)." : "No valid new learners found. Copy tab-separated SF1 rows first."
                } label: {
                    Label("Paste from SF1", systemImage: "doc.on.clipboard")
                }
                Text(importMessage).font(.caption).foregroundStyle(.secondary)
                Spacer()
                Text("\(store.data.learners.count) learners").foregroundStyle(.secondary)
            }
            List {
                ForEach($store.data.learners) { $learner in
                    HStack(spacing: 10) {
                        TextField("12-digit LRN", text: $learner.lrn).frame(width: 135)
                        TextField("Learner Name", text: $learner.fullName).frame(minWidth: 260)
                        Picker("", selection: $learner.sex) {
                            Text("Sex").tag("")
                            Text("Male").tag("Male")
                            Text("Female").tag("Female")
                        }
                        .frame(width: 110)
                        TextField("Birth Date", text: $learner.dateOfBirth).frame(width: 120)
                    }
                    .padding(.vertical, 4)
                }
                .onDelete(perform: store.deleteLearners)
            }
            .listStyle(.inset(alternatesRowBackgrounds: true))
        }
        .padding(28)
    }
}

struct PreAssessmentView: View {
    @ObservedObject var store: AppStore
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            PageHeader(title: "Pre-Assessment", subtitle: "Encode each learner's initial reading level and profile")
            HStack {
                Text("Automatic Key Stage:").foregroundStyle(.secondary)
                Text(store.keyStage() == 0 ? "Select a grade level in Setup" : "Key Stage \(store.keyStage())").bold()
                Spacer()
            }
            List {
                ForEach($store.data.learners) { $learner in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(learner.fullName.isEmpty ? "Unnamed learner" : learner.fullName)
                                .bold()
                                .frame(minWidth: 220, alignment: .leading)
                            Picker("Initial Level", selection: $learner.pre.level) {
                                Text("Select Level").tag("")
                                ForEach(readingLevels) { Text($0.code).tag($0.code) }
                            }
                            .frame(width: 170)
                            Text(readingLevels.first(where: {$0.code == learner.pre.level})?.area ?? "—")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .frame(minWidth: 220, alignment: .leading)
                        }
                        HStack {
                            Picker("BOSY", selection: $learner.pre.bosy) {
                                ForEach(store.profileOptions(), id: \.self) { Text($0.isEmpty ? "BOSY" : $0).tag($0) }
                            }
                            .frame(width: 190)
                            Picker("MOSY", selection: $learner.pre.mosy) {
                                ForEach(store.profileOptions(), id: \.self) { Text($0.isEmpty ? "MOSY" : $0).tag($0) }
                            }
                            .frame(width: 190)
                            Picker("EOSY", selection: $learner.pre.eosy) {
                                ForEach(store.profileOptions(), id: \.self) { Text($0.isEmpty ? "EOSY" : $0).tag($0) }
                            }
                            .frame(width: 190)
                        }
                    }
                    .padding(.vertical, 5)
                }
            }
            .listStyle(.inset(alternatesRowBackgrounds: true))
        }
        .padding(28)
    }
}

struct MonitoringView: View {
    @ObservedObject var store: AppStore

    func resultBinding(for learnerID: UUID) -> Binding<String> {
        Binding(
            get: {
                store.data.learners.first(where: {$0.id == learnerID})?.assessments[store.selectedAP]?.result ?? ""
            },
            set: { newValue in
                guard let index = store.data.learners.firstIndex(where: {$0.id == learnerID}) else { return }
                store.data.learners[index].assessments[store.selectedAP] = AssessmentEntry(result: newValue)
                store.save()
            }
        )
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
                Text("READY advances one level • NOT READY/NLP retains level")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            List {
                ForEach(store.data.learners) { learner in
                    HStack(spacing: 12) {
                        Text(learner.fullName.isEmpty ? "Unnamed learner" : learner.fullName)
                            .frame(minWidth: 240, alignment: .leading)
                            .bold()
                        VStack(alignment: .leading) {
                            Text("Previous").font(.caption2).foregroundStyle(.secondary)
                            Text(store.levelBeforeAP(learner, ap: store.selectedAP).isEmpty ? "—" : store.levelBeforeAP(learner, ap: store.selectedAP))
                                .monospaced()
                        }
                        .frame(width: 115, alignment: .leading)
                        Picker("Result", selection: resultBinding(for: learner.id)) {
                            ForEach(results, id: \.self) { Text($0.isEmpty ? "Select Result" : $0).tag($0) }
                        }
                        .frame(width: 170)
                        Image(systemName: "arrow.right").foregroundStyle(.secondary)
                        VStack(alignment: .leading) {
                            Text("New Level").font(.caption2).foregroundStyle(.secondary)
                            Text(store.levelAfterAP(learner, ap: store.selectedAP).isEmpty ? "—" : store.levelAfterAP(learner, ap: store.selectedAP))
                                .monospaced()
                                .bold()
                        }
                        .frame(width: 115, alignment: .leading)
                        Spacer()
                    }
                    .padding(.vertical, 5)
                }
            }
            .listStyle(.inset(alternatesRowBackgrounds: true))
        }
        .padding(28)
    }
}

struct ReportsView: View {
    @ObservedObject var store: AppStore
    @State private var stage = "PRETEST"
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                PageHeader(title: "Reports", subtitle: "CRM summary and printable report")
                HStack {
                    Picker("Report", selection: $stage) {
                        Text("Pre-Test").tag("PRETEST")
                        ForEach(assessmentPeriods, id: \.self) { Text($0).tag($0) }
                    }
                    .frame(width: 220)
                    Spacer()
                    Button { store.exportCSV(stage: stage) } label: {
                        Label("Export CSV", systemImage: "square.and.arrow.up")
                    }
                    Button { store.printReport(stage: stage) } label: {
                        Label("Print / Save PDF", systemImage: "printer")
                    }
                    .buttonStyle(.borderedProminent)
                }
                GroupBox(stage == "PRETEST" ? "CRM Report – Pre-Test" : "CRM Report – \(stage)") {
                    Grid(alignment: .leading, horizontalSpacing: 34, verticalSpacing: 9) {
                        GridRow {
                            Text("LEVEL").bold()
                            Text("MALE").bold()
                            Text("FEMALE").bold()
                            Text("TOTAL").bold()
                        }
                        Divider()
                        ForEach(store.reportRows(stage: stage), id: \.0) { row in
                            GridRow {
                                Text(row.0).bold()
                                Text("\(row.1)").monospacedDigit()
                                Text("\(row.2)").monospacedDigit()
                                Text("\(row.3)").monospacedDigit().bold()
                            }
                        }
                        Divider()
                        GridRow {
                            Text("TOTAL LEARNERS").bold()
                            Text("")
                            Text("")
                            Text("\(store.data.learners.count)").bold()
                        }
                    }
                    .padding(12)
                }
                GroupBox("Class Details") {
                    Text(store.reportText(stage: stage))
                        .font(.system(.caption, design: .monospaced))
                        .textSelection(.enabled)
                        .padding(8)
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
                Text("BULIG RMS Teacher • Offline macOS App")
            }
        }
    }
}
