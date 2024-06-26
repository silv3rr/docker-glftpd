// docker-glftpd::template

/* zsconfig.h - ZipScript-C config file
 *
 * This file only contains overrides of the defaults. If you need to edit/change
 * other options, please copy the option from README.ZSCONFIG and place it in
 * here.
 * The complete list of options availible is found in README.ZSCONFIG.
 *
 * Please do not change settings you do not understand!
 *
 * The hash char ``#'' does not signify comments! DO NOT REMOVE!
 */


/* DO NOT USE WILDCARDS HERE! */
#define sitepath_dir                 "/site/"
#define group_dirs                   "/site/groups/"
#define zip_dirs                     "/site/test/ /site/incoming/0day/"
#define sfv_dirs                     "/site/test/ /site/incoming/mp3/ /site/incoming/games/ /site/incoming/apps/ /site/incoming/musicvideos/ /site/incoming/requests/"
#define nocheck_dirs                 "/site/private/"
#define noforce_sfv_first_dirs       "/site/incoming/requests/"
#define audio_nocheck_dirs           "/site/groups/ /site/incoming/requests/"
#define allowed_types_exemption_dirs "/site/incoming/musicvideos/"
#define check_for_missing_nfo_dirs   "/site/incoming/games/ /site/incoming/apps/"
#define cleanupdirs                  "/site/test/ /site/incoming/games/ /site/incoming/apps/ /site/incoming/musicvideos/"
#define cleanupdirs_dated            "/site/incoming/0day/%m%d/ /site/incoming/mp3/%m%d/"

#define check_for_missing_sample_dirs "/site/incoming/movies/"
#define create_missing_sample_link   FALSE

#define short_sitename               "NG"

#define debug_mode                   FALSE
#define debug_altlog                 TRUE

#define status_bar_type              BAR_DIR
#define incompleteislink             TRUE

#define ignored_types                ",diz,debug,message,imdb,html,url,m3u,metadata"

#define deny_double_sfv              FALSE
#define force_sfv_first              FALSE

#define audio_genre_path             "/site/incoming/music.by.genre/"
#define audio_artist_path            "/site/incoming/music.by.artist/"
#define audio_year_path              "/site/incoming/music.by.year/"
#define audio_group_path             "/site/incoming/music.by.group/"
#define audio_language_path          "/site/incoming/music.by.language/"
#define allowed_constant_bitrates    "160,192"
#define allowed_years                "2007,2008,2009,2010,2011,2012"
#define banned_genres                "Christian Rap,Christian Gangsta Rap,Contemporary Christian,Christian Rock"
#define allowed_genres               "Top 40,Pop Funk,Rock,Pop"
#define audio_genre_sort             FALSE
#define audio_year_sort              FALSE
#define audio_artist_sort            FALSE
#define audio_group_sort             FALSE
#define audio_language_sort          FALSE
#define audio_cbr_check              TRUE
#define audio_cbr_warn               TRUE
#define audio_year_check             TRUE
#define audio_year_warn              TRUE
#define audio_banned_genre_check     TRUE
#define audio_allowed_genre_check    FALSE
#define audio_genre_warn             TRUE

#define enable_nfo_script            FALSE
#define nfo_script                   "/bin/psxc-imdb.sh"
#define enable_complete_script       FALSE
#define complete_script              "/bin/nfo_copy.sh"
