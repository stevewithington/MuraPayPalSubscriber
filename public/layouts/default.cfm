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

		Document:	/public/layouts/default.cfm
		Author:		Steve Withington | www.stephenwithington.com
		Modified:	2011.09.02

--->

	<cfscript>
		request.layout = false;
		rc.lib.htmlHead('
				<link rel="stylesheet" type="text/css" href="#rc.$.globalConfig('context')#/plugins/#rc.pluginConfig.getDirectory()#/assets/css/common.css" />
				<link rel="stylesheet" type="text/css" href="#rc.$.globalConfig('context')#/plugins/#rc.pluginConfig.getDirectory()#/assets/css/public.css" />
		');
	</cfscript>
</cfsilent>
<cfoutput>
	<div id="subscriberBody">
		<!--- display errors, if any --->
		<cfif StructKeyExists(rc, 'errors') and IsArray(rc.errors) and ArrayLen(rc.errors)>
			<h4 class="red">Please note the following message<cfif ArrayLen(rc.errors) gt 1>s</cfif>:</h4>
			<ul>
				<cfloop from="1" to="#ArrayLen(rc.errors)#" index="local.e">
					<li>#rc.errors[local.e]#</li>
				</cfloop>
			</ul>
		</cfif>
		#body#
	</div>
	<cfif StructKeyExists(rc, 'nav')>
		<div id="subscriberFooter">#rc.nav#</div>
	</cfif>	
</cfoutput>