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

    var targetURL: NSURL {
        return NSURL(string: "https://www.googleapis.com/urlshortener/v1/url?key=" + APIKey.URLEncodedString)!
    }

    var URLRequest: NSURLRequest {
        let request = NSMutableURLRequest(URL: targetURL)
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

    public func getShortURL() throws -> NSURL {

        let semaphore = dispatch_semaphore_create(0)
        var maybeResponseData: NSData? = nil
        var maybeResponse: NSHTTPURLResponse? = nil
        var maybeError: NSError? = nil

        let task = NSURLSession.sharedSession().dataTaskWithRequest(URLRequest) {
            maybeResponseData = $0
            maybeResponse = $1 as? NSHTTPURLResponse
            maybeError = $2
            dispatch_semaphore_signal(semaphore)
        }

        task.resume()
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER)

        // Basic connectivity issues: no network etc.
        if let error = maybeError {
            throw URLShortenerError.NetworkError(error: error)
        }

        // Weird case where there’s no response and no error
        guard let response = maybeResponse else {
            throw URLShortenerError.UnexpectedError(description: "No response from server")
        }

        // Plain HTTP error
        if response.statusCode < 200 || response.statusCode > 299 {
            throw URLShortenerError.HTTPError(response: response)
        }

        // Weird case where we get HTTP success, but no response
        guard let responseData = maybeResponseData else {
            throw URLShortenerError.UnexpectedError(description: "Server returned no error, but no response either")
        }

        // Parsing errors
        guard let shortURL = parseResponseData(responseData)
            else { throw URLShortenerError.ResponseParseError }
        
        return shortURL
    }
}

private extension String {

    // http://stackoverflow.com/a/1455639/17279
    var URLEncodedString: String {
        let customAllowedSet = NSCharacterSet(charactersInString:":/?#[]@!$&'()*+,;=").invertedSet
        return stringByAddingPercentEncodingWithAllowedCharacters(customAllowedSet)!
    }
}
