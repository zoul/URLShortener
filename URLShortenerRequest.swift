import Foundation

public enum URLShortenerResult: Error {
    case unexpectedError(description: String)
    case httpError(response: URLResponse)
    case networkError(error: NSError)
    case responseParseError
    case success(URL)
}

open class URLShortenerRequest {

    open let APIKey: String
    open let URL: Foundation.URL

    public init(APIKey: String, URL: Foundation.URL) {
        self.APIKey = APIKey
        self.URL = URL
    }

    var targetAPIURL: Foundation.URL {
        return Foundation.URL(string: "https://www.googleapis.com/urlshortener/v1/url?key=" + APIKey.URLEncodedString)!
    }

    var URLRequest: Foundation.URLRequest {
        let request = NSMutableURLRequest(url: targetAPIURL)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "POST"
        request.httpBody = try! JSONSerialization.data(withJSONObject: ["longUrl": URL.absoluteString], options: [])
        return request as URLRequest
    }

    func parseResponseData(_ data: Data) -> Foundation.URL? {
        guard
            let parsedResponse = try? JSONSerialization.jsonObject(with: data, options: []),
            let responseDict = parsedResponse as? NSDictionary,
            let shortURLString = responseDict["id"] as? String,
            let shortURL = Foundation.URL(string: shortURLString)
            else { return nil }
        return shortURL
    }

    open func getShortURL(_ completion: @escaping (URLShortenerResult) -> Void) {

        let task = URLSession.shared.dataTask(with: URLRequest, completionHandler: {
            responseData, response, error in

            // Basic connectivity issues: no network etc.
            if let error = error {
                completion(.networkError(error: error as NSError))
                return
            }

            // Weird case where there’s no response and no error
            guard let response = response as? HTTPURLResponse else {
                completion(.unexpectedError(description: "No response from server"))
                return
            }

            // Plain HTTP error
            if response.statusCode < 200 || response.statusCode > 299 {
                completion(.httpError(response: response))
                return
            }

            // Weird case where we get HTTP success, but no response
            guard let responseData = responseData else {
                completion(.unexpectedError(description: "Server returned no error, but no response data either"))
                return
            }

            // Parsing errors
            guard let shortURL = self.parseResponseData(responseData) else {
                completion(.responseParseError)
                return
            }

            completion(.success(shortURL))
        }) 

        task.resume()
    }

    open func getShortURL() -> URLShortenerResult {
        let semaphore = DispatchSemaphore(value: 0)
        var result: URLShortenerResult?
        getShortURL {
            result = $0
            semaphore.signal()
        }
        _ = semaphore.wait(timeout: DispatchTime.distantFuture)
        return result!
    }
}

private extension String {

    // http://stackoverflow.com/a/1455639/17279
    var URLEncodedString: String {
        let customAllowedSet = CharacterSet(charactersIn:":/?#[]@!$&'()*+,;=").inverted
        return addingPercentEncoding(withAllowedCharacters: customAllowedSet)!
    }
}
