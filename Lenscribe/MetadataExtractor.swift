//
//  MetadataExtractor.swift
//  Lenscribe
//
//  Created by Ranjan Bhakta on 28/03/26.
//

import Foundation
import ImageIO
import UIKit
import CoreLocation

struct PhotoMetaData {
    var iso: Int?
    var shutterSpeed: Double?
    var aperture: Double?
    var deviceModel: String?
    var latitude: Double?
    var longitude: Double?
}

func extractMetaData(from data: Data) -> PhotoMetaData? {
    
    guard let source = CGImageSourceCreateWithData(data as CFData, nil),
          let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any]
    else { return nil }
    
    let exif = properties[kCGImagePropertyExifDictionary] as? [CFString: Any]
    let tiff = properties[kCGImagePropertyTIFFDictionary] as? [CFString: Any]
    
    let gps = properties[kCGImagePropertyGPSDictionary] as? [CFString: Any]
    
    let latitude = gps?[kCGImagePropertyGPSLatitude] as? Double
    let longitude = gps?[kCGImagePropertyGPSLongitude] as? Double
    
    return PhotoMetaData(
        iso: (exif?[kCGImagePropertyExifISOSpeedRatings] as? [Int])?.first,
        shutterSpeed: exif?[kCGImagePropertyExifExposureTime] as? Double,
        aperture: exif?[kCGImagePropertyExifFNumber] as? Double,
        deviceModel: tiff?[kCGImagePropertyTIFFModel] as? String,
        latitude: latitude,
        longitude: longitude
             )
}

func getLocationName(lat: Double, lon: Double, completion: @escaping (String) -> Void) {
    let location = CLLocation(latitude: lat, longitude: lon)
    let geocoder = CLGeocoder()
    
    geocoder.reverseGeocodeLocation(location) { placemarks, error in
        if let place = placemarks?.first {
            let city = place.locality ?? ""
            let state = place.administrativeArea ?? ""
            
            let location = [city, state]
                .filter { !$0.isEmpty }
                .joined(separator: ", ")
            
            completion(location.isEmpty ? "Unknown location" : location)
        } else {
            completion("Unknown location")
        }
    }
}
