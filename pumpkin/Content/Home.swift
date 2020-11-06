//
//  Home.swift
//  pumpkin
//
//  Created by Barnett, Olivia on 11/6/20.
//  Copyright © 2020 Barnett, Olivia. All rights reserved.
//

import ComposableArchitecture
import SwiftUI

/// Representing a device controlled by the app.
struct Device: Equatable, Identifiable {
  let id: UUID
  var description = ""
  var isConnected = false
}

/// Representing a purchased animation that can be used on any device.
struct Animation: Equatable, Identifiable {
  let id: UUID
  var description = ""
}

struct HomeState: Equatable {
  static func == (lhs: HomeState, rhs: HomeState) -> Bool {
    lhs.devices == rhs.devices
  }

  var devices: IdentifiedArrayOf<Device> = [
    Device(
      id: UUID(),
      description: "Front yard pumpkin",
      isConnected: true
    ),
    Device(
      id: UUID(),
      description: "Back yard pumpkin",
      isConnected: false
    )
  ]
  var animations: [Animation] = []
  var details: DetailsState?
}

public enum HomeAction: Equatable {
  case select(id: UUID?)
  case details(DetailsAction)
}

// Holds all of the dependencies our feature needs to do its job
struct HomeEnvironment {}

let homeReducer = Reducer<HomeState, HomeAction, HomeEnvironment>
  .combine(
    Reducer { state, action, environment in
      switch action {
      case .select(let id):
        guard let id = id,
          let item = state.devices[id: id] else {
          return .none
        }
        state.details = DetailsState(description: state.devices[id: id]?.description ?? "")
        print("<OB> set: ")
        return .none
      case .details:
        return .none
      }
    }.debug(),
    detailsReducer.optional().pullback(
      state: \.details,
      action: /HomeAction.details,
      environment: { _ in DetailsEnvironment() }
    ).debug()
  )

// The Home page view
struct HomeView: View {
  // Runtime object that is responsible for powering our views by accumulating state changes over time
  // Each view powered by the Composable Architecture will need to hold onto one of these.
  let store: Store<HomeState, HomeAction>

  var body: some View {
    NavigationView {
      WithViewStore(self.store) { viewStore in
        List {
          ForEach(viewStore.devices) { device in
            Button(device.description) {
              viewStore.send(.select(id: device.id))
            }
          }
        }
      }
      .navigationBarTitle("Home")
    }
  }
}

struct HomeView_Previews: PreviewProvider {
  static var previews: some View {
    HomeView(
      store: Store(
        initialState: HomeState(
          devices: [
            Device(
              id: UUID(),
              description: "Front yard pumpkin",
              isConnected: true
            ),
            Device(
              id: UUID(),
              description: "Back yard pumpkin",
              isConnected: false
            )
          ],
          animations: [
            Animation(
              id: UUID(),
              description: "Funny"
            ),
            Animation(
              id: UUID(),
              description: "Scary"
            )
          ]
        ),
        reducer: homeReducer,
        environment: HomeEnvironment()
      )
    )
  }
}
