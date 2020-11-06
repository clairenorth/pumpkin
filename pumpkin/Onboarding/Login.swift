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
  public var alert: AlertState<LoginAction>?
  public var email = ""
  public var isFormValid = false
  public var isLoginRequestInFlight = false
  public var password = ""
  public var twoFactor: TwoFactorState?

  public init() {}
}

public enum LoginAction: Equatable {
  case alertDismissed
  case emailChanged(String)
  case passwordChanged(String)
  case loginButtonTapped
  case loginResponse(Result<AuthenticationResponse, AuthenticationError>)
  case twoFactor(TwoFactorAction)
  case twoFactorDismissed
}

public struct LoginEnvironment {
  public var authenticationClient: AuthenticationClient
  public var mainQueue: AnySchedulerOf<DispatchQueue>

  public init(
    authenticationClient: AuthenticationClient,
    mainQueue: AnySchedulerOf<DispatchQueue>
  ) {
    self.authenticationClient = authenticationClient
    self.mainQueue = mainQueue
  }
}

public let loginReducer =
  twoFactorReducer
  .optional()
  .pullback(
    state: \.twoFactor,
    action: /LoginAction.twoFactor,
    environment: {
      TwoFactorEnvironment(
        authenticationClient: $0.authenticationClient,
        mainQueue: $0.mainQueue
      )
    }
  )
  .combined(
    with: Reducer<LoginState, LoginAction, LoginEnvironment> {
      state, action, environment in
      switch action {
      case .alertDismissed:
        state.alert = nil
        return .none

      case let .emailChanged(email):
        state.email = email
        state.isFormValid = !state.email.isEmpty && !state.password.isEmpty
        return .none

      case let .loginResponse(.success(response)):
        state.isLoginRequestInFlight = false
        if response.twoFactorRequired {
          state.twoFactor = TwoFactorState(token: response.token)
        }
        return .none

      case let .loginResponse(.failure(error)):
        state.alert = .init(title: .init(error.localizedDescription))
        state.isLoginRequestInFlight = false
        return .none

      case let .passwordChanged(password):
        state.password = password
        state.isFormValid = !state.email.isEmpty && !state.password.isEmpty
        return .none

      case .loginButtonTapped:
        state.isLoginRequestInFlight = true
        return environment.authenticationClient
          .login(LoginRequest(email: state.email, password: state.password))
          .receive(on: environment.mainQueue)
          .catchToEffect()
          .map(LoginAction.loginResponse)

      case .twoFactor:
        return .none

      case .twoFactorDismissed:
        state.twoFactor = nil
        return .cancel(id: TwoFactorTearDownToken())
      }
    }
  )


public struct LoginView: View {
  struct ViewState: Equatable {
    var alert: AlertState<LoginAction>?
    var email: String
    var isActivityIndicatorVisible: Bool
    var isFormDisabled: Bool
    var isLoginButtonDisabled: Bool
    var password: String
    var isTwoFactorActive: Bool
  }

  enum ViewAction {
    case alertDismissed
    case emailChanged(String)
    case loginButtonTapped
    case passwordChanged(String)
    case twoFactorDismissed
  }

  let store: Store<LoginState, LoginAction>

  public init(store: Store<LoginState, LoginAction>) {
    self.store = store
  }

  public var body: some View {
    WithViewStore(self.store.scope(state: { $0.view }, action: LoginAction.view)) { viewStore in
      VStack {
        Form {
          Section(
            header: Text(
              """
              To login use any email and "password" for the password. If your email contains the \
              characters "2fa" you will be taken to a two-factor flow, and on that screen you can \
              use "1234" for the code.
              """
            )
          ) { EmptyView() }
        }
      }
      .alert(self.store.scope(state: { $0.alert }), dismiss: .alertDismissed)
    }
    .navigationBarTitle("Login")
  }
}

extension LoginAction {
  static func view(_ localAction: LoginView.ViewAction) -> Self {
    switch localAction {
    case .alertDismissed:
      return .alertDismissed
    case .twoFactorDismissed:
      return .twoFactorDismissed
    case let .emailChanged(email):
      return .emailChanged(email)
    case .loginButtonTapped:
      return .loginButtonTapped
    case let .passwordChanged(password):
      return .passwordChanged(password)
    }
  }
}

extension LoginState {
  var view: LoginView.ViewState {
    LoginView.ViewState(
      alert: self.alert,
      email: self.email,
      isActivityIndicatorVisible: self.isLoginRequestInFlight,
      isFormDisabled: self.isLoginRequestInFlight,
      isLoginButtonDisabled: !self.isFormValid,
      password: self.password,
      isTwoFactorActive: self.twoFactor != nil
    )
  }
}

