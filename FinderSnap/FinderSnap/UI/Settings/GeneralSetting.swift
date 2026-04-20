//
//  GeneralSetting.swift
//  FinderSnap
//
//  Created by Eden on 2024/5/6.
//

import Cocoa
import SettingsKit
import SwiftUI

struct GeneralSettingPane: SettingsPane {
  var tabViewImage: NSImage? {
    NSImage(systemSymbolName: "gearshape.circle", accessibilityDescription: nil)
  }

  var preferredTitle: String {
    String(localized: "General")
  }

  var view: some View {
    GeneralSettingView(state: .shared)
      .frame(width: GeneralSettingView.Layout.settingsPaneWidth)
  }
}

struct GeneralSettingView: View {
  enum Layout {
    static let settingsPaneWidth: CGFloat = 400
    static let numberFieldWidth: CGFloat = 50
  }

  @ObservedObject var state: AppState

  @State private var accessibilityEnable = AXUtils.trusted

  var requestPermissionView: some View {
    VStack(alignment: .leading) {
      Button("Open Accessibility Settings") {
        AXUtils.openAccessibilitySetting()
      }
    }
  }

  var grantPermissionView: some View {
    Text("Granted.")
      .foregroundColor(.green)
      .bold()
  }

  @ViewBuilder var accessibilityView: some View {
    HStack(alignment: .center) {
      Text("Accessibility access status:")
      if accessibilityEnable {
        grantPermissionView
      } else {
        requestPermissionView
      }
    }
    .padding(.bottom, 3)
    Text("FinderSnap requires Accessibility access to change Finder's window frame.")
      .fixedSize(horizontal: false, vertical: true)
      .settingPrompt()
  }

  private static let sizeFormatter: NumberFormatter = {
    let formatter = NumberFormatter()
    formatter.numberStyle = .decimal
    formatter.minimum = 100
    formatter.maximum = 10000
    return formatter
  }()

  private static let zeroFormatter: NumberFormatter = {
    let formatter = NumberFormatter()
    formatter.numberStyle = .decimal
    formatter.minimum = 0
    formatter.maximum = 10000
    return formatter
  }()

  @ViewBuilder var sizeView: some View {
    Toggle("Resize window to:", isOn: $state.resizeWindow)
    HStack {
      HStack {
        Text("Width")
          .font(.subheadline)
        TextField("Width", value: $state.windowSize.width, formatter: Self.sizeFormatter)
          .font(.subheadline)
          .frame(width: Layout.numberFieldWidth)
      }
      HStack {
        Text("Height")
          .font(.subheadline)
        TextField("Height", value: $state.windowSize.height, formatter: Self.sizeFormatter)
          .font(.subheadline)
          .frame(width: Layout.numberFieldWidth)
      }
    }
    .padding(.top, 1)
    .padding(.leading, 20)
  }

  @ViewBuilder var positionView: some View {
    Toggle("Move window to:", isOn: $state.placeWindow)
    Picker(selection: $state.place, label: EmptyView()) {
      Text("Center")
        .tag(AppState.WindowPlace.center)
      HStack {
        Text("Custom")
        HStack {
          HStack {
            Text("X")
              .font(.subheadline)
            TextField("X", value: $state.position.x, formatter: Self.zeroFormatter)
              .font(.subheadline)
              .frame(width: Layout.numberFieldWidth)
          }
          HStack {
            Text("Y")
              .font(.subheadline)
            TextField("Y", value: $state.position.y, formatter: Self.zeroFormatter)
              .font(.subheadline)
              .frame(width: Layout.numberFieldWidth)
          }
        }
        .padding(.leading, 10)
      }
      .tag(AppState.WindowPlace.custom)
    }
    .pickerStyle(.radioGroup)
    .padding(.leading, 12)
  }

  var screenView: some View {
    Picker(selection: $state.screen, label: Text("Place window to:")) {
      Text("Main Screen")
        .tag(AppState.WindowScreen.main)
      Text("Active Screen")
        .tag(AppState.WindowScreen.current)
    }
    .pickerStyle(.radioGroup)
    .padding(.leading, 12)
  }

  var onlyEffectFirstTimeView: some View {
    Toggle("Only effect to first Finder's window.", isOn: $state.effectFirstWindow)
  }

  private static let durationFormatter: NumberFormatter = {
    let formatter = NumberFormatter()
    formatter.numberStyle = .decimal
    formatter.minimumFractionDigits = 2
    formatter.maximumFractionDigits = 2
    formatter.minimum = 0.1
    formatter.maximum = 1.0
    return formatter
  }()

  @ViewBuilder var enableAnimationView: some View {
    Toggle(String(localized: "Enable window transition animation"), isOn: $state.enableAnimation)
    if state.enableAnimation {
      HStack {
        Text(String(localized: "Animation duration:"))
        Slider(value: $state.animationDuration, in: 0.1...1.0, step: 0.05)
          .frame(width: 120)
        TextField("", value: $state.animationDuration, formatter: Self.durationFormatter)
          .font(.subheadline)
          .frame(width: 45)
        Text(String(localized: "sec"))
          .font(.subheadline)
      }
      .padding(.leading, 20)
      .padding(.top, 2)
    }
  }

  var body: some View {
    VStack(alignment: .leading) {
      accessibilityView
      Divider()
      sizeView
      Divider()
      positionView
      onlyEffectFirstTimeView
      Divider()
      screenView
      Divider()
      enableAnimationView
    }
    .padding()
    .onReceive(AXUtils.trustPublisher) { accessibilityEnable = $0 }
  }
}

// MARK: - View Helpers

private extension View {
  func settingPrompt() -> some View {
    font(.system(size: 11))
      .foregroundColor(.secondary)
  }
}

#Preview {
  GeneralSettingView(state: .shared)
    .frame(width: GeneralSettingView.Layout.settingsPaneWidth)
}
