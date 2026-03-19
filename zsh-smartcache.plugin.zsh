ZSH_SMARTCACHE_DIR=${ZSH_SMARTCACHE_DIR:-${XDG_CACHE_HOME:-$HOME/.cache}/zsh-smartcache}

_smartcache-eval() {
    local cache=$ZSH_SMARTCACHE_DIR/eval-$1; shift
    if [[ ! -f $cache ]] {
        local output=$("$@")
        eval $output
        {
            printf '%s' $output >| $cache
            zcompile $cache
        } &!
    } else {
        source $cache
        {
            local output=$("$@")
            [[ $output == "$(<$cache)" ]] && return
            printf '%s' $output >| $cache
            zcompile $cache
            print "smartcache: '$@' updated (takes effect next launch)"
        } &!
    }
}

_smartcache-comp() {
    local cache=$ZSH_SMARTCACHE_DIR/_$1; shift
    if [[ ! -f $cache ]] {
        "$@" >| $cache
    } else {
        {
            local output=$("$@")
            [[ $output == "$(<$cache)" ]] && return
            printf '%s' $output >| $cache
            print "smartcache: '$@' updated (takes effect next launch)"
        } &!
    }
    # fpath is set unique by default so it's OK to append multiple times.
    fpath+=($ZSH_SMARTCACHE_DIR)
}

smartcache() {
    emulate -LR zsh -o extended_glob -o err_return

    # Doing these lately as users might change settings after plugin loading.
    [[ -d $ZSH_SMARTCACHE_DIR ]] || mkdir -p $ZSH_SMARTCACHE_DIR

    local -i hash=2166136261
    for c in ${(s::)@:3}; (( hash = ((hash ^ #c) * 16777619) & 0xffffffff ))
    _smartcache-$1 $2-$(([##16]hash)) "${@:2}"
}
