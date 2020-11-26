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

// Hardcode the backend in right now, start not logged in.
public class DummyDependencies {
  let isLoggedIn = false
  func logIn(email: String, password: String) -> Effect<String, LoginApiError> {
    return Effect(value: "yay")
  }

  func register(email: String, password: String) -> Effect<String, RegisterApiError> {
    return Effect(value: "yay")
  }
}

public struct LoginApiError: Error, Equatable {}
public struct RegisterApiError: Error, Equatable {}

public struct LoginState: Equatable {
  var isLoggedIn = false
  var isLoginRequestInFlight = false
  var register = RegisterState()
}

public enum LoginAction: Equatable {
  case start
  case logIn(String, String)
  case loginResponse(Result<String, LoginApiError>)
  case didLogIn
  case register(RegisterAction)
}

public struct OnboardingEnvironment {
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

let loginReducer = registerReducer
  .pullback(
    state: \.register,
    action: /LoginAction.register,
    environment: { $0 }
  ).combined(
    with: Reducer<LoginState, LoginAction, OnboardingEnvironment> { state, action, environment in
      switch action {
      // Upon Login startup, check keychain for automatic login.
      case .start:
        if environment.authenticationClient.isSignedIn {
          return Effect(value: .didLogIn)
        }
        return .none
      case .logIn(let email, let password):
        state.isLoginRequestInFlight = true
        let name = UIDevice.current.name
        let user = User(name: name, email: email)

        // Use keychain to save log in.
        do {
          try environment.authenticationClient.signIn(user, password: password)
        }
        catch {
          print("Error signing in: \(error.localizedDescription)")
        }

        // Hit mock service
        return environment.dummyData.logIn(email: email, password: password)
          .receive(on: environment.mainQueue)
          .catchToEffect()
          .map(LoginAction.loginResponse)
      case let .loginResponse(.success(response)):
        state.isLoginRequestInFlight = false
        return Effect(value: LoginAction.didLogIn)
      case let .loginResponse(.failure(error)):
        state.isLoginRequestInFlight = false
        return .none
      case .didLogIn:
        return .none
      case let .register(.didRegister(email, password)):
        // On successful registration, log user in.
        return Effect(value: LoginAction.logIn(email, password))
      case .register:
       return .none
      }
    }
)

public struct LoginView: View {
  @State var email: String = ""
  @State var password: String = ""

  let store: Store<LoginState, LoginAction>

  public init(store: Store<LoginState, LoginAction>) {
    self.store = store
  }

  var isButtonDisabled: Bool {
    self.email.isEmpty || self.password.isEmpty
  }

  var buttonColor: Color {
    return isButtonDisabled ? .gray : .black
  }

  public var body: some View {
    WithViewStore(store) { viewStore in
      VStack {
        Spacer()
        Image("smart-deco-logo")
        TextField("Email", text: self.$email)
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
          viewStore.send(.logIn(self.email, self.password))
        }
        .disabled(isButtonDisabled)
        .foregroundColor(buttonColor)
        .padding(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
        .cornerRadius(8)
        NavigationLink(
          destination: IfLetStore(
            self.store.scope(state: { $0.register }, action: LoginAction.register),
            then: RegisterView.init(store:)
          )
        ) {
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
          environment: OnboardingEnvironment(
            dummyData: DummyDependencies(),
            authenticationClient: AuthenticationClient(),
            mainQueue: DispatchQueue.main.eraseToAnyScheduler()
          )
        )
      )
    }
  }
}
