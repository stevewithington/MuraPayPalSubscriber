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

		Document:	default.cfm
		Author:		Steve Withington | www.stephenwithington.com
		Modified:	2011.09.02

--->

	<cfparam name="rc.profilestatus" default="" />
	<cfparam name="rc.cancelled" default="false" />
	<cfparam name="rc.suspended" default="false" />
	<cfparam name="rc.reactivated" default="false" />

	<cfset local.gridName = 'gridSubscribers' />
	<cfset local.maxRecordsPerPage = 25 />

	<cfajaximport tags="cfform, cfwindow, cfgrid">
	<cfsavecontent variable="head">
		<!--- assumes ColdFusion mapping to CFIDE exists!! --->
		<script src="/CFIDE/scripts/ajax/ext/package/date.js" type="text/javascript"></script>
		<script type="text/javascript">
			init = function() {
				grid = ColdFusion.Grid.getGridObject('<cfoutput>#local.gridName#</cfoutput>');
				cm = grid.getColumnModel();
				// cfgridcolumn starts at 0
				cm.setRenderer(3, Ext.util.Format.dateRenderer('Y-m-d'));
				cm.setRenderer(4, Ext.util.Format.dateRenderer('Y-m-d'));
				cm.setRenderer(5, Ext.util.Format.dateRenderer('M j, Y, g:i a'));
				//cm.setRenderer(6, Ext.util.Format.usMoney);				
				grid.reconfigure(grid.getDataSource(), cm);
			};
		</script>
	</cfsavecontent>
	<cfhtmlhead text="#head#" />
	<cfset ajaxOnLoad('init') />

</cfsilent>
<cfoutput>
	<h3>Subscribers</h3>
	<cfif len(trim(rc.profilestatus))>
		<ul id="navTask">
			<li><a href="#buildURL('admin:subscribers')#">View All</a></li>
		</ul>
	<cfelse>
		<!---<p>Filter 'Status' by click on the status name (i.e., Active, Suspended, Cancelled).</p>--->
	</cfif>

	<!--- messaging --->
	<cfif rc.cancelled>
		<h4 class="error">Subscriber Cancelled</h4>
	<cfelseif rc.reactivated>
		<h4 class="success">Subscriber Reactivated</h4>
	<cfelseif rc.suspended>
		<h4 class="error">Subscriber Suspended</h4>
	</cfif>

	<cfif rc.rsSubscribers.recordcount>	
		<cfscript>
			// debug - if we can connect and dump, cfGrid will be able to work
			//local.newRS = CreateObject('component','#rc.pluginConfig.getPackage()#.admin.controllers.subscribers').getMuraSubscribers(profileStatus=rc.profilestatus);
			//rc.lib.dump(local.newRS,1);
			// if grid does NOT appear, make sure a virtual mapping has been created for CFIDE (typically under '/inetpub/wwwroot/CFIDE/'

			if ( rc.rsSubscribers.recordcount gt local.maxRecordsPerPage ) {
				local.pageSize = local.maxRecordsPerPage;
			} else {
				local.pageSize = rc.rsSubscribers.recordcount;
			};

			local.args = StructNew();
			local.args.name = local.gridName;
			local.args.format = 'html';
			local.args.striperows = true;
			local.args.striperowcolor = '##efefef';
			local.args.selectonload = false;
			local.args.colheaderbold = true;
			local.args.bind = 'cfc:#rc.pluginConfig.getPackage()#.admin.controllers.subscribers.getMuraSubscribers(page={cfGridPage},pageSize={cfGridPageSize},gridSortColumn={cfGridSortColumn},gridSortDirection={cfGridSortDirection},profilestatus="#rc.profilestatus#")';
			local.args.bindonload = true;
			local.args.pageSize = local.pageSize;
			local.args.width = 826;
		</cfscript>

		<div id="gridWrapper">
			<cfform>
				<cfgrid attributeCollection="#local.args#">
					<cfgridcolumn name="lastNameLink" display="yes" width="110" header="Last Name" />
					<cfgridcolumn name="Fname" display="yes" width="80" header="First Name" />
					<cfgridcolumn name="subscriptionPlan" display="yes" width="175" header="Subscription Plan" />
					<cfgridcolumn name="profileStartDate" display="yes" width="100" header="Start Date" />
					<cfgridcolumn name="nextBillingDate" display="yes" width="100" header="Next Billing Date" />
					<cfgridcolumn name="LastUpdate" display="yes" width="150" header="Last Update" />
					<cfgridcolumn name="profileStatusLink" display="yes" width="65" header="Status" />
					<cfgridcolumn name="detailsLink" display="yes" width="30" header="" />
				</cfgrid>
			</cfform>
		</div>
		<p>Total <cfif len(trim(rc.profilestatus))><span class="red">#uCase(rc.profilestatus)#</span></cfif> records: #rc.rsSubscribers.recordcount#</p>
	<cfelse>
		<p><em>Either no subscribers exist yet or there are no subscribers that match your request.</em></p>
	</cfif>
</cfoutput>