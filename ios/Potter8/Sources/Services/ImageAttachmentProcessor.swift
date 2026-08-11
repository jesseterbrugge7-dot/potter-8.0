import UIKit

enum ImageAttachmentError: LocalizedError {
    case unreadableImage
    case imageTooLarge

    var errorDescription: String? {
        switch self {
        case .unreadableImage:
            "Potter could not read that photo. Try a different image."
        case .imageTooLarge:
            "That photo is too large to attach. Try a smaller image."
        }
    }
}

enum ImageAttachmentProcessor {
    private static let maxImageDimension: CGFloat = 1_600
    private static let maxThumbnailDimension: CGFloat = 360
    private static let maxImageBytes = 4 * 1_024 * 1_024

    static func prepare(_ sourceData: Data) throws -> PendingImageAttachment {
        guard let sourceImage = UIImage(data: sourceData),
              sourceImage.size.width > 0,
              sourceImage.size.height > 0
        else {
            throw ImageAttachmentError.unreadableImage
        }

        let image = render(sourceImage, maxDimension: maxImageDimension)
        var imageData = image.jpegData(compressionQuality: 0.78)
        if let currentData = imageData, currentData.count > maxImageBytes {
            imageData = image.jpegData(compressionQuality: 0.55)
        }

        let thumbnail = render(sourceImage, maxDimension: maxThumbnailDimension)
        guard let imageData,
              imageData.count <= maxImageBytes,
              let thumbnailData = thumbnail.jpegData(compressionQuality: 0.68)
        else {
            throw ImageAttachmentError.imageTooLarge
        }

        return PendingImageAttachment(
            imageData: imageData,
            thumbnailData: thumbnailData,
            mimeType: "image/jpeg"
        )
    }

    private static func render(_ image: UIImage, maxDimension: CGFloat) -> UIImage {
        let largestSide = max(image.size.width, image.size.height)
        let scale = min(1, maxDimension / largestSide)
        let targetSize = CGSize(
            width: max(1, (image.size.width * scale).rounded()),
            height: max(1, (image.size.height * scale).rounded())
        )
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = true
        return UIGraphicsImageRenderer(size: targetSize, format: format).image { context in
            context.cgContext.setFillColor(UIColor.white.cgColor)
            context.cgContext.fill(CGRect(origin: .zero, size: targetSize))
            image.draw(in: CGRect(origin: .zero, size: targetSize))
        }
    }
}
