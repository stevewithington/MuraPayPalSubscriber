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

		Document:	/public/controllers/main.cfc
		Author:		Steve Withington | www.stephenwithington.com
		Modified:	2011.09.02

--->
<cfcomponent extends="controller" output="false">

	<!--- ********************************* PAGES ******************************************* --->

	<cffunction name="default" output="false" returntype="any">
		<cfargument name="rc" required="true" />
		<cfscript>
			if ( 
				( not getIsAdmin(rc) )
				and (
					not rc.$.currentUser().isLoggedIn() 
					or not StructKeyExists(session, 'muraSubscriber') 
					or StructIsEmpty(session.muraSubscriber)
					or not len(trim(getProfileID()))
					or not getIsActive()
				)
			) {
				setup(rc);
			};
			rc.nav = dspProfileNav(rc);			
			return;
		</cfscript>
	</cffunction>

	<cffunction name="profile" output="false" returntype="any">
		<cfargument name="rc" required="true" />
		<cfscript>
			return;
		</cfscript>
	</cffunction>

	<cffunction name="error" output="false" returntype="any">
		<cfargument name="rc" />
		<cfscript>
			return;
		</cfscript>
	</cffunction>

	<cffunction name="options" output="false" returntype="any">
		<cfargument name="rc" />
		<cfscript>			
			// this is the landing page for anyone who isn't either logged in or have an active or pending account
			// purposely NOT running setup(rc) here to display options ... otherwise we'll end up in an ugly loop!
			
			
			// if a potential user selected a subscription choice and had to create a profile, then after they complete
			// the profile, let's go ahead and forward them on to checkout
			if ( 
				rc.$.currentUser().isLoggedIn() 
				and IsDefined('session.muraSubscriber.subscriptionChoice.groupid')
				and NOT IsDefined('session.muraSubscriber.DOEXPRESSCHECKOUTRESPONSE.PAYMENTINFO_0_TRANSACTIONID') 
			) {
				rc.subscriptionOption = session.muraSubscriber.subscriptionChoice.groupid;
				fw.redirect(action='public:main.setexpresscheckout',preserve='choice');
			};

			// status
			rc.isActive 	= getIsActive();
			rc.isCancelled 	= getIsCancelled();
			rc.isExpired 	= getIsExpired();
			rc.isSuspended 	= getIsSuspended();

			rc.rsMuraSubscriberGroups 	= rsMuraSubscriberGroups(rc);
			rc.listMuraSubscriberGroups = ValueList(rc.rsMuraSubscriberGroups.GroupName);
			rc.rsCurrentUserGroups 		= rsCurrentUserGroups(rc);
			rc.listCurrentUserGroups 	= ValueList(rc.rsCurrentUserGroups.GroupName);
			
			rc.muraSubscribers = getMuraSubscribers();
			rc.nav = dspProfileNav(rc);
			return;
		</cfscript>
	</cffunction>

	<cffunction name="review" output="false" returntype="any">
		<cfargument name="rc" />
		<cfreturn />
	</cffunction>

	<cffunction name="receipt" output="false" returntype="any">
		<cfargument name="rc" />
			<!--- re-login user so he/she can view restricted content --->
			<!---<cfset rc.$.getBean('loginManager').loginByUserID(rc.$.currentUser().getAllValues()) />--->
			<!---<cfif IsDefined('session.muraSubscriber.DOEXPRESSCHECKOUTRESPONSE.PAYMENTINFO_0_TRANSACTIONID')>--->
		<cfreturn />
	</cffunction>

	<cffunction name="continue" output="false" returntype="any">
		<cfargument name="rc" required="true" />
		<cfif rc.$.currentUser().isLoggedIn()>
			<cfset rc.$.getBean('loginManager').loginByUserID(rc.$.currentUser().getAllValues()) />	
		</cfif>
		<cfreturn />
	</cffunction>

	<!--- *********************************** PAYPAL ******************************************* --->

	<cffunction name="setSubscriptionOption" output="false" returntype="void">
		<cfargument name="subscriptionOption" required="false" default="" />
		<cflock type="exclusive" scope="session" timeout="5">
			<cfset session.subscriptionOption = arguments.subscriptionOption />
		</cflock>
	</cffunction>

	<cffunction name="getSubscriptionOption" output="false" returntype="any">
		<cfscript>
			var local = StructNew();
			local.ret = '';
		</cfscript>
		<cflock type="readonly"scope="session" timeout="5">
			<cfset local.ret = session.subscriptionOption />
		</cflock>
		<cfreturn local.ret />
	</cffunction>

	<!--- setExpressCheckout() --->
	<cffunction name="setExpressCheckout" output="false" returntype="any">
		<cfargument name="rc" />
		<cfscript>
			var local = StructNew();
			rc.errors = ArrayNew(1);
			
			if ( StructKeyExists(rc, 'subscriptionOption') ) {
				setSubscriptionOption(rc.subscriptionOption);
			};
			if ( not StructKeyExists(rc, 'subscriptionOption') and StructKeyExists(session, 'subscriptionOption') ) {
				rc.subscriptionOption = getSubscriptionOption();
			};
			if ( not StructKeyExists(rc, 'subscriptionOption') ) {
				ArrayAppend(rc.errors,'Please select a valid subscription option.');
				fw.redirect(action='public:main.options',preserve='errors');		
			};

			local.rs = getSubscriptionOptionDetails(rc.subscriptionOption,rc.pluginConfig);
			
			if ( local.rs.recordcount eq 1 ) {
				setSubscriptionOption(rc.subscriptionOption);
			} else {
				ArrayAppend(rc.errors, "We're sorry, the subscription you selected doesn't appear to be valid. Please select another option.");
			};

			if ( IsDefined('session.muraSubscriber.profile.profileReference') 
				and ListLast(session.muraSubscriber.profile.profileReference,'^') eq rc.subscriptionOption
				and ( getIsActive() or getIsSuspended() ) ) {
				// existing subscriber who selected existing plan
				if ( getIsActive() ) {
					ArrayAppend(rc.errors, "Great news! You're already a subscriber of the option you selected. There's no need to do anything else at this time.");
				} else {
					// suspended
					ArrayAppend(rc.errors, "Actually, you're already a subscriber of the option you selected &hellip; please contact Customer Service to reactivate your account.");
				};
			};
			//if any errors exist, display them
			if ( ArrayLen(rc.errors) ) {
				fw.redirect(action='public:main.options',preserve='errors');
			};
		</cfscript>
		<cflock type="exclusive" scope="session" timeout="25">
			<cfscript>
				// Subscription Option
				StructDelete(session.muraSubscriber, 'subscriptionChoice');
				local.groupBean = application.serviceFactory.getBean('user');
				local.groupBean.loadBy(userid=local.rs.UserID);
				session.muraSubscriber.subscriptionChoice = StructNew();
				session.muraSubscriber.subscriptionChoice.siteid = rc.$.siteConfig('siteid');
				session.muraSubscriber.subscriptionChoice.userid = rc.$.currentUser('userid');
				session.muraSubscriber.subscriptionChoice.fullName = rc.$.currentUser().getFullName();
				session.muraSubscriber.subscriptionChoice.groupid = local.groupBean.getValue('userid');
				session.muraSubscriber.subscriptionChoice.groupName = local.groupBean.getValue('groupName');
				session.muraSubscriber.subscriptionChoice.subscriptionBillingCycleAmount = local.groupBean.getValue('subscriptionBillingCycleAmount');
				session.muraSubscriber.subscriptionChoice.subscriptionBillingCycleNumber = local.groupBean.getValue('subscriptionBillingCycleNumber');
				session.muraSubscriber.subscriptionChoice.subscriptionBillingCyclePeriod = local.groupBean.getValue('subscriptionBillingCyclePeriod');
				session.muraSubscriber.subscriptionChoice.subscriptionDescription = local.groupBean.getValue('subscriptionDescription');
			</cfscript>
		</cflock>
		<cfscript>
			if ( IsDefined('session.muraSubscriber.profile.profileReference') 
				and ListLast(session.muraSubscriber.profile.profileReference,'^') neq rc.subscriptionOption
				and not getIsCancelled() 
			) {
				// existing subscriber who selected a NEW plan, so we MUST cancel their existing plan
				//fw.redirect(action='public:main.cancel',preserve='subscriptionOption');
				rc.forwardTo = 'public:main.setexpresscheckout';
				fw.redirect(action='public:main.cancelRecurringPaymentsProfile',preserve='forwardTo');
			};

			if ( not len(trim(rc.$.currentUser('userid'))) ) {
				// New User, needs to create a profile before proceeding so we have a UserID to associate with the subscription
				local.redirectTo = rc.lib.getValue('baseURL') & rc.lib.getValue('currentURI') & rc.$.siteConfig('editProfileURL');
				rc.lib.redirect(local.redirectTo);

			};
		</cfscript>
		<!--- remove credentials to force app to get new credentials --->
		<cflock type="exclusive" scope="session" timeout="5">
			<cfset StructDelete(session.muraSubscriber, 'hasCredentials') />
		</cflock>
		<cfset fw.redirect(action='public:main.setexpresscheckoutresponse') />
	</cffunction>

	<!--- setExpressCheckoutResponse() --->
	<cffunction name="setExpressCheckoutResponse" output="false" returntype="any">
		<cfargument name="rc" required="true" />
		<cfscript>
			var local = StructNew();

			// https://cms.paypal.com/us/cgi-bin/?&cmd=_render-content&content_ID=developer/e_howto_api_nvp_r_SetExpressCheckout
			local.requestData = StructNew();
			local.requestData.METHOD 			= 'SetExpressCheckout';
			local.requestData.ADDROVERRIDE 		= 0; // 1 indicates indicates that the PayPal pages should display the shipping address set by you in this SetExpressCheckout request, not the shipping address on file with PayPal for this customer. Displaying the PayPal street address on file does not allow the customer to edit that address. Character length and limitations: One single-byte numeric character. Allowable values: 0, 1 
			local.requestData.ALLOWNOTE			= 0; // 1 indicates that the customer may enter a note to the merchant on the PayPal page during checkout.
			local.requestData.LOCALECODE		= 'US';
			local.requestData.LANDINGPAGE		= 'Billing'; // options: Billing (non-PayPal account), Login (PayPal account login)
			//local.requestData.BRANDNAME			= ''; // label that overrides the businessname in the PayPal account on the hosted checkout pages.
			//local.requestData.CUSTOMERSERVICENUMBER	 = '800.555.1212'; // merchant customer service phone number displayed on the PayPal review page.

			// recurring billing info
			local.requestData.L_PAYMENTREQUEST_0_NAME0			= session.muraSubscriber.subscriptionChoice.groupName; //itemName;
			local.requestData.L_PAYMENTREQUEST_0_DESC0			= session.muraSubscriber.subscriptionChoice.subscriptionDescription; //itemDesc;
			local.requestData.L_PAYMENTREQUEST_0_AMT0 			= session.muraSubscriber.subscriptionChoice.subscriptionBillingCycleAmount; //itemAmt;
			local.requestData.L_PAYMENTREQUEST_0_NUMBER0 		= session.muraSubscriber.subscriptionChoice.groupID; // subscription uuid
			local.requestData.L_PAYMENTREQUEST_0_QTY0			= 1;
			local.requestData.L_PAYMENTREQUEST_0_TAXAMT0		= '0.00';
			local.requestData.L_BILLINGTYPE0 					= 'RecurringPayments';
			local.requestData.L_BILLINGAGREEMENTDESCRIPTION0 	= session.muraSubscriber.subscriptionChoice.subscriptionDescription; //itemDesc; //Description of goods or services associated with the billing agreement, which is required for each recurring payment billing agreement.  PayPal recommends that the description contain a brief summary of the billing agreement terms and conditions. For example, customer will be billed at '9.99 per month for 2 years.' 127-characters

			local.requestData.PAYMENTREQUEST_0_CURRENCYCODE 	= 'USD';
			local.requestData.PAYMENTREQUEST_0_ITEMAMT 			= (local.requestData.L_PAYMENTREQUEST_0_QTY0 * local.requestData.L_PAYMENTREQUEST_0_AMT0); // Sum of the cost of all items in this order
			//local.requestData.PAYMENTREQUEST_0_SHIPPINGAMT 		= '0.00';
			//local.requestData.PAYMENTREQUEST_0_INSURANCEAMT		= '0.00';
			//local.requestData.PAYMENTREQUEST_0_SHIPDISCAMT 		= '0.00';
			//local.requestData.PAYMENTREQUEST_0_INSURANCEOPTIONOFFERED = false;
			//local.requestData.PAYMENTREQUEST_0_HANDLINGAMT 		= '0.00';
			//local.requestData.PAYMENTREQUEST_0_TAXAMT 			= '0.00';
			local.requestData.PAYMENTREQUEST_0_AMT 				= local.requestData.PAYMENTREQUEST_0_ITEMAMT; // Total cost of the transaction to the customer (including shipping and tax)

			local.requestData.PAYMENTREQUEST_0_PAYMENTACTION 	= 'Sale'; // valid options: Authorization, Sale or Order

			// The cancelURL is the location buyers are sent to when they hit the cancel button during authorization of payment during the PayPal flow
			local.requestData.CancelURL = rc.$.payPalService.getValue('baseURL') 
				& rc.$.payPalService.getValue('currentURI') 
				& '?action=public:main.default' 
				& '&paymentaction=' 
				& local.requestData.PAYMENTREQUEST_0_PAYMENTACTION;

			// The returnURL is the location where buyers return when a payment has been succesfully authorized. 
			local.requestData.ReturnURL = rc.$.payPalService.getValue('baseURL') 
				& rc.$.payPalService.getValue('currentURI') 
				& '?action=public:main.getexpresscheckoutdetails' 
				& '&amt=' & local.requestData.PAYMENTREQUEST_0_AMT 
				& '&paymentaction=' & local.requestData.PAYMENTREQUEST_0_PAYMENTACTION;

			local.responseStruct = rc.$.payPalService.doNVPResponse(local.requestData);
		</cfscript>
		<cflock type="exclusive" scope="session" timeout="5">
			<cfscript>
				session.muraSubscriber.setExpressCheckoutResponse = local.responseStruct; // TOKEN = session.muraSubscriber.setExpressCheckoutResponse.TOKEN
				session.muraSubscriber.setExpressCheckoutRequestData = local.requestData;
			</cfscript>
		</cflock>
		<cfscript>
			if ( rc.$.payPalService.isAckSuccess(local.responseStruct) ) {
				// success! we need to post this information back to PayPal so they can authenticate it
				rc.success = true;
				local.redirectURL = rc.$.payPalService.getValue('paypalURL') & local.responseStruct.TOKEN;
				rc.lib.redirect(local.redirectURL);
			} else {
				// fail OR error
				rc.success = false;
				rc.responseStruct = local.responseStruct;
				rc.requestData = local.requestData;
				fw.redirect(action='public:main.error',preserve='success,responseStruct,requestData');
			};
		</cfscript>
	</cffunction>

	<!--- getExpressCheckoutDetails() --->
	<cffunction name="getExpressCheckoutDetails" output="false" returntype="any">
		<cfargument name="rc" required="true" />
		<cfscript>
			var local = StructNew();
			rc.errors = ArrayNew(1);
			if ( not IsDefined('session.muraSubscriber.setExpressCheckoutResponse.TOKEN') ) {
				ArrayAppend(rc.errors, 'Please selected a subscription option.');
				fw.redirect(action='public:main.options',preserve='errors');
			};
			local.requestData = StructNew();
			local.requestData.METHOD = 'GetExpressCheckoutDetails';
			local.requestData.TOKEN	= session.muraSubscriber.setExpressCheckoutResponse.TOKEN;
			local.responseStruct = rc.$.payPalService.doNVPResponse(local.requestData);
		</cfscript>
		
		<cflock type="exclusive" scope="session" timeout="5">
			<cfscript>
				session.muraSubscriber.getExpressCheckoutResponse = local.responseStruct;
				session.muraSubscriber.getExpressCheckoutRequestData = local.requestData;
			</cfscript>
		</cflock>
		
		<cfscript>
			//dump(session.muraSubscriber,1);
			if ( rc.$.payPalService.isAckSuccess(local.responseStruct) ) {
				// success!
				rc.success = true;
				fw.redirect(action='public:main.review',preserve='success,token');
			} else {
				// fail OR error
				rc.success = false;
				rc.responseStruct = local.responseStruct;
				rc.requestData = local.requestData;
				fw.redirect(action='public:main.error',preserve='success,responseStruct,requestData');
			};
		</cfscript>
	</cffunction>

	<!--- doExpressCheckoutPayment() --->
	<cffunction name="doExpressCheckoutPayment" output="false" returntype="any">
		<cfargument name="rc" required="true" />
		<cfscript>
			var local = StructNew();
			rc.errors = ArrayNew(1);
			
			if ( not IsDefined('session.muraSubscriber.getExpressCheckoutResponse') ) {
				ArrayAppend(rc.errors, 'Somehow you ended up at doExpressCheckoutPayment() but do not have a valid session.');
				fw.redirect(action='public:main.error',preserve='errors');
			};
			
			local.requestData = StructNew();
			local.requestData.METHOD 	= 'DoExpressCheckoutPayment';
			local.requestData.TOKEN	= session.muraSubscriber.getExpressCheckoutResponse.TOKEN;
			local.requestData.PAYERID = session.muraSubscriber.getExpressCheckoutResponse.PAYERID;
			local.requestData.PAYMENTREQUEST_0_AMT = session.muraSubscriber.getExpressCheckoutResponse.PAYMENTREQUEST_0_AMT;
			local.requestData.PAYMENTREQUEST_0_CURRENCYCODE = 'USD';
			local.requestData.PAYMENTREQUEST_0_PAYMENTACTION = session.muraSubscriber.setExpressCheckoutRequestData.PAYMENTREQUEST_0_PAYMENTACTION;
				//local.requestData.PAYMENTREQUEST_0_NOTIFYURL = rc.$.payPalService.getValue('baseURL') & rc.$.payPalService.getValue('currentURI') & '?action=public:main.ipn';

			local.responseStruct = rc.$.payPalService.doNVPResponse(local.requestData);
		</cfscript>
		<cflock type="exclusive" scope="session" timeout="5">
			<cfscript>
				session.muraSubscriber.doExpressCheckoutResponse = local.responseStruct;
				session.muraSubscriber.doExpressCheckoutRequestData = local.requestData;
			</cfscript>
		</cflock>
		<cfscript>
			if ( rc.$.payPalService.isAckSuccess(local.responseStruct) ) {
				// success!
				rc.success = true;
				// create new profile with PayPal
				fw.redirect(action='public:main.createrecurringpaymentsprofile',preserve='success');
			} else {
				// fail OR error
				rc.success = false;
				rc.responseStruct = local.responseStruct;
				rc.requestData = local.requestData;
				fw.redirect(action='public:main.error',preserve='success,responseStruct,requestData');
			};
		</cfscript>
	</cffunction>

	<!--- createRecurringPaymentsProfile() --->
	<cffunction name="createRecurringPaymentsProfile" output="false" returntype="any">
		<cfargument name="rc" required="true" />
		<cfscript>
			var local = StructNew();
			rc.success = false;
			rc.errors = ArrayNew(1);
			if ( not IsDefined('session.muraSubscriber.doExpressCheckoutResponse') ) {
				ArrayAppend(rc.errors, 'Interesting ... somehow you ended up at createRecurringPaymentsProfile without a valid doExpressCheckoutResponse');
				fw.redirect(action='public:main.error',preserve='errors');
			};

			// https://cms.paypal.com/us/cgi-bin/?&cmd=_render-content&content_ID=developer/e_howto_api_nvp_r_CreateRecurringPayments
			local.requestData = StructNew();
			local.requestData.METHOD = 'CreateRecurringPaymentsProfile';
			local.requestData.TOKEN = session.muraSubscriber.getExpressCheckoutResponse.TOKEN;
			local.requestData.PROFILESTARTDATE = rc.$.payPalService.makePayPalTimestamp(now()); // date when billing for this profile begins
			local.requestData.SUBSCRIBERNAME = rc.$.currentUser().getFullName();
			//	PROFILEREFERENCE = userid,groupid
			local.requestData.PROFILEREFERENCE =  rc.$.currentUser('userid') & '^' & session.muraSubscriber.subscriptionChoice.groupid; // merchant's own unique reference or invoice number (127 alphanumeric chars) - i'm using 'userid^groupid' to identify which group the user is subscribing to
			local.requestData.DESC = session.muraSubscriber.subscriptionChoice.subscriptionDescription; // REQUIRED! MUST match corresponding billing agreement description from SetExpressCheckout
			local.requestData.MAXFAILEDPAYMENTS = 1; // number of failed payments allowed before the profile is automatically suspended.
			local.requestData.AUTOBILLAMT = 'AddToNextBilling'; // valid options: AddToNextBilling OR NoAutoBill
			local.requestData.AMT = session.muraSubscriber.subscriptionChoice.subscriptionBillingCycleAmount; // Amount to bill for each billing cycle.
			// oddly, PayPal now wants the full word instead of an initial
			switch (session.muraSubscriber.subscriptionChoice.subscriptionBillingCyclePeriod) {
					case 'D' : local.period = 'Day'; break;
					case 'W' : local.period = 'Week'; break;
					case 'S' : local.period = 'SemiMonth'; break;
					case 'Y' : local.period = 'Year'; break;
					default  : local.period = 'Month';
				};
			
			local.requestData.BILLINGPERIOD = local.period; // Day, Week, SemiMonth (billing is done on 1st and 15th), Month, Year
			local.requestData.BILLINGFREQUENCY = session.muraSubscriber.subscriptionChoice.subscriptionBillingCycleNumber; // Number of billing periods that make up one cycle. NOTE: combination of BILLINGPERIOD + BILLINGFREQUENCY must be less than or equal to one year.  Also, if BILLINGPERIOD is 'SemiMonth', then BILLINGFREQUENCY must be 1.
			local.requestData.TOTALBILLINGCYCLES = 0; // Leave at Zero (0) to have payments continue until the profile is either canceled or suspended.
			local.requestData.CURRENCYCODE = 'USD';
			local.requestData.SHIPPINGAMT = '0.00';
			local.requestData.TAXAMT = '0.00';
			// OPTIONAL TRIAL PERIOD FIELDS
			//local.requestData.TRIALBILLINGPERIOD = 'Day'; // Day, Week, SemiMonth, Month, Year
			//local.requestData.TRIALBILLINGFREQUENCY = 14;
			//local.requestData.TRIALAMT = '0.00';
			//local.requestData.TRIALTOTALBILLINGCYCLES = 1;
			// ACTIVATION DETAILS FIELDS
			//local.requestData.INITAMT = '0.00';
			local.requestData.FAILEDINITAMTACTION = 'CancelOnFailure';	// FAILEDINITAMTACTION options: ContinueOnFailure (add the failed payment amount ot the outstanding balance due), CancelOnFailure (create payment profile, but place it into a 'pending status' until the inital payment is completed.)
			// SHIP TO ADDRESS FIELDS
			// SHIPTONAME, SHIPTOSTREET, SHIPTOSTREET2, SHIPTOCITY, SHIPTOSTATE, SHIPTOZIP, SHIPTOCOUNTRY, SHIPTOPHONENUM

			local.responseStruct = rc.$.payPalService.doNVPResponse(local.requestData);
		</cfscript>
		<cflock type="exclusive" scope="session" timeout="5000">
			<cfscript>
				session.muraSubscriber.createRecurringPaymentsResponse = local.responseStruct;
				session.muraSubscriber.createRecurringPaymentsRequestData = local.requestData;
			</cfscript>
		</cflock>
		<cfscript>
			if ( rc.$.payPalService.isAckSuccess(local.responseStruct) ) {
				// success!
				rc.success = true;
				rc.profileid = local.responseStruct.profileid;
				// get full profile details from PayPal
				try {
					rc.success = getRecurringPaymentsProfileDetails(rc);
				} catch (any e) {
					rc.success = false;
					ArrayAppend(rc.errors, e.message & '<br />' & e.detail);
				};
				// now update the database with the new info!
				if ( rc.success ) {
					try {
						rc.showReceipt = true;
						updateCurrentMuraSubscriber(rc);
					} catch (any e) {
						rc.success = false;
						ArrayAppend(rc.errors, e.message & '<br />' & e.detail);
					};
				};
			};
			
			if ( rc.success ) {
				fw.redirect(action='public:main.receipt',preserve='success');
			} else {
				rc.responseStruct = local.responseStruct;
				rc.requestData = local.requestData;
				fw.redirect(action='public:main.error',preserve='errors,success,responseStruct,requestData');
			};
		</cfscript>
	</cffunction>

	<!--- **** getRecurringPaymentsProfileDetails() **** --->
	<cffunction name="getRecurringPaymentsProfileDetails" output="false" returntype="any">
		<cfargument name="rc" required="true" />
		<cfscript>
			var local = StructNew();
			rc.errors = ArrayNew(1);
			local.isSuccess = true;

			// validation
			if ( not StructKeyExists(session, 'muraSubscriber') ) {
				setup(rc);
			};
			if ( not StructKeyExists(rc, 'profileid') and len(trim(rc.$.currentUser('profileID'))) ) {
				rc.profileid = rc.$.currentUser('profileID');			
			};
			if ( not len(trim(rc.profileid)) ) { 
				ArrayAppend(rc.errors, 'ProfileID is required and was not passed in to getRecurringPaymentsProfileDetails()');
				fw.redirect(action='public:main.error',preserve='success,errors');
			};

			local.requestData = StructNew();
			local.requestData.METHOD = 'GetRecurringPaymentsProfileDetails';
			local.requestData.PROFILEID = rc.profileid;
			local.responseStruct = rc.$.payPalService.doNVPResponse(local.requestData);
		</cfscript>
		<cfif rc.$.payPalService.isAckSuccess(local.responseStruct)>
			<cflock type="exclusive" scope="session" timeout="5000">
				<cfscript>
					session.muraSubscriber.profile = StructNew();
					session.muraSubscriber.profile.payPalResponse = local.responseStruct;
					session.muraSubscriber.profile.requestData = local.requestData;
					if ( IsDefined('session.muraSubscriber.DOEXPRESSCHECKOUTRESPONSE.PAYMENTINFO_0_TRANSACTIONID')
						and len(trim(session.muraSubscriber.DOEXPRESSCHECKOUTRESPONSE.PAYMENTINFO_0_TRANSACTIONID)) ) {
						session.muraSubscriber.profile.transactionID = session.muraSubscriber.DOEXPRESSCHECKOUTRESPONSE.PAYMENTINFO_0_TRANSACTIONID;
					};
					if ( StructKeyExists(local.responseStruct, 'DESC') ) {
						session.muraSubscriber.profile.desc = local.responseStruct.DESC;
					};
					if ( StructKeyExists(local.responseStruct, 'PROFILEID') ) {
						session.muraSubscriber.profile.profileid = local.responseStruct.PROFILEID;
					};
//					if ( StructKeyExists(local.responseStruct, 'LASTPAYMENTDATE') ) {
//						session.muraSubscriber.profile.lastPaymentDate = local.responseStruct.LASTPAYMENTDATE;
//					};
//					if ( StructKeyExists(local.responseStruct, 'LASTPAYMENTAMT') ) {
//						session.muraSubscriber.profile.lastPaymentAmt = local.responseStruct.LASTPAYMENTAMT;
//					};
					if ( StructKeyExists(local.responseStruct, 'NEXTBILLINGDATE') ) {
						session.muraSubscriber.profile.nextBillingDate = local.responseStruct.NEXTBILLINGDATE;
					};
//					if ( StructKeyExists(local.responseStruct, 'OUTSTANDINGBALANCE') ) {
//					
//					};
					if ( StructKeyExists(local.responseStruct, 'PROFILEREFERENCE') ) {
						session.muraSubscriber.profile.profileReference = local.responseStruct.PROFILEREFERENCE;
					};
					if ( StructKeyExists(local.responseStruct, 'PROFILESTARTDATE') ) {
						session.muraSubscriber.profile.profileStartDate = local.responseStruct.PROFILESTARTDATE;
					};
//					if ( StructKeyExists(local.responseStruct, 'REGULARAMT') ) {
//						session.muraSubscriber.profile.regularAmt = local.responseStruct.REGULARAMT;
//					};
//					if ( StructKeyExists(local.responseStruct, 'REGULARBILLINGFREQUENCY') ) {
//						session.muraSubscriber.profile.regularBillingFrequency = local.responseStruct.REGULARBILLINGFREQUENCY;
//					};
//					if ( StructKeyExists(local.responseStruct, 'REGULARBILLINGPERIOD') ) {
//						session.muraSubscriber.profile.regularBillingPeriod = local.responseStruct.REGULARBILLINGPERIOD;
//					};
//					if ( StructKeyExists(local.responseStruct, 'REGULARCURRENCYCODE') ) {
//						session.muraSubscriber.profile.regularBillingPeriod = local.responseStruct.REGULARCURRENCYCODE;
//					};
//					if ( StructKeyExists(local.responseStruct, 'SHIPTOCITY') ) {
//						session.muraSubscriber.profile.shipToCity = local.responseStruct.SHIPTOCITY;
//					};
//					if ( StructKeyExists(local.responseStruct, 'SHIPTOCOUNTRYNAME') ) {
//						session.muraSubscriber.profile.shipToCountryName = local.responseStruct.SHIPTOCOUNTRYNAME;
//					};
//					if ( StructKeyExists(local.responseStruct, 'SHIPTOSTATE') ) {
//						session.muraSubscriber.profile.shipToState = local.responseStruct.SHIPTOSTATE;
//					};
//					if ( StructKeyExists(local.responseStruct, 'SHIPTOSTREET') ) {
//						session.muraSubscriber.profile.shipToStreet = local.responseStruct.SHIPTOSTREET;
//					};
//					if ( StructKeyExists(local.responseStruct, 'SHIPTOSTREET2') ) {
//						session.muraSubscriber.profile.shipToStreet2 = local.responseStruct.SHIPTOSTREET2;
//					};
//					if ( StructKeyExists(local.responseStruct, 'SHIPTOZIP') ) {
//						session.muraSubscriber.profile.shipToZip = local.responseStruct.SHIPTOZIP;
//					};
					if ( StructKeyExists(local.responseStruct, 'STATUS') ) {
						session.muraSubscriber.profile.status = local.responseStruct.STATUS;
					};
					if ( StructKeyExists(local.responseStruct, 'SUBSCRIBERNAME') ) {
						session.muraSubscriber.profile.subscriberName = local.responseStruct.SUBSCRIBERNAME;
					};
				</cfscript>
			</cflock>
		<cfelse>
			<cfset local.isSuccess = false />
		</cfif>
		<cfreturn local.isSuccess />
	</cffunction>

	<!--- **** cancelRecurringPaymentsProfile() **** --->
	<cffunction name="cancelRecurringPaymentsProfile" output="false" returntype="any">
		<cfargument name="rc" required="true" />
		<cfargument name="statusAction" required="false" default="Cancel" hint="Valid options: Cancel, Suspend, Reactivate" />
		<cfscript>
			var local = StructNew();
			rc.success = false;
			rc.errors = ArrayNew(1);

			// validate PayPal ACTIONs
			if ( not StructKeyExists(arguments, 'statusAction') 
				or not len(trim(arguments.statusAction)) 
				or not ListFind('Cancel,Suspend,Reactivate', arguments.statusAction) ) {
				arguments.statusAction = 'Cancel';
			};

			if ( not StructKeyExists(rc, 'profileid') and len(trim(getProfileID())) ) {
				rc.profileid = getProfileID();
			};

			// verify the profile isn't already cancelled
			if ( rc.$.currentUser().isLoggedIn() and getIsCancelled() ) {
				ArrayAppend(rc.errors, 'This profile has already been cancelled.');
			};

			if ( not StructKeyExists(rc, 'profileid') ) {
				ArrayAppend(rc.errors, 'ProfileID is required, but was not passed into cancelRecurringPaymentsProfile.');
			};

			if ( ArrayLen(rc.errors) ) {
				fw.redirect(action='public:main.options',preserve='errors');
			};
			// package data to sent to PayPal
			// valid PayPal ACTION options: 'Cancel,Suspend,Reactivate'
			// NOTE: you CANNOT 'Reactivate' a 'Cancelled' profile!
			local.requestData = StructNew();
			local.requestData.METHOD = 'ManageRecurringPaymentsProfileStatus';
			local.requestData.PROFILEID = trim(rc.profileid);
			local.requestData.ACTION = arguments.statusAction;

			// send data and get response from PayPal
			local.responseStruct = rc.$.payPalService.doNVPResponse(local.requestData);

			if ( rc.$.payPalService.isAckSuccess(local.responseStruct) ) {
				rc.success = true;
			};

			if ( not rc.success ) {
				// fail OR error
				rc.responseStruct = local.responseStruct;
				rc.requestData = local.requestData;
				fw.redirect(action='public:main.error',preserve='errors,success,responseStruct,requestData');
			} else if ( rc.$.currentUser().isLoggedIn() ) {
				// if logged in, we need to update the CURRENTly logged in user
				getRecurringPaymentsProfileDetails(rc);
				updateCurrentMuraSubscriber(rc);
				
				// this kicks in if a subscriber is trying to change their subscription plan
				if ( StructKeyExists(rc, 'forwardTo') ) {
					fw.redirect(action=rc.forwardTo);
				} else {
					fw.redirect(action='public:main');
				};
			
			} else {
				return true;
			};
		</cfscript>
	</cffunction>

	<!--- ************************************ DB/MURA *************************************** --->

	<cffunction name="updateCurrentMuraSubscriber" output="false" returntype="any">
		<cfargument name="rc" required="true" />
		<cfscript>
			var local = StructNew();
			rc.errors = ArrayNew(1);

			// validation
			if ( not StructKeyExists(session, 'muraSubscriber') ) {
				setup(rc);
			};		
			if ( not StructKeyExists(session.muraSubscriber, 'profile') ) { 
				ArrayAppend(rc.errors, 'session.muraSubscriber.profile is required to updateCurrentMuraSubscriber()'); 
			};
			if ( ArrayLen(rc.errors) ) {
				fw.redirect(action='public:main.error',preserve='errors');	
			};

			// update the current user with the latest info stored in the session
			rc.$.currentUser('Type',2);
			rc.$.currentUser('subType',rc.pluginConfig.getPackage());
			rc.$.currentUser('siteid',rc.$.siteConfig('siteid'));
			rc.$.currentUser('isPublic',1);
			rc.$.currentUser('InActive',0);
			if ( StructKeyExists(session.muraSubscriber.profile, 'PROFILEID') ) {
				rc.$.currentUser('profileID',session.muraSubscriber.profile.PROFILEID);
			};
			if ( StructKeyExists(session.muraSubscriber.profile, 'STATUS') ) {
				rc.$.currentUser('profileStatus',session.muraSubscriber.profile.STATUS);
			};
			if ( StructKeyExists(session.muraSubscriber.profile, 'DESC') ) {
				rc.$.currentUser('subscriptionPlan',session.muraSubscriber.profile.DESC);
			};
			if ( StructKeyExists(session.muraSubscriber.profile, 'PROFILESTARTDATE') ) {
				rc.$.currentUser('profileStartDate',rc.lib.convertPayPalTimeStamp(session.muraSubscriber.profile.PROFILESTARTDATE));
			};
			if ( StructKeyExists(session.muraSubscriber.profile, 'NEXTBILLINGDATE') ) {
				rc.$.currentUser('nextBillingDate',rc.lib.convertPayPalTimeStamp(session.muraSubscriber.profile.NEXTBILLINGDATE));
			};
			if ( StructKeyExists(session.muraSubscriber.profile, 'TRANSACTIONID') ) {
				rc.$.currentUser('transactionID',session.muraSubscriber.profile.TRANSACTIONID);
			};
			if ( StructKeyExists(session.muraSubscriber.profile, 'PROFILEREFERENCE') ) {
				rc.$.currentUser('profileReference',session.muraSubscriber.profile.PROFILEREFERENCE);
			};
			rc.$.currentUser().save();
			
			if ( StructKeyExists(session.muraSubscriber.profile, 'STATUS') ) {
				// each time the subscriber is updated (i.e., on Login) their group will be updated ... this way
				// if a user is 'Suspended' they will be removed from the group ... if they're ever reactivated,
				// then they'll be added back into the group!
				if ( ListFindNoCase('ActiveProfile,Active,PendingProfile,Pending', session.muraSubscriber.profile.STATUS) ) {
					addUserToGroup(
						userid = URLDecode(ListFirst(session.muraSubscriber.profile.PROFILEREFERENCE, '^'))
						, groupid = URLDecode(ListLast(session.muraSubscriber.profile.PROFILEREFERENCE, '^'))
					);
					// populate session.mura.memberships with the new group and re-login user
					addMuraMembership(rc);
				} else {
					deleteUserFromGroup(
						userid = URLDecode(ListFirst(session.muraSubscriber.profile.PROFILEREFERENCE, '^'))
						, groupid = URLDecode(ListLast(session.muraSubscriber.profile.PROFILEREFERENCE, '^'))					
					);
					// remove the old group from session.mura.memberships and re-login user
					deleteMuraMembership(rc);
				};
			};
			return true;
		</cfscript>
	</cffunction>

	<cffunction name="addMuraMembership" output="false" returntype="any">
		<cfargument name="rc" required="true" />
		<cfscript>
			var local = StructNew();
			local.memberships = '';
		</cfscript>
		<cfif StructKeyExists(session, 'mura') and rc.$.currentUser().isLoggedIn()>
			<cflock type="readonly" scope="session" timeout="5">
				<cfset local.memberships = session.mura.memberships />
			</cflock>
			<cfset local.rs = rsCurrentUserGroups(rc) />
			<cfif local.rs.recordcount>
				<cfloop query="local.rs">
					<cfif not ListFindNoCase(local.memberships, local.rs.GroupName)>
						<cflock type="exclusive" scope="session" timeout="5">
							<cfset session.mura.memberships = ListAppend(session.mura.memberships, local.rs.GroupName) />
						</cflock>
					</cfif>
				</cfloop>
				<cfif StructKeyExists(rc, 'showReceipt') and rc.showReceipt>
					<cfset fw.redirect(action='public:main.receipt',preserve='success') />
				</cfif>
			</cfif>
		</cfif>
		<cfreturn true />
	</cffunction>

	<cffunction name="deleteMuraMembership" output="false" returntype="any">
		<cfargument name="rc" required="true" />
		<cfscript>
			var local = StructNew();
			local.memberships = '';
		</cfscript>
		<cfif StructKeyExists(session, 'mura') and rc.$.currentUser().isLoggedIn()>
			<cflock type="readonly" scope="session" timeout="5">
				<cfset local.memberships = session.mura.memberships />
			</cflock>
			<cfset local.rs = rsMuraSubscriberGroups(rc) />
			<cfif local.rs.recordcount>
				<cfloop query="local.rs">
					<cfif ListFindNoCase(local.memberships, local.rs.GroupName)>
						<cflock type="exclusive" scope="session" timeout="5">
							<cfset session.mura.memberships = ListDeleteAt(session.mura.memberships, ListFindNoCase(local.memberships, local.rs.GroupName)) />
						</cflock>
					</cfif>
				</cfloop>
			</cfif>
		</cfif>
		<cfreturn true />
	</cffunction>

	<cffunction name="rsCurrentUserGroups" output="false" returntype="any">
		<cfargument name="rc" required="true" />
		<cfset var local = StructNew() />
		<cfquery name="local.rs" 
			datasource="#rc.pluginConfig.getConfigBean().getDatasource()#" 
			username="#rc.pluginConfig.getConfigBean().getDBUsername()#" 
			password="#rc.pluginConfig.getConfigBean().getDBPassword()#">
			SELECT tusers.userID
				, tusersmemb.groupID
				, tusers.userID
				, tusers.GroupName
				, tusers.Fname
				, tusers.Lname
				, tusers.UserName
				, tusers.Website
				<!--- may cause issues (possible keyword conflict?) --->
				, tusers.Type
				, tusers.subType
				, tusers.Perm
				, tusers.InActive
				, tusers.IsPublic
				, tusers.SiteID
			FROM tusers 
				INNER JOIN tusersmemb on tusers.userid=tusersmemb.groupid 
				LEFT JOIN tfiles on tusers.photoFileId=tfiles.fileid 
			WHERE tusersmemb.userid = <cfqueryparam value="#rc.$.currentUser('userid')#" cfsqltype="cf_sql_char" maxlength="35" />
				AND tusers.subType = <cfqueryparam value="#rc.pluginConfig.getPackage()#" cfsqltype="cf_sql_varchar" maxlength="50" />
			ORDER BY tusers.groupname
		</cfquery>
		<cfreturn local.rs />
	</cffunction>

	<cffunction name="rsMuraSubscriberGroups" output="false" returntype="any">
		<cfargument name="rc" required="true" />
		<cfset var local = StructNew() />
		<cfquery name="local.rs" 
			datasource="#rc.pluginConfig.getConfigBean().getDatasource()#" 
			username="#rc.pluginConfig.getConfigBean().getDBUsername()#" 
			password="#rc.pluginConfig.getConfigBean().getDBPassword()#">
			SELECT UserID, GroupName, SiteID, IsPublic, Type, subType
			FROM tusers 
			WHERE subType LIKE <cfqueryparam value="#rc.pluginConfig.getPackage()#%" cfsqltype="cf_sql_varchar" />
				AND Type = <cfqueryparam value="1" cfsqltype="cf_sql_varchar" />
				AND InActive = 0
				AND IsPublic = 1
			ORDER BY GroupName ASC
		</cfquery>
		<cfreturn local.rs />
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

	<cffunction name="getSubscriptionOptionDetails" output="false" returntype="any">
		<cfargument name="subscriptionOption" required="true" type="uuid" />
		<cfargument name="pluginConfig" required="true" />
		<cfscript>
			var local = StructNew();
		</cfscript>
		<cfquery 	name="local.rs" 
					datasource="#arguments.pluginConfig.getConfigBean().getDatasource()#" 
					username="#arguments.pluginConfig.getConfigBean().getDBUsername()#" 
					password="#arguments.pluginConfig.getConfigBean().getDBPassword()#">
		SELECT UserID, GroupName, SiteID, IsPublic, Type, subType
		FROM tusers 
		WHERE UserID = <cfqueryparam value="#arguments.subscriptionOption#" cfsqltype="cf_sql_char" maxlength="35" />
			AND InActive = 0
		</cfquery>
		<cfreturn local.rs />
	</cffunction>

	<cffunction name="setMuraSubscribers" output="false" returntype="any">
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
		<cfscript>
			QueryAddColumn(local.rs, 'subscriptionPlan', ArrayNew(1));
			QueryAddColumn(local.rs, 'profileStartDate', ArrayNew(1));
			QueryAddColumn(local.rs, 'nextBillingDate', ArrayNew(1));
			QueryAddColumn(local.rs, 'profileStatus', ArrayNew(1));
			QueryAddColumn(local.rs, 'profileID', ArrayNew(1));
			QueryAddColumn(local.rs, 'GroupID', ArrayNew(1));
		</cfscript>
		<cfloop query="local.rs">
			<cfscript>
				local.userBean = application.serviceFactory.getBean('user');
				local.userBean.loadBy(userid=local.rs.UserID);
				QuerySetCell(local.rs,'subscriptionPlan',local.userBean.getValue('subscriptionPlan'),currentrow);
				QuerySetCell(local.rs,'profileStartDate',local.userBean.getValue('profileStartDate'),currentrow);
				QuerySetCell(local.rs,'nextBillingDate',DateFormat(local.userBean.getValue('nextBillingDate'), 'yyyy-mm-dd'),currentrow);
				QuerySetCell(local.rs,'profileStatus',local.userBean.getValue('profileStatus'),currentrow);
				QuerySetCell(local.rs,'profileID',local.userBean.getValue('profileID'),currentrow);
				QuerySetCell(local.rs,'GroupID',local.userBean.getValue('GroupID'),currentrow);
			</cfscript>
		</cfloop>
		<cfreturn local.rs />
	</cffunction>

	<cffunction name="getMuraSubscribers" output="false" returntype="any" access="remote">
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
						AND profileStatus LIKE <cfqueryparam value="#arguments.profileStatus#%" cfsqltype="cf_sql_varchar" />
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

	<!--- ****************************** PROFILE *********************************** --->

	<cffunction name="createTempProfile" output="false" returntype="void">
		<cfif not StructKeyExists(session, 'muraSubscriber')>
			<cflock type="exclusive" scope="session" timeout="5">
				<cfset session.muraSubscriber = StructNew() />
			</cflock>
		</cfif>
		<cflock type="exclusive" scope="session" timeout="5">
			<cfscript>
				if ( not IsDefined('session.muraSubscriber.profile') ) {
					session.muraSubscriber.profile = StructNew();
				};
			</cfscript>
		</cflock>
		<cfscript>
			setProfileID();
			setProfileStatus();
		</cfscript>
	</cffunction>

	<cffunction name="getProfileID" output="false" returntype="any">
		<cfscript>
			var local = StructNew();
			local.ret = '';
		</cfscript>
		<cflock type="readonly" scope="session" timeout="5">
			<cfif IsDefined('session.muraSubscriber.profile.PROFILEID')>
				<cfset local.ret = session.muraSubscriber.profile.PROFILEID />
			</cfif>
		</cflock>
		<cfreturn local.ret />
	</cffunction>

	<cffunction name="setProfileID" output="false" returntype="void">
		<cfargument name="profileID" required="false" default="" />
		<cflock type="exclusive" scope="session" timeout="5">
			<cfset session.muraSubscriber.profile.profileID = arguments.profileID />
		</cflock>
	</cffunction>

	<cffunction name="getProfileStatus" output="false" returntype="any">
		<cfscript>
			var local = StructNew();
			local.ret = 'temp';
		</cfscript>
		<cflock type="readonly" scope="session" timeout="5">
			<cfif IsDefined('session.muraSubscriber.profile.STATUS')>
				<cfset local.ret = session.muraSubscriber.profile.STATUS />
			</cfif>
		</cflock>
		<cfreturn local.ret />
	</cffunction>

	<cffunction name="setProfileStatus" output="false" returntype="void">
		<cfargument name="profileStatus" required="false" default="" />
		<cflock type="exclusive" scope="session" timeout="5">
			<cfset session.muraSubscriber.profile.status = arguments.profileStatus />
		</cflock>
	</cffunction>

	<cffunction name="getIsActive" output="false" returntype="boolean">
		<cfreturn ListFindNoCase('Active,ActiveProfile,Pending,PendingProfile',getProfileStatus()) />
	</cffunction>

	<cffunction name="getIsCancelled" output="false" returntype="boolean">
		<cfreturn ListFindNoCase('Cancelled,CancelledProfile',getProfileStatus()) />
	</cffunction>

	<cffunction name="getIsExpired" output="false" returntype="boolean">
		<cfreturn ListFindNoCase('Expired,ExpiredProfile',getProfileStatus()) />
	</cffunction>

	<cffunction name="getIsSuspended" output="false" returntype="boolean">
		<cfreturn ListFindNoCase('Suspended,SuspendedProfile',getProfileStatus()) />
	</cffunction>

	<!--- ****************************** SETUP / UTILS *********************************** --->

	<cffunction name="setup" output="false" returntype="any">
		<cfargument name="rc" />
		<cfscript>
			var local = StructNew();

			// container for errors
			rc.errors = ArrayNew(1);

			// prepare the profile navigation
			rc.nav = dspProfileNav(rc);

			// status
			rc.isActive = getIsActive();
			rc.isCancelled = getIsCancelled();
			rc.isExpired = getIsExpired();
			rc.isSuspended = getIsSuspended();

			// push listing of muraSubscriber groups the user belongs to into request.context scope
			rc.rsCurrentUserGroups = rsCurrentUserGroups(rc);
			rc.listCurrentUserGroups = ValueList(rc.rsCurrentUserGroups.GroupName);
		</cfscript>
		<cfif NOT StructKeyExists(session, 'muraSubscriber')>
			<cflock type="exclusive" scope="session" timeout="5">
				<cfset session.muraSubscriber = StructNew() />
			</cflock>
		</cfif>
		<!--- SUBSCRIBER AUTHENTICATION FLOW --->
		<cfscript>
			// logged in, but no credentials yet
			if ( rc.$.currentUser().isLoggedIn() and NOT hasMuraSubscriberCredentials() ) {
				// this will take care of getRecurringPaymentsProfileDetails() and updateCurrentMuraSubscriber(), then run the setup again
				doMuraSubscriberCredentials(rc);
				setup(rc);

			// logged in, has credentials: however, could be a NON-subscriber
			} else if ( rc.$.currentUser().isLoggedIn() and hasMuraSubscriberCredentials() ) {
				// if profileid DOES exist and Status is 'Active' or 'Pending' then we're good to go. 
				if ( getIsActive() ) {
					// we're good, don't really need to do anything. ;)
					fw.redirect(action='public:main');

				// was trying to purchase an option, but had to create a profile first
				//} else if ( StructKeyExists(session, 'subscriptionOption') ) {					
					//fw.redirect(action='public:main.setexpresscheckout');

				// Otherwise, send to options.
				} else {
					fw.redirect(action='public:main.options');
				};

			// NOT logged in AND does NOT have credentials - OR - NOT logged in AND HAS credentials
			} else {	
				fw.redirect(action='public:main.options');
			};

			return;
		</cfscript>
	</cffunction>

	<cffunction name="doMuraSubscriberCredentials" output="false" returntype="void">
		<cfargument name="rc" required="true" />
		<cfscript>
			var local = StructNew();
			local.hasCredentials = false;
			local.hasDetails = false;
		</cfscript>
		<cflock type="exclusive" scope="session" timeout="5">
			<cfset StructDelete(session.muraSubscriber, 'hasCredentials') />
		</cflock>
		<cfscript>
			// 1) try to get updated info from PayPal on this subscriber
			if ( rc.$.currentUser().isLoggedIn() and len(trim(rc.$.currentUser('profileID'))) ) {
				try {
					local.hasDetails = getRecurringPaymentsProfileDetails(rc);
				} catch (any e) {
					local.hasDetails = false;
				};
			} else if ( getIsAdmin(rc) ) {
					local.hasDetails = true;
			} else {
				local.hasDetails = false;
			};
			// 2) if hasDetails, then update the database with the current info from PayPal
			if ( local.hasDetails and not getIsAdmin(rc) ) {
				updateCurrentMuraSubscriber(rc);
			} else {
				createTempProfile();
			};
			local.hasCredentials = true;
		</cfscript>
		<cflock type="exclusive" scope="session" timeout="5">
			<cfset session.muraSubscriber.hasCredentials = local.hasCredentials />
		</cflock>
	</cffunction>

	<cffunction name="hasMuraSubscriberCredentials" output="false" returntype="boolean">
		<cfset var hasCredentials = false />
		<cfif StructKeyExists(session, 'muraSubscriber') and StructKeyExists(session.muraSubscriber, 'hasCredentials')>
			<cflock type="readonly" scope="session" timeout="5">
				<cfset hasCredentials = session.muraSubscriber.hasCredentials />
			</cflock>
		</cfif>
		<cfreturn hasCredentials />
	</cffunction>

	<cffunction name="getThisDirectory" output="false" returntype="string">
		<cfscript>
			var local = StructNew();
			local.fileDelim = CreateObject('java','java.io.File').separator;
			local.rootLen = Len(ExpandPath(local.fileDelim));
			local.thisDir = RemoveChars(GetDirectoryFromPath(GetCurrentTemplatePath()),1,local.rootLen-1);
			return '/' & ListChangeDelims(local.thisDir, '/', local.fileDelim) & '/';
		</cfscript>
	</cffunction>

	<cffunction name="getBaseURL" output="false" returntype="string">
		<cfscript>
			return getPageContext().getRequest().getScheme() & '://' & getPageContext().getRequest().getServerName();
		</cfscript>
	</cffunction>

	<cffunction name="dspProfileNav" output="false" returntype="string">
		<cfargument name="rc" required="true" />
		<cfscript>
			var local = StructNew();
			local.nav = '';
			// welcomeLink
			if ( rc.$.currentUser().isLoggedIn() ) {
				local.welcomeLink = '<li><strong>Hello, #rc.$.currentUser().getFullName()#.</strong> (<a href="#application.configBean.getIndexFile()#?doaction=logout&amp;nocache=1">Not #rc.$.currentUser('Fname')#</a>?)</li>';
				// profileLink			
				local.profileLink = '<li><a href="#rc.$.siteConfig('editProfileURL')#">Your Profile</a></li>';
				if ( len(trim(rc.$.currentUser('profileID'))) ) {
					local.profileLink = local.profileLink & '<li><a href="#application.configBean.getIndexFile()#?action=public:main.options">Your Account</a></li>';
				};
			} else {
				local.welcomeLink = '<li><strong>Hello.</strong> <a href="#rc.$.getSite(rc.$.event('siteid')).getLoginURL()#">Sign in</a>.</li>';
				//profileLink
				local.profileLink = '';
			};
			// sandboxLinks
			if ( rc.$.payPalService.getValue('useSandbox') ) {
			 	local.sandboxLinks = '<li class="red">Sandbox is ENABLED</li>';
			 } else {
			 	local.sandboxLinks = '';
			};
			
			// build the nav
			local.nav = '<ul>' & local.nav & local.welcomeLink & local.profileLink & local.sandboxLinks & '</ul>';
			//local.nav = '<ul>' & local.nav & local.welcomeLink & local.profileLink & local.sandboxLinks & '<li>IsAdmin: #getIsAdmin(rc)#</li>' & '</ul>';
			return trim(local.nav);
		</cfscript>
	</cffunction>

	<cffunction name="getIsAdmin" output="false" returntype="boolean">
		<cfargument name="rc" required="true" />
		<cfscript>
			if ( 
				rc.$.currentUser().isLoggedIn()  
				and rc.$.currentUser('InActive') eq '0'
				and ( rc.$.currentUser('isPublic') eq '0' OR rc.$.currentUser('S2') eq '1' )
			) {
				return true;
			} else {
				return false;
			};
		</cfscript>
	</cffunction>

</cfcomponent>