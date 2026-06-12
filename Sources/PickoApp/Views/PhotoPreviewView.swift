import PickoCore
import PickoPhotos
import SwiftUI
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

public struct PhotoPreviewView: View {
    private let asset: PhotoAsset
    @Bindable private var model: PickoAppModel
    @Environment(\.dismiss) private var dismiss
    @State private var thumbnailData: Data?
    @State private var scale: CGFloat = 1
    @State private var lastScale: CGFloat = 1
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero

    public init(asset: PhotoAsset, model: PickoAppModel) {
        self.asset = asset
        self.model = model
    }

    public var body: some View {
        NavigationStack {
            VStack(spacing: PickoDesign.Spacing.md) {
                Spacer(minLength: 0)

                previewImage
                    .scaleEffect(scale)
                    .offset(offset)
                    .gesture(magnificationGesture.simultaneously(with: dragGesture))
                    .onTapGesture(count: 2) {
                        resetZoom()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipped()
                    .accessibilityLabel("照片预览")

                HStack(spacing: PickoDesign.Spacing.md) {
                    Button {
                        model.keep(assetId: asset.id)
                        dismiss()
                    } label: {
                        Label(PickoCopy.Review.keep, systemImage: "star.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.plain)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .padding(.vertical, 14)
                    .background(PickoDesign.ColorToken.goldSoft, in: RoundedRectangle(cornerRadius: PickoDesign.Radius.lg))
                    .foregroundStyle(PickoDesign.ColorToken.primaryDeep)

                    Button {
                        model.preDelete(assetId: asset.id)
                        dismiss()
                    } label: {
                        Label(PickoCopy.Review.preDelete, systemImage: "tray.and.arrow.down")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.plain)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .padding(.vertical, 14)
                    .background(PickoDesign.ColorToken.coralDeep, in: RoundedRectangle(cornerRadius: PickoDesign.Radius.lg))
                    .foregroundStyle(PickoDesign.ColorToken.coral)
                }
                .padding(.horizontal, PickoDesign.Spacing.page)
            }
            .padding(.bottom, PickoDesign.Spacing.md)
            .navigationTitle("照片预览")
            .pickoInlineNavigationTitle()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(PickoCopy.Basket.cancelAction) {
                        dismiss()
                    }
                }
            }
            .pickoScreenBackground()
            .task(id: asset.id) {
                await loadThumbnail()
            }
        }
    }

    @ViewBuilder
    private var previewImage: some View {
        if let image = platformImage(from: thumbnailData) {
            image
                .resizable()
                .scaledToFit()
        } else {
            RoundedRectangle(cornerRadius: PickoDesign.Radius.xl)
                .fill(PickoDesign.ColorToken.surfaceLow)
                .overlay {
                    Image(systemName: "photo")
                        .font(.system(size: 64, weight: .semibold))
                        .foregroundStyle(PickoDesign.ColorToken.primary.opacity(0.58))
                }
                .aspectRatio(1, contentMode: .fit)
                .padding(PickoDesign.Spacing.page)
        }
    }

    private var magnificationGesture: some Gesture {
        MagnificationGesture()
            .onChanged { value in
                scale = max(1, min(lastScale * value, 5))
            }
            .onEnded { _ in
                lastScale = scale
                if scale == 1 {
                    offset = .zero
                    lastOffset = .zero
                }
            }
    }

    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                guard scale > 1 else {
                    return
                }
                offset = CGSize(
                    width: lastOffset.width + value.translation.width,
                    height: lastOffset.height + value.translation.height
                )
            }
            .onEnded { _ in
                lastOffset = offset
            }
    }

    @MainActor
    private func loadThumbnail() async {
        guard let thumbnailProvider = model.thumbnailProvider else {
            thumbnailData = nil
            return
        }

        let request = PhotoThumbnailRequest(
            assetId: asset.id,
            targetPixelWidth: 1400,
            targetPixelHeight: 1400
        )
        thumbnailData = try? await thumbnailProvider.thumbnailData(for: request)
    }

    private func resetZoom() {
        scale = 1
        lastScale = 1
        offset = .zero
        lastOffset = .zero
    }

    private func platformImage(from data: Data?) -> Image? {
        guard let data else {
            return nil
        }

        #if canImport(UIKit)
        guard let image = UIImage(data: data) else {
            return nil
        }
        return Image(uiImage: image)
        #elseif canImport(AppKit)
        guard let image = NSImage(data: data) else {
            return nil
        }
        return Image(nsImage: image)
        #else
        return nil
        #endif
    }
}

#Preview {
    PhotoPreviewView(asset: PickoAppModel.preview().assets[0], model: .preview())
}
