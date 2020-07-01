# Per-platform settings
case `uname` in
    Darwin)
        # commands for macOS go here
    ;;
    Linux)
        # commands for Linux go here
        if [ -f /etc/redhat-release ]; then
            # module avail [app]
            module load git
            module load python/3.7.4
            module load chrome/75.0.3770.100-1
            # module list
        fi
    ;;
    FreeBSD)
        # commands for FreeBSD go here
    ;;
esac