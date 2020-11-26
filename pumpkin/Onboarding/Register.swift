//
//  Register.swift
//  pumpkin
//
//  Created by Barnett, Olivia on 11/25/20.
//  Copyright © 2020 Barnett, Olivia. All rights reserved.
//

import SwiftUI
import ComposableArchitecture

public struct RegisterState: Equatable {
  var isRegistered = false
  var isRegisterRequestInFlight = false
  var email: String?
  var password: String?
}

public enum RegisterAction: Equatable {
  case registerTapped(String, String)
  case registerResponse(Result<String, RegisterApiError>)
  case didRegister(String, String)
}

let registerReducer = Reducer<RegisterState, RegisterAction, OnboardingEnvironment> { state, action, environment in
  switch action {
  case .registerTapped(let email, let password):
    state.isRegisterRequestInFlight = true
    state.email = email
    state.password = password
    return environment.dummyData.register(email: email, password: password)
      .receive(on: environment.mainQueue)
      .catchToEffect()
      .map(RegisterAction.registerResponse)
  case let .registerResponse(.success(response)):
    state.isRegisterRequestInFlight = false
    if let email = state.email, let password = state.password {
      return Effect(value: RegisterAction.didRegister(email, password))
    }
    else {
      return .none
    }
  case let .registerResponse(.failure(error)):
    state.isRegisterRequestInFlight = false
    return .none
  case .didRegister:
    return .none
  }
}

struct RegisterView : View {
  @State var email: String = ""
  @State var password: String = ""
  let store: Store<RegisterState, RegisterAction>

  public init(store: Store<RegisterState, RegisterAction>) {
    self.store = store
  }

  public var body: some View {
    WithViewStore(store) { viewStore in
      VStack {
        Spacer()
        TextField("email", text: self.$email)
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
          viewStore.send(.registerTapped(self.email, self.password))
        }
        .disabled(self.email.isEmpty || self.password.isEmpty)
        Spacer()
      }
    .navigationBarTitle("Register")
    }
  }
}
