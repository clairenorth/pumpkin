//
//  AppState.swift
//  pumpkin
//
//  Created by Barnett, Olivia on 10/31/20.
//  Copyright © 2020 Barnett, Olivia. All rights reserved.
//

import ComposableArchitecture
import Dispatch

// Hardcode the backend in right now, start not logged in.
public class DummyDependencies {
  let isLoggedIn = false
  func logIn(username: String, password: String) -> Effect<Void, Error> {
    return .none
  }
}

public struct AppState: Equatable {
  // Initializing loginState only will direct user through Login first.
  var login: LoginState? = LoginState()
  var home: HomeState?

  init() {}
}

public enum AppAction: Equatable {
  case login(LoginAction)
  case home(HomeAction)
}

// Holds all of the dependencies our feature needs to do its job
public struct AppEnvironment {
  var dummyData: DummyDependencies
  var authenticationClient: AuthenticationClient
  var mainQueue: AnySchedulerOf<DispatchQueue>

  init(
    dummyData: DummyDependencies,
    authenticationClient: AuthenticationClient,
    mainQueue: AnySchedulerOf<DispatchQueue>
  ) {
    self.dummyData = dummyData
    self.authenticationClient = authenticationClient
    self.mainQueue = mainQueue
  }
}

// Glues together the state, action and environment into a cohesive package
public let appReducer = Reducer<AppState, AppAction, AppEnvironment>.combine(
  loginReducer.optional().pullback(
    state: \.login,
    action: /AppAction.login,
    environment: {
      LoginEnvironment(
        dummyData: $0.dummyData,
        authenticationClient: $0.authenticationClient,
        mainQueue: $0.mainQueue
      )
    }
  ),
  Reducer { state, action, _ in
    switch action {
    case .login:
      state.home = HomeState()
      state.login = nil
      return .none
    case .home:
      return .none
    }
  }
)
