import SwiftUI

#if canImport(UIKit)
import UIKit
#endif

enum DecideTypography {
    static let fontName = "Baskerville"
    static let boldFontName = "Baskerville-Bold"

    static func configureAppearance() {
        #if canImport(UIKit)
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.backgroundEffect = UIBlurEffect(style: .systemUltraThinMaterial)
        appearance.shadowColor = .clear
        appearance.titleTextAttributes = [
            .font: UIFont(name: boldFontName, size: 18) ?? .preferredFont(forTextStyle: .headline),
            .foregroundColor: UIColor.label
        ]
        appearance.largeTitleTextAttributes = [
            .font: UIFont(name: boldFontName, size: 42) ?? .preferredFont(forTextStyle: .largeTitle),
            .foregroundColor: UIColor.label
        ]

        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        #endif
    }
}

extension Font {
    static let decideCaption = Font.custom(DecideTypography.fontName, size: 11, relativeTo: .caption)
    static let decideBody = Font.custom(DecideTypography.fontName, size: 17, relativeTo: .body)
    static let decideFootnote = Font.custom(DecideTypography.fontName, size: 13, relativeTo: .footnote)
    static let decideSubheadline = Font.custom(DecideTypography.fontName, size: 15, relativeTo: .subheadline)
    static let decideHeadline = Font.custom(DecideTypography.boldFontName, size: 17, relativeTo: .headline)
    static let decideTitle3 = Font.custom(DecideTypography.boldFontName, size: 20, relativeTo: .title3)
    static let decideTitle2 = Font.custom(DecideTypography.boldFontName, size: 22, relativeTo: .title2)
    static let decideLargeTitle = Font.custom(DecideTypography.boldFontName, size: 40, relativeTo: .largeTitle)
    static let decideDisplay = Font.custom(DecideTypography.boldFontName, size: 54, relativeTo: .largeTitle)
}
