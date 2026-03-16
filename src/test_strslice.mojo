def main() raises:
    var s = String("1/2/3")
    # find slash
    var slash = -1
    for i in range(len(s)):
        if String(s[byte=i]) == "/":
            slash = i
            break
    print("slash at:", slash)
    
    # build substring manually
    var prefix = String("")
    for i in range(slash):
        prefix += String(s[byte=i])
    print("prefix:", prefix)
    print("Int:", Int(prefix))
