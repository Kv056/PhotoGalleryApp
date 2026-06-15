//
//  PhotoDTO.swift
//  CodingChallenge
//
//  Created by Kirtan on 6/14/26.
//
import Foundation

struct PhotoDTO: Codable, Sendable {
    let albumId: Int
    let id: Int
    let title: String
    let url: String
    let thumbnailUrl: String
}
