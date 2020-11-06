//
//  AuthenticationClient.swift
//  pumpkin
//
//  Created by Barnett, Olivia on 10/31/20.
//  Copyright © 2020 Barnett, Olivia. All rights reserved.
//

import ComposableArchitecture
import Foundation

public struct LoginRequest {
  public var email: String
  public var password: String

  public init(
    email: String,
    password: String
  ) {
    self.email = email
    self.password = password
  }
}

public struct TwoFactorRequest {
  public var code: String
  public var token: String

  public init(
    code: String,
    token: String
  ) {
    self.code = code
    self.token = token
  }
}

public struct AuthenticationResponse: Equatable {
  public var token: String
  public var twoFactorRequired: Bool

  public init(
    token: String,
    twoFactorRequired: Bool
  ) {
    self.token = token
    self.twoFactorRequired = twoFactorRequired
  }
}

public enum AuthenticationError: Equatable, LocalizedError {
  case invalidUserPassword
  case invalidTwoFactor
  case invalidIntermediateToken

  public var errorDescription: String? {
    switch self {
    case .invalidUserPassword:
      return "Unknown user or invalid password."
    case .invalidTwoFactor:
      return "Invalid second factor (try 1234)"
    case .invalidIntermediateToken:
      return "404!! What happened to your token there bud?!?!"
    }
  }
}

public struct AuthenticationClient {
  public var login: (LoginRequest) -> Effect<AuthenticationResponse, AuthenticationError>
  public var twoFactor: (TwoFactorRequest) -> Effect<AuthenticationResponse, AuthenticationError>

  public init(
    login: @escaping (LoginRequest) -> Effect<AuthenticationResponse, AuthenticationError>,
    twoFactor: @escaping (TwoFactorRequest) -> Effect<AuthenticationResponse, AuthenticationError>
  ) {
    self.login = login
    self.twoFactor = twoFactor
  }
}

#if DEBUG
  extension AuthenticationClient {
    public static func mock(
      login: @escaping (LoginRequest) -> Effect<AuthenticationResponse, AuthenticationError> = {
        _ in
        fatalError()
      },
      twoFactor: @escaping (TwoFactorRequest) -> Effect<
        AuthenticationResponse, AuthenticationError
      > =
        { _ in
          fatalError()
        }
    ) -> Self {
      Self(login: login, twoFactor: twoFactor)
    }
  }
#endif

public struct TwoFactorState: Equatable {
  public var alert: AlertState<TwoFactorAction>?
  public var code = ""
  public var isFormValid = false
  public var isTwoFactorRequestInFlight = false
  public let token: String

  public init(token: String) {
    self.token = token
  }
}

public enum TwoFactorAction: Equatable {
  case alertDismissed
  case codeChanged(String)
  case submitButtonTapped
  case twoFactorResponse(Result<AuthenticationResponse, AuthenticationError>)
}

public struct TwoFactorTearDownToken: Hashable {
  public init() {}
}

public struct TwoFactorEnvironment {
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

public let twoFactorReducer = Reducer<TwoFactorState, TwoFactorAction, TwoFactorEnvironment> {
  state, action, environment in

  switch action {
  case .alertDismissed:
    state.alert = nil
    return .none

  case let .codeChanged(code):
    state.code = code
    state.isFormValid = code.count >= 4
    return .none

  case .submitButtonTapped:
    state.isTwoFactorRequestInFlight = true
    return environment.authenticationClient
      .twoFactor(TwoFactorRequest(code: state.code, token: state.token))
      .receive(on: environment.mainQueue)
      .catchToEffect()
      .map(TwoFactorAction.twoFactorResponse)
      .cancellable(id: TwoFactorTearDownToken())

  case let .twoFactorResponse(.failure(error)):
    state.alert = .init(title: .init(error.localizedDescription))
    state.isTwoFactorRequestInFlight = false
    return .none

  case let .twoFactorResponse(.success(response)):
    state.isTwoFactorRequestInFlight = false
    return .none
  }
}

extension AuthenticationClient {
  public static let live = AuthenticationClient(
    login: { request in
      (request.email.contains("@") && request.password == "password"
        ? Effect(value: .init(token: "deadbeef", twoFactorRequired: request.email.contains("2fa")))
        : Effect(error: .invalidUserPassword))
        .delay(for: 1, scheduler: DispatchQueue.global())
        .eraseToEffect()
    },
    twoFactor: { request in
      (request.token != "deadbeef"
        ? Effect(error: .invalidIntermediateToken)
        : request.code != "1234"
          ? Effect(error: .invalidTwoFactor)
          : Effect(value: .init(token: "deadbeefdeadbeef", twoFactorRequired: false)))
        .delay(for: 1, scheduler: DispatchQueue.global())
        .eraseToEffect()
    })
}
