import Quick
import Nimble
import Nimble_Snapshots
import UIKit
import Interstellar
import Forgeries
import OCMock
import Mantle
import ISO8601DateFormatter
@testable
import Artsy


let pendingBidder = try! Bidder(dictionary: ["qualifiedForBidding": false, "saleRequiresBidderApproval": true, "bidderID": "123456"], error: Void())
let qualifiedBidder = try! Bidder(dictionary: ["qualifiedForBidding": true, "saleRequiresBidderApproval": true, "bidderID": "123456"], error: Void())


var dateMock: AnyObject?
var systemDateMock: AnyObject?

func freezeTime(_ now: Date = Date(), work: () -> ()) {
    freezeTime(now)
    work()
    unfreezeTime()
}

func freezeTime(_ now: Date = Date()) {
    dateMock = ARTestContext.freezeTime(now)
    systemDateMock = ARTestContext.freezeSystemTime(now)
}

func unfreezeTime() {
    dateMock?.stopMocking()
    systemDateMock?.stopMocking()
}

class AuctionViewControllerTests: QuickSpec {
    override func spec() {
        var sale: Sale!
        var saleViewModel: Test_SaleViewModel!
        var dateMock: OCMockObject!

        sharedExamples("auctions view controller registration status") { (context: SharedExampleContext) in
            var horizontalSizeClass: UIUserInterfaceSizeClass!
            var device: ARDeviceType!

            beforeEach {
                let now = NSDate()
                let endTime = now.dateByAddingTimeInterval(3600.9) // 0.9 is to cover the possibility a clock tick happens between this line and the next.
                dateMock = ARTestContext.freezeTime(now)

                sale = try! Sale(dictionary: ["saleID": "the-tada-sale", "name": "The 🎉 Sale", "endDate": endTime], error: Void())
                saleViewModel = Test_SaleViewModel(sale: sale, saleArtworks: [], bidders: [])

                horizontalSizeClass = UIUserInterfaceSizeClass(rawValue: context()["horizontalSizeClass"] as! Int)
                device = ARDeviceType(rawValue: context()["device"] as! Int)
            }

            afterEach {
                dateMock.stopMocking()
            }

            it("looks good without a registration status") {
                let subject = AuctionViewController(saleID: sale.saleID)
                subject.allowAnimations = false
                subject.networkModel = Test_AuctionNetworkModel(saleViewModel: saleViewModel)
                subject.stubHorizontalSizeClass(horizontalSizeClass)

                ARTestContext.useDevice(device) {
                    expect(subject).to( haveValidSnapshot(usesDrawRect: true) )
                }
            }

            it("looks good when registration status changes") {
                let subject = AuctionViewController(saleID: sale.saleID)
                subject.allowAnimations = false
                let networkModel = Test_AuctionNetworkModel(saleViewModel: saleViewModel)
                subject.networkModel = networkModel

                ARTestContext.useDevice(device) {
                    // Must load view within context of device, since the iPad-specific layout will cause a throw exception on iPhone.
                    subject.stubHorizontalSizeClass(horizontalSizeClass)
                    subject.loadViewProgrammatically()

                    saleViewModel.stubbedAuctionState.insert(.UserIsRegistered)
                    NSNotificationCenter.defaultCenter().postNotificationName(ARAuctionArtworkRegistrationUpdatedNotification, object: nil)

                    expect(subject).to( haveValidSnapshot(usesDrawRect: true) )
                }
            }

            it("looks good when registereed") {
                let subject = AuctionViewController(saleID: sale.saleID)
                subject.allowAnimations = false
                subject.networkModel = Test_AuctionNetworkModel(saleViewModel: saleViewModel, bidders: [qualifiedBidder])
                saleViewModel.stubbedAuctionState.insert(.UserIsRegistered)
                subject.stubHorizontalSizeClass(horizontalSizeClass)

                ARTestContext.useDevice(device) {
                    expect(subject).to( haveValidSnapshot(usesDrawRect: true) )
                }
            }

            it("looks good when not logged in") {
                let subject = AuctionViewController(saleID: sale.saleID)
                subject.allowAnimations = false
                subject.networkModel = Test_AuctionNetworkModel(saleViewModel: saleViewModel)
                subject.stubHorizontalSizeClass(horizontalSizeClass)

                ARTestContext.useDevice(device) {
                    expect(subject).to( haveValidSnapshot(usesDrawRect: true) )
                }
            }

            it("looks good when not registered") {
                let subject = AuctionViewController(saleID: sale.saleID)
                subject.allowAnimations = false
                subject.networkModel = Test_AuctionNetworkModel(saleViewModel: saleViewModel)
                subject.stubHorizontalSizeClass(horizontalSizeClass)

                ARTestContext.useDevice(device) {
                    expect(subject).to( haveValidSnapshot(usesDrawRect: true) )
                }
            }

            it("looks good when sorting by Artist A-Z") {
                let subject = AuctionViewController(saleID: sale.saleID)
                subject.allowAnimations = false
                saleViewModel.stubbedAuctionState.insert(.UserIsRegistered)
                subject.networkModel = Test_AuctionNetworkModel(saleViewModel: saleViewModel, bidders: [qualifiedBidder])

                // Need to use the device when stubbing to use proper screen size.
                ARTestContext.useDevice(device) {
                    subject.stubHorizontalSizeClass(horizontalSizeClass)
                    subject.loadViewProgrammatically() // We need to load the view so it has a view model before calling defaultRefineSettings()
                    subject.refineSettings = subject.defaultRefineSettings().refineSettingsWithSelectedIndexPath(NSIndexPath.init(forRow: 1, inSection: 0))
                    expect(subject).to( haveValidSnapshot(usesDrawRect: true) )
                }

            }

            it("looks good when filtering based on price") {
                let subject = AuctionViewController(saleID: sale.saleID)
                subject.allowAnimations = false
                saleViewModel.stubbedAuctionState.insert(.UserIsRegistered)
                subject.networkModel = Test_AuctionNetworkModel(saleViewModel: saleViewModel, bidders: [qualifiedBidder])

                // Need to use the device when stubbing to use proper screen size.
                ARTestContext.useDevice(device) {
                    subject.stubHorizontalSizeClass(horizontalSizeClass)
                    subject.loadViewProgrammatically() // We need to load the view so it has a view model before calling defaultRefineSettings()
                    subject.refineSettings = subject.defaultRefineSettings().refineSettingsWithPriceRange((min: 1000, max: 1000_000))
                    expect(subject).to( haveValidSnapshot(usesDrawRect: true) )
                }

            }

            it("looks good when sorting by Artist A-Z and filtering based on price") {
                let subject = AuctionViewController(saleID: sale.saleID)
                subject.allowAnimations = false
                saleViewModel.stubbedAuctionState.insert(.UserIsRegistered)
                subject.networkModel = Test_AuctionNetworkModel(saleViewModel: saleViewModel, bidders: [qualifiedBidder])

                // Need to use the device when stubbing to use proper screen size.
                ARTestContext.useDevice(device) {
                    subject.stubHorizontalSizeClass(horizontalSizeClass)
                    subject.loadViewProgrammatically() // We need to load the view so it has a view model before calling defaultRefineSettings()
                    subject.refineSettings = subject.defaultRefineSettings().refineSettingsWithSelectedIndexPath(NSIndexPath(forRow: 1, inSection: 0)).refineSettingsWithPriceRange((min: 1000_000, max: 1000_000_000_000))
                    expect(subject).to( haveValidSnapshot(usesDrawRect: true) )
                }
            }

            describe("sorting") {
                var subject: AuctionViewController!

                beforeEach {
                    saleViewModel = Test_SaleViewModel(sale: sale, saleArtworks: [
                        test_saleArtworkWithLotNumber(1, artistName: "Ash", bidCount: 0, highestBidCents: 100_00),
                        test_saleArtworkWithLotNumber(2, artistName: "Orta", bidCount: 4, highestBidCents: 1000_00),
                        test_saleArtworkWithLotNumber(3, artistName: "Sarah", bidCount: 2, highestBidCents: 50_00),
                        test_saleArtworkWithLotNumber(4, artistName: "Eloy", bidCount: 17, highestBidCents: 1000_000_00),
                        test_saleArtworkWithLotNumber(5, artistName: "Maxim", bidCount: 6, highestBidCents: 5011_00),
                    ], bidders: [qualifiedBidder])
                    saleViewModel.stubbedAuctionState.insert(.UserIsRegistered)

                    subject = AuctionViewController(saleID: sale.saleID)
                    subject.allowAnimations = false
                    subject.networkModel = Test_AuctionNetworkModel(saleViewModel: saleViewModel, bidders: [qualifiedBidder])
                }


                it("looks good with a changed number of refined lots") {
                    // Need to use the device when stubbing to use proper screen size.
                    ARTestContext.useDevice(device) {
                        subject.stubHorizontalSizeClass(horizontalSizeClass)
                        subject.loadViewProgrammatically() // We need to load the view so it has a view model before calling defaultRefineSettings()
                        subject.refineSettings = subject.defaultRefineSettings().refineSettingsWithPriceRange((min: 2_000_00, max: 3_000_00)) // Outside the sale artworks' estimates.
                        expect(subject).to( haveValidSnapshot(usesDrawRect: true) )
                    }
                }

                it("sorts by lot number") {
                    // Need to use the device when stubbing to use proper screen size.
                    ARTestContext.useDevice(device) {
                        subject.stubHorizontalSizeClass(horizontalSizeClass)
                        subject.loadViewProgrammatically() // We need to load the view so it has a view model before calling defaultRefineSettings()
                        subject.refineSettings = subject.defaultRefineSettings().refineSettingsWithSelectedIndexPath(NSIndexPath.init(forRow: 0, inSection: 0))
                        expect(subject).to( haveValidSnapshot(usesDrawRect: true) )
                    }
                }

                it("sorts by artist name") {
                    // Need to use the device when stubbing to use proper screen size.
                    ARTestContext.useDevice(device) {
                        subject.stubHorizontalSizeClass(horizontalSizeClass)
                        subject.loadViewProgrammatically() // We need to load the view so it has a view model before calling defaultRefineSettings()
                        subject.refineSettings = subject.defaultRefineSettings().refineSettingsWithSelectedIndexPath(NSIndexPath.init(forRow: 1, inSection: 0))
                        expect(subject).to( haveValidSnapshot(usesDrawRect: true) )
                    }
                }

                it("sorts by most bids") {
                    // Need to use the device when stubbing to use proper screen size.
                    ARTestContext.useDevice(device) {
                        subject.stubHorizontalSizeClass(horizontalSizeClass)
                        subject.loadViewProgrammatically() // We need to load the view so it has a view model before calling defaultRefineSettings()
                        subject.refineSettings = subject.defaultRefineSettings().refineSettingsWithSelectedIndexPath(NSIndexPath.init(forRow: 3, inSection: 0))
                        expect(subject).to( haveValidSnapshot(usesDrawRect: true) )
                    }
                }

                it("sorts by least bids") {
                    // Need to use the device when stubbing to use proper screen size.
                    ARTestContext.useDevice(device) {
                        subject.stubHorizontalSizeClass(horizontalSizeClass)
                        subject.loadViewProgrammatically() // We need to load the view so it has a view model before calling defaultRefineSettings()
                        subject.refineSettings = subject.defaultRefineSettings().refineSettingsWithSelectedIndexPath(NSIndexPath.init(forRow: 2, inSection: 0))
                        expect(subject).to( haveValidSnapshot(usesDrawRect: true) )
                    }
                }

                it("sorts by highest bid") {
                    // Need to use the device when stubbing to use proper screen size.
                    ARTestContext.useDevice(device) {
                        subject.stubHorizontalSizeClass(horizontalSizeClass)
                        subject.loadViewProgrammatically() // We need to load the view so it has a view model before calling defaultRefineSettings()
                        subject.refineSettings = subject.defaultRefineSettings().refineSettingsWithSelectedIndexPath(NSIndexPath.init(forRow: 4, inSection: 0))
                        expect(subject).to( haveValidSnapshot(usesDrawRect: true) )
                    }
                }

                it("sorts by lowest bid") {
                    // Need to use the device when stubbing to use proper screen size.
                    ARTestContext.useDevice(device) {
                        subject.stubHorizontalSizeClass(horizontalSizeClass)
                        subject.loadViewProgrammatically() // We need to load the view so it has a view model before calling defaultRefineSettings()
                        subject.refineSettings = subject.defaultRefineSettings().refineSettingsWithSelectedIndexPath(NSIndexPath.init(forRow: 5, inSection: 0))
                        expect(subject).to( haveValidSnapshot(usesDrawRect: true) )
                    }
                }
            }
        }


        describe("regular horizontal size class ") {
            itBehavesLike("auctions view controller registration status") {
                return ["horizontalSizeClass": UIUserInterfaceSizeClass.Regular.rawValue, "device": ARDeviceType.Pad.rawValue] as NSDictionary
            }
        }

        describe("compact horizontal size class") {
            itBehavesLike("auctions view controller registration status") {
                return ["horizontalSizeClass": UIUserInterfaceSizeClass.Compact.rawValue, "device": ARDeviceType.Phone6.rawValue] as NSDictionary
            }
        }


        it("handles showing information for upcoming auctions with no sale artworks") {
            let exact_now = ISO8601DateFormatter().dateFromString("2025-11-24T10:00:00+00:00")!
            let start = exact_now.dateByAddingTimeInterval(3600.9)
            let end = exact_now.dateByAddingTimeInterval(3700.9)

            freezeTime(exact_now) {
                sale = try! Sale(dictionary: [
                    "saleID": "the-tada-sale", "name": "The 🎉 Sale",
                    "saleDescription": "This is a description",
                    "startDate": start, "endDate": end], error: Void())
                saleViewModel = Test_SaleViewModel(sale: sale, saleArtworks: [], bidders: [])

                let subject = AuctionViewController(saleID: sale.saleID)
                subject.allowAnimations = false
                subject.networkModel = Test_AuctionNetworkModel(saleViewModel: saleViewModel)

                expect(subject).to( haveValidSnapshot(usesDrawRect: true) )
            }
        }

        it("handles showing information for upcoming auctions with long names with no sale artworks") {
            let exact_now = ISO8601DateFormatter().dateFromString("2025-11-24T10:00:00+00:00")!
            let start = exact_now.dateByAddingTimeInterval(3600.9)
            let end = exact_now.dateByAddingTimeInterval(3700.9)

            ARTestContext.freezeTime(exact_now) {
                sale = try! Sale(dictionary: [
                    "saleID": "the-tada-sale", "name": "The Sale With The Really Really Looooong Name",
                    "saleDescription": "This is a description",
                    "startDate": start, "endDate": end], error: Void())
                saleViewModel = Test_SaleViewModel(sale: sale, saleArtworks: [], bidders: [])

                let subject = AuctionViewController(saleID: sale.saleID)
                subject.allowAnimations = false
                subject.networkModel = Test_AuctionNetworkModel(saleViewModel: saleViewModel)

                expect(subject).to( haveValidSnapshot(usesDrawRect: true) )
            }
        }

        it("looking correct when an auction is closed") {
            let exact_now_past = ISO8601DateFormatter().dateFromString("2015-11-24T10:00:00+00:00")!
            let start = exact_now_past.dateByAddingTimeInterval(3600.9)
            let end = exact_now_past.dateByAddingTimeInterval(3700.9)

            sale = try! Sale(dictionary: [
                "saleID": "the-tada-sale", "name": "The 🎉 Sale",
                "saleDescription": "This is a description",
                "startDate": start, "endDate": end], error: Void())
            saleViewModel = Test_SaleViewModel(sale: sale, saleArtworks: [], bidders: [])

            let subject = AuctionViewController(saleID: sale.saleID)
            subject.allowAnimations = false
            subject.networkModel = Test_AuctionNetworkModel(saleViewModel: saleViewModel)

            expect(subject).to( haveValidSnapshot(usesDrawRect: true) )
        }

        it("uses the correct settings when auction is closed") {
            let exact_now_past = ISO8601DateFormatter().dateFromString("2015-11-24T10:00:00+00:00")!
            let start = exact_now_past.dateByAddingTimeInterval(3600.9)
            let end = exact_now_past.dateByAddingTimeInterval(3700.9)

            sale = try! Sale(dictionary: [
                "saleID": "the-tada-sale", "name": "The 🎉 Sale",
                "saleDescription": "This is a description",
                "startDate": start, "endDate": end], error: Void())
            saleViewModel = Test_SaleViewModel(sale: sale, saleArtworks: [], bidders: [])

            let subject = AuctionViewController(saleID: sale.saleID)
            subject.allowAnimations = false
            subject.networkModel = Test_AuctionNetworkModel(saleViewModel: saleViewModel)
            subject.saleViewModel = saleViewModel

            expect(subject.defaultRefineSettings().numberOfRowsInSection(0)).to(equal(2))
        }

        it("uses the correct settings when auction is open") {
            let exact_now = ISO8601DateFormatter().dateFromString("2025-11-24T10:00:00+00:00")!
            let start = exact_now.dateByAddingTimeInterval(3600.9)
            let end = exact_now.dateByAddingTimeInterval(3700.9)

            freezeTime(exact_now) {
                sale = try! Sale(dictionary: [
                    "saleID": "the-tada-sale", "name": "The 🎉 Sale",
                    "saleDescription": "This is a description",
                    "startDate": start, "endDate": end], error: Void())
                saleViewModel = Test_SaleViewModel(sale: sale, saleArtworks: [], bidders: [])

                let subject = AuctionViewController(saleID: sale.saleID)
                subject.allowAnimations = false
                subject.networkModel = Test_AuctionNetworkModel(saleViewModel: saleViewModel)
                subject.saleViewModel = saleViewModel

                expect(subject.defaultRefineSettings().numberOfRowsInSection(0)).to(equal(6))
            }
        }

        it("shows a message about an upcoming live auction") {
            let exact_now = ISO8601DateFormatter().dateFromString("2025-11-24T10:00:00+00:00")!
            let start = exact_now.dateByAddingTimeInterval(-3600.9)
            let liveStart = exact_now.dateByAddingTimeInterval(1650.9)
            let end = exact_now.dateByAddingTimeInterval(3700.9)

            ARTestContext.freezeTime(exact_now) {
                sale = try! Sale(dictionary: [
                    "saleID": "the-tada-sale", "name": "The 🎉 Sale",
                    "saleDescription": "This is a description",
                    "startDate": start, "endDate": end, "liveAuctionStartDate": liveStart], error: Void())
                saleViewModel = Test_SaleViewModel(sale: sale, saleArtworks: [], bidders: [])

                let subject = AuctionViewController(saleID: sale.saleID)
                subject.allowAnimations = false
                subject.networkModel = Test_AuctionNetworkModel(saleViewModel: saleViewModel)

                expect(subject).to( haveValidSnapshot(usesDrawRect: true) )
            }
        }

        it("wraps auction name correctly") {
            let now = NSDate()
            let start = now.dateByAddingTimeInterval(-3600.9)
            let end = now.dateByAddingTimeInterval(3600.9) // 0.9 is to cover the possibility a clock tick happens between this line and the next.

            freezeTime(now) {
                sale = try! Sale(dictionary: [
                    "saleID": "the-testing-sale",
                    "name": "Ash Furrow Auctions: Nerds Collect Art",
                    "saleDescription": "This is a description",
                    "startDate": start, "endDate": end], error: Void())
                saleViewModel = Test_SaleViewModel(sale: sale, saleArtworks: [], bidders: [])

                let subject = AuctionViewController(saleID: sale.saleID)
                subject.stubHorizontalSizeClass(.Compact)
                subject.allowAnimations = false
                subject.networkModel = Test_AuctionNetworkModel(saleViewModel: saleViewModel)

                expect(subject).to( haveValidSnapshot(usesDrawRect: true) )
            }
        }
    }
}

class Test_SaleViewModel: SaleViewModel {
    var stubbedAuctionState: ARAuctionState = .Default
    override var currencySymbol: String { return "$" }
    override var auctionState: ARAuctionState { return stubbedAuctionState }
}

class Test_AuctionNetworkModel: AuctionNetworkModelType {
    let saleViewModel: SaleViewModel
    var bidders: [Bidder]

    init(saleViewModel: SaleViewModel, bidders: [Bidder] = []) {
        self.saleViewModel = saleViewModel
        self.bidders = bidders
    }

    func fetch() -> Observable<Result<SaleViewModel>> {
        return Observable(.Success(saleViewModel))
    }

    func fetchBidders() -> Observable<Result<[Bidder]>> {
        return Observable(.Success(bidders))
    }
}

func test_saleArtworkWithLotNumber(_ lotNumber: Int, artistName: String, bidCount: Int, highestBidCents: Int) -> SaleArtwork {

    let artistJSON: NSDictionary = [
        "id": "artist_id",
        "name": artistName,
        "sortable_id": artistName
    ]
    let imagesJSON: NSArray = [
        [
            "id": "image_1_id",
            "is_default": true,
            "image_url": "http://example.com/:version.jpg",
            "image_versions": ["large"],
            "aspect_ratio": 1.5
        ]
    ]
    let artworkJSON: NSDictionary = [
        "id": "artwork_id",
        "artist": artistJSON,
        "title": "roly poly",
        "images": imagesJSON,
    ]
    let saleArtwork = SaleArtwork(JSON:
        [
            "id": "sale",
            "artwork": artworkJSON,
            "lot_number": lotNumber,
            "bidder_positions_count": bidCount,
            "low_estimate_cents": 1_000_000_00,
            "highest_bid": ["id": "bid-id", "amount_cents": highestBidCents],
            "opening_bid_cents": 100_00,
            "symbol": "$"
        ]
    )

    return saleArtwork
}
