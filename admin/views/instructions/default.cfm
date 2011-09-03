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

		Document:	/admin/views/main/default.cfm
		Author:		Steve Withington | www.stephenwithington.com
		Modified:	2011.09.02

--->
</cfsilent>
<cfoutput><div class="subscriberAdminContent">
	<h3 class="red">Plugin User Warnings/Notices</h3>
	<ul><li>BE WARY OF UPDATES TO SUBSCRIPTIONS
			<ul>
				<li>Once a subscription option has been created/activated, if any changes are made to that subscription such as price, name, etc. ... anyone who subscribed before the change will continue to be billed at the original rate. In other words, their rates and/or terms WILL NOT CHANGE.</li>
			</ul>
	</li>
		<li>DON'T DELETE SUBSCRIPTIONS
			<ul>
				<li>If a subscription is deleted, subscribers will continue to be billed.</li>
				<li>If you need to delete a subscription, consider either making it 'Inactive' first. Otherwise, you'll want to cancel each subscriber's account before doing so.</li>
			</ul>
		</li>
		<li>DON'T MANAGE USERS VIA SITE MEMBERS LINK IN ADMIN AREA
			<ul>
				<li>If a subscriber is removed from a group by an Administrator (via Site Members), they will continue to be billed until the subscriber logs into PayPal and cancels their subscription there.</li>
				<li>However, if for whatever reason, you need to delete a subscriber, their subscription should automatically be cancelled during the delete process.</li>
			</ul>
		</li>
		<li>APPLY TO ONE SITE PER MURA INSTALL
			<ul>
				<li>While Mura CMS can handle multiple web sites per installation, this plugin will only work with one site per Mura installation.</li>
			</ul>
		</li>
		<li>OTHER THINGS TO BE AWARE OF
			<ul>
				<li>If a subscriber cancels their subscription by logging into their PayPal account, the account will still show as Active in the Admin area until either you view the subscriber's details or they attempt to login again. Both of these methods automatically update the user information via PayPal.</li>
					<li>If there is more than one subscription option, and an existing subscriber encounters an area that is restricted to a different 'level' or group than they are affiliated with, they will be presented with a subscription 'options' page and a brief message detailing which group(s) the content is restricted to. The subscription options dropdown may not necessarily match up with the group(s) that the content is restricted to.</li>
				</ul>
		</li>
	</ul>


	<h3>General Instructions</h3>
	<ul>
		<li>Create a PayPal business account.</li>
		<li>Create API credentials for your PayPal business account. For instructions, visit <a href="https://cms.paypal.com/us/cgi-bin/?&amp;cmd=_render-content&amp;content_ID=developer/e_howto_api_NVPAPIBasics##id084DN0AK0HS" target="_blank">https://cms.paypal.com/us/cgi-bin/?&amp;cmd=_render-content&amp;content_ID=developer/e_howto_api_NVPAPIBasics##id084DN0AK0HS</a></li>
		<li>Login to your  PayPal business account, then go to <strong>My Account</strong> &gt; <strong>Profile</strong> &gt; <strong>API Access</strong> to edit your API account access info.
			<ul>
				<li>Click <strong>Add or edit API permissions</strong>, then click the<strong> Edit </strong>button and make sure the following are enabled (have a checkmark next to it)
					<ul>
						<li>SetExpressCheckout</li>
						<li>GetExpressCheckoutDetails</li>
						<li>DoExpressCheckoutPayment</li>
						<li> SetCustomerBillingAgreement </li>
						<li> GetBillingAgreementCustomerDetails </li>
						<li> CreateBillingAgreement </li>
						<li> CreateRecurringPaymentsProfile </li>
						<li> GetRecurringPaymentsProfileDetails </li>
						<li> ManageRecurringPaymentsProfileStatus </li>
						<li> BillOutstandingAmount </li>
						<li> UpdateRecurringPaymentsProfile</li>
					</ul>
				</li>
				<li>Click <strong>View  API Certificate</strong> and note your API Credentials (username, password and signature) and enter this information into the appropriate fields by editing this plugin (Site Settings &gt; Plugins tab &gt; click the Pencil icon to edit your settings)</li>
			</ul>
		</li>
		<li>Create one or more subscription options.</li>
		<li>Create a landing page that all potential subscribers can view.
			Do NOT restrict this page to any particular group(s).
			<ul>
				<li>On this 'landing page' add the <strong>muraSubscriber</strong> content object found under 'plugins' to the main content area.</li>
			</ul>
		</li>
		<li>Pretty much anywhere else on the site you can now restrict access to any or all of the subscription groups you've created.</li>
	</ul>
</div></cfoutput>