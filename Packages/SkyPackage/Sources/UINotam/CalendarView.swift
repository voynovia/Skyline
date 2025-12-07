import SrvDatabase
import SwiftUI
import UIKit

struct CalendarView: View {
  @State private var selectedDate = Date()
  @State private var weekDates: [Date] = []
  @State private var weekPageViewController: UIPageViewController?
  @State private var dayPageViewController: UIPageViewController?

  @State private var showTodayButton = false
  @State private var todayButtonAlignment: Alignment = .trailing

  // добавляем массив notam
  @State private var notams: [DatabaseApp.Notam] = []

  // флаги для предотвращения циклических обновлений
  @State private var isUpdatingFromWeek = false
  @State private var isUpdatingFromDay = false

  private static let calendar = Calendar.current

  // кешируем форматтеры как статические для переиспользования
  private static let yearFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy"
    return formatter
  }()

  private static let monthFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "MMM"
    return formatter
  }()

  private static let dayFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "E"
    return formatter
  }()

  init() {
    let notams = [
      DatabaseApp.Notam(
        sphere: "", format: "", text: "text1", provider: "", uniformAbbreviation: "",
        validTime: Date(),
        number: "A322/3", icao: "ULLI", fromDate: Date().addingTimeInterval(.day * -1),
        toDate: Date(), toString: "", schedule: "",
        eCode: "eCode1", lowerLimit: "", upperLimit: "", fir: "FIR1", qCode: "qCode1",
        fromLevel: 10, toLevel: 900
      ),
      DatabaseApp.Notam(
        sphere: "", format: "", text: "text2", provider: "", uniformAbbreviation: "",
        validTime: Date(),
        number: "A322/5", icao: "ULLI", fromDate: Date(),
        toDate: Date().addingTimeInterval(.day * 2), toString: "", schedule: "",
        eCode: "eCode2", lowerLimit: "", upperLimit: "", fir: "FIR2", qCode: "qCode2",
        fromLevel: 10, toLevel: 900
      ),
      DatabaseApp.Notam(
        sphere: "", format: "", text: "text3", provider: "", uniformAbbreviation: "",
        validTime: Date(),
        number: "A322/8", icao: "ULLI", fromDate: Date().addingTimeInterval(.day), toDate: nil,
        toString: "", schedule: "",
        eCode: "eCode3", lowerLimit: "", upperLimit: "", fir: "FIR3", qCode: "qCode3",
        fromLevel: 10, toLevel: 900
      ),
    ]
    _notams = State(initialValue: notams)
    _weekDates = State(initialValue: Self.getWeekDates(for: Date()))
  }

  var body: some View {
    VStack(spacing: 0) {
      headerView

      ZStack {
        InfinitePageView(
          selectedDate: $selectedDate,
          weekDates: $weekDates,
          dayPageViewController: $dayPageViewController,
          notams: notams,
          onDateChanged: { newDate in
            updateSelectedDateFromDay(newDate)
          }
        )

        // кнопка today
        if showTodayButton {
          VStack {
            Spacer()
            HStack {
              if todayButtonAlignment == .leading {
                todayButton
                Spacer()
              } else {
                Spacer()
                todayButton
              }
            }
            .padding(.bottom)
            .padding(.horizontal)
          }
        }
      }
    }
    .background(Color(UIColor.systemBackground))
    .onAppear {
      updateTodayButtonVisibility(for: selectedDate)
    }
  }

  // обновление даты из day page view
  private func updateSelectedDateFromDay(_ newDate: Date) {
    guard !isUpdatingFromWeek else { return }
    guard !Self.calendar.isDate(selectedDate, inSameDayAs: newDate) else { return }

    isUpdatingFromDay = true
    defer { isUpdatingFromDay = false }

    let oldWeekDates = weekDates
    let newWeekDates = Self.getWeekDates(for: newDate)

    selectedDate = newDate

    // проверяем, изменилась ли неделя
    let weekChanged = !oldWeekDates.contains(where: {
      Self.calendar.isDate($0, inSameDayAs: newDate)
    })

    if weekChanged {
      weekDates = newWeekDates
      updateWeekPageViewController(to: newWeekDates, selectedDate: newDate, animated: false)
    } else {
      // обновляем выбранную дату в текущей неделе
      updateCurrentWeekViewController(selectedDate: newDate)
    }

    updateTodayButtonVisibility(for: newDate)
  }

  // обновление даты из week page view
  private func updateSelectedDateFromWeek(_ newDate: Date) {
    guard !isUpdatingFromDay else { return }
    guard !Self.calendar.isDate(selectedDate, inSameDayAs: newDate) else { return }

    isUpdatingFromWeek = true
    defer { isUpdatingFromWeek = false }

    selectedDate = newDate

    // обновляем day page view
    updateDayPageViewController(to: newDate)

    updateTodayButtonVisibility(for: newDate)
  }

  // обновленный метод для создания day view controller с notam
  private func updateDayPageViewController(to date: Date) {
    guard let dayPageVC = dayPageViewController else { return }

    let dayVC = DayViewController(date: date, notams: notams)
    let currentDate = (dayPageVC.viewControllers?.first as? DayViewController)?.date ?? selectedDate
    let direction: UIPageViewController.NavigationDirection =
      date > currentDate ? .forward : .reverse

    dayPageVC.setViewControllers([dayVC], direction: direction, animated: true)
  }

  // метод для обновления notam
  func updateNotams(_ newNotams: [DatabaseApp.Notam]) {
    notams = newNotams

    // обновляем текущий day view controller
    if let dayPageVC = dayPageViewController,
      let currentDayVC = dayPageVC.viewControllers?.first as? DayViewController
    {
      currentDayVC.updateNotams(newNotams)
    }
  }

  // обновление текущего week view controller
  private func updateCurrentWeekViewController(selectedDate: Date) {
    guard let weekPageVC = weekPageViewController,
      let currentWeekVC = weekPageVC.viewControllers?.first as? WeekViewController
    else { return }

    currentWeekVC.updateSelectedDate(selectedDate)
  }

  // централизованное обновление week page view controller
  private func updateWeekPageViewController(
    to newWeekDates: [Date], selectedDate: Date, animated: Bool
  ) {
    guard let weekPageVC = weekPageViewController else { return }

    let newWeekVC = WeekViewController(
      weekDates: newWeekDates,
      selectedDate: selectedDate,
      onDateSelected: { date in
        self.updateSelectedDateFromWeek(date)
      }
    )

    weekPageVC.setViewControllers([newWeekVC], direction: .forward, animated: animated)
  }

  // кнопка today
  private var todayButton: some View {
    Button(action: {
      let today = Date()
      updateSelectedDateFromDay(today)
      updateDayPageViewController(to: today)
    }) {
      HStack(spacing: 4) {
        if todayButtonAlignment == .leading {
          Image(systemName: "arrow.left.circle")
          Text("Today")
        } else {
          Text("Today")
          Image(systemName: "arrow.right.circle")
        }
      }
      .font(.title2)
      .fontWeight(.medium)
      .foregroundColor(Color(UIColor.systemBackground))
      .padding(.horizontal, 8)
      .padding(.vertical, 8)
      .background(Color(UIColor.label))
      .clipShape(Capsule())
    }
  }

  // обновляем видимость кнопки today
  private func updateTodayButtonVisibility(for date: Date) {
    let isToday = Self.calendar.isDateInToday(date)
    let shouldShow = !isToday
    let alignment: Alignment = date < Date() ? .trailing : .leading

    if showTodayButton != shouldShow || (shouldShow && todayButtonAlignment != alignment) {
      withAnimation(.spring(response: 0.2, dampingFraction: 0.9)) {
        showTodayButton = shouldShow
        if shouldShow {
          todayButtonAlignment = alignment
        }
      }
    }
  }

  // дни недели
  private var headerView: some View {
    HStack(spacing: 8) {
      VStack(alignment: .center, spacing: 0) {
        Text(Self.yearFormatter.string(from: selectedDate))
          .font(.subheadline)
          .foregroundColor(.secondary)
        Text(Self.monthFormatter.string(from: selectedDate))
          .font(.headline)
          .fontWeight(.medium)
          .frame(height: 32)
      }
      Divider()
      WeekPageView(
        selectedDate: $selectedDate,
        weekDates: $weekDates,
        weekPageViewController: $weekPageViewController,
        dayPageViewController: $dayPageViewController,
        onWeekChanged: { newWeekDates in
          weekDates = newWeekDates
        },
        onDateSelected: { date in
          updateSelectedDateFromWeek(date)
        }
      )
    }
    .frame(height: 50)
    .padding(.horizontal)
  }

  // получить даты текущей недели
  static func getWeekDates(for date: Date) -> [Date] {
    guard let weekInterval = calendar.dateInterval(of: .weekOfYear, for: date) else {
      return []
    }

    var weekStart = weekInterval.start
    // корректируем начало недели на понедельник
    if calendar.component(.weekday, from: weekStart) == 1 {
      weekStart = calendar.date(byAdding: .day, value: 1, to: weekStart) ?? weekStart
    }

    return (0..<7).compactMap { dayOffset in
      calendar.date(byAdding: .day, value: dayOffset, to: weekStart)
    }
  }

  // получить день недели
  static func getDayOfWeek(_ date: Date) -> String {
    String(dayFormatter.string(from: date).prefix(1).uppercased())
  }
}

// исправленный WeekViewController с правильным обновлением
final class WeekViewController: UIViewController {
  var weekDates: [Date]
  var selectedDate: Date
  let onDateSelected: (Date) -> Void
  private var hostingController: UIHostingController<WeekHeaderView>?

  init(weekDates: [Date], selectedDate: Date, onDateSelected: @escaping (Date) -> Void) {
    self.weekDates = weekDates
    self.selectedDate = selectedDate
    self.onDateSelected = onDateSelected
    super.init(nibName: nil, bundle: nil)
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    setupHostingController()
  }

  private func setupHostingController() {
    let weekView = WeekHeaderView(
      weekDates: weekDates,
      selectedDate: selectedDate,
      onDateSelected: { [weak self] date in
        self?.selectedDate = date
        self?.updateHostingController()
        self?.onDateSelected(date)
      }
    )
    let hostingController = UIHostingController(rootView: weekView)

    addChild(hostingController)
    view.addSubview(hostingController.view)
    hostingController.view.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      hostingController.view.topAnchor.constraint(equalTo: view.topAnchor),
      hostingController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      hostingController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      hostingController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
    ])
    hostingController.didMove(toParent: self)

    self.hostingController = hostingController
  }

  func updateSelectedDate(_ date: Date) {
    guard !Calendar.current.isDate(selectedDate, inSameDayAs: date) else { return }
    selectedDate = date
    updateHostingController()
  }

  func updateWeekDates(_ newWeekDates: [Date], selectedDate: Date) {
    self.weekDates = newWeekDates
    self.selectedDate = selectedDate
    updateHostingController()
  }

  private func updateHostingController() {
    guard let hostingController = hostingController else { return }

    let weekView = WeekHeaderView(
      weekDates: weekDates,
      selectedDate: selectedDate,
      onDateSelected: { [weak self] date in
        self?.selectedDate = date
        self?.updateHostingController()
        self?.onDateSelected(date)
      }
    )
    hostingController.rootView = weekView
  }
}

// исправленный WeekHeaderView с правильным обновлением состояния
struct WeekHeaderView: View {
  let weekDates: [Date]
  let selectedDate: Date
  let onDateSelected: (Date) -> Void

  var body: some View {
    HStack(spacing: 0) {
      ForEach(weekDates.indices, id: \.self) { index in
        WeekDayView(
          date: weekDates[index],
          selectedDate: selectedDate,
          onTap: {
            onDateSelected(weekDates[index])
          }
        )
        .frame(maxWidth: .infinity)
      }
    }
  }
}

// оптимизированный WeekDayView с правильным отображением выбранного состояния
struct WeekDayView: View {
  let date: Date
  let selectedDate: Date
  let onTap: () -> Void

  private static let calendar = Calendar.current

  private var isToday: Bool {
    Self.calendar.isDateInToday(date)
  }

  private var isSelected: Bool {
    Self.calendar.isDate(date, inSameDayAs: selectedDate)
  }

  private var dayOfWeekColor: Color {
    isToday ? .red : .secondary
  }

  private var textColor: Color {
    if isToday {
      return .white
    } else if isSelected {
      return .primary
    } else {
      let dateComponents = Self.calendar.dateComponents([.month, .year], from: date)
      let selectedComponents = Self.calendar.dateComponents([.month, .year], from: selectedDate)
      if dateComponents.month != selectedComponents.month
        || dateComponents.year != selectedComponents.year
      {
        return Color(UIColor.systemGray3)
      } else {
        return .primary
      }
    }
  }

  private var backgroundColor: Color {
    if isToday {
      return .red
    } else if isSelected {
      return Color(UIColor.systemGray4)
    } else {
      return .clear
    }
  }

  var body: some View {
    VStack(spacing: 0) {
      Text(CalendarView.getDayOfWeek(date))
        .font(.subheadline)
        .foregroundColor(dayOfWeekColor)

      Text("\(Self.calendar.component(.day, from: date))")
        .font(.headline)
        .fontWeight(.medium)
        .foregroundColor(textColor)
        .frame(width: 32, height: 32)
        .background(backgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
    .contentShape(Rectangle())
    .onTapGesture(perform: onTap)
  }
}

// остальные классы остаются без изменений
struct WeekPageView: UIViewControllerRepresentable {
  @Binding var selectedDate: Date
  @Binding var weekDates: [Date]
  @Binding var weekPageViewController: UIPageViewController?
  @Binding var dayPageViewController: UIPageViewController?
  let onWeekChanged: ([Date]) -> Void
  let onDateSelected: (Date) -> Void

  func makeUIViewController(context: Context) -> UIPageViewController {
    let pageViewController = UIPageViewController(
      transitionStyle: .scroll,
      navigationOrientation: .horizontal,
      options: nil
    )

    pageViewController.dataSource = context.coordinator
    pageViewController.delegate = context.coordinator

    let initialVC = WeekViewController(
      weekDates: weekDates,
      selectedDate: selectedDate,
      onDateSelected: onDateSelected
    )
    pageViewController.setViewControllers([initialVC], direction: .forward, animated: false)

    DispatchQueue.main.async {
      weekPageViewController = pageViewController
    }

    return pageViewController
  }

  func updateUIViewController(_ uiViewController: UIPageViewController, context: Context) {
    context.coordinator.updateParent(self)
  }

  func makeCoordinator() -> Coordinator {
    Coordinator(self)
  }

  class Coordinator: NSObject, UIPageViewControllerDataSource, UIPageViewControllerDelegate {
    var parent: WeekPageView
    private let calendar = Calendar.current

    init(_ parent: WeekPageView) {
      self.parent = parent
    }

    func updateParent(_ newParent: WeekPageView) {
      self.parent = newParent
    }

    func pageViewController(
      _ pageViewController: UIPageViewController,
      viewControllerBefore viewController: UIViewController
    ) -> UIViewController? {
      guard let weekVC = viewController as? WeekViewController,
        let firstDate = weekVC.weekDates.first,
        let previousWeekDate = calendar.date(byAdding: .weekOfYear, value: -1, to: firstDate)
      else {
        return nil
      }

      let previousWeekDates = CalendarView.getWeekDates(for: previousWeekDate)
      return WeekViewController(
        weekDates: previousWeekDates,
        selectedDate: previousWeekDates.first ?? parent.selectedDate,
        onDateSelected: parent.onDateSelected
      )
    }

    func pageViewController(
      _ pageViewController: UIPageViewController,
      viewControllerAfter viewController: UIViewController
    ) -> UIViewController? {
      guard let weekVC = viewController as? WeekViewController,
        let firstDate = weekVC.weekDates.first,
        let nextWeekDate = calendar.date(byAdding: .weekOfYear, value: 1, to: firstDate)
      else {
        return nil
      }
      let nextWeekDates = CalendarView.getWeekDates(for: nextWeekDate)
      return WeekViewController(
        weekDates: nextWeekDates,
        selectedDate: nextWeekDates.first ?? parent.selectedDate,
        onDateSelected: parent.onDateSelected
      )
    }

    func pageViewController(
      _ pageViewController: UIPageViewController, didFinishAnimating finished: Bool,
      previousViewControllers: [UIViewController], transitionCompleted completed: Bool
    ) {
      if completed,
        let currentVC = pageViewController.viewControllers?.first as? WeekViewController
      {
        DispatchQueue.main.async {
          self.parent.onWeekChanged(currentVC.weekDates)

          if let monday = currentVC.weekDates.first {
            self.parent.onDateSelected(monday)
          }
        }
      }
    }
  }
}

// MARK: - InfinitePageView

// обновленный InfinitePageView с правильной передачей notam
struct InfinitePageView: UIViewControllerRepresentable {
  @Binding var selectedDate: Date
  @Binding var weekDates: [Date]
  @Binding var dayPageViewController: UIPageViewController?
  let notams: [DatabaseApp.Notam]
  let onDateChanged: (Date) -> Void

  func makeUIViewController(context: Context) -> UIPageViewController {
    let pageViewController = UIPageViewController(
      transitionStyle: .scroll,
      navigationOrientation: .horizontal,
      options: nil
    )

    pageViewController.dataSource = context.coordinator
    pageViewController.delegate = context.coordinator

    let initialVC = DayViewController(date: selectedDate, notams: notams)
    pageViewController.setViewControllers([initialVC], direction: .forward, animated: false)

    DispatchQueue.main.async {
      dayPageViewController = pageViewController
    }

    return pageViewController
  }

  func updateUIViewController(_ uiViewController: UIPageViewController, context: Context) {
    context.coordinator.updateNotams(notams)
  }

  func makeCoordinator() -> Coordinator {
    Coordinator(self)
  }

  class Coordinator: NSObject, UIPageViewControllerDataSource, UIPageViewControllerDelegate {
    var parent: InfinitePageView
    private let calendar = Calendar.current
    private var viewControllerCache = NSCache<NSDate, DayViewController>()
    private var currentNotams: [DatabaseApp.Notam] = []

    init(_ parent: InfinitePageView) {
      self.parent = parent
      self.currentNotams = parent.notams
      super.init()
      viewControllerCache.countLimit = 7
    }

    func updateNotams(_ newNotams: [DatabaseApp.Notam]) {
      currentNotams = newNotams
      // обновляем все кешированные контроллеры
      viewControllerCache.removeAllObjects()
    }

    private func getDayViewController(for date: Date) -> DayViewController {
      let nsDate = date as NSDate
      if let cached = viewControllerCache.object(forKey: nsDate) {
        cached.updateNotams(currentNotams)
        return cached
      }

      let vc = DayViewController(date: date, notams: currentNotams)
      viewControllerCache.setObject(vc, forKey: nsDate)
      return vc
    }

    func pageViewController(
      _ pageViewController: UIPageViewController,
      viewControllerBefore viewController: UIViewController
    ) -> UIViewController? {
      guard let dayVC = viewController as? DayViewController,
        let previousDate = calendar.date(byAdding: .day, value: -1, to: dayVC.date)
      else {
        return nil
      }
      return getDayViewController(for: previousDate)
    }

    func pageViewController(
      _ pageViewController: UIPageViewController,
      viewControllerAfter viewController: UIViewController
    ) -> UIViewController? {
      guard let dayVC = viewController as? DayViewController,
        let nextDate = calendar.date(byAdding: .day, value: 1, to: dayVC.date)
      else {
        return nil
      }
      return getDayViewController(for: nextDate)
    }

    func pageViewController(
      _ pageViewController: UIPageViewController, didFinishAnimating finished: Bool,
      previousViewControllers: [UIViewController], transitionCompleted completed: Bool
    ) {
      if completed,
        let currentVC = pageViewController.viewControllers?.first as? DayViewController
      {
        DispatchQueue.main.async {
          self.parent.onDateChanged(currentVC.date)
        }
      }
    }
  }
}

final class DayViewController: UIViewController {
  let date: Date
  private var notams: [DatabaseApp.Notam] = []
  private var hostingController: UIHostingController<DayNotamView>?

  init(date: Date, notams: [DatabaseApp.Notam] = []) {
    self.date = date
    self.notams = notams
    super.init(nibName: nil, bundle: nil)
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    setupHostingController()
  }

  private func setupHostingController() {
    let dayName = CalendarView.getDayOfWeek(date)
    let dayView = DayNotamView(day: dayName, date: date, notams: notams)
    let hostingController = UIHostingController(rootView: dayView)

    addChild(hostingController)
    view.addSubview(hostingController.view)
    hostingController.view.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      hostingController.view.topAnchor.constraint(equalTo: view.topAnchor),
      hostingController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      hostingController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      hostingController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
    ])
    hostingController.didMove(toParent: self)

    self.hostingController = hostingController
  }

  // метод для обновления notam
  func updateNotams(_ newNotams: [DatabaseApp.Notam]) {
    notams = newNotams
    guard let hostingController = hostingController else { return }

    let dayName = CalendarView.getDayOfWeek(date)
    let dayView = DayNotamView(day: dayName, date: date, notams: newNotams)
    hostingController.rootView = dayView
  }
}

struct DayHoursView: View {
  let day: String
  let date: Date

  private static let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "dd.MM"
    return formatter
  }()

  private var dateString: String {
    Self.dateFormatter.string(from: date)
  }

  var body: some View {
    ScrollView {
      LazyVStack(spacing: 0) {
        ForEach(0..<24, id: \.self) { hour in
          HourRowView(
            hour: hour,
            day: day,
            dateString: dateString
          )
        }
      }
    }
  }
}

struct HourRowView: View {
  let hour: Int
  let day: String
  let dateString: String

  private var timeString: String {
    String(format: "%02d:00", hour)
  }

  var body: some View {
    HStack {
      Text("\(day) \(dateString) \(timeString)")
        .font(.body)
        .foregroundColor(.secondary)
        .frame(minWidth: 120, alignment: .leading)
        .padding(.leading)

      Divider()
        .padding(.leading, 8)

      Spacer()
    }
    .frame(height: 60)
    .background(Color(UIColor.systemBackground))
  }
}

// MARK: - Notam

struct DayNotamView: View {
  let day: String
  let date: Date
  let notams: [DatabaseApp.Notam]

  private static let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "dd.MM"
    return formatter
  }()

  private var dateString: String {
    Self.dateFormatter.string(from: date)
  }

  // фильтруем и сортируем notam для текущего дня
  private var dayNotams: [DatabaseApp.Notam] {
    let calendar = Calendar.current
    return
      notams
      .filter { notam in
        // проверяем, должен ли notam отображаться в этот день
        return shouldShowNotam(notam, on: date, calendar: calendar)
      }
      .sorted { $0.fromDate < $1.fromDate }
  }

  // логика определения, должен ли notam показываться в конкретный день
  private func shouldShowNotam(_ notam: DatabaseApp.Notam, on date: Date, calendar: Calendar)
    -> Bool
  {
    // notam должен начинаться не позже текущего дня
    guard calendar.compare(notam.fromDate, to: date, toGranularity: .day) != .orderedDescending
    else {
      return false
    }

    if let toDate = notam.toDate {
      // если есть toDate, проверяем что текущий день между fromDate и toDate включительно
      return calendar.compare(date, to: toDate, toGranularity: .day) != .orderedDescending
    } else {
      // если toDate = nil, notam перманентный и показывается начиная с fromDate
      return true
    }
  }

  var body: some View {
    ScrollView {
      LazyVStack(spacing: 0) {
        if dayNotams.isEmpty {
          // показываем сообщение если нет notam
          EmptyNotamView(day: day, dateString: dateString)
        } else {
          ForEach(dayNotams.indices, id: \.self) { index in
            NotamRowView(
              notam: dayNotams[index],
              day: day,
              dateString: dateString,
              currentDate: date
            )
            .id(dayNotams[index].number)  // используем номер как уникальный id
          }
        }
      }
    }
  }
}

// view для пустого состояния
struct EmptyNotamView: View {
  let day: String
  let dateString: String

  var body: some View {
    VStack(spacing: 16) {
      Image(systemName: "doc.text")
        .font(.system(size: 48))
        .foregroundColor(.secondary)

      Text("нет notam")
        .font(.headline)
        .foregroundColor(.secondary)

      Text("\(day) \(dateString)")
        .font(.subheadline)
        .foregroundColor(.secondary)
    }
    .frame(maxWidth: .infinity, minHeight: 200)
    .padding()
  }
}

struct NotamRowView: View {
  let notam: DatabaseApp.Notam
  let day: String
  let dateString: String
  let currentDate: Date

  private static let timeFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "HH:mm"
    return formatter
  }()

  private static let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "dd.MM"
    return formatter
  }()

  private var timeString: String {
    Self.timeFormatter.string(from: notam.fromDate)
  }

  private var validUntilString: String {
    if let toDate = notam.toDate {
      return Self.timeFormatter.string(from: toDate)
    } else if let toString = notam.toString {
      return toString
    } else {
      return "perm"
    }
  }

  // показываем статус notam относительно текущего дня
  private var notamStatus: (text: String, color: Color) {
    let calendar = Calendar.current

    guard let toDate = notam.toDate else {
      return ("перманентный", .purple)
    }

    // проверяем, является ли notam дневным (начинается и заканчивается в один день)
    if calendar.isDate(notam.fromDate, inSameDayAs: toDate) {
      return ("дневной", .cyan)
    }

    // если это день начала notam
    if calendar.isDate(notam.fromDate, inSameDayAs: currentDate) {
      return ("начинается", .green)
    }

    if calendar.isDate(toDate, inSameDayAs: currentDate) {
      return ("заканчивается", .orange)
    } else {
      return ("активен", .blue)
    }

  }

  // показываем период действия
  private var validityPeriod: String {
    let calendar = Calendar.current

    if calendar.isDate(notam.fromDate, inSameDayAs: currentDate) {
      // если начинается сегодня, показываем время начала
      return "с \(timeString)"
    } else if let toDate = notam.toDate, calendar.isDate(toDate, inSameDayAs: currentDate) {
      // если заканчивается сегодня, показываем время окончания
      return "до \(validUntilString)"
    } else if let toDate = notam.toDate {
      // показываем полный период
      let fromDateStr = Self.dateFormatter.string(from: notam.fromDate)
      let toDateStr = Self.dateFormatter.string(from: toDate)
      return "\(fromDateStr) - \(toDateStr)"
    } else {
      // перманентный
      let fromDateStr = Self.dateFormatter.string(from: notam.fromDate)
      return "с \(fromDateStr)"
    }
  }

  // цвет по типу notam
  private var typeColor: Color {
    switch notam.type.lowercased() {
    case "a": return .red  // аэродром
    case "w": return .orange  // предупреждение
    case "n": return .blue  // навигация
    case "r": return .purple  // ограничения
    case "c": return .green  // связь
    default: return .gray
    }
  }

  // иконка по типу
  private var typeIcon: String {
    switch notam.type.lowercased() {
    case "a": return "airplane"
    case "w": return "exclamationmark.triangle"
    case "n": return "location"
    case "r": return "hand.raised"
    case "c": return "antenna.radiowaves.left.and.right"
    default: return "doc.text"
    }
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      // header с временем и типом
      HStack {
        // время и статус
        VStack(alignment: .leading, spacing: 2) {
          Text("\(day) \(dateString)")
            .font(.caption)
            .foregroundColor(.secondary)

          HStack(spacing: 8) {
            Text(validityPeriod)
              .font(.subheadline)
              .fontWeight(.medium)

            // статус notam
            Text(notamStatus.text)
              .font(.caption)
              .fontWeight(.medium)
              .foregroundColor(notamStatus.color)
              .padding(.horizontal, 6)
              .padding(.vertical, 2)
              .background(notamStatus.color.opacity(0.1))
              .clipShape(RoundedRectangle(cornerRadius: 4))
          }
        }

        Spacer()

        // тип и иконка
        HStack(spacing: 8) {
          Image(systemName: typeIcon)
            .foregroundColor(typeColor)
            .font(.title2)

          VStack(alignment: .trailing, spacing: 2) {
            Text(notam.type)
              .font(.caption)
              .fontWeight(.bold)
              .foregroundColor(typeColor)

            Text(notam.qCode)
              .font(.caption2)
              .foregroundColor(.secondary)
          }
        }
      }

      // основная информация
      VStack(alignment: .leading, spacing: 4) {
        // номер и icao
        HStack {
          Text("notam \(notam.number)")
            .font(.caption)
            .fontWeight(.medium)
            .foregroundColor(.primary)

          Spacer()

          Text(notam.icao)
            .font(.caption)
            .fontWeight(.medium)
            .foregroundColor(.secondary)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(Color(UIColor.systemGray5))
            .clipShape(RoundedRectangle(cornerRadius: 4))
        }

        // текст notam
        Text(notam.text)
          .font(.body)
          .foregroundColor(.primary)
          .lineLimit(nil)
          .fixedSize(horizontal: false, vertical: true)

        // дополнительная информация
        HStack {
          // уровни полета
          if notam.lowerLimit != nil || notam.upperLimit != nil {
            HStack(spacing: 2) {
              if let lower = notam.lowerLimit {
                Text("fl \(lower)")
                  .font(.caption)
                  .foregroundColor(.secondary)
              }

              if notam.lowerLimit != nil && notam.upperLimit != nil {
                Text("-")
                  .font(.caption)
                  .foregroundColor(.secondary)
              }

              if let upper = notam.upperLimit {
                Text("fl \(upper)")
                  .font(.caption)
                  .foregroundColor(.secondary)
              }
            }
          }

          Spacer()

          // время создания
          Text(notam.ago)
            .font(.caption)
            .foregroundColor(.secondary)
        }
      }
    }
    .padding()
    .background(Color(UIColor.systemBackground))
    .overlay(
      Rectangle()
        .frame(height: 1)
        .foregroundColor(Color(UIColor.separator)),
      alignment: .bottom
    )
  }
}
