import SrvCore
import UIKit
import WxMap

final public class AppDelegate: UIResponder, UIApplicationDelegate, ObservableObject {

  //  var server: HttpServer?

  public func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
  ) -> Bool {

    //    server = HttpServer()
    //    Task {
    //      await server?.startServer()
    //    }

    Task {
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
