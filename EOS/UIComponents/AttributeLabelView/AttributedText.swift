/**
 *  Atributika
 *
 *  Copyright (c) 2017 Pavel Sharanda. Licensed under the MIT license, as follows:
 *
 *  Permission is hereby granted, free of charge, to any person obtaining a copy
 *  of this software and associated documentation files (the "Software"), to deal
 *  in the Software without restriction, including without limitation the rights
 *  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 *  copies of the Software, and to permit persons to whom the Software is
 *  furnished to do so, subject to the following conditions:
 *
 *  The above copyright notice and this permission notice shall be included in all
 *  copies or substantial portions of the Software.
 *
 *  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 *  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 *  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 *  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 *  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 *  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 *  SOFTWARE.
 */

import Foundation

public enum DetectionType {
    case tag(Tag)
    case hashtag(String)
    case mention(String)
    case regex(String)
    case phoneNumber(String)
    case link(URL)
    case textCheckingType(String, NSTextCheckingResult.CheckingType)
    case range
}

public struct Detection {
    public let type: DetectionType
    public let style: AttributeStyle
    public let range: Range<String.Index>
}

public protocol AttributedTextProtocol {
    var string: String {get}
    var detections: [Detection] {get}
    var baseStyle: AttributeStyle {get}
}

extension AttributedTextProtocol {

    private func makeAttributedString(getAttributes: (AttributeStyle)-> [NSAttributedString.Key: Any]) -> NSAttributedString {
        let attributedString = NSMutableAttributedString(string: string, attributes: getAttributes(baseStyle))

        for detection in detections {
            let attrs = getAttributes(detection.style)
            if attrs.count > 0 {
                attributedString.addAttributes(attrs, range: NSRange(detection.range, in: string))
            }
        }

        return attributedString
    }

    public var attributedString: NSAttributedString {
        return makeAttributedString { $0.attributes }
    }

    public var highlightedAttributedString: NSAttributedString {
        return makeAttributedString { $0.highlightedAttributes }
    }

    public var disabledAttributedString: NSAttributedString {
        return makeAttributedString { $0.disabledAttributes }
    }
}

public struct AttributedText: AttributedTextProtocol {
    public let string: String
    public let detections: [Detection]
    public let baseStyle: AttributeStyle

    init(string: String, detections: [Detection], baseStyle: AttributeStyle) {
        self.string = string
        self.detections = detections
        self.baseStyle = baseStyle
    }
}

extension AttributedTextProtocol {

    /// style the whole string
    public func styleAll(_ style: AttributeStyle) -> AttributedText {
        return AttributedText(string: string, detections: detections, baseStyle: baseStyle.merged(with: style))
    }

    /// style things like #xcode #mentions
    public func styleHashtags(_ style: AttributeStyle) -> AttributedText {
        let ranges = string.detectHashTags()
        let ds = ranges.map { Detection(type: .hashtag(String(string[(string.index($0.lowerBound, offsetBy: 1))..<$0.upperBound])), style: style, range: $0) }
        return AttributedText(string: string, detections: detections + ds, baseStyle: baseStyle)
    }

    /// style things like @John @all
    public func styleMentions(_ style: AttributeStyle) -> AttributedText {
        let ranges = string.detectMentions()
        let ds = ranges.map { Detection(type: .mention(String(string[(string.index($0.lowerBound, offsetBy: 1))..<$0.upperBound])), style: style, range: $0) }
        return AttributedText(string: string, detections: detections + ds, baseStyle: baseStyle)
    }

    public func style(regex: String, options: NSRegularExpression.Options = [], style: AttributeStyle) -> AttributedText {
        let ranges = string.detect(regex: regex, options: options)
        let ds = ranges.map { Detection(type: .regex(regex), style: style, range: $0) }
        return AttributedText(string: string, detections: detections + ds, baseStyle: baseStyle)
    }

    public func style(textCheckingTypes: NSTextCheckingResult.CheckingType, style: AttributeStyle) -> AttributedText {
        let ranges = string.detect(textCheckingTypes: textCheckingTypes)
        let ds = ranges.map { Detection(type: .textCheckingType(String(string[$0]), textCheckingTypes), style: style, range: $0) }
        return AttributedText(string: string, detections: detections + ds, baseStyle: baseStyle)
    }

    public func stylePhoneNumbers(_ style: AttributeStyle) -> AttributedText {
        let ranges = string.detect(textCheckingTypes: [.phoneNumber])
        let ds = ranges.map { Detection(type: .phoneNumber(String(string[$0])), style: style, range: $0) }
        return AttributedText(string: string, detections: detections + ds, baseStyle: baseStyle)
    }

    public func styleLinks(_ style: AttributeStyle) -> AttributedText {
        let ranges = string.detect(textCheckingTypes: [.link])

        #if swift(>=4.1)
        let ds = ranges.compactMap { range in
            URL(string: String(string[range])).map { Detection(type: .link($0), style: style, range: range) }
        }
        #else
        let ds = ranges.flatMap { range in
            URL(string: String(string[range])).map { Detection(type: .link($0), style: style, range: range) }
        }
        #endif

        return AttributedText(string: string, detections: detections + ds, baseStyle: baseStyle)
    }

    public func style(range: Range<String.Index>, style: AttributeStyle) -> AttributedText {
        let detection = Detection(type: .range, style: style, range: range)
        return AttributedText(string: string, detections: detections + [detection], baseStyle: baseStyle)
    }
}

extension String: AttributedTextProtocol {

    public var string: String {
        return self
    }

    public var detections: [Detection] {
        return []
    }

    public var baseStyle: AttributeStyle {
        return AttributeStyle()
    }

    public func style(tags: [AttributeStyle], transformers: [TagTransformer] = [TagTransformer.brTransformer]) -> AttributedText {
        let (string, tagsInfo) = detectTags(transformers: transformers)

        var ds: [Detection] = []

        tagsInfo.forEach { tag in

            if let style = (tags.first { style in style.name == tag.tag.name }) {
                ds.append(Detection(type: .tag(tag.tag), style: style, range: tag.range))
            } else {
                ds.append(Detection(type: .tag(tag.tag), style: AttributeStyle(), range: tag.range))
            }
        }

        return AttributedText(string: string, detections: ds, baseStyle: baseStyle)
    }

    public func style(tags: AttributeStyle..., transformers: [TagTransformer] = [TagTransformer.brTransformer]) -> AttributedText {
        return style(tags: tags, transformers: transformers)
    }
}

extension NSAttributedString: AttributedTextProtocol {

    public var detections: [Detection] {

        var ds: [Detection] = []

        enumerateAttributes(in: NSRange(location: 0, length: length), options: []) { (attributes, range, _) in
            if let range = Range(range, in: self.string) {
                ds.append(Detection(type: .range, style: AttributeStyle("", attributes), range: range))
            }
        }

        return ds
    }

    public var baseStyle: AttributeStyle {
        return AttributeStyle()
    }
}
