//
//  HTMLTextView.swift
//  Broccoli
//
//  Created by Gaurav Jaiswal
//

import SwiftUI
import UIKit

/// A SwiftUI view that renders HTML content
struct HTMLTextView: UIViewRepresentable {
    let htmlString: String
    let font: UIFont
    let textColor: UIColor
    
    init(htmlString: String, font: UIFont = .systemFont(ofSize: 14), textColor: UIColor = .label) {
        self.htmlString = htmlString
        self.font = font
        self.textColor = textColor
    }
    
    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.isEditable = false
        textView.isScrollEnabled = false
        textView.backgroundColor = .clear
        textView.textContainerInset = .zero
        textView.textContainer.lineFragmentPadding = 0
        textView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        return textView
    }
    
    func updateUIView(_ textView: UITextView, context: Context) {
        // Convert HTML to attributed string
        if let attributedString = htmlString.htmlToAttributedString(font: font, textColor: textColor) {
            textView.attributedText = attributedString
        } else {
            // Fallback to plain text if HTML parsing fails
            textView.text = htmlString
            textView.font = font
            textView.textColor = textColor
        }
    }
}

// MARK: - String Extension for HTML Parsing
extension String {
    func htmlToAttributedString(font: UIFont, textColor: UIColor) -> NSAttributedString? {
        // Prepare HTML with styling
        let styledHTML = """
        <html>
        <head>
        <style>
        body {
            font-family: -apple-system;
            font-size: \(font.pointSize)px;
            color: \(textColor.hexString);
            line-height: 1.5;
        }
        p {
            margin: 8px 0;
        }
        h1, h2, h3, h4, h5, h6 {
            margin: 12px 0 8px 0;
            font-weight: 600;
        }
        ul, ol {
            margin: 8px 0;
            padding-left: 20px;
        }
        li {
            margin: 4px 0;
        }
        </style>
        </head>
        <body>
        \(self)
        </body>
        </html>
        """
        
        guard let data = styledHTML.data(using: .utf8) else { return nil }
        
        do {
            let options: [NSAttributedString.DocumentReadingOptionKey: Any] = [
                .documentType: NSAttributedString.DocumentType.html,
                .characterEncoding: String.Encoding.utf8.rawValue
            ]
            
            let attributedString = try NSMutableAttributedString(
                data: data,
                options: options,
                documentAttributes: nil
            )
            
            // Apply custom font to the entire string
            let range = NSRange(location: 0, length: attributedString.length)
            attributedString.addAttribute(.font, value: font, range: range)
            attributedString.addAttribute(.foregroundColor, value: textColor, range: range)
            
            return attributedString
        } catch {
            print("Error parsing HTML: \(error)")
            return nil
        }
    }
}

// MARK: - UIColor Extension for Hex String
extension UIColor {
    var hexString: String {
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        
        getRed(&r, green: &g, blue: &b, alpha: &a)
        
        let rgb: Int = (Int)(r * 255) << 16 | (Int)(g * 255) << 8 | (Int)(b * 255) << 0
        return String(format: "#%06x", rgb)
    }
}
