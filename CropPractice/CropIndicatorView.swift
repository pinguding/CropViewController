//
//  CropIndicatorView.swift
//  CropPractice
//
//  Created by Houston Park on 2022/06/13.
//

import UIKit

class CropIndicatorView: UIView {

    func loadView() -> CropIndicatorView {
        let bundleName = Bundle(for: type(of: self))
        let nibName =  String(describing: type(of: self))
        let nib = UINib(nibName: nibName, bundle: bundleName)
        let view = nib.instantiate(withOwner: nil).first as! CropIndicatorView
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }

    func rotate(angle: CGFloat) -> Self {
        let radians = angle / 180 * CGFloat.pi
        let rotation = CGAffineTransform(rotationAngle: radians)
        self.transform = rotation
        return self
    }
}


