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

public struct LoginApiError: Error, Equatable {}
public struct RegisterApiError: Error, Equatable {}

public struct LoginState: Equatable {
  var isLoggedIn = false
  var isLoginRequestInFlight = false
  var isRegisterRequestInFlight = false
}

public enum LoginAction: Equatable {
  case start
  case logInTapped(String, String)
  case registerTapped(String, String)
  case loginResponse(Result<String, LoginApiError>)
  case registerResponse(Result<String, RegisterApiError>)
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
  case .logInTapped(let username, let password):
    state.isLoginRequestInFlight = true
    return environment.dummyData.logIn(username: username, password: password)
      .receive(on: environment.mainQueue)
      .catchToEffect()
      .map(LoginAction.loginResponse)
  case .registerTapped(let username, let password):
    state.isRegisterRequestInFlight = true
    return environment.dummyData.register(username: username, password: password)
      .receive(on: environment.mainQueue)
      .catchToEffect()
      .map(LoginAction.registerResponse)
  case let .loginResponse(.success(response)):
    state.isLoginRequestInFlight = false
    return Effect(value: LoginAction.didLogIn)
  case let .loginResponse(.failure(error)):
    state.isLoginRequestInFlight = false
    return .none
  case let .registerResponse(.success(response)):
    state.isRegisterRequestInFlight = false
    return Effect(value: LoginAction.didLogIn)
  case let .registerResponse(.failure(error)):
    state.isRegisterRequestInFlight = false
    return .none
  case .didLogIn:
    return .none
  }
  return .none
}

struct RegisterView : View {
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
          .textFieldStyle(RoundedBorderTextFieldStyle())
          .padding(8)
          .cornerRadius(8)
        SecureField("Password", text: self.$password)
          .foregroundColor(.black)
          .multilineTextAlignment(.center)
          .textFieldStyle(RoundedBorderTextFieldStyle())
          .padding(8)
          .cornerRadius(8)
        Button("Submit") {
          viewStore.send(.registerTapped(self.username, self.password))
        }
        Spacer()
      }
    .navigationBarTitle("Register")
    }
  }
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
        Image("smart-deco-logo")
        TextField("Username", text: self.$username)
          .foregroundColor(.black)
          .multilineTextAlignment(.center)
          .textFieldStyle(RoundedBorderTextFieldStyle())
          .padding(8)
          .cornerRadius(8)
        SecureField("Password", text: self.$password)
          .foregroundColor(.black)
          .multilineTextAlignment(.center)
          .textFieldStyle(RoundedBorderTextFieldStyle())
          .padding(8)
          .cornerRadius(8)
        Button("Log In") {
          viewStore.send(.logInTapped(self.username, self.password))
        }
        .foregroundColor(.black)
        .padding(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
        .cornerRadius(8)
        NavigationLink(destination: RegisterView(store: store)) {
          Text("Register")
        }
        .buttonStyle(PlainButtonStyle())
        Spacer()
      }
      .padding(32)
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
