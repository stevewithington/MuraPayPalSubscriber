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

		Document:	default.cfm
		Author:		Steve Withington | www.stephenwithington.com
		Modified:	2011.09.02

--->
<cfoutput>
	<h3>Subscription Plans</h3>	
	<ul id="navTask">
		<li><a href="#buildURL('admin:main.edit')#">Add New Subscription Plan</a></li>
	</ul>

	<!--- messaging --->
	<cfif rc.add>
		<div class="success">
			<h4>New Subscription Created!</h4>
			<p><em>Don't forget to enable this group for any desired areas that are currently restricted.</em></p>
		</div>
	<cfelseif rc.update>
		<h4 class="success">Subscription Updated!</h4>
	<cfelseif rc.delete>
		<h4 class="error">Subscription Deleted!</h4>
	</cfif>

	<!--- list --->
	<cfif rc.rsSubscriberGroups.recordcount>
		<table class="stripe">
			<tr>
				<th class="varWidth">Subscription Plan</th>
				<th>Active</th>
				<!---<th>Amount</th>--->
				<th>&nbsp;</th>
			</tr>
			<cfloop query="rc.rsSubscriberGroups">
				<cfscript>
					local.groupBean = application.serviceFactory.getBean('user');
					local.groupBean.loadBy(userid=rc.rsSubscriberGroups.UserID);
				</cfscript>
				<tr>
					<td class="varWidth"><a href="#buildURL('admin:main.edit')#&amp;userid=#rc.rsSubscriberGroups.UserID#">#HTMLEditFormat(local.groupBean.getValue('subscriptionDescription'))#</a></td>
					<td><cfif local.groupBean.getValue('InActive')><span class="red">No</span><cfelse><span class="green">Yes</span></cfif></td>
					<!---<td>#dollarFormat(local.groupBean.getValue('subscriptionBillingCycleAmount'))#</td>--->
					<td class="administration">
						<ul class="two">
							<li class="edit"><a title="Edit" href="#buildURL('admin:main.edit')#&amp;userid=#rc.rsSubscriberGroups.UserID#">Edit</a></li>
							<li class="delete"><a title="Delete" href="#buildURL('admin:main.delete')#&amp;userid=#rc.rsSubscriberGroups.UserID#" 
								onclick="if(
									confirm(
										'WARNING: A deleted subscription plan cannot be recovered. You may want to verify that there are no subscribers currently assigned to the \'#HTMLEditFormat(local.groupBean.getValue('GroupName'))#\' plan!'
										)
									){
										return confirm(
											'Are you sure that you want to continue?'
										);
									} else {
										return false;
									}">Delete</a></li>
						</ul>
					</td>
				</tr>
			</cfloop>
		</table>
	<cfelse>
		<p><em>No subscription options exist yet. <a href="#buildURL('admin:main.edit')#">Let's add one now!</a></em></p>
	</cfif>

</cfoutput>