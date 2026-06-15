//
//  PhotoDTO.swift
//  CodingChallenge
//
//  Created by Kirtan on 6/14/26.
//

import SDWebImageSwiftUI
import SwiftUI

struct PhotoRowView: View {
    let photo: Photo

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            WebImage(url: URL(string: photo.thumbnailUrl ?? "")) { image in
                image.resizable()
            } placeholder: {
                PhotoPlaceholderImage()
            }
            .indicator(.activity)
            .transition(.fade(duration: 0.2))
            .scaledToFill()
            .frame(width: 60, height: 60)
            .clipShape(RoundedRectangle(cornerRadius: 8))

            Text(photo.title ?? "")
                .font(.body)
                .lineLimit(3)
                .multilineTextAlignment(.leading)
        }
        .padding(.vertical, 4)
    }
}
