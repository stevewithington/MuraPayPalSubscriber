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

		Document:	details.cfm
		Author:		Steve Withington | www.stephenwithington.com
		Modified:	2011.09.02

--->
</cfsilent>

<cfoutput>
	<h3>Subscriber Details</h3>	
	<ul id="navTask">
		<li><a href="#buildURL('admin:subscribers')#">View All Subscribers</a></li>
	</ul>
	<cfif StructKeyExists(rc, 'rsSubscriber') and rc.rsSubscriber.recordcount eq 1>
	
		<!--- admin messaging --->		
		<cfif ListFindNoCase('Suspended,SuspendedProfile', rc.rsSubscriber.profileStatus)>
			<h4>This profile has been <span class="red">suspended</span>, and no further amounts will be collected.<br />
			To reactivate this profile, click the Reactivate button under the Profile information below.</h4>
		<cfelseif ListFindNoCase('Cancelled,CancelledProfile', rc.rsSubscriber.profileStatus)>
			<h4><span class="red">This profile has been cancelled and cannot be reactivated.</span><br />
			<em>No more recurring payments will be made or collected.</em></h4>
		</cfif>
		
		<!--- subscriber details --->
		<div id="subscriberDetailsTables">
			<table class="stripe">
				<tbody>
					<tr>
						<th>Name</th><td>#rc.rsSubscriber.Fname# #rc.rsSubscriber.Lname#</td>
					</tr>
					<tr>
						<th>Email</th><td>#rc.rsSubscriber.EmailLink#</td>
					</tr>
					<tr>
						<th>Subscription Plan</th><td>#rc.rsSubscriber.SubscriptionPlan#</td>
					</tr>
					<tr>
						<th>Status</th><td<cfif ListFindNoCase('Cancelled,CancelledProfile', rc.rsSubscriber.ProfileStatus)> class="red"</cfif>>#rc.rsSubscriber.ProfileStatus#</td>
					</tr>
					<tr>
						<th>SiteID</th><td>#rc.rsSubscriber.SiteID#</td>
					</tr>
					<tr>
						<th>Last Updated</th><td>#DateFormat(rc.rsSubscriber.LastUpdate, 'yyyy-mm-dd')# #Timeformat(rc.rsSubscriber.LastUpdate, 'h:mm:ss tt')#</td>
					</tr>
					<tr>
						<th>Next Billing Date</th><td>#DateFormat(rc.rsSubscriber.NextBillingDate, 'yyyy-mm-dd')#</td>
					</tr>
					<tr>
						<th>Profile Start Date</th><td>#DateFormat(rc.rsSubscriber.ProfileStartDate, 'yyyy-mm-dd')#</td>
					</tr>
					<tr>
						<th>PayPal ProfileID</th><td>#rc.rsSubscriber.ProfileID#</td>
					</tr>
					<cfif StructKeyExists(rc.rsSubscriber, 'transactionID')>
						<tr>
							<th>PayPal TransactionID</th><td>#rc.rsSubscriber.transactionID#</td>
						</tr>
					</cfif>
				</tbody>
			</table>
			<cfif not ListFindNoCase('Cancelled,CancelledProfile', rc.rsSubscriber.profileStatus)>
				<cfif not ListFindNoCase('Suspended,SuspendedProfile', rc.rsSubscriber.profileStatus)>
					<!--- Suspend button --->
					<div class="subscriberButton">
						<form class="subscriberButton">
							<input type="hidden" name="action" value="admin:subscribers.manageprofile" />
							<input type="hidden" name="userid" value="#rc.rsSubscriber.userid#" />
							<input type="hidden" name="profileid" value="#rc.rsSubscriber.profileid#" />
							<input type="hidden" name="statusAction" value="Suspend" />
							<input type="hidden" name="currentStatus" value="#rc.rsSubscriber.profileStatus#" />
							<input type="submit" value="Suspend" onclick="if(
									confirm(
										'WARNING: You are about to suspend this profile,\nand no further amounts will be collected.'
										)
									){
										return confirm(
											'Are you sure you want to suspend this profile?'
										);
									} else {
										return false;
									}" />
						</form>
					</div>
				<cfelse>
					<!--- Reactivate button --->
					<div class="subscriberButton">
						<form class="subscriberButton">
							<input type="hidden" name="action" value="admin:subscribers.manageprofile" />
							<input type="hidden" name="userid" value="#rc.rsSubscriber.userid#" />
							<input type="hidden" name="profileid" value="#rc.rsSubscriber.profileid#" />
							<input type="hidden" name="statusAction" value="Reactivate" />
							<input type="hidden" name="currentStatus" value="#rc.rsSubscriber.profileStatus#" />
							<input type="submit" value="Reactivate" onclick="if(
									confirm(
										'WARNING: You are about to reactivate this profile,\nand future billing will commence.'
										)
									){
										return confirm(
											'Are you sure you want to reactivate this profile?'
										);
									} else {
										return false;
									}" />
						</form>
					</div>
				</cfif>
				<!--- Cancel subscription button --->
				<div class="subscriberButton">
					<form class="subscriberButton">
						<input type="hidden" name="action" value="admin:subscribers.manageprofile" />
						<input type="hidden" name="userid" value="#rc.rsSubscriber.userid#" />
						<input type="hidden" name="profileid" value="#rc.rsSubscriber.profileid#" />
						<input type="hidden" name="statusAction" value="Cancel" />
						<input type="hidden" name="currentStatus" value="#rc.rsSubscriber.profileStatus#" />
						<input type="submit" value="Cancel Subscription" onclick="if(
									confirm(
										'WARNING: You are about to cancel this profile,\nand a cancelled subscriber cannot be reactivated.'
										)
									){
										return confirm(
											'Are you sure you want to continue?'
										);
									} else {
										return false;
									}" />
					</form>
				</div>
			<cfelse>
				<!--- future TODO: display delete button. before deleting it, we need to cancel the subscription first. --->
			</cfif>
		</div>
		
	<cfelse>
		<p><em>The selected subscriber either does not exist or is no longer available.</em></p>
	</cfif>
</cfoutput>