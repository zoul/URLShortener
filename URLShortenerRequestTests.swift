import XCTest

class URLShortenerRequestTests: XCTestCase {

    let sampleURL = NSURL(string: "https://developers.google.com/")!

    func testURLBuilding() {
        let request = URLShortenerRequest(APIKey: "foo", URL: sampleURL)
        XCTAssertEqual(request.targetURL, NSURL(string: "https://www.googleapis.com/urlshortener/v1/url?key=foo"))
    }

    func testKeyEscaping() {
        let request = URLShortenerRequest(APIKey: "foo=bar", URL: sampleURL)
        XCTAssertEqual(request.targetURL, NSURL(string: "https://www.googleapis.com/urlshortener/v1/url?key=foo%3Dbar"))
    }

    func testURLRequestBuilding() {
        let request = URLShortenerRequest(APIKey: "foo", URL: sampleURL)
        let body = String(data: request.URLRequest.HTTPBody!, encoding: NSUTF8StringEncoding)
        XCTAssertEqual(body, "{\"longUrl\":\"https:\\/\\/developers.google.com\\/\"}")
        XCTAssertEqual(request.URLRequest.HTTPMethod, "POST")
        XCTAssertEqual(request.URLRequest.valueForHTTPHeaderField("Content-Type"), "application/json")
    }

    func testResponseParsing() {
        let request = URLShortenerRequest(APIKey: "foo", URL: sampleURL)
        let sampleResponse = "{\"kind\": \"urlshortener#url\", \"id\": \"http://goo.gl/fbsS\", \"longUrl\": \"http://www.google.com/\" }"
        let sampleResponseData = sampleResponse.dataUsingEncoding(NSUTF8StringEncoding)!
        XCTAssertEqual(request.parseResponseData(sampleResponseData), NSURL(string: "http://goo.gl/fbsS")!)
    }
}
