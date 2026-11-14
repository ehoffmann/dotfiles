" Read marks drawn by gitreview#qftext() in review lists.
syntax match qfReviewRead /^✓ .*/
syntax match qfReviewChanged /^\~ .*/
highlight default link qfReviewRead Comment
highlight default link qfReviewChanged WarningMsg
