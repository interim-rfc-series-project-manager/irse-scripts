# irse-scripts
Scripts the iRSE used for various things

## Monthly surveys
`mksurvey.py`
Script to extract author names and addresses from recent RFCs, and shepherd addresses from the Datatracker, 
and make survey message to send out.

`surveyconfig.txt`
Config info for mksurvey.py

`template.msg`
Mail message template for surveys

`sendsurveys`
Script that sends the messages that mksurvey.py created

## Tweeting out RFCs

`tweetit`
Script to read a an RFC announcement message and tweet out the good bits

`rfcannounce.py`
Read an RFC announcement message and pick out the RFC number, title, author, and abstract

`tweet.pl`
Read input and turn into 
