# Per-platform settings
case `uname` in
    Darwin)
        alias ll='ls -alhF'
        alias tree='tree -C'
        alias wrk='docker run --rm skandyla/wrk'
        alias venv='echo "venv" >> .gitignore && python3 -m venv venv && source venv/bin/activate && pip install -U pip pylint black pep8 pydocstyle && pip list && python --version'
        alias activate='source venv/bin/activate'

    ;;
    Linux)
        # commands for Linux go here
    ;;
    FreeBSD)
        # commands for FreeBSD go here
    ;;
esac
