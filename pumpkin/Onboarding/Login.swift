//
//  Login.swift
//  pumpkin
//
//  Created by Barnett, Olivia on 10/31/20.
//  Copyright © 2020 Barnett, Olivia. All rights reserved.
//

import Foundation
import SwiftUI
import ComposableArchitecture

public struct LoginState: Equatable {
  var isLoggedIn = false
}

public enum LoginAction: Equatable {
  case start
  case logIn(String, String)
  case didLogIn
}

public struct LoginEnvironment {
  public var dummyData: DummyDependencies
  public var authenticationClient: AuthenticationClient
  public var mainQueue: AnySchedulerOf<DispatchQueue>

  public init(
    dummyData: DummyDependencies,
    authenticationClient: AuthenticationClient,
    mainQueue: AnySchedulerOf<DispatchQueue>
  ) {
    self.dummyData = dummyData
    self.authenticationClient = authenticationClient
    self.mainQueue = mainQueue
  }
}

let loginReducer = Reducer<LoginState, LoginAction, LoginEnvironment> { state, action, environment in
  switch action {
  case .start:
    state.isLoggedIn = environment.dummyData.isLoggedIn
    if state.isLoggedIn {
      return Effect(value: .didLogIn)
    }
  case .logIn(let username, let password):
    return environment.dummyData.logIn(username: username, password: password)
      .receive(on: environment.mainQueue)
      .catchToEffect()
      .map { _ in LoginAction.start }
  case .didLogIn:
    break
  }
  return .none
}

public struct LoginView: View {
  @State var username: String = ""
  @State var password: String = ""

  let store: Store<LoginState, LoginAction>

  public init(store: Store<LoginState, LoginAction>) {
    self.store = store
  }

  public var body: some View {
    WithViewStore(store) { viewStore in
      VStack {
        Spacer()
        TextField("Username", text: self.$username)
          .foregroundColor(.black)
          .multilineTextAlignment(.center)
          .padding(8)
          .background(Color.white)
          .cornerRadius(8)
        SecureField("Password", text: self.$password)
        .foregroundColor(.black)
        .multilineTextAlignment(.center)
        .padding(8)
        .background(Color.white)
        .cornerRadius(8)
        Button("Log In") {
          viewStore.send(.logIn(self.username, self.password))
        }
        .foregroundColor(.white)
        .padding(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
        .cornerRadius(8)

        Spacer()
      }
      .padding(32)
      .background(Color.orange)
      .edgesIgnoringSafeArea(.all)
    }
  }
}

struct LoginView_Previews: PreviewProvider {
  static var previews: some View {
    NavigationView {
      LoginView(
        store: Store(
          initialState: LoginState(),
          reducer: loginReducer,
          environment: LoginEnvironment(
            dummyData: DummyDependencies(),
            authenticationClient: AuthenticationClient(
              login: { _ in Effect(value: .init(token: "deadbeef", twoFactorRequired: false)) },
              twoFactor: { _ in Effect(value: .init(token: "deadbeef", twoFactorRequired: false)) }
            ),
            mainQueue: DispatchQueue.main.eraseToAnyScheduler()
          )
        )
      )
    }
  }
}
