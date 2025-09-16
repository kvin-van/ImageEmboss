//
//  ImageAnalysisMG.swift
//  AiBoKe
//
//  Created by kevin_wang on 2025/7/17.
//苹果相册 高亮闪动 抠图

import Foundation
import UIKit
import VisionKit

@MainActor
class ImageAnalysisMG: NSObject {
    var _callBack:((_ img : UIImage) -> Void)? = nil
    
    var rectArr : [CGRect] = []
  
    private let analyzer = ImageAnalyzer()
    let interaction = ImageAnalysisInteraction()
    var detectedObjects: Set<ImageAnalysisInteraction.Subject> = [] //发现的对象

    override init() {
        super.init()
//        interaction.allowLongPressForDataDetectorsInTextMode = true
        interaction.preferredInteractionTypes = [.imageSubject]
//        interaction.preferredInteractionTypes = [.automatic]
        
    }
    
    //分析图片
    func analyzerImg(readImg:UIImage,completion : @escaping ((Bool) -> Void)){
        self.detectedObjects.removeAll()
        self.rectArr.removeAll()
        Task { @MainActor in
            do {
                self.detectedObjects = try await self.analyzeImage(readImg)
//                try await Task.sleep(nanoseconds: 2_000_000_000) // 添加 2 秒延迟（单位：纳秒）
                completion(!self.detectedObjects.isEmpty)
            } catch {
                print("图像分析失败:: \(error.localizedDescription)")
                completion(false)
            }
        }
    }
    
    // MARK: - center
    func analyzeImage(_ image: UIImage) async throws -> Set<ImageAnalysisInteraction.Subject> {
        // 配置分析选项
        let configuration = ImageAnalyzer.Configuration([.visualLookUp])
        let analysis = try await analyzer.analyze(image, configuration: configuration)
        interaction.analysis = analysis
        let detectedSubjects = await interaction.subjects
        return detectedSubjects
    }
    
    //为选定对象生成图像
    func generateImageForSelectedObjects(){
        Task { @MainActor in
            print("主体个数\(self.detectedObjects.count)")
            for item in self.detectedObjects{
                print("Position: x \(item.bounds.origin.x) y \(item.bounds.origin.y)")
                print("Size: width \(item.bounds.width) height \(item.bounds.height)")
                self.rectArr.append(item.bounds)
                self.interaction.highlightedSubjects.insert(item)//添加高亮后 好像不需要赋值image
            }
       
//            if self.detectedObjects.count > 0{
//                let backImage = try await self.detectedObjects.first!.image
//                _callBack?(backImage)
//                let subject = self.detectedObjects.first!
//                self.interaction.highlightedSubjects.insert(subject)
//            }
            //异步提供一个图像，删除背景的image
//            let allSubjectsImage = try await self.interaction.image(for: self.interaction.highlightedSubjects)
//            _callBack?(allSubjectsImage)
        }
    }
    

}
