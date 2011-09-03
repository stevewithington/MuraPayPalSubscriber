<!---

This file is part of MuraPayPalSubscriber
(c) Stephen J. Withington, Jr. | www.stephenwithington.com

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License along
with this program; if not, write to the Free Software Foundation, Inc.,
51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.

		Document:	/admin/controllers/main.cfc
		Author:		Steve Withington | www.stephenwithington.com
		Modified:	2011.09.02

--->
<cfcomponent extends="controller" output="false">

	<!--- ************ pages *************** --->
	<cffunction name="default" output="false" returntype="any">
		<cfargument name="rc" />
		<cfparam name="rc.add" default="false" />
		<cfparam name="rc.update" default="false" />
		<cfparam name="rc.delete" default="false" />
		<cfscript>
			rc.rsSubscriberGroups = getMuraSubscriberGroups(rc);
		</cfscript>
	</cffunction>

	<cffunction name="edit" output="false" returntype="any">
		<cfargument name="rc" />
		<cfset var local = {} />
		
		<cfparam name="rc.groupName" default="" />
		<cfparam name="rc.InActive" default="0" />
		<cfparam name="rc.subscriptionBillingCycleAmount" default="0.00" />
		<cfparam name="rc.subscriptionBillingCycleNumber" default="1" />
		<cfparam name="rc.subscriptionBillingCyclePeriod" default="M" />
		<cfparam name="rc.add" default="false" />
		<cfparam name="rc.update" default="false" />
		<cfparam name="rc.userid" default="" />
		<cfparam name="rc.errors" default="" />
		<cfscript>
			/* 	
				ALPHA/BETA NOTES: 
				Updating a subscription here will NOT update a subscribers billing amount!!!!
				This would require looping over each subscriber, posting an UpdateRecurringPaymentsProfile call
				to PayPal, verifying each response, etc.  ... this could get ugly with thousands of subscribers.
				
				The same thing goes for deleting a subscription option though ... we should technically cancel
				each subscribers subscription at PayPal, etc.
				
				To top things off, PayPal has some pretty strict guidlines on modifying billing frequencies and/or
				billing periods of a profile. For example, no updates to the billing amount on a subscription are 
				allowed within 3 days of the scheduled billing date, otherwise an error is returned.
				
				For more info:
				https://cms.paypal.com/us/cgi-bin/?cmd=_render-content&content_ID=developer/e_howto_api_ECRecurringPayments
			*/
		
			// this would need to change in the future for multi-site installs
			local.rs = getMuraSubscriberGroup(rc);
			if ( local.rs.recordcount ) {
				local.groupBean = application.serviceFactory.getBean('user');
				local.groupBean.loadBy(userid=local.rs.UserID);
				rc.groupName = local.groupBean.getValue('groupName');
				rc.InActive = local.groupBean.getValue('InActive');
				rc.subscriptionBillingCycleAmount = local.groupBean.getValue('subscriptionBillingCycleAmount');
				rc.subscriptionBillingCycleNumber = local.groupBean.getValue('subscriptionBillingCycleNumber');
				rc.subscriptionBillingCyclePeriod = local.groupBean.getValue('subscriptionBillingCyclePeriod');
				rc.update = true;
			} else {
				rc.add = true;
			};
			return;
		</cfscript>
	</cffunction>

	<cffunction name="delete" output="false" returntype="any">
		<cfargument name="rc" />
		<cfset var local = {} />
		
		<cfparam name="rc.userid" default="" />	
		<cfscript>
			if ( IsValid('uuid', rc.userid) ) {
				
				// future TODO: before deleting a GROUP, cancel each member's subscription at PayPal!
				
				local.groupBean = application.serviceFactory.getBean('user');
				local.groupBean.loadBy(userid=rc.UserID);
				try {
					local.groupBean.delete();
				} catch (any e) {
					rc.delete = false;
				};
				rc.delete = true;
			} else {
				rc.delete = false;
			};
			fw.redirect(action="admin:main",append='delete',path='');
			return;
		</cfscript>
	</cffunction>

	<cffunction name="submit" output="false" returntype="any">
		<cfargument name="rc" />
		<cfscript>
			var local = {};
			local.period = 'Month'; // default selection
			rc.errors = [];
			
			// VALIDATION
			if ( not StructKeyExists(rc, 'groupName') or not len(trim(rc.groupName)) ) {
				ArrayAppend(rc.errors,'Subscription (Group) Name is required.');
			};
			if ( not StructKeyExists(rc, 'subscriptionBillingCycleAmount') or not IsNumeric(rc.subscriptionBillingCycleAmount) ) {
				ArrayAppend(rc.errors, 'Please enter a valid Billing Amount. <em>(numbers and decimals only)</em>');
			};
			// Validate Billing Cycle combinations
			// Days: 1-90
			if ( rc.subscriptionBillingCyclePeriod eq 'D' and rc.subscriptionBillingCycleNumber gt 90 ) {
				ArrayAppend(rc.errors, 'The valid subscription duration for <strong>DAYS is 1-90</strong>. You selected ' & rc.subscriptionBillingCycleNumber & '.');
			};
			// Weeks: 1-52
			if ( rc.subscriptionBillingCyclePeriod eq 'W' and rc.subscriptionBillingCycleNumber gt 52 ) {
				ArrayAppend(rc.errors, 'The valid subscription duration for <strong>WEEKS is 1-52</strong>. You selected ' & rc.subscriptionBillingCycleNumber & '.');
			};
			// Months: 1-24
			if ( rc.subscriptionBillingCyclePeriod eq 'M' and rc.subscriptionBillingCycleNumber gt 24 ) {
				ArrayAppend(rc.errors, 'The valid subscription duration for <strong>MONTHS is 1-24</strong>. You selected ' & rc.subscriptionBillingCycleNumber & '.');
			};
			// Years: 1-5
			if ( rc.subscriptionBillingCyclePeriod eq 'Y' and rc.subscriptionBillingCycleNumber gt 5 ) {
				ArrayAppend(rc.errors, 'The valid subscription duration for <strong>YEARS is 1-5</strong>. You selected ' & rc.subscriptionBillingCycleNumber & '.');
			};
			
			// IF ERRORS EXIST
			if ( ArrayLen(rc.errors) ) {
				fw.redirect(action='admin:main.edit',preserve='errors,groupName,InActive,subscriptionBillingCycleAmount,subscriptionBillingCycleNumber,subscriptionBillingCyclePeriod,add,update,userid');
			};
			
			// IF VALIDATION PASSES, THEN PROCEED
			local.rsSites = rc.pluginConfig.getAssignedSites();
			// add/update values for each site the plugin has been assigned to
			for ( local.i=1; local.i lte local.rsSites.recordcount; local.i++ ) {
				// for USERS, you can loadby(userid,siteid | username,siteid);
				// for GROUPS, loadby(userid,siteid,{isPublic} | groupname,siteid,{isPublic})
				local.groupBean = application.serviceFactory.getBean('user');
				if ( StructKeyExists(rc, 'userid') and IsValid('uuid', rc.userid) ) {
					local.groupBean.loadBy(userid=rc.userid,siteid=local.rsSites.siteid[local.i],isPublic=1);
				} else {
					local.groupBean.loadBy(groupname=rc.groupName,siteid=local.rsSites.siteid[local.i],isPublic=1);
				};
				local.groupBean.setValue('Type',1);
				local.groupBean.setValue('subType',rc.pluginConfig.getPackage());
				local.groupBean.setValue('groupName',rc.groupName);
				local.groupBean.setValue('siteid',local.rsSites.siteid[local.i]);
				local.groupBean.setValue('isPublic',1);
				local.groupBean.setValue('InActive',rc.InActive);
				local.groupBean.setValue('subscriptionBillingCycleAmount',rc.subscriptionBillingCycleAmount);
				local.groupBean.setValue('subscriptionBillingCycleNumber',rc.subscriptionBillingCycleNumber);
				local.groupBean.setValue('subscriptionBillingCyclePeriod',rc.subscriptionBillingCyclePeriod);
				// build the description
				local.desc = HTMLEditFormat(rc.groupName) & ': ' & DollarFormat(rc.subscriptionBillingCycleAmount) & ' per ';
				// billing cycle: period
				switch (rc.subscriptionBillingCyclePeriod) {
					case 'D': local.period = 'Day'; break;
					case 'W': local.period = 'Week'; break;
					case 'Y' : local.period = 'Year'; break;
					default : local.period = 'Month';
				};
				if ( rc.subscriptionBillingCycleNumber eq 1 ) {
					// i.e., Subscription Name - $9.99 per Month
					local.desc = local.desc & local.period;
				} else {
					// i.e., Subscription Name - $9.99 per 18 Months
					local.desc = local.desc & rc.subscriptionBillingCycleNumber & ' ' & local.period & 's';
				};
				// auto-populate the description based on info entered
				local.groupBean.setValue('subscriptionDescription',local.desc);
				try {
					local.groupBean.save();
				} catch (any e) {
					// if there's a problem trying to save this, display an error message with _hopefully_ useful info.
					ArrayAppend(rc.errors, 'An error occurred while trying to save this record.<br />Message: ' & e.message & ' Details: ' & e.detail);
					fw.redirect(action='admin:main.edit',preserve='errors,groupName,InActive,subscriptionBillingCycleAmount,subscriptionBillingCycleNumber,subscriptionBillingCyclePeriod,add,update,userid');
				};
			};
			
			fw.redirect(action='admin:main',append='add,update');
		</cfscript>
	</cffunction>

	<!--- *************** db ***************** --->
	
	<cffunction name="getMuraSubscriberGroup" output="false" returntype="any">
		<cfargument name="rc" required="true" />
		<cfset var local = {} />
		<cfquery 	name="local.rs" 
					datasource="#rc.pluginConfig.getConfigBean().getDatasource()#" 
					username="#rc.pluginConfig.getConfigBean().getDBUsername()#" 
					password="#rc.pluginConfig.getConfigBean().getDBPassword()#">
		SELECT UserID, GroupName, SiteID, IsPublic, Type, subType
		FROM tusers 
		WHERE UserID = <cfqueryparam value="#rc.userid#" cfsqltype="cf_sql_char" maxlength="35" />
		</cfquery>
		<cfreturn local.rs />
	</cffunction>

	<cffunction name="getMuraSubscriberGroups">
		<cfargument name="rc" required="true" />
		<cfscript>
			var local = {};
		</cfscript>
		<cfquery name="local.rs" 
			datasource="#rc.pluginConfig.getConfigBean().getDatasource()#" 
			username="#rc.pluginConfig.getConfigBean().getDBUsername()#" 
			password="#rc.pluginConfig.getConfigBean().getDBPassword()#">
			SELECT UserID, GroupName, SiteID, IsPublic, Type, subType
			FROM tusers 
			WHERE subType LIKE <cfqueryparam value="#rc.pluginConfig.getPackage()#%" cfsqltype="cf_sql_varchar" />
				AND Type = 1
			ORDER BY GroupName ASC
		</cfquery>
		<cfreturn local.rs />
	</cffunction>

</cfcomponent>