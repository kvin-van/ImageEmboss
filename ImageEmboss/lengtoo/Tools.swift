//
//  Tools.swift
//  lengtoo
//
//  Created by kevin_wang on 2025/7/18.
//

import Foundation
import UIKit
import CoreImage


class Tools :Any{
    
    //获取主体颜色
    static func getMainColor(_ image:UIImage) -> UIColor? {
        guard let ciImage = CIImage(image: image) else { return nil }
        let context = CIContext()
        let extent = ciImage.extent
        
        // 创建滤镜并设置参数（使用 inputExtent 代替 inputCenter/inputRadius）
           guard let filter = CIFilter(name: "CIAreaAverage", parameters: [
               kCIInputImageKey: ciImage,
               kCIInputExtentKey: CIVector(cgRect: extent)
           ]) else { return nil }
           
           // 获取输出图像（此时是 1x1 像素）
           guard let outputImage = filter.outputImage else { return nil }
        // 创建单像素位图
            var pixel = [UInt8](repeating: 0, count: 4)
            let bounds = CGRect(x: 0, y: 0, width: 1, height: 1)
            
            // 直接渲染到像素缓冲区
            context.render(outputImage,toBitmap: &pixel,rowBytes: 4,bounds: bounds,format: .RGBA8,colorSpace: nil)
            
            // 从缓冲区读取颜色值
            return UIColor(red: CGFloat(pixel[0]) / 255.0,green: CGFloat(pixel[1]) / 255.0,blue: CGFloat(pixel[2]) / 255.0,alpha: CGFloat(pixel[3]) / 255.0)
    }
    
    //读取img小大
    static func imageSizeMB(image: UIImage) -> Int {
        // 1. 获取图片数据
        let data = image.pngData()!
        // 2. 将数据转换为 Data 对象
        let imageData = Data(data)
        // 3. 获取字节数
        let byteCount = imageData.count
        // 4. 将字节数转换为兆字节数
        let megabyteCount = byteCount / 1024 / 1024
        print("图片大小：",byteCount/1024,"KB")
        return megabyteCount
    }
    
    //压缩图片
    static func imageCompress(_ image:UIImage) -> UIImage{
        let imageSize = Tools.imageSize(image, true)
        let reImage = Tools.scaleToSize(image, imageSize)
        let data = reImage.jpegData(compressionQuality: 0.1)
        return UIImage(data: data!)!
    }
    
    //裁图
    static func scaleToSize(_ image:UIImage,_ size:CGSize) -> UIImage{
        //第一个参数表示区域大小。第二个参数表示是否是非透明的。如果需要显示半透明效果,需要传NO,否则传YES。第三个参数就是屏幕密度了
        UIGraphicsBeginImageContext(size)
        var newImage = UIImage(cgImage: image.cgImage!,scale: 1,orientation: image.imageOrientation)
        newImage.draw(in: CGRectMake(0, 0, size.width, size.height))
        newImage = UIGraphicsGetImageFromCurrentImageContext() ?? UIImage()
        UIGraphicsEndImageContext()
        return newImage
    }
    
    //获取压缩尺寸
    static func imageSize(_ image:UIImage,_ isSession:Bool) -> CGSize{
        var width = image.size.width;
        var height = image.size.height;
        var boundary:CGFloat = 1280
        
        // width, height <= 1280, Size remains the same
        if (width < boundary && height < boundary) {
            return CGSizeMake(width, height)
        }
        
        // aspect ratio
        let ratio:CGFloat = max(width, height) / min(width, height);
        if (ratio <= 2) {
            let x:CGFloat = max(width, height) / boundary;
            if (width > height) {
                width = boundary
                height = height / x
            } else {
                height = boundary
                width = width / x
            }
        } else {
            // width, height > 1280
            if (min(width, height) >= boundary) {
                boundary = isSession ? 800:1280;
                // Set the smaller value to the boundary, and the larger value is compressed
                let x:CGFloat = min(width, height) / boundary;
                if (width < height) {
                    width = boundary;
                    height = height / x;
                } else {
                    height = boundary;
                    width = width / x;
                }
            }
        }
        return CGSizeMake(width, height);
    }
}
