#!/usr/bin/env bash
###
# Thanks to https://github.com/laravel/valet/edit/master/valet
# Fill fix this up later for bash command line usage
# if needed
###

SOURCE="${BASH_SOURCE[0]}"

# If the current source is a symbolic link, we need to resolve it to an
# actual directory name. We'll use PHP to do this easier than we can
# do it in pure Bash. So, we'll call into PHP CLI here to resolve.
if [[ -L $SOURCE ]]
then
    DIR=$(php -r "echo dirname(realpath('$SOURCE'));")
else
    DIR="$( cd "$( dirname "$SOURCE" )" && pwd )"
fi

# If we are in the global Composer "bin" directory, we need to bump our
# current directory up two, so that we will correctly proxy into the
# Valet CLI script which is written in PHP. Will use PHP to do it.
if [ ! -f "$DIR/cli/valet.php" ]
then
    DIR=$(php -r "echo realpath('$DIR/../laravel/valet');")
fi

# If the command is one of the commands that requires "sudo" privileges
# then we'll proxy the incoming CLI request using sudo, which allows
# us to never require the end users to manually specify each sudo.
if [[ "$EUID" -ne 0 ]]
then
    sudo $SOURCE "$@"
    exit
fi

# If the command is the "share" command we will need to resolve out any
# symbolic links for the site. Before starting Ngrok, we will fire a
# process to retrieve the live Ngrok tunnel URL in the background.
if [[ "$1" = "share" ]]
then
    HOST="${PWD##*/}"
    DOMAIN=$(php "$DIR/cli/valet.php" domain)

    for linkname in ~/.valet/Sites/*; do
        if [[ "$(readlink $linkname)" = "$PWD" ]]
        then
            HOST="${linkname##*/}"
        fi
    done

    # Fetch Ngrok URL In Background...
    bash "$DIR/cli/scripts/fetch-share-url.sh" &
    sudo -u $(logname) "$DIR/bin/ngrok" http "$HOST.$DOMAIN:80" -host-header=rewrite ${*:2}
    exit

# Finally, for every other command we will just proxy into the PHP tool
# and let it handle the request. These are commands which can be run
# without sudo and don't require taking over terminals like Ngrok.
else
    php "$DIR/cli/valet.php" "$@"
fi
