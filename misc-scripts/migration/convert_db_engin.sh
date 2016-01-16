#!/bin/bash

#The root of the Backup location
RDS_HOST="area51-db.cyhjcpqokgzi.eu-west-1.rds.amazonaws.com"
RDS_USER="area51"

# Read Password
echo -n Database Password: 
read -s RDS_PWD
echo

(
mysql -h ${RDS_HOST} -P 3306 -u ${RDS_USER} -p${RDS_PWD} <<EOF

use ukrgb_phpBB3;

alter TABLE phpbb_acl_groups ENGINE=innodb, ALGORITHM=COPY;
alter TABLE phpbb_acl_options ENGINE=innodb, ALGORITHM=COPY;
alter TABLE phpbb_acl_roles ENGINE=innodb, ALGORITHM=COPY;
alter TABLE phpbb_acl_roles_data ENGINE=innodb, ALGORITHM=COPY;
alter TABLE phpbb_acl_users ENGINE=innodb, ALGORITHM=COPY;
alter TABLE phpbb_attachments ENGINE=innodb, ALGORITHM=COPY;
alter TABLE phpbb_banlist ENGINE=innodb, ALGORITHM=COPY;
alter TABLE phpbb_bbcodes ENGINE=innodb, ALGORITHM=COPY;
alter TABLE phpbb_bookmarks ENGINE=innodb, ALGORITHM=COPY;
alter TABLE phpbb_bots ENGINE=innodb, ALGORITHM=COPY;
alter TABLE phpbb_captcha_answers ENGINE=innodb, ALGORITHM=COPY;
alter TABLE phpbb_captcha_questions ENGINE=innodb, ALGORITHM=COPY;
alter TABLE phpbb_config ENGINE=innodb, ALGORITHM=COPY;
alter TABLE phpbb_confirm ENGINE=innodb, ALGORITHM=COPY;
alter TABLE phpbb_disallow ENGINE=innodb, ALGORITHM=COPY;
alter TABLE phpbb_drafts ENGINE=innodb, ALGORITHM=COPY;
alter TABLE phpbb_extension_groups ENGINE=innodb, ALGORITHM=COPY;
alter TABLE phpbb_extensions ENGINE=innodb, ALGORITHM=COPY;
alter TABLE phpbb_forums ENGINE=innodb, ALGORITHM=COPY;
alter TABLE phpbb_forums_access ENGINE=innodb, ALGORITHM=COPY;
alter TABLE phpbb_forums_track ENGINE=innodb, ALGORITHM=COPY;
alter TABLE phpbb_forums_watch ENGINE=innodb, ALGORITHM=COPY;
alter TABLE phpbb_groups ENGINE=innodb, ALGORITHM=COPY;
alter TABLE phpbb_icons ENGINE=innodb, ALGORITHM=COPY;
alter TABLE phpbb_lang ENGINE=innodb, ALGORITHM=COPY;
alter TABLE phpbb_log ENGINE=innodb, ALGORITHM=COPY;
alter TABLE phpbb_login_attempts ENGINE=innodb, ALGORITHM=COPY;
alter TABLE phpbb_moderator_cache ENGINE=innodb, ALGORITHM=COPY;
alter TABLE phpbb_mods ENGINE=innodb, ALGORITHM=COPY;
alter TABLE phpbb_modules ENGINE=innodb, ALGORITHM=COPY;
alter TABLE phpbb_poll_options ENGINE=innodb, ALGORITHM=COPY;
alter TABLE phpbb_poll_votes ENGINE=innodb, ALGORITHM=COPY;
alter TABLE phpbb_posts ENGINE=innodb, ALGORITHM=COPY;
alter TABLE phpbb_privmsgs ENGINE=innodb, ALGORITHM=COPY;
alter TABLE phpbb_privmsgs_folder ENGINE=innodb, ALGORITHM=COPY;
alter TABLE phpbb_privmsgs_rules ENGINE=innodb, ALGORITHM=COPY;
alter TABLE phpbb_privmsgs_to ENGINE=innodb, ALGORITHM=COPY;
alter TABLE phpbb_profile_fields ENGINE=innodb, ALGORITHM=COPY;
alter TABLE phpbb_profile_fields_data ENGINE=innodb, ALGORITHM=COPY;
alter TABLE phpbb_profile_fields_lang ENGINE=innodb, ALGORITHM=COPY;
alter TABLE phpbb_profile_lang ENGINE=innodb, ALGORITHM=COPY;
alter TABLE phpbb_qa_confirm ENGINE=innodb, ALGORITHM=COPY;
alter TABLE phpbb_ranks ENGINE=innodb, ALGORITHM=COPY;
alter TABLE phpbb_reports ENGINE=innodb, ALGORITHM=COPY;
alter TABLE phpbb_reports_reasons ENGINE=innodb, ALGORITHM=COPY;
alter TABLE phpbb_search_results ENGINE=innodb, ALGORITHM=COPY;
alter TABLE phpbb_search_wordlist ENGINE=innodb, ALGORITHM=COPY;
alter TABLE phpbb_search_wordmatch ENGINE=innodb, ALGORITHM=COPY;
alter TABLE phpbb_sessions ENGINE=innodb, ALGORITHM=COPY;
alter TABLE phpbb_sessions_keys ENGINE=innodb, ALGORITHM=COPY;
alter TABLE phpbb_sitelist ENGINE=innodb, ALGORITHM=COPY;
alter TABLE phpbb_smilies ENGINE=innodb, ALGORITHM=COPY;
alter TABLE phpbb_styles ENGINE=innodb, ALGORITHM=COPY;
alter TABLE phpbb_tapatalk_push_data ENGINE=innodb, ALGORITHM=COPY;
alter TABLE phpbb_tapatalk_users ENGINE=innodb, ALGORITHM=COPY;
alter TABLE phpbb_topics ENGINE=innodb, ALGORITHM=COPY;
alter TABLE phpbb_topics_posted ENGINE=innodb, ALGORITHM=COPY;
alter TABLE phpbb_topics_track ENGINE=innodb, ALGORITHM=COPY;
alter TABLE phpbb_topics_watch ENGINE=innodb, ALGORITHM=COPY;
alter TABLE phpbb_user_group ENGINE=innodb, ALGORITHM=COPY;
alter TABLE phpbb_users ENGINE=innodb, ALGORITHM=COPY;
alter TABLE phpbb_warnings ENGINE=innodb, ALGORITHM=COPY;
alter TABLE phpbb_words ENGINE=innodb, ALGORITHM=COPY;
alter TABLE phpbb_zebra ENGINE=innodb, ALGORITHM=COPY;

  
EOF
)
