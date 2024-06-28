import Array "mo:base/Array";
import Principal "mo:base/Principal";
import Time "mo:base/Time";
import Timer "mo:base/Timer";
import Text "mo:base/Text";
import Buffer "mo:base/Buffer";
import TFriends "./canisters/friends/types";
import Cycles "mo:base/ExperimentalCycles";
import Nat "mo:base/Nat";
import Int "mo:base/Int";
import Result "mo:base/Result";
import Frontend "frontend/__html__";
import Replace "replace";
import Bool "mo:base/Bool";
import Float "mo:base/Float";
import Http "http";
import Prim "mo:⛔";

shared ({ caller = creator }) actor class UserCanister(
    yourName : Text,
) = this {
    let NANOSECONDS_PER_DAY = 24 * 60 * 60 * 1_000_000_000;

    stable let version : (Nat, Nat, Nat) = (0, 0, 1);
    stable let birth : Time.Time = Time.now();
    stable let owner : Principal = creator;
    stable let name : Name = yourName;

    public type Mood = Text;
    public type Name = Text;
    public type Friend = TFriends.Friend;
    public type FriendRequest = TFriends.FriendRequest;
    public type FriendRequestResult = TFriends.FriendRequestResult;
    public type Result<Ok, Err> = Result.Result<Ok, Err>;

    stable var alive : Bool = true;
    stable var latestPing : Time.Time = Time.now();
    stable var modules : [(Text, Principal)] = [];
    
//-----------------------BASE-----------------------

    // Function to kill the user if they haven't pinged in 24 hours
    func _kill() : async () {
        let now = Time.now();
        if (now - latestPing > NANOSECONDS_PER_DAY) {
            alive := false;
        };
    };

    // Timer to reset the alive status every 24 hours
    let _daily = Timer.recurringTimer<system>(#nanoseconds(NANOSECONDS_PER_DAY), _kill);

    public query func reboot_user_isAlive() : async Bool {
        return alive;
    };

    // Import the board actor and related types
    public type WriteError = {
        #NotEnoughCycles;
        #MemoryFull;
        #NameTooLong;
        #MoodTooLong;
        #NotAllowed;
    };

    public type MessageError = {
        #NotEnoughCycles;
        #MemoryFull;
        #MessageTooLong;
        #NotAllowed;
    };

    let board = actor ("q3gy3-sqaaa-aaaas-aaajq-cai") : actor {
        reboot_board_write : (name : Name, mood : Mood) -> async Result<(), WriteError>;
    };

    public shared ({ caller }) func reboot_user_dailyCheck(
        mood : Mood
    ) : async Result<(), WriteError> {
        assert (caller == owner);
        alive := true;
        latestPing := Time.now();

        // Write the daily check to the board
        try {
            Cycles.add<system>(1_000_000_000);
            await board.reboot_board_write(name, mood);
        } catch (e) {
            throw e;
        };
    };


//-----------------------END BASE-------------------
//-----------------------Friends--------------------

    public query ({caller}) func reboot_getName() : async Name {
        assert (caller == owner);
        return name;
    };

    public query ({caller}) func reboot_getOwner() : async Principal {
        assert (caller == owner);
        return owner;
    };

    public query ({caller}) func reboot_getBirth() : async Int {
        assert (caller == owner);
        return birth;
    };

    public query ({caller}) func reboot_getAge() : async Int {
        assert (caller == owner);
        return Time.now() - birth;
    };

    // public shared ({ caller }) func reboot_friends_receiveFriendRequest(
    stable var messagesId : Nat = 0;
    var messages : [(Nat, Text)] = [];

    public shared query func reboot_user_getModules () : async [(Text, Principal)] {
        return modules;
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
    
//-----------------------END Friends----------------


//-----------------------Admin----------------------

    public query func reboot_user_version() : async (Nat, Nat, Nat) {
        return version;
    };

    private func getModule(moduleName : Text) : Principal {
        for (mod in modules.vals()) {
            if (mod.0 == moduleName) {
                return mod.1;
            };
        };
        return Principal.fromActor(this);
    };

//-----------------------END Admin------------------

};
