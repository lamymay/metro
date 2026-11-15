import AVFoundation
import Foundation
import SwiftUI

#if os(macOS)
  import AppKit

  public class MacFolderImporter {
    public static let shared = MacFolderImporter()

    /// 允许的文件扩展名
    private let supportedExtensions = ["mp3", "m4a", "wav", "flac", "aac"]

    /// 打开选择器，支持文件和文件夹多选
    public func selectItems(completion: @escaping ([URL]) -> Void) {
      let panel = NSOpenPanel()
      panel.canChooseFiles = true
      panel.canChooseDirectories = true
      panel.allowsMultipleSelection = true
      panel.message = "选择音乐文件或文件夹导入"

      panel.begin { response in
        if response == .OK {
          completion(panel.urls)
        } else {
          completion([])
        }
      }
    }

    /// 处理选中的项（可能是文件或文件夹的混合）
    public func processSelectedItems(
      _ urls: [URL],
      progress: @escaping (Double) -> Void,
      completion: @escaping ([LocalSongImportInfo]) -> Void
    ) {
      DispatchQueue.global(qos: .userInitiated).async {
        let fm = FileManager.default
        var results: [LocalSongImportInfo] = []

        // 首先收集所有要处理的文件 URL，按顶级 URL 分组
        var filesByTopURL: [URL: [URL]] = [:]

        for topURL in urls {
          let accessGranted = topURL.startAccessingSecurityScopedResource()
          defer { if accessGranted { topURL.stopAccessingSecurityScopedResource() } }

          var isDir: ObjCBool = false
          if fm.fileExists(atPath: topURL.path, isDirectory: &isDir) {
            if isDir.boolValue {
              var files: [URL] = []
              if let enumerator = fm.enumerator(
                at: topURL,
                includingPropertiesForKeys: [.isRegularFileKey],
                options: [.skipsHiddenFiles, .skipsPackageDescendants])
              {
                while let fileURL = enumerator.nextObject() as? URL {
                  if self.supportedExtensions.contains(fileURL.pathExtension.lowercased()) {
                    files.append(fileURL)
                  }
                }
              }
              filesByTopURL[topURL] = files
            } else {
              if self.supportedExtensions.contains(topURL.pathExtension.lowercased()) {
                filesByTopURL[topURL] = [topURL]
              }
            }
          }
        }

        let totalFiles = filesByTopURL.values.reduce(0) { $0 + $1.count }
        print("🔍 扫描完成，找到 \(totalFiles) 个待处理文件")
        if totalFiles == 0 {
          DispatchQueue.main.async { completion([]) }
          return
        }

        var processedCount = 0

        // 重新开始访问权限并提取信息
        for (topURL, files) in filesByTopURL {
          let accessGranted = topURL.startAccessingSecurityScopedResource()
          print("📂 开启目录访问: \(topURL.path), 状态: \(accessGranted)")

          for fileURL in files {
            if let info = self.extractInfo(for: fileURL) {
              results.append(info)
            }
            processedCount += 1
            let p = Double(processedCount) / Double(totalFiles)
            DispatchQueue.main.async { progress(p) }
          }

          if accessGranted {
            topURL.stopAccessingSecurityScopedResource()
          }
        }
        print("✅ 元数据提取完成，成功处理 \(results.count) 个文件")

        DispatchQueue.main.async { completion(results) }
      }
    }

    /// 提取单个文件的元数据
    private func extractInfo(for url: URL) -> LocalSongImportInfo? {
      let asset = AVAsset(url: url)
      let metadata = asset.metadata

      var title = url.deletingPathExtension().lastPathComponent
      var artist = ""
      var album = ""
      var genre = ""

      for item in metadata {
        guard let commonKey = item.commonKey?.rawValue else { continue }

        switch commonKey {
        case "title":
          title = item.stringValue ?? title
        case "artist":
          artist = item.stringValue ?? ""
        case "albumName":
          album = item.stringValue ?? ""
        case "type":
          genre = item.stringValue ?? ""
        default:
          break
        }
      }

      let duration = CMTimeGetSeconds(asset.duration)

      return LocalSongImportInfo(
        url: url,
        title: title,
        artist: artist,
        album: album,
        genre: genre,
        duration: duration
      )
    }
  }

  /// 导入信息的结构体
  public struct LocalSongImportInfo {
    public let url: URL
    public let title: String
    public let artist: String
    public let album: String?
    public let genre: String?
    public let duration: Double

    public init(url: URL, title: String, artist: String, album: String?, genre: String?, duration: Double) {
      self.url = url
      self.title = title
      self.artist = artist
      self.album = album
      self.genre = genre
      self.duration = duration
    }
  }

#endif
