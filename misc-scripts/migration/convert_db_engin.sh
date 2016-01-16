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

alter TABLE phpbb_acl_groups,
phpbb_acl_options,
phpbb_acl_roles,
phpbb_acl_roles_data,
phpbb_acl_users,
phpbb_attachments,
phpbb_banlist,
phpbb_bbcodes,
phpbb_bookmarks,
phpbb_bots,
phpbb_captcha_answers,
phpbb_captcha_questions,
phpbb_config,
phpbb_confirm,
phpbb_disallow,
phpbb_drafts,
phpbb_extension_groups,
phpbb_extensions,
phpbb_forums,
phpbb_forums_access,
phpbb_forums_track,
phpbb_forums_watch,
phpbb_groups,
phpbb_icons,
phpbb_lang,
phpbb_log,
phpbb_login_attempts,
phpbb_moderator_cache,
phpbb_mods,
phpbb_modules,
phpbb_poll_options,
phpbb_poll_votes,
phpbb_posts,
phpbb_privmsgs,
phpbb_privmsgs_folder,
phpbb_privmsgs_rules,
phpbb_privmsgs_to,
phpbb_profile_fields,
phpbb_profile_fields_data,
phpbb_profile_fields_lang,
phpbb_profile_lang,
phpbb_qa_confirm,
phpbb_ranks,
phpbb_reports,
phpbb_reports_reasons,
phpbb_search_results,
phpbb_search_wordlist,
phpbb_search_wordmatch,
phpbb_sessions,
phpbb_sessions_keys,
phpbb_sitelist,
phpbb_smilies,
phpbb_styles,
phpbb_tapatalk_push_data,
phpbb_tapatalk_users,
phpbb_topics,
phpbb_topics_posted,
phpbb_topics_track,
phpbb_topics_watch,
phpbb_user_group,
phpbb_users,
phpbb_warnings,
phpbb_words,
phpbb_zebra
ENGINE=innodb, ALGORITHM=COPY;

  
EOF
)
