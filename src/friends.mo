import Principal "mo:base/Principal";
import Time "mo:base/Time";
import Array "mo:base/Array";
import Error "mo:base/Error";

module {
    public type Friend = {
        name : Text;
        principal : Principal;
        conversation : [PrivateMessage];
    };

    public type PrivateMessage = {
        me : Bool;
        content : Text;
        time : Time.Time;
    };

    public func addFriend(friends : [Friend], target_name : Text, principal : Principal) : [Friend] {
        switch (Array.find<Friend>(friends, func(f : Friend) { f.name == target_name or f.principal == principal;}))
        {
            case (null) {};
            case (?friend) { return friends; };
        };
        return Array.append(friends, [{
            name = target_name;
            principal = principal;
            conversation = [];
        }]);
    };

    public func sendMessage(friends : [Friend], target_name : Text, my_principal : Principal, message_content : Text) : async [Friend] {
        let friend_principal = switch (Array.find<Friend>(friends, func(f : Friend) { f.name == target_name;}))
        {
            case (null) { throw Error.reject("No friend with provided name : " # target_name);};
            case (?friend) { friend.principal};
        };
        let userCanister = actor (Principal.toText(friend_principal)) : actor {
            reboot_recieveMessage : shared (PrivateMessage, Principal) -> async ();
        };
        await userCanister.reboot_recieveMessage({
            me = false;
            content = message_content;
            time = Time.now();
        }, friend_principal);
        return Array.map<Friend, Friend>(friends, func(f : Friend) { 
            if (f.name == target_name){({
                name = f.name;
                principal = f.principal;
                conversation = Array.append(f.conversation, [{
                    me = true;
                    content = message_content;
                    time = Time.now();
                }]);
            })} else {f};
         });
    };

    public func recieveMessage(friends : [Friend], sender_principal : Principal, message : PrivateMessage) : [Friend] {
        var friend = switch (Array.find<Friend>(friends, func(f : Friend) { f.principal == sender_principal;}))
        {
            case (null) { return friends; };
            case (?friend) { friend };
        };

        return Array.map<Friend, Friend>(friends, func(f : Friend) { 
            if (f.principal == sender_principal){({
                name = friend.name;
                principal = friend.principal;
                conversation = Array.append(friend.conversation, [message]);
            })
            } else {f};
         });
    };

}