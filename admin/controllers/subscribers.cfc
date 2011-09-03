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

		Document:	/admin/controllers/subscribers.cfc
		Author:		Steve Withington | www.stephenwithington.com
		Modified:	2011.09.02

--->
<cfcomponent extends="controller" output="false">

	<!--- ************ pages *************** --->
	<cffunction name="default" output="false" returntype="any">
		<cfargument name="rc" />
		<cfscript>
			var local = StructNew();
			local.args = StructNew();

			if ( StructKeyExists(rc, 'profilestatus') and len(trim(rc.profilestatus)) ) {
				local.args.profilestatus = rc.profilestatus;
			};			

			rc.rsSubscribers = getMuraSubscribers(argumentCollection=local.args);
		</cfscript>		
	</cffunction>

	<cffunction name="details" output="false" returntype="any">
		<cfargument name="rc" />
		<cfscript>
			var local = StructNew();

			if ( StructKeyExists(rc, 'userid') and IsValid('uuid', rc.userid) ) {
				// update db with latest info from PayPal
				refreshSubscriberProfile(rc);
				// ping db for display
				rc.rsSubscriber = getMuraSubscribers(UserID=rc.userid);
			};
		</cfscript>
	</cffunction>

	<!--- ******************** PAYPAL ********************* --->
	<cffunction name="manageProfile" output="false" returntype="any">
		<cfargument name="rc" required="true" />
		<cfscript>
			var local = StructNew();
			rc.errors = ArrayNew(1);
			rc.suspended = false;
			rc.reactivated = false;
			rc.cancelled = false;

			// validation
			if ( not StructKeyExists(rc, 'statusAction') 
				or not len(trim(rc.statusAction)) 
				or not ListFind('Cancel,Suspend,Reactivate', rc.statusAction) ) {
				ArrayAppend(rc.errors, 'Invalid statusAction passed to manageProfile(). Valid options are Cancel, Suspend and Reactivate.');
				fw.redirect(action='admin:subscribers',preserve='errors');
			} else {
				// process the request
				manageRecurringPaymentsProfile(rc);
			};
			
			// setup messaging
			switch(rc.statusAction) {
				case 'Suspend' : {
					rc.suspended = true;
					break;
				};
				case 'Reactivate' : {
					rc.reactivated = true;
					break;
				};
				case 'Cancel' : {
					rc.cancelled = true;
					break;
				};
			};
			// forward admin user to default listing with message
			fw.redirect(action='admin:subscribers',preserve='suspended,reactivated,cancelled');
		</cfscript>
		<cfreturn />
	</cffunction>

	<!--- **** getRecurringPaymentsProfileDetails() **** --->
	<cffunction name="getRecurringPaymentsProfileDetails" output="false" returntype="any">
		<cfargument name="rc" required="true" />
		<cfscript>
			var local = StructNew();

			rc.errors = ArrayNew(1);
			rc.success = true;
			local.profile = StructNew();

			// validation
			if ( not StructKeyExists(rc, 'profileid') or not len(trim(rc.profileid)) ) { 
				ArrayAppend(rc.errors, 'ProfileID is required and was not passed in to getRecurringPaymentsProfileDetails()');
				fw.redirect(action='admin:subscribers',preserve='success,errors');
			};

			local.requestData = StructNew();
			local.requestData.METHOD = 'GetRecurringPaymentsProfileDetails';
			local.requestData.PROFILEID = rc.profileid;
			local.responseStruct = rc.payPalService.doNVPResponse(local.requestData);
		</cfscript>
		<cfif rc.payPalService.isAckSuccess(local.responseStruct)>
			<cfscript>
				local.profile.payPalResponse = local.responseStruct;
				local.profile.requestData = local.requestData;
				if ( StructKeyExists(local.responseStruct, 'DESC') ) {
					local.profile.desc = local.responseStruct.DESC;
				};
				if ( StructKeyExists(local.responseStruct, 'PROFILEID') ) {
					local.profile.profileid = local.responseStruct.PROFILEID;
				};
//					if ( StructKeyExists(local.responseStruct, 'LASTPAYMENTDATE') ) {
//						local.profile.lastPaymentDate = local.responseStruct.LASTPAYMENTDATE;
//					};
//					if ( StructKeyExists(local.responseStruct, 'LASTPAYMENTAMT') ) {
//						local.profile.lastPaymentAmt = local.responseStruct.LASTPAYMENTAMT;
//					};
				if ( StructKeyExists(local.responseStruct, 'NEXTBILLINGDATE') ) {
					local.profile.nextBillingDate = local.responseStruct.NEXTBILLINGDATE;
				};
//					if ( StructKeyExists(local.responseStruct, 'OUTSTANDINGBALANCE') ) {
//						local.profile.outstandingBalance = local.responseStruct.OUTSTANDINGBALANCE;
//					};
				if ( StructKeyExists(local.responseStruct, 'PROFILEREFERENCE') ) {
					local.profile.profileReference = local.responseStruct.PROFILEREFERENCE;
				};
				if ( StructKeyExists(local.responseStruct, 'PROFILESTARTDATE') ) {
					local.profile.profileStartDate = local.responseStruct.PROFILESTARTDATE;
				};
//					if ( StructKeyExists(local.responseStruct, 'REGULARAMT') ) {
//						local.profile.regularAmt = local.responseStruct.REGULARAMT;
//					};
//					if ( StructKeyExists(local.responseStruct, 'REGULARBILLINGFREQUENCY') ) {
//						local.profile.regularBillingFrequency = local.responseStruct.REGULARBILLINGFREQUENCY;
//					};
//					if ( StructKeyExists(local.responseStruct, 'REGULARBILLINGPERIOD') ) {
//						local.profile.regularBillingPeriod = local.responseStruct.REGULARBILLINGPERIOD;
//					};
//					if ( StructKeyExists(local.responseStruct, 'REGULARCURRENCYCODE') ) {
//						local.profile.regularBillingPeriod = local.responseStruct.REGULARCURRENCYCODE;
//					};
//					if ( StructKeyExists(local.responseStruct, 'SHIPTOCITY') ) {
//						local.profile.shipToCity = local.responseStruct.SHIPTOCITY;
//					};
//					if ( StructKeyExists(local.responseStruct, 'SHIPTOCOUNTRYNAME') ) {
//						local.profile.shipToCountryName = local.responseStruct.SHIPTOCOUNTRYNAME;
//					};
//					if ( StructKeyExists(local.responseStruct, 'SHIPTOSTATE') ) {
//						local.profile.shipToState = local.responseStruct.SHIPTOSTATE;
//					};
//					if ( StructKeyExists(local.responseStruct, 'SHIPTOSTREET') ) {
//						local.profile.shipToStreet = local.responseStruct.SHIPTOSTREET;
//					};
//					if ( StructKeyExists(local.responseStruct, 'SHIPTOSTREET2') ) {
//						local.profile.shipToStreet2 = local.responseStruct.SHIPTOSTREET2;
//					};
//					if ( StructKeyExists(local.responseStruct, 'SHIPTOZIP') ) {
//						local.profile.shipToZip = local.responseStruct.SHIPTOZIP;
//					};
				if ( StructKeyExists(local.responseStruct, 'STATUS') ) {
					local.profile.status = local.responseStruct.STATUS;
				};
				if ( StructKeyExists(local.responseStruct, 'SUBSCRIBERNAME') ) {
					local.profile.subscriberName = local.responseStruct.SUBSCRIBERNAME;
				};
			</cfscript>
		<cfelse>
			<cfscript>
				rc.success = false;
				rc.responseStruct = local.responseStruct;
				rc.requestData = local.requestData;
				fw.redirect(action='admin:subscribers.default',preserve='success,responseStruct,requestData');
			</cfscript>
		</cfif>
		<cfreturn local.profile />
	</cffunction>

	<!--- **** manageRecurringPaymentsProfile() **** --->
	<cffunction name="manageRecurringPaymentsProfile" output="false" returntype="any">
		<cfargument name="rc" required="true" />
		<cfscript>
			var local = StructNew();

			rc.success = false;
			rc.errors = ArrayNew(1);

			// validation
			if ( not StructKeyExists(rc, 'statusAction') 
				or not len(trim(rc.statusAction)) 
				or not ListFind('Cancel,Suspend,Reactivate', rc.statusAction) ) {
				ArrayAppend(rc.errors, 'Invalid statusAction passed to manageRecurringPaymentsProfile(). Valid options are Cancel, Suspend and Reactivate.');
			};
			if ( not StructKeyExists(rc, 'profileid') ) {
				ArrayAppend(rc.errors, 'rc.profileid is required but was not passed into manageRecurringPaymentsProfile()');
			};
			if ( not StructKeyExists(rc, 'userid') ) {
				ArrayAppend(rc.errors, 'rc.userid is required but was not passed into manageRecurringPaymentsProfile()');
			};
			// verify the profile isn't already cancelled
			if ( ListFindNoCase('Cancelled,CancelledProfile',rc.currentStatus) ) {
				ArrayAppend(rc.errors, 'This profile has already been cancelled.');
			};
			if ( ArrayLen(rc.errors) ) {
				fw.redirect(action='admin:subscribers',preserve='errors');
			};

			// package data to sent to PayPal
			// NOTE: you CANNOT 'Reactivate' a 'Cancelled' profile!
			local.requestData = StructNew();
			local.requestData.METHOD = 'ManageRecurringPaymentsProfileStatus';
			local.requestData.PROFILEID = trim(rc.profileid);
			local.requestData.ACTION = rc.statusAction;

			// send data and get response from PayPal
			local.responseStruct = rc.payPalService.doNVPResponse(local.requestData);

			if ( rc.payPalService.isAckSuccess(local.responseStruct) ) {
				rc.success = true;
			};

			if ( not rc.success ) {
				// fail OR error
				rc.responseStruct = local.responseStruct;
				rc.requestData = local.requestData;
				fw.redirect(action='admin:subscribers',preserve='errors,success,responseStruct,requestData');
			} else {
				// update the subscriber details
				local.profileDetails = getRecurringPaymentsProfileDetails(rc);
				StructAppend(rc,local.profileDetails);
				updateMuraSubscriber(rc);
			};
		</cfscript>
	</cffunction>

	<!--- ************ db ***************** --->	
	<cffunction name="refreshSubscriberProfile" output="false" returntype="any">
		<cfargument name="rc" required="true" />
		<cfscript>
			var local = StructNew();
			local.profile = StructNew();
			if ( StructKeyExists(rc, 'userid') and IsValid('uuid', rc.userid) ) {
				// 1) grab the current profileid
				local.userBean = application.serviceFactory.getBean('user');
				local.userBean.loadBy(userid=rc.userid);
				rc.profileid = local.userBean.getValue('profileID');
				// 2) get an updated profile form PayPal
				local.profile = getRecurringPaymentsProfileDetails(rc);
				StructAppend(rc, local.profile);
				// 3) update the db with current info
				updateMuraSubscriber(rc);
			} else {
				local.profile.error = 'Invalid UserID passed to getUserProfile().';
			};
			return local.profile;
		</cfscript>
	</cffunction>	

	<cffunction name="updateMuraSubscriber" output="false" returntype="any">
		<cfargument name="rc" required="true" />
		<cfscript>
			var local = StructNew();

			rc.errors = ArrayNew(1);

			// validation	
			if ( not StructKeyExists(rc, 'userid') ) { 
				ArrayAppend(rc.errors, 'rc.userid is required for updateMuraSubscriber()'); 
			};
			if ( ArrayLen(rc.errors) ) {
				fw.redirect(action='admin:subscribers.error',preserve='errors');	
			};

			local.userBean = application.serviceFactory.getBean('user');
			local.userBean.loadBy(userid=rc.userid);

			local.userBean.setValue('Type',2);
			local.userBean.setValue('subType',rc.pluginConfig.getPackage());
			local.userBean.setValue('isPublic',1);
			local.userBean.setValue('InActive',0);

			if ( StructKeyExists(rc, 'PROFILEID') ) {
				local.userBean.setValue('profileID',rc.PROFILEID);
			};
			if ( StructKeyExists(rc, 'STATUS') ) {
				local.userBean.setValue('profileStatus',rc.STATUS);
			};
			if ( StructKeyExists(rc, 'DESC') ) {
				local.userBean.setValue('subscriptionPlan',rc.DESC);
			};
			if ( StructKeyExists(rc, 'PROFILESTARTDATE') ) {
				local.userBean.setValue('profileStartDate',rc.lib.convertPayPalTimeStamp(rc.PROFILESTARTDATE));
			};
			if ( StructKeyExists(rc, 'NEXTBILLINGDATE') ) {
				local.userBean.setValue('nextBillingDate',rc.lib.convertPayPalTimeStamp(rc.NEXTBILLINGDATE));
			};
//			if ( StructKeyExists(rc, 'TRANSACTIONID') ) {
//				local.userBean.setValue('transactionID',rc.TRANSACTIONID);
//			};
			if ( StructKeyExists(rc, 'PROFILEREFERENCE') ) {
				local.userBean.setValue('profileReference',rc.PROFILEREFERENCE);
			};
			local.userBean.save();
			
			if ( StructKeyExists(rc, 'STATUS') ) {
				// each time the subscriber is updated (i.e., on Login) their group will be updated ... this way
				// if a user is 'Suspended' they will be removed from the group ... if they're ever reactivated,
				// then they'll be added back into the group!
				if ( ListFindNoCase('ActiveProfile,Active,PendingProfile,Pending', rc.STATUS) ) {
					addUserToGroup(
						userid = URLDecode(ListFirst(rc.PROFILEREFERENCE, '^'))
						, groupid = URLDecode(ListLast(rc.PROFILEREFERENCE, '^'))
					);
				} else {
					deleteUserFromGroup(
						userid = URLDecode(ListFirst(rc.PROFILEREFERENCE, '^'))
						, groupid = URLDecode(ListLast(rc.PROFILEREFERENCE, '^'))					
					);
				};
			};
			return true;
		</cfscript>
	</cffunction>

	<cffunction name="setMuraSubscribers">
		<cfargument name="rc" required="true" />
		<cfscript>
			var local = StructNew();
		</cfscript>
		<cfquery name="local.rs" 
			datasource="#rc.pluginConfig.getConfigBean().getDatasource()#" 
			username="#rc.pluginConfig.getConfigBean().getDBUsername()#" 
			password="#rc.pluginConfig.getConfigBean().getDBPassword()#">
			SELECT tusers.UserID
				, tusers.Fname
				, tusers.Lname
				, tusers.Email
				, tusers.Type
				, tusers.subType
				, tusers.InActive
				, tusers.SiteID
				, tusers.LastUpdate
			FROM tusers 
			WHERE tusers.subType LIKE <cfqueryparam value="#rc.pluginConfig.getPackage()#%" cfsqltype="cf_sql_varchar" />
				AND tusers.Type = 2
			ORDER BY Lname, Fname ASC
		</cfquery>
		<cfif local.rs.recordcount>
			<cfscript>
				QueryAddColumn(local.rs, 'subscriptionPlan', 'VarChar', ArrayNew(1));
				QueryAddColumn(local.rs, 'profileStartDate', 'Date', ArrayNew(1));
				QueryAddColumn(local.rs, 'nextBillingDate', 'Date', ArrayNew(1));
				QueryAddColumn(local.rs, 'profileStatus', 'VarChar', ArrayNew(1));
				QueryAddColumn(local.rs, 'profileStatusLink', 'VarChar', ArrayNew(1));
				QueryAddColumn(local.rs, 'profileID', 'VarChar', ArrayNew(1));
				QueryAddColumn(local.rs, 'GroupID', 'VarChar', ArrayNew(1));
				QueryAddColumn(local.rs, 'emailLink', 'VarChar', ArrayNew(1));
				QueryAddColumn(local.rs, 'detailsLink', 'VarChar', ArrayNew(1));
				QueryAddColumn(local.rs, 'lastNameLink', 'VarChar', ArrayNew(1));
				QueryAddColumn(local.rs, 'transactionID', 'VarChar', ArrayNew(1));
			</cfscript>
			<cfloop query="local.rs">
				<cfscript>
					local.userBean = application.serviceFactory.getBean('user');
					local.userBean.loadBy(userid=local.rs.UserID);
					QuerySetCell(local.rs,'subscriptionPlan',local.userBean.getValue('subscriptionPlan'),currentrow);
					QuerySetCell(local.rs,'profileStartDate',local.userBean.getValue('profileStartDate'),currentrow);
					QuerySetCell(local.rs,'nextBillingDate',local.userBean.getValue('nextBillingDate'),currentrow);
					QuerySetCell(local.rs,'profileStatus',local.userBean.getValue('profileStatus'),currentrow);
					QuerySetCell(local.rs,'profileStatusLink','<a href="?action=admin:subscribers.default&amp;profilestatus=' & local.userBean.getValue('profileStatus') & '">' & local.userBean.getValue('profileStatus') & '<a>',currentrow);
					QuerySetCell(local.rs,'profileID',local.userBean.getValue('profileID'),currentrow);
					QuerySetCell(local.rs,'GroupID',local.userBean.getValue('GroupID'),currentrow);
					QuerysetCell(local.rs,'emailLink','<a href="mailto:' & local.userBean.getValue("Email") & '">' & local.userBean.getValue("Email") & '</a>',currentrow);
					
					QuerySetCell(local.rs,'detailsLink','<a title="Edit/Details" href="?action=admin:subscribers.details&amp;userid=' & local.userBean.getValue("UserID") & '"><img src="../../admin/images/icons/edit_24.png" border="0" /></a>',currentrow);
					QuerySetCell(local.rs,'lastNameLink','<a href="?action=admin:subscribers.details&amp;userid=' & local.userBean.getValue("UserID") & '">' & local.userBean.getValue("Lname") & '</a>',currentrow);
					QuerySetCell(local.rs,'transactionID',local.userBean.getValue('transactionID'),currentrow);
				</cfscript>
			</cfloop>
		</cfif>
		<cfreturn local.rs />
	</cffunction>

	<cffunction name="getMuraSubscribers" access="remote" output="false" returntype="any">
		<cfargument name="page" required="false" />
		<cfargument name="pageSize" required="false" />
		<cfargument name="gridSortColumn" required="false" />
		<cfargument name="gridSortDirection" required="false" />
		<cfargument name="UserID" required="false" />
		<cfargument name="Fname" required="false" />
		<cfargument name="Lname" required="false" />
		<cfargument name="SiteID" required="false" />
		<cfargument name="profileID" required="false" />
		<cfargument name="profileStatus" required="false" />
		<cfargument name="GroupID" required="false" />
		<cfscript>
			var local = StructNew();
			var rc = request.context;
			var origRS = setMuraSubscribers(rc);
		</cfscript>
		<cftry>
			<cfquery name="local.rs" dbtype="query">			
				SELECT *
				FROM origRS
				WHERE 0 = 0
					<cfif StructKeyExists(arguments, 'UserID') and IsValid('uuid', arguments.UserID) >
						AND UserID = <cfqueryparam value="#arguments.UserID#" cfsqltype="cf_sql_varchar" />
					</cfif>
					<cfif StructKeyExists(arguments, 'Fname') and len(trim(arguments.Fname)) >
						AND Fname LIKE <cfqueryparam value="%#arguments.Fname#%" cfsqltype="cf_sql_varchar" />
					</cfif>
					<cfif StructKeyExists(arguments, 'Lname') and len(trim(arguments.Lname)) >
						AND Lname LIKE <cfqueryparam value="%#arguments.Lname#%" cfsqltype="cf_sql_varchar" />
					</cfif>
					<cfif StructKeyExists(arguments, 'SiteID') and len(trim(arguments.SiteID)) >
						AND SiteID = <cfqueryparam value="#arguments.SiteID#" cfsqltype="cf_sql_varchar" />
					</cfif>
					<cfif StructKeyExists(arguments, 'profileID') and len(trim(arguments.profileID)) >
						AND profileID = <cfqueryparam value="#arguments.profileID#" cfsqltype="cf_sql_varchar" />
					</cfif>
					<cfif StructKeyExists(arguments, 'profileStatus') and len(trim(arguments.profileStatus)) >
						AND profileStatus = <cfqueryparam value="#arguments.profileStatus#" cfsqltype="cf_sql_varchar" />
					</cfif>
					<cfif StructKeyExists(arguments, 'GroupID') and IsValid('uuid', arguments.GroupID) >
						AND GroupID = <cfqueryparam value="#arguments.GroupID#" cfsqltype="cf_sql_varchar" />
					</cfif>

				<cfif StructKeyExists(arguments, 'GridSortColumn') 
					and len(trim(arguments.GridSortColumn)) 
					and StructKeyExists(arguments, 'GridSortDirection')
					and len(trim(arguments.GridSortDirection))>
					ORDER BY #arguments.GridSortColumn# #arguments.GridSortDirection#
				<cfelse>
					ORDER BY Lname, Fname ASC
				</cfif>
			</cfquery>
			<cfcatch>
				<cfthrow message="#cfcatch.message#" detail="#cfcatch.detail#" />
			</cfcatch>
		</cftry>
		<cfscript>
			if ( StructKeyExists(arguments, 'page') and StructKeyExists(arguments, 'pageSize') ) {
				return QueryConvertForGrid(local.rs, arguments.page, arguments.pageSize);
			} else {
				return local.rs;
			};
		</cfscript>
	</cffunction>

	<cffunction name="addUserToGroup" output="false" returntype="any">
		<cfargument name="userid" required="true" />
		<cfargument name="groupid" required="true" />
		<cfscript>
			var local = StructNew();
			local.success = true;
			local.userDAO = application.serviceFactory.getBean('userDAO');
			try {
				local.userDAO.createUserInGroup(userid=arguments.userid, groupid=arguments.groupid);
			} catch (any e) {
				local.success = false;
			};
			return local.success;
		</cfscript>
	</cffunction>

	<cffunction name="deleteUserFromGroup" output="false" returntype="any">
		<cfargument name="userid" required="true" />
		<cfargument name="groupid" required="true" />
		<cfscript>
			var local = StructNew();
			local.success = true;
			local.userDAO = application.serviceFactory.getBean('userDAO');
			try {
				local.userDAO.deleteUserFromGroup(userid=arguments.userid, groupid=arguments.groupid);
			} catch (any e) {
				local.success = false;
			};
			return local.success;
		</cfscript>
	</cffunction>
	
</cfcomponent>