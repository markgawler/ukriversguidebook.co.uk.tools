#!/bin/bash
acme.sh --install-cert -d ukriversguidebook.co.uk \
--cert-file      /etc/ssl/ukrgb/letsencrypt/cert.pem  \
--key-file       /etc/ssl/ukrgb/letsencrypt/key.pem  \
--fullchain-file /etc/ssl/ukrgb/letsencrypt/fullchain.pem \
--reloadcmd     "service apache2 force-reload"
