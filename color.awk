function  BLACK(X)             { return "\033[30m"   X "\033[0m" }
function  RED(X)               { return "\033[31m"   X "\033[0m" }
function  GREEN(X)             { return "\033[32m"   X "\033[0m" }
function  YELLOW(X)            { return "\033[33m"   X "\033[0m" }
function  BLUE(X)              { return "\033[34m"   X "\033[0m" }
function  MAGENTA(X)           { return "\033[35m"   X "\033[0m" }
function  CYAN(X)              { return "\033[36m"   X "\033[0m" }
function  WHITE(X)             { return "\033[37m"   X "\033[0m" }
function  BRIGHT_BLACK(X)      { return "\033[90m"   X "\033[0m" }
function  BRIGHT_RED(X)        { return "\033[91m"   X "\033[0m" }
function  BRIGHT_GREEN(X)      { return "\033[92m"   X "\033[0m" }
function  BRIGHT_YELLOW(X)     { return "\033[93m"   X "\033[0m" }
function  BRIGHT_BLUE(X)       { return "\033[94m"   X "\033[0m" }
function  BRIGHT_MAGENTA(X)    { return "\033[95m"   X "\033[0m" }
function  BRIGHT_CYAN(X)       { return "\033[96m"   X "\033[0m" }
function  BRIGHT_WHITE(X)      { return "\033[97m"   X "\033[0m" }
function  BG_BLACK(X)          { return "\033[40m"   X "\033[0m" }
function  BG_RED(X)            { return "\033[41m"   X "\033[0m" }
function  BG_GREEN(X)          { return "\033[42m"   X "\033[0m" }
function  BG_YELLOW(X)         { return "\033[43m"   X "\033[0m" }
function  BG_BLUE(X)           { return "\033[44m"   X "\033[0m" }
function  BG_MAGENTA(X)        { return "\033[45m"   X "\033[0m" }
function  BG_CYAN(X)           { return "\033[46m"   X "\033[0m" }
function  BG_WHITE(X)          { return "\033[47m"   X "\033[0m" }
function  BG_BRIGHT_BLACK(X)   { return "\033[100m"  X "\033[0m" }
function  BG_BRIGHT_RED(X)     { return "\033[101m"  X "\033[0m" }
function  BG_BRIGHT_GREEN(X)   { return "\033[102m"  X "\033[0m" }
function  BG_BRIGHT_YELLOW(X)  { return "\033[103m"  X "\033[0m" }
function  BG_BRIGHT_BLUE(X)    { return "\033[104m"  X "\033[0m" }
function  BG_BRIGHT_MAGENTA(X) { return "\033[105m"  X "\033[0m" }
function  BG_BRIGHT_CYAN(X)    { return "\033[106m"  X "\033[0m" }
function  BG_BRIGHT_WHITE(X)   { return "\033[107m"  X "\033[0m" }
#function  SKYBLUE(X)           { return "\033[38;2;40;177;249m" X "\033[0m" }
function  BL_BRIGHT_RED(X)     { return "\033[91;5m"  X "\033[0m" }
function  BL_BRIGHT_YELLOW(X)  { return "\033[93;5m"  X "\033[0m" }
function  BL_BRIGHT_BLUE(X)    { return "\033[94;5m"  X "\033[0m" }
function  BL_BRIGHT_MAGENTA(X) { return "\033[35;5m"  X "\033[0m" }
function  BL_BRIGHT_CYAN(X)    { return "\033[96;5m"  X "\033[0m" }

function percent_bar(percent){
    sub(/%/, "", percent)
    space=""
    for(i=1;i<=17;i++){
        space=space" "
    }
    total_space_len=length(space)

    if(percent ~ /\//){
        each_space=""
        split(percent,pct,"/")
        total_num=length(pct)
        each_space_len=int((total_space_len - total_num - 1)/total_num + 0.9)
        for(i=1;i<=each_space_len;i++){
            each_space=each_space" "
        }
        for(i in pct){
            leadingspace=""
            trailingspace=""
            pc=pct[i]
            p=int(each_space_len*(pc/100)+0.5)
            leadingspace=substr(each_space,0,p)
            trailingspace=substr(each_space,p+1,each_space_len)
            if(pc*1 > 80 && pc*1 <= 89){
                bar=bar"\033[43;37m" leadingspace "\033[47;30m"  trailingspace "\033[0m""/"
            } else if(pc*1 > 89){
                bar=bar"\033[41;37m" leadingspace "\033[47;30m"  trailingspace "\033[0m""/"
            } else{
               bar=bar"\033[104;37m" leadingspace "\033[47;30m"  trailingspace "\033[0m""/"
            }
        }
        # remove "/" at the end
        sub(/\/$/, "", bar)
        return bar
    }

    p=int(total_space_len*(percent/100)+0.5)
    leadingspace=substr(space,0,p)
    trailingspace=substr(space,p+1,total_space_len)
    if(percent*1 > 80 && percent*1 <= 89){
        return "\033[43;37m" leadingspace "\033[47;30m"  trailingspace "\033[0m"
    } else if(percent*1 > 89){
        return "\033[41;37m" leadingspace "\033[47;30m"  trailingspace "\033[0m"
    } else{
        return "\033[104;37m" leadingspace "\033[47;30m"  trailingspace "\033[0m"
    }
}
