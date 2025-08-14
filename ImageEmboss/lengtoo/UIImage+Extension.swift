//
//  UIImage+Extension.swift
//  AiNews
//
//

import Foundation
import UIKit
import CoreImage

extension UIView {
    /// 打印当前视图及其所有子视图的类名（带层级缩进）
    func printSubviewsHierarchy(level: Int = 0) {
        let indent = String(repeating: "│  ", count: level)
        let className = String(describing: type(of: self))
        print("\(indent)└─ \(className)")
        
        if className == "VKCImageSubjectHighlightView"{
            self.backgroundColor = UIColor(white: 0.2, alpha: 0.4)
//            self.printAllProperties()
        }
        
        subviews.forEach { $0.printSubviewsHierarchy(level: level + 1) }
    }
    
    func printAllProperties() {
           let mirror = Mirror(reflecting: self)
           print("=== \(type(of: self)) 属性列表 ===")
           for child in mirror.children {
               guard let propertyName = child.label else { continue }
               print("\(propertyName): \(child.value)")
           }
       }
}

extension UIImage {
    static func gif(data: Data) -> UIImage? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else {
            return nil
        }
 
        let count = CGImageSourceGetCount(source)
        var images = [UIImage]()
 
        for i in 0..<count {
            if let image = CGImageSourceCreateImageAtIndex(source, i, nil) {
                images.append(UIImage(cgImage: image))
            }
        }
 
        return UIImage.animatedImage(with: images, duration: Double(count) / 30.0) // 30 FPS
    }
    
    static func gif(data: Data,duration:CGFloat) -> UIImage? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else {
            return nil
        }
 
        let count = CGImageSourceGetCount(source)
        var images = [UIImage]()
 
        for i in 0..<count {
            if let image = CGImageSourceCreateImageAtIndex(source, i, nil) {
                images.append(UIImage(cgImage: image))
            }
        }
 
        return UIImage.animatedImage(with: images, duration: duration) // 自定义动画时长
    }
    
    static func gif(name: String) -> UIImage? {
        guard let path = Bundle.main.path(forResource: name, ofType: "gif"),
              let data = try? Data(contentsOf: URL(fileURLWithPath: path)) else {
            return nil
        }
        return gif(data: data)
    }
    static func gif(name: String,duration:CGFloat) -> UIImage? {
        guard let path = Bundle.main.path(forResource: name, ofType: "gif"),
              let data = try? Data(contentsOf: URL(fileURLWithPath: path)) else {
            return nil
        }
        return gif(data: data,duration: duration)
    }
}

extension UIImageView {
    func frameForImage() -> CGRect? { //图片在 imageview内坐标
           guard let image = self.image, contentMode == .scaleAspectFit else {
               return nil
           }
           
           let imageSize = image.size
           let viewSize = bounds.size
           
           // 计算缩放比例
           let widthScale = viewSize.width / imageSize.width
           let heightScale = viewSize.height / imageSize.height
           let scale = min(widthScale, heightScale)
           
           // 计算缩放后尺寸
           let scaledWidth = imageSize.width * scale
           let scaledHeight = imageSize.height * scale
           
           // 计算居中位置
           let x = (viewSize.width - scaledWidth) / 2.0
           let y = (viewSize.height - scaledHeight) / 2.0
           
           return CGRect(x: x, y: y, width: scaledWidth, height: scaledHeight)
       }
    
    func  applyBlurEffect(_ radius: CGFloat) {
             //获取原始图片
        guard let image = self.image else { return }
        let  inputImage =   CIImage (image: image)
             //使用高斯模糊滤镜
             let  filter  =  CIFilter (name:  "CIGaussianBlur" )!
             filter.setValue(inputImage, forKey:kCIInputImageKey)
             //设置模糊半径值（越大越模糊）
             filter.setValue(radius, forKey: kCIInputRadiusKey)
             let  outputCIImage =  filter .outputImage!
        let  rect =  CGRect (origin:  CGPoint .zero, size: self.bounds.size)
             let  cgImage = CIContext(options: nil).createCGImage(outputCIImage, from: rect)
             //显示生成的模糊图片
             self.image =  UIImage (cgImage: cgImage!)
         }
}
