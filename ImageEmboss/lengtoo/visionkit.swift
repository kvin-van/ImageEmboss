//
//  visionkit.swift
//  lengtoo
//
//  Created by kevin_wang on 2025/7/29.
//
import UIKit


/*
/// 一个扫描相机实时视频中文本、文本数据和机器可读码的对象
///
/// 使用 `DataScannerViewController` 对象获取相机实时视频中出现的物理对象（如包裹上的印刷文本和二维码）的输入。
///
/// 通过向初始化方法 ``DataScannerViewController/init(recognizedDataTypes:qualityLevel:recognizesMultipleItems:isHighFrameRateTrackingEnabled:isPinchToZoomEnabled:isGuidanceEnabled:isHighlightingEnabled:)`` 传递配置界面的参数来创建数据扫描器。然后将其委托设置为应用中实现 ``DataScannerViewControllerDelegate`` 协议的对象。
///
/// 在呈现视图控制器之前，使用 ``DataScannerViewController/isSupported`` 和 ``DataScannerViewController/isAvailable`` 属性检查数据扫描器是否可用。在使用数据扫描器之前，必须提供使用相机的理由（在信息属性列表中添加 <doc://com.apple.documentation/documentation/bundleresources/information_property_list/nscamerausagedescription> 键），并且用户需在系统对话框首次出现时同意。
///
/// 然后通过调用 ``DataScannerViewController/startScanning()`` 方法开始数据扫描，并实现 ``DataScannerViewControllerDelegate/dataScanner(_:didTapOn:)-4z7ql`` 及类似的委托方法来处理用户操作。使用传递给这些方法的 ``RecognizedItem`` 参数执行特定于数据的操作。例如，如果项目是二维码，则使用其有效载荷字符串执行操作，如在浏览器中打开 URL 或拨打电话号码。
///
/// 或者，您可以使用异步的 ``DataScannerViewController/recognizedItems`` 数组跟踪实时视频中出现的项目。
@available(iOS 16.0, *)
@available(macCatalyst, unavailable)
@MainActor @objc public class DataScannerViewController : UIViewController {

    /// 扫描器识别的数据类型
    public struct RecognizedDataType : Hashable {

        /// 创建用于文本和扫描器在文本中查找信息的数据类型
        ///
        /// 使用此方法创建自定义文本数据类型。例如，如果您知道内容包含用户首选语言之外的其他语言，请将那些语言的标识符作为 `languages` 参数传递。如果只想扫描电话号码，请传递 ``DataScannerViewController/TextContentType/telephoneNumber`` 作为 `textContentType` 参数。
        ///
        /// 要获取数据扫描器支持的语言，请使用 ``DataScannerViewController/supportedTextRecognitionLanguages`` 属性。
        ///
        /// - 参数 languages: 按语言处理顺序指定的语言标识符。要指定用户的首选语言，请传递空集合。此参数提示扫描器使用哪些语言处理模型。扫描器仍会识别所有支持的语言。
        /// - 参数 textContentType: 要查找的特定语义文本类型。要识别所有内容类型，请传递 `nil`。
        ///
        /// - 返回: 文本数据类型
        public static func text(languages: [String] = [], textContentType: DataScannerViewController.TextContentType? = nil) -> DataScannerViewController.RecognizedDataType

        /// 创建用于指定符号体系的条形码数据类型
        ///
        /// - 参数 symbologies: 扫描器识别的条形码符号体系
        ///
        /// - 返回: 指定符号体系的条形码数据类型
        public static func barcode(symbologies: [VNBarcodeSymbology] = []) -> DataScannerViewController.RecognizedDataType

        /// 返回布尔值，指示两个集合是否具有相同元素
        ///
        /// - 参数 lhs: 要比较的值
        /// - 参数 rhs: 另一个要比较的值
        ///
        /// - 返回: 如果相等则为 `true`；否则为 `false`
        public static func == (lhs: DataScannerViewController.RecognizedDataType, rhs: DataScannerViewController.RecognizedDataType) -> Bool

        /// 使用指定的哈希器哈希此值的组件
        ///
        /// - 参数 hasher: 组合组件时使用的哈希器
        public func hash(into hasher: inout Hasher)

        /// 哈希值
        ///
        /// 哈希值在不同程序执行中不保证相同。请勿保存哈希值用于未来执行。
        ///
        /// - 重要: `hashValue` 作为 `Hashable` 要求已被弃用。要实现 `Hashable`，请改为实现 `hash(into:)` 要求。编译器会为您提供 `hashValue` 的实现。
        public var hashValue: Int { get }
    }

    /// 扫描器用于查找数据时可能使用的质量级别
    ///
    /// 质量级别主要影响相机分辨率。
    public enum QualityLevel : Sendable {

        /// 介于快速和准确之间的质量级别
        case balanced

        /// 优先识别速度而非准确性的质量级别
        ///
        /// 此质量级别可能无法识别较小的文本和条形码。
        case fast

        /// 优先识别准确性而非速度的质量级别
        ///
        /// 若需识别较小的文本和条形码，请使用此质量级别。
        case accurate

        /// 返回布尔值，指示两个值是否相等
        ///
        /// 相等是不等式的反义。对于任何值 `a` 和 `b`，`a == b` 意味着 `a != b` 为 `false`。
        ///
        /// - 参数 lhs: 要比较的值
        /// - 参数 rhs: 另一个要比较的值
        public static func == (a: DataScannerViewController.QualityLevel, b: DataScannerViewController.QualityLevel) -> Bool

        /// 通过将基本组件馈入给定哈希器来哈希值
        ///
        /// 实现此方法以符合 `Hashable` 协议。用于哈希的组件必须与类型 `==` 运算符实现中比较的组件相同。使用 `hasher.combine(_:)` 组合每个组件。
        ///
        /// - 重要: 在 `hash(into:)` 的实现中，请勿在提供的 `hasher` 实例上调用 `finalize()` 或用不同实例替换它。否则可能在将来成为编译时错误。
        ///
        /// - 参数 hasher: 组合此实例组件时使用的哈希器
        public func hash(into hasher: inout Hasher)

        /// 哈希值
        ///
        /// 哈希值在不同程序执行中不保证相同。请勿保存哈希值用于未来执行。
        ///
        /// - 重要: `hashValue` 作为 `Hashable` 要求已被弃用。要实现 `Hashable`，请改为实现 `hash(into:)` 要求。编译器会为您提供 `hashValue` 的实现。
        public var hashValue: Int { get }
    }

    /// 数据扫描器识别的文本类型
    ///
    /// 配置 ``VisionKit/DataScannerViewController`` 时，向其初始化方法传递一个或多个选项。例如，以下代码创建检测货币文本引用的数据扫描器：
    ///
    /// ```swift
    /// let recognizedDataTypes:Set<DataScannerViewController.RecognizedDataType> = [
    ///     .text(textContentType: .currency)
    /// ]
    ///
    /// // 创建数据扫描器
    /// let dataScanner = DataScannerViewController(recognizedDataTypes: recognizedDataTypes)
    /// ```
    public enum TextContentType : Sendable {

        /// 文本中出现的日期、时间和持续时间的内容类型
        ///
        /// 用于日期（如 `2021-7-3`）、时间（如 `本周六` 和 `12:30`）及持续时间（如 `上午10-11点`）。
        case dateTimeDuration

        /// 文本中出现的电子邮件地址内容类型
        case emailAddress

        /// 文本中出现的供应商特定航班号内容类型
        case flightNumber

        /// 文本中出现的邮寄地址内容类型
        case fullStreetAddress

        /// 文本中出现的供应商特定包裹追踪号内容类型
        case shipmentTrackingNumber

        /// 文本中出现的电话号码内容类型
        case telephoneNumber

        /// 文本中出现的 URL 内容类型
        case URL

        /// 货币内容类型
        @available(iOS 17.0, *)
        case currency

        /// 返回布尔值，指示两个值是否相等
        ///
        /// - 参数 lhs: 要比较的值
        /// - 参数 rhs: 另一个要比较的值
        public static func == (a: DataScannerViewController.TextContentType, b: DataScannerViewController.TextContentType) -> Bool

        /// 通过将基本组件馈入给定哈希器来哈希值
        ///
        /// 实现此方法以符合 `Hashable` 协议。用于哈希的组件必须与类型 `==` 运算符实现中比较的组件相同。使用 `hasher.combine(_:)` 组合每个组件。
        ///
        /// - 重要: 在 `hash(into:)` 的实现中，请勿在提供的 `hasher` 实例上调用 `finalize()` 或用不同实例替换它。否则可能在将来成为编译时错误。
        ///
        /// - 参数 hasher: 组合此实例组件时使用的哈希器
        public func hash(into hasher: inout Hasher)

        /// 哈希值
        ///
        /// 哈希值在不同程序执行中不保证相同。请勿保存哈希值用于未来执行。
        ///
        /// - 重要: `hashValue` 作为 `Hashable` 要求已被弃用。要实现 `Hashable`，请改为实现 `hash(into:)` 要求。编译器会为您提供 `hashValue` 的实现。
        public var hashValue: Int { get }
    }

    /// 数据扫描器不可用的可能原因
    public enum ScanningUnavailable : Error {

        /// 此设备不支持数据扫描器
        ///
        /// 设备必须配备神经引擎才能执行数据扫描。
        case unsupported

        /// 由于用户对相机使用的限制，数据扫描器不可用
        case cameraRestricted

        /// 返回布尔值，指示两个值是否相等
        ///
        /// - 参数 lhs: 要比较的值
        /// - 参数 rhs: 另一个要比较的值
        public static func == (a: DataScannerViewController.ScanningUnavailable, b: DataScannerViewController.ScanningUnavailable) -> Bool

        /// 通过将基本组件馈入给定哈希器来哈希值
        ///
        /// 实现此方法以符合 `Hashable` 协议。用于哈希的组件必须与类型 `==` 运算符实现中比较的组件相同。使用 `hasher.combine(_:)` 组合每个组件。
        ///
        /// - 重要: 在 `hash(into:)` 的实现中，请勿在提供的 `hasher` 实例上调用 `finalize()` 或用不同实例替换它。否则可能在将来成为编译时错误。
        ///
        /// - 参数 hasher: 组合此实例组件时使用的哈希器
        public func hash(into hasher: inout Hasher)

        /// 哈希值
        ///
        /// 哈希值在不同程序执行中不保证相同。请勿保存哈希值用于未来执行。
        ///
        /// - 重要: `hashValue` 作为 `Hashable` 要求已被弃用。要实现 `Hashable`，请改为实现 `hash(into:)` 要求。编译器会为您提供 `hashValue` 的实现。
        public var hashValue: Int { get }
    }

    /// 指示设备是否支持数据扫描的布尔值
    ///
    /// 此属性为 `true` 的条件：设备必须配备 A12 仿生芯片或更高版本。在 visionOS 中运行的应用程序此属性为 `false`。
    ///
    /// - 重要: 如果应用的核心功能需要数据扫描，可以使应用仅在支持数据扫描的设备上可用。在应用的信息属性列表中添加 <doc://com.apple.documentation/documentation/bundleresources/information_property_list/uirequireddevicecapabilities> 键，并在设备功能数组中包含 `iphone-ipad-minimum-performance-a12` 子键。
    @MainActor public class var isSupported: Bool { get }

    /// 指示用户是否授权应用访问相机且无使用限制的布尔值
    ///
    /// 例如，如果用户有屏幕时间限制，此属性可能为 `false`。
    @MainActor public class var isAvailable: Bool { get }

    /// 数据扫描器识别的语言标识符
    @MainActor public class var supportedTextRecognitionLanguages: [String] { get }

    /// 处理用户与数据扫描器识别项目交互的委托
    @MainActor weak public var delegate: (any DataScannerViewControllerDelegate)?

    /// 数据扫描器在其视图上方显示且不干扰实时文本界面的视图
    ///
    /// 可选地，在此视图中添加不影响点击测试或引导对象的自定义高亮。如果要在高亮上方添加界面对象，请将这些对象添加为 <doc://com.apple.documentation/documentation/uikit/uiviewcontroller/1621460-view> 属性的子视图。
    @MainActor public var overlayContainerView: UIView { get }

    /// 数据扫描器在实时视频中识别的数据类型
    @MainActor final public let recognizedDataTypes: Set<DataScannerViewController.RecognizedDataType>

    /// 扫描器用于查找数据的分辨率
    ///
    /// 默认值为 ``DataScannerViewController/QualityLevel-swift.enum/balanced``。要提高较大项目的识别速度，可将此属性设置为 ``DataScannerViewController/QualityLevel-swift.enum/fast``。对于较小项目，可设置为 ``DataScannerViewController/QualityLevel-swift.enum/accurate``，但可能影响识别速度。
    @MainActor final public let qualityLevel: DataScannerViewController.QualityLevel

    /// 指示扫描器是否应识别实时视频中所有项目的布尔值
    ///
    /// 若为 `true`，扫描器查找实时视频中所有项目。若为 `false`，扫描器仅查找最接近用户兴趣点的项目。兴趣点默认为视图中心或用户在实时视频中点击的位置。默认值为 `false`。
    @MainActor final public let recognizesMultipleItems: Bool

    /// 指示扫描器更新识别项目几何结构频率的布尔值
    ///
    /// 若为 `true`，扫描器更频繁地更新项目几何结构，允许应用紧密跟踪识别项目。如果未在实时视频中跟踪项目，请将此属性设置为 `false`。默认值为 `true`。
    @MainActor final public let isHighFrameRateTrackingEnabled: Bool

    /// 指示用户是否可使用双指捏合缩放手势的布尔值
    ///
    /// 默认值为 `true`。
    @MainActor final public let isPinchToZoomEnabled: Bool

    /// 指示扫描器在选择项目时是否提供帮助的布尔值
    ///
    /// 引导文本（如“放慢速度”）会显示在实时视频上方。此属性的默认值为 `true`。
    @MainActor final public let isGuidanceEnabled: Bool

    /// 指示扫描器是否在识别项目周围显示高亮的布尔值
    ///
    /// 默认值为 `false`。
    @MainActor final public let isHighlightingEnabled: Bool

    /// 数据扫描器在视图坐标系中搜索项目的实时视频区域
    ///
    /// 如果向实时视频添加可能对用户隐藏项目的界面对象（使用 ``DataScannerViewController/overlayContainerView`` 属性），请设置此属性以限制扫描区域。默认值为视图的边界。
    @MainActor public var regionOfInterest: CGRect?

    /// 指示数据扫描器是否正在主动查找项目的布尔值
    @MainActor public var isScanning: Bool { get }

    /// 数据扫描器当前在相机实时视频中识别项目的异步数组
    ///
    /// 您可以使用此属性代替 ``DataScannerViewControllerDelegate`` 协议方法实时跟踪识别项目。要获取数组之间的变化，请使用 <doc://com.apple.documentation/documentation/swift/array/difference(from:)> 方法。有关异步流的更多信息，请参阅 <doc://com.apple.documentation/documentation/swift/concurrency>。
    ///
    /// 此数组中的文本项目按语言和地区的阅读顺序出现。
    @MainActor public var recognizedItems: AsyncStream<[RecognizedItem]> { get }

    /// 相机支持的最小缩放因子
    @MainActor public var minZoomFactor: Double { get }

    /// 相机支持的最大缩放因子
    @MainActor public var maxZoomFactor: Double { get }

    /// 相机实时视频的缩放因子
    ///
    /// 将此属性设置为介于 ``DataScannerViewController/minZoomFactor`` 和 ``DataScannerViewController/maxZoomFactor`` 属性之间的值。
    @MainActor public var zoomFactor: Double

    /// 创建用于在相机实时视频中查找数据（如文本和机器可读码）的扫描器
    ///
    /// - 参数 recognizedDataTypes: 数据扫描器在实时视频中识别的数据类型
    /// - 参数 qualityLevel: 取决于项目大小的扫描分辨率级别
    /// - 参数 recognizesMultipleItems: 指示扫描器是否识别实时视频中所有项目的布尔值
    /// - 参数 isHighFrameRateTrackingEnabled: 指示扫描器更新识别项目几何结构频率的布尔值
    /// - 参数 isPinchToZoomEnabled: 指示用户是否可使用双指捏合缩放手势的布尔值
    /// - 参数 isGuidanceEnabled: 指示扫描器在选择项目时是否提供帮助的布尔值
    /// - 参数 isHighlightingEnabled: 指示扫描器是否在识别项目周围显示高亮的布尔值
    @MainActor public init(recognizedDataTypes: Set<DataScannerViewController.RecognizedDataType>, qualityLevel: DataScannerViewController.QualityLevel = .balanced, recognizesMultipleItems: Bool = false, isHighFrameRateTrackingEnabled: Bool = true, isPinchToZoomEnabled: Bool = true, isGuidanceEnabled: Bool = true, isHighlightingEnabled: Bool = false)

    /// 创建控制器管理的视图
    @MainActor override dynamic public func loadView()

    /// 系统将视图加载到内存后执行某些操作
    @MainActor override dynamic public func viewDidLoad()

    /// 视图出现前执行某些操作
    ///
    /// - 参数 animated: 指示视图是否以动画形式出现的布尔值
    @MainActor override dynamic public func viewWillAppear(_ animated: Bool)

    /// 视图消失后执行某些操作
    ///
    /// - 参数 animated: 指示视图是否以动画形式消失的布尔值
    @MainActor override dynamic public func viewDidDisappear(_ animated: Bool)

    @MainActor override dynamic public func removeFromParent()

    /// 捕获相机实时视频的高分辨率照片
    ///
    /// - 返回: 实时视频的图像
    @MainActor public func capturePhoto() async throws -> UIImage

    /// 开始扫描相机实时视频中的数据
    @MainActor public func startScanning() throws

    /// 停止扫描相机实时视频中的数据
    ///
    /// 此方法从 ``DataScannerViewController/recognizedItems`` 属性中移除所有项目。
    @MainActor public func stopScanning()
}

@available(iOS 16.0, *)
@available(macCatalyst, unavailable)
extension DataScannerViewController.QualityLevel : Equatable {
}

@available(iOS 16.0, *)
@available(macCatalyst, unavailable)
extension DataScannerViewController.QualityLevel : Hashable {
}

@available(iOS 16.0, *)
@available(macCatalyst, unavailable)
extension DataScannerViewController.TextContentType : Equatable {
}

@available(iOS 16.0, *)
@available(macCatalyst, unavailable)
extension DataScannerViewController.TextContentType : Hashable {
}

@available(iOS 16.0, *)
@available(macCatalyst, unavailable)
extension DataScannerViewController.ScanningUnavailable : Equatable {
}

@available(iOS 16.0, *)
@available(macCatalyst, unavailable)
extension DataScannerViewController.ScanningUnavailable : Hashable {
}

/// 处理用户与数据扫描器识别项目交互的委托对象
///
/// 实现此协议以处理用户点击识别项目的情况，并可选地在数据扫描器更新识别项目时提供额外反馈。
@available(iOS 16.0, *)
@available(macCatalyst, unavailable)
@MainActor public protocol DataScannerViewControllerDelegate : AnyObject {

    /// 当用户或您的代码更改缩放因子时响应
    ///
    /// 当 ``DataScannerViewController/zoomFactor`` 属性更改时，数据扫描器调用此方法。
    ///
    /// - 参数 dataScanner: 缩放因子更改的数据扫描器
    @MainActor func dataScannerDidZoom(_ dataScanner: DataScannerViewController)

    /// 当用户点击数据扫描器识别的项目时响应
    ///
    /// 实现此方法以根据用户点击的数据类型执行操作。
    ///
    /// - 参数 dataScanner: 缩放因子更改的数据扫描器
    /// - 参数 item: 用户点击的项目
    @MainActor func dataScanner(_ dataScanner: DataScannerViewController, didTapOn item: RecognizedItem)

    /// 当数据扫描器开始识别项目时响应
    ///
    /// 要识别 `addedItems` 和 `allItems` 参数中的项目，请使用项目的 `id` 属性。
    ///
    /// - 参数 dataScanner: 识别项目的数据扫描器
    /// - 参数 addedItems: 数据扫描器开始跟踪的项目
    /// - 参数 allItems: 数据扫描器当前跟踪的项目。文本项目按语言和地区的阅读顺序出现。
    @MainActor func dataScanner(_ dataScanner: DataScannerViewController, didAdd addedItems: [RecognizedItem], allItems: [RecognizedItem])

    /// 当数据扫描器更新其识别项目的几何结构时响应
    ///
    /// 要识别 `updatedItems` 和 `allItems` 参数中的项目，请使用项目的 `id` 属性。
    ///
    /// - 参数 dataScanner: 识别项目的数据扫描器
    /// - 参数 updatedItems: 几何结构被数据扫描器更改的项目
    /// - 参数 allItems: 数据扫描器当前跟踪的项目。文本项目按语言和地区的阅读顺序出现。
    @MainActor func dataScanner(_ dataScanner: DataScannerViewController, didUpdate updatedItems: [RecognizedItem], allItems: [RecognizedItem])

    /// 当数据扫描器停止识别项目时响应
    ///
    /// 要识别 `removedItems` 和 `allItems` 参数中的项目，请使用项目的 `id` 属性。
    ///
    /// - 参数 dataScanner: 识别项目的数据扫描器
    /// - 参数 removedItems: 数据扫描器从 ``DataScannerViewController/recognizedItems`` 属性中移除的项目
    /// - 参数 allItems: 数据扫描器当前跟踪的项目。文本项目按语言和地区的阅读顺序出现。
    @MainActor func dataScanner(_ dataScanner: DataScannerViewController, didRemove removedItems: [RecognizedItem], allItems: [RecognizedItem])

    /// 当数据扫描器不可用并停止扫描时响应
    ///
    /// - 参数 dataScanner: 不可用的数据扫描器
    /// - 参数 error: 错误描述（如果发生）
    @MainActor func dataScanner(_ dataScanner: DataScannerViewController, becameUnavailableWithError error: DataScannerViewController.ScanningUnavailable)
}

/// 默认实现
@available(iOS 16.0, *)
@available(macCatalyst, unavailable)
extension DataScannerViewControllerDelegate {

    /// 用户或代码更改缩放因子时的默认空实现
    ///
    /// - 参数 dataScanner: 缩放因子更改的数据扫描器
    @MainActor public func dataScannerDidZoom(_ dataScanner: DataScannerViewController)

    /// 用户点击数据扫描器识别项目时的默认空实现
    ///
    /// - 参数 dataScanner: 缩放因子更改的数据扫描器
    /// - 参数 item: 用户点击的项目
    @MainActor public func dataScanner(_ dataScanner: DataScannerViewController, didTapOn item: RecognizedItem)

    /// 数据扫描器开始识别项目时的默认空实现
    ///
    /// - 参数 dataScanner: 识别项目的数据扫描器
    /// - 参数 addedItems: 数据扫描器开始跟踪的项目
    /// - 参数 allItems: 数据扫描器当前跟踪的项目。文本项目按语言和地区的阅读顺序出现。
    @MainActor public func dataScanner(_ dataScanner: DataScannerViewController, didAdd addedItems: [RecognizedItem], allItems: [RecognizedItem])

    /// 数据扫描器更新识别项目几何结构时的默认空实现
    ///
    /// - 参数 dataScanner: 识别项目的数据扫描器
    /// - 参数 updatedItems: 几何结构被数据扫描器更改的项目
    /// - 参数 allItems: 数据扫描器当前跟踪的项目。文本项目按语言和地区的阅读顺序出现。
    @MainActor public func dataScanner(_ dataScanner: DataScannerViewController, didUpdate updatedItems: [RecognizedItem], allItems: [RecognizedItem])

    /// 数据扫描器停止识别项目时的默认空实现
    ///
    /// - 参数 dataScanner: 识别项目的数据扫描器
    /// - 参数 removedItems: 数据扫描器从 ``DataScannerViewController/recognizedItems`` 属性中移除的项目
    /// - 参数 allItems: 数据扫描器当前跟踪的项目。文本项目按语言和地区的阅读顺序出现。
    @MainActor public func dataScanner(_ dataScanner: DataScannerViewController, didRemove removedItems: [RecognizedItem], allItems: [RecognizedItem])

    /// 数据扫描器不可用并停止扫描时的默认空实现
    ///
    /// - 参数 dataScanner: 不可用的数据扫描器
    /// - 参数 error: 错误描述（如果发生）
    @MainActor public func dataScanner(_ dataScanner: DataScannerViewController, becameUnavailableWithError error: DataScannerViewController.ScanningUnavailable)
}

/// 表示图像分析结果并为实时文本界面对象提供输入的对象
///
/// `ImageAnalysis` 对象表示 ``ImageAnalyzer`` 对象在图像中查找用户可交互项目的结果。要创建 `ImageAnalysis` 对象，请使用 `ImageAnalyzer` 类的 ``ImageAnalyzer/analyze(_:configuration:)`` 方法，传递图像和指定要查找项目的 ``ImageAnalyzer/Configuration`` 对象。然后将图像分析传递给 iOS 的 ``ImageAnalysisInteraction`` 对象或 macOS 的 ``ImageAnalysisOverlayView`` 对象以提供实时文本界面。
@available(iOS 16.0, macOS 13.0, macCatalyst 17.0, *)
final public class ImageAnalysis {

    /// 图像中文本项目表示的字符串
    ///
    /// 文本按语言和地区的阅读顺序出现。
    final public var transcript: String { get }

    /// 返回布尔值，指示分析是否在图像中找到指定类型
    ///
    /// - 参数 analysisTypes: 要在图像中查找的数据类型
    ///
    /// - 返回: 如果图像分析对指定类型有结果则为 `true`；否则为 `false`
    final public func hasResults(for analysisTypes: ImageAnalyzer.AnalysisTypes) -> Bool
}

/// 使用户能够与图像中识别的文本、条形码和其他对象交互的界面
///
/// 此类使用户能够与框架在图像中识别的特定内容类型（``ImageAnalysisInteraction/InteractionTypes``）交互。例如：
/// - 实时文本界面允许用户选择图像中的任何文本（``ImageAnalysisInteraction/InteractionTypes/textSelection``）或调用 URL（``ImageAnalysisInteraction/InteractionTypes/dataDetectors``）。文本选择 UI 提供框架标准按钮用于复制选定文本或在网上查找更多信息。
/// - *主体提取*功能通过 ``ImageAnalysisInteraction/InteractionTypes/imageSubject`` 交互类型识别图像中的各种对象或*主体*，并为应用提供背景移除后的主体图像。``ImageAnalysisInteraction/InteractionTypes/visualLookUp`` 类型通过添加视图右下角的按钮补充此功能，用户可点击获取有关识别主体的更多信息。
///
/// ## 配置界面并开始交互
///
/// 此类符合 <doc://com.apple.documentation/documentation/uikit/uiinteraction> 协议。要将界面与应用显示的图像连接，在应用的图像视图上调用 <doc://com.apple.documentation/documentation/uikit/uiview/2891013-addinteraction> 并传递此类的新实例。
///
/// 通过配置 ``ImageAnalysisInteraction/preferredInteractionTypes`` 属性选择框架在图像中识别的项目。要识别所有类型的内容，请指定 ``ImageAnalysisInteraction/InteractionTypes/automatic`` 选项，或通过分配数组选择类型组合：
///
/// ```swift
/// interaction.preferredInteractionTypes = [.textSelection, .imageSubject]
/// ```
/// 要开始交互，请调用 ``ImageAnalyzer`` 类的某个 `analyze` 方法（如 ``ImageAnalyzer/analyze(_:configuration:)``），并将结果设置到此类 ``ImageAnalysisOverlayView/analysis`` 属性。
///
/// 您可以通过实现委托（``ImageAnalysisInteractionDelegate``）并将其分配给 ``ImageAnalysisInteraction/delegate`` 属性来更好地控制交互或提供应用图像视图的详细信息。如果图像视图不是 <doc://com.apple.documentation/documentation/uikit/uiimageview> 的实例，应用需要通过实现 ``ImageAnalysisInteractionDelegate/contentsRect(for:)-187x`` 方法定义图像内的交互区域。
@available(iOS 16.0, macCatalyst 17.0, *)
@MainActor @objc final public class ImageAnalysisInteraction : NSObject, UIInteraction {

    /// 使用此交互的视图
    @MainActor @preconcurrency weak final public var view: UIView? { get }

    /// 用户可与图像进行的交互类型
    public struct InteractionTypes : OptionSet {

        /// 原始类型的对应值
        public var rawValue: UInt

        /// 从原始类型创建实例
        ///
        /// - 参数 rawValue: 原始类型的对应值
        public init(rawValue: UInt)

        /// 启用与框架识别的任何文本、符号或主体的交互
        ///
        /// 用户可以选择文本执行操作，点击实时文本按钮后可与数据检测器交互。如果 ``ImageAnalysisInteraction/allowLongPressForDataDetectorsInTextMode`` 属性为 `true`，用户无需点击实时文本按钮，长按文本即可激活数据检测器。
        public static let automatic: ImageAnalysisInteraction.InteractionTypes

        /// 启用除图像主体和视觉查找外的所有交互类型
        ///
        /// 此选项表示 ``VisionKit/ImageAnalysisInteraction/InteractionTypes/automatic`` 类型，但排除 ``VisionKit/ImageAnalysisInteraction/InteractionTypes/imageSubject`` 和 ``VisionKit/ImageAnalysisInteraction/InteractionTypes/visualLookUp`` 类型。
        public static let automaticTextOnly: ImageAnalysisInteraction.InteractionTypes

        /// 启用文本选择、复制和翻译
        ///
        /// 用户可以选择文本执行操作。在此模式下，框架默认禁用数据检测器（``VisionKit/ImageAnalysisInteraction/InteractionTypes/dataDetectors``）。但如果将 ``ImageAnalysisInteraction/allowLongPressForDataDetectorsInTextMode`` 属性设为 `true`，用户可使用长按手势启用它们。
        public static let textSelection: ImageAnalysisInteraction.InteractionTypes

        /// 启用与特定格式文本（如 URL、电子邮件地址和物理地址）的交互
        ///
        /// 用户与*数据检测器*交互，即高亮图像文本中识别格式实例的 UI。数据检测器出现时没有实时文本按钮，因为用户无法使用此选项与其他文本交互。
        public static let dataDetectors: ImageAnalysisInteraction.InteractionTypes

        /// 使用户能长按图像中的主体将其从背景中分离
        ///
        /// 有关图像主体的更多信息，请参阅 ``VisionKit/ImageAnalysisInteraction/Subject``。
        public static let imageSubject: ImageAnalysisInteraction.InteractionTypes

        /// 显示按钮以获取有关框架在图像中识别主体的更多信息
        ///
        /// 当框架识别出图像中可提供更多信息的熟悉内容时（参见 ``ImageAnalysisInteraction/Subject``），它会在视图右下角提供一个按钮。用户点击按钮后，会出现一个模态表单，提供有关主体的信息。例如，如果图像包含一只狗，模态表单会描述狗的品种并提供相关网页 URL 供用户阅读更多关于该品种的信息。
        ///
        /// 当框架识别以下主体时，VisionKit 支持视觉查找：
        /// - 植物和花卉
        /// - 动物，如猫、狗、鸟、爬行动物和昆虫
        /// - 地点，如建筑地标、雕塑和自然地标
        /// - 艺术和媒体，如绘画、书籍和专辑封面
        /// - 食物，如预制菜肴和甜点
        /// - 符号，如洗衣护理标签和车辆仪表盘指示器
        public static let visualLookUp: ImageAnalysisInteraction.InteractionTypes

        /// 数组字面量的元素类型
        @available(iOS 16.0, macCatalyst 17.0, *)
        public typealias ArrayLiteralElement = ImageAnalysisInteraction.InteractionTypes

        /// 选项集的元素类型
        ///
        /// 要从 `OptionSet` 协议继承所有默认实现，`Element` 类型必须为 `Self`（默认）。
        @available(iOS 16.0, macCatalyst 17.0, *)
        public typealias Element = ImageAnalysisInteraction.InteractionTypes

        /// 可用于表示符合类型所有值的原始类型
        ///
        /// 符合类型的每个不同值都有 `RawValue` 类型的唯一对应值，但可能存在 `RawValue` 类型值没有符合类型对应值的情况。
        @available(iOS 16.0, macCatalyst 17.0, *)
        public typealias RawValue = UInt
    }

    /// 创建用于与图像中项目进行实时文本操作的交互
    @MainActor override dynamic public init()

    /// 处理交互回调的委托
    @MainActor weak final public var delegate: (any ImageAnalysisInteractionDelegate)?

    /// 使用指定委托创建实时文本操作的交互
    ///
    /// - 参数 delegate: 为交互提供界面详细信息的对象
    @MainActor public convenience init(_ delegate: any ImageAnalysisInteractionDelegate)

    /// 分析图像中用户可交互项目的结果
    @MainActor final public var analysis: ImageAnalysis?

    /// 在视图从其交互数组添加或移除交互前执行操作
    ///
    /// - 参数 view: 在其交互数组中拥有并包含交互的视图
    @MainActor @preconcurrency final public func willMove(to view: UIView?)

    /// 在视图从其交互数组添加或移除交互后执行操作
    ///
    /// - 参数 view: 在其交互数组中拥有并包含交互的视图
    @MainActor @preconcurrency final public func didMove(to view: UIView?)

    /// 用户可与图像进行的交互类型
    ///
    /// 需设置此属性以启用与图像的交互。如果此属性包含 ``ImageAnalysisInteraction/InteractionTypes/automatic``，则交互忽略集合中的其他类型。此属性的默认值为空数组，禁用所有交互。
    ///
    /// 如果将此属性设置为一种或多种类型，交互会将视图的 <doc://com.apple.documentation/documentation/uikit/uiview/1622577-isuserinteractionenabled> 属性设置为 `true` 以启动交互。例如，准备启动实时文本界面时，将此属性设置为 ``ImageAnalysisInteraction/InteractionTypes/automatic``。
    ///
    /// 如果将此属性设置为空数组，图像分析交互不会将视图的 `isUserInteractionEnabled` 属性重置为 `false`。
    @MainActor final public var preferredInteractionTypes: ImageAnalysisInteraction.InteractionTypes

    /// 用户主动进行的交互类型
    ///
    /// 此属性始终是具体类型，从不为 ``ImageAnalysisInteraction/InteractionTypes/automatic``。
    @MainActor final public var activeInteractionTypes: ImageAnalysisInteraction.InteractionTypes { get }

    /// 指示交互是否高亮分析器在文本中检测到的可操作文本或数据的布尔值
    ///
    /// 交互对象为您管理此属性值。如果设置 ``ImageAnalysisInteraction/analysis`` 属性或 ``ImageAnalysisInteraction/activeInteractionTypes`` 属性为空集合，则将此属性设置为 `false`。否则，它会根据用户在界面中是否切换实时文本按钮来设置此属性。
    @MainActor final public var selectableItemsHighlighted: Bool

    /// 指示用户是否可长按文本激活数据检测器的布尔值
    ///
    /// 当交互类型仅为文本时，如果将此属性设为 `true`，用户可长按文本中的数据，即使数据检测器未激活。否则，用户只能执行文本操作（如复制和翻译）。此属性的默认值为 `true`。
    @MainActor final public var allowLongPressForDataDetectorsInTextMode: Bool

    /// 指示用户或应用是否在图像中选择了文本的布尔值
    ///
    /// 如果 ``VisionKit/ImageAnalysisInteraction/InteractionTypes/textSelection`` 是活动交互类型，用户可使用标准输入方法选择文本，应用可通过 ``selectedRanges`` 属性选择文本。如果用户和应用均未选择文本，则此属性返回 `false`。
    @MainActor final public var hasActiveTextSelection: Bool { get }

    /// 从界面中移除用户的文本选择
    @MainActor final public func resetTextSelection()

    /// 当前图像分析的文本内容
    @available(iOS 17.0, *)
    @MainActor final public var text: String { get }

    /// 当前选定的文本
    @available(iOS 17.0, *)
    @MainActor final public var selectedText: String { get }

    /// 当前选定的属性文本
    @available(iOS 17.0, *)
    @MainActor final public var selectedAttributedText: AttributedString { get }

    /// 设置选定的文本范围
    @available(iOS 17.0, *)
    @MainActor final public var selectedRanges: [Range<String.Index>]

    /// 当布局更改且视图需要重新加载内容时，通知包含图像的视图
    ///
    /// 当应用将交互添加到 <doc://com.apple.documentation/documentation/uikit/uiimageview> 时，框架忽略此方法的调用，后者会根据图像视图的 <doc://com.apple.documentation/documentation/uikit/uiviewcontentmode> 计算 ``contentsRect``。
    ///
    /// 当包含图像的视图不是 <doc://com.apple.documentation/documentation/uikit/uiimageview> 的实例时，在布局更改时调用此方法。交互随后调用委托的 ``ImageAnalysisInteractionDelegate/contentsRect(for:)-187x`` 回调，向系统提供更新的内容区域。
    @MainActor final public func setContentsRectNeedsUpdate()

    /// 描述交互内容区域的矩形（单位坐标系）
    ///
    /// 如果交互的视图不是 <doc://com.apple.documentation/documentation/uikit/uiimageview> 的实例，应用通过实现 ``VisionKit/ImageAnalysisInteractionDelegate`` 回调 ``VisionKit/ImageAnalysisInteractionDelegate/contentsRect(for:)-187x`` 设置此属性的值。默认返回值为单位矩形 `[0.0, 0.0, 1.0, 1.0]`，表示整个视图内容。
    @MainActor final public var contentsRect: CGRect { get }

    /// 返回布尔值，指示活动文本、数据检测器或补充界面对象是否存在于指定点
    ///
    /// - 参数 point: 图像中的点（视图坐标系）
    ///
    /// - 返回: 如果活动文本、数据检测器或补充界面对象存在于 `point` 则为 `true`；否则为 `false`
    @MainActor final public func hasInteractiveItem(at point: CGPoint) -> Bool

    /// 返回布尔值，指示活动文本是否存在于指定点
    ///
    /// - 参数 point: 图像中的点（视图坐标系）
    ///
    /// - 返回: 如果活动文本存在于 `point` 则为 `true`；否则为 `false`
    @MainActor final public func hasText(at point: CGPoint) -> Bool

    /// 返回布尔值，指示分析是否在指定点检测到数据
    ///
    /// - 参数 point: 图像中的点（视图坐标系）
    ///
    /// - 返回: 如果分析器在 `point` 检测到数据则为 `true`；否则为 `false`
    @MainActor final public func hasDataDetector(at point: CGPoint) -> Bool

    /// 返回布尔值，指示补充界面对象是否存在于指定点
    ///
    /// 补充界面对象包括实时文本按钮和快捷操作（取决于项目类型）。
    ///
    /// - 参数 point: 图像中的点（视图坐标系）
    ///
    /// - 返回: 如果补充界面对象存在于 `point` 则为 `true`；否则为 `false`
    @MainActor final public func hasSupplementaryInterface(at point: CGPoint) -> Bool

    /// 返回布尔值，指示分析是否在指定点找到文本
    ///
    /// - 参数 point: 图像中的点（视图坐标系）
    ///
    /// - 返回: 如果文本存在于 `point` 则为 `true`；否则为 `false`
    @MainActor final public func analysisHasText(at point: CGPoint) -> Bool

    /// 指示实时文本按钮是否出现的布尔值
    ///
    /// 当用户点击实时文本按钮时，它会高亮图像中的识别项目。
    @MainActor final public var liveTextButtonVisible: Bool { get }

    /// 指示视图是否隐藏补充界面对象的布尔值
    ///
    /// 补充界面对象包括实时文本按钮和快捷操作（取决于项目类型）。设置此属性会调用 ``ImageAnalysisInteraction/setSupplementaryInterfaceHidden(_:animated:)`` 方法，传递此属性值和 `true` 给 `animated` 参数。
    @MainActor final public var isSupplementaryInterfaceHidden: Bool

    /// 隐藏或显示补充界面对象，如实时操作按钮和快捷操作（取决于项目类型）
    ///
    /// - 参数 hidden: `true` 隐藏补充界面；否则为 `false`
    /// - 参数 animated: `true` 以动画形式过渡界面；否则为 `false`
    @MainActor final public func setSupplementaryInterfaceHidden(_ hidden: Bool, animated: Bool)

    /// 内容边缘与补充界面的间距
    @MainActor final public var supplementaryInterfaceContentInsets: UIEdgeInsets

    /// 补充界面使用的字体
    ///
    /// 交互同时使用字体粗细表示图像符号，但忽略点大小以保持按钮大小一致。
    @MainActor final public var supplementaryInterfaceFont: UIFont?

    /// 主体分析期间可能发生的错误条件
    ///
    /// 此枚举包含当 ``VisionKit/ImageAnalysisInteraction/Subject`` 属性 ``VisionKit/ImageAnalysisInteraction/Subject/image`` 无法生成结果时可能发生的失败 ``VisionKit/ImageAnalysisInteraction/SubjectUnavailable/imageUnavailable``。
    @available(iOS 17.0, *)
    public enum SubjectUnavailable : Error {

        /// 表示主体无法生成图像的错
        case imageUnavailable

        /// 返回布尔值，指示两个值是否相等
        ///
        /// - 参数 lhs: 要比较的值
        /// - 参数 rhs: 另一个要比较的值
        public static func == (a: ImageAnalysisInteraction.SubjectUnavailable, b: ImageAnalysisInteraction.SubjectUnavailable) -> Bool

        /// 通过将基本组件馈入给定哈希器来哈希值
        ///
        /// 实现此方法以符合 `Hashable` 协议。用于哈希的组件必须与类型 `==` 运算符实现中比较的组件相同。使用 `hasher.combine(_:)` 组合每个组件。
        ///
        /// - 重要: 在 `hash(into:)` 的实现中，请勿在提供的 `hasher` 实例上调用 `finalize()` 或用不同实例替换它。否则可能在将来成为编译时错误。
        ///
        /// - 参数 hasher: 组合此实例组件时使用的哈希器
        public func hash(into hasher: inout Hasher)

        /// 哈希值
        ///
        /// 哈希值在不同程序执行中不保证相同。请勿保存哈希值用于未来执行。
        ///
        /// - 重要: `hashValue` 作为 `Hashable` 要求已被弃用。要实现 `Hashable`，请改为实现 `hash(into:)` 要求。编译器会为您提供 `hashValue` 的实现。
        public var hashValue: Int { get }
    }

    /// 框架在图像中识别为主要焦点对象的感兴趣区域
    ///
    /// *主体*是图像中的前景对象。
    /// 单个图像可包含多个主体。例如，在三个不同咖啡杯的图像中，框架可能将所有三个杯子分类为单独的主体。
    /// 当框架无法将照片中的重叠对象分离为单独主体时，一个主体可能由两个或多个对象组成。
    ///
    /// VisionKit 使应用能够单独或一起提取或*提取*移除背景后的图像主体。更多信息请参阅 ``ImageAnalysisInteraction/Subject/image``。
    ///
    /// ``VisionKit/ImageAnalysisInteraction`` 对象包含一个主体数组（``VisionKit/ImageAnalysisInteraction/subjects``），当 ``ImageAnalysisInteraction/preferredInteractionTypes`` 包含主体相关选项（如 ``ImageAnalysisInteraction/InteractionTypes/automatic`` 或 ``ImageAnalysisInteraction/InteractionTypes/imageSubject``）时激活。
    ///
    /// 应用还可通过启用 ``ImageAnalysisInteraction/InteractionTypes/visualLookUp`` 交互类型显示提供有关图像主体更多信息的按钮。
    public struct Subject : Hashable {

        /// 标识图像中主体范围的矩形
        @MainActor public var bounds: CGRect { get }

        /// 背景移除后的主体图像
        public var image: UIImage { get async throws }

        /// 使用给定哈希器序列化主体
        public func hash(into hasher: inout Hasher)

        /// 返回布尔值，指示两个值是否相等
        ///
        /// - 参数 lhs: 要比较的值
        /// - 参数 rhs: 另一个要比较的值
        public static func == (a: ImageAnalysisInteraction.Subject, b: ImageAnalysisInteraction.Subject) -> Bool

        /// 哈希值
        ///
        /// 哈希值在不同程序执行中不保证相同。请勿保存哈希值用于未来执行。
        ///
        /// - 重要: `hashValue` 作为 `Hashable` 要求已被弃用。要实现 `Hashable`，请改为实现 `hash(into:)` 要求。编译器会为您提供 `hashValue` 的实现。
        public var hashValue: Int { get }
    }

    /// 框架在图像中识别的所有主体集合
    @MainActor final public var subjects: Set<ImageAnalysisInteraction.Subject> { get async }

    /// 交互图像中所有高亮的主体
    @MainActor final public var highlightedSubjects: Set<ImageAnalysisInteraction.Subject>

    /// 返回交互图像中给定点处的主体（如果存在）
    ///
    /// 此方法适用于包含 ``VisionKit/ImageAnalysisInteraction/InteractionTypes/imageSubject`` 的交互类型。
    ///
    /// 以下代码根据屏幕点（例如用户点击的位置）检索主体图像：
    ///
    ///```swift
    /// let configuration = ImageAnalyzer.Configuration()
    /// ...
    /// interaction.preferredInteractionTypes = [.imageSubject]
    /// ...
    /// let viewPoint = /* 视图坐标系中的点 */
    /// if let subjectObject = try await interaction.subject(at: viewPoint) {
    ///     if let image = subjectObject.image {
    ///         // 使用主体图像执行操作
    ///     }
    /// }
    /// ```
    /// - 参数 point: 选择主体的视图坐标系中的点
    /// - 返回: 位于 `point` 的主体；如果无主体则返回 `nil`
    @MainActor final public func subject(at point: CGPoint) async -> ImageAnalysisInteraction.Subject?

    /// 异步提供包含给定主体且背景移除的图像
    ///
    /// - 参数 subjects: 要包含在图像中的主体数组
    ///
    /// 如果一个或多个主体无法生成图像，方法抛出 ``VisionKit/ImageAnalysisInteraction/SubjectUnavailable/imageUnavailable``。
    @MainActor final public func image(for subjects: Set<ImageAnalysisInteraction.Subject>) async throws -> UIImage
}

@available(iOS 16.0, macCatalyst 17.0, *)
extension ImageAnalysisInteraction : Sendable {
}

@available(iOS 17.0, *)
extension ImageAnalysisInteraction.SubjectUnavailable : Equatable {
}

@available(iOS 17.0, *)
extension ImageAnalysisInteraction.SubjectUnavailable : Hashable {
}

/// 处理交互对象的图像分析和用户交互回调的委托
///
/// ``ImageAnalysisInteraction`` 对象的委托实现此协议以提供界面详细信息并自定义用户交互的响应。
@available(iOS 16.0, macCatalyst 17.0, *)
@MainActor public protocol ImageAnalysisInteractionDelegate : AnyObject {

    /// 提供布尔值，指示交互是否可以在给定点开始
    ///
    /// 系统对每种交互类型调用此方法一次。默认值为 `true`，在图像显示后立即开始交互。
    ///
    /// - 参数 interaction: 可以开始交互的对象
    /// - 参数 point: 交互可以开始的点
    /// - 参数 interactionType: 可以开始的交互类型
    ///
    /// - 返回: 如果可以开始交互则为 `true`；否则为 `false`
    @MainActor func interaction(_ interaction: ImageAnalysisInteraction, shouldBeginAt point: CGPoint, for interactionType: ImageAnalysisInteraction.InteractionTypes) -> Bool

    /// 返回包含视图内图像的单位坐标系矩形
    ///
    /// 当交互视图类型不是 <doc://com.apple.documentation/documentation/uikit/uiimageview> 时实现此方法。
    ///
    /// - 参数 interaction: 内容矩形的关联交互对象
    ///
    /// - 返回: 视图内图像的矩形（单位坐标系）。默认返回值为单位矩形 `[0.0, 0.0, 1.0, 1.0]`，表示整个视图内容。
    @MainActor func contentsRect(for interaction: ImageAnalysisInteraction) -> CGRect

    /// 提供包含图像的视图
    ///
    /// 仅当包含图像的视图与交互的视图不同时实现此委托方法。
    ///
    /// - 参数 interaction: 内容视图的关联交互对象
    ///
    /// - 返回: 此交互包含图像的视图
    @MainActor func contentView(for interaction: ImageAnalysisInteraction) -> UIView?

    /// 提供呈现界面对象的视图控制器
    ///
    /// 默认返回值为窗口的根视图控制器。
    ///
    /// - 参数 interaction: 呈现视图的关联交互对象
    ///
    /// - 返回: 呈现交互对象的高亮、菜单和其他元素的视图控制器
    @MainActor func presentingViewController(for interaction: ImageAnalysisInteraction) -> UIViewController?

    /// 当实时文本按钮的可见性更改时通知应用
    ///
    /// - 参数 interaction: 实时文本按钮出现的交互对象
    /// - 参数 visible: 如果实时文本按钮出现则为 `true`；否则为 `false`
    @MainActor func interaction(_ interaction: ImageAnalysisInteraction, liveTextButtonDidChangeToVisible visible: Bool)

    /// 当用户点击实时文本按钮导致图像中识别项目高亮时通知应用
    ///
    /// - 参数 interaction: 选定项目高亮更改的交互对象
    /// - 参数 highlightSelectedItems: 指示是否出现高亮的布尔值
    @MainActor func interaction(_ interaction: ImageAnalysisInteraction, highlightSelectedItemsDidChange highlightSelectedItems: Bool)

    /// 当交互的文本选择更改时通知应用
    ///
    /// - 参数 interaction: 文本选择更改的交互对象
    @available(iOS 17.0, *)
    @MainActor func textSelectionDidChange(_ interaction: ImageAnalysisInteraction)
}

/// 默认实现
@available(iOS 16.0, macCatalyst 17.0, *)
extension ImageAnalysisInteractionDelegate {

    /// 指示交互开始的默认实现
    ///
    /// - 返回: 此默认实现返回 `true`
    @MainActor public func interaction(_ interaction: ImageAnalysisInteraction, shouldBeginAt point: CGPoint, for interactionType: ImageAnalysisInteraction.InteractionTypes) -> Bool

    /// 表示交互视图完整大小的默认单位矩形
    ///
    /// - 返回: 原点为 `(0, 0)` 且宽度和高度与交互视图相同的单位矩形
    @MainActor public func contentsRect(for interaction: ImageAnalysisInteraction) -> CGRect

    /// 提供交互视图的默认实现
    ///
    /// - 返回: 交互的视图
    @MainActor public func contentView(for interaction: ImageAnalysisInteraction) -> UIView?

    /// 提供交互视图根视图控制器的默认实现
    ///
    /// - 返回: 交互视图的根视图控制器
    @MainActor public func presentingViewController(for interaction: ImageAnalysisInteraction) -> UIViewController?

    /// 实时文本按钮出现或消失时的默认空实现
    @MainActor public func interaction(_ interaction: ImageAnalysisInteraction, liveTextButtonDidChangeToVisible visible: Bool)

    /// 用户点击实时文本按钮导致图像中识别项目高亮时的默认空实现
    @MainActor public func interaction(_ interaction: ImageAnalysisInteraction, highlightSelectedItemsDidChange highlightSelectedItems: Bool)

    /// 文本选择更改时的默认空实现
    @MainActor public func textSelectionDidChange(_ interaction: ImageAnalysisInteraction)
}

/// 在图像中查找用户可交互项目（如主体、文本和二维码）的对象
///
/// 使用 `ImageAnalyzer` 对象时，首先创建 ``ImageAnalyzer/Configuration`` 对象，并指定要在图像中查找的项目类型。然后将要分析的图像和配置对象传递给 `ImageAnalyzer` 对象，使用 ``ImageAnalyzer/analyze(_:configuration:)`` 或类似方法。此方法返回包含 VisionKit 实现实时文本界面所需所有数据的 ``ImageAnalysis`` 对象。
///
/// 接下来，显示实时文本界面。对于 iOS 应用，将包含图像的视图的交互对象设置为 ``ImageAnalysisInteraction`` 的实例，并将其 ``ImageAnalysisInteraction/analysis`` 属性设置为 `ImageAnalysis` 对象。要启用与图像的交互，设置交互对象的 ``ImageAnalysisInteraction/preferredInteractionTypes`` 属性。要自定义实时文本界面，设置 `ImageAnalysisInteraction` 对象的 ``ImageAnalysisInteraction/delegate`` 属性并实现 ``ImageAnalysisInteractionDelegate`` 协议方法。
///
/// 对于 macOS 应用，在包含图像的视图上方添加 `ImageAnalysisOverlayView` 对象，并将其 `analysis` 属性设置为 `ImageAnalysis` 对象。要启用与图像的交互，设置覆盖视图的 `preferredInteractionTypes` 属性。设置 `ImageAnalysisOverlayView` 对象的 `delegate` 属性并实现 `ImageAnalysisOverlayViewDelegate` 协议方法。
///
/// 默认情况下，实时文本界面在显示视图时立即启动。
@available(iOS 16.0, macOS 13.0, macCatalyst 17.0, *)
final public class ImageAnalyzer : @unchecked Sendable {

    /// 指定图像分析器识别的项目类型和区域设置的配置
    ///
    /// 创建 `ImageAnalyzer.Configuration` 结构以指定分析图像时的条件。然后将配置对象传递给 `ImageAnalyzer` 的 ``ImageAnalyzer/analyze(_:configuration:)`` 或类似方法以查找所需项目。
    public struct Configuration {

        /// 图像分析器在图像中查找的项目类型
        public let analysisTypes: ImageAnalyzer.AnalysisTypes

        /// 图像分析器识别文本项目时使用的语言
        public var locales: [String]

        /// 创建图像分析器用于查找项目的配置
        ///
        /// - 参数 types: 图像分析器在图像中查找的项目类型
        public init(_ types: ImageAnalyzer.AnalysisTypes)
    }

    /// 图像分析器在图像中查找的项目类型
    public struct AnalysisTypes : OptionSet {

        /// 分析类型的唯一基础值
        public var rawValue: UInt

        /// 使用给定值创建分析类型
        ///
        /// - 参数 rawValue: 分析类型的基础值
        public init(rawValue: UInt)

        /// 分析图像文本的选项
        public static let text: ImageAnalyzer.AnalysisTypes

        /// 分析图像中机器可读码（如二维码）的选项
        ///
        /// 框架识别以下码类型：
        ///
        /// Aztec, Codabar, Code 39 Checksum,
        /// Code 39, Code 39 Full ASCII, Code 39 Full ASCII Checksum,
        /// Code 93, Code 93i, Code 128, Data Matrix, EAN-8,
        /// EAN-13, GS1 DataBar Expanded, GS1 DataBar Limited, ITF,
        /// ITF-14, MicroPDF417, MicroQR, PDF417, QR, UPC-E
        ///
        /// - 重要: 在 macOS 上框架忽略此选项。
        public static let machineReadableCode: ImageAnalyzer.AnalysisTypes

        /// 分析图像中框架可查找更多信息的主体的选项
        ///
        /// 当框架识别图像中的特定类型主体时，它提供界面让用户了解有关主体的更多信息。例如，如果图像包含玫瑰，框架识别植物并让用户点击植物，呈现包含有关特定植物类型（即玫瑰）额外资源的列表的表单。
        ///
        /// 有关图像中主体的更多信息，请参阅 ``ImageAnalysisInteraction/Subject``。
        public static let visualLookUp: ImageAnalyzer.AnalysisTypes

        /// 数组字面量的元素类型
        @available(iOS 16.0, macOS 13.0, macCatalyst 17.0, *)
        public typealias ArrayLiteralElement = ImageAnalyzer.AnalysisTypes

        /// 选项集的元素类型
        ///
        /// 要从 `OptionSet` 协议继承所有默认实现，`Element` 类型必须为 `Self`（默认）。
        @available(iOS 16.0, macOS 13.0, macCatalyst 17.0, *)
        public typealias Element = ImageAnalyzer.AnalysisTypes

        /// 可用于表示符合类型所有值的原始类型
        ///
        /// 符合类型的每个不同值都有 `RawValue` 类型的唯一对应值，但可能存在 `RawValue` 类型值没有符合类型对应值的情况。
        @available(iOS 16.0, macOS 13.0, macCatalyst 17.0, *)
        public typealias RawValue = UInt
    }

    /// 创建识别图像中主体、文本和机器可读码的图像分析器
    public init()

    /// 指示设备是否支持图像分析的布尔值
    ///
    /// 在运行时检查此属性以确定设备是否支持在图像中查找文本、机器可读码和主体。系统在配备 A12 仿生芯片或更高版本的设备上将此属性设置为 `true`。
    ///
    /// 有关分析器在图像中查找内容的更多信息，请参阅 ``ImageAnalyzer/AnalysisTypes``。
    ///
    /// - 注意: 如果图像分析是应用操作的基本要求，可防止不受支持的设备安装应用。在应用的 `Info.plist` 中添加 <doc://com.apple.documentation/documentation/bundleresources/information_property_list/uirequireddevicecapabilities> 键（或更新键（如果已存在）并在数组中包含 `iphone-ipad-minimum-performance-a12` 成员。
    final public class var isSupported: Bool { get }

    /// 图像分析器识别的语言标识符
    final public class var supportedTextRecognitionLanguages: [String] { get }

    /// 返回提供图像实时文本交互的数据
    ///
    /// - 参数 image: 分析器处理的图像
    /// - 参数 configuration: 指定要识别的数据类型和文本项目区域设置的配置
    ///
    /// - 返回: 分析器在图像中找到的数据项目
    ///
    /// 此函数根据给定图像的 orientation 属性自动配置方向。
    final public func analyze(_ image: UIImage, configuration: ImageAnalyzer.Configuration) async throws -> ImageAnalysis

    /// 返回提供指定方向图像实时文本交互的数据
    ///
    /// - 参数 image: 分析器处理的图像
    /// - 参数 orientation: 分析器处理图像的方向
    /// - 参数 configuration: 指定要识别的数据类型和文本项目区域设置的配置
    ///
    /// - 返回: 分析器在图像中找到的数据项目
    final public func analyze(_ image: UIImage, orientation: UIImage.Orientation, configuration: ImageAnalyzer.Configuration) async throws -> ImageAnalysis

    /// 返回提供 Core Graphics 图像实时文本交互的数据（指定方向）
    ///
    /// - 参数 cgImage: 分析器处理的图像
    /// - 参数 orientation: 分析器处理图像的方向
    /// - 参数 configuration: 指定要识别的数据类型和文本项目区域设置的配置
    ///
    /// - 返回: 分析器在图像中找到的数据项目
    final public func analyze(_ cgImage: CGImage, orientation: CGImagePropertyOrientation, configuration: ImageAnalyzer.Configuration) async throws -> ImageAnalysis

    /// 返回提供位图图像实时文本交互的数据（指定方向）
    ///
    /// - 参数 ciImage: 分析器处理的位图图像或图像掩码
    /// - 参数 orientation: 分析器处理图像的方向
    /// - 参数 configuration: 指定要识别的数据类型和文本项目区域设置的配置
    ///
    /// - 返回: 分析器在图像中找到的数据项目
    final public func analyze(_ ciImage: CIImage, orientation: CGImagePropertyOrientation, configuration: ImageAnalyzer.Configuration) async throws -> ImageAnalysis

    /// 返回提供像素缓冲图像实时文本交互的数据（指定方向）
    ///
    /// - 参数 pixelBuffer: 分析器处理的 Core Video 像素缓冲对象
    /// - 参数 orientation: 分析器处理图像的方向
    /// - 参数 configuration: 指定要识别的数据类型和文本项目区域设置的配置
    ///
    /// - 返回: 分析器在图像中找到的数据项目
    final public func analyze(_ pixelBuffer: CVPixelBuffer, orientation: CGImagePropertyOrientation, configuration: ImageAnalyzer.Configuration) async throws -> ImageAnalysis
 
 /// 返回提供 URL 图像实时文本交互的数据（指定方向）
 ///
 /// - 参数 url: 分析器处理的图像 URL 位置
 /// - 参数 orientation: 分析器处理图像的方向
 /// - 参数 configuration: 指定要识别的数据类型和文本项目区域设置的配置
 ///
 /// - 返回: 分析器在图像中找到的数据项目
 final public func analyze(imageAt url: URL, orientation: CGImagePropertyOrientation, configuration: ImageAnalyzer.Configuration) async throws -> ImageAnalysis
 }

 /// 数据扫描器在相机实时视频中识别的项目
 ///
 /// `RecognizedItem` 枚举包含扫描器识别项目的数据，如项目的位置、边界和内容。
 /// 对于文本项目，内容是选定的字符串；对于条形码，是编码的有效载荷字符串。
 @available(iOS 16.0, *)
 @available(macCatalyst, unavailable)
 public enum RecognizedItem : Identifiable {

     /// 表示识别项目的四个角的对象
     @available(iOS 16.0, *)
     @available(macCatalyst, unavailable)
     public struct Bounds : @unchecked Sendable {

         /// 识别项目的左上角（视图坐标系）
         public var topLeft: CGPoint

         /// 识别项目的右上角（视图坐标系）
         public var topRight: CGPoint

         /// 识别项目的右下角（视图坐标系）
         public var bottomRight: CGPoint

         /// 识别项目的左下角（视图坐标系）
         public var bottomLeft: CGPoint
     }

     /// 表示扫描器识别的文本项目的对象
     @available(iOS 16.0, *)
     @available(macCatalyst, unavailable)
     public struct Text : Identifiable {

         /// 识别项目的唯一标识符
         ///
         /// 如果同一项目出现在多个视频帧中，`id`保持不变。
         public var id: UUID { get }

         /// 识别项目的边界（视图坐标系）
         public var bounds: RecognizedItem.Bounds { get }

         /// 文本项目表示的字符串
         public var transcript: String { get }

         /// 包含图像中文本和字形位置及内容详细信息的对象
         ///
         /// 仅在需要识别项目属性中未包含的视觉详细信息时使用此属性
         public var observation: VNRecognizedTextObservation { get }

         /// 表示与实例关联的实体稳定标识的类型
         @available(iOS 16.0, *)
         @available(macCatalyst, unavailable)
         public typealias ID = UUID
     }

     /// 表示扫描器识别的机器可读码的对象
     @available(iOS 16.0, *)
     @available(macCatalyst, unavailable)
     public struct Barcode : Identifiable {

         /// 识别项目的唯一标识符
         ///
         /// 如果同一项目出现在多个视频帧中，`id`保持不变。
         public var id: UUID { get }

         /// 识别项目在视图中的位置
         public var bounds: RecognizedItem.Bounds { get }

         /// 条形码的有效载荷或字符串表示
         public var payloadStringValue: String? { get }

         /// 条形码信息的表示
         public var observation: VNBarcodeObservation { get }

         /// 表示与实例关联的实体稳定标识的类型
         @available(iOS 16.0, *)
         @available(macCatalyst, unavailable)
         public typealias ID = UUID
     }

     /// 分析器在文本中检测到的文本或数据
     ///
     /// - 参数 Text: 识别的文本项目
     case text(RecognizedItem.Text)

     /// 机器可读的条形码
     case barcode(RecognizedItem.Barcode)

     /// 识别项目的唯一标识符
     ///
     /// 如果同一项目出现在多个视频帧中，`id`保持不变。
     public var id: UUID { get }

     /// 识别项目的四个角（视图坐标系）
     public var bounds: RecognizedItem.Bounds { get }

     /// 表示与实例关联的实体稳定标识的类型
     @available(iOS 16.0, *)
     @available(macCatalyst, unavailable)
     public typealias ID = UUID


 public protocol ImageAnalysisInteractionDelegate : AnyObject {
     // 返回一个布尔值，可以控制某个位置是否允许交互
     func interaction(_ interaction: ImageAnalysisInteraction, shouldBeginAt point: CGPoint, for interactionType: ImageAnalysisInteraction.InteractionTypes) -> Bool
     // 对于非UIImageView的组件，此代理可以返回一个渲染区域，用来告诉交互层要渲染的位置
     func contentsRect(for interaction: ImageAnalysisInteraction) -> CGRect
     // 自定义设置用来渲染图片的视图
     func contentView(for interaction: ImageAnalysisInteraction) -> UIView?
     // 设置一个视图控制器用来承接可交互元素的弹出跳转，默认为Window的根视图
     func presentingViewController(for interaction: ImageAnalysisInteraction) -> UIViewController?
     // 当实时文本的可见性变化时会回调
     func interaction(_ interaction: ImageAnalysisInteraction, liveTextButtonDidChangeToVisible visible: Bool)
     // 选中的高亮元素变化时回调
     func interaction(_ interaction: ImageAnalysisInteraction, highlightSelectedItemsDidChange highlightSelectedItems: Bool)
     // 选中的文本变化时回调
     func textSelectionDidChange(_ interaction: ImageAnalysisInteraction)
 }

 
 */
