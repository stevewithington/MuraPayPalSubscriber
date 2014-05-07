# MuraPayPalSubscriber

**SEE THE INSTRUCTIONS FOUND AT /ADMIN/VIEWS/INSTRUCTIONS/DEFAULT.CFM**

## WARNING!!! USE AT YOUR OWN RISK!!
This plugin has NOT been tested in a production application! It's more of a proof of
concept, but thought it could be useful to other Mura CMS plugin developers looking
for a PayPal Subscription management plugin.

This plugin assumes Adobe ColdFusion 8+ and Microsoft SQL Server. Not fully tested on MySQL. In addition, this is NOT designed for multi-site installs (yet)!!!

## INTRODUCTION
This is a [Mura CMS](http://getmura.com) plugin to allow clients the ability to lock down
specific areas of a site to PayPal subscriber groups. Please note it is NOT fully
functional yet and needs some additional work. The TODO list is most definitely NOT
complete by any means.

## TODOs
1. Better instructions.
2. Auto-'hide' the body as needed for display purposes.
3. Auto-cancel all subscriber's accounts when deleting a muraSubscriber group
4. Handle user updates that occur outside of the plugin (i.e., Site Members). What would happen 
when a user is changed from a subtype of 'muraSubscriber' to something else? 
5. Possibly prevent Admins from being able to edit user fields that contain PayPal information.
6. 'Instant Payment Notification' (IPN) handler. These are automated form posts from PayPal as 
particular transactions take place ... for example, if a subscriber cancels their plan via PayPal 
vs. this site, the data is submitted to a pre-specified 'notifyURL'
7. Tested (not thoroughly) on CF9 and CF8 running Microsoft SQL Server on Windows (one running IIS, the other 
running Apache), it would be nice to run additional test configurations 
(i.e., Railo, MySQL, Linux etc.)