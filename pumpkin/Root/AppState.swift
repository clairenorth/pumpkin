//
//  AppState.swift
//  pumpkin
//
//  Created by Barnett, Olivia on 10/31/20.
//  Copyright © 2020 Barnett, Olivia. All rights reserved.
//

import SwiftUI
import ComposableArchitecture
import Dispatch

// Hardcode the backend in right now, start not logged in.
public class DummyDependencies {
  let isLoggedIn = false
  func logIn(username: String, password: String) -> Effect<String, LoginApiError> {
    return Effect(value: "yay")
  }

  func register(username: String, password: String) -> Effect<String, RegisterApiError> {
    return Effect(value: "yay")
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
    case let .login(.didLogIn):
      state.home = HomeState()
      state.login = nil
      return .none
    case .home:
      return .none
    case .login:
      return .none
    }
  }
)

public struct AppView: View {
  let store: Store<AppState, AppAction>

  public init(store: Store<AppState, AppAction>) {
    self.store = store
  }

  @ViewBuilder public var body: some View {
    IfLetStore(self.store.scope(state: { $0.login }, action: AppAction.login)) { store in
      NavigationView {
        LoginView(store: store)
      }
      .navigationViewStyle(StackNavigationViewStyle())
    }

    IfLetStore(self.store.scope(state: { $0.home }, action: AppAction.home)) { store in
      NavigationView {
         HomeView(
           store: Store(
             initialState: HomeState(),
             reducer: homeReducer,
             environment: HomeEnvironment()
           )
         )
      }
      .navigationViewStyle(StackNavigationViewStyle())
    }
  }
}
