# Per-platform settings
case `uname` in
    Darwin)
        alias ll='ls -alhF'
        alias tree='tree -C'
        alias gg='git grep'
        alias rebase='git pull origin master'
        alias wrk='docker run --rm skandyla/wrk'

        alias venv='echo "venv" >> .gitignore && python3 -m venv venv && source venv/bin/activate && pip install -U pip black flake8 pydocstyle && pip list && python --version'
        alias activate='source venv/bin/activate'
        alias pyclean='find . -name "*.py[co]" -o -name __pycache__ -exec rm -rf {}'
        alias pip-purge='pip freeze | xargs pip uninstall -y'

    ;;
    Linux)
        # commands for Linux go here
    ;;
    FreeBSD)
        # commands for FreeBSD go here
    ;;
esac
