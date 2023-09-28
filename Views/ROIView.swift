//
//  ROIView.swift
//  mirbot
//
//  Created by Master Móviles on 01/08/2017.
//  Copyright © 2017 Master Móviles. All rights reserved.
//

class ROIView: UIView {
    var theImageView: UIImageView?
    var imageCropped: UIImage?
    
    init(frame: CGRect, theImage: UIImage) {
        super.init(frame: frame)
        
        let rotatedimage: UIImage = scaleAndRotateImage(theImage)
        theImageView = UIImageView(image: rotatedimage)
        if theImage.imageOrientation == .up {
            theImageView?.transform = CGAffineTransform(rotationAngle: 0)
        }
        //print("Size image(after): height(\(self.theImageView!.image!.size.height)) width(\(self.theImageView!.image!.size.width))")
        
        theImageView?.frame = frame
        theImageView?.backgroundColor = UIColor.black
        addSubview(theImageView!)
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func scaleAndRotateImage(_ image: UIImage) -> UIImage {
        let imgRef: CGImage? = image.cgImage
        let width: CGFloat = CGFloat((imgRef?.width)!)
        let height: CGFloat = CGFloat((imgRef?.height)!)
        var transform = CGAffineTransform.identity
        var bounds = CGRect(x: 0, y: 0, width: width, height: height)
        if width > kMAXRESOLUTION || height > kMAXRESOLUTION {
            let ratio: CGFloat = width / height
            if ratio > 1 {
                bounds.size.width = kMAXRESOLUTION
                bounds.size.height = bounds.size.width / ratio
            }
            else {
                bounds.size.height = kMAXRESOLUTION
                bounds.size.width = bounds.size.height * ratio
            }
        }
        let scaleRatio: CGFloat = bounds.size.width / width
        let imageSize = CGSize(width: width, height: height)
        var boundHeight: CGFloat
        let orient: UIImageOrientation = image.imageOrientation
        //FIXME orientation
        switch orient {
        case .up:
            //EXIF = 1
            boundHeight = bounds.size.height
            bounds.size.height = bounds.size.width
            bounds.size.width = boundHeight
            transform = CGAffineTransform(translationX: imageSize.height, y: 0.0)
            transform = transform.rotated(by: .pi / 2.0)
        case .upMirrored:
            //EXIF = 2
            transform = CGAffineTransform(translationX: imageSize.width, y: 0.0)
            transform = transform.scaledBy(x: -1.0, y: 1.0)
        case .down:
            //EXIF = 3
            boundHeight = bounds.size.height
            bounds.size.height = bounds.size.width
            bounds.size.width = boundHeight
            transform = CGAffineTransform(translationX: imageSize.height, y: 0.0)
            transform = transform.rotated(by: .pi / 2.0)
        case .downMirrored:
            //EXIF = 4
            transform = CGAffineTransform(translationX: 0.0, y: imageSize.height)
            transform = transform.scaledBy(x: 1.0, y: -1.0)
        case .leftMirrored:
            //EXIF = 5
            boundHeight = bounds.size.height
            bounds.size.height = bounds.size.width
            bounds.size.width = boundHeight
            transform = CGAffineTransform(translationX: imageSize.height, y: imageSize.width)
            transform = transform.scaledBy(x: -1.0, y: 1.0)
            transform = transform.rotated(by: 3.0 * .pi / 2.0)
        case .left:
            //EXIF = 6
            transform = CGAffineTransform(translationX: -imageSize.height/3, y: imageSize.height)
            transform = transform.scaledBy(x: -1.0, y: 1.0)
            transform = transform.rotated(by: .pi)
        case .rightMirrored:
            //EXIF = 7
            boundHeight = bounds.size.height
            bounds.size.height = bounds.size.width
            bounds.size.width = boundHeight
            transform = CGAffineTransform(scaleX: -1.0, y: 1.0)
            transform = transform.rotated(by: .pi / 2.0)
        case .right:
            //EXIF = 8
            transform = CGAffineTransform(translationX: imageSize.height, y: 0.0)
            transform = transform.scaledBy(x: -1.0, y: 1.0)
        }
        
        UIGraphicsBeginImageContext(bounds.size)
        let context: CGContext? = UIGraphicsGetCurrentContext()
        if orient == .right || orient == .left {
            context?.scaleBy(x: -scaleRatio, y: scaleRatio)
            context?.translateBy(x: -height, y: 0)
        }
        else {
            context?.scaleBy(x: scaleRatio, y: scaleRatio)
            context?.translateBy(x: 0, y: 0)
        }
        context?.concatenate(transform)
        image.draw(in: CGRect(x: 0, y: 0, width: width, height: height))
        imageCropped = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return imageCropped!
    }
}
