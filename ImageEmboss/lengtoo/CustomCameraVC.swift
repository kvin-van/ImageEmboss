//
//  CustomCameraVC.swift
//  lengtoo
//
//  Created by kevin_wang on 2025/7/24.
//

import Foundation
import UIKit
import AVFoundation
import Photos

class CustomCameraVC: UIViewController {
    
    @IBOutlet weak var previewView: UIView!
    @IBOutlet weak var captureButton: UIButton!
    
    // MARK: - 相机属性
       private var captureSession: AVCaptureSession!
       private var previewLayer: AVCaptureVideoPreviewLayer!
       private var photoOutput: AVCapturePhotoOutput!
       private var videoDevice: AVCaptureDevice!
    
    var _getImgBlock:((_ img : UIImage) -> Void)? = nil
    
        private let focusView = UIView()
    
    override func viewDidLoad() {
           super.viewDidLoad()
        view.backgroundColor = .black
        if isGet_Camera == 2{
            SystemAuthorityTool.requestCameraPermission()
        }
        setupCamera()
        
        // 对焦指示器
                focusView.frame = CGRect(x: 0, y: 0, width: 80, height: 80)
                focusView.layer.borderColor = UIColor.yellow.cgColor
                focusView.layer.borderWidth = 2
                focusView.layer.cornerRadius = 40
                focusView.alpha = 0
                previewView.addSubview(focusView)
        
       }
    
    override func viewWillAppear(_ animated: Bool) {
            super.viewWillAppear(animated)
            startCameraSession()
        }
        
        override func viewWillDisappear(_ animated: Bool) {
            super.viewWillDisappear(animated)
            stopCameraSession()
        }
    
    override func viewDidLayoutSubviews() {//布局更新后 最终的调整。
            super.viewDidLayoutSubviews()
            previewLayer?.frame = previewView.bounds
        }
    
    // MARK: - 相机设置
        private func setupCamera() {
            // 1. 创建捕获会话
            captureSession = AVCaptureSession()
            captureSession.sessionPreset = .photo
            // 2. 获取后置摄像头
            guard let device = AVCaptureDevice.default(.builtInWideAngleCamera,for: .video,position: .back) else {
//                showAlert(title: "相机错误", message: "无法访问后置摄像头")
                return
            }
            videoDevice = device
            do {
                // 3. 创建输入
                let input = try AVCaptureDeviceInput(device: device)
                // 4. 配置输出
                photoOutput = AVCapturePhotoOutput()
                // 5. 添加到会话
                if captureSession.canAddInput(input) {
                    captureSession.addInput(input)
                }
                
                if captureSession.canAddOutput(photoOutput) {
                    captureSession.addOutput(photoOutput)
                }
                
                // 6. 创建预览层
                previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
                previewLayer.videoGravity = .resizeAspectFill
                previewLayer.frame = previewView.bounds
                previewView.layer.addSublayer(previewLayer)
                // 7. 添加对焦手势
                let tapGesture = UITapGestureRecognizer(target: self, action: #selector(focusAndExposeTap(_:)))
                previewView.addGestureRecognizer(tapGesture)
                
                // 8. 开始会话
                DispatchQueue.global(qos: .userInitiated).async {
                    self.captureSession.startRunning()
                }
                
            } catch {
                print("相机错误",error.localizedDescription)
            }
        }
    
    private func startCameraSession() {
            DispatchQueue.global(qos: .userInitiated).async {
                if !(self.captureSession?.isRunning ?? false) {
                    self.captureSession?.startRunning()
                }
            }
        }
        
        private func stopCameraSession() {
            DispatchQueue.global(qos: .userInitiated).async {
                if self.captureSession?.isRunning ?? false {
                    self.captureSession?.stopRunning()
                }
            }
        }
    
    // MARK: - 拍照功能
    @IBAction func capturePhoto(_ sender:UIButton) {
           let settings = AVCapturePhotoSettings()
           settings.flashMode =  .off //闪光灯
           
           if let photoOutput = self.photoOutput {
               photoOutput.capturePhoto(with: settings, delegate: self)
           }
       }
    
    // MARK: - 对焦功能
        @objc private func focusAndExposeTap(_ gesture: UITapGestureRecognizer) {
            let point = gesture.location(in: previewView)
            // 显示对焦动画
            focusView.center = point
            focusView.alpha = 1.0
            UIView.animate(withDuration: 0.3, delay: 0.5, options: .curveEaseOut, animations: {
                self.focusView.alpha = 0
            })
            
            // 转换为摄像头坐标
            let cameraPoint = previewLayer.captureDevicePointConverted(fromLayerPoint: point)
            
            do {
                try videoDevice.lockForConfiguration()
                // 对焦模式
                if videoDevice.isFocusPointOfInterestSupported {
                    videoDevice.focusPointOfInterest = cameraPoint
                    videoDevice.focusMode = .autoFocus
                }
                // 曝光模式
                if videoDevice.isExposurePointOfInterestSupported {
                    videoDevice.exposurePointOfInterest = cameraPoint
                    videoDevice.exposureMode = .autoExpose
                }
                videoDevice.unlockForConfiguration()
            } catch {
                print("对焦设置错误: \(error)")
            }
        }
}

// MARK: - AVCapturePhotoCaptureDelegate
extension CustomCameraVC: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard error == nil else {
            print("拍照错误: \(error!.localizedDescription)")
            return
        }
        
        guard let imageData = photo.fileDataRepresentation(),var resultImage = UIImage(data: imageData) else {
            return
        }
        
        // 获取图片方向
        let orientation: UIImage.Orientation
        switch UIDevice.current.orientation {
        case .portraitUpsideDown:
            orientation = .left
        case .landscapeLeft:
            orientation = videoDevice.position == .front ? .downMirrored : .up
        case .landscapeRight:
            orientation = videoDevice.position == .front ? .upMirrored : .down
        default:
            orientation = .right
        }
        
        // 旋转图片
        if let cgImage = resultImage.cgImage {
            resultImage = UIImage(cgImage: cgImage, scale: 1.0, orientation: orientation)
        }
        if Tools.imageSizeMB(image: resultImage) > 6{
            resultImage = Tools.imageCompress(resultImage)
        }
         if Tools.imageSizeMB(image: resultImage) > 1{ //压缩图片
            let data = resultImage.jpegData(compressionQuality: 0.1)
             resultImage = UIImage(data: data ?? Data())!
        }
        
        _getImgBlock?(resultImage)
        self.dismiss(animated: true)
        // 保存图片到相册（可选）
//        saveImageToPhotoLibrary(croppedImage)
    }
    

    
    private func saveImageToPhotoLibrary(_ image: UIImage) {
        PHPhotoLibrary.shared().performChanges {
            PHAssetChangeRequest.creationRequestForAsset(from: image)
        } completionHandler: { success, error in
            if !success {
                print("保存图片错误: \(error?.localizedDescription ?? "未知错误")")
            }
        }
    }
    
}
