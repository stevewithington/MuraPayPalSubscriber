<cfsilent>
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

		Document:	options.cfm
		Author:		Steve Withington | www.stephenwithington.com
		Modified:	2011.09.02

--->

	<cfsavecontent variable="local.clientMessage">
		<cfif len(trim(rc.pluginConfig.getSetting('messageOptions')))>
			<cfscript>
				local.txt = rc.lib.HTMLSafeText(rc.pluginConfig.getSetting('messageOptions'));
				local.txt = rc.lib.XHTMLParagraphFormat(local.txt);
			</cfscript>
			<cfoutput>#local.txt#</cfoutput>
		<cfelse>
			<p>Select any of the available subscription options from the dropdown below.</p>
		</cfif>
	</cfsavecontent>

	<cfsavecontent variable="local.renewMessage">
		<cfif len(trim(rc.pluginConfig.getSetting('messageRenew')))>
			<cfscript>
				local.txt = rc.lib.HTMLSafeText(rc.pluginConfig.getSetting('messageRenew'));
				local.txt = rc.lib.XHTMLParagraphFormat(local.txt);
			</cfscript>
			<cfoutput>#local.txt#</cfoutput>
		<cfelse>
			<p>Please renew your account today!</p>
		</cfif>
	</cfsavecontent>

	<cfsavecontent variable="local.suspendedMessage">
		<cfif len(trim(rc.pluginConfig.getSetting('messageSuspend')))>
			<cfscript>
				local.txt = rc.lib.HTMLSafeText(rc.pluginConfig.getSetting('messageSuspend'));
				local.txt = rc.lib.XHTMLParagraphFormat(local.txt);
			</cfscript>
			<cfoutput>#local.txt#</cfoutput>
		<cfelse>
			<p>Your account has been suspended. Please contact us. Thank you.</p>
		</cfif>
	</cfsavecontent>

</cfsilent>
<cfoutput>

	<!---<h3>#rc.$.siteConfig('editProfileURL')#</h3>--->

	<!--- active --->
	<cfif rc.isActive>
		<div id="subscriberDetals">
			<table>
				<tr>
					<th colspan="3"><h5>Current Subscription Details</h5></th>
				</tr>
				<tr>
					<th>Subscription</th>
					<th>Next Billing Date</th>
					<th>Status</th>
				</tr>
				<tr>
					<td>#$.currentUser('subscriptionPlan')#</td>
					<td>#DateFormat($.currentUser('nextBillingDate'), 'mmmm d, yyyy')#</td>
					<td>#$.currentUser('profileStatus')#</td>
				</tr>
			</table>
			<form method="post">
				<input type="image" src="https://www.paypal.com/en_US/i/btn/btn_unsubscribe_LG.gif" border="0" alt="Unsubscribe" onclick="javascript:if(confirm('Your current plan WILL BE CANCELLED.\n\nAre you sure you want to continue?')){return true;} else {return false;}" />
				<input type="hidden" name="action" value="public:main.cancelrecurringpaymentsprofile" />
			</form>
		</div>
	</cfif>

	<!---
		Subscription Options

			* do not show if:
				- subscriber is Suspended
				- subscriber is Active AND there is only 1 subscription option (otherwise, the dropdown will be empty)
	--->
	<cfif not rc.isSuspended and rc.rsMuraSubscriberGroups.recordcount
		and not ( rc.isActive and rc.rsMuraSubscriberGroups.recordcount eq 1 ) >
		<h4><cfif rc.isActive>Other</cfif> Subscription Options</h4>
		#local.clientMessage#
		<div id="muraSubscriberWrapper">
			<form method="post">
					<p><select name="subscriptionOption">
					<cfloop query="rc.rsMuraSubscriberGroups">
						<cfscript>
							local.groupBean = application.serviceFactory.getBean('user');
							local.groupBean.loadBy(userid=rc.rsMuraSubscriberGroups.UserID);
						</cfscript>
						<cfif IsDefined('session.muraSubscriber.profile.profileReference') and ListLast(session.muraSubscriber.profile.profileReference,'^') eq rc.rsMuraSubscriberGroups.UserID and not ListFindNoCase('Cancelled,CancelledProfile', session.muraSubscriber.profile.status)>
						<!---	<option value="#rc.rsMuraSubscriberGroups.UserID#" selected="selected">#local.groupBean.getValue('subscriptionDescription')# (YOUR CURRENT PLAN)</option>--->
						<cfelse>
							<option value="#rc.rsMuraSubscriberGroups.UserID#">#local.groupBean.getValue('subscriptionDescription')#</option>							
						</cfif>
						
						</cfloop>
					</select></p>
				<p><input type="image" name="submit" src="https://www.paypal.com/en_US/i/btn/btn_subscribeCC_LG.gif" id="submit" runat="server"<cfif rc.isActive> onclick="if(confirm('You are selecting a new plan,\nso your current plan WILL BE CANCELLED.\n\nAre you sure you want to continue?')){return true;} else {return false;}"</cfif> /></p>
				<input type="hidden" name="action" value="public:main.setexpresscheckout" />
			</form>
		</div>
		<cfif not $.currentUser().isLoggedIn()>
			<p><strong>Already have an account? <a href="#$.getSite($.event('siteid')).getLoginURL()#">Please login &raquo;</a></strong></p>
		</cfif>
	</cfif>
	
	<!--- cancelled/expired --->
	<cfif rc.isCancelled or rc.isExpired>
		<div id="subscriberDetails">
			#local.renewMessage#
			<table>
				<tr>
					<th colspan="2"><h5>Subscription Details</h5></th>
				</tr>
				<tr>
					<th>Subscription</th>
					<th>Status</th>
				</tr>
				<tr>
					<td>#$.currentUser('subscriptionPlan')#</td>
					<td><span class="red">#$.currentUser('profileStatus')#</span></td>
				</tr>
			</table>
		</div>
	</cfif>
	
	<!--- suspended--->
	<cfif rc.isSuspended>
		<div id="subscriberDetails">
			<h3>Account Is Suspended</h3>
			#local.suspendedMessage#
		</div>
	</cfif>

</cfoutput>