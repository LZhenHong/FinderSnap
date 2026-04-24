//
//  OnboardingView.swift
//  FinderSnap
//
//  Created by Eden on 2026/4/24.
//

import Combine
import SwiftUI

// MARK: - Onboarding View

struct OnboardingView: View {
  @ObservedObject var state: AppState
  @State private var currentStep: OnboardingStep = .welcome
  @State private var accessibilityGranted = AXUtils.trusted
  @State private var trustCancellable: AnyCancellable?

  var onComplete: (() -> Void)?
  var onOpenSettings: (() -> Void)?

  var body: some View {
    VStack(spacing: 0) {
      // Step indicator
      stepIndicator
        .padding(.top, 24)
        .padding(.bottom, 16)

      // Step content
      stepContent
        .frame(maxWidth: .infinity, maxHeight: .infinity)

      // Bottom actions
      bottomActions
        .padding(.horizontal, 28)
        .padding(.bottom, 24)
    }
    .frame(width: 520, height: 380)
    .onAppear {
      accessibilityGranted = AXUtils.trusted
      trustCancellable = AXUtils.trustPublisher
        .receive(on: DispatchQueue.main)
        .sink { granted in
          accessibilityGranted = granted
        }
    }
    .onDisappear {
      trustCancellable?.cancel()
    }
  }
}

// MARK: - Steps

private extension OnboardingView {
  enum OnboardingStep: CaseIterable {
    case welcome
    case permission
    case quickSetup

    var index: Int {
      Self.allCases.firstIndex(of: self) ?? 0
    }

    static var total: Int { allCases.count }
  }
}

// MARK: - Step Indicator

private extension OnboardingView {
  var stepIndicator: some View {
    HStack(spacing: 8) {
      ForEach(0..<OnboardingStep.total, id: \.self) { index in
        Circle()
          .fill(index <= currentStep.index ? Color.accentColor : Color.secondary.opacity(0.3))
          .frame(width: 8, height: 8)
      }
    }
  }
}

// MARK: - Step Content

private extension OnboardingView {
  @ViewBuilder var stepContent: some View {
    switch currentStep {
    case .welcome:
      welcomeStep
    case .permission:
      permissionStep
    case .quickSetup:
      quickSetupStep
    }
  }
}

// MARK: - Welcome Step

private extension OnboardingView {
  var welcomeStep: some View {
    VStack(spacing: 20) {
      Image(nsImage: NSApp.applicationIconImage)
        .resizable()
        .frame(width: 64, height: 64)

      VStack(spacing: 8) {
        Text(String(localized: "Welcome to FinderSnap"))
          .font(.title2)
          .fontWeight(.semibold)

        Text(String(localized: "FinderSnap runs silently in your menu bar and automatically resizes and positions new Finder windows."))
          .font(.body)
          .foregroundStyle(.secondary)
          .multilineTextAlignment(.center)
          .frame(maxWidth: 400)
      }

      HStack(spacing: 12) {
        Image(systemName: "macwindow.on.rectangle")
          .font(.system(size: 28))
          .foregroundStyle(.secondary)

        VStack(alignment: .leading, spacing: 2) {
          Text(String(localized: "Menu Bar Icon"))
            .font(.subheadline)
            .fontWeight(.medium)
          Text(String(localized: "Click the icon to access settings and controls."))
            .font(.caption)
            .foregroundStyle(.secondary)
        }
      }
      .padding(.horizontal, 16)
      .padding(.vertical, 12)
      .background(Color(NSColor.controlBackgroundColor))
      .clipShape(RoundedRectangle(cornerRadius: 8))
      .frame(maxWidth: 400)
    }
    .padding(.horizontal, 28)
  }
}

// MARK: - Permission Step

private extension OnboardingView {
  var permissionStep: some View {
    VStack(spacing: 24) {
      VStack(spacing: 8) {
        Text(String(localized: "Enable Accessibility Access"))
          .font(.title2)
          .fontWeight(.semibold)

        Text(String(localized: "FinderSnap needs Accessibility permission to resize and reposition Finder windows. This is a one-time setup."))
          .font(.body)
          .foregroundStyle(.secondary)
          .multilineTextAlignment(.center)
          .frame(maxWidth: 420)
      }

      VStack(spacing: 16) {
        Image(systemName: "lock.shield")
          .font(.system(size: 40))
          .foregroundStyle(.secondary)

        if accessibilityGranted {
          HStack(spacing: 6) {
            Image(systemName: "checkmark.circle.fill")
              .foregroundColor(.green)
            Text(String(localized: "Access granted. You're all set!"))
              .font(.subheadline)
              .foregroundColor(.green)
          }
        } else {
          VStack(spacing: 12) {
            Button {
              AXUtils.checkIsTrusted()
            } label: {
              Label(
                String(localized: "Grant Accessibility Access"),
                systemImage: "arrow.up.forward.app"
              )
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)

            Button(String(localized: "Open Accessibility Settings")) {
              AXUtils.openAccessibilitySetting()
            }
            .buttonStyle(.plain)
            .font(.callout)
            .foregroundStyle(.secondary)
          }
        }
      }
      .padding(.horizontal, 16)
      .padding(.vertical, 20)
      .background(Color(NSColor.controlBackgroundColor))
      .clipShape(RoundedRectangle(cornerRadius: 8))
      .frame(maxWidth: 440)

      if !accessibilityGranted {
        Text(String(localized: "Click the button above to request permission, then turn on the switch next to FinderSnap in System Settings."))
          .font(.caption)
          .foregroundStyle(.secondary)
          .multilineTextAlignment(.center)
          .frame(maxWidth: 400)
      }
    }
    .padding(.horizontal, 28)
  }
}

// MARK: - Quick Setup Step

private extension OnboardingView {
  var quickSetupStep: some View {
    VStack(spacing: 20) {
      VStack(spacing: 8) {
        Text(String(localized: "Quick Setup"))
          .font(.title2)
          .fontWeight(.semibold)

        Text(String(localized: "Choose how you'd like FinderSnap to handle new Finder windows. You can always change this later in Settings."))
          .font(.body)
          .foregroundStyle(.secondary)
          .multilineTextAlignment(.center)
          .frame(maxWidth: 420)
      }

      VStack(alignment: .leading, spacing: 12) {
        settingPreviewRow(
          icon: "macwindow",
          title: String(localized: "Resize to 1200 × 800"),
          description: String(localized: "New windows will be resized to a comfortable default size.")
        )

        settingPreviewRow(
          icon: "arrow.up.and.down.and.arrow.left.and.right",
          title: String(localized: "Center on Main Screen"),
          description: String(localized: "Windows will appear centered on your primary display.")
        )

        settingPreviewRow(
          icon: "sparkles",
          title: String(localized: "Smooth Animation"),
          description: String(localized: "Window transitions will animate smoothly over 0.25 seconds.")
        )
      }
      .padding(.horizontal, 16)
      .padding(.vertical, 14)
      .background(Color(NSColor.controlBackgroundColor))
      .clipShape(RoundedRectangle(cornerRadius: 8))
      .frame(maxWidth: 440)
    }
    .padding(.horizontal, 28)
  }

  func settingPreviewRow(icon: String, title: String, description: String) -> some View {
    HStack(spacing: 12) {
      Image(systemName: icon)
        .font(.system(size: 18))
        .foregroundStyle(.secondary)
        .frame(width: 24)

      VStack(alignment: .leading, spacing: 2) {
        Text(title)
          .font(.subheadline)
          .fontWeight(.medium)
        Text(description)
          .font(.caption)
          .foregroundStyle(.secondary)
      }

      Spacer()
    }
  }
}

// MARK: - Bottom Actions

private extension OnboardingView {
  var bottomActions: some View {
    HStack {
      // Skip button (except on last step)
      if currentStep != .quickSetup {
        Button(String(localized: "Skip")) {
          completeOnboarding()
        }
        .buttonStyle(.plain)
        .foregroundStyle(.secondary)
      } else {
        Button(String(localized: "Open Settings")) {
          onOpenSettings?()
          completeOnboarding()
        }
        .buttonStyle(.plain)
        .foregroundStyle(.secondary)
      }

      Spacer()

      // Back button (not on first step)
      if currentStep.index > 0 {
        Button(String(localized: "Back")) {
          withAnimation(.easeInOut(duration: 0.2)) {
            currentStep = OnboardingStep.allCases[currentStep.index - 1]
          }
        }
      }

      // Primary action
      Button(action: primaryAction) {
        Text(primaryButtonTitle)
          .fontWeight(.medium)
      }
      .keyboardShortcut(.defaultAction)
      .disabled(currentStep == .permission && !accessibilityGranted)
    }
  }

  var primaryButtonTitle: String {
    switch currentStep {
    case .welcome:
      String(localized: "Get Started")
    case .permission:
      String(localized: "Continue")
    case .quickSetup:
      String(localized: "Use Recommended Settings")
    }
  }

  func primaryAction() {
    switch currentStep {
    case .welcome:
      withAnimation(.easeInOut(duration: 0.2)) {
        currentStep = .permission
      }

    case .permission:
      withAnimation(.easeInOut(duration: 0.2)) {
        currentStep = .quickSetup
      }

    case .quickSetup:
      state.applyRecommendedSettings()
      completeOnboarding()
    }
  }

  func completeOnboarding() {
    state.onboardingCompleted = true
    onComplete?()
  }
}

// MARK: - Preview

#Preview {
  OnboardingView(state: .shared)
}
