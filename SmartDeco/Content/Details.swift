//
//  Details.swift
//  pumpkin
//
//  Created by Barnett, Olivia on 11/6/20.
//  Copyright © 2020 Barnett, Olivia. All rights reserved.
//

import SwiftUI
import ComposableArchitecture

struct DetailsState: Equatable {
  var device: Device
  var currentAnimation: Animation?
}

public enum DetailsAction: Equatable {
}

// Holds all of the dependencies our feature needs to do its job
struct DetailsEnvironment {}

let detailsReducer = Reducer<DetailsState, DetailsAction, DetailsEnvironment> { state, action, environment in
  switch action {
  }
}


struct DetailsView: View {

  let store: Store<DetailsState, DetailsAction>

  public init(store: Store<DetailsState, DetailsAction>) {
    self.store = store
  }

  var body: some View {
    WithViewStore(self.store) { viewStore in
      Text("Details for \(viewStore.device.description)")
    }
  }
}
