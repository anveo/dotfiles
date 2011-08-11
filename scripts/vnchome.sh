#!/bin/sh

ssh -f -L 5900:localhost:5900 bracer@anveo.dyndns.org \
        x11vnc -safer -localhost -nopw -once -display :0 \
        && sleep 5 \
        && vncviewer localhost:0
