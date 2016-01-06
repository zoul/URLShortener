import Foundation

public enum URLShortenerError: ErrorType {
    case UnexpectedError(description: String)
    case HTTPError(response: NSURLResponse)
    case NetworkError(error: NSError)
    case ResponseParseError
}

public class URLShortenerRequest {

    public let APIKey: String
    public let URL: NSURL

    public init(APIKey: String, URL: NSURL) {
        self.APIKey = APIKey
        self.URL = URL
    }

    var targetAPIURL: NSURL {
        return NSURL(string: "https://www.googleapis.com/urlshortener/v1/url?key=" + APIKey.URLEncodedString)!
    }

    var URLRequest: NSURLRequest {
        let request = NSMutableURLRequest(URL: targetAPIURL)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.HTTPMethod = "POST"
        request.HTTPBody = try! NSJSONSerialization.dataWithJSONObject(["longUrl": URL.absoluteString], options: [])
        return request
    }

    func parseResponseData(data: NSData) -> NSURL? {
        guard
            let parsedResponse = try? NSJSONSerialization.JSONObjectWithData(data, options: []),
            let responseDict = parsedResponse as? NSDictionary,
            let shortURLString = responseDict["id"] as? String,
            let shortURL = NSURL(string: shortURLString)
            else { return nil }
        return shortURL
    }

    public func getShortURL(completion: (NSURL?, URLShortenerError?) -> Void) {

        let task = NSURLSession.sharedSession().dataTaskWithRequest(URLRequest) {
            (responseData, response, error) in

            // Basic connectivity issues: no network etc.
            if let error = error {
                completion(nil, URLShortenerError.NetworkError(error: error))
                return
            }

            // Weird case where there’s no response and no error
            guard let response = response as? NSHTTPURLResponse else {
                completion(nil, URLShortenerError.UnexpectedError(
                    description: "No response from server"))
                return
            }

            // Plain HTTP error
            if response.statusCode < 200 || response.statusCode > 299 {
                completion(nil, URLShortenerError.HTTPError(response: response))
                return
            }

            // Weird case where we get HTTP success, but no response
            guard let responseData = responseData else {
                completion(nil, URLShortenerError.UnexpectedError(
                    description: "Server returned no error, but no response data either"))
                return
            }

            // Parsing errors
            guard let shortURL = self.parseResponseData(responseData) else {
                completion(nil, URLShortenerError.ResponseParseError)
                return
            }

            completion(shortURL, nil)
        }

        task.resume()
    }

    public func getShortURL() throws -> NSURL {
        let semaphore = dispatch_semaphore_create(0)
        var shortURL: NSURL?
        var error: URLShortenerError?
        getShortURL {
            shortURL = $0
            error = $1
            dispatch_semaphore_signal(semaphore)
        }
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER)
        if let error = error {
            throw error
        } else {
            return shortURL!
        }
    }
}

private extension String {

    // http://stackoverflow.com/a/1455639/17279
    var URLEncodedString: String {
        let customAllowedSet = NSCharacterSet(charactersInString:":/?#[]@!$&'()*+,;=").invertedSet
        return stringByAddingPercentEncodingWithAllowedCharacters(customAllowedSet)!
    }
}
