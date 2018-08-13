# ***************************************************************************
# Copyright (c) 2013 SAP AG or an SAP affiliate company. All rights reserved.
# ***************************************************************************
get_lang_code()
###############
# Returns current language environment code
{
    case $LANG in
	ja* )
	    LANGCODE="ja"
	    ;;
	zh_HK* | zh_TW* | zh_SG* )
	    LANGCODE="en"
	    ;;
	zh* )
	    LANGCODE="zh"
           ;;
        de* )
	    LANGCODE="de"
           ;;
        fr* )
	    LANGCODE="fr"
           ;;
        * )
	    LANGCODE="en"
	    ;;
    esac
    echo $LANGCODE
}
