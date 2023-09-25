//
//  SwiftUIView.swift
//  wishkit-ios
//
//  Created by Martin Lasek on 9/15/23.
//  Copyright © 2023 Martin Lasek. All rights reserved.
//
#if os(iOS)
import SwiftUI
import WishKitShared
import Combine

extension ScrollView {
    func refreshableCompat(action: @escaping @Sendable () async -> Void) -> some View {
        if #available(iOS 15, *) {
            return self.refreshable(action: action)
        }

        return self
    }
}

struct WishlistViewIOS: View {

    @Environment(\.colorScheme)
    private var colorScheme

    @Environment (\.presentationMode)
    var presentationMode

    @State
    private var selectedWishState: WishState = .approved

    @ObservedObject
    var wishModel: WishModel

    @State
    var selectedWish: WishResponse? = nil

    private var isInTabBar: Bool {
        let rootViewController = if #available(iOS 15, *) {
            UIApplication
                .shared
                .connectedScenes
                .compactMap { ($0 as? UIWindowScene)?.keyWindow }
                .first?
                .rootViewController
        } else {
            UIApplication.shared.windows.first(where: \.isKeyWindow)?.rootViewController
        }

        return rootViewController is UITabBarController
    }

    private func getList() -> [WishResponse] {
        switch selectedWishState {
        case .approved:
            return wishModel.approvedWishlist
        case .implemented:
            return wishModel.implementedWishlist
        default:
            return []
        }
    }

    var body: some View {
        NavigationView {
            ZStack {
                ScrollView {
                    VStack {

                        if WishKit.config.buttons.segmentedControl.display == .show {
                            Spacer(minLength: 15)

                            SegmentedView(selectedWishState: $selectedWishState)
                                .frame(maxWidth: 200)
                        }

                        Spacer(minLength: 15)

                        ForEach(getList()) { wish in
                            NavigationLink(destination: {
                                DetailWishView(wishResponse: wish, voteActionCompletion: wishModel.fetchList)
                            }, label: {
                                WKWishView(wishResponse: wish, voteActionCompletion: wishModel.fetchList)
                                    .padding(.all, 5)
                                    .frame(maxWidth: 700)
                            })
                        }
                    }
                }.refreshableCompat(action: wishModel.fetchList)
                .padding([.leading, .bottom, .trailing])
                .frame(maxWidth: .infinity)
            }
            .background(backgroundColor)
            .ignoresSafeArea(edges: [.leading, .bottom, .trailing])
            .navigationTitle(WishKit.config.localization.featureWishlist)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {

                ToolbarItem(placement: .topBarLeading) {
                    getRefreshButton()
                }

                ToolbarItem(placement: .topBarTrailing) {
                    if !isInTabBar {
                        Button(WishKit.config.localization.done) {
                            presentationMode.wrappedValue.dismiss()
                        }
                    }
                }
            }
        }.onAppear(perform: wishModel.fetchList)
    }

    func getRefreshButton() -> some View {
        if #unavailable(iOS 15) {
            return Button(action: wishModel.fetchList) {
                Image(systemName: "arrow.clockwise")
            }
        } else {
            return EmptyView()
        }
    }
}

extension WishlistViewIOS {
    var arrowColor: Color {
        let userUUID = UUIDManager.getUUID()
        if
            let selectedWish = selectedWish,
            selectedWish.votingUsers.contains(where: { user in user.uuid == userUUID })
        {
            return WishKit.theme.primaryColor
        }

        switch colorScheme {
        case .light:
            return WishKit.config.buttons.voteButton.arrowColor.light
        case .dark:
            return WishKit.config.buttons.voteButton.arrowColor.dark
        }
    }

    var textColor: Color {
        switch colorScheme {
        case .light:

            if let color = WishKit.theme.textColor {
                return color.light
            }

            return .black
        case .dark:
            if let color = WishKit.theme.textColor {
                return color.dark
            }

            return .white
        }
    }

    var cellBackgroundColor: Color {
        switch colorScheme {
        case .light:

            if let color = WishKit.theme.secondaryColor {
                return color.light
            }

            return PrivateTheme.elementBackgroundColor.light
        case .dark:
            if let color = WishKit.theme.secondaryColor {
                return color.dark
            }

            return PrivateTheme.elementBackgroundColor.dark
        }
    }

    var backgroundColor: Color {
        switch colorScheme {
        case .light:
            if let color = WishKit.theme.tertiaryColor {
                return color.light
            }

            return PrivateTheme.systemBackgroundColor.light
        case .dark:
            if let color = WishKit.theme.tertiaryColor {
                return color.dark
            }

            return PrivateTheme.systemBackgroundColor.dark
        }
    }
}
#endif
