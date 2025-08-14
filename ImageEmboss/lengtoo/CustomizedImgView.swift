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
    

    func addLinePath(){
        if let bezierPath = self.createOpaquePath(from: self.image!.cgImage!,targetSize: self.frame.size){
            whitePath = bezierPath
            self.startLineAnimation(with: self.whitePath!)
        }
    }

       func clearTrack() {
           self.layer.sublayers?.filter { $0.name == "contourTrackLayer" || $0.name == "movingLineLayer" }
               .forEach { $0.removeFromSuperlayer() }
       }
    
    func startLineAnimation(with path: UIBezierPath, lineWidth: CGFloat = 5.0, lineSegmentLength: CGFloat = 0.2) {
        let movingLineLayer = CAShapeLayer()
        movingLineLayer.name = "movingLineLayer"
        // 配置 CAShapeLayer
        movingLineLayer.path = path.cgPath
        movingLineLayer.strokeColor = UIColor.white.cgColor
        movingLineLayer.fillColor = nil
        movingLineLayer.lineWidth = lineWidth
        movingLineLayer.lineCap = .round
        
        // 初始值
        movingLineLayer.strokeStart = 0.0
        movingLineLayer.strokeEnd = lineSegmentLength
        
        layer.addSublayer(movingLineLayer)
        
        let duration: CFTimeInterval = 10.0
        // strokeStart 动画
        let startAnim = CABasicAnimation(keyPath: "strokeStart")
        startAnim.fromValue = 0.0
        startAnim.toValue = 1.0 - lineSegmentLength
        startAnim.duration = duration
        startAnim.repeatCount = .infinity
        startAnim.isRemovedOnCompletion = false
        startAnim.fillMode = .forwards
        startAnim.speed = -1.0
        
        // strokeEnd 动画，始终比 start 多 lineSegmentLength
        let endAnim = CABasicAnimation(keyPath: "strokeEnd")
        endAnim.fromValue = lineSegmentLength
        endAnim.toValue = 1.0
        endAnim.duration = duration
        endAnim.repeatCount = .infinity
        endAnim.isRemovedOnCompletion = false
        endAnim.fillMode = .forwards
        endAnim.speed = -1.0

        movingLineLayer.add(startAnim, forKey: "strokeStartAnim")
        movingLineLayer.add(endAnim, forKey: "strokeEndAnim")
    }
    
    

//        func createOpaquePath(from cgImage: CGImage, targetSize: CGSize) -> UIBezierPath? {
//            let width = cgImage.width
//            let height = cgImage.height
//    
//            // 1. 创建颜色空间和位图上下文
//            guard let colorSpace = CGColorSpace(name: CGColorSpace.sRGB),
//                  let context = CGContext(data: nil,
//                                         width: width,
//                                         height: height,
//                                         bitsPerComponent: 8,
//                                         bytesPerRow: width * 4,
//                                         space: colorSpace,
//                                         bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else {
//                return nil
//            }
//    
//            // 2. 绘制图像到上下文
//            context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
//            // 3. 获取像素数据
//            guard let pixelData = context.data?.assumingMemoryBound(to: UInt8.self) else {
//                return nil
//            }
//    
//            // 4. 存储每行不透明区域的边界
//            var lineBounds: [CGRect] = []
//            // 5. 扫描每一行像素
//            for y in 0..<height {
//                var startX: Int? = nil
//                for x in 0..<width {
//                    let pixelIndex = (y * width + x) * 4
//                    let alpha = pixelData[pixelIndex + 3]  // Alpha 通道
//    
//                    if alpha > 0 {  // 检测不透明像素
//                        if startX == nil {
//                            startX = x  // 记录区域开始位置
//                        }
//                    }
//                    else if let start = startX {
//                        // 遇到透明像素且之前有记录起点，保存当前行区域
//                        lineBounds.append(CGRect(x: start, y: y, width: x - start, height: 1))
//                        startX = nil
//                    }
//                }
//                // 处理行尾未闭合的区域
//                if let start = startX {
//                    lineBounds.append(CGRect(x: start, y: y, width: width - start, height: 1))
//                }
//            }
//    
//            // 6. 创建合并路径
//            let path = UIBezierPath()
//    
//            // 添加上边界（从左到右）
//            if let firstLine = lineBounds.first {
//                path.move(to: CGPoint(x: firstLine.minX, y: firstLine.minY))
//            }
//            for bounds in lineBounds {
//                path.addLine(to: CGPoint(x: bounds.minX, y: bounds.minY))
//            }
//            // 添加下边界（从右到左）
//            for bounds in lineBounds.reversed() {
//                path.addLine(to: CGPoint(x: bounds.maxX, y: bounds.minY))
//            }
//            path.close()
//    
//            // 7. 坐标转换到目标视图尺寸
//            return scalePathToTargetSize(path,
//                                        imageSize: CGSize(width: width, height: height),
//                                        targetSize: targetSize)
//        }


        func createOpaquePath(from cgImage: CGImage, targetSize: CGSize) -> UIBezierPath? {
            let width = cgImage.width
            let height = cgImage.height
            let maskPoints: [CGPoint] = self.extractAlphaContour(from: cgImage) ?? []
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
          
            return scalePathToTargetSize(path,imageSize: CGSize(width: width, height: height),targetSize: targetSize)
        }
      
        private func scalePathToTargetSize(_ path: UIBezierPath,imageSize: CGSize,targetSize: CGSize) -> UIBezierPath {

            let contentRect = calculateAspectFitRect(imageSize: imageSize,targetSize: targetSize)

            let transform = CGAffineTransform(translationX: contentRect.origin.x,y: contentRect.origin.y)
                .scaledBy(x: contentRect.width / imageSize.width,y: contentRect.height / imageSize.height)
            
            // 应用变换到路径
            path.apply(transform)
            return path
        }

        private func calculateAspectFitRect(imageSize: CGSize, targetSize: CGSize) -> CGRect {

            let scale = min(targetSize.width / imageSize.width,targetSize.height / imageSize.height)

            let scaledSize = CGSize(width: imageSize.width * scale,height: imageSize.height * scale)

            let origin = CGPoint(x: (targetSize.width - scaledSize.width) / 2,y: (targetSize.height - scaledSize.height) / 2)
            
            return CGRect(origin: origin, size: scaledSize)
        }
    

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
    
}

