#if targetEnvironment(macCatalyst)
import CoreGraphics

enum ZMenuPositioning {
    private enum VerticalPlacement {
        case below
        case above
    }

    /// Calculates the top-leading origin for the menu offset relative to the screen,
    /// flipping above if there's not enough space below, and clamping horizontally.
    static func calculate(
        anchorFrame: CGRect,
        menuSize: CGSize,
        screenBounds: CGRect,
        spacing: CGFloat = 4
    ) -> CGPoint {
        let verticalPlacement = determineVerticalPlacement(
            anchorFrame: anchorFrame,
            menuHeight: menuSize.height,
            screenBounds: screenBounds,
            spacing: spacing
        )

        let y: CGFloat
        switch verticalPlacement {
        case .below:
            y = anchorFrame.maxY + spacing
        case .above:
            y = anchorFrame.minY - spacing - menuSize.height
        }

        var x = anchorFrame.midX - menuSize.width / 2
        let margin: CGFloat = 8

        if x < screenBounds.minX + margin {
            x = screenBounds.minX + margin
        } else if x + menuSize.width > screenBounds.maxX - margin {
            x = screenBounds.maxX - margin - menuSize.width
        }

        return CGPoint(x: x, y: y)
    }

    private static func determineVerticalPlacement(
        anchorFrame: CGRect,
        menuHeight: CGFloat,
        screenBounds: CGRect,
        spacing: CGFloat
    ) -> VerticalPlacement {
        let spaceBelow = screenBounds.maxY - anchorFrame.maxY - spacing
        let spaceAbove = anchorFrame.minY - screenBounds.minY - spacing

        if spaceBelow >= menuHeight {
            return .below
        } else if spaceAbove >= menuHeight {
            return .above
        } else {
            return spaceBelow >= spaceAbove ? .below : .above
        }
    }
}

#endif
