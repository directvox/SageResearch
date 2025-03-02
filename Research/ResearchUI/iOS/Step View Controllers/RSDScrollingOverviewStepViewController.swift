//
//  RSDScrollingOverviewStepViewController.swift
//  ResearchUI (iOS)
//
//  Copyright © 2019 Sage Bionetworks. All rights reserved.
//
// Redistribution and use in source and binary forms, with or without modification,
// are permitted provided that the following conditions are met:
//
// 1.  Redistributions of source code must retain the above copyright notice, this
// list of conditions and the following disclaimer.
//
// 2.  Redistributions in binary form must reproduce the above copyright notice,
// this list of conditions and the following disclaimer in the documentation and/or
// other materials provided with the distribution.
//
// 3.  Neither the name of the copyright holder(s) nor the names of any contributors
// may be used to endorse or promote products derived from this software without
// specific prior written permission. No license is granted to the trademarks of
// the copyright holders even if such marks are included in this software.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
// ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE
// FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
// DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
// SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
// CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
// OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
// OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//

import UIKit

/// The scrolling overview step view controller is a custom subclass of the overview step view controller
/// that uses a scrollview to allow showing detailed overview instructions.
open class RSDScrollingOverviewStepViewController: RSDOverviewStepViewController {

    /// The label which tells the user about the icons. Typically displays
    /// "This is what you'll need".
    @IBOutlet
    open weak var iconViewLabel: UILabel!
    
    /// The constraint that sets the scroll bar's top background view's height.
    @IBOutlet
    open weak var scrollViewBackgroundHeightConstraint: NSLayoutConstraint!
    
    /// The constraint that sets the distance between the title and the image.
    @IBOutlet
    var titleTopConstraint: NSLayoutConstraint!
    
    /// The constraint that sets the distance between the icon images and their leading/trailing edge.
    @IBOutlet
    var iconImagesLeadingConstraint: NSLayoutConstraint!
    @IBOutlet
    var iconImagesTrailingConstraint: NSLayoutConstraint!
    
    /// The image views to display the icons on.
    @IBOutlet
    open var iconImages: [UIImageView]!
    
    /// The labels to display the titles of the icons on.
    @IBOutlet
    open var iconTitles: [UILabel]!
    
    /// The view that holds the icons.
    @IBOutlet
    open var iconHolder: UIView!
    
    /// The scroll view that contains the elements which scroll.
    @IBOutlet
    open var scrollView: UIScrollView!
    
    /// The constraint that sets the heigh of the learn more button.
    @IBOutlet
    var learnMoreHeightConstraint: NSLayoutConstraint!
    
    /// Overrides viewWillAppear to add an info button, display the icons, to save
    /// the current Date to UserDefaults, and to use the saved date to decide whether
    /// or not to show the full task info or an abbreviated screen.
    override open func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        

        if let overviewStep = self.step as? RSDOverviewStep,
            let icons = overviewStep.icons, icons.count > 0 {
        
            for idx in 0..<iconImages.count {
                let iconInfo = (idx < icons.count) ? icons[idx] : nil
                iconImages[idx].image = iconInfo?.icon?.embeddedImage()
                iconTitles[idx].text = iconInfo?.title
            }
            
            // TODO: syoung 03/12/2019 Change to using a collection view.
            // When there are only 2 icons, employ this hack to center them evenly
            if (icons.count == 2) {
                let removeIdx = 2
                
                // Adjust margin factor to give smaller screens more room
                let cellWidth = self.view.frame.size.width / CGFloat(iconImages.count)
                let marginFactor: CGFloat = (cellWidth < 125) ? 3.0 : 2.0
                
                // First, Adjust the leading/trailing spacing
                iconImagesLeadingConstraint.constant = cellWidth / marginFactor
                iconImagesTrailingConstraint.constant = cellWidth / marginFactor
                
                // Then, remove the third icon from the stack view
                iconImages[removeIdx].superview?.removeFromSuperview()
            }
        }
        else {
            self.iconViewLabel.removeFromSuperview()
            self.iconHolder.removeFromSuperview()
        }
        
        // Hide learn more action if it is not provided by the step json
        if self.stepViewModel.shouldHideAction(for: .navigation(.learnMore)) {
            self.learnMoreButton?.setTitle(nil, for: .normal)
            self.learnMoreButton?.isHidden = true
            self.learnMoreHeightConstraint.constant = 0
        }
        
        // Update the image placement constraint based on the status bar height.
        updateImagePlacementConstraints()
    }
    
    open override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        let shouldShowInfo = !(self.stepViewModel.rootPathComponent.shouldShowAbbreviatedInstructions ?? false)
        if shouldShowInfo {
            self._scrollToBottom()
            self._stopAnimating()
        } else if let titleLabel = self.stepTitleLabel {
            // We add a 30 pixel margin to the bottom of the title label so it isn't squished
            // up against the bottom of the scroll view.
            let frame = titleLabel.frame.offsetBy(dx: 0, dy: 30)
            // On the SE this fixes the title label being chopped off, on larger screens this is
            // expected to do nothing.
            self.scrollView.scrollRectToVisible(frame, animated: false)
        }
    }
    
    /// Sets the height of the scroll views top background view depending on
    /// the image placement type from this step.
    open func updateImagePlacementConstraints() {
        guard let placementType = self.imageTheme?.placementType else { return }
        let statusBarHeight = UIApplication.shared.statusBarFrame.height
        self.scrollViewBackgroundHeightConstraint.constant = (placementType == .topMarginBackground) ? statusBarHeight : CGFloat(0)
    }
    
    override open func setColorStyle(for placement: RSDColorPlacement, background: RSDColorTile) {
        super.setColorStyle(for: placement, background: background)
        
        if placement == .body {
            
            scrollView.backgroundColor = background.color
            iconViewLabel.text = Localization.localizedString("OVERVIEW_WHAT_YOU_NEED")
            iconViewLabel.textColor = self.designSystem.colorRules.textColor(on: background, for: .mediumHeader)
            iconViewLabel.font = self.designSystem.fontRules.font(for: .mediumHeader, compatibleWith: traitCollection)
            
            let textColor = self.designSystem.colorRules.textColor(on: background, for: .microHeader)
            let font = self.designSystem.fontRules.font(for: .microHeader, compatibleWith: traitCollection)
            iconTitles.forEach {
                $0.textColor = textColor
                $0.font = font
            }
        }
    }
    
    /// Stops the animation view from animating.
    private func _stopAnimating() {
        /// The image view that is used to show the animation.
        let animationView = (self.navigationHeader as? RSDStepHeaderView)?.imageView
        animationView?.stopAnimating()
    }
    
    // Makes the scroll view scroll all the way down.
    private func _scrollToBottom() {
        let frame = self.scrollView.convert(self.iconTitles[0].bounds, from: self.iconTitles[0])
        let shiftedFrame = frame.offsetBy(dx: 0, dy: 20)
        self.scrollView.scrollRectToVisible(shiftedFrame, animated: false)
    }
    
    // MARK: Initialization
    
    /// The default nib name to use when instantiating the view controller using `init(step:)`.
    override open class var nibName: String {
        return String(describing: RSDScrollingOverviewStepViewController.self)
    }
    
    /// The default bundle to use when instantiating the view controller using `init(step:)`.
    override open class var bundle: Bundle {
        return Bundle(for: RSDScrollingOverviewStepViewController.self)
    }

}
