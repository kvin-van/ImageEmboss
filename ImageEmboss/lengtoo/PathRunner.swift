//
//  PathRunner.swift
//  iSnap
//
//  Created by kevin_wang on 2025/9/4.
//给闭环路径添加运动白线

import Foundation
import UIKit

// MARK: -  添加白线动画
//路径奔跑者
class PathRunner {
    private var displayLink: CADisplayLink?
    private var progress: CGFloat = 0
    private let duration: CFTimeInterval
    private let path: UIBezierPath
    private let runnerLayer: CAShapeLayer
    private let segmentLength: CGFloat
    private let pathLength: CGFloat //总长度
    private var startTime: CFTimeInterval?
    
    init(path: UIBezierPath,lineWidth: CGFloat = 5,segmentLengthRatio: CGFloat = 0.1,duration: CFTimeInterval = 10.0,hostLayer: CALayer) {
        
        self.path = path
        self.duration = duration
        
        // 计算路径总长度
        self.pathLength = path.approxLength()
        self.segmentLength = pathLength * segmentLengthRatio
        
        self.runnerLayer = CAShapeLayer()
        runnerLayer.name = "movingLineLayer"
        runnerLayer.strokeColor = UIColor.white.cgColor
        runnerLayer.fillColor = UIColor.clear.cgColor
        runnerLayer.lineWidth = lineWidth
        runnerLayer.lineCap = .round
        hostLayer.addSublayer(runnerLayer)
    }
    
    func start() {
        startTime = CACurrentMediaTime()
        displayLink = CADisplayLink(target: self, selector: #selector(update))
        displayLink?.add(to: .main, forMode: .common)
    }
    
    func stop() {
        displayLink?.invalidate()
        displayLink = nil
    }
    
    @objc private func update() {
        guard let startTime else { return }
        let elapsed = CACurrentMediaTime() - startTime
        //顺时针
//        let progress = CGFloat((elapsed.truncatingRemainder(dividingBy: duration)) / duration)
        //逆时针
        let rawProgress = CGFloat((elapsed.truncatingRemainder(dividingBy: duration)) / duration) // 先算出顺时针的进度
        let progress = 1.0 - rawProgress // // 反转成逆时针
        
        let startDistance = progress * pathLength
        let endDistance = startDistance + segmentLength

        let subPath = UIBezierPath()
        if endDistance <= pathLength { //正常情况
            subPath.append(path.subPath(from: startDistance, to: endDistance))
        } else {
            // 跨越了闭环
            let part1 = path.subPath(from: startDistance, to: pathLength)
            let part2 = path.subPath(from: 0, to: endDistance - pathLength)
            subPath.append(part1)
            subPath.append(part2)
        }

        runnerLayer.path = subPath.cgPath
    }

}

extension UIBezierPath {
    /// 粗略计算长度（离散化）
    func approxLength(stepsPerCurve: Int = 30) -> CGFloat {
        var length: CGFloat = 0
        var lastPoint: CGPoint = .zero
        var hasPoint = false
        
        cgPath.applyWithBlock { elementPtr in
            let e = elementPtr.pointee
            switch e.type {
            case .moveToPoint:
                lastPoint = e.points[0]
                hasPoint = true
            case .addLineToPoint:
                if hasPoint {
                    let p = e.points[0]
                    length += hypot(p.x - lastPoint.x, p.y - lastPoint.y)
                    lastPoint = p
                }
            default:
                break // 简化：可以扩展二次/三次贝塞尔
            }
        }
        return length
    }
    
    /// 从路径中截取 [startDist, endDist] 段，返回 UIBezierPath
    func subPath(from start: CGFloat, to end: CGFloat) -> UIBezierPath {
        let sub = UIBezierPath()
        var dist: CGFloat = 0
        var lastPoint: CGPoint = .zero
        var hasPoint = false
        
        cgPath.applyWithBlock { elementPtr in
            let e = elementPtr.pointee
            switch e.type {
            case .moveToPoint:
                lastPoint = e.points[0]
                hasPoint = true
            case .addLineToPoint:
                if hasPoint {
                    let p = e.points[0]
                    let segLen = hypot(p.x - lastPoint.x, p.y - lastPoint.y)
                    let nextDist = dist + segLen
                    if nextDist >= start && dist <= end {
                        let t0 = max(0, (start - dist) / segLen)
                        let t1 = min(1, (end - dist) / segLen)
                        let s = CGPoint(x: lastPoint.x + (p.x - lastPoint.x) * t0,
                                        y: lastPoint.y + (p.y - lastPoint.y) * t0)
                        let e = CGPoint(x: lastPoint.x + (p.x - lastPoint.x) * t1,
                                        y: lastPoint.y + (p.y - lastPoint.y) * t1)
                        sub.move(to: s)
                        sub.addLine(to: e)
                    }
                    dist = nextDist
                    lastPoint = p
                }
            default:
                break
            }
        }
        return sub
    }
}
