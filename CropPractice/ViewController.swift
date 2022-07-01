//
//  ViewController.swift
//  CropPractice
//
//  Created by Houston Park on 2022/06/10.
//

import UIKit

/*
class ViewController: UIViewController {

    enum Edge: CaseIterable {
        case topLeft
        case topRight
        case bottomLeft
        case bottomRight
    }

    typealias Coordinate = (x: CGFloat, y: CGFloat)

    private var edgePoints: [Edge: Coordinate] = [
        .topLeft: (0, 0),
        .topRight: (0, 0),
        .bottomLeft: (0, 0),
        .bottomRight: (0, 0)
    ]

    private var edgeIndicator: [Edge: CropIndicatorView] = [
        .topLeft: CropIndicatorView().loadView().rotate(angle: 180),
        .topRight: CropIndicatorView().loadView().rotate(angle: 270),
        .bottomLeft: CropIndicatorView().loadView().rotate(angle: 90),
        .bottomRight: CropIndicatorView().loadView()
    ]

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var cropBackgroundView: UIView!

    override func viewDidLoad() {
        super.viewDidLoad()
        let rect = CGRect(x: 75, y: 300, width: self.view.bounds.width - 150, height: 100)
        self.createCropBounds(bounds: rect)
        self.updateEdgePoints(bounds: rect)
        self.addGestureAction()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.createEdgeIndicatorLayout()
    }

    @objc func dragTopLeft(sender: UIPanGestureRecognizer) {
        guard let indicatorView = self.edgeIndicator[.topLeft] else { return }

        let transition = sender.translation(in: indicatorView)
        let changedX = indicatorView.center.x - transition.x
        let changedY = indicatorView.center.y - transition.y
        var currentCropRect = self.calcCurrentCropRect()
        guard changedX < currentCropRect.maxX - 30, changedY < currentCropRect.maxY - 30, changedX <= self.view.bounds.maxX - 10, changedX >= 10, changedY <= self.view.bounds.maxY - 10, changedY >= 10 else { return }
        self.edgePoints[.topLeft] = (changedX, changedY)
        self.edgePoints[.topRight] = (self.edgePoints[.topRight]!.x, changedY)
        self.edgePoints[.bottomLeft] = (changedX, self.edgePoints[.bottomLeft]!.y)
        currentCropRect = self.calcCurrentCropRect()
        self.createCropBounds(bounds: currentCropRect)
        self.updateEdgeIndicatorLayout()

        sender.setTranslation(.zero, in: indicatorView)
    }

    @objc func dragTopRight(sender: UIPanGestureRecognizer) {
        guard let indicatorView = self.edgeIndicator[.topRight] else { return }

        let transition = sender.translation(in: indicatorView)
        let changedX = indicatorView.center.x + transition.y
        let changedY = indicatorView.center.y - transition.x
        var currentCropRect = self.calcCurrentCropRect()
        guard changedX > currentCropRect.minX + 30, changedY < currentCropRect.maxY - 30, changedX <= self.view.bounds.maxX - 10, changedX >= 10, changedY <= self.view.bounds.maxY - 10, changedY >= 10 else { return }
        self.edgePoints[.topRight] = (changedX, changedY)
        self.edgePoints[.topLeft] = (self.edgePoints[.topLeft]!.x, changedY)
        self.edgePoints[.bottomRight] = (changedX, self.edgePoints[.bottomRight]!.y)
        currentCropRect = self.calcCurrentCropRect()
        self.createCropBounds(bounds: currentCropRect)
        self.updateEdgeIndicatorLayout()

        sender.setTranslation(.zero, in: indicatorView)
    }

    @objc func dragBottomLeft(sender: UIPanGestureRecognizer) {
        guard let indicatorView = self.edgeIndicator[.bottomLeft] else { return }

        let transition = sender.translation(in: indicatorView)
        let changedX = indicatorView.center.x - transition.y
        let changedY = indicatorView.center.y + transition.x
        var currnetCropRect = self.calcCurrentCropRect()
        guard changedX < currnetCropRect.maxX - 30, changedY > currnetCropRect.minY + 30, changedX <= self.view.bounds.maxX - 10, changedX >= 10, changedY <= self.view.bounds.maxY - 10, changedY >= 10 else { return }
        self.edgePoints[.bottomLeft] = (changedX, changedY)
        self.edgePoints[.bottomRight] = (self.edgePoints[.bottomRight]!.x, changedY)
        self.edgePoints[.topLeft] = (changedX, self.edgePoints[.topLeft]!.y)
        currnetCropRect = self.calcCurrentCropRect()
        self.createCropBounds(bounds: currnetCropRect)
        self.updateEdgeIndicatorLayout()

        sender.setTranslation(.zero, in: indicatorView)
    }

    @objc func dragBottomRight(sender: UIPanGestureRecognizer) {
        guard let indicatorView = self.edgeIndicator[.bottomRight] else { return }

        let transition = sender.translation(in: indicatorView)
        let changedX = indicatorView.center.x + transition.x
        let changedY = indicatorView.center.y + transition.y
        var currentCropRect = self.calcCurrentCropRect()
        guard changedX > currentCropRect.minX + 30, changedY > currentCropRect.minY + 30, changedX <= self.view.bounds.maxX - 10, changedX >= 10, changedY <= self.view.bounds.maxY - 10, changedY >= 10 else { return }
        self.edgePoints[.bottomRight] = (changedX, changedY)
        self.edgePoints[.bottomLeft] = (self.edgePoints[.bottomLeft]!.x, changedY)
        self.edgePoints[.topRight] = (changedX, self.edgePoints[.topRight]!.y)
        currentCropRect = self.calcCurrentCropRect()
        self.createCropBounds(bounds: currentCropRect)
        self.updateEdgeIndicatorLayout()

        sender.setTranslation(.zero, in: indicatorView)
    }

    @objc func dragCropRect(sender: UIPanGestureRecognizer) {
        let transition = sender.translation(in: self.cropBackgroundView)
        guard let minPoint = self.edgePoints[.topLeft] else { return }
        guard let maxPoint = self.edgePoints[.bottomRight] else { return }
        let changedMinX = minPoint.x + transition.x
        let changedMaxX = maxPoint.x + transition.x
        let changedMinY = minPoint.y + transition.y
        let changedMaxY = maxPoint.y + transition.y
        //guard changedMinX > 10, changedMinY > 10, changedMaxX < self.view.bounds.maxX - 10, changedMaxY < self.view.bounds.maxY - 10 else { return }
        ViewController.Edge.allCases.forEach { edge in
            self.edgePoints[edge] = (self.edgePoints[edge]!.x + transition.x, self.edgePoints[edge]!.y + transition.y)
        }
        let currentCropRect = self.calcCurrentCropRect()
        self.createCropBounds(bounds: currentCropRect)
        self.updateEdgeIndicatorLayout()

        sender.setTranslation(.zero, in: self.cropBackgroundView)
    }
}

extension ViewController {

    private func addGestureAction() {
        ViewController.Edge.allCases.forEach { edge in
            guard let indicatorView = edgeIndicator[edge] else { return }
            switch edge {
            case .topRight:
                let gesture = UIPanGestureRecognizer(target: self, action: #selector(self.dragTopRight(sender:)))
                indicatorView.addGestureRecognizer(gesture)
            case .topLeft:
                let gesture = UIPanGestureRecognizer(target: self, action: #selector(self.dragTopLeft(sender:)))
                indicatorView.addGestureRecognizer(gesture)
            case .bottomLeft:
                let gesture = UIPanGestureRecognizer(target: self, action: #selector(self.dragBottomLeft(sender:)))
                indicatorView.addGestureRecognizer(gesture)
            case .bottomRight:
                let gesture = UIPanGestureRecognizer(target: self, action: #selector(self.dragBottomRight(sender:)))
                indicatorView.addGestureRecognizer(gesture)
            }
        }
        let gesture = UIPanGestureRecognizer(target: self, action: #selector(self.dragCropRect(sender:)))
        self.cropBackgroundView.addGestureRecognizer(gesture)
    }

    private func createCropBounds(bounds: CGRect) {
        let cropBackgroundBounds = self.cropBackgroundView.bounds

        let path = UIBezierPath()
        let pathRect = UIBezierPath(rect: cropBackgroundBounds)
        let pathSmallRect = UIBezierPath(rect: bounds)

        path.append(pathRect)
        path.append(pathSmallRect.reversing())

        let layer = CAShapeLayer()
        layer.path = path.cgPath
        self.cropBackgroundView.layer.mask = layer
    }

    private func updateEdgePoints(bounds: CGRect) {
        self.edgePoints[.topLeft] = (bounds.minX, bounds.minY)
        self.edgePoints[.topRight] = (bounds.maxX, bounds.minY)
        self.edgePoints[.bottomLeft] = (bounds.minX, bounds.maxY)
        self.edgePoints[.bottomRight] = (bounds.maxX, bounds.maxY)
    }

    private func createEdgeIndicatorLayout() {
        ViewController.Edge.allCases.forEach { edge in
            guard let indicatorView = self.edgeIndicator[edge] else { return }
            guard let position = self.edgePoints[edge] else { return }
            self.cropBackgroundView.addSubview(indicatorView)
            indicatorView.widthAnchor.constraint(equalToConstant: 30).isActive = true
            indicatorView.heightAnchor.constraint(equalToConstant: 30).isActive = true
            indicatorView.centerXAnchor.constraint(equalTo: self.view.centerXAnchor, constant: position.x - self.view.center.x).isActive = true
            indicatorView.centerYAnchor.constraint(equalTo: self.view.centerYAnchor, constant: position.y - self.view.center.y).isActive = true
        }
    }

    private func updateEdgeIndicatorLayout() {
        ViewController.Edge.allCases.forEach { edge in
            guard let indicatorView = self.edgeIndicator[edge] else { return }
            guard let position = self.edgePoints[edge] else { return }
        }
    }

    private func calcCurrentCropRect() -> CGRect {
        return CGRect(x: self.edgePoints[.topLeft]?.x ?? 0, y: self.edgePoints[.topLeft]?.y ?? 0, width: (self.edgePoints[.topRight]?.x ?? 0) - (self.edgePoints[.topLeft]?.x ?? 0), height: (self.edgePoints[.bottomLeft]?.y ?? 0) - (self.edgePoints[.topLeft]?.y ?? 0))
    }
}
*/
