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

    //MARK: - UIView Animation Duration

    private let defaultAnimateDuration: CGFloat = 0.3

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

            self.imageView.transform = self.imageView.transform.scaledBy(x: 1/self.currentImageScale, y: 1/self.currentImageScale)
            self.currentImageScale = 1

            UIView.animate(withDuration: self.defaultAnimateDuration) {
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

        self.imageFrameOnScreen = self.scalingBounds(bounds: self.imageFrameOnScreen, scale: scale)

        let currentIndicatorBounds = self.calcCurrentCropRect()

        if self.imageFrameOnScreen.maxX < currentIndicatorBounds.maxX {
            let dx = currentIndicatorBounds.maxX - self.imageFrameOnScreen.maxX
            self.imageView.center.x += dx
            self.imageFrameOnScreen.origin.x += dx
        }

        if self.imageFrameOnScreen.minX > currentIndicatorBounds.minX {
            let dx = currentIndicatorBounds.minX - self.imageFrameOnScreen.minX
            self.imageView.center.x += dx
            self.imageFrameOnScreen.origin.x += dx
        }

        if self.imageFrameOnScreen.maxY < currentIndicatorBounds.maxY {
            let dy = currentIndicatorBounds.maxY - self.imageFrameOnScreen.maxY
            self.imageView.center.y += dy
            self.imageFrameOnScreen.origin.y += dy
        }

        if self.imageFrameOnScreen.minY > currentIndicatorBounds.minY {
            let dy = currentIndicatorBounds.minY - self.imageFrameOnScreen.minY
            self.imageView.center.y += dy
            self.imageFrameOnScreen.origin.y += dy
        }

        self.updateImageFramePadding()

        self.imageView.transform = self.imageView.transform.scaledBy(x: scale, y: scale)
        self.fitCropBoundsOnImageFrameIfNeeded()

        self.cropLayerPinchGestureSender.scale = 1.0

        switch self.cropLayerPinchGestureSender.state {
        case .ended, .cancelled, .failed:
            var dx: CGFloat = 0
            var dy: CGFloat = 0
            var currentCropBounds = self.calcCurrentCropRect()
            if self.currentImageScale < 1.1 {
                self.cropLayerView.layer.mask = nil

                self.cropLayerView.layer.opacity = 0
                Edge.allCases.forEach { edge in
                    self.edgeIndicator[edge]?.alpha = 0
                }

                dx = self.imageView.center.x - self.cropLayerView.center.x
                dy = self.imageView.center.y - self.cropLayerView.center.y
                self.imageFrameOnScreen.origin.x -= dx
                self.imageFrameOnScreen.origin.y -= dy
                currentCropBounds.origin.x -= dx
                currentCropBounds.origin.y -= dy
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    UIView.animate(withDuration: self.defaultAnimateDuration) {
                        self.cropLayerView.layer.opacity = 1
                        Edge.allCases.forEach { edge in
                            self.edgeIndicator[edge]?.alpha = 1.0
                        }
                    }
                }
                self.updateImageFramePadding()

            }
            UIView.animate(withDuration: self.defaultAnimateDuration) {
                self.imageView.center.x -= dx
                self.imageView.center.y -= dy
            }
            self.drawCropTransparentPaths(bounds: currentCropBounds)

        default:
            break
        }
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

    @IBAction func imageRotationAction(_ sender: Any) {
        let radian: CGFloat = -.pi / 2
        self.imageFrameOnScreen = self.rotate90(bounds: self.imageFrameOnScreen)
        let resizedImageFrameOnScreen = self.resizeImageFitOnCropLayerView(imageSize: self.imageFrameOnScreen, needScaling: false)
        let imageViewScale = resizedImageFrameOnScreen.width / self.imageFrameOnScreen.width
        self.imageFrameOnScreen = resizedImageFrameOnScreen
        self.originImageFrameOnScreen = self.imageFrameOnScreen
        self.updateImageFramePadding()

        UIView.animate(withDuration: self.defaultAnimateDuration) {
            self.imageView.transform = self.imageView.transform
                .rotated(by: radian)
                .scaledBy(x: imageViewScale, y: imageViewScale)
            self.imageView.center = self.cropLayerView.center
            self.currentImageScale = 1
            self.fitCropBoundsOnImageFrameIfNeeded()
        }
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

        self.imageFrameOnScreen = self.resizeImageFitOnCropLayerView(imageSize: CGRect(origin: .zero, size: imageSize), needScaling: false)

        self.originImageFrameOnScreen = self.imageFrameOnScreen

        self.updateImageFramePadding()
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

    private func rotate90(bounds: CGRect) -> CGRect {
        let centerX: CGFloat = bounds.midX
        let centerY: CGFloat = bounds.midY
        let rotatedWidth: CGFloat = bounds.height
        let rotatedHeight: CGFloat = bounds.width
        let rotatedOriginX: CGFloat = centerX - rotatedWidth/2
        let rotatedOriginY: CGFloat = centerY - rotatedHeight/2
        return CGRect(origin: CGPoint(x: rotatedOriginX, y: rotatedOriginY), size: CGSize(width: rotatedWidth, height: rotatedHeight))
    }

    private func scalingBounds(bounds: CGRect, scale: CGFloat) -> CGRect {
        var originX = bounds.origin.x
        var originY = bounds.origin.y
        let scaledWidth = bounds.size.width * scale
        let scaledHeight = bounds.size.height * scale
        let dw = bounds.size.width * (scale - 1)
        let dh = bounds.size.height * (scale - 1)
        originX -= dw/2
        originY -= dh/2
        return CGRect(x: originX, y: originY, width: scaledWidth, height: scaledHeight)
    }

    private func resizeImageFitOnCropLayerView(imageSize: CGRect, needScaling: Bool) -> CGRect {
        var imageResize = CGRect.zero
        let viewSize = self.cropLayerView.frame.size
        if imageSize.width > imageSize.height {
            if imageSize.width / imageSize.height < viewSize.width / viewSize.height {
                imageResize.size.width = viewSize.height * imageSize.width / imageSize.height
                imageResize.size.height = viewSize.height
            }
            else if imageSize.width / imageSize.height > viewSize.width / viewSize.height {
                imageResize.size.width = viewSize.width
                imageResize.size.height = viewSize.width * imageSize.height / imageSize.width
            }
            else {
                imageResize.size.width = viewSize.width
                imageResize.size.height = viewSize.height
            }
        }
        else if imageSize.width < imageSize.height {
            if imageSize.height / imageSize.width < viewSize.height / viewSize.width {
                imageResize.size.width = viewSize.width
                imageResize.size.height = viewSize.width * imageSize.height / imageSize.width
            }
            else if imageSize.height / imageSize.width > viewSize.height / viewSize.width {
                imageResize.size.width = viewSize.height * imageSize.width / imageSize.height
                imageResize.size.height = viewSize.height
            }
            else {
                imageResize.size.width = viewSize.width
                imageResize.size.height = viewSize.height
            }
        }
        else {
            if viewSize.width > viewSize.height {
                imageResize.size.width = viewSize.height
                imageResize.size.height = viewSize.height
            }
            else if viewSize.width < viewSize.height {
                imageResize.size.width = viewSize.width
                imageResize.size.height = viewSize.width
            }
            else {
                imageResize.size.width = viewSize.width
                imageResize.size.height = viewSize.height
            }
        }

        if needScaling {
            let scale = imageResize.width / imageSize.width
            imageResize.origin = self.scalingBounds(bounds: imageSize, scale: scale).origin
        }
        else {
            imageResize.origin.x = (self.cropLayerView.frame.width - imageResize.width) / 2
            imageResize.origin.y = (self.cropLayerView.frame.height - imageResize.height) / 2
        }

        return imageResize
    }

    private func fitCropBoundsOnImageFrameIfNeeded() {
        var cropBounds = self.calcCurrentCropRect()

        if cropBounds.minX < self.imageFrameOnScreen.minX {
            cropBounds.origin.x = self.imageFrameOnScreen.origin.x
            cropBounds.size.width = cropBounds.maxX - self.imageFrameOnScreen.minX
        }

        if cropBounds.maxX > self.imageFrameOnScreen.maxX {
            cropBounds.size.width = self.imageFrameOnScreen.maxX - cropBounds.minX
        }

        if cropBounds.minY < self.imageFrameOnScreen.minY {
            cropBounds.origin.y = self.imageFrameOnScreen.origin.y
            cropBounds.size.height = cropBounds.maxY - self.imageFrameOnScreen.minY
        }

        if cropBounds.maxY > self.imageFrameOnScreen.maxY {
            cropBounds.size.height = self.imageFrameOnScreen.maxY - cropBounds.minY
        }

        self.drawCropTransparentPaths(bounds: cropBounds)
    }
}
