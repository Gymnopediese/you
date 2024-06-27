import Array "mo:base/Array";
import Text "mo:base/Text";
import Blob "mo:base/Blob";
import index "index";
import favicon "favicon";
import style "style";
import image_profile "image/profile";
module {
        public type StatusCode = Nat16;
        public type HeaderField = (Text, Text);
        public type Request = {
            url : Text;
            method : Method;
            body : Blob;
            headers : [HeaderField];
        };
        public type Method = Text;
        public type Response = {
            body : Blob;
            headers : [HeaderField];
            status_code : StatusCode;
        };

    public func http_request(request : Request) : Response {
        let url = request.url;

        if (url == "/" or url == "/index.html")
        {
            return ({
                body = index.get_html();
                headers = [("Content-Type", "text/html")];
                status_code = 200;
            });
        };
        if (url == "/favicon.png")
        {
            return ({
                body = favicon.get_html();
                headers = [("Content-Type", "image/png")];
                status_code = 200;
            });
        };
        if (url == "/style.css")
        {
            return ({
                body = style.get_html();
                headers = [("Content-Type", "text/css")];
                status_code = 200;
            });
        };
        if (url == "/image/profile.png")
        {
            return ({
                body = image_profile.get_html();
                headers = [("Content-Type", "image/png")];
                status_code = 200;
            });
        };
        return ({
            body = Blob.fromArray([]);
            headers = [("Content-Type", "text/html")];
            status_code = 404;
        });
    }
}