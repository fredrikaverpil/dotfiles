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
            module load python/3.6.6
            module load python/3.7.4
            module load python/3.8.5
            module load python/3.9.0
            module load chrome/83.0.4103.116-1
            # module list
        fi
    ;;
    FreeBSD)
        # commands for FreeBSD go here
    ;;
esac
