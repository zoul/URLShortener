import XCTest

class URLShortenerRequestTests: XCTestCase {

    let sampleURL = URL(string: "https://developers.google.com/")!

    func testAPIURLBuilding() {
        let request = URLShortenerRequest(APIKey: "foo", URL: sampleURL)
        XCTAssertEqual(request.targetAPIURL, URL(string: "https://www.googleapis.com/urlshortener/v1/url?key=foo"))
    }

    func testKeyEscaping() {
        let request = URLShortenerRequest(APIKey: "foo=bar", URL: sampleURL)
        XCTAssertEqual(request.targetAPIURL, URL(string: "https://www.googleapis.com/urlshortener/v1/url?key=foo%3Dbar"))
    }

    func testURLRequestBuilding() {
        let request = URLShortenerRequest(APIKey: "foo", URL: sampleURL)
        let body = String(data: request.URLRequest.httpBody!, encoding: String.Encoding.utf8)
        XCTAssertEqual(body, "{\"longUrl\":\"https:\\/\\/developers.google.com\\/\"}")
        XCTAssertEqual(request.URLRequest.httpMethod, "POST")
        XCTAssertEqual(request.URLRequest.value(forHTTPHeaderField: "Content-Type"), "application/json")
    }

    func testResponseParsing() {
        let request = URLShortenerRequest(APIKey: "foo", URL: sampleURL)
        let sampleResponse = "{\"kind\": \"urlshortener#url\", \"id\": \"http://goo.gl/fbsS\", \"longUrl\": \"http://www.google.com/\" }"
        let sampleResponseData = sampleResponse.data(using: String.Encoding.utf8)!
        XCTAssertEqual(request.parseResponseData(sampleResponseData), URL(string: "http://goo.gl/fbsS")!)
    }
}
