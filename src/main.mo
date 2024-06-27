import Principal "mo:base/Principal";
import Time "mo:base/Time";
import Timer "mo:base/Timer";
import Text "mo:base/Text";
import Error "mo:base/Error";
import Frontend "frontend/__html__";
import Replace "replace";
import Friends "friends";

shared ({ caller = creator }) actor class UserCanister(
    yourName : Text
) = this {

    public type Mood = Text;
    public type Name = Text;

    stable let birth : Time.Time = Time.now();

    stable var friends : [Friends.Friend] = [];

    let name : Name = yourName;
    let owner : Principal = creator;
    let nanosecondsPerDay = 24 * 60 * 60 * 1_000_000_000;

    let board = actor ("q3gy3-sqaaa-aaaas-aaajq-cai") : actor {
        reboot_writeDailyCheck : (name : Name, mood : Mood) -> async ();
    };

    stable var alive : Bool = true;
    stable var latestPing : Time.Time = Time.now();

    func _kill() : async () {
        let now = Time.now();
        if (now - latestPing > nanosecondsPerDay) {
            alive := false;
        };
    };

    // Timer to reset the alive status every 24 hours
    let _daily = Timer.recurringTimer<system>(#nanoseconds(nanosecondsPerDay), _kill);

    // The idea here is to have a function to call every 24 hours to indicate that you are alive
    public shared ({ caller }) func reboot_dailyCheck(
        mood : Mood
    ) : async () {
        assert (caller == owner);
        alive := true;
        latestPing := Time.now();

        // Write the daily check to the board
        try {
            await board.reboot_writeDailyCheck(name, mood);
        } catch (e) {
            throw e;
        };
    };


    public query func reboot_isAlive() : async Bool {
        return alive;
    };

    public query func reboot_getName() : async Name {
        return name;
    };

    public query func reboot_getOwner() : async Principal {
        return owner;
    };

    public query func reboot_getBirth() : async Int {
        return birth;
    };


    public query func reboot_getAge() : async Int {
        return Time.now() - birth;
    };

    public query ({caller}) func reboot_getFriends() : async [Friends.Friend] {
        assert (caller == owner);
        return friends;
    };

    public shared ({caller}) func reboot_addFriend(
        friend_name : Name,
        friend_principal : Principal
    ) : async () {
        assert (caller == owner);
        friends := Friends.addFriend(friends, friend_name, friend_principal);
    };

     public shared ({caller}) func reboot_sendMessage(
        target_name : Text,
        message_content : Text
     ) : async () {
        assert (caller == owner);
        friends := (await Friends.sendMessage(friends, target_name, caller, message_content));
    };

    public shared ({caller}) func reboot_recieveMessage(
        message : Friends.PrivateMessage,
        sender_principal : Principal
    ) : async () {
        assert (caller == sender_principal);
        friends := Friends.recieveMessage(friends, sender_principal, message);
    };


    public query func http_request(_request : Frontend.Request) : async Frontend.Response {

        var response : Frontend.Response = Frontend.http_request(_request);

        if (Text.contains(response.headers[0].1, #text "text")) {
            let text = Text.decodeUtf8(response.body);
            return switch text {
                case null response;
                case (?val) ({
                        body = Text.encodeUtf8(Replace.replace(val, name, Time.now() - birth));
                        headers = response.headers;
                        status_code = response.status_code;
                    });
            };
        };
        return response;
    };

};
