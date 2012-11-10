Create Gitorious' merge requests from command-line

Installation
===========

    gem install gitorious-merge-request

or from source:

    bundle install

Examples
========

    gitorious-merge-request --help
    gitorious-merge-request new --help
    gitorious-merge-request show --help
    gitorious-merge-request rm --help

    gitorious-merge-request new -e brauliobo@gmail.com -s 'test' -r '~brauliobo/noosfero/brauliobos-noosfero' -a easysafeinstall -b master -t 'noosfero/noosfero'
    gitorious-merge-request show -c noosfero/noosfero:248

    gitorious-merge-request rm -c eita/test:3 -e brauliobo@gmail.com






