import Frontend "frontend/__html__";
import Array "mo:base/Array";
import Blob "mo:base/Blob";

module {

    public func isAuthorized(request : Frontend.Request, password : Text) : Bool {
        return switch (Array.find<Frontend.HeaderField>(request.headers, func (header : Frontend.HeaderField) {header.0 == "Authorization"})) {
            case null false;
            case (?header) {
                return header.1 == "Bearer " # password;
            };
        };
    };

    public func OK() : async Frontend.Response {
        return ({
            body = Blob.fromArray([]);
            headers = [("Content-Type", "text/plain")];
            status_code = 200;
        });
    };
}