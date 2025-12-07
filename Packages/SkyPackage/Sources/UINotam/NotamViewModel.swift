//
//  NotamViewModel.swift
//  SkyPackage
//
//  Created by Igor Voynov on 14. 4. 25.
//

import SwiftUI
import Horizon
import SrvNotam

@HorizonViewModel
@Observable
@MainActor
final class NotamViewModel {
  
  struct Day: Hashable {
    let date: Date
    let title: String
    let isCurrentMonth: Bool
  }
  
  let calendar = Calendar.current
  
  private(set) var displayedMonth: Date = .init()
  private(set) var displayedMonthText: String = ""
  private(set) var weekdays: [String] = []
  private(set) var days: [Day] = []
  private(set) var selectedDate: Date? = nil
//  private(set) var notams: [Notam] = []
  
  var todayWeekdayIndex: Int {
    let originalIndex = calendar.component(.weekday, from: Date()) - 1
    return (originalIndex + 6) % 7
  }

  
  private let formatter: DateFormatter = {
    let f = DateFormatter()
    f.dateFormat = "MMMM yyyy"
    return f
  }()
  

  enum Action {
    case onAppear
    case onDisappear
    case changeMonth(Int)
    case setSelectedDate(Date?)
  }
  
  private func handleAction(_ action: Action) async {
    switch action {
    case .onAppear:
      do {
        let notams = try await NotamService().fromDatabase(list: ["ULLI"], sphere: .arp)
        print("notams.count:", notams.count)
      } catch {
        print(error.localizedDescription)
      }
      let symbols = calendar.shortStandaloneWeekdaySymbols
      weekdays = Array(symbols [1...6] + [symbols[0]])
      displayedMonthText = formatter.string(from: displayedMonth)
      days = generateMonthGrid()
      fillNotams()
    case .onDisappear:
      await cancelAllTasks()
    case .changeMonth(let value):
      displayedMonth = calendar.date(byAdding: .month, value: value, to: displayedMonth) ?? displayedMonth
      displayedMonthText = formatter.string(from: displayedMonth)
      days = generateMonthGrid()
    case .setSelectedDate(let date):
      selectedDate = date
    }
  }
  
  private func generateMonthGrid() -> [Day] {
    guard let monthInterval = calendar.dateInterval(of: .month, for: displayedMonth),
          let firstWeek = calendar.dateInterval(of: .weekOfMonth, for: monthInterval.start),
          let lastWeek = calendar.dateInterval(of: .weekOfMonth, for: monthInterval.end - 1)
    else { return [] }
    let dates = stride(from: firstWeek.start, through: lastWeek.end, by: 86400).map { $0 }
    
    var days: [Day] = []
    for date in dates {
      let isCurrentMonth = calendar.isDate(date, equalTo: displayedMonth, toGranularity: .month)
      let title = calendar.component(.day, from: date)
      days.append(Day(date: date, title: String(title), isCurrentMonth: isCurrentMonth))
    }
    return days
  }
  
  private func fillNotams() {
    let f = DateFormatter()
    f.dateFormat = "yyyy-MM-dd"
//    notams = [
//      Notam(date: f.date(from: "2025-04-01")!, title: "Team meeting"),
//      Notam(date: f.date(from: "2025-04-01")!, title: "Write blog post"),
//      Notam(date: f.date(from: "2025-04-04")!, title: "Code review"),
//      Notam(date: f.date(from: "2025-04-08")!, title: "Submit report"),
//      Notam(date: f.date(from: "2025-04-08")!, title: "Buy groceries"),
//      Notam(date: f.date(from: "2025-04-09")!, title: "Gym session"),
//      Notam(date: f.date(from: "2025-04-10")!, title: "Prepare slides"),
//      Notam(date: f.date(from: "2025-04-12")!, title: "Call client"),
//      Notam(date: f.date(from: "2025-04-17")!, title: "Dentist appointment"),
//      Notam(date: f.date(from: "2025-04-17")!, title: "Submit taxes"),
//      Notam(date: f.date(from: "2025-04-17")!, title: "Update resume"),
//      Notam(date: f.date(from: "2025-04-27")!, title: "Dinner with friends")
//    ]
  }

}

//struct Notam: Identifiable {
//  let id = UUID()
//  let date: Date
//  let title: String
//}
