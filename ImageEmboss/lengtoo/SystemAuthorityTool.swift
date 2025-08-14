//
//  SystemAuthorityTool.swift
//  AiBoKe
//
//  Created by kevin_wang on 2025/1/13.
//

import Foundation
import UIKit
import AVFoundation
import Photos

var isGet_MKF : Int? = nil //获取麦克风。1就是同意 2就是未知 0 就是拒绝
var isGet_Camera : Int? = nil //获取相机
var isGet_Photo : Int? = nil //获取相册
var isGet_UserNotification : Int? = nil //获取推送

class SystemAuthorityTool: NSObject {
    
    // MARK: - 麦克风权限
    // 请求麦克风权限
    static func requestMicrophoneAuthorization(){
        AVCaptureDevice.requestAccess(for: .audio) { granted in
            if granted {   // 用户授予了权限
                isGet_MKF = 1
            }
            else {  // 用户拒绝了权限
                isGet_MKF = 0
            }
        }
    }
    
    // 检查麦克风权限状态
    static func checkMicrophoneAuthorization(){
        switch AVCaptureDevice.authorizationStatus(for: .audio) {
        case .authorized:  // 已经有权限，可以直接使用麦克风
            isGet_MKF = 1
            break
        case .notDetermined:  // 权限尚未确定，请求权限
            isGet_MKF = 2
            break
        case .restricted, .denied:   // 权限被限制或已拒绝，无法访问麦克风
            isGet_MKF = 0
            break
        @unknown default:
            break
        }
    }
    
    // MARK: - 推送
    static func checkNotificationAuthorization(){
        UNUserNotificationCenter.current().getNotificationSettings { settings in
                    if settings.authorizationStatus == .authorized {
                        isGet_UserNotification = 1
                    } else if settings.authorizationStatus == .denied {
//                        print("推送权限被拒绝")
                        isGet_UserNotification = 0
                    } else if settings.authorizationStatus == .notDetermined {
//                        print("推送权限尚未确定")
                        isGet_UserNotification = 2
                    }
                else {
                isGet_UserNotification = 2
                    }
                }
    }
    
    static func requestNotificationPermission() {
        let options: UNAuthorizationOptions = [.alert, .badge, .sound]
               UNUserNotificationCenter.current().requestAuthorization(options: options) { granted, error in
                   if let error = error {
                       print("请求推送权限时出错: \(error.localizedDescription)")
                   } else if granted {
                       isGet_UserNotification = 1
                   } else {
//                       print("推送权限请求被拒绝")
                       isGet_UserNotification = 0
                   }
               }
    }
    
    // MARK: - 相机权限
    static func checkCameraPermission() {
        let authorizationStatus = AVCaptureDevice.authorizationStatus(for: .video)
        switch authorizationStatus {
        case .authorized:
            //                        print("相机权限已授权")
            isGet_Camera = 1
            break
        case .denied:
            //                        print("相机权限被拒绝")
            isGet_Camera = 0
            break
        case .restricted:
            //                        print("相机权限被限制（例如：家长控制）")
            isGet_Camera = 0
            break
        case .notDetermined:
            //                        print("相机权限尚未确定，可以请求权限")
            isGet_Camera = 2
            break
        @unknown default:
            print("未知状态")
        }
    }
    
    // 请求相机权限
    static func requestCameraPermission() {
        AVCaptureDevice.requestAccess(for: .video) { granted in
            if granted {
                isGet_Camera = 1
                //                            print("相机权限请求成功")
            }
            else {
                isGet_Camera = 0
                //                            print("相机权限请求失败")
            }
        }
    }
    
    // MARK: - 相册权限
    static func checkPhotoPermission() {
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        switch status {
        case .notDetermined:
            isGet_Photo = 2
            break
        case .denied, .restricted:
            isGet_Photo = 0
            break
        case .authorized:
            isGet_Photo = 1
            break
        case .limited:
            isGet_Photo = 1
            break
        @unknown default:
            break
        }
    }
    
    static func requestPhotoPermission() {
        PHPhotoLibrary.requestAuthorization { status in
            switch status {
            case .authorized:
                isGet_Photo = 1
                break
            case .denied, .restricted:
//                print("未获得相册权限")
                isGet_Photo = 0
                break
            case .notDetermined:
                isGet_Photo = 2
                break
            case .limited:
                isGet_Photo = 1
                break
            @unknown default:
//                print("未知的权限状态")
                break
            }
        }
    }

}

