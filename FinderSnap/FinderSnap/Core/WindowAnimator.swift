//
//  WindowAnimator.swift
//  FinderSnap
//
//  Created by Eden on 2024/5/6.
//

import Cocoa

// MARK: - WindowAnimator

/// Animates window frame changes using CVDisplayLink for smooth, vsync-synchronized animation.
final class WindowAnimator {
  // MARK: - Properties

  private let window: AXUIElement
  private let startFrame: CGRect
  private let targetFrame: CGRect
  private let duration: TimeInterval

  private var displayLink: CVDisplayLink?
  private var startTime: CFTimeInterval = 0
  private var retainedSelf: Unmanaged<WindowAnimator>?

  // MARK: - Initialization

  init(
    window: AXUIElement,
    from startFrame: CGRect,
    to targetFrame: CGRect,
    duration: TimeInterval = 0.25
  ) {
    self.window = window
    self.startFrame = startFrame
    self.targetFrame = targetFrame
    self.duration = duration
  }

  // MARK: - Public Methods

  func start() {
    guard retainedSelf == nil else { return }

    var displayLink: CVDisplayLink?
    CVDisplayLinkCreateWithActiveCGDisplays(&displayLink)

    guard let displayLink else {
      applyFinalFrame()
      return
    }

    self.displayLink = displayLink
    startTime = CACurrentMediaTime()

    // Retain self for the duration of the animation
    retainedSelf = Unmanaged.passRetained(self)

    let callback: CVDisplayLinkOutputCallback = { _, _, _, _, _, context in
      guard let context else { return kCVReturnSuccess }
      let animator = Unmanaged<WindowAnimator>.fromOpaque(context).takeUnretainedValue()
      animator.handleDisplayLinkCallback()
      return kCVReturnSuccess
    }

    CVDisplayLinkSetOutputCallback(displayLink, callback, retainedSelf?.toOpaque())
    CVDisplayLinkStart(displayLink)
  }
}

// MARK: - Animation Logic

private extension WindowAnimator {
  func handleDisplayLinkCallback() {
    let elapsed = CACurrentMediaTime() - startTime
    let progress = min(elapsed / duration, 1.0)
    let easedProgress = easeOutCubic(progress)

    let interpolatedFrame = interpolateFrame(progress: easedProgress)

    DispatchQueue.main.async { [weak self] in
      guard let self else { return }
      window.setSize(interpolatedFrame.size)
      window.setPosition(interpolatedFrame.origin)

      if progress >= 1.0 {
        stop()
      }
    }
  }

  func stop() {
    guard let displayLink else { return }

    CVDisplayLinkStop(displayLink)
    self.displayLink = nil

    // Ensure final frame is exact
    applyFinalFrame()

    // Release the retained self to allow deallocation
    retainedSelf?.release()
    retainedSelf = nil
  }

  func applyFinalFrame() {
    window.setSize(targetFrame.size)
    window.setPosition(targetFrame.origin)
  }
}

// MARK: - Interpolation

private extension WindowAnimator {
  func interpolateFrame(progress: Double) -> CGRect {
    let x = startFrame.origin.x + (targetFrame.origin.x - startFrame.origin.x) * progress
    let y = startFrame.origin.y + (targetFrame.origin.y - startFrame.origin.y) * progress
    let width = startFrame.width + (targetFrame.width - startFrame.width) * progress
    let height = startFrame.height + (targetFrame.height - startFrame.height) * progress

    return CGRect(x: x, y: y, width: width, height: height)
  }

  /// Ease-out cubic easing function for smooth deceleration
  func easeOutCubic(_ t: Double) -> Double {
    let t1 = t - 1
    return t1 * t1 * t1 + 1
  }
}
