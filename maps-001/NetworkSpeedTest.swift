//
//  NetworkSpeedTest.swift
//  maps-001
//
//  Real network speed testing implementation
//

import Foundation
import Network
import CoreLocation

class NetworkSpeedTest: ObservableObject {
    @Published var downloadSpeed: Double = 0
    @Published var uploadSpeed: Double = 0
    @Published var latency: Double = 0
    @Published var isTestRunning = false
    @Published var testProgress: Double = 0
    
    private let testURLs = [
        "https://speed.cloudflare.com/__down?bytes=10000000", // 10MB
        "https://www.google.com/images/branding/googlelogo/2x/googlelogo_color_272x92dp.png",
        "https://raw.githubusercontent.com/google/material-design-icons/master/README.md"
    ]
    
    func runSpeedTest(completion: @escaping (WiFiMeasurement) -> Void) {
        isTestRunning = true
        testProgress = 0
        
        // Test download speed
        testDownloadSpeed { [weak self] downloadMbps in
            guard let self = self else { return }
            self.downloadSpeed = downloadMbps
            self.testProgress = 0.33
            
            // Test upload speed (using POST request timing)
            self.testUploadSpeed { uploadMbps in
                self.uploadSpeed = uploadMbps
                self.testProgress = 0.66
                
                // Test latency
                self.testLatency { latencyMs in
                    self.latency = latencyMs
                    self.testProgress = 1.0
                    self.isTestRunning = false
                    
                    // Get WiFi signal strength
                    let signalStrength = self.getWiFiSignalStrength()
                    
                    // Create measurement
                    let measurement = WiFiMeasurement(
                        timestamp: Date(),
                        downloadSpeed: downloadMbps,
                        uploadSpeed: uploadMbps,
                        ping: latencyMs,
                        signalStrength: signalStrength,
                        exactLocation: nil,
                        seatDescription: nil,
                        userId: UUID().uuidString
                    )
                    
                    completion(measurement)
                }
            }
        }
    }
    
    private func testDownloadSpeed(completion: @escaping (Double) -> Void) {
        guard let url = URL(string: testURLs[0]) else {
            completion(0)
            return
        }
        
        let startTime = Date()
        var downloadedBytes: Int64 = 0
        
        let session = URLSession(configuration: .ephemeral)
        let task = session.dataTask(with: url) { data, response, error in
            let endTime = Date()
            let duration = endTime.timeIntervalSince(startTime)
            
            if let data = data {
                downloadedBytes = Int64(data.count)
                let mbps = (Double(downloadedBytes) * 8) / (duration * 1_000_000)
                DispatchQueue.main.async {
                    completion(mbps)
                }
            } else {
                DispatchQueue.main.async {
                    completion(0)
                }
            }
        }
        
        task.resume()
    }
    
    private func testUploadSpeed(completion: @escaping (Double) -> Void) {
        // Create test data (1MB)
        let testData = Data(repeating: 0, count: 1_000_000)
        
        guard let url = URL(string: "https://httpbin.org/post") else {
            completion(0)
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = testData
        
        let startTime = Date()
        
        let task = URLSession.shared.dataTask(with: request) { _, response, error in
            let endTime = Date()
            let duration = endTime.timeIntervalSince(startTime)
            
            if error == nil, let httpResponse = response as? HTTPURLResponse,
               httpResponse.statusCode == 200 {
                let mbps = (Double(testData.count) * 8) / (duration * 1_000_000)
                DispatchQueue.main.async {
                    completion(mbps)
                }
            } else {
                DispatchQueue.main.async {
                    completion(0)
                }
            }
        }
        
        task.resume()
    }
    
    private func testLatency(completion: @escaping (Double) -> Void) {
        guard let url = URL(string: "https://www.google.com") else {
            completion(0)
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "HEAD"
        
        let startTime = Date()
        
        let task = URLSession.shared.dataTask(with: request) { _, _, _ in
            let endTime = Date()
            let latencyMs = endTime.timeIntervalSince(startTime) * 1000
            
            DispatchQueue.main.async {
                completion(latencyMs)
            }
        }
        
        task.resume()
    }
    
    private func getWiFiSignalStrength() -> Double {
        // Note: Getting actual WiFi signal strength requires:
        // 1. NEHotspotConfiguration entitlement
        // 2. Access WiFi Information capability
        // For now, we'll estimate based on network performance
        
        let performanceScore = (downloadSpeed / 100.0) * 0.5 + 
                             (1.0 / max(latency, 1.0)) * 50.0 * 0.3 +
                             (uploadSpeed / 50.0) * 0.2
        
        return min(max(performanceScore * 100, 0), 100)
    }
}