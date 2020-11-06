//
//  Register.swift
//  pumpkin
//
//  Created by Barnett, Olivia on 10/31/20.
//  Copyright © 2020 Barnett, Olivia. All rights reserved.
//

import ComposableArchitecture
import SwiftUI
import Foundation

public struct RegisterState: Equatable {
  public var oPlayerName = ""
  public var xPlayerName = ""

  public init() {}
}

public enum RegisterAction: Equatable {
  case gameDismissed
  case letsPlayButtonTapped
  case logoutButtonTapped
  case oPlayerNameChanged(String)
  case xPlayerNameChanged(String)
}

public struct RegisterEnvironment {
  public init() {}
}

public let registerReducer = Reducer<RegisterState, RegisterAction, RegisterEnvironment> { _,_,_ in
  return .none
}

public struct RegisterView: View {
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
