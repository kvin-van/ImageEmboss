import UIKit
import Vision
import CoreImage
//去掉背景并且生成识别出的文字或者主体的轮廓

class ImageProcessor {
    func processImage(_ image: UIImage, completion: @escaping (UIImage?) -> Void) {
        guard let cgImage = image.cgImage else {
            completion(nil)
            return
        }
        
        DispatchQueue.global(qos: .userInitiated).async {
            // 创建图像处理请求
            let maskRequest = VNGenerateForegroundInstanceMaskRequest()
            let contourRequest = VNDetectContoursRequest()
            contourRequest.revision = VNDetectContourRequestRevision1
            contourRequest.detectsDarkOnLight = false // 假设物体比背景暗
            contourRequest.contrastAdjustment = 1.5
            contourRequest.maximumImageDimension = 1024  // 限制处理尺寸提高性能
            
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
                try handler.perform([maskRequest])
                
                guard let maskResult = maskRequest.results?.first else {
                    DispatchQueue.main.async { completion(nil) }
                    return
                }
                
                // 修复：使用正确的方法创建透明背景
                guard let transparentImage = self.removeBackground(from: image, using: maskResult) else {
                    DispatchQueue.main.async { completion(nil) }
                    return
                }
//                DispatchQueue.main.async { completion(transparentImage) }
                
                try handler.perform([contourRequest])
                
                guard let contourResult = contourRequest.results?.first else {
                    DispatchQueue.main.async { completion(transparentImage) }
                    return
                }
                
                let finalImage = self.drawContours(
                    contours: contourResult,
                    on: transparentImage,
                    lineWidth: 3.0,
                    lineColor: UIColor.white
                )
                
                DispatchQueue.main.async { completion(finalImage) }
                
            } catch {
                print("图像处理失败: \(error)")
                DispatchQueue.main.async { completion(nil) }
            }
        }
    }
    
    private func removeBackground(from image: UIImage, using mask: VNInstanceMaskObservation) -> UIImage? {
        guard let maskBuffer = try? mask.generateScaledMaskForImage(forInstances: mask.allInstances, from: VNImageRequestHandler(cgImage: image.cgImage!)) else {
            return nil
        }
        
        // 修复：正确创建透明背景
        guard let ciImage = CIImage(image: image),
              let filter = CIFilter(name: "CIBlendWithMask") else {
            return nil
        }
        
        let maskCIImage = CIImage(cvImageBuffer: maskBuffer)
        
        // 创建透明背景图像（大小与原始图像相同）
        let backgroundImage = CIImage(color: CIColor.clear)
            .cropped(to: ciImage.extent)
        
        filter.setValue(ciImage, forKey: kCIInputImageKey)
        filter.setValue(backgroundImage, forKey: kCIInputBackgroundImageKey) // 使用透明背景图像
        filter.setValue(maskCIImage, forKey: kCIInputMaskImageKey)
        
        guard let outputCIImage = filter.outputImage else { return nil }
        
        let context = CIContext()
        guard let outputCGImage = context.createCGImage(outputCIImage, from: outputCIImage.extent) else { return nil }
        
        return UIImage(cgImage: outputCGImage)
    }
    
    private func drawContours(contours: VNContoursObservation,on image: UIImage,lineWidth: CGFloat,lineColor: UIColor) -> UIImage {
        let imageSize = image.size
        let renderer = UIGraphicsImageRenderer(size: imageSize)
        
        return renderer.image { ctx in
            // 绘制透明背景图像
            image.draw(at: .zero)
            
            let context = ctx.cgContext
            context.setLineWidth(lineWidth)
            context.setStrokeColor(lineColor.cgColor)
            
            // 坐标系转换
            context.scaleBy(x: 1, y: -1)
            context.translateBy(x: 0, y: -imageSize.height)
            
            let path = contours.normalizedPath
            var scale = CGAffineTransform(scaleX: imageSize.width, y: imageSize.height)
            guard let scaledPath = path.copy(using: &scale) else { return }
            
            context.addPath(scaledPath)
            context.strokePath()
        }
    }
}
