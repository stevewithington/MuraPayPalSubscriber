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

		Document:	payPalService.cfc
		Author:		Steve Withington | www.stephenwithington.com
		Modified:	2011.09.02

--->
<cfcomponent>
	<cfscript>
		variables.APIAccount	= ''; // this is the business owner email or merchantID
		variables.APIUsername 	= '';
		variables.APIPassword 	= '';
		variables.APISignature 	= '';
		variables.useSandbox 	= true;
		variables.useSDKCredentials = false; // set this to FALSE if you have your own developer credentials you wish to use for sandbox testing!!
		variables.SDKUsername 	= 'sdk-three_api1.sdk.com';
		variables.SDKPassword 	= 'QFZCWN5HZM8VBG7Q';
		variables.SDKSignature	= 'A.d9eRKfd1yVkRrtmMfCFLTqa6M9AyodL0SJkhYztxUi8W9pCXF6.4NI';
		variables.serverURL 	= 'https://api-3t.sandbox.paypal.com/nvp';
		variables.PayPalURL 	= 'https://www.sandbox.paypal.com/cgi-bin/webscr?cmd=_express-checkout&token=';
		variables.useProxy 		= false;
		variables.proxyName 	= '';
		variables.proxyPort 	= '';
		variables.version 		= '63.0'; // PayPal API Version 5.2.63 (63.0): 5-03-2010 - DON'T ALTER!!!


		// URL settings
		variables.baseURL		= getPageContext().getRequest().getScheme() & '://' & getPageContext().getRequest().getServerName();
		if ( getPageContext().getRequest().getServerPort() neq '80' and getPageContext().getRequest().getServerPort() neq '443' ) {
			variables.baseURL = variables.baseURL & ':' & getPageContext().getRequest().getServerPort();
		};
		variables.currentURI 	= getPageContext().getRequest().getRequestURI();
		if ( len(trim(getPageContext().getRequest().getQueryString())) ) {
			variables.currentQS = '?' & getPageContext().getRequest().getQueryString();
		} else {
			variables.currentQS = '';
		};
		variables.noBaseURL = variables.currentURI & variables.currentQS;
		variables.currentFullURL = variables.baseURL & variables.noBaseURL;

		// constructor
		// arguments: APIAccount, APIUsername, APIPassword, APISignature, useSandbox, useSDKCredentials, useProxy, proxyName, proxyPort 
		function init() {
			if ( ArrayLen(arguments) ) {
				setValues(argumentCollection=arguments);
			} else {
				setValues();
			};
			return this;
		};

		function getValues() { return variables; };
		function getAllValues() { return variables; };

		function setValues() {
			// if the API settings aren't specified, then use Sandbox mode with SDK credentials
			if ( not StructKeyExists(arguments, 'APIAccount') ) { arguments.APIAccount = ''; };
			if ( not StructKeyExists(arguments, 'APIUsername') ) { arguments.APIUsername = getValue('SDKUsername'); };
			if ( not StructKeyExists(arguments, 'APIPassword') ) { arguments.APIPassword = getValue('SDKPassword'); };
			if ( not StructKeyExists(arguments, 'APISignature') ) { arguments.APISignature = getValue('SDKSignature'); };
			if ( not StructKeyExists(arguments, 'useSandbox') or not IsBoolean(arguments.useSandbox) ) { arguments.useSandbox = true; };
			if ( not StructKeyExists(arguments, 'useSDKCredentials') or not IsBoolean(arguments.useSDKCredentials) ) { arguments.useSDKCredentials = true; };
			if ( not StructKeyExists(arguments, 'useProxy') or not IsBoolean(arguments.useProxy) ) { arguments.useProxy = false; };
			if ( not StructKeyExists(arguments, 'proxyName') ) { arguments.proxyName = ''; };
			if ( not StructKeyExists(arguments, 'proxyPort') ) { arguments.proxyPort = ''; };

			setValue('APIAccount', arguments.APIAccount);
			setValue('APIUsername',arguments.APIUsername);
			setValue('APIPassword',arguments.APIPassword);
			setValue('APISignature',arguments.APISignature);
			setValue('useSandbox',arguments.useSandbox);
			setValue('useSDKCredentials',arguments.useSDKCredentials);
			setValue('useProxy',arguments.useProxy);
			setValue('proxyName',arguments.proxyName);
			setValue('proxyPort',arguments.proxyPort);

			if ( getValue('useSandbox') ) {
				// SDK credentials will only work in sandbox mode!!
				if ( getValue('useSDKCredentials') ) {
					setValue('APIUsername',getValue('SDKUsername'));
					setValue('APIPassword',getValue('SDKPassword'));
					setValue('APISignature',getValue('SDKSignature'));
				};
				setValue('serverURL','https://api-3t.sandbox.paypal.com/nvp');
				setValue('PayPalURL','https://www.sandbox.paypal.com/cgi-bin/webscr?cmd=_express-checkout&token=');
			} else {
				setValue('serverURL','https://api-3t.paypal.com/nvp');
				setValue('PayPalURL','https://www.paypal.com/cgi-bin/webscr?cmd=_express-checkout&token=');
			};
		};
		
		function getValue(key) {
			if ( StructKeyExists(variables, arguments.key) ) {
				return variables[arguments.key];
			} else {
				return '';
			};
		};

		function setValue(key,value) {
			if ( StructKeyExists(variables, arguments.key) ) {
				variables[arguments.key] = arguments.value;
			};
		};

		// getNVPResponse()
		// parse server response
		function getNVPResponse(nvpString) {
			var local = {};
			local.responseStruct = {};
			local.keyValStruct = {};
			local.key = '';
			local.keys = '';
			local.value = '';
			local.values = '';
			local.tempVal = '';
			local.tempValue = '';
			local.currentValue = '';
			local.nvpArray = [];
			local.keyArray = [];
			local.valueArray = [];
			local.count = 1;
			local.lennvp = 0;

			for ( local.i=1; local.i lte len(nvpString); local.i++ ) {
				local.lennvp++;
				local.index = 1;
				if ( mid(nvpString, local.i, 1) neq '&' ) {
					local.tempVal = local.tempVal & mid(nvpString, local.i, 1);
				};
				if ( mid(nvpString, local.i, 1) eq '&' or local.lennvp eq len(nvpString) ) {
					local.nvpArray[local.count] = trim(local.tempVal);
					local.count++;
					local.tempVal = '';
				};
			};

			for ( local.x=1; local.x lte ArrayLen(local.nvpArray); local.x++ ) {
				local.currentValue = local.nvpArray[local.x];
				for ( local.y=1; local.y lte len(local.currentValue); local.y++ ) {
					if ( mid(local.currentValue, local.y, 1) eq '=' ) {
						break;
					} else {
						local.tempValue = local.tempValue & mid(local.currentValue, local.y, 1);
					};
				};
				local.keyArray[local.index] = trim(local.tempValue);
				local.index++;
				local.tempValue = '';
			};
			
			for ( local.z=1; local.z lte ArrayLen(local.nvpArray); local.z++ ) {
				local.vals = local.nvpArray[local.z];
				local.key = local.keyArray[local.z];
				local.value = RemoveChars(local.vals, 1, len(local.key)+1);
				local.valueArray[local.z] = local.value;
				local.temp = StructInsert(local.responseStruct, trim(local.key), trim(local.value));
			};

			return local.responseStruct;
		};

		function doNVPResponse(requestData) {
			var local = {};
			local.requestData = getCredentials();
			if ( StructKeyExists(arguments, 'requestData') ) {
				StructAppend(local.requestData, arguments.requestData);
			};
			try {
				local.response = doHttpPost(
					requestData = local.requestData
					, serverURL = getValue('serverURL')
					, proxyName = getValue('proxyName')
					, proxyPort = getValue('proxyPort')
					, useProxy = getValue('useProxy')
				);
				local.responseStruct = getNVPResponse(URLDecode(local.response));
				//session.paypalResponse = local.responseStruct;
				//session.paypalRequestData = local.requestData;
				//session.paypalURL = variables.PayPalURL;
				//session.serverURL = variables.serverURL;
			} catch (any e) {
				local.responseStruct = {};
				local.responseStruct.error = 'fromClient';
				local.responseStruct.errorType =  e.type;
				local.responseStruct.errorMessage = e.message;
				//session.paypalResponse = local.responseStruct;
			};
			return local.responseStruct;
		};

		function getCredentials() {
			var local = StructNew();
			local.requestData = StructNew();
			local.requestData.USER = getValue('APIusername');
			local.requestData.PWD = getValue('APIpassword');
			local.requestData.SIGNATURE = getValue('APIsignature');
			//local.requestData.SUBJECT = getValue('UNIPAYSUBJECT');
			local.requestData.VERSION = getValue('version');
			return local.requestData;
		};
		
		function isAckSuccess(responseStruct) {
			var local = {};
			if ( StructKeyExists(arguments, 'responseStruct') and StructKeyExists(arguments.responseStruct, 'ACK') ) {
				if ( arguments.responseStruct.ACK eq 'Success' ) {
					return true;
				} else if ( arguments.responseStruct.ACK eq 'SuccessWithWarning' ) {
					return true;
				} else if ( arguments.responseStruct.ACK eq 'Failure' ) {
					return false;
				} else if ( arguments.responseStruct.ACK eq 'FailureWithWarning' ) {
					return false;
				} else {
					// the response should be one of the four previous, so anything else would be bogus
					return false;
				};
			} else {
				// bad responseStruct
				return false;
			};		
		};

		// displayText()
		function displayText(responseStruct) {
			var local = {};
			local.key = '';
			for ( local.key in arguments.responseStruct ) {
				WriteOutput('<tr><td>' & local.key & ':</td><td>' & arguments.responseStruct[local.key] & '</td></tr>');
			};
		};

		// convertPayPalTimestamp()
		function convertPayPalTimestamp(t) {
			var local = {};
			//local.tempdate = '2010-05-28T16:17:58Z';
			local.tempdate = t;
			local.tempdate = ReReplace(local.tempdate, 'T', ' ');
			local.tempdate = ReReplace(local.tempdate, 'Z', ' ');
			if ( IsDate(local.tempdate) ) {
				local.convertedDate = DateConvert('utc2local', local.tempdate);
			} else {
				local.convertedDate = '';
			};
			return local.convertedDate;
		};

		// makePayPalTimestamp()
		function makePayPalTimestamp(t) {
			var local = {};

			if ( not IsDefined('arguments.t') ) {
				local.tempdate = now();
			} else {
				local.tempdate = t;
			};

			local.utc = DateConvert('local2utc', local.tempdate);
			local.d = DateFormat(local.utc, 'yyyy-mm-dd');
			local.t = TimeFormat(local.utc, 'HH:mm:ss');
			local.convertedDate = local.d & 'T' & local.t & 'Z';
			return local.convertedDate;
		};
	</cfscript>

	<cffunction name="doHttpPost" access="public" returntype="string">
		<cfargument name="requestData" type="struct" required="yes" />
		<cfargument name="serverURL" type="string" required="yes" />
		<cfargument name="useProxy" type="boolean" required="yes" />
		<cfargument name="proxyName" type="string" required="no" />
		<cfargument name="proxyPort" type="string" required="no" />
		<cfif useProxy>
			<cfhttp url="#serverURL#" method="POST" proxyserver="#proxyName#" proxyport="#proxyPort#">
			  <cfloop collection="#requestData#" item="key">
				  <cfhttpparam name="#key#" value="#requestData[key]#" type="FormField" encoded="yes" />
			  </cfloop>
			</cfhttp>
		<cfelse>
			<cfhttp url="#serverURL#" method="POST">
			  <cfloop collection="#requestData#" item="key">
				  <cfhttpparam name="#key#" value="#requestData[key]#" type="FormField" encoded="yes" />
			  </cfloop>
			</cfhttp>
		</cfif>
		<cfreturn cfhttp.FileContent />
	</cffunction>

	<cffunction name="dump">
		<cfargument name="var" required="true" />
		<cfargument name="abort" required="false" default="false" />
		<cfargument name="label" required="false" default="" />
		<cfdump var="#arguments.var#" label="#arguments.label#" />
		<cfif arguments.abort>
			<cfabort />
		</cfif>
	</cffunction>

	<cffunction name="redirect">
		<cfargument name="url" required="true" />
		<cflocation url="#arguments.url#" addtoken="false" />
	</cffunction>

</cfcomponent>