import SnaprCore
import SwiftUI

/// The Layout section: repeat behavior, sizes and steps.
struct LayoutSettingsSection: View {
    @ObservedObject var model: AppModel
    private var settings: SettingsStore { model.settings }
    private var options: LayoutOptions { settings.get(.layoutOptions) }

    var body: some View {
        Section("Layout") {
            Picker("Repeat half cycle order", selection: layout(\.halfCycleOrder)) {
                ForEach(HalfCycleOrder.allCases, id: \.self) { Text($0.title).tag($0) }
            }
            .settingTarget("layout.half-cycle-order")
            Picker("Repeating left/right half", selection: layout(\.repeatBehavior)) {
                ForEach(RepeatBehavior.allCases, id: \.self) { Text($0.title).tag($0) }
            }
            .settingTarget("layout.repeat-behavior")
            Toggle("Repeating a quarter cycles through quadrants", isOn: layout(\.quadrantCycling))
                .settingTarget("layout.quadrant-cycling")
            Toggle("Opposite half keeps the current width", isOn: layout(\.oppositeSideSwitch))
                .settingTarget("layout.opposite-side")
            Toggle("Repeating Maximize restores the window", isOn: layout(\.repeatedMaximizeRestores))
                .settingTarget("layout.repeat-maximize")
            Toggle("Halves keep the window's other axis", isOn: layout(\.halvesKeepOtherAxis))
                .settingTarget("layout.halves-other-axis")
            Toggle("Dragging a snapped window restores its size", isOn: layout(\.unsnapRestoresSize))
                .settingTarget("layout.unsnap-size")
            Toggle("Thirds stack vertically on portrait displays", isOn: layout(\.portraitAwareThirds))
                .settingTarget("layout.portrait-thirds")
            Stepper(
                "Almost Maximize: \(Int((options.almostMaximizeFraction * 100).rounded()))%",
                value: layout(\.almostMaximizeFraction), in: 0.5...1, step: 0.05
            )
            .settingTarget("layout.almost-maximize")
            Stepper("Larger / Smaller step: \(Int(options.resizeStep)) pt", value: layout(\.resizeStep), in: 5...200, step: 5)
                .settingTarget("layout.resize-step")
            Stepper(
                "Specified size width: \(Int(options.specifiedSize.width)) pt",
                value: layoutSize(\.width), in: 200...8000, step: 20
            )
            .settingTarget("layout.specified-width")
            Stepper(
                "Specified size height: \(Int(options.specifiedSize.height)) pt",
                value: layoutSize(\.height), in: 200...8000, step: 20
            )
            .settingTarget("layout.specified-height")
        }
    }

    private func layout<V>(_ keyPath: WritableKeyPath<LayoutOptions, V>) -> Binding<V> {
        Binding(
            get: { settings.get(.layoutOptions)[keyPath: keyPath] },
            set: { value in
                var current = settings.get(.layoutOptions)
                current[keyPath: keyPath] = value
                settings.set(current, for: .layoutOptions)
            })
    }

    private func layoutSize(_ keyPath: WritableKeyPath<CGSize, CGFloat>) -> Binding<CGFloat> {
        Binding(
            get: { settings.get(.layoutOptions).specifiedSize[keyPath: keyPath] },
            set: { value in
                var current = settings.get(.layoutOptions)
                current.specifiedSize[keyPath: keyPath] = value
                settings.set(current, for: .layoutOptions)
            })
    }
}

/// The Gaps section: spacing between windows and around the screen.
struct GapSettingsSection: View {
    @ObservedObject var model: AppModel
    private var settings: SettingsStore { model.settings }
    private var gaps: GapOptions { settings.get(.layoutOptions).gaps }

    var body: some View {
        Section("Gaps") {
            Stepper("Between windows: \(Int(gaps.windowGap)) pt", value: gap(\.windowGap), in: 0...100, step: 1)
                .settingTarget("gaps.window-gap")
            Stepper("Screen top: \(Int(gaps.screenGaps.top)) pt", value: gap(\.screenGaps.top), in: 0...200, step: 1)
                .settingTarget("gaps.screen-top")
            Stepper("Screen left: \(Int(gaps.screenGaps.left)) pt", value: gap(\.screenGaps.left), in: 0...200, step: 1)
                .settingTarget("gaps.screen-left")
            Stepper("Screen bottom: \(Int(gaps.screenGaps.bottom)) pt", value: gap(\.screenGaps.bottom), in: 0...200, step: 1)
                .settingTarget("gaps.screen-bottom")
            Stepper("Screen right: \(Int(gaps.screenGaps.right)) pt", value: gap(\.screenGaps.right), in: 0...200, step: 1)
                .settingTarget("gaps.screen-right")
            Toggle("Only on the main screen", isOn: gap(\.mainScreenOnly))
                .settingTarget("gaps.main-screen-only")
            Toggle("Keep windows below the notch", isOn: gap(\.notchAwareTopGap))
                .settingTarget("gaps.notch")
            Toggle("Use full height when the menu bar is hidden", isOn: gap(\.fullHeightWhenMenuBarHidden))
                .settingTarget("gaps.full-height-menu-bar")
            DisclosureGroup("Actions exempt from gaps") {
                ForEach(ActionRegistry.all, id: \.self) { action in
                    Toggle(action.title, isOn: exempt(action))
                }
            }
            .settingTarget("gaps.exempt-actions")
        }
    }

    private func updateLayout(_ change: (inout LayoutOptions) -> Void) {
        var options = settings.get(.layoutOptions)
        change(&options)
        settings.set(options, for: .layoutOptions)
    }

    private func gap<V>(_ keyPath: WritableKeyPath<GapOptions, V>) -> Binding<V> {
        Binding(
            get: { gaps[keyPath: keyPath] },
            set: { value in updateLayout { $0.gaps[keyPath: keyPath] = value } })
    }

    private func exempt(_ action: SnapAction) -> Binding<Bool> {
        Binding(
            get: { gaps.isExempt(action) },
            set: { on in
                updateLayout {
                    if on { $0.gaps.exemptActions.insert(action.name) } else { $0.gaps.exemptActions.remove(action.name) }
                }
            })
    }
}
