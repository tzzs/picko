import MapKit
import PickoCore
import PickoPhotos
import SwiftUI

public struct CollectionReviewView: View {
    public enum Mode: String, Identifiable {
        case time
        case place

        public var id: String { rawValue }

        var title: String {
            switch self {
            case .time:
                return "时间"
            case .place:
                return "地点"
            }
        }

        var subtitle: String {
            switch self {
            case .time:
                return "按拍摄日期整理"
            case .place:
                return "按城市与地点聚合"
            }
        }

        var systemImage: String {
            switch self {
            case .time:
                return "clock"
            case .place:
                return "location"
            }
        }
    }

    @Bindable private var model: PickoAppModel
    @State private var placeGroups: [PhotoCollectionGroup] = []
    @State private var isLoadingPlaceGroups = false

    private let mode: Mode
    private let groupingEngine: PhotoCollectionGroupingEngine
    private let placeLabelResolver: any PlaceLabelResolving
    private let timeChips = ["今天", "昨天", "本周早些", "上个月", "按月归档"]

    public init(
        mode: Mode,
        model: PickoAppModel,
        groupingEngine: PhotoCollectionGroupingEngine = PhotoCollectionGroupingEngine(),
        placeLabelResolver: any PlaceLabelResolving = SystemPlaceLabelResolver()
    ) {
        self.mode = mode
        self.model = model
        self.groupingEngine = groupingEngine
        self.placeLabelResolver = placeLabelResolver
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: PickoDesign.Spacing.lg) {
                header

                switch mode {
                case .time:
                    timeContent
                case .place:
                    placeContent
                }
            }
            .padding(PickoDesign.Spacing.page)
            .padding(.bottom, 96)
        }
        .navigationTitle(mode.title)
        .pickoInlineNavigationTitle()
        .pickoScreenBackground()
        .task(id: placeTaskKey) {
            guard mode == .place else {
                return
            }
            await refreshPlaceGroups()
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 12) {
                Image(systemName: mode.systemImage)
                    .font(.system(size: 20, weight: .semibold))
                    .frame(width: 44, height: 44)
                    .background(PickoDesign.ColorToken.primarySoft.opacity(0.75), in: Circle())
                    .foregroundStyle(PickoDesign.ColorToken.primary)

                VStack(alignment: .leading, spacing: 2) {
                    Text(mode.title)
                        .font(.system(size: 30, weight: .semibold, design: .rounded))
                        .foregroundStyle(PickoDesign.ColorToken.primary)
                    Text(mode.subtitle)
                        .font(.system(size: 14, weight: .regular, design: .rounded))
                        .foregroundStyle(PickoDesign.ColorToken.secondaryInk)
                }

                Spacer()
            }
        }
    }

    private var timeContent: some View {
        let groups = groupingEngine.timeGroups(from: model.assets, similarGroups: model.groups)

        return VStack(alignment: .leading, spacing: PickoDesign.Spacing.md) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(timeChips, id: \.self) { chip in
                        Text(chip)
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(
                                chip == timeChips.first ? PickoDesign.ColorToken.primary : PickoDesign.ColorToken.surface,
                                in: Capsule()
                            )
                            .foregroundStyle(chip == timeChips.first ? .white : PickoDesign.ColorToken.primary)
                            .overlay {
                                Capsule()
                                    .stroke(PickoDesign.ColorToken.outline.opacity(0.45), lineWidth: chip == timeChips.first ? 0 : 1)
                            }
                    }
                }
            }

            if groups.isEmpty {
                emptyState(
                    title: "暂无可按时间整理的照片",
                    message: "当前没有未复核照片可进入时间合集。你可以返回首页查看其他整理入口。",
                    systemImage: "calendar.badge.exclamationmark"
                )
            } else {
                collectionList(groups: groups)
            }
        }
    }

    private var placeContent: some View {
        VStack(alignment: .leading, spacing: PickoDesign.Spacing.md) {
            if isLoadingPlaceGroups {
                progressPanel
            } else if placeGroups.isEmpty {
                emptyState(
                    title: "暂无带地点信息的照片",
                    message: "当前未复核照片没有可用地点信息，或系统暂时无法读取照片坐标。",
                    systemImage: "location.slash"
                )
            } else {
                placeMapPanel(groups: placeGroups)
                collectionList(groups: placeGroups)
            }
        }
    }

    private var progressPanel: some View {
        HStack(spacing: 12) {
            ProgressView()
            Text("正在聚合地点")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(PickoDesign.ColorToken.secondaryInk)
        }
        .frame(maxWidth: .infinity, minHeight: 92)
        .background(PickoDesign.ColorToken.surface, in: RoundedRectangle(cornerRadius: PickoDesign.Radius.lg))
        .overlay {
            RoundedRectangle(cornerRadius: PickoDesign.Radius.lg)
                .stroke(PickoDesign.ColorToken.outline.opacity(0.45), lineWidth: 1)
        }
    }

    private func collectionList(groups: [PhotoCollectionGroup]) -> some View {
        VStack(spacing: PickoDesign.Spacing.gutter) {
            ForEach(groups) { group in
                collectionCard(group: group)
            }
        }
    }

    private func collectionCard(group: PhotoCollectionGroup) -> some View {
        Button {
            startReview(group: group)
        } label: {
            VStack(alignment: .leading, spacing: PickoDesign.Spacing.md) {
                HStack(alignment: .firstTextBaseline) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(group.title)
                            .font(.system(size: 20, weight: .semibold, design: .rounded))
                            .foregroundStyle(PickoDesign.ColorToken.primary)
                        Text(group.subtitle)
                            .font(.system(size: 12, weight: .medium, design: .monospaced))
                            .foregroundStyle(PickoDesign.ColorToken.secondaryInk)
                    }

                    Spacer()

                    Text("整理 →")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(PickoDesign.ColorToken.coralDeep)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(PickoDesign.ColorToken.goldSoft, in: Capsule())
                }

                previewStrip(assetIds: group.previewAssetIds)
            }
            .padding(PickoDesign.Spacing.md)
            .background(PickoDesign.ColorToken.surface, in: RoundedRectangle(cornerRadius: PickoDesign.Radius.lg))
            .overlay {
                RoundedRectangle(cornerRadius: PickoDesign.Radius.lg)
                    .stroke(PickoDesign.ColorToken.outline.opacity(0.45), lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(group.title)，\(group.subtitle)，整理")
    }

    private func previewStrip(assetIds: [PhotoAsset.ID]) -> some View {
        HStack(spacing: 6) {
            ForEach(assetIds, id: \.self) { assetId in
                if let asset = model.store.asset(id: assetId) {
                    PickoThumbnailView(
                        asset: asset,
                        thumbnailProvider: model.thumbnailProvider,
                        targetPixelWidth: 220,
                        targetPixelHeight: 220,
                        contentMode: .fill
                    )
                    .frame(height: 74)
                    .frame(maxWidth: .infinity)
                    .clipShape(RoundedRectangle(cornerRadius: PickoDesign.Radius.sm))
                    .background(PickoDesign.ColorToken.surfaceLow, in: RoundedRectangle(cornerRadius: PickoDesign.Radius.sm))
                }
            }
        }
        .frame(minHeight: 74)
    }

    private func placeMapPanel(groups: [PhotoCollectionGroup]) -> some View {
        let mapPresentation = PlaceMapPresentation(groups: groups)

        return VStack(alignment: .leading, spacing: PickoDesign.Spacing.gutter) {
            HStack {
                Label("地图聚合", systemImage: "map")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(PickoDesign.ColorToken.primary)
                Spacer()
                Text("\(groups.count) 个地点")
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundStyle(PickoDesign.ColorToken.secondaryInk)
            }

            Map(position: .constant(.region(mapPresentation.region)), interactionModes: []) {
                ForEach(mapPresentation.annotations) { annotation in
                    Annotation(annotation.title, coordinate: annotation.coordinate) {
                        placePin(count: annotation.count)
                    }
                }
            }
            .frame(height: 160)
            .clipShape(RoundedRectangle(cornerRadius: PickoDesign.Radius.lg))
            .overlay {
                RoundedRectangle(cornerRadius: PickoDesign.Radius.lg)
                    .stroke(PickoDesign.ColorToken.outline.opacity(0.35), lineWidth: 1)
            }
        }
        .padding(PickoDesign.Spacing.md)
        .background(PickoDesign.ColorToken.surface, in: RoundedRectangle(cornerRadius: PickoDesign.Radius.lg))
        .overlay {
            RoundedRectangle(cornerRadius: PickoDesign.Radius.lg)
                .stroke(PickoDesign.ColorToken.outline.opacity(0.45), lineWidth: 1)
        }
    }

    private func placePin(count: Int) -> some View {
        HStack(spacing: 4) {
            Image(systemName: "mappin.circle.fill")
                .font(.system(size: 16, weight: .semibold))
            Text("\(count)")
                .font(.system(size: 11, weight: .bold, design: .monospaced))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(PickoDesign.ColorToken.primary, in: Capsule())
        .foregroundStyle(.white)
    }

    private func emptyState(title: String, message: String, systemImage: String) -> some View {
        VStack(spacing: PickoDesign.Spacing.md) {
            PickoEmptyStateView(title: title, message: message, systemImage: systemImage)
                .padding(0)
        }
    }

    private func startReview(group: PhotoCollectionGroup) {
        model.startReview(scope: PickoAppModel.ReviewScope(
            id: group.id,
            mode: group.kind == .time ? .time : .place,
            title: group.title,
            assetIds: group.assetIds
        ))
    }

    private func refreshPlaceGroups() async {
        isLoadingPlaceGroups = true
        let groups = await groupingEngine.placeGroups(
            from: model.assets,
            similarGroups: model.groups,
            resolver: placeLabelResolver
        )
        placeGroups = groups
        isLoadingPlaceGroups = false
    }

    private var placeTaskKey: String {
        guard mode == .place else {
            return mode.rawValue
        }
        return model.assets
            .map { "\($0.id):\($0.status)" }
            .joined(separator: "|")
    }
}

#Preview {
    NavigationStack {
        CollectionReviewView(mode: .time, model: .preview())
    }
}
