import CryptoKit
import Foundation

public struct FileFingerprint {
  /// 计算文件的 SHA-256 哈希值作为指纹
  public static func calculate(for url: URL) -> String? {
    guard let data = try? Data(contentsOf: url, options: .mappedIfSafe) else {
      return nil
    }
    let hash = SHA256.hash(data: data)
    return hash.compactMap { String(format: "%02x", $0) }.joined()
  }

  /// 异步计算指纹，避免阻塞主线程
  public static func calculateAsync(for url: URL, completion: @escaping (String?) -> Void) {
    DispatchQueue.global(qos: .userInitiated).async {
      let result = calculate(for: url)
      DispatchQueue.main.async {
        completion(result)
      }
    }
  }
}
