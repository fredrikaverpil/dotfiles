# Per-platform settings
case `uname` in
    Darwin)
        # commands for macOS go here
    ;;
    Linux)
        # commands for Linux go here
        if [ -f /etc/redhat-release ]; then
            # https://modules.readthedocs.io/en/latest/index.html
            # module avail [app]
            # module load git
            module load $(module avail git --latest | sed -nre 's/^git\/[^0-9]*(([0-9]+\.)*[0-9]+).*/\0/p')
            module load python/3.6.6
            module load python/3.7.4
            module load python/3.8.5
            module load python/3.9.0
            # module load chrome/83.0.4103.116-1
            module load $(module avail chrome --latest | sed -nre 's/^chrome\/[^0-9]*(([0-9]+\.)*[0-9]+).*/\0/p')
            module load $(module avail firefox --latest | sed -nre 's/^firefox\/[^0-9]*(([0-9]+\.)*[0-9]+).*/\0/p')
            # module list
        fi
    ;;
    FreeBSD)
        # commands for FreeBSD go here
    ;;
esac
