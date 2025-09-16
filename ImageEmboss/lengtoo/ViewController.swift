//
//  ViewController.swift
//  lengtoo
//
//  Created by kevin_wang on 2024/11/11.
//

import UIKit
import PhotosUI


class ViewController: UIViewController , UIImagePickerControllerDelegate, UINavigationControllerDelegate,PHPickerViewControllerDelegate{

    @IBOutlet weak var imagesView: CustomizedImgView! //装图片
    @IBOutlet weak var imagesView2: UIImageView! //装图片
    @IBOutlet weak var nameLab: UILabel! //装
    
    var imageAnalysisMG : ImageAnalysisMG!
    

    override func viewDidLoad() {
        super.viewDidLoad()
        imageAnalysisMG = ImageAnalysisMG()

        self.imagesView.addInteraction(self.imageAnalysisMG.interaction)//需要提前绑定 interaction 不然没有圈
//        self.imagesView2.addInteraction(self.imageAnalysisMG.interaction)
   
    }

    func showImg(_ image:UIImage) -> Void {
//        UIImageWriteToSavedPhotosAlbum(resultImg!, nil, nil, nil)
        self.imagesView.clearTrack()
        self.view.backgroundColor = Tools.getMainColor(image)
        self.nameLab.text = ""
        self.imagesView.image = image
        

        //方式1 相册方式
        imageAnalysisMG._callBack = {backImg in
//            self.imagesView.image = backImg
//             self.imagesView2.image = backImg
//            self.imagesView2.frame = self.imageAnalysisMG.rectArr.first!
//            self.imagesView.addSubview(self.imagesView2)
//            self.view.backgroundColor = Tools.getMainColor(backImg)
         }
        imageAnalysisMG.analyzerImg(readImg: image) { ok in
            self.particleizeImage(self.imagesView)
            self.imageAnalysisMG.generateImageForSelectedObjects()
        }
        
        //方式3 抠图方式
//        let imageEmboss = ImageEmboss()
//        imageEmboss.processImage(imageV: imagesView) { resultImg in
//            self.particleizeImage(self.imagesView)
////            self.particleizeImageView(self.imagesView)
//            self.imagesView.image = resultImg
//            DispatchQueue.main.asyncAfter(deadline: .now()+2.0) { //延时
//                self.imagesView.addLinePath()
//            }
//        }
        
        //方式2
//        let imageProcessor = ImageProcessor()
//        imageProcessor.processImage(image) { resultImg in
//            self.imagesView.image = resultImg
//        }
        
    }
    
    
    // MARK: - 相机 相册
    @IBAction func openCamera(_ sender : UIButton){
        let pickerVC = UIImagePickerController()
//       pickerVC.modalPresentationStyle = .fullScreen
        pickerVC.view.backgroundColor = .white
        pickerVC.delegate = self
        pickerVC.allowsEditing = false
        pickerVC.sourceType = .camera
        self.present(pickerVC, animated: true, completion: nil)
        //为了 ImageAnalysisMG 让阴影撑满屏幕。 如果使用其他的可以不这么设置
        self.imagesView.contentMode = .scaleAspectFill
    }

    @IBAction func openPhoto(_ sender : UIButton){
        var configuration = PHPickerConfiguration()
        configuration.filter = .images
        configuration.selectionLimit = 1
        configuration.preferredAssetRepresentationMode = .automatic  // 设置预览是否可用
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = self
        self.present(picker, animated: true, completion: nil)
    }
    
    @IBAction func customCamera(_ sender : UIButton){
        let customCameraVC = CustomCameraVC()
        customCameraVC._getImgBlock = { image in
            self.imagesView.contentMode = .scaleAspectFit
            self.showImg(image)
        }
        customCameraVC.modalPresentationStyle = .fullScreen
            self.present(customCameraVC, animated: true)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if var image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            if Tools.imageSizeMB(image: image) > 6{
                image = Tools.imageCompress(image)
            }
             if Tools.imageSizeMB(image: image) > 1{ //压缩图片
                let data = image.jpegData(compressionQuality: 0.1)
                image = UIImage(data: data ?? Data())!
            }
            showImg(image)
        }
        picker.dismiss(animated: true,completion:nil)
        
    }
    
    //PHPickerViewControllerDelegate
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        for result in results {   //视频 UTType.movie.identifier
            result.itemProvider.loadFileRepresentation(forTypeIdentifier: UTType.image.identifier) { url, error in
                if let error = error {
                    print("Error loading image: \(error.localizedDescription)")
                    return
                }
                if let fileURL = url {// 处理选择的图片URL
                    if let image = UIImage(contentsOfFile: fileURL.path) {
                        DispatchQueue.main.async {
                            self.imagesView.contentMode = .scaleAspectFit
                            self.showImg(image)
                            
                        }
                    }
                }
            }
        }
            picker.dismiss(animated: true, completion: nil)

    }
    
    // MARK: - 动画
    //化成灰 四处乱窜
    func particleizeImageView(_ imageView: UIImageView, particleSize: CGFloat = 3.0) {
        guard let image = imageView.image,let cgImage = image.cgImage else { return }
        
        var imageRect : CGRect = CGRect(origin: CGPointMake(0, 0), size: imageView.frame.size)
        if imageView.contentMode == .scaleAspectFit,let backRect = imageView.frameForImage(){
            imageRect = backRect
        }
        
//        let imageSize = imageView.bounds.size
        let imageSize = imageRect.size

           // 获取像素数据
           guard let data = cgImage.dataProvider?.data,let bytes = CFDataGetBytePtr(data) else { return }

           let width = cgImage.width
           let height = cgImage.height
        print("width:",width)
        print("height:",height)
           let bytesPerPixel = 4
           let bytesPerRow = cgImage.bytesPerRow

        let passSize = 9
           for y in stride(from: 0, to: height, by: Int(passSize)) {
               for x in stride(from: 0, to: width, by: Int(passSize)) {
                   let pixelIndex = y * bytesPerRow + x * bytesPerPixel
                   let r = CGFloat(bytes[pixelIndex]) / 255.0
                   let g = CGFloat(bytes[pixelIndex + 1]) / 255.0
                   let b = CGFloat(bytes[pixelIndex + 2]) / 255.0
                   let a = CGFloat(bytes[pixelIndex + 3]) / 255.0

                   if a < 0.05 { continue }

                   let color = UIColor(red: r, green: g, blue: b, alpha: a)
                   //这里 后加入的 imageRect.origin.x&y 因为是scaleAspectFit
                   let particle = UIView(frame: CGRect(x: CGFloat(x) * imageSize.width / CGFloat(width) + imageRect.origin.x,
                                                       y: CGFloat(y) * imageSize.height / CGFloat(height) + imageRect.origin.y,
                                                       width: particleSize,height: particleSize))
                   
                   particle.backgroundColor = color
                   particle.layer.cornerRadius = particleSize / 2
                   particle.frame = CGRectMake(imageView.frame.origin.x+particle.frame.origin.x, imageView.frame.origin.y+particle.frame.origin.y, particle.frame.size.width, particle.frame.size.height)
                   self.view.insertSubview(particle, belowSubview: imageView)
                   // 粒子动画
                   UIView.animate(withDuration: 1.5,delay: Double.random(in: 0.5...1.0),options: [],animations: {
                       let dx = CGFloat.random(in: -150...150)
                       let dy = CGFloat.random(in: -200...50)
                       particle.transform = CGAffineTransform(translationX: dx, y: dy).rotated(by: .pi * CGFloat.random(in: -2...2))
                       particle.alpha = 0
                   }, completion: { _ in
                       particle.removeFromSuperview()
                   })
               }
           }
        imageView.image = nil
       }

    //化成灰 然后向上飘  这个动画⚠️要注意容器的位置
    func particleizeImage(_ imageView: UIImageView, particleSize: CGSize = CGSize(width: 4, height: 4)) {
           guard let image = imageView.image else { return }
           
        var imageRect : CGRect = CGRect(origin: CGPointMake(0, 0), size: imageView.frame.size)
        if imageView.contentMode == .scaleAspectFit,let backRect = imageView.frameForImage(){
            imageRect = backRect
        }
        
           // 2. 创建粒子容器
           let particleContainer = UIView(frame: imageRect)
           particleContainer.backgroundColor = .clear
        self.view.insertSubview(particleContainer, belowSubview: imageView)
        
           // 3. 创建粒子网格
           let cols = Int(imageRect.width / particleSize.width)
           let rows = Int(imageRect.height / particleSize.height)
           
           for row in 0..<rows {
               for col in 0..<cols {
                   let xOffset = CGFloat(col) * particleSize.width
                   let yOffset = CGFloat(row) * particleSize.height
                   let particleRect = CGRect(x: xOffset, y: yOffset, width: particleSize.width, height: particleSize.height)
                   
                   // 4. 创建单个粒子
                   let particle = CALayer()
                   particle.frame = particleRect
                   particle.contents = image.cgImage
                   particle.contentsRect = CGRect(
                       x: xOffset / imageRect.width,
                       y: yOffset / imageRect.height,
                       width: particleSize.width / imageRect.width,
                       height: particleSize.height / imageRect.height
                   )
                   particle.contentsGravity = .resizeAspect //等比例缩放，完整显示内容
//                   particle.cornerRadius = particleSize.width / 2
//                   particle.masksToBounds = true
                   
                   // 11. 添加随机偏移使粒子看起来更自然
//                                  let jitterX = CGFloat.random(in: -1...1)
//                                  let jitterY = CGFloat.random(in: -1...1)
//                                  particle.position.x += jitterX
//                                  particle.position.y += jitterY
                                  particleContainer.layer.addSublayer(particle)
               }
           }
           
        imageView.image = nil
           // 5. 3秒后执行粒子飘散动画
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
               self.animateParticles(particles: particleContainer)
           }
       }
    
    func animateParticles(particles: UIView) {
        guard let particleLayers = particles.layer.sublayers else { return }
        
        for layer in particleLayers {
            // 6. 为每个粒子创建随机动画参数
            let randomX = CGFloat.random(in: -50...50)
            let randomY = CGFloat.random(in: -150 ... -80)
            let duration = Double.random(in: 2.0...4.0)
            let delay = Double.random(in: 0...0.5)
            
            // 7. 位置动画（向上飘散）
            let positionAnimation = CAKeyframeAnimation()
            positionAnimation.keyPath = "position"
            positionAnimation.values = [
                layer.position,
                CGPoint(x: layer.position.x + randomX, y: layer.position.y + randomY),
                CGPoint(x: layer.position.x + randomX * 1.5, y: layer.position.y + randomY * 3)
            ]
            positionAnimation.keyTimes = [0, 0.7, 1]
            
            // 8. 透明度动画（渐隐）
            let opacityAnimation = CABasicAnimation()
            opacityAnimation.keyPath = "opacity"
            opacityAnimation.fromValue = 1.0
            opacityAnimation.toValue = 0.0
            
            // 9. 缩放动画（缩小）
            let scaleAnimation = CABasicAnimation()
            scaleAnimation.keyPath = "transform.scale"
            scaleAnimation.toValue = CGFloat.random(in: 0.1...0.5)
            
            // 10. 组合动画
            let group = CAAnimationGroup()
            group.animations = [positionAnimation, opacityAnimation, scaleAnimation]
            group.duration = duration
            group.beginTime = CACurrentMediaTime() + delay
            group.fillMode = .forwards
            group.isRemovedOnCompletion = false
            
            layer.add(group, forKey: nil)
        }
        
        // 11. 动画完成后移除粒子容器
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            particles.removeFromSuperview()
        }
    }
   
   
}
