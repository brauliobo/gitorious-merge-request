Create Gitorious' merge requests from command-line

Installation
============

    gem install gitorious-merge-request

or from source:

    bundle install

List of commands
================

*   new
*   show
*   rm
*   list
*   diff
*   checkout

Examples
========

    gitorious-merge-request --help
    gitorious-merge-request command --help

    gitorious-merge-request new -e brauliobo@gmail.com -s 'test' -r '~brauliobo/noosfero/brauliobos-noosfero' -a easysafeinstall -b master -t 'noosfero/noosfero'
    gitorious-merge-request show -c noosfero/noosfero:248

    gitorious-merge-request rm -c eita/test:3 -e brauliobo@gmail.com

    # will use remote origin to guess repo
    gitorious-merge-request list
    gitorious-merge-request list -r eita/test

    gitorious-merge-request diff -c 5
    gitorious-merge-request checkout -c 5






