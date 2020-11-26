//
//  Home.swift
//  pumpkin
//
//  Created by Barnett, Olivia on 11/6/20.
//  Copyright © 2020 Barnett, Olivia. All rights reserved.
//

import ComposableArchitecture
import SwiftUI

struct HomeState: Equatable {
  var rows: IdentifiedArrayOf<Row> = [
    .init(device: Device(description: "Front yard pumpkin"), id: UUID()),
    .init(device: Device(description: "Back yard pumpkin"), id: UUID())
  ]

  struct Row: Equatable, Identifiable {
    var device: Device
    let id: UUID
  }

  var animations: [Animation] = []
  var selection: Identified<Row.ID, DetailsState?>?
}

public enum HomeAction: Equatable {
  case details(DetailsAction)
  case select(id: UUID?)
  case logOut
}

struct HomeEnvironment {}

let homeReducer =
  detailsReducer
    .optional()
    .pullback(state: \Identified.value, action: .self, environment: { $0 })
    .optional()
    .pullback(
      state: \HomeState.selection,
      action: /HomeAction.details,
      environment: { _ in DetailsEnvironment() }
    )
  .combined(
    with: Reducer<HomeState, HomeAction, HomeEnvironment> { state, action, environment in
      struct CancelId: Hashable {}
      switch action {
      case let .select(id: .some(id)):
        guard let device = state.rows[id: id]?.device else { return .none }
        state.selection = Identified(DetailsState(device: device), id: id)
        return .none
      case .select(id: .none):
        if let selection = state.selection, let device = selection.value?.device {
          state.rows[id: selection.id]?.device = device
        }
        state.selection = nil
        return .cancel(id: CancelId())
      case .logOut:
        return .none
      }
    }
  )

// The Home page view
struct HomeView: View {
  // Runtime object that is responsible for powering our views by accumulating state changes over time
  // Each view powered by the Composable Architecture will need to hold onto one of these.
  let store: Store<HomeState, HomeAction>

  var body: some View {
    NavigationView {
      WithViewStore(self.store) { viewStore in
        VStack {
          List {
            ForEach(viewStore.rows) { row in
              NavigationLink(
                 destination: IfLetStore(
                   self.store.scope(
                    state: { $0.selection?.value },
                    action: HomeAction.details),
                   then: DetailsView.init(store:),
                   else: ActivityIndicator()
                 ),
                 tag: row.id,
                 selection: viewStore.binding(
                   get: { $0.selection?.id },
                   send: HomeAction.select(id:)
                 )
               ) {
                Text(row.device.description)
              }
            }
          }
        }
        .navigationBarItems(trailing: Button("Log Out") {
          viewStore.send(.logOut)
        })
      }
    }
  }
}

struct HomeView_Previews: PreviewProvider {
  static var previews: some View {
    HomeView(
      store: Store(
        initialState: HomeState(
          rows: [
            .init(device: Device(description: "Front yard pumpkin"), id: UUID()),
            .init(device: Device(description: "Back yard pumpkin"), id: UUID())
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
