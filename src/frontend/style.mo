import Text "mo:base/Text";
module { 
 public func get_html() : Blob { return Text.encodeUtf8("html, body {"
#"  width: 100%;"
#"  height:100%;"
#"}"
#""
#"body {"
#"    background: linear-gradient(-45deg, #ee7752, #e73c7e, #23a6d5, #23d5ab);"
#"    background-size: 400% 400%;"
#"    animation: gradient 15s ease infinite;"
#"    font-family: 'Roboto', sans-serif;"
#"}"
#""
#"@keyframes gradient {"
#"    0% {"
#"        background-position: 0% 50%;"
#"    }"
#"    50% {"
#"        background-position: 100% 50%;"
#"    }"
#"    100% {"
#"        background-position: 0% 50%;"
#"    }"
#"}"
#"");
 };
}