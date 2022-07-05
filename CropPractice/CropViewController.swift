//
//  CropViewController.swift
//  CropPractice
//
//  Created by Houston Park on 2022/06/22.
//

import UIKit

class CropViewController: UIViewController {

    //MARK: - Outlet Variables

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var cropLayerView: UIView!

    //MARK: - Gesture Variables

    @IBOutlet var cropLayerPanGestureSender: UIPanGestureRecognizer!
    @IBOutlet var cropLayerPinchGestureSender: UIPinchGestureRecognizer!

    //MARK: - Indicator Variables

    private let indicatorSize = CGSize(width: 44, height: 44)

    private enum Edge: CaseIterable {
        case topLeft
        case topRight
        case bottomLeft
        case bottomRight
    }

    private var edgeCoordinates: [Edge: CGPoint] = [
        .topLeft: CGPoint(),
        .topRight: CGPoint(),
        .bottomLeft: CGPoint(),
        .bottomRight: CGPoint()
    ]

    private var edgeIndicator: [Edge: CropIndicatorView] = [
        .topLeft:
            CropIndicatorView().loadView().rotate(angle: 180),
        .topRight:
            CropIndicatorView().loadView().rotate(angle: 270),
        .bottomLeft:
            CropIndicatorView().loadView().rotate(angle: 90),
        .bottomRight:
            CropIndicatorView().loadView()
    ]

    private var edgeAnchor: [Edge: (x: NSLayoutConstraint, y: NSLayoutConstraint)] = [
        .topLeft: (x: NSLayoutConstraint(), y: NSLayoutConstraint()),
        .topRight: (x: NSLayoutConstraint(), y: NSLayoutConstraint()),
        .bottomLeft: (x: NSLayoutConstraint(), y: NSLayoutConstraint()),
        .bottomRight: (x: NSLayoutConstraint(), y: NSLayoutConstraint())
    ]

    //MARK: - Image Size

    private var imageFrameOnScreen: CGRect = .zero
    private var originImageFrameOnScreen: CGRect = .zero
    private var currentImageScale: CGFloat = 1

    private var imageFrameScale: CGFloat = 1
    private var imageFrameLeadingPadding: CGFloat = 0
    private var imageFrameTrailingPadding: CGFloat = 0
    private var imageFrameTopPadding: CGFloat = 0
    private var imageFrameBottomPadding: CGFloat = 0

    //MARK: - Overriding Functions

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.translatesAutoresizingMaskIntoConstraints = false
        self.cropLayerView.translatesAutoresizingMaskIntoConstraints = false
        Edge.allCases.forEach { edge in
            guard let indicatorView = self.edgeIndicator[edge] else { return }
            indicatorView.translatesAutoresizingMaskIntoConstraints = false
        }
        self.registerGesture()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        Edge.allCases.forEach { edge in
            guard let indicatorView = self.edgeIndicator[edge] else { return }
            self.cropLayerView.addSubview(indicatorView)
            indicatorView.widthAnchor.constraint(equalToConstant: self.indicatorSize.width).isActive = true
            indicatorView.heightAnchor.constraint(equalToConstant: self.indicatorSize.height).isActive = true
            self.edgeAnchor[edge]?.x = indicatorView.centerXAnchor.constraint(equalTo: self.cropLayerView.centerXAnchor)
            self.edgeAnchor[edge]?.y = indicatorView.centerYAnchor.constraint(equalTo: self.cropLayerView.centerYAnchor)
            self.edgeAnchor[edge]?.x.isActive = true
            self.edgeAnchor[edge]?.y.isActive = true
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.calculateImageSizeOnScreenAndFitCropLayerView()
        let rect = CGRect(x: self.cropLayerView.frame.width / 2 - 100, y: self.cropLayerView.frame.height / 2 - 50, width: 200, height: 100)
        self.drawCropTransparentPaths(bounds: rect)
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)

        coordinator.animate { context in

            self.cropLayerView.layer.mask = nil

            self.cropLayerView.layer.opacity = 0
            Edge.allCases.forEach { edge in
                self.edgeIndicator[edge]?.alpha = 0
            }

        } completion: { context in

            let previousImageFrameOnScreen = self.imageFrameOnScreen
            self.calculateImageSizeOnScreenAndFitCropLayerView()
            let currentImageFrameOnScreen = self.imageFrameOnScreen

            print("Previous: ", previousImageFrameOnScreen)
            print("Current : ", currentImageFrameOnScreen)

            let previousCropBounds = self.calcCurrentCropRect()
            var currentCropBounds = previousCropBounds

            let previousCurrentImageFrameRatio = currentImageFrameOnScreen.width / previousImageFrameOnScreen.width

            currentCropBounds.origin.x = self.imageFrameLeadingPadding + (previousCropBounds.minX - previousImageFrameOnScreen.minX) * previousCurrentImageFrameRatio

            currentCropBounds.origin.y = self.imageFrameTopPadding + (previousCropBounds.minY - previousImageFrameOnScreen.minY) * previousCurrentImageFrameRatio

            currentCropBounds.size.width = previousCropBounds.width * previousCurrentImageFrameRatio
            currentCropBounds.size.height = previousCropBounds.height * previousCurrentImageFrameRatio

            Edge.allCases.forEach { edge in
                switch edge {
                case .topLeft:
                    self.edgeCoordinates[edge] = CGPoint(x: currentCropBounds.minX, y: currentCropBounds.minY)
                case .topRight:
                    self.edgeCoordinates[edge] = CGPoint(x: currentCropBounds.maxX, y: currentCropBounds.minY)
                case .bottomLeft:
                    self.edgeCoordinates[edge] = CGPoint(x: currentCropBounds.minX, y: currentCropBounds.maxY)
                case .bottomRight:
                    self.edgeCoordinates[edge] = CGPoint(x: currentCropBounds.maxX, y: currentCropBounds.maxY)
                }
            }

            UIView.animate(withDuration: context.transitionDuration) {
                self.cropLayerView.layer.opacity = 1
                Edge.allCases.forEach { edge in
                    self.edgeIndicator[edge]?.alpha = 1.0
                }
            }

            self.drawCropTransparentPaths(bounds: currentCropBounds)

        }

    }

    //MARK: - IBAction Implementation

    @IBAction func cropLayerPinch(_ sender: Any) {

        var scale = self.cropLayerPinchGestureSender.scale

        let ratio = self.imageFrameOnScreen.width * scale / self.originImageFrameOnScreen.width

        self.currentImageScale = ratio

        if ratio < 1 {
            scale = 1
            self.currentImageScale = 1
        }
        else if ratio > 3 {
            scale = 1
            self.currentImageScale = 3
        }

        let dw = self.imageFrameOnScreen.size.width * (scale - 1)   //Width Delta Value
        let dh = self.imageFrameOnScreen.size.height * (scale - 1)  //Height Delta Value
        self.imageFrameOnScreen.size.width *= scale
        self.imageFrameOnScreen.size.height *= scale
        self.imageFrameOnScreen.origin.x -= dw / 2
        self.imageFrameOnScreen.origin.y -= dh / 2

        self.updateImageFramePadding()

        self.imageView.transform = self.imageView.transform.scaledBy(x: scale, y: scale)

        self.cropLayerPinchGestureSender.scale = 1.0
    }

    @IBAction func cropLayerPanGesture(_ sender: Any) {

        let transition = self.cropLayerPanGestureSender.translation(in: self.cropLayerView)

        let currentIndicatorBounds = self.calcCurrentCropRect()

        var dx = transition.x
        var dy = transition.y

        if self.imageFrameOnScreen.minX + dx > currentIndicatorBounds.minX || self.imageFrameOnScreen.maxX + dx < currentIndicatorBounds.maxX {
            dx = 0 //X Coordinate Delta Value
        }

        if self.imageFrameOnScreen.minY + dy > currentIndicatorBounds.minY || self.imageFrameOnScreen.maxY + dy < currentIndicatorBounds.maxY {
            dy = 0 //Y Coordinate Delta Value
        }

        self.imageView.center = CGPoint(x: self.imageView.center.x + dx, y: self.imageView.center.y + dy)

        self.imageFrameOnScreen.origin = CGPoint(x: self.imageFrameOnScreen.origin.x + dx, y: self.imageFrameOnScreen.origin.y + dy)

        self.updateImageFramePadding()

        self.cropLayerPanGestureSender.setTranslation(.zero, in: self.cropLayerView)
    }

}

//MARK: - Indicator Gesture Code

extension CropViewController {

    private func registerGesture() {
        Edge.allCases.forEach { edge in
            switch edge {
            case .topLeft:
                guard let indicatorView = self.edgeIndicator[edge] else { return }
                indicatorView.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(self.dragTopLeft(sender:))))
            case .topRight:
                guard let indicatorView = self.edgeIndicator[edge] else { return }
                indicatorView.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(self.dragTopRight(sender:))))
            case .bottomLeft:
                guard let indicatorView = self.edgeIndicator[edge] else { return }
                indicatorView.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(self.dragBottomLeft(sender:))))
            case .bottomRight:
                guard let indicatorView = self.edgeIndicator[edge] else { return }
                indicatorView.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(self.dragBottomRight(sender:))))
            }
        }
    }


    @objc func dragTopLeft(sender: UIPanGestureRecognizer) {
        guard let indicatorView = self.edgeIndicator[.topLeft] else { return }

        let transition = sender.translation(in: indicatorView)
        let currentBounds = self.calcCurrentCropRect()

        var changedX = indicatorView.center.x - transition.x
        var changedY = indicatorView.center.y - transition.y
        var changedWidth = self.edgeCoordinates[.topRight]!.x - changedX
        var changedHeight = self.edgeCoordinates[.bottomLeft]!.y - changedY

        if changedX < self.imageFrameLeadingPadding {
            changedX = self.imageFrameLeadingPadding
            changedWidth = currentBounds.maxX - changedX
        }

        if changedY < self.imageFrameTopPadding {
            changedY = self.imageFrameTopPadding
            changedHeight = currentBounds.maxY - changedY
        }

        if changedWidth < self.indicatorSize.width {
            changedX = currentBounds.maxX - self.indicatorSize.width
            changedWidth = self.indicatorSize.width
        }

        if changedHeight < self.indicatorSize.height {
            changedY = currentBounds.maxY - self.indicatorSize.width
            changedHeight = self.indicatorSize.height
        }

        let draggedRect = CGRect(x: changedX, y: changedY, width: changedWidth, height: changedHeight)

        self.drawCropTransparentPaths(bounds: draggedRect)

        sender.setTranslation(.zero, in: indicatorView)
    }

    @objc func dragTopRight(sender: UIPanGestureRecognizer) {
        guard let indicatorView = self.edgeIndicator[.topRight] else { return }

        let transition = sender.translation(in: indicatorView)
        let currentBounds = self.calcCurrentCropRect()

        let changedX = indicatorView.center.x + transition.y
        var changedY = indicatorView.center.y - transition.x
        var changedWidth = changedX - self.edgeCoordinates[.topLeft]!.x
        var changedHeight = self.edgeCoordinates[.bottomRight]!.y - changedY

        if changedX > self.cropLayerView.frame.width - self.imageFrameTrailingPadding {
            changedWidth = currentBounds.width
        }

        if changedY < self.imageFrameTopPadding {
            changedY = self.imageFrameTopPadding
            changedHeight = currentBounds.maxY - changedY
        }

        if changedWidth < self.indicatorSize.width {
            changedWidth = self.indicatorSize.width
        }

        if changedHeight < self.indicatorSize.height {
            changedY = currentBounds.maxY - self.indicatorSize.height
            changedHeight = self.indicatorSize.height
        }

        let draggedRect = CGRect(x: currentBounds.origin.x, y: changedY, width: changedWidth, height: changedHeight)

        self.drawCropTransparentPaths(bounds: draggedRect)

        sender.setTranslation(.zero, in: indicatorView)
    }

    @objc func dragBottomLeft(sender: UIPanGestureRecognizer) {
        guard let indicatorView = self.edgeIndicator[.bottomLeft] else { return }

        let transition = sender.translation(in: indicatorView)
        let currentBounds = self.calcCurrentCropRect()

        var changedX = indicatorView.center.x - transition.y
        let changedY = indicatorView.center.y + transition.x
        var changedWidth = self.edgeCoordinates[.bottomRight]!.x - changedX
        var changedHeight = changedY - self.edgeCoordinates[.topLeft]!.y

        if changedX < self.imageFrameLeadingPadding {
            changedX = self.imageFrameLeadingPadding
            changedWidth = currentBounds.maxX - changedX
        }

        if changedY > self.cropLayerView.frame.height - self.imageFrameBottomPadding {
            changedHeight = currentBounds.height
        }

        if changedWidth < self.indicatorSize.width {
            changedX = currentBounds.maxX - self.indicatorSize.width
            changedWidth = self.indicatorSize.width
        }

        if changedHeight < self.indicatorSize.height {
            changedHeight = self.indicatorSize.height
        }

        let draggedRect = CGRect(x: changedX, y: currentBounds.origin.y, width: changedWidth, height: changedHeight)

        self.drawCropTransparentPaths(bounds: draggedRect)

        sender.setTranslation(.zero, in: indicatorView)
    }

    @objc func dragBottomRight(sender: UIPanGestureRecognizer) {
        guard let indicatorView = self.edgeIndicator[.bottomRight] else { return }

        let transition = sender.translation(in: indicatorView)
        let currentBounds = self.calcCurrentCropRect()

        let changedX = indicatorView.center.x + transition.x
        let changedY = indicatorView.center.y + transition.y
        var changedWidth = changedX - self.edgeCoordinates[.bottomLeft]!.x
        var changedHeight = changedY - self.edgeCoordinates[.topRight]!.y

        if changedX > self.cropLayerView.frame.width - self.imageFrameTrailingPadding {
            changedWidth = currentBounds.width
        }

        if changedY > self.cropLayerView.frame.height - self.imageFrameBottomPadding {
            changedHeight = currentBounds.height
        }

        if changedWidth < self.indicatorSize.width {
            changedWidth = self.indicatorSize.width
        }

        if changedHeight < self.indicatorSize.height {
            changedHeight = self.indicatorSize.height
        }

        let draggedRect = CGRect(x: currentBounds.origin.x, y: currentBounds.origin.y, width: changedWidth, height: changedHeight)

        self.drawCropTransparentPaths(bounds: draggedRect)

        sender.setTranslation(.zero, in: indicatorView)
    }
}

//MARK: - Drawing Engine
extension CropViewController {

    private func calculateImageSizeOnScreenAndFitCropLayerView() {
        guard let imageSize = imageView.image?.size else { return }
        let viewSize = self.cropLayerView.frame.size
        var imageResize = CGSize.zero
        if imageSize.width > imageSize.height {
            if imageSize.width / imageSize.height < viewSize.width / viewSize.height {
                imageResize.width = viewSize.height * imageSize.width / imageSize.height
                imageResize.height = viewSize.height
            }
            else if imageSize.width / imageSize.height > viewSize.width / viewSize.height {
                imageResize.width = viewSize.width
                imageResize.height = viewSize.width * imageSize.height / imageSize.width
            }
            else {
                imageResize.width = viewSize.width
                imageResize.height = viewSize.height
            }
        }
        else if imageSize.width < imageSize.height {
            if imageSize.height / imageSize.width < viewSize.height / viewSize.width {
                imageResize.width = viewSize.width
                imageResize.height = viewSize.width * imageSize.height / imageSize.width
            }
            else if imageSize.height / imageSize.width > viewSize.height / viewSize.width {
                imageResize.width = viewSize.height * imageSize.width / imageSize.height
                imageResize.height = viewSize.height
            }
            else {
                imageResize.width = viewSize.width
                imageResize.height = viewSize.height
            }
        }
        else {
            if viewSize.width > viewSize.height {
                imageResize.width = viewSize.height
                imageResize.height = viewSize.height
            }
            else if viewSize.width < viewSize.height {
                imageResize.width = viewSize.width
                imageResize.height = viewSize.width
            }
            else {
                imageResize.width = viewSize.width
                imageResize.height = viewSize.height
            }
        }

        self.imageFrameOnScreen = CGRect(x: (self.cropLayerView.frame.width - imageResize.width) / 2, y: (self.cropLayerView.frame.height - imageResize.height) / 2, width: imageResize.width, height: imageResize.height)

        // 변화량 이기때문에 벡터성분과는 관련이 없다.
        let originDeltaWidth = self.imageFrameOnScreen.size.width * (self.currentImageScale - 1)
        let originDeltaHeight = self.imageFrameOnScreen.size.height * (self.currentImageScale - 1)

        // 팽창 방향과 수축 방향의 벡터가 Pinch Zoom 과 반대이기때문에 Multiplier 와 Divider 를 바꿔서 사용해줘야한다.
        self.originImageFrameOnScreen.size.width = self.imageFrameOnScreen.size.width / self.currentImageScale
        self.originImageFrameOnScreen.size.height = self.imageFrameOnScreen.size.height / self.currentImageScale

        // 팽창 방향과 수축 방향의 벡터가 Pinch Zoom 과 반대이기때문에 Adder 와 Subtractor 를 바꿔서 사용해줘야한다.
        self.originImageFrameOnScreen.origin.x = self.imageFrameOnScreen.origin.x + (originDeltaWidth / 2)
        self.originImageFrameOnScreen.origin.y = self.imageFrameOnScreen.origin.y + (originDeltaHeight / 2)

        self.imageFrameLeadingPadding = self.imageFrameOnScreen.minX - self.cropLayerView.frame.minX
        self.imageFrameTrailingPadding = self.cropLayerView.frame.maxX - self.imageFrameOnScreen.maxX
        self.imageFrameTopPadding = self.imageFrameOnScreen.minY - self.cropLayerView.frame.minY
        self.imageFrameBottomPadding = self.cropLayerView.frame.maxY - self.imageFrameOnScreen.maxY
    }

    private func drawCropTransparentPaths(bounds: CGRect) {

        let cropLayerBounds = self.cropLayerView.frame
        let path = UIBezierPath()
        let pathRect = UIBezierPath(rect: cropLayerBounds)
        let pathSmallRect = UIBezierPath(rect: bounds)

        path.append(pathRect)
        path.append(pathSmallRect.reversing())

        let layer = CAShapeLayer()
        layer.path = path.cgPath

        self.cropLayerView.layer.mask = layer
        self.drawEdgeIndicator(bounds: bounds)
    }

    private func drawEdgeIndicator(bounds: CGRect) {
        Edge.allCases.forEach { edge in
            switch edge {
            case .topLeft:
                self.edgeCoordinates[edge] = CGPoint(x: bounds.minX, y: bounds.minY)
            case .topRight:
                self.edgeCoordinates[edge] = CGPoint(x: bounds.maxX, y: bounds.minY)
            case .bottomLeft:
                self.edgeCoordinates[edge] = CGPoint(x: bounds.minX, y: bounds.maxY)
            case .bottomRight:
                self.edgeCoordinates[edge] = CGPoint(x: bounds.maxX, y: bounds.maxY)
            }
            self.edgeAnchor[edge]?.x.constant = self.edgeCoordinates[edge]!.x - self.cropLayerView.frame.midX
            self.edgeAnchor[edge]?.y.constant = self.edgeCoordinates[edge]!.y - self.cropLayerView.frame.midY
        }
    }

    private func calcCurrentCropRect() -> CGRect {
        return CGRect(x: self.edgeCoordinates[.topLeft]?.x ?? self.cropLayerView.frame.minX, y: self.edgeCoordinates[.topLeft]?.y ?? self.cropLayerView.frame.minY, width: (self.edgeCoordinates[.topRight]?.x ?? self.cropLayerView.frame.maxX) - (self.edgeCoordinates[.topLeft]?.x ?? self.cropLayerView.frame.minX), height: (self.edgeCoordinates[.bottomLeft]?.y ?? self.cropLayerView.frame.maxY) - (self.edgeCoordinates[.topLeft]?.y ?? self.cropLayerView.frame.minY))
    }

    private func updateImageFramePadding() {
        let leadingPadding = self.imageFrameOnScreen.minX - self.cropLayerView.frame.minX
        self.imageFrameLeadingPadding = leadingPadding < 0 ? 0 : leadingPadding

        let trailingPadding = self.cropLayerView.frame.maxX - self.imageFrameOnScreen.maxX
        self.imageFrameTrailingPadding = trailingPadding < 0 ? 0 : trailingPadding

        let topPadding = self.imageFrameOnScreen.minY - self.cropLayerView.frame.minY
        self.imageFrameTopPadding = topPadding < 0 ? 0 : topPadding

        let bottomPadding = self.cropLayerView.frame.maxY - self.imageFrameOnScreen.maxY
        self.imageFrameBottomPadding = bottomPadding < 0 ? 0 : bottomPadding
    }
}
