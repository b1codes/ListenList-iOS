// ListenList/ListenList/Components/SkeletonCardRow.swift
//
// Loading placeholder shaped like a List Card row, so the "Loading..." /
// "Searching..." states show the shape of what's coming instead of a
// spinner sitting in otherwise-empty space.

import SwiftUI

struct SkeletonCardRow: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isPulsing = false

    var body: some View {
        HStack(spacing: 15) {
            RoundedRectangle(cornerRadius: 10.0)
                .fill(Color.gray.opacity(0.3))
                .frame(width: 90, height: 90)

            VStack(alignment: .leading, spacing: 8) {
                RoundedRectangle(cornerRadius: 4.0)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 170, height: 16)
                RoundedRectangle(cornerRadius: 4.0)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 110, height: 13)
            }

            Spacer()
        }
        .padding(.horizontal, 20)
        .frame(maxWidth: 600, minHeight: 120)
        .background(
            RoundedRectangle(cornerRadius: 15.0)
                .fill(Color.gray.opacity(0.12))
        )
        .padding([.leading, .trailing], 10)
        .opacity(isPulsing ? 0.55 : 1.0)
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) {
                isPulsing = true
            }
        }
        .accessibilityHidden(true)
    }
}

/// A stack of `SkeletonCardRow`s standing in for a list that's still loading.
struct SkeletonCardListView: View {
    var count: Int = 5

    var body: some View {
        VStack(spacing: 10) {
            ForEach(0..<count, id: \.self) { _ in
                SkeletonCardRow()
            }
        }
    }
}

#Preview {
    SkeletonCardListView()
}
