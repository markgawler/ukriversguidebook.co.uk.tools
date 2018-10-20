#!/bin/bash
cd  ~/ukriversguidebook.co.uk.tools/misc-scripts/backup
./site_restore.sh
./create_db_users.sh 
./site_restore.sh
