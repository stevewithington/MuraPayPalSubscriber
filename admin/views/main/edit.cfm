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

		Document:	edit.cfm
		Author:		Steve Withington | www.stephenwithington.com
		Modified:	2011.09.02

--->
<cfoutput>
	<h3><cfif rc.add>Add New<cfelse>Update</cfif> Subscription Plan</h3>
	<ul id="navTask">
		<li><a href="#buildURL('admin:main')#">Cancel</a></li>
	</ul>
	<form method="post" id="frmEdit" name="frmEdit">
		<dl class="oneColumn">
			<cfif StructKeyExists(rc, 'errors') and IsArray(rc.errors) and ArrayLen(rc.errors)>
				<dt><label for="errors" class="red">Please Correct the Following Error<cfif ArrayLen(rc.errors) gt 1>s</cfif></label></dt>
				<cfloop from="1" to="#ArrayLen(rc.errors)#" index="local.e">
					<dd>&bull; #rc.errors[local.e]#</dd>
				</cfloop>
			</cfif>
			<dt>
				<label for="groupName"><a href="javascript:void(0);" class="tooltip">Subscription (Group) Name<span>What should people refer to this subscription plan as? (i.e., Weekly Subscription Plan, Basic Plan, etc.)</span></a></label>
			</dt>
			<dd><input type="text" name="groupName" id="groupName" value="#rc.groupName#" /></dd>
			
			<dt><label for="itemAmt"><a href="javascript:void(0);" class="tooltip">Billing Amount <em>(per billing cycle)</em><span>Please enter the dollar amount that should be charged for each billing cycle.</span></a></label></dt>
			<dd><input type="text" name="subscriptionBillingCycleAmount" id="subscriptionBillingCycleAmount" value="#rc.subscriptionBillingCycleAmount#" /> USD</dd>
			
			<dt><label for="subscriptionBillingCycleNumber"><a href="javascript:void(0);" class="tooltip">Billing Cycle<span>		
			These fields specify the total subscription duration. Allowable values: days; allowable range is 1 to 90, weeks; allowable range is 1 to 52, months; allowable range is 1 to 24, years; allowable range is 1 to 5</span></a></label></dt>
			<dd><select name="subscriptionBillingCycleNumber">
				<cfloop from="1" to="90" step="1" index="local.idx"><option value="#local.idx#"<cfif rc.subscriptionBillingCycleNumber eq local.idx> selected="selected"</cfif>>#local.idx#</option></cfloop>
			</select>
			<select id="subscriptionBillingCyclePeriod" name="subscriptionBillingCyclePeriod">
				<option value="D"<cfif rc.subscriptionBillingCyclePeriod eq 'D'> selected="selected"</cfif>>day(s)</option>
				<option value="W"<cfif rc.subscriptionBillingCyclePeriod eq 'W'> selected="selected"</cfif>>week(s)</option>
				<option value="M"<cfif rc.subscriptionBillingCyclePeriod eq 'M'> selected="selected"</cfif>>month(s)</option>
				<option value="Y"<cfif rc.subscriptionBillingCyclePeriod eq 'Y'> selected="selected"</cfif>>year(s)</option>
			</select></dd>

			<dt><label for="InActive">Is Active</label></dt>
			<dd>
				<label for="InActive1"><input type="radio" id="InActive1" name="InActive" value="1"<cfif rc.InActive>checked="checked"</cfif> /> No</label>
				<label for="InActive0"><input type="radio" id="InActive0" name="InActive" value="0"<cfif not rc.InActive>checked="checked"</cfif> /> Yes</label>
			</dd>		
		</dl>
		<p><input type="submit" value="Submit" /></p>
		<input type="hidden" name="type" value="1" />
		<input type="hidden" name="subType" value="#rc.pluginConfig.getPackage()#" />
		<input type="hidden" name="isPublic" value="1" />
		<input type="hidden" name="add" value="#rc.add#" />
		<input type="hidden" name="update" value="#rc.update#" />
		<input type="hidden" name="action" value="#getFullyQualifiedAction('admin:main.submit')#" />
	</form>
	<script type="text/javascript">
		document.forms['frmEdit'].elements['groupName'].focus();
	</script>
</cfoutput>