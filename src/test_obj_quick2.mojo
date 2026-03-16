from std.testing import assert_true

def main() raises:
    var line = String("v 1.0 2.0 3.0")
    # test byte access
    var c = line[byte=0]
    print(c)
    
    # test splitlines
    var content = String("v 1.0 2.0 3.0\nf 1 2 3\n")
    var lines = content.splitlines()
    for i in range(len(lines)):
        var l = String(lines[i])
        print(l)
        if l.startswith("v"):
            print("found v line")
