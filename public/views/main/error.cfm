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

		Document:	error.cfm
		Author:		Steve Withington | www.stephenwithington.com
		Modified:	2011.09.02

--->
	<cfsavecontent variable="local.clientMessage">
		<h4 class="red">An Error Has Occurred.</h4>
		<p>We're sorry &hellip; but an unexpected error occurred while processing your transaction. You can either <a href="javascript:history.go(-1);">go back and try to order your subscription again</a> or wait and give our Web Response Team some time to figure out what in the heck just happened. It's entirely up to you.</p>
	</cfsavecontent>
</cfsilent>
<cfoutput>
	#local.clientMessage#

	<!--- if in sandbox mode and ?debug=1 --->
	<cfif $.payPalService.getValue('useSandbox') and StructKeyExists(rc, 'debug') and rc.debug>
		<cfif StructKeyExists(rc, 'responseStruct')>
			<cfdump var="#rc.responseStruct#" label="rc.responseStruct" />
		</cfif>
		<cfif StructKeyExists(rc, 'requestData')>
			<cfdump var="#rc.requestData#" label="rc.requestData" />
		</cfif>
		<cfif StructKeyExists(rc, 'muraSubscriber')>
			<cfdump var="#session.muraSubscriber#" label="session.muraSubscriber" />
		</cfif>
	</cfif>

</cfoutput>