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

		Document:	review.cfm
		Author:		Steve Withington | www.stephenwithington.com
		Modified:	2011.09.02

--->

	<cfsavecontent variable="local.clientMessage">
		<h3>Review Your Order</h3>
		<cfif len(trim(rc.pluginConfig.getSetting('messageReview')))>
			<cfscript>
				local.txt = rc.lib.HTMLSafeText(rc.pluginConfig.getSetting('messageReview'));
				local.txt = rc.lib.XHTMLParagraphFormat(local.txt);
			</cfscript>
			<cfoutput>#local.txt#</cfoutput>
		<cfelse>
			<p>Select any of the available subscription options from the dropdown below.</p>
		</cfif>
	</cfsavecontent>

</cfsilent>
<cfoutput>
	<cfif IsDefined('session.muraSubscriber.setExpressCheckoutResponse.TOKEN')>
		#local.clientMessage#
		<table>
			<tr>
				<th>Description</th>
				<th>Unit Price</th>
				<th>Quantity</th>
				<th>Amount</th>
				<th>&nbsp;</th>
			</tr>
			<tr>
				<td>#session.muraSubscriber.getExpressCheckoutResponse.L_PAYMENTREQUEST_0_DESC0#</td>
				<td align="right">#DollarFormat(session.muraSubscriber.getExpressCheckoutResponse.L_PAYMENTREQUEST_0_AMT0)#</td>
				<td align="center">#session.muraSubscriber.getExpressCheckoutResponse.L_PAYMENTREQUEST_0_QTY0#</td>
				<td align="right">#DollarFormat(session.muraSubscriber.getExpressCheckoutResponse.PAYMENTREQUEST_0_ITEMAMT)#</td>
				<td>&nbsp;</td>
			</tr>
			<tr>
				<td colspan="3" align="right"><strong>Total:</strong></td>
				<td align="right"><strong>#DollarFormat(session.muraSubscriber.getExpressCheckoutResponse.PAYMENTREQUEST_0_AMT)#</strong></td>
				<td><strong>#session.muraSubscriber.getExpressCheckoutResponse.PAYMENTREQUEST_0_CURRENCYCODE#</strong></td>
			</tr>
		</table>
			<form method="post">			
			<p><input type="submit" value=" Yes, everything is correct! Pay Now &gt;&gt; " /></p>
			<input type="hidden" name="action" value="public:main.doexpresscheckoutpayment" />
		</form>
	<cfelse>
		<p>Hmm, you must've been sent here by accident. We're you trying to <a href="#rc.lib.getValue('currentURI')#?action=public:main.options">order a subscription</a>?</p>
	</cfif>
</cfoutput>