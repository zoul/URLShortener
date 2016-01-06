import Foundation
import URLShortener

let request = URLShortenerRequest(
    APIKey: "ADD_YOUR_OWN_HERE",
    URL: NSURL(string: "http://www.theguardian.com/world/live/2016/jan/06/north-korea-major-announcement-artificial-earthquake-nuclear-test-site-live")!)
do {
    let shortURL = try request.getShortURL()
    print(shortURL)
} catch (let error) {
    print(error)
}
