//
//  RestManager.swift
//  Virtual Tourist
//
//  Created by Anna Zislina on 07/11/2019.
//  Copyright © 2019 Anna Zislina. All rights reserved.
//

import Foundation

class RestManager {
    
    enum HttpMethod: String {
        case get
        case post
        case put
        case patch
        case delete
    }
    
    var requestHttpHeaders = RestEntity()
    var urlQueryParameters = RestEntity()
    var httpBodyParameters = RestEntity()
    var data: Data?
    
// MARK: Setting a request HTTP header.
    
    func json() {
        requestHttpHeaders.add(value: "application/json", forKey: "Content-Type")
        requestHttpHeaders.add(value: "application/json", forKey: "Accept")
    }
 
//MARK: Appending Parameters To URL
    
    private func addURLQueryParameters(toURL url: URL) -> URL {
        if urlQueryParameters.totalItems() > 0 {
            guard var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false) else { return url }
            var queryItems = [URLQueryItem]()
            for (key, value) in urlQueryParameters.allValues() {
                let item = URLQueryItem(name: key, value: (value as AnyObject).addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed))
                queryItems.append(item)
            }
            urlComponents.queryItems = queryItems
            guard let updatedURL = urlComponents.url else { return url }
            return updatedURL
        }
        return url
    }
    
//MARK: Preparing The URL Request
    
    private func prepareRequest(withURL url: URL?, httpBody: Data?, httpMethod: HttpMethod) -> URLRequest? {
        guard let url = url else { return nil }
        var request = URLRequest(url: url)
        request.httpMethod = httpMethod.rawValue
     
        for (header, value) in requestHttpHeaders.allValues() {
            request.setValue(value as? String, forHTTPHeaderField: header)
        }
        request.httpBody = httpBody
        return request
    }
    
//MARK: Making Web Requests
    
    func makeRequest(toURL url: URL,
                     withHttpMethod httpMethod: HttpMethod,
                     completion: @escaping (_ result: Results) -> Void) {

        let targetURL = addURLQueryParameters(toURL: url)
        let httpBody = getHttpBody()
        guard let request = prepareRequest(withURL: targetURL, httpBody: httpBody, httpMethod: httpMethod) else {
            completion(Results(withError: CustomError.failedToCreateRequest))
            return
        }
     
        let sessionConfiguration = URLSessionConfiguration.default
        let session = URLSession(configuration: sessionConfiguration)
        let task = session.dataTask(with: request) { (data, response, error) in
            completion(Results(withData: data,
                                   response: Response(fromURLResponse: response),
                                   error: error))
        }
        task.resume()
    }

//MARK: Http Body
    
    private func getHttpBody() -> Data? {
        guard let contentType = requestHttpHeaders.value(forKey: "Content-Type") else { return nil }
     
        if contentType.contains("application/json") {
            return try? JSONSerialization.data(withJSONObject: httpBodyParameters.allValues(), options: [.prettyPrinted, .sortedKeys])
        } else if contentType.contains("application/x-www-form-urlencoded") {
            let bodyString = httpBodyParameters.allValues().map { "\($0)=\(String(describing: ($1 as AnyObject).addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)))" }.joined(separator: "&")
            return bodyString.data(using: .utf8)
        } else {
            return data
        }
    }
}

extension RestManager {
    
//MARK: Rest Entity
    
    struct RestEntity {
        
        private var values = [String: Any]()
     
        mutating func add(value: String, forKey key: String) {
            values[key] = value
        }

        mutating func add(values: [String: Any], forKey key: String) {
            self.values[key] = values
        }
        
        mutating func add(values: [String: Any]) {
            self.values = values
        }
        
        func value(forKey key: String) -> String? {
            return values[key] as? String
        }
        
        func allValues() -> [String: Any] {
            return values
        }
        
        func totalItems() -> Int {
            return values.count
        }    }

//MARK: Response
    
    struct Response {
        
        var response: URLResponse?
        var httpStatusCode: Int = 0
        var headers = RestEntity()
        
        init(fromURLResponse response: URLResponse?) {
            guard let response = response else { return }
            self.response = response
            httpStatusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
        
            if let headerFields = (response as? HTTPURLResponse)?.allHeaderFields {
                for (key, value) in headerFields {
                    headers.add(value: "\(value)", forKey: "\(key)")
                }
            }
        }
    }

//MARK: Results
    
    struct Results {
        var data: Data?
        var response: Response?
        var error: Error?
        
        init(withData data: Data?, response: Response?, error: Error?) {
            self.data = data
            self.response = response
            self.error = error
        }
        
        init(withError error: Error) {
            self.error = error
        }
    }
    
    enum CustomError: Error {
        case failedToCreateRequest
    }
    
    enum Result<S, F: Error> {
        case success(S)
        case failure(F)
    }
}

extension RestManager.CustomError: LocalizedError {
    public var localizedDescription: String {
        switch self {
        case .failedToCreateRequest: return NSLocalizedString("Unable to create the URLRequest object", comment: "")
        }
    }
}
