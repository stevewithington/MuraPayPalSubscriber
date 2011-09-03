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

		Document:	receipt.cfm
		Author:		Steve Withington | www.stephenwithington.com
		Modified:	2011.09.02

--->

	<cfsavecontent variable="local.clientMessage">
		<h3>Thank You For Your Order!</h3>
		<cfif len(trim(rc.pluginConfig.getSetting('messageReceipt')))>
			<cfscript>
				local.txt = rc.lib.HTMLSafeText(rc.pluginConfig.getSetting('messageReceipt'));
				local.txt = rc.lib.XHTMLParagraphFormat(local.txt);
			</cfscript>
			<cfoutput>#local.txt#</cfoutput>
		<cfelse>
			<p>A copy of your order has been emailed to you by <a href="http://www.paypal.com" target="_blank">PayPal</a>.</p>
		</cfif>
	</cfsavecontent>

</cfsilent>
<cfoutput>
	<cfif IsDefined('session.muraSubscriber.DOEXPRESSCHECKOUTRESPONSE.PAYMENTINFO_0_TRANSACTIONID')>
		#local.clientMessage#
		<table>
			<tr>
				<th>Sold To</th>
				<th>Subscription Start Date</th>
				<th>Transaction ID</th>
				<!---<th>Profile ID</th>--->
			</tr>
			<tr>
				<td>
					<p><strong>#session.muraSubscriber.profile.paypalResponse.SUBSCRIBERNAME#</strong><br />
		#session.muraSubscriber.profile.paypalResponse.SHIPTOSTREET#<br />
		#session.muraSubscriber.profile.paypalResponse.SHIPTOCITY#<br />
		#session.muraSubscriber.profile.paypalResponse.SHIPTOSTATE#  #session.muraSubscriber.profile.paypalResponse.SHIPTOZIP#</p>
				</td>
				<td>
					<cfscript>
						local.profileStartDate = session.muraSubscriber.profile.paypalResponse.PROFILESTARTDATE;
						local.profileStartDate = rc.lib.convertPayPalTimeStamp(local.profileStartDate);
						local.profileStartDate = DateFormat(local.profileStartDate, 'mmmm d, yyyy');
					</cfscript>
					<p>#local.profileStartDate#</p>
				</td>
				<td>#session.muraSubscriber.DOEXPRESSCHECKOUTRESPONSE.PAYMENTINFO_0_TRANSACTIONID#</td>
				<!---<td>#session.muraSubscriber.profile.paypalResponse.PROFILEID#</td>--->
			</tr>
		</table>
		
		<table>
			<tr>
				<th>Description</th>
				<th>Unit Price</th>
				<th>Quantity</th>
				<th>Amount</th>
				<th>&nbsp;</th>
			</tr>
			<tr>
				<td>#session.muraSubscriber.GETEXPRESSCHECKOUTRESPONSE.L_PAYMENTREQUEST_0_DESC0#</td>
				<td align="right">#DollarFormat(session.muraSubscriber.GETEXPRESSCHECKOUTRESPONSE.L_PAYMENTREQUEST_0_AMT0)#</td>
				<td align="center">#session.muraSubscriber.GETEXPRESSCHECKOUTRESPONSE.L_PAYMENTREQUEST_0_QTY0#</td>
				<td align="right">#DollarFormat(session.muraSubscriber.GETEXPRESSCHECKOUTRESPONSE.PAYMENTREQUEST_0_ITEMAMT)#</td>
				<td>&nbsp;</td>
			</tr>
			<tr>
				<td colspan="3" align="right"><strong>Total:</strong></td>
				<td align="right"><strong>#DollarFormat(session.muraSubscriber.GETEXPRESSCHECKOUTRESPONSE.PAYMENTREQUEST_0_AMT)#</strong></td>
				<td><strong>#session.muraSubscriber.GETEXPRESSCHECKOUTRESPONSE.PAYMENTREQUEST_0_CURRENCYCODE#</strong></td>
			</tr>
		</table>
		<!--- LINKS: print / continue --->
		<p><strong><a href="javascript:void(0);" onclick="javascript:window.print();">Print Receipt</a>&nbsp;&nbsp;|&nbsp;&nbsp;<a href="#rc.lib.getValue('currentURI')#?action=public:main.continue">Continue</a></strong></p>
	<cfelse>
		<p>Hmm, you must've been sent here by accident. We're you trying to <a href="#rc.lib.getValue('currentURI')#?action=public:main.options">order a subscription</a>?</p>
	</cfif>
</cfoutput>