import Int "mo:base/Int";
import Text "mo:base/Text";
import Float "mo:base/Float";

module {

    public func replace (text : Text, name : Text, age : Int) : Text {
        var _text = Text.replace(text, #text "__NAME__", name);
        _text := Text.replace(_text, #text "__AGE__", Int.toText(age));
        _text := Text.replace(_text, #text "__FULL_AGE__", get_full_age(age));
        return _text;
    };

    public func get_full_age (age : Int) : Text {
        var full_age : Text = "";

        //temp is the time in seconds
        var temp = age / 1_000_000_000;

        full_age := Int.toText(temp % 60) # " seconds";

        //temp is the time in minutes
        temp := temp / 60;
        if (temp == 0) {
            return full_age;
        };
        full_age := Int.toText(temp % 60) # " minutes, " # full_age;


        //temp is the time in hours
        temp := temp / 60;
        if (temp == 0) {
            return full_age;
        };
        full_age := Int.toText(temp % 24) # " hours, " # full_age;

        //temp is the time in days
        temp := temp / 24;
        if (temp == 0) {
            return full_age;
        };
        full_age := Int.toText(temp % 365) # " days, " # full_age;

        //temp is the time in years
        temp := Float.toInt(Float.fromInt(temp) / 365.25);
        if (temp == 0) {
            return full_age;
        };
        full_age := Int.toText(temp) # " years " # full_age;

        return full_age;
    };

}