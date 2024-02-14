//
//  File.swift
//  
//
//  Created by Igor Parnadjiev on 8.2.24.
//

import UIKit
import SwiftUI
import GoogleMobileAds

struct BannerView: View, InsideAdCallbackDelegate {
    @State var height: CGFloat = 0
    @State var width: CGFloat = 0
    @Binding var insideAdCallback: InsideAdCallbackType
    var insideAdViewModel: InsideAdViewModel
    
    public var body: some View {
            BannerAd(insideAdViewModel: insideAdViewModel, parent: self)
                .frame(width: width, height: height, alignment: .trailing)
                .onAppear {
                    setFrame()
                }
    }
    
    func setFrame() {
        //Get the frame of the safe area
        let scenes = UIApplication.shared.connectedScenes
        let windowScenes = scenes.first as? UIWindowScene
        let safeAreaInsets = windowScenes?.windows.first(where: { $0.isKeyWindow })?.safeAreaInsets ?? .zero
        let frame = UIScreen.main.bounds.inset(by: safeAreaInsets)
        
        //Use the frame to determine the size of the ad
        let adSize = GADCurrentOrientationAnchoredAdaptiveBannerAdSizeWithWidth(frame.width)
        
        //Set the ads frame
        self.width = adSize.size.width
        self.height = adSize.size.height
    }
    
    func insideAdCallbackReceived(data: InsideAdCallbackType) {
        insideAdCallback = data
    }
}

struct BannerAd: UIViewControllerRepresentable {
    var insideAdViewModel: InsideAdViewModel
    let parent: BannerView
    
    func makeUIViewController(context: Context) -> BannerAdVC {
        return BannerAdVC(viewModel: insideAdViewModel, insideAdCallbackDelegate: parent)
    }

    func updateUIViewController(_ uiViewController: BannerAdVC, context: Context) {
        
    }
}

class BannerAdVC: UIViewController {
    var viewModel: InsideAdViewModel
    var insideAdCallbackDelegate: InsideAdCallbackDelegate
    var adSizes = [NSValue]()
    
    init(viewModel: InsideAdViewModel, insideAdCallbackDelegate: InsideAdCallbackDelegate) {
        self.viewModel = viewModel
        self.insideAdCallbackDelegate = insideAdCallbackDelegate
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    var bannerView: GAMBannerView = GAMBannerView(adSize: GADAdSizeFullBanner)

    override func viewDidLoad() {
       setupBannerView()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        loadBannerAd()
    }

    private func setupBannerView() {
        bannerView.adUnitID = viewModel.activeInsideAd?.url
               bannerView.rootViewController = self
               bannerView.delegate = self
               bannerView.adSizeDelegate = self
               bannerView.load(GADRequest())
    }

    private func loadBannerAd() {
        let frame = view.frame.inset(by: view.safeAreaInsets)
        let viewWidth = frame.size.width

        bannerView.adSize = GADCurrentOrientationAnchoredAdaptiveBannerAdSizeWithWidth(viewWidth)
        addValidSizesToBannerView()
        bannerView.validAdSizes = adSizes
        bannerView.load(GADRequest())
    }
    
    private func addValidSizesToBannerView() {
        if let sizes =  viewModel.activeInsideAd?.properties?.sizes {
            for size in sizes {
                let customSize = GADAdSizeFromCGSize(CGSize(width: size.width ?? 320, height: size.height ?? 50))
                adSizes.append(NSValueFromGADAdSize(customSize))
            }
        } else {
            adSizes.append(NSValueFromGADAdSize(GADAdSizeBanner))
        }
    }
}

extension BannerAdVC: GADBannerViewDelegate, GADAdSizeDelegate {
    func adView(_ bannerView: GADBannerView, willChangeAdSizeTo size: GADAdSize) {
        print("bannerViewDidRecordImpression willChangeAdSizeTo size: GADAdSize \(size)")
    }
    
    func bannerViewDidReceiveAd(_ bannerView: GADBannerView) {
        view.addSubview(bannerView)
        print("bannerViewDidReceiveAd")
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(viewModel.activeInsideAd?.properties?.durationInSeconds ?? 10)) {
            bannerView.removeFromSuperview()
            
        }
    }

    func bannerView(_ bannerView: GADBannerView, didFailToReceiveAdWithError error: Error) {
        insideAdCallbackDelegate.insideAdCallbackReceived(data: EventTypeHandler.convertErrorType(message: error.localizedDescription ))
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds((Int(viewModel.activeCampaign?.properties?.intervalInMinutes ?? "1") ?? 1 * 60) + (viewModel.activeInsideAd?.properties?.durationInSeconds ?? 1))) {
            NotificationCenter.post(name: .AdsContentView_startTimer)
            print("bannerViewErrorReceivedNewReqeustSent")
        }
    }

    func bannerViewDidRecordImpression(_ bannerView: GADBannerView) {
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds((Int(viewModel.activeCampaign?.properties?.intervalInMinutes ?? "1") ?? 1 * 60) + (viewModel.activeInsideAd?.properties?.durationInSeconds ?? 1))) {
            NotificationCenter.post(name: .AdsContentView_startTimer)
            print("bannerViewDidRecordImpression")
        }
    }

    func bannerViewWillPresentScreen(_ bannerView: GADBannerView) {
      print("bannerViewWillPresentScreen")
    }

    func bannerViewWillDismissScreen(_ bannerView: GADBannerView) {
      print("bannerViewWillDIsmissScreen")
    }

    func bannerViewDidDismissScreen(_ bannerView: GADBannerView) {
      print("bannerViewDidDismissScreen")
    }
}
