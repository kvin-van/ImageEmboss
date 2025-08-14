import Foundation
import UIKit
import CoreImage
import Vision
// 主体背景分离、 生成线动画、生成白底图片
 
@available(macOS 14.0, iOS 17.0, *)
class ImageEmboss : AnyObject{
    
    // 处理输入图像并返回分割结果
    //   - combined: 是否将多个实例合并为单个图像
    public func cutImageAction(image: UIImage, combined: Bool) -> Result<[CIImage], Error> {
         let ciImage = CIImage(cgImage:image.cgImage!)
        //前景实例分割请求
        let req = VNGenerateForegroundInstanceMaskRequest()
        //图像处理器
        let handler = VNImageRequestHandler(ciImage: ciImage, options: [:])
        do {
            try handler.perform([req])
        } catch {
            return .failure(error)
        }
                
        guard let results = req.results!.first else {
            return .failure(NSError(domain: "失败4", code: 4, userInfo: nil))
        }
        
        if combined { //合并所有实例为单个图像
            return self.extractImagesCombined(handler: handler, results: results)
        }
        // 每个实例生成单独图像
        return self.extractImages(handler: handler, results: results)
    }
    
    /// 为每个检测到的实例生成单独的分割图像
       ///   - handler: Vision 图像处理器
       ///   - results: 实例分割结果
       /// - Returns: 包含多个分割图像的 Result 对象
    private func extractImages(handler: VNImageRequestHandler, results: VNInstanceMaskObservation) -> Result<[CIImage], Error>  {
        
        var images: [CIImage] = []
        var i = 1 // 实例索引从1开始（0表示背景）
        // 遍历所有检测到的实例
        for _ in results.allInstances {
            defer {
                i += 1
            }
            
            do {
                // 为当前实例生成掩码图像
                let buf = try results.generateMaskedImage(ofInstances: [i],from: handler,croppedToInstancesExtent: true) // 裁剪到实例边界
                // 将缓冲区转换为 Core Image
                let im = CIImage(cvImageBuffer: buf)
                images.append(im)
            } catch {
                return .failure(error)
            }
        }
        return .success(images)
    }
    
    /// 将所有检测到的实例合并为单个分割图像
        ///   - handler: Vision 图像处理器
        ///   - results: 实例分割结果
        /// - Returns: 包含单个合并图像的 Result 对象
    private func extractImagesCombined(handler: VNImageRequestHandler, results: VNInstanceMaskObservation) -> Result<[CIImage], Error>  {
        
        var images: [CIImage] = []
        do {
            // 为所有实例生成合并的掩码图像
            let buf = try results.generateMaskedImage(ofInstances: results.allInstances,from: handler,croppedToInstancesExtent: true)
            let im = CIImage(cvImageBuffer: buf)
            images.append(im)
        } catch {
            return .failure(error)
        }
        return .success(images)
    }

    // MARK: - 返回去背景整体图片
    public func processImage(imageV: UIImageView, completion: @escaping (UIImage?) -> Void) {
        guard let viewImage = imageV.image,let cgImage = viewImage.cgImage else {
               completion(nil)
               return
           }
           let maskRequest = VNGenerateForegroundInstanceMaskRequest()
        
           let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
           DispatchQueue.global(qos: .userInitiated).async {
               do {
                   try handler.perform([maskRequest])
                   // 获取全部检测结果
                   guard let maskResult = maskRequest.results?.first else {
                       DispatchQueue.main.async { completion(nil) }
                       return
                   }
                   
                   // 修复：使用正确的方法创建透明背景
                   guard let transparentImage = self.removeBackground(from: viewImage, using: maskResult) else {
                       DispatchQueue.main.async { completion(nil) }
                       return
                   }
                   
                   DispatchQueue.main.async { completion(transparentImage) }
//                self.getImageContours(image: transparentImage) { finalImage in
//                       DispatchQueue.main.async { completion(finalImage) }
//                   }
                   
               } catch {
                   DispatchQueue.main.async {
                       completion(nil)
                   }
               }
           }
       }
    
    //获取轮廓图片
     func getImageContours(image: UIImage, completion: @escaping (UIImage?) -> Void) {
        guard let cgImage = image.cgImage else {
             completion(nil)
               return
           }
        // 创建轮廓检测请求
        let contourRequest = VNDetectContoursRequest()
        contourRequest.revision = VNDetectContourRequestRevision1
        contourRequest.contrastAdjustment = 1.0
        contourRequest.detectsDarkOnLight = false
        contourRequest.maximumImageDimension = 512
         
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        do {
            try handler.perform([contourRequest])
            
            guard let contourResult = contourRequest.results?.first else {
                 completion(image)
                return
            }
            
            let finalImage = self.drawContours(contours: contourResult,on: image,lineWidth: 5.0,lineColor: UIColor.white)

             completion(finalImage)
        } catch {
             completion(nil)
        }
    }

    // MARK: - 清除背景
    private func removeBackground(from image: UIImage, using mask: VNInstanceMaskObservation) -> UIImage? {
        guard let firstInstance = mask.allInstances.first else {return nil}
        let maskOne = IndexSet(integer: firstInstance) //只取第一个
        guard let maskBuffer = try? mask.generateScaledMaskForImage(forInstances: maskOne, from: VNImageRequestHandler(cgImage: image.cgImage!)) else {
            return nil
        }
        
        // 修复：正确创建透明背景
        guard let ciImage = CIImage(image: image),
              let filter = CIFilter(name: "CIBlendWithMask") else {
            return nil
        }
        
        let maskCIImage = CIImage(cvImageBuffer: maskBuffer)
        
        // 创建透明背景图像（大小与原始图像相同）
        let backgroundImage = CIImage(color: CIColor.clear).cropped(to: ciImage.extent)
        
        filter.setValue(ciImage, forKey: kCIInputImageKey)
        filter.setValue(backgroundImage, forKey: kCIInputBackgroundImageKey) // 使用透明背景图像
        filter.setValue(maskCIImage, forKey: kCIInputMaskImageKey)
        
        guard let outputCIImage = filter.outputImage else { return nil }
        
        let context = CIContext()
        guard let outputCGImage = context.createCGImage(outputCIImage, from: outputCIImage.extent) else { return nil }

        return UIImage(cgImage: outputCGImage)
    }
    
    //画出轮廓 ：基于轮廓请求 ， 会把图片内部的轮廓画出来。 想基于最外层的轮廓画貌似没有这样的方法。只能通过边缘算法算
    private func drawContours(contours: VNContoursObservation,on image: UIImage,lineWidth: CGFloat,lineColor: UIColor) -> UIImage {
        let imageSize = image.size
        let renderer = UIGraphicsImageRenderer(size: imageSize)
        
        let path : CGPath = contours.normalizedPath
       
        return renderer.image { ctx in
            // 绘制透明背景图像
            image.draw(at: .zero)
            let context = ctx.cgContext
            context.setLineWidth(lineWidth)
            context.setStrokeColor(lineColor.cgColor)
            // 坐标系转换
            context.scaleBy(x: 1, y: -1)
            context.translateBy(x: 0, y: -imageSize.height)
            
            var scale = CGAffineTransform(scaleX: imageSize.width, y: imageSize.height)
            guard let scaledPath = path.copy(using: &scale) else { return }
            
            context.addPath(scaledPath)
            context.strokePath()
        }
    }

}
