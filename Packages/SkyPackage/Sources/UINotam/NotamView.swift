//
//  NotamView.swift
//  SkyPackage
//
//  Created by Igor Voynov on 14. 4. 25.
//
// https://youtu.be/3zE6m1H_7Bo - SwiftUI Tutorial Custom Calendar
// https://youtu.be/pYk2dz8tDDA - SwiftUI Expanded Calendar
// https://youtu.be/iPTBqYJBczc - SwiftUI Custom Week Calendar

// https://youtu.be/QGcp2fxWkxs - Highlight text
// https://youtu.be/PMIwLf9iEvc - list animation
// https://youtu.be/3NRLlXXMN3I - scroll indicator
// https://youtu.be/Cb5_LCBZFqs - change theme
// https://youtu.be/cmJudhQH_co - SwiftUI Tutorial Shimmer Animation Effect
import SwiftUI
import Horizon

import Extensions

@HorizonView
public struct NotamView: View {
  
  @State private var viewModel = NotamViewModel()
  
  public init() {}
  
  public var body: some View {
    VStack {
      CalendarView()
    }
    .onDisappearAsync {
      await viewModel.send(.onDisappear)
    }
  }
  
}

//@HorizonView
//public struct NotamView: View {
//
//  @State private var viewModel = NotamViewModel()
//
//  public init() {}
//
//  public var body: some View {
//    VStack {
//      CalendarView()
//        .environment(viewModel)
//      ListView()
//        .environment(viewModel)
//    }
//    .padding()
//    .onAppearAsync {
//      await viewModel.send(.onAppear)
//    }
//    .onDisappearAsync {
//      await viewModel.send(.onDisappear)
//    }
//  }
//
//}
//
//private struct CalendarView: View {
//  @Environment(NotamViewModel.self) private var viewModel
//
//  public var body: some View {
//    VStack {
//      HeaderView()
//        .environment(viewModel)
//
//      LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 2), count: 7), spacing: 2) {
//        ForEach(viewModel.days, id: \.self) { day in
//          let notamsForDay = viewModel.notams.filter { viewModel.calendar.isDate($0.date, inSameDayAs: day.date) }
//          let isSelected = viewModel.selectedDate != nil && viewModel.calendar.isDate(viewModel.selectedDate!, inSameDayAs: day.date)
//          VStack(spacing: 4) {
//            Text(day.title)
//              .font(.system(size: 15))
//              .frame(maxWidth: .infinity, minHeight: 45)
//              .foregroundColor(isSelected ? Color.se : (day.isCurrentMonth ? .primary : .gray ))
//              .background(isSelected ? Color.primary : (day.isCurrentMonth ? Color.BG : .gray.opacity(0.2)))
//              .clipShape(RoundedRectangle(cornerRadius: 8))
//              .overlay {
//                RoundedRectangle(cornerRadius: 8)
//                  .stroke(lineWidth: 1)
//                  .foregroundStyle(viewModel.calendar.isDateInToday(day.date) ? Color.primary : .clear)
//                  .padding (1)
//              }
//              .overlay(alignment: .bottom) {
//                HStack(spacing: 3) {
//                  ForEach(0..<min(notamsForDay.count, 5), id: \.self) { _ in
//                    Circle()
//                      .frame(width: 4, height: 4)
//                      .padding(.bottom, 6)
//                      .foregroundStyle(isSelected ? Color.se : Color.primary)
//                  }
//                }
//              }
//          }
//          .onTapGestureAsync {
//            if let selected = viewModel.selectedDate, viewModel.calendar.isDate(selected, inSameDayAs: day.date) {
//              await viewModel.send(.setSelectedDate(nil))
//            } else {
//              await viewModel.send(.setSelectedDate(day.date))
//            }
//          }
//        }
//      }
//    }
//  }
//}
//
//private struct ListView: View {
//  @Environment(NotamViewModel.self) private var viewModel
//
//  public var body: some View {
//    let visibleNotams = viewModel.selectedDate != nil
//    ? viewModel.notams.filter { viewModel.calendar.isDate($0.date, inSameDayAs: viewModel.selectedDate!) }
//    : viewModel.notams
//    if visibleNotams.isEmpty {
//      Spacer()
//      Text ("No notams for this day.")
//        .foregroundColor(.gray)
//      Spacer()
//    } else {
//      let groupedNotams = Dictionary(grouping: visibleNotams, by: { $0.date.description })
//      let sections = Array(groupedNotams.keys.sorted())
//      Table(
//        sections: sections,
//        items: { section in
//          groupedNotams[section] ?? []
//        },
//        style: .init(tableStyle: .plain, separatorStyle: .none),
//        headerContent: { sectionName in
//          Text(sectionName)
//            .font(.headline)
//            .padding(.top)
//            .frame(maxWidth: .infinity, alignment: .center)
//            .background(Color(uiColor: .systemBackground))
//        },
//        rowContent: { notam in
//          HStack{
//            Text(notam.title)
//            Spacer()
//            Image(systemName: "circle")
//          }
//          .frame(height: 55)
//          .padding(.horizontal, 12) // внутренний отступ
//          .background(Color.BG, in: .rect(cornerRadius: 12))
//          .padding(.vertical, 4) // внешний отступ
//        }
//      )
//    }
//  }
//
//}
//
//private struct HeaderView: View {
//  @Environment(NotamViewModel.self) private var viewModel
//
//  public var body: some View {
//    VStack {
//      // Month
//      HStack {
//        Button(action: { await viewModel.send(.changeMonth(-1)) }, label: { Image(systemName: "chevron.left") })
//        Spacer()
//        Text(viewModel.displayedMonthText)
//          .font(.headline)
//        Spacer()
//        Button(action: { await viewModel.send(.changeMonth(1)) }, label: { Image(systemName: "chevron.right") })
//      }
//      .tint(.primary)
//      .padding(.horizontal)
//      // WeekDays
//      HStack(spacing: 2) {
//        ForEach(viewModel.weekdays.indices, id: \.self) { index in
//          Text(viewModel.weekdays[index])
//            .font(.system(size: 15))
//            .frame(maxWidth: .infinity)
//            .foregroundStyle(index == viewModel.todayWeekdayIndex ? Color.primary : Color.gray)
//            .padding(.vertical, 3)
//            .background (index == viewModel.todayWeekdayIndex ? Color.gray.opacity(0.4) : Color.gray.opacity(0.2), in: .rect(cornerRadius: 8))
//        }
//      }
//    }
//  }
//
//}
