//
//  CustomizedImgView.swift
//  lengtoo
//
//  Created by kevin_wang on 2025/7/21.
//

import Foundation
import UIKit
import Vision
import CoreGraphics

@MainActor
class CustomizedImgView: UIImageView {
    
    var whitePath : UIBezierPath?
    var originalPath : UIBezierPath?
    
    override var intrinsicContentSize: CGSize {
        .zero
    }
    
    //画线
    func addLinePath(){
        if let bezierPath = self.createOpaquePath(from: self.image!.cgImage!,targetSize: self.frame.size){
            whitePath = bezierPath
            let runner = PathRunner(path: bezierPath,lineWidth: 5,segmentLengthRatio: 0.1,duration: 10.0,hostLayer: self.layer)
            runner.start()
        }
    }

    //获取截图
    func getWhiteImg() -> UIImage? {
//        let shapeLayer = CAShapeLayer()  //用层盖住
//            shapeLayer.path = whitePath?.cgPath
//            shapeLayer.strokeColor = UIColor.white.cgColor
//            shapeLayer.fillColor = UIColor.clear.cgColor
//            shapeLayer.lineWidth = 5
//            shapeLayer.lineJoin = .round
//            shapeLayer.lineCap = .round
//            // 确保图层大小对齐 imageView
//            shapeLayer.frame = self.bounds
//            // 添加到 imageView 的图层上（在图片上方）
//        self.layer.addSublayer(shapeLayer)
            return createWhitePathImg(from: self.image!)
    }
    
    // 清除轨迹
       func clearTrack() {
           self.layer.sublayers?.filter { $0.name == "contourTrackLayer" || $0.name == "movingLineLayer" }
               .forEach { $0.removeFromSuperlayer() }
       }
    
    // MARK: -  获取白底截图
    func createWhitePathImg(from image: UIImage) -> UIImage? {
        guard let cgImage = image.cgImage else { return nil }
        let maskPoints: [CGPoint] = self.extractAlphaContour(from: cgImage) ?? [] //不知道为什么就是需要重新计算。不然空白图
        if maskPoints.count < 1 {
            print("异常")
        }
        // 6. 创建合并路径
        let path = UIBezierPath()
        // 添加上边界（从左到右）
        if let firstLine = maskPoints.first {
            path.move(to: firstLine)
            for bounds in maskPoints {
                path.addLine(to: bounds)
                path.move(to: bounds)
            }
            path.addLine(to: firstLine)
        }
        path.close()
        

        UIGraphicsBeginImageContextWithOptions(image.size, false, image.scale)
        defer { UIGraphicsEndImageContext() }
        // 1. 画原图
        image.draw(at: .zero)
        // 2. 配置路径样式并绘制
        UIColor.white.setStroke()
        path.lineWidth = 20
        path.lineCapStyle = .round
        path.lineJoinStyle = .round
        path.stroke()
        // 3. 获取最终图像
        let resultImg = UIGraphicsGetImageFromCurrentImageContext()
        
        return self.cropImage(resultImg!, toPath: path) ?? nil
    }
    
    func cropImage(_ image: UIImage, toPath path: UIBezierPath) -> UIImage? {
        // 获取路径边界（点单位）
        let pathBounds = path.bounds
        
        // 验证边界有效性
        guard !pathBounds.isEmpty, !pathBounds.isNull, !pathBounds.isInfinite else {
            print("无效的路径边界")
            return nil
        }
        
        // 创建固定方向的图像（确保坐标系一致）
        let fixedImage = image
        let imageScale = fixedImage.scale
        
        // 转换为像素坐标
        let pixelBounds = CGRect(
            x: pathBounds.origin.x * imageScale,
            y: pathBounds.origin.y * imageScale,
            width: pathBounds.width * imageScale,
            height: pathBounds.height * imageScale
        )
        
        // 确保裁剪区域在图像范围内
        let validCropRect = pixelBounds.intersection(CGRect(origin: .zero, size: CGSize(width: fixedImage.cgImage!.width, height: fixedImage.cgImage!.height)))
        
        guard !validCropRect.isEmpty else {
            print("裁剪区域超出图像边界")
            return nil
        }
        
        // 执行裁剪
        guard let cgImage = fixedImage.cgImage,
              let croppedCGImage = cgImage.cropping(to: validCropRect) else {
            print("CGImage裁剪失败")
            return nil
        }
        
        return UIImage(cgImage: croppedCGImage, scale: imageScale, orientation: .up)
    }
    
    //根据CGImage和【CGPoint】裁剪出来图片
    func cropImageWithContour(from originalImage: CGImage, contour: [CGPoint]) -> CGImage? {
        guard !contour.isEmpty else { return nil }
        
        let width = originalImage.width
        let height = originalImage.height
        
        // 创建透明背景的图像上下文
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue
        
        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: bitmapInfo
        ) else {
            return nil
        }
        
        // 调整坐标系以匹配 UIKit 的坐标系 (原点在左上角)
        context.translateBy(x: 0, y: CGFloat(height))
        context.scaleBy(x: 1.0, y: -1.0)
        
        // 创建裁剪路径 - 注意：这里需要将轮廓点的 y 坐标翻转
        let path = CGMutablePath()
        if let firstPoint = contour.first {
            // 翻转 y 坐标
            let flippedFirstPoint = CGPoint(x: firstPoint.x, y: CGFloat(height) - firstPoint.y)
            path.move(to: flippedFirstPoint)
            
            for point in contour.dropFirst() {
                // 翻转每个点的 y 坐标
                let flippedPoint = CGPoint(x: point.x, y: CGFloat(height) - point.y)
                path.addLine(to: flippedPoint)
            }
            path.closeSubpath()
        }
        
        // 应用裁剪路径
        context.addPath(path)
        context.clip()
        
        // 绘制原始图像
        let rect = CGRect(x: 0, y: 0, width: width, height: height)
        context.draw(originalImage, in: rect)
        
        // 获取裁剪后的图像
        let croppedImage = context.makeImage()
        
        // 再次翻转图像以确保方向正确
        guard let finalImage = croppedImage else { return nil }
        
        // 创建一个新的上下文来翻转图像
        guard let flippedContext = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: bitmapInfo
        ) else {
            return finalImage
        }
        
        // 翻转上下文
        flippedContext.translateBy(x: 0, y: CGFloat(height))
        flippedContext.scaleBy(x: 1.0, y: -1.0)
        
        // 绘制图像
        flippedContext.draw(finalImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        
        return flippedContext.makeImage()
    }
    
    // MARK: -  透明图获取轮廓路径
  //给定图片 获取边缘路径
        func createOpaquePath(from cgImage: CGImage, targetSize: CGSize) -> UIBezierPath? {
            let width = cgImage.width
            let height = cgImage.height
            let maskPoints: [CGPoint] = self.extractAlphaContour2(from: cgImage) ?? []
            if maskPoints.count < 1 {
                print("异常")
            }
            // 6. 创建合并路径
            let path = UIBezierPath()
            
            // 添加上边界（从左到右）
            if let firstLine = maskPoints.first {
                path.move(to: firstLine)
                
                for bounds in maskPoints {
                    path.addLine(to: bounds)
                    path.move(to: bounds)
                }
                path.addLine(to: firstLine)
            }
            path.close()
            originalPath = path
            // 7. 坐标转换到目标视图尺寸
            return scalePathToTargetSize(path,imageSize: CGSize(width: width, height: height),targetSize: targetSize)
        }
        // 坐标转换方法
        private func scalePathToTargetSize(_ path: UIBezierPath,imageSize: CGSize,targetSize: CGSize) -> UIBezierPath {
            // 计算Aspect Fit模式下的实际显示区域
            let contentRect = calculateAspectFitRect(imageSize: imageSize,targetSize: targetSize)
            // 创建坐标变换
            let transform = CGAffineTransform(translationX: contentRect.origin.x,y: contentRect.origin.y)
                .scaledBy(x: contentRect.width / imageSize.width,y: contentRect.height / imageSize.height)
            
            // 应用变换到路径
            path.apply(transform)
            return path
        }

        private func calculateAspectFitRect(imageSize: CGSize, targetSize: CGSize) -> CGRect {
            // 计算缩放比例
            let scale = min(targetSize.width / imageSize.width,targetSize.height / imageSize.height)
            // 计算实际显示尺寸
            let scaledSize = CGSize(width: imageSize.width * scale,height: imageSize.height * scale)
            // 计算居中位置
            let origin = CGPoint(x: (targetSize.width - scaledSize.width) / 2,y: (targetSize.height - scaledSize.height) / 2)
            
            return CGRect(origin: origin, size: scaledSize)
        }
    
    // MARK: -  核心-边缘算法
    //gpt
    func extractAlphaContour(from cgImage: CGImage) -> [CGPoint]? {
        let width = cgImage.width
        let height = cgImage.height

        let bytesPerPixel = 4
        let bytesPerRow = bytesPerPixel * width
        let bitsPerComponent = 8

        var pixelData = [UInt8](repeating: 0, count: Int(height * width * 4))
        guard let context = CGContext(
            data: &pixelData,
            width: width,
            height: height,
            bitsPerComponent: bitsPerComponent,
            bytesPerRow: bytesPerRow,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return nil }

        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))

        // 构建二值 alpha 掩码：非透明为 true
        var alphaMask = Array(repeating: false, count: width * height)
        for y in 0..<height {
            for x in 0..<width {
                let index = y * width + x
                let pixelIndex = index * 4
                let alpha = pixelData[pixelIndex + 3]
                alphaMask[index] = alpha > 0
            }
        }

        // 用 Moore-Neighbor Tracing 找轮廓
        func getPixel(x: Int, y: Int) -> Bool {
            guard x >= 0, x < width, y >= 0, y < height else { return false }
            return alphaMask[y * width + x]
        }

        let neighborOffsets = [  // 按逆时针顺序
            (-1,  0), (-1, -1), ( 0, -1), ( 1, -1),
            ( 1,  0), ( 1,  1), ( 0,  1), (-1,  1)
        ]

        var visited = Set<String>()
        var contour: [CGPoint] = []

        // 找起点
        var startX = 0, startY = 0
        var foundStart = false
        outer: for y in 0..<height {
            for x in 0..<width {
                if getPixel(x: x, y: y) {
                    startX = x
                    startY = y
                    foundStart = true
                    break outer
                }
            }
        }
        if !foundStart { return nil }

        var current = (x: startX, y: startY)
        var prevDir = 0
        repeat {
            contour.append(CGPoint(x: current.x, y: current.y))
            var foundNext = false
            for i in 0..<8 {
                let dir = (prevDir + i) % 8
                let offset = neighborOffsets[dir]
                let nx = current.x + offset.0
                let ny = current.y + offset.1

                let key = "\(nx),\(ny)"
                if getPixel(x: nx, y: ny) && !visited.contains(key) {
                    visited.insert(key)
                    current = (nx, ny)
                    prevDir = (dir + 5) % 8  // 回退方向
                    foundNext = true
                    break
                }
            }

            if !foundNext {
                break  // 封闭路径结束
            }
        } while !(current.x == startX && current.y == startY)

        return contour
    }
    //deepseek
    func extractAlphaContour2(from cgImage: CGImage) -> [CGPoint]? {
        let width = cgImage.width
        let height = cgImage.height
        
        // 创建上下文来读取像素数据
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bytesPerPixel = 4
        let bytesPerRow = bytesPerPixel * width
        let bitsPerComponent = 8
        
        var pixelData = [UInt8](repeating: 0, count: height * width * bytesPerPixel)
        
        guard let context = CGContext(
            data: &pixelData,
            width: width,
            height: height,
            bitsPerComponent: bitsPerComponent,
            bytesPerRow: bytesPerRow,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            return nil
        }
        
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        
        // 创建alpha掩码
        var alphaMask = [Bool](repeating: false, count: width * height)
        for y in 0..<height {
            for x in 0..<width {
                let index = y * width + x
                let alpha = pixelData[index * 4 + 3]  // Alpha值在RGBA中的第4个位置
                alphaMask[index] = alpha > 0
            }
        }
        
        // 辅助函数检查像素是否在不透明区域内
        func isOpaquePixel(x: Int, y: Int) -> Bool {
            guard x >= 0, x < width, y >= 0, y < height else { return false }
            return alphaMask[y * width + x]
        }
        
        // 定义8个邻居方向的偏移量（逆时针顺序）
        let neighborOffsets = [
            (0, -1),  // 上
            (1, -1),  // 右上
            (1, 0),   // 右
            (1, 1),   // 右下
            (0, 1),   // 下
            (-1, 1),  // 左下
            (-1, 0),  // 左
            (-1, -1)  // 左上
        ]
        
        // 寻找起始点（第一个不透明像素）
        var startPoint: (x: Int, y: Int)?
        for y in 0..<height {
            for x in 0..<width {
                if isOpaquePixel(x: x, y: y) {
                    startPoint = (x, y)
                    break
                }
            }
            if startPoint != nil { break }
        }
        
        guard let start = startPoint else { return nil }
        
        var contour = [CGPoint]()
        var current = start
        var previousDirection = 7 // 从左上方向开始搜索
        let maxIterations = width * height * 2 // 防止无限循环
        
        // 使用Moore-Neighbor追踪算法
        for _ in 0..<maxIterations {
            contour.append(CGPoint(x: current.x, y: current.y))
            
            var foundNext = false
            var nextDirection = 0
            var nextPoint = (x: 0, y: 0)
            
            // 从上一个方向的前一个位置开始搜索（逆时针）
            for i in 0..<8 {
                let direction = (previousDirection + 1 + i) % 8
                let offset = neighborOffsets[direction]
                let nx = current.x + offset.0
                let ny = current.y + offset.1
                
                if isOpaquePixel(x: nx, y: ny) {
                    nextPoint = (nx, ny)
                    nextDirection = direction
                    foundNext = true
                    break
                }
            }
            
            if !foundNext {
                // 没有找到下一个点，可能是孤立像素
                break
            }
            
            // 检查是否回到起点，形成闭合轮廓
            if nextPoint.x == start.x && nextPoint.y == start.y && contour.count > 2 {
                break
            }
            
            current = nextPoint
            previousDirection = (nextDirection + 5) % 8 // 调整方向以便下一次逆时针搜索
        }
        
        return contour
    }
}

