from std.testing import assert_true

def _split_line(line: String) -> List[String]:
    var tokens = List[String]()
    var current = String("")
    for i in range(len(line)):
        var c = String(line[byte=i])
        if c == " " or c == "\t":
            if len(current) > 0:
                tokens.append(current)
                current = String("")
        else:
            current += c
    if len(current) > 0:
        tokens.append(current)
    return tokens^

def main() raises:
    var line = String("v 1.0 2.0 3.0")
    var tokens = _split_line(line)
    print(len(tokens))
    for i in range(len(tokens)):
        print(tokens[i])
