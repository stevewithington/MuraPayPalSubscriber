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

		Document:	/admin/layouts/default.cfm
		Author:		Steve Withington | www.stephenwithington.com
		Modified:	2011.09.02

--->

	<cfscript>
		rc.lib.htmlHead('
				<link rel="stylesheet" type="text/css" href="#rc.$.globalConfig('context')#/plugins/#rc.pluginConfig.getDirectory()#/assets/css/common.css" />
				<link rel="stylesheet" type="text/css" href="#rc.$.globalConfig('context')#/plugins/#rc.pluginConfig.getDirectory()#/assets/css/admin.css" />
		');
	</cfscript>
</cfsilent>
<cfparam name="rc.compactDisplay" default="false">
<cfsavecontent variable="local.newBody">
	<cfoutput>	
		<div id="outerWrapper">
			<div id="pageTitle"><h2>#rc.pluginConfig.getPackage()#&trade;</h2></div>
			<div id="navWrapper">
				<ul>
					<li class="first<cfif rc.action eq 'admin:main.default'> active</cfif>"><a href="#buildURL('admin:main')#">Subscription Plans</a></li>
					<li<cfif rc.action eq 'admin:subscribers.default'> class="active"</cfif>><a href="#buildURL('admin:subscribers')#">Subscribers</a></li>
					<li class="last<cfif rc.action eq 'admin:instructions.default'> active</cfif>"><a href="#buildURL('admin:instructions')#">Instructions</a></li>
				</ul>
			</div>
			<div id="subContent">
				<!--- display errors, if any --->
				<cfif StructKeyExists(rc, 'errors') and IsArray(rc.errors) and ArrayLen(rc.errors)>
					<div class="subscriberAdminContent">
						<h4 class="red">Please note the following message<cfif ArrayLen(rc.errors) gt 1>s</cfif>:</h4>
						<ul>
							<cfloop from="1" to="#ArrayLen(rc.errors)#" index="local.e">
								<li>#rc.errors[local.e]#</li>
							</cfloop>
						</ul>
					</div>
				</cfif>
				#body#
				<div id="subscriberFooter">
					<a href="http://www.getmura.com/index.cfm/app-store/plugins/" target="_blank">Powered by <strong>#rc.pluginConfig.getPackage()#&trade;</strong></a> 
					| <cfif rc.payPalService.getValue('useSandbox')><strong>Sandbox is ENABLED</strong><cfelse><span class="green">LIVE!</span></cfif>
				</div>
			</div>
		</div>
	</cfoutput>
</cfsavecontent>
<cfoutput>#application.pluginManager.renderAdminTemplate(body=local.newBody,pageTitle=rc.pc.getName(),compactDisplay=rc.compactDisplay)#</cfoutput>