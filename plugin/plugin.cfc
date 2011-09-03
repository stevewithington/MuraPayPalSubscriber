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

		Document:	plugin/plugin.cfc
		Author:		Steve Withington | www.stephenwithington.com
		Modified:	2011.09.02

--->
<cfcomponent output="false" extends="mura.plugin.plugincfc">

	<cfset variables.config = '' />

	<cffunction name="init" access="public" returntype="any" output="false">
		<cfargument name="config"  type="any" default="" />
		<cfscript>
			variables.config = arguments.config;
		</cfscript>
	</cffunction>
	
	<cffunction name="install" access="public" returntype="void" output="false">
		<cfscript>
			var local = StructNew();

			// need to check and see if this is already installed ... if so, then abort!
			local.moduleid = variables.config.getModuleID();

			// comment this out if you want to allow more than 1 installation of this plugin per Mura CMS install.
			if ( val(getInstallationCount()) neq 1 ) {
				variables.config.getPluginManager().deletePlugin(local.moduleid);
			} else {
				upsertMuraSubscriber();
			};

			application.appInitialized = false;
		</cfscript>
	</cffunction>

	<cffunction name="update" access="public" returntype="void" output="false">
		<cfscript>
			upsertMuraSubscriber();
			// this will be executed by the pluginManager when the plugin is updated.
			application.appInitialized = false;
		</cfscript>
	</cffunction>
	
	<cffunction name="delete" access="public" returntype="void" output="false">
		<cfscript>
			// this will be executed by the pluginManager when the plugin is deleted.
			var local = StructNew();
			// don't delete the subTypes if this is being invoked by the deletePlugin() from install()
			if ( val(getInstallationCount()) eq 1 ) {
				// WARNING: deleting a subType will also delete any files associated with it! For example, if you
				// 			uploaded 50 files using this plugin, then all 50 files will also be deleted.
				deleteMuraSubscriberGroup();
				deleteMuraSubscriberUser();
			};
			application.appInitialized = false;
		</cfscript>
	</cffunction>

	<!--- *******************************    private    ******************************** --->
	<cffunction name="getInstallationCount" access="private" returntype="any" output="false">
		<cfscript>
			var qoq = '';
			var rs = variables.config.getConfigBean().getPluginManager().getAllPlugins();
		</cfscript>
		<cfquery name="qoq" dbtype="query">
			SELECT *
			FROM rs
			WHERE package = <cfqueryparam value="#variables.config.getPackage()#" cfsqltype="cf_sql_varchar" maxlength="100" />
		</cfquery>
		<cfreturn val(qoq.recordcount) />
	</cffunction>


	<cffunction name="upsertMuraSubscriber" access="private" returntype="any" output="false">
		<cfscript>
			var local = StructNew();
			// grab a recordset of sites this plugin has been assigned to
			local.rsSites = variables.config.getAssignedSites();
			// for each assigned site, create the necessary custom class extensions and attributes
			for ( local.i=1; local.i lte local.rsSites.recordcount; local.i++ ) {
				doMuraSubscriberGroup(siteid=local.rsSites.siteid[local.i]);
				doMuraSubscriberUser(siteid=local.rsSites.siteid[local.i]);
			};
		</cfscript>
	</cffunction>

	<cffunction name="doMuraSubscriberGroup" access="private" returntype="void" output="false">
		<cfargument name="siteid" required="true" />
		<cfscript>
			var local = StructNew();
			// subType: muraSubscriber
			local.subType = application.classExtensionManager.getSubTypeBean();
			local.subType.setType('1'); // Portal, Page, etc. (1 = 'User Group' and 2 = 'User')
			local.subType.setSubType(variables.config.getPackage());
			local.subType.setSiteID(arguments.siteid);
			local.subType.load();
			local.subType.setBaseTable('tusers');
			local.subType.setBaseKeyField('userID');
			local.subType.setDataTable('tclassextenddatauseractivity');
			local.subType.save();

			// grab the subTypeID
			local.subTypeID = local.subType.getSubTypeID();

			// get rid of the 'Default' extendSet
			local.subType.getExtendSetByName('Default').delete();

			// extendSet: muraSubscriber Settings
			local.extendSetName = variables.config.getPackage() & ' Group Settings';
			local.extendSetBean = local.subType.getExtendSetBean();
			local.extendSetBean.setName(local.extendSetName);
			local.extendSetBean.load();
			local.extendSetBean.setContainer('Basic');
			local.extendSetBean.save();

			// now we need to add the extendSet attributes
			upsertMuraSubscriberGroupAttributes(local.extendSetBean);
		</cfscript>
	</cffunction>
	
	<cffunction name="upsertMuraSubscriberGroupAttributes" access="private" returntype="void" output="false">
		<cfargument name="extendSetBean" required="true" />
		<cfscript>
			var local = StructNew();
	
			// subscriptionBillingAmount
			local.attribute = arguments.extendSetBean.getAttributeBean();
			local.attribute.setName('subscriptionBillingCycleAmount');
			local.attribute.load();
			local.attribute.setLabel('Billing Amount Each Cycle USD');
			local.attribute.setHint('Please enter the dollar amount that should be charged for each billing cycle.');
			local.attribute.setType('textbox');
			local.attribute.setDefaultValue(0);	
			local.attribute.setRequired(true);
			local.attribute.setValidation('Numeric');
			local.attribute.setRegex('');
			local.attribute.setMessage('Billing Amount Each Cycle USD should be numbers only please.');
			local.attribute.setOptionList('');
			local.attribute.setOptionLabelList('');
			local.attribute.setOrderNo(1);
			local.attribute.save();
			
			// subscriptionBillingCycleNumber (billing frequency)
			local.attribute = arguments.extendSetBean.getAttributeBean();
			local.attribute.setName('subscriptionBillingCycleNumber');
			local.attribute.load();
			local.attribute.setLabel('Subscription Billing Cycle Number');
			local.attribute.setHint('This field in conjunction with Subscription Billing Cycle Period specifies the total subscription duration. Specify an integer value in the allowable range for the units of duration that you specify with Subscription Period/Units.');
			local.attribute.setType('SelectBox');
			local.attribute.setDefaultValue(1);	
			local.attribute.setRequired(true);
			local.attribute.setValidation('Numeric');
			local.attribute.setRegex('');
			local.attribute.setMessage('');
			local.attribute.setOptionList('1^2^3^4^5^6^7^8^9^10^11^12^13^14^15^16^17^18^19^20^21^22^23^24^25^26^27^28^29^30');
			local.attribute.setOptionLabelList('1^2^3^4^5^6^7^8^9^10^11^12^13^14^15^16^17^18^19^20^21^22^23^24^25^26^27^28^29^30');
			local.attribute.setOrderNo(2);
			local.attribute.save();
	
			// subscriptionBillingCyclePeriod (billing period)
			local.attribute = arguments.extendSetBean.getAttributeBean();
			local.attribute.setName('subscriptionBillingCyclePeriod');
			local.attribute.load();
			local.attribute.setLabel('Subscription Billing Cycle Period');
			local.attribute.setHint('This field in conjunction with Subscription Billing Cycle Number specifies the total subscription duration. Allowable values: days; allowable range is 1 to 90, weeks; allowable range is 1 to 52, months; allowable range is 1 to 24, years; allowable range is 1 to 5');
			local.attribute.setType('SelectBox');
			local.attribute.setDefaultValue('M');	
			local.attribute.setRequired(true);
			local.attribute.setValidation('None');
			local.attribute.setRegex('');
			local.attribute.setMessage('');
			local.attribute.setOptionList('D^W^M^Y');
			local.attribute.setOptionLabelList('Day^Week^Month^Year');
			local.attribute.setOrderNo(3);
			local.attribute.save();
			
			// subscriptionDescription
			local.attribute = arguments.extendSetBean.getAttributeBean();
			local.attribute.setName('subscriptionDescription');
			local.attribute.load();
			local.attribute.setLabel('Subscription Description');
			local.attribute.setHint('This shows up in the subscription options drop down list (i.e., Monthly Subscription Plan - 20.00 per Month)');
			local.attribute.setType('textbox');
			local.attribute.setDefaultValue('');	
			local.attribute.setRequired(false);
			local.attribute.setValidation('None');
			local.attribute.setRegex('');
			local.attribute.setMessage('');
			local.attribute.setOptionList('');
			local.attribute.setOptionLabelList('');
			local.attribute.setOrderNo(4);
			local.attribute.save();
		</cfscript>
	</cffunction>

	<cffunction name="deleteMuraSubscriberGroup" access="private" returntype="any" output="false">
		<cfscript>
			var local 		= StructNew();
			local.rsSites	= application.settingsManager.getList();
			local.subType 	= application.classExtensionManager.getSubTypeBean();
			for ( local.i=1; local.i lte local.rsSites.recordcount; local.i++ ) {
				local.subType.setType('1');
				local.subType.setSubType(variables.config.getPackage());
				local.subType.setSiteID(local.rsSites.siteid[local.i]);
				local.subType.load();
				local.subType.delete();		
			};
		</cfscript>
	</cffunction>

	<cffunction name="doMuraSubscriberUser" access="private" returntype="void" output="false">
		<cfargument name="siteid" required="true" />
		<cfscript>
			var local = StructNew();
			// subType: muraSubscriber
			local.subType = application.classExtensionManager.getSubTypeBean();
			local.subType.setType('2'); // Portal, Page, etc. (1 = 'User Group' and 2 = 'User')
			local.subType.setSubType(variables.config.getPackage());
			local.subType.setSiteID(arguments.siteid);
			local.subType.load();
			local.subType.setBaseTable('tusers');
			local.subType.setBaseKeyField('userID');
			local.subType.setDataTable('tclassextenddatauseractivity');
			local.subType.save();

			// grab the subTypeID
			local.subTypeID = local.subType.getSubTypeID();

			// get rid of the 'Default' extendSet
			local.subType.getExtendSetByName('Default').delete();

			// extendSet: muraSubscriber Settings
			//local.rsExtendSets = local.subType.getSetsQuery();
			//local.extendSetNameList = ValueList(local.rsExtendSets.name);
			local.extendSetName = variables.config.getPackage() & ' User Settings';

			local.extendSetBean = local.subType.getExtendSetBean();
			local.extendSetBean.setName(local.extendSetName);
			local.extendSetBean.load();
			local.extendSetBean.setContainer('Basic');
			local.extendSetBean.save();

			// now we need to add the extendSet attributes
			upsertMuraSubscriberUserAttributes(local.extendSetBean);
		</cfscript>
	</cffunction>

	<cffunction name="upsertMuraSubscriberUserAttributes" access="private" returntype="void" output="false">
		<cfargument name="extendSetBean" required="true" />
		<cfscript>
			var local = StructNew();

			// profileID
			local.attribute = arguments.extendSetBean.getAttributeBean();
			local.attribute.setName('profileID');
			local.attribute.load();
			local.attribute.setLabel('Profile ID');
			local.attribute.setHint('PayPal Recurring Payments ProfileID');
			local.attribute.setType('hidden');
			local.attribute.setDefaultValue('');	
			local.attribute.setRequired(true);
			local.attribute.setValidation('None');
			local.attribute.setRegex('');
			local.attribute.setMessage('');
			local.attribute.setOptionList('');
			local.attribute.setOptionLabelList('');
			local.attribute.setOrderNo(1);
			local.attribute.save();

			// profileStatus
			local.attribute = arguments.extendSetBean.getAttributeBean();
			local.attribute.setName('profileStatus');
			local.attribute.load();
			local.attribute.setLabel('Profile Status');
			local.attribute.setHint('Paypal Recurring Payments Profile Status (i.e., Active, Pending, Expired, Suspended, Cancelled)');
			local.attribute.setType('hidden');
			local.attribute.setDefaultValue('');	
			local.attribute.setRequired(true);
			local.attribute.setValidation('None');
			local.attribute.setRegex('');
			local.attribute.setMessage('');
			local.attribute.setOptionList('');
			local.attribute.setOptionLabelList('');
			local.attribute.setOrderNo(2);
			local.attribute.save();

			// subscriptionPlan
			local.attribute = arguments.extendSetBean.getAttributeBean();
			local.attribute.setName('subscriptionPlan');
			local.attribute.load();
			local.attribute.setLabel('Subscription Plan');
			local.attribute.setHint('The DESC from PayPal of which plan the subscriber is enrolled in.');
			local.attribute.setType('hidden');
			local.attribute.setDefaultValue('');	
			local.attribute.setRequired(true);
			local.attribute.setValidation('None');
			local.attribute.setRegex('');
			local.attribute.setMessage('');
			local.attribute.setOptionList('');
			local.attribute.setOptionLabelList('');
			local.attribute.setOrderNo(3);
			local.attribute.save();

			// profileStartDate
			local.attribute = arguments.extendSetBean.getAttributeBean();
			local.attribute.setName('profileStartDate');
			local.attribute.load();
			local.attribute.setLabel('Profile Start Date');
			local.attribute.setHint('The date the profile was created with PayPal.');
			local.attribute.setType('hidden');
			local.attribute.setDefaultValue('');	
			local.attribute.setRequired(true);
			local.attribute.setValidation('None');
			local.attribute.setRegex('');
			local.attribute.setMessage('');
			local.attribute.setOptionList('');
			local.attribute.setOptionLabelList('');
			local.attribute.setOrderNo(4);
			local.attribute.save();

			// nextBillingDate
			local.attribute = arguments.extendSetBean.getAttributeBean();
			local.attribute.setName('nextBillingDate');
			local.attribute.load();
			local.attribute.setLabel('Next Billing Date');
			local.attribute.setHint('The date when the next payment is due.');
			local.attribute.setType('hidden');
			local.attribute.setDefaultValue('');	
			local.attribute.setRequired(true);
			local.attribute.setValidation('None');
			local.attribute.setRegex('');
			local.attribute.setMessage('');
			local.attribute.setOptionList('');
			local.attribute.setOptionLabelList('');
			local.attribute.setOrderNo(5);
			local.attribute.save();

			// transactionID
			local.attribute = arguments.extendSetBean.getAttributeBean();
			local.attribute.setName('transactionID');
			local.attribute.load();
			local.attribute.setLabel('Transaction ID');
			local.attribute.setHint('The PayPal Transaction ID.');
			local.attribute.setType('hidden');
			local.attribute.setDefaultValue('');	
			local.attribute.setRequired(true);
			local.attribute.setValidation('None');
			local.attribute.setRegex('');
			local.attribute.setMessage('');
			local.attribute.setOptionList('');
			local.attribute.setOptionLabelList('');
			local.attribute.setOrderNo(6);
			local.attribute.save();
		</cfscript>
	</cffunction>

	<cffunction name="deleteMuraSubscriberUser" access="private" returntype="any" output="false">
		<cfscript>
			var local 		= StructNew();
			local.rsSites	= application.settingsManager.getList();
			local.subType 	= application.classExtensionManager.getSubTypeBean();
			for ( local.i=1; local.i lte local.rsSites.recordcount; local.i++ ) {
				local.subType.setType('2');
				local.subType.setSubType(variables.config.getPackage());
				local.subType.setSiteID(local.rsSites.siteid[local.i]);
				local.subType.load();
				local.subType.delete();		
			};
		</cfscript>
	</cffunction>

</cfcomponent>