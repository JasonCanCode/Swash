import UIKit

/**
 A type that represents a font and can generate a `UIFont` object.
 */
public protocol Font {
    
    /**
     Defines a mapping to convert one Font weight to another in the case that `UIAccessibility.isBoldTextEnabled` is true. Does not apply to watchOS.
     
     Example:
     ```
     var boldTextMapping: MyFont {
         switch self {
         case .regular: return .bold
         case .bold: return .black
         case .black: return self
         }
     }
     ```
     Now every regular `MyFont` instance will become bold if the user has "Bold Text" turned on in their device settings.
     
     If you'd like, you can observe `UIAccessibility.boldTextStatusDidChangeNotification` via `NotificationCenter` and set your fonts when that updates.
     */
    var boldTextMapping: Self { get }
    
    /**
     Defines a list of fonts to fall back to in the case that characters are used which the font does not support. Uses `UIFontDescriptor.AttributeName.cascadeList`.
     
     Example:
     ```
     var cascadeList: [CascadingFontProperties] {
         switch self {
         case .regular:
             return [.init(Damascus.regular)]
         case .bold:
             return [.init(Damascus.bold)]
     }
     ```
     */
    var cascadeList: [CascadingFontProperties] { get }
    
    func of(size: CGFloat) -> UIFont
    func of(textStyle: UIFont.TextStyle, maxSize: CGFloat?, defaultSize: CGFloat?) -> UIFont
    
    static func preferred(forStyle textStyle: UIFont.TextStyle) -> Self
    static func preferredSize(forStyle textStyle: UIFont.TextStyle) -> CGFloat
    static func font(forStyle textStyle: UIFont.TextStyle, maxSize: CGFloat?) -> UIFont
}

// MARK: - Default Implementations

public extension Font where Self: Hashable, Self: RawRepresentable, Self.RawValue == String {
    var name: String { rawValue }
    
    /**
     Creates a font object of the specified size.
     
     The `rawValue` string is used to initialize the `UIFont` object with `UIFont(name:size:)`.
     
     If the font fails to initialize in a debug build (using `-Onone` optimization), a fatal error will be thrown. This is done to help catch boilerplate typos in development.
     
     Instead of using this method to get a font, it’s often more appropriate to use `of(textStyle:maxSize:defaultSize:)` because that method respects the user’s selected content size category.
     
     - Parameter size: The text size for the font.
     
     - Returns: A font object of the specified size.
     */
    func of(size: CGFloat) -> UIFont {
        let fontName: String
        let cascadeNames: [String]

        #if os(iOS) || os(tvOS)
        fontName = UIAccessibility.isBoldTextEnabled
            ? boldTextMapping.rawValue
            : rawValue
        
        cascadeNames = UIAccessibility.isBoldTextEnabled
            ? cascadeList.map { $0.boldFontName ?? $0.fontName }
            : cascadeList.map { $0.fontName }
        #else
        fontName = rawValue
        cascadeNames = cascadeList.map { $0.fontName }
        #endif
        
        guard let font = UIFont(name: fontName, size: size) else {
            // If font not found, crash debug builds.
            assertionFailure("Font not found: \(rawValue)")
            return .systemFont(ofSize: size)
        }
        
        let cascadeDescriptors = cascadeNames.map { UIFontDescriptor(fontAttributes: [.name: $0]) }
        let cascadedFontDescriptor = font.fontDescriptor.addingAttributes([.cascadeList: cascadeDescriptors])
        return UIFont(descriptor: cascadedFontDescriptor, size: size)
    }
}

public extension Font {
    var boldTextMapping: Self { self }
    var cascadeList: [CascadingFontProperties] { [] }
    
    
    /**
     Creates a dynamic font object corresponding to the given parameters.
     
     Uses `UIFontMetrics` to initialize the dynamic font. If the font fails to initialize in a debug build (using `-Onone` optimization), a fatal error will be thrown. This is done to help catch boilerplate typos in development.
     
     - Parameters:
        - textStyle: The text style used to scale the text.
        - defaultSize: The base size used for text scaling. Corresponds to `UIContentSizeCategory.large`.
        - maxSize: The size which the text may not exceed.
     
     - Returns: A dynamic font object corresponding to the given parameters.
     */
    func of(textStyle: UIFont.TextStyle, maxSize: CGFloat? = nil, defaultSize: CGFloat? = nil) -> UIFont {
        let defaultSize = defaultSize ?? Self.preferredSize(forStyle: textStyle)
        let font = of(size: defaultSize)
        let fontMetrics = UIFontMetrics(forTextStyle: textStyle)
        
        if let maxSize = maxSize {
            return fontMetrics.scaledFont(for: font, maximumPointSize: maxSize)
        } else {
            return fontMetrics.scaledFont(for: font)
        }
    }
    
    static func of(textStyle: UIFont.TextStyle, maxSize: CGFloat?) -> UIFont {
        let font = preferred(forStyle: textStyle)
        let size = preferredSize(forStyle: textStyle)
        
        return font.of(textStyle: textStyle, maxSize: maxSize, defaultSize: size)
    }
}

// MARK: - Preferred Sizing

public extension Font {
    
#if os(iOS)
    /// Default text sizes taken from Apple's Human Interface Guidelines for [iOS](https://developer.apple.com/design/human-interface-guidelines/ios/visual-design/typography/ ).
    /// These sizes correspond to the default category used by `UIFontMetrics` for dynamic type.
    static func preferredSize(forStyle textStyle: UIFont.TextStyle) -> CGFloat {
        switch textStyle {
            case .caption2: return 11
            case .caption1: return 12
            case .footnote: return 13
            case .subheadline: return 15
            case .callout: return 16
            case .body: return 17
            case .headline: return 17
            case .title3: return 20
            case .title2: return 22
            case .title1: return 28
            case .largeTitle: return 34
            default: return 17
        }
    }
    
#elseif os(tvOS)
    /// Default text sizes taken from Apple's Human Interface Guidelines for [watchOS](https://developer.apple.com/design/human-interface-guidelines/watchos/visual-design/typography/ ).
    /// These sizes correspond to the default category used by `UIFontMetrics` for dynamic type.
    static func preferredSize(forStyle textStyle: UIFont.TextStyle) -> CGFloat {
        switch textStyle {
            case .caption2: return 23
            case .caption1: return 25
            case .footnote: return 29
            case .subheadline: return 29
            case .callout: return 31
            case .body: return 29
            case .headline: return 38
            case .title3: return 48
            case .title2: return 57
            case .title1: return 76
            case .largeTitle: return 76
            default: return 17
        }
    }
    
#elseif os(watchOS)
    /// Default text sizes taken from Apple's Human Interface Guidelines for [tvOS](https://developer.apple.com/design/human-interface-guidelines/tvos/visual-design/typography/ ).
    /// These sizes correspond to the default category used by `UIFontMetrics` for dynamic type.
    static func preferredSize(forStyle textStyle: UIFont.TextStyle) -> CGFloat {
        
        switch (WKInterfaceDevice.current().preferredContentSizeCategory) {
            case "UICTContentSizeCategoryS":
                
                switch textStyle {
                    case .footnote: return 12
                    case .caption2: return 13
                    case .caption1: return 14
                    case .body: return 15
                    case .headline: return 15
                    case .title3: return 18
                    case .title2: return 26
                    case .title1: return 30
                    case .largeTitle: return 32
                    default: return 15
                }

            case "UICTContentSizeCategoryL":
                
                switch textStyle {
                    case .footnote: return 13
                    case .caption2: return 14
                    case .caption1: return 15
                    case .body: return 16
                    case .headline: return 16
                    case .title3: return 19
                    case .title2: return 27
                    case .title1: return 34
                    case .largeTitle: return 36
                    default: return 16
                }

            case "UICTContentSizeCategoryXL":
                
                switch textStyle {
                    case .footnote: return 13
                    case .caption2: return 14
                    case .caption1: return 15
                    case .body: return 16
                    case .headline: return 16
                    case .title3: return 19
                    case .title2: return 27
                    case .title1: return 34
                    case .largeTitle: return 36
                    default: return 16
                }
            
            default:
                return 16
        }
    }
    
#endif
    
}
