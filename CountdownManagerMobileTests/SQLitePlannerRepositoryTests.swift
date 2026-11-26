import Foundation
import Testing
@testable import CountdownManagerMobile

struct SQLitePlannerRepositoryTests {
    @Test func newPlannerUsesAutomaticLocation() throws {
        try withDirectory { directory in
            let data = try SQLitePlannerRepository(directory: directory).load()
            #expect(data == PlannerData())
            #expect(data.settings.weatherMode == .automatic)
        }
    }

    @Test func firstLaunchStartsWithAnEmptyDatabaseEvenWithAnOldJSONFile() throws {
        try withDirectory { directory in
            let legacy = directory.appending(path: "planner.json")
            let saved = PlannerData(plans: [Plan(title: "Old plan")])
            let bytes = try JSONEncoder().encode(saved)
            try bytes.write(to: legacy)

            #expect(try SQLitePlannerRepository(directory: directory).load() == PlannerData())
            #expect(try Data(contentsOf: legacy) == bytes)
        }
    }

    @Test func recordsSurviveReopeningAndRetainExactTimestamps() throws {
        try withDirectory { directory in
            let date = Date(timeIntervalSinceReferenceDate: 850_000_000.1234567)
            let plan = Plan(
                title: "Поездка", day: date, note: "Помнить билеты", isFavorite: true,
                checklist: [.init(title: "Pack", isDone: true), .init(title: "Check tickets")],
                advanceNotice: .oneWeek
            )
            let initial = PlannerData(
                plans: [plan, Plan(title: "Earlier", day: date.addingTimeInterval(-172_800))],
                reminders: [
                    Reminder(title: "One time", rule: .once(date), notifies: false),
                    Reminder(title: "Repeat", rule: .interval(minutes: 75, days: [.friday, .sunday], start: 500, end: 920),
                             handledThrough: date, snoozedUntil: date.addingTimeInterval(600))
                ],
                settings: Settings(appearance: .dark, showsWeather: false, city: .moscow,
                                   weatherLocationMode: .manual, notificationsEnabled: false,
                                   notificationSound: .silent, focusMinutes: 50),
                focus: FocusSession(planID: plan.id, planTitle: plan.title, minutes: 15, endsAt: date)
            )
            let repository = try SQLitePlannerRepository(directory: directory)
            try repository.save(initial, replacing: PlannerData())
            #expect(try SQLitePlannerRepository(directory: directory).load() == initial)

            var updated = initial
            updated.plans.removeFirst()
            updated.focus = nil
            updated.settings = Settings()
            updated.reminders[1].rule = .once(date.addingTimeInterval(1_800))
            updated.reminders[1].handledThrough = nil
            updated.reminders[1].snoozedUntil = nil
            try repository.save(updated, replacing: initial)

            #expect(try SQLitePlannerRepository(directory: directory).load() == updated)
        }
    }

    @Test func failedSaveRollsBackEarlierChangesInTheSameTransaction() throws {
        try withDirectory { directory in
            let repository = try SQLitePlannerRepository(directory: directory)
            let reminder = Reminder(title: "Drink water")
            let initial = PlannerData(plans: [Plan(title: "Before")], reminders: [reminder])
            try repository.save(initial, replacing: PlannerData())

            var invalid = initial
            invalid.plans[0].title = "After"
            invalid.reminders.append(reminder)
            #expect(throws: PlannerStorageError.self) { try repository.save(invalid, replacing: initial) }
            #expect(try SQLitePlannerRepository(directory: directory).load() == initial)
        }
    }

    @Test func updatingOneRecordKeepsChangesToOtherRecords() throws {
        try withDirectory { directory in
            let repository = try SQLitePlannerRepository(directory: directory)
            let initial = PlannerData(plans: [Plan(title: "Plan")], reminders: [Reminder(title: "Reminder")])
            try repository.save(initial, replacing: PlannerData())

            var reminderChange = initial
            reminderChange.reminders[0].title = "Updated reminder"
            try SQLitePlannerRepository(directory: directory).save(reminderChange, replacing: initial)

            var planChange = initial
            planChange.plans[0].title = "Updated plan"
            try repository.save(planChange, replacing: initial)

            let restored = try repository.load()
            #expect(restored.plans == planChange.plans)
            #expect(restored.reminders == reminderChange.reminders)
        }
    }

    @Test func attachmentsKeepTheirBytesAndFollowPlanAndChecklistDeletion() throws {
        try withDirectory { directory in
            let repository = try SQLitePlannerRepository(directory: directory)
            let bytes = Data("%PDF-1.4 fixture".utf8)
            let source = directory.appending(path: "source.pdf")
            try bytes.write(to: source)
            let item = ChecklistItem(title: "Book a hotel")
            let file = PlanAttachment(id: UUID(), checklistItemID: item.id, name: "Booking.pdf",
                                      contents: .file(contentType: "com.adobe.pdf", byteCount: Int64(bytes.count)))
            let address = try #require(PlanAttachment.webURL(from: "https://example.org/route"))
            let link = PlanAttachment(id: UUID(), checklistItemID: nil, name: "Route", contents: .link(address))
            let plan = Plan(title: "Trip", checklist: [item], attachments: [file, link])
            let created = PlannerData(plans: [plan])
            try repository.save(created, replacing: PlannerData(), importing: [file.id: source])

            let reopened = try SQLitePlannerRepository(directory: directory)
            let savedFile = try #require(reopened.fileURL(for: file))
            #expect(try reopened.load() == created)
            #expect(try Data(contentsOf: savedFile) == bytes)
            #expect(reopened.fileURL(for: link) == nil)

            var edited = created
            edited.plans[0].checklist = []
            edited.plans[0].attachments = [link]
            try reopened.save(edited, replacing: created)
            #expect(try reopened.load() == edited)
            #expect(!FileManager.default.fileExists(atPath: savedFile.path(percentEncoded: false)))

            try reopened.save(PlannerData(), replacing: edited)
            #expect(try reopened.load().plans.isEmpty)
        }
    }

    @Test func failedAttachmentImportRollsBackPlanAndFilesAndCanBeRetried() throws {
        try withDirectory { directory in
            let repository = try SQLitePlannerRepository(directory: directory)
            let bytes = Data([1, 2, 3])
            let source = directory.appending(path: "source.png")
            try bytes.write(to: source)
            let first = PlanAttachment(id: UUID(), checklistItemID: nil, name: "First.png",
                                       contents: .file(contentType: "public.png", byteCount: Int64(bytes.count)))
            let second = PlanAttachment(id: UUID(), checklistItemID: nil, name: "Second.png",
                                        contents: first.contents)
            let created = PlannerData(plans: [Plan(title: "Trip", attachments: [first, second])])
            #expect(throws: PlannerStorageError.self) {
                try repository.save(created, replacing: PlannerData(), importing: [first.id: source])
            }

            let savedFile = try #require(repository.fileURL(for: first))
            #expect(try repository.load() == PlannerData())
            #expect(!FileManager.default.fileExists(atPath: savedFile.path(percentEncoded: false)))
            try repository.save(created, replacing: PlannerData(), importing: [first.id: source, second.id: source])
            #expect(try repository.load() == created)
            #expect(try Data(contentsOf: savedFile) == bytes)
        }
    }

    @Test func sharingInAnotherConnectionPreservesThePlanAndRoutesToItOnce() throws {
        try withDirectory { directory in
            let legacy = directory.appending(path: "legacy")
            let shared = directory.appending(path: "shared")
            let bytes = Data([4, 5, 6])
            let source = directory.appending(path: "source.png")
            try bytes.write(to: source)
            let file = PlanAttachment(id: UUID(), checklistItemID: nil, name: "Photo.png",
                                      contents: .file(contentType: "public.png", byteCount: Int64(bytes.count)))
            let initial = PlannerData(plans: [Plan(title: "Original", attachments: [file])])
            try SQLitePlannerRepository(directory: legacy).save(initial, replacing: PlannerData(), importing: [file.id: source])
            try PlannerSharedLocation.prepare(legacy: legacy, shared: shared)

            let app = try SQLitePlannerRepository(directory: shared)
            let shareExtension = try SQLitePlannerRepository(directory: shared)
            let beforeShare = try app.load()
            #expect(beforeShare == initial)
            let savedFile = try #require(app.fileURL(for: file))
            #expect(try Data(contentsOf: savedFile) == bytes)

            let id = initial.plans[0].id
            let address = try #require(PlanAttachment.webURL(from: "example.org"))
            let link = PlanAttachment(id: UUID(), checklistItemID: nil, name: "Link", contents: .link(address))
            try shareExtension.addSharedAttachments([link], to: id, importing: [:])

            var edited = beforeShare
            edited.plans[0].title = "Renamed"
            try app.save(edited, replacing: beforeShare)
            let pending = try app.consumeSharedUpdate()
            let update = try #require(pending)
            #expect(update.planID == id)
            #expect(update.data.plans[0].title == "Renamed")
            #expect(update.data.plans[0].attachments == [file, link])
            #expect(try app.consumeSharedUpdate() == nil)

            try PlannerSharedLocation.prepare(legacy: legacy, shared: shared)
            #expect(try SQLitePlannerRepository(directory: shared).load() == update.data)
            #expect(try SQLitePlannerRepository(directory: legacy).load() == initial)
        }
    }

    private func withDirectory(_ body: (URL) throws -> Void) throws {
        let directory = URL.temporaryDirectory.appending(path: UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        try body(directory)
    }
}
