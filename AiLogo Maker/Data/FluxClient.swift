//
//  FluxClient.swift
//  AiLogo Maker
//
//  Created by Apple on 09/03/2026.
//


import Foundation

final class FluxClient {
    
    static let shared = FluxClient()
    
    private init() {}
    
    
    // MARK: - Generate Request
    struct GenerateRequest: Encodable {
        let prompt: String
        let enableTranslation: Bool
        let aspectRatio: String
        let outputFormat: String
        let promptUpsampling: Bool
        let model: String
        let safetyTolerance: Int
    }
    
    
    // MARK: - Generate Response
    struct GenerateResponse: Decodable {
        let code: Int
        let msg: String
        let data: TaskData
    }
    
    struct TaskData: Decodable {
        let taskId: String
    }
    
    
    // MARK: - Fetch Response
    struct FetchResponse: Decodable {
        let code: Int
        let msg: String
        let data: FetchData
    }
    
    struct FetchData: Decodable {
        let taskId: String
        let paramJson: String
        let completeTime: String?
        let response: ImageResponse?
        let successFlag: Int
        let errorCode: String?
        let errorMessage: String?
        let createTime: String
    }
    
    struct ImageResponse: Decodable {
        let originImageUrl: String?
        let resultImageUrl: String?
    }
    
    
    // MARK: - Generate Image
    func generateImage(
        apiKey: String,
        prompt: String,
        aspectRatio: String
    ) async throws -> String {
        
        guard let url = URL(string: "https://api.fluxapi.ai/api/v1/flux/kontext/generate") else {
            throw URLError(.badURL)
        }
        
        let body = GenerateRequest(
            prompt: prompt,
            enableTranslation: true,
            aspectRatio: aspectRatio,
            outputFormat: "jpeg",
            promptUpsampling: false,
            model: "flux-kontext-pro",
            safetyTolerance: 2
        )
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        
        let decoded = try JSONDecoder().decode(GenerateResponse.self, from: data)
        return decoded.data.taskId
    }
    
    
    // MARK: - Fetch Generated Image
    func fetchImage(
        apiKey: String,
        taskId: String
    ) async throws -> String? {

        let urlString = "https://api.fluxapi.ai/api/v1/flux/kontext/record-info?taskId=\(taskId)"
        
        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }

        let decoded = try JSONDecoder().decode(FetchResponse.self, from: data)

        return decoded.data.response?.resultImageUrl
    }
}
