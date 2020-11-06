//
//  SceneDelegate.swift
//  pumpkin
//
//  Created by Barnett, Olivia on 10/31/20.
//  Copyright © 2020 Barnett, Olivia. All rights reserved.
//

import ComposableArchitecture
import SwiftUI
import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
  var window: UIWindow?

  func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
    let store = makeStore()
    self.window = (scene as? UIWindowScene).map(UIWindow.init(windowScene:))
    self.window?.rootViewController = UIHostingController(rootView: RouterView(store: store))
    self.window?.makeKeyAndVisible()
  }
}

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
  func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    true
  }
}

func makeStore() -> Store<AppState, AppAction> {
  let state = AppState()
  let environment = AppEnvironment(
    authenticationClient: .live,
    mainQueue: DispatchQueue.main.eraseToAnyScheduler()
  )
  let reducer = Reducer.combine(
    appReducer,
    loginReducer.optional().pullback(state: \.login,
                                     action: /AppAction.login,
                                     environment: {
                                      LoginEnvironment(
                                       authenticationClient: $0.authenticationClient,
                                       mainQueue: $0.mainQueue
                                      )}),
    registerReducer.optional().pullback(state: \.register,
                                     action: /AppAction.register,
                                     environment: { _ in RegisterEnvironment() })
  )
  let store = Store(initialState: state,
                    reducer: reducer,
                    environment: environment)
  ViewStore(store).send(.login(.loginButtonTapped))
  return store
}
