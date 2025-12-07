//
//  Table.swift
//  SkyPackage
//
//  Created by Igor Voynov on 15. 4. 25.
//

import SwiftUI

public struct TableStyle {
  
  let tableStyle: UITableView.Style
  let separatorStyle: UITableViewCell.SeparatorStyle
  let indicatorStyle: UIScrollView.IndicatorStyle
  let hoverStyle: UIHoverStyle?
  let showsHorizontalScrollIndicator: Bool
  let showsVerticalScrollIndicator: Bool
  let tableBackgroundColor: UIColor
  let headerBackgroundColor: UIColor
  let cellBackgroundColor: UIColor
  
  init(
    tableStyle: UITableView.Style = .plain,
    separatorStyle: UITableViewCell.SeparatorStyle = .none,
    indicatorStyle: UIScrollView.IndicatorStyle = .default,
    hoverStyle: UIHoverStyle? = nil,
    showsHorizontalScrollIndicator: Bool = false,
    showsVerticalScrollIndicator: Bool = false,
    tableBackgroundColor: UIColor = .clear,
    headerBackgroundColor: UIColor = .clear,
    cellBackgroundColor: UIColor = .clear
  ) {
    self.tableStyle = tableStyle
    self.separatorStyle = separatorStyle
    self.indicatorStyle = indicatorStyle
    self.hoverStyle = hoverStyle
    self.showsHorizontalScrollIndicator = showsHorizontalScrollIndicator
    self.showsVerticalScrollIndicator = showsVerticalScrollIndicator
    self.tableBackgroundColor = tableBackgroundColor
    self.headerBackgroundColor = headerBackgroundColor
    self.cellBackgroundColor = cellBackgroundColor
  }
  
}

public struct Table<Section: Hashable, Item: Identifiable, Content: View, Header: View>: View {
  
  let sections: [Section]
  let items: (Section) -> [Item]
  let style: TableStyle
  let swipeActions: ((Item) -> UISwipeActionsConfiguration?)?
  let rowContent: (Item) -> Content
  let headerContent: ((Section) -> Header)?
  
  init(
    sections: [Section],
    items: @escaping (Section) -> [Item],
    style: TableStyle = .init(),
    swipeActions: ((Item) -> UISwipeActionsConfiguration?)? = nil,
    headerContent: ((Section) -> Header)? = nil,
    rowContent: @escaping (Item) -> Content
  ) {
    self.sections = sections
    self.items = items
    self.style = style
    self.swipeActions = swipeActions
    self.rowContent = rowContent
    self.headerContent = headerContent
  }
  
  public var body: some View {
    TableRepresentable(
      sections: sections, items: items,
      style: style, swipeActions: swipeActions,
      headerContent: headerContent, rowContent: rowContent
    )
  }
  
  private struct TableRepresentable: UIViewRepresentable {
    var sections: [Section]
    var items: (Section) -> [Item]
    var style: TableStyle
    var swipeActions: ((Item) -> UISwipeActionsConfiguration?)?
    var headerContent: ((Section) -> Header)?
    var rowContent: (Item) -> Content
    
    func makeCoordinator() -> Coordinator {
      Coordinator(
        sections: sections,
        items: items,
        style: style,
        swipeActions: swipeActions,
        rowContent: rowContent,
        headerContent: headerContent
      )
    }
    
    func makeUIView(context: Context) -> UITableView {
      let tableView = UITableView(frame: .zero, style: style.tableStyle)
      tableView.register(UITableViewCell.self, forCellReuseIdentifier: context.coordinator.cellReuseIdentifier)
      tableView.dataSource = context.coordinator
      tableView.delegate = context.coordinator
      tableView.indicatorStyle = style.indicatorStyle
      tableView.separatorStyle = style.separatorStyle
      tableView.hoverStyle = style.hoverStyle
      tableView.showsVerticalScrollIndicator = style.showsVerticalScrollIndicator
      tableView.showsHorizontalScrollIndicator = style.showsHorizontalScrollIndicator
      tableView.backgroundColor = style.tableBackgroundColor
      // динамическая высота ячейки
      tableView.rowHeight = UITableView.automaticDimension
      tableView.estimatedRowHeight = 80
      // убираем отступы
      tableView.sectionHeaderTopPadding = 0      
      tableView.contentInset = .zero
      tableView.contentInsetAdjustmentBehavior = .never
      tableView.separatorInset = .zero
      tableView.layoutMargins = .zero
      return tableView
    }
    
    func updateUIView(_ uiView: UITableView, context: Context) {
      context.coordinator.sections = sections
      context.coordinator.items = items
      context.coordinator.style = style
      context.coordinator.rowContent = rowContent
      context.coordinator.swipeActions = swipeActions
      context.coordinator.headerContent = headerContent
      uiView.reloadData()
    }
    
    class Coordinator: NSObject, UITableViewDataSource, UITableViewDelegate {
      let cellReuseIdentifier = "Cell"
      
      var sections: [Section]
      var items: (Section) -> [Item]
      var style: TableStyle
      var swipeActions: ((Item) -> UISwipeActionsConfiguration?)?
      var rowContent: (Item) -> Content
      var headerContent: ((Section) -> Header)?
      
      init(
        sections: [Section],
        items: @escaping (Section) -> [Item],
        style: TableStyle,
        swipeActions: ((Item) -> UISwipeActionsConfiguration?)?,
        rowContent: @escaping (Item) -> Content,
        headerContent: ((Section) -> Header)?
      ) {
        self.sections = sections
        self.items = items
        self.style = style
        self.swipeActions = swipeActions
        self.rowContent = rowContent
        self.headerContent = headerContent
      }
      
      func numberOfSections(in tableView: UITableView) -> Int {
        sections.count
      }
      
      func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        items(sections[section]).count
      }
      
      func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = items(sections[indexPath.section])[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: cellReuseIdentifier, for: indexPath)
        cell.backgroundColor = style.cellBackgroundColor
        cell.selectionStyle = .none
        // убираем отступы
        cell.preservesSuperviewLayoutMargins = false
        cell.separatorInset = .zero
        cell.layoutMargins = .zero
        cell.contentConfiguration = UIHostingConfiguration(content: {
          rowContent(item)
            .id(item.id)
        }).margins(.all, 0)
        return cell
      }
      
      func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let item = items(sections[indexPath.section])[indexPath.row]
        return swipeActions?(item)
      }
      
      func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let headerContent = headerContent else { return nil }
        let hostingController = UIHostingController(rootView: headerContent(sections[section]))
        hostingController.view.backgroundColor = style.headerBackgroundColor
        return hostingController.view
      }
      
      func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        headerContent == nil ? 0 : UITableView.automaticDimension
      }
    }
  }
  
}
