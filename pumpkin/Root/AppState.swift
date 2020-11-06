//
//  AppState.swift
//  pumpkin
//
//  Created by Barnett, Olivia on 10/31/20.
//  Copyright © 2020 Barnett, Olivia. All rights reserved.
//

import ComposableArchitecture
import Dispatch

enum Route: Equatable {
  case loggedOut
  case home

  static func == (lhs: Route, rhs: Route) -> Bool {
    switch (lhs, rhs) {
    case (.loggedOut, .loggedOut):
      return true
    case (.home, .home):
      return true
    default:
      return false
    }
  }
}

struct AppState: Equatable {
  var login: LoginState? = LoginState()
  var register: RegisterState?
  var route: Route = .loggedOut

  init() {}
}

enum AppAction: Equatable {
  case login(LoginAction)
  case register(RegisterAction)
}

struct AppEnvironment {
  var authenticationClient: AuthenticationClient
  var mainQueue: AnySchedulerOf<DispatchQueue>

  init(
    authenticationClient: AuthenticationClient,
    mainQueue: AnySchedulerOf<DispatchQueue>
  ) {
    self.authenticationClient = authenticationClient
    self.mainQueue = mainQueue
  }
}

let appReducer = Reducer<AppState, AppAction, AppEnvironment> { state, action, environment in
  switch action {
  case .login:
    state.route = .loggedOut
  case .register:
    state.route = .loggedOut
  }
  return .none
}
