//
//  CanvasStore.swift
//  LoopCanvas
//
//  Created by Peter Rice on 8/14/24.
//

import Foundation
import SwiftUI
import os

struct SavedCanvasModel: Identifiable, Hashable {
  var id: Int { index }
  let index: Int
  let name: String
  let thumnail: UIImage
}

// Manages browsing, loading, saving of canvas
class CanvasStore: ObservableObject {
  private static let logger = Logger(
    subsystem: "Models",
    category: String(describing: CanvasStore.self)
  )
  let sampleSetStore: SampleSetStore?

  @Published var savedCanvases: [SavedCanvasModel] = []
  var debugSavedCanvases: [SavedCanvasModel]?

  init(sampleSetStore: SampleSetStore?) {
    self.sampleSetStore = sampleSetStore
  }

  init(debugSavedCanvases: [SavedCanvasModel], sampleSetStore: SampleSetStore?) {
    self.debugSavedCanvases = debugSavedCanvases
    self.savedCanvases = debugSavedCanvases
    self.sampleSetStore = sampleSetStore
  }

  func reloadSavedCanvases() {
    if let debugSavedCanvases = debugSavedCanvases {
      savedCanvases = debugSavedCanvases
    } else {
      savedCanvases = getSavedCanvases()
    }
  }

  func getSavedCanvases() -> [SavedCanvasModel] {
    guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
      Self.logger.error("Error: Unable to access documents directory")
      return []
    }
    let dataDirectoryURL = documentsDirectory.appendingPathComponent("LoopCanvas")
    if !FileManager.default.fileExists(atPath: dataDirectoryURL.path) {
      do {
        try FileManager.default.createDirectory(
          at: dataDirectoryURL, withIntermediateDirectories: true, attributes: nil)
      } catch {
        Self.logger.error("Error: Unable to create directory \(dataDirectoryURL)")
        return []
      }
    }

    var savedCanvasModels: [SavedCanvasModel] = []
    do {
      let canvasFileNames = try FileManager.default.contentsOfDirectory(atPath: dataDirectoryURL.path)
      for (index, canvasFileName) in canvasFileNames.enumerated() where canvasFileName.hasSuffix(".json") {
        let canvasName = String(canvasFileName.dropLast(5))

        let thumbnailURL = dataDirectoryURL
          .appendingPathComponent(canvasName)
          .appendingPathExtension("png")


        var image = UIImage(systemName: "Image")
        if FileManager.default.fileExists(atPath: thumbnailURL.path) {
          do {
            let imageData = try Data(contentsOf: thumbnailURL)
            if let loadedImage = UIImage(data: imageData) {
              image = loadedImage
            }
          } catch {
            Self.logger.error("Error: Unable to convert data to UIImage")
          }
        }

        if let image = image {
          savedCanvasModels.append(
            SavedCanvasModel(
              index: index,
              name: canvasName,
              thumnail: image
            ))
        }
      }
    } catch {
      Self.logger.error("Error: emumerating canvas filenames")
      return []
    }


    return savedCanvasModels
  }

  func saveCanvas(canvasModel: CanvasModel) {
    guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
      Self.logger.error("Error: Unable to access documents directory")
      return
    }
    let dataDirectoryURL = documentsDirectory.appendingPathComponent("LoopCanvas")
    if !FileManager.default.fileExists(atPath: dataDirectoryURL.path) {
      do {
        try FileManager.default.createDirectory(
          at: dataDirectoryURL, withIntermediateDirectories: true, attributes: nil)
      } catch {
        Self.logger.error("Error: Unable to create directory \(dataDirectoryURL)")
        return
      }
    }

    let jsonFileURL = dataDirectoryURL
      .appendingPathComponent(canvasModel.name)
      .appendingPathExtension("json")

    let encoder = JSONEncoder()
    do {
      let canvasJSONData = try encoder.encode(canvasModel.data)
      try canvasJSONData.write(to: jsonFileURL, options: .atomicWrite)
      Self.logger.info("writing canvas to \(jsonFileURL)")
    } catch {
      // TODO proper error handling
      Self.logger.error("Error saving file \(jsonFileURL)")
    }

    if let thumbnail = canvasModel.thumnail, let imageData = thumbnail.pngData() {
      let thumbnailURL = dataDirectoryURL
        .appendingPathComponent(canvasModel.name)
        .appendingPathExtension("png")

      do {
        try imageData.write(to: thumbnailURL)
        Self.logger.info("writing thumbnail to \(thumbnailURL)")
      } catch {
        Self.logger.error("Error saving thumbnail \(thumbnailURL)")
      }
    }
  }

  func loadCanvas(name: String) -> CanvasModel? {
    guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
      Self.logger.error("Error: Unable to access documents directory")
      return nil
    }
    let dataDirectoryURL = documentsDirectory.appendingPathComponent("LoopCanvas")

    let jsonFileURL = dataDirectoryURL
      .appendingPathComponent(name)
      .appendingPathExtension("json")
    let thumbnailURL = dataDirectoryURL
      .appendingPathComponent(name)
      .appendingPathExtension("png")

    let decoder = JSONDecoder()
    do {
      Self.logger.info("Loading canvas \(jsonFileURL.path)")
      if !FileManager.default.fileExists(atPath: jsonFileURL.path) {
        Self.logger.error("Error loasding canvas: path does not exist")
        return nil
      }
      let canvasJSONData = try Data(contentsOf: jsonFileURL)
      let canvasModelData = try decoder.decode(CanvasModelData.self, from: canvasJSONData)
      let canvasModel = CanvasModel(data: canvasModelData, sampleSetStore: sampleSetStore)

      if FileManager.default.fileExists(atPath: thumbnailURL.path) {
        let imageData = try Data(contentsOf: thumbnailURL)
        if let image = UIImage(data: imageData) {
          canvasModel.thumnail = image
        } else {
          Self.logger.error("Error: Unable to convert data to UIImage")
        }
      } else {
        Self.logger.error("Error loading image file: path does not exist \(thumbnailURL)")
      }

      return canvasModel
    } catch {
      Self.logger.error("\(error)")
      // TODO proper error handling
      Self.logger.error("Error loading json file \(jsonFileURL)")
      Self.logger.error("Error loading image file \(thumbnailURL)")
    }
    return nil
  }
}
