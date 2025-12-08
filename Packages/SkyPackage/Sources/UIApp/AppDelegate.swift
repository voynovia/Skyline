import SrvCore
import UIKit
import WxMap
import MetarParser

final public class AppDelegate: UIResponder, UIApplicationDelegate, ObservableObject {

  public func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
  ) -> Bool {

    Task {
//      try await Task.sleep(for: .seconds(5))
//      do {
//        let parser = try MetarJSParser()
//        
//        var startTime = CFAbsoluteTimeGetCurrent()
//        let data1 = try parser.parseMetar("METAR UUOL 081530Z 14003MPS 0550 0400W R15/0400N FZFG VV001 M03/M03 Q1030 R15/////// NOSIG RMK QBB040")
//        let data2 = try parser.parseMetar("METAR LOWL 081450Z 08002KT 4500 -DZ BR FEW015 SCT019 BKN020 09/09 Q1021 NOSIG")
//        let data3 = try parser.parseMetar("METAR LIPZ 081520Z 13002KT CAVOK 10/04 Q1022 NOSIG")
//        print("metarParser simple: \(String(format: "%.5f", CFAbsoluteTimeGetCurrent() - startTime)) seconds")
//        
//        startTime = CFAbsoluteTimeGetCurrent()
//        let results = try parser.parseMetars([
//          "METAR UUOL 081530Z 14003MPS 0550 0400W R15/0400N FZFG VV001 M03/M03 Q1030 R15/////// NOSIG RMK QBB040",
//          "METAR LOWL 081450Z 08002KT 4500 -DZ BR FEW015 SCT019 BKN020 09/09 Q1021 NOSIG",
//          "METAR LIPZ 081520Z 13002KT CAVOK 10/04 Q1022 NOSIG"
//        ])
//        print("metarParser pool: \(String(format: "%.5f", CFAbsoluteTimeGetCurrent() - startTime)) seconds")
//        
//      } catch {
//        print(error)  
//      }
      
      // синхронизация времени с NTP серверами
      await TimeSync.initialize()
    }

//    do {
//      try WxMap().get()
//    } catch {
//      print(error.localizedDescription)
//    }

    return true
  }

  public func applicationWillEnterForeground(_ application: UIApplication) {
    // ресинхронизация времени при возвращении из фона
    Task {
      if TimeSync.needsResync {
        await TimeSync.sync()
      }
    }
  }

}
