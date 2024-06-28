import Array "mo:base/Array";
import Principal "mo:base/Principal";
import Text "mo:base/Text";
import Types "types";
import Cycles "mo:base/ExperimentalCycles";
import Nat "mo:base/Nat";
import Result "mo:base/Result";
import Buffer "mo:base/Buffer";

shared ({ caller = creator }) actor class ContactsCanister(
    yourName : Text,
) = this {

    public type Result<Ok, Err> = Result.Result<Ok, Err>;
    public type Mood = Text;
    public type Name = Text;
    public type Contact = Types.Contact;
    public type RelationshipRequest = Types.RelationshipRequest;
    public type RelationshipRequestResult = Types.RelationshipRequestResult;



    // stable var friendRequestId : Nat = 0;
    stable var relationshipRequests : [RelationshipRequest] = [];
    stable var contacts : [Contact] = [];
    let name : Name = yourName;

    let owner : Principal = creator;

    public query func reboot_contacts_supportedStandards() : async [{
        name : Text;
        url : Text;
    }] {
        return ([{
            name = "contacts";
            url = "https://github.com/motoko-bootcamp/reboot/blob/main/standards/contacts.md";
        }]);
    };

    public shared ({ caller }) func reboot_contacts_sendFriendRequest(
        receiver : Principal,
        message : Text,
    ) : async RelationshipRequestResult {

        assert (caller == owner);

        // Create the actor reference
        let contactUserActor = actor (Principal.toText(receiver)) : actor {
            reboot_contacts_receiveFriendRequest : (name : Text, message : Text, senderPrincipal : Principal) -> async RelationshipRequestResult;
        };

        // Attach the cycles to the call (1 billion cycles)
        Cycles.add<system>(500_000_000);

        // Call the function (handle potential errors)
        try {
            return await contactUserActor.reboot_contacts_receiveFriendRequest(name, message, caller);
        } catch (e) {
            throw e;
        };
    };

    public shared ({ caller }) func reboot_contacts_receiveFriendRequest(
        name : Text,
        message : Text,
        senderPrincipal : Principal
    ) : async RelationshipRequestResult {
        
        //Check if the caller is the User Canister.
        assert(caller == owner);

        let relationshipRequestsBuffer : Buffer.Buffer<RelationshipRequest> = Buffer.fromArray(relationshipRequests);

        // Check if there is enough cycles attached (Fee for Friend Request) and accept them
        let availableCycles = Cycles.available();
        let acceptedCycles = Cycles.accept<system>(availableCycles);
        if (acceptedCycles < 500_000_000) {
            return #err(#NotEnoughCycles);
        };


        let request : RelationshipRequest = {
            name = name;
            sender = senderPrincipal;
            message = message;
        };

        // Check if the user is already a friend
        for (friend in contacts.vals()) {
            if (friend.canisterId == senderPrincipal) {
                return #err(#AlreadyExistingRelationship);
            };
        };

        // Check if the user has already sent a friend request
        for (req in relationshipRequests.vals()) {
            if (req.sender == senderPrincipal) {
                return #err(#AlreadyRequested);
            };
        };

        relationshipRequestsBuffer.add(request);
        relationshipRequests := Buffer.toArray(relationshipRequestsBuffer);
        return #ok();
    };

    public shared query ({ caller }) func reboot_contacts_getFriendRequests() : async [RelationshipRequest] {
        assert (caller == owner);
        return relationshipRequests;
    };

    public shared func test () : async () {
        relationshipRequests := [];
    };

    public shared ({ caller }) func reboot_contacts_handleFriendRequest(
        index : Nat,
        accept : Bool,
    ) : async Result<(), Text> {

        assert (caller == owner);

        // Check if the index is valid
        if (index >= relationshipRequests.size())
        {
            return #err("Friend request not found for index " # Nat.toText(index));
        };

        
       if (accept) {

            // let contactsBuffer : Buffer.Buffer<Contact> = Buffer.fromArray(contacts);

            //TODO: GENERATE THE RELATIONSHIP, the request to accept is in relationshipRequests[index]
            return #ok();
        };
        relationshipRequests := Array.filter<RelationshipRequest>(relationshipRequests, func(x : RelationshipRequest) { x.sender != relationshipRequests[index].sender });
        return #ok();
    };

    public shared query ({ caller }) func reboot_contacts_getContacts() : async [Contact] {
        assert (caller == owner);
        return contacts;
    };

    public shared ({ caller }) func reboot_contacts_removeFriend(
        canisterId : Principal
    ) : async Result<(), Text> {
        assert (caller == owner);

        for (friend in contacts.vals()) {
            if (friend.canisterId == canisterId) {
                contacts := Array.filter<Contact>(contacts, func(x : Contact) { x.canisterId != canisterId });
                return #ok();
            };
        };

        return #err("Friend not found with canisterId " # Principal.toText(canisterId));
    };

};
