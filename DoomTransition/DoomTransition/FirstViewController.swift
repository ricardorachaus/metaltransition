//
//  FirstViewController.swift
//  DoomTransition
//
//  Created by Ricardo Rachaus on 07/11/22.
//

import UIKit

class FirstViewController: UIViewController {

    let queue = DispatchQueue.main

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = UIColor(red: 0.2, green: 0.1, blue: 1, alpha: 1) // Blue
        navigationController?.delegate = self
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        queue.asyncAfter(deadline: .now() + 3) { [weak self] in
            self?.navigationController?.pushViewController(
                SecondViewController(),
                animated: true
            )
        }
    }

}

extension FirstViewController: UINavigationControllerDelegate {

    func navigationController(
        _ navigationController: UINavigationController,
        animationControllerFor operation: UINavigationController.Operation,
        from fromVC: UIViewController,
        to toVC: UIViewController
    ) -> UIViewControllerAnimatedTransitioning? {
        return DoomTransition()
    }

}
