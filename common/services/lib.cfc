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

		Document:	lib.cfc
		Author:		Steve Withington | www.stephenwithington.com
		Modified:	2010.07.01

--->
<cfcomponent>
	<cfscript>
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

		// CONSTRUCTOR
		function init() {
			return this;
		};

		// GENERICS
		function getAllValues() { 
			return variables; 
		};

		function getValue(key) {
			if ( StructKeyExists(variables, arguments.key) ) {
				return variables[arguments.key];
			} else {
				return '';
			};
		};

		function setValue(key,value) {
			variables[arguments.key] = arguments.value;
		};

		// URL
		function getBaseURL() {
			return variables.baseURL;
		};

		function getCurrentURI() {
			return variables.currentURI;
		};
		
		function getCurrentQS() {
			return variables.currentQS;
		};
		
		function getNoBaseURL() {
			return variables.noBaseURL;
		};
		
		function getCurrentFullURL() {
			return variables.currentFullURL;
		};

		// TIME

		// convertPayPalTimestamp()
		function convertPayPalTimeStamp(t) {
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

		// convertPayPalTimestamp()
		function makePayPalTimeStamp(t) {
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

		// DST START
		function getDaylightSavingTimeStart() {
			var TheYear=Year(Now());
			if (ArrayLen(arguments)) { TheYear = arguments[1]; };
			//US Congress changed it for 2007 (may switch back) from first Sunday in April to Second Sunday in March 
			if (TheYear lt 2007) {
				return CreateDate(TheYear,4,GetNthOccOfDayInMonth(1,1,4,TheYear));
			} else {
				return CreateDate(TheYear,3,GetNthOccOfDayInMonth(2,1,3,TheYear));
			};
		};

		// DST END
		function getDaylightSavingTimeEnd() {
			var TheYear=Year(Now());
			if (ArrayLen(Arguments)) { TheYear = Arguments[1]; };
			//US Congress changed it for 2007 (may switch back) from last Sunday in October to First Sunday in November 
			if ( TheYear lt 2007 ) { 
				return CreateDate(TheYear, 10, GetLastOccOfDayInMonth(1,10,TheYear)); 
			} else {
				return CreateDate(TheYear, 11, GetNthOccOfDayInMonth(1,1,11,TheYear));
			};
		};



		// STRINGS

		function XHTMLParagraphFormat(str) {
			var attributeString = '';
			var returnValue = '';
			if(ArrayLen(arguments) GTE 2) { attributeString = ' ' & arguments[2]; };
			if(Len(Trim(arguments.str))) {
				returnValue = '<p' & attributeString & '>' & Replace(arguments.str, Chr(13) & Chr(10), '</p>' & Chr(13) & Chr(10) & '<p' & attributeString & '>', 'ALL') & '</p>';
			};
			return returnValue;
		};

		function StripBlock(strString,strFirstChar,strLastChar) {
			// Special Chars - Don't include ] (end-bracket) since it must be the
			// first character within brackets [ ] in the regular expression
			var strSpecialChars = "+*?.[^$(){}|\&##-";
			// Default to replace all blocks in string unless they passed a scope
			var strScope = "ALL"; 
			if ( ArrayLen(Arguments) gt 3 ) { strScope = Arguments[4]; };
			// Escape the start and end chars if they're special
			if ( FindNoCase(strFirstChar,strSpecialChars) ) { strFirstChar = "\" & strFirstChar; };
			if (FindNoCase(strLastChar,strSpecialChars)) { strLastChar = "\" & strLastChar; };
			return REReplaceNoCase(strString, strFirstChar & "[^" & strLastChar & "]*" & strLastChar, "", "#strScope#");
		};

		function xmlSafeText(txt) {
			var replaced = '';
			var i = '';
			var str = XmlFormat(txt);
			var chars = REMatch('[^[:ascii:]]',str);
			for ( i=1; i lte ArrayLen(chars); i++ ) {
				if ( not ListFind(replaced, chars[i]) ) {
					str = Replace(str, chars[i], '&##' & asc(chars[i]) & ';', 'ALL');
					replaced = ListAppend(replaced, chars[i]);
				};
			};
			return str;
		};

		function stripHTML(str) {
			str = reReplaceNoCase(str, "<.*?>","","all");
			//get partial html in front
			str = reReplaceNoCase(str, "^.*?>","");
			//get partial html at end
			str = reReplaceNoCase(str, "<.*$","");
			return str;
		};

		function HTMLSafeText(txt) {
			var badChars = "&,"",#Chr(161)#,#Chr(162)#,#Chr(163)#,#Chr(164)#,#Chr(165)#,#Chr(166)#,#Chr(167)#,#Chr(168)#,#Chr(169)#,#Chr(170)#,#Chr(171)#,#Chr(172)#,#Chr(173)#,#Chr(174)#,#Chr(175)#,#Chr(176)#,#Chr(177)#,#Chr(178)#,#Chr(179)#,#Chr(180)#,#Chr(181)#,#Chr(182)#,#Chr(183)#,#Chr(184)#,#Chr(185)#,#Chr(186)#,#Chr(187)#,#Chr(188)#,#Chr(189)#,#Chr(190)#,#Chr(191)#,#Chr(215)#,#Chr(247)#,#Chr(192)#,#Chr(193)#,#Chr(194)#,#Chr(195)#,#Chr(196)#,#Chr(197)#,#Chr(198)#,#Chr(199)#,#Chr(200)#,#Chr(201)#,#Chr(202)#,#Chr(203)#,#Chr(204)#,#Chr(205)#,#Chr(206)#,#Chr(207)#,#Chr(208)#,#Chr(209)#,#Chr(210)#,#Chr(211)#,#Chr(212)#,#Chr(213)#,#Chr(214)#,#Chr(216)#,#Chr(217)#,#Chr(218)#,#Chr(219)#,#Chr(220)#,#Chr(221)#,#Chr(222)#,#Chr(223)#,#Chr(224)#,#Chr(225)#,#Chr(226)#,#Chr(227)#,#Chr(228)#,#Chr(229)#,#Chr(230)#,#Chr(231)#,#Chr(232)#,#Chr(233)#,#Chr(234)#,#Chr(235)#,#Chr(236)#,#Chr(237)#,#Chr(238)#,#Chr(239)#,#Chr(240)#,#Chr(241)#,#Chr(242)#,#Chr(243)#,#Chr(244)#,#Chr(245)#,#Chr(246)#,#Chr(248)#,#Chr(249)#,#Chr(250)#,#Chr(251)#,#Chr(252)#,#Chr(253)#,#Chr(254)#,#Chr(255)#";
			var goodChars = "&amp;,&quot;,&iexcl;,&cent;,&pound;,&curren;,&yen;,&brvbar;,&sect;,&uml;,&copy;,&ordf;,&laquo;,&not;,&shy;,&reg;,&macr;,&deg;,&plusmn;,&sup2;,&sup3;,&acute;,&micro;,&para;,&middot;,&cedil;,&sup1;,&ordm;,&raquo;,&frac14;,&frac12;,&frac34;,&iquest;,&times;,&divide;,&Agrave;,&Aacute;,&Acirc;,&Atilde;,&Auml;,&Aring;,&AElig;,&Ccedil;,&Egrave;,&Eacute;,&Ecirc;,&Euml;,&Igrave;,&Iacute;,&Icirc;,&Iuml;,&ETH;,&Ntilde;,&Ograve;,&Oacute;,&Ocirc;,&Otilde;,&Ouml;,&Oslash;,&Ugrave;,&Uacute;,&Ucirc;,&Uuml;,&Yacute;,&THORN;,&szlig;,&agrave;,&aacute;,&acirc;,&atilde;,&auml;,&aring;,&aelig;,&ccedil;,&egrave;,&eacute;,&ecirc;,&euml;,&igrave;,&iacute;,&icirc;,&iuml;,&eth;,&ntilde;,&ograve;,&oacute;,&ocirc;,&otilde;,&ouml;,&oslash;,&ugrave;,&uacute;,&ucirc;,&uuml;,&yacute;,&thorn;,&yuml;,&##338;,&##339;,&##352;,&##353;,&##376;,&##710;,&##8211;,&##8212;,&##8216;,&##8217;,&##8218;,&##8220;,&##8221;,&##8222;,&##8224;,&##8225;,&##8240;,&##8249;,&##8250;,&##8364;,<sup><small>TM</small></sup>,&bull;";

			badChars = "#badChars#,#Chr(338)#,#Chr(339)#,#Chr(352)#,#Chr(353)#,#Chr(376)#,#Chr(710)#,#Chr(8211)#,#Chr(8212)#,#Chr(8216)#,#Chr(8217)#,#Chr(8218)#,#Chr(8220)#,#Chr(8221)#,#Chr(8222)#,#Chr(8224)#,#Chr(8225)#,#Chr(8240)#,#Chr(8249)#,#Chr(8250)#,#Chr(8364)#,#Chr(8482)#,#Chr(8226)#";

			if ( not Len(Trim(txt)) ) { return txt; };
			return ReplaceList(txt, badChars, goodChars);		
		};

		function safetext(text) {
			//default mode is "escape"
			var mode = "escape";
			//the things to strip out (badTags are HTML tags to strip and badEvents are intra-tag stuff to kill)
			//you can change this list to suit your needs
			var badTags = "SCRIPT,OBJECT,APPLET,EMBED,FORM,LAYER,ILAYER,FRAME,IFRAME,FRAMESET,PARAM,META";
			var badEvents = "onClick,onDblClick,onKeyDown,onKeyPress,onKeyUp,onMouseDown,onMouseOut,onMouseUp,onMouseOver,onBlur,onChange,onFocus,onSelect,javascript:";
			var stripperRE = "";
			//set up variable to parse and while we're at it trim white space 
			var theText = trim(text);
			//find the first open bracket to start parsing
			var obracket = find("<",theText);        
			//var for badTag
			var badTag = "";
			//var for the next start in the parse loop
			var nextStart = "";
			//if there is more than one argument and the second argument is boolean TRUE, we are stripping
			if(arraylen(arguments) GT 1 AND isBoolean(arguments[2]) AND arguments[2]) { mode = "strip"; };
			if(arraylen(arguments) GT 2 and len(arguments[3])) { badTags = arguments[3]; };
			if(arraylen(arguments) GT 3 and len(arguments[4])) { badEvents = arguments[4]; };
			//the regular expression used to stip tags
			stripperRE = "</?(" & listChangeDelims(badTags,"|") & ")[^>]*>";
			//Deal with "smart quotes" and other "special" chars from MS Word
			theText = replaceList(theText,chr(8216) & "," & chr(8217) & "," & chr(8220) & "," & chr(8221) & "," & chr(8212) & "," & chr(8213) & "," & chr(8230),"',',"","",--,--,...");
			//if escaping, run through the code bracket by bracket and escape the bad tags.
			if(mode is "escape"){
				//go until no more open brackets to find
				while(obracket){
					//find the next instance of one of the bad tags
					badTag = REFindNoCase(stripperRE,theText,obracket,1);
					//if a bad tag is found, escape it
					if(badTag.pos[1]){
						theText = replace(theText,mid(TheText,badtag.pos[1],badtag.len[1]),HTMLEditFormat(mid(TheText,badtag.pos[1],badtag.len[1])),"ALL");
						nextStart = badTag.pos[1] + badTag.len[1];
					} else {
						nextStart = obracket + 1;
					};
					//find the next open bracket
					obracket = find("<",theText,nextStart);
				};
			} else {
				theText = REReplaceNoCase(theText,stripperRE,"","ALL");
			};
			//now kill the bad "events" (intra tag text)
			theText = REReplaceNoCase(theText,'(#ListChangeDelims(badEvents,"|")#)[^ >]*',"","ALL");
			return theText;
		};
	
		function stringToAscii(str) {
			var local = StructNew();
			local.oldStr = '';
			local.newStr = '';
			if ( StructKeyExists(arguments, 'str') and IsSimpleValue(arguments.str) ) {
				local.oldStr = arguments.str;
				for ( local.i=1; local.i lte Len(arguments.str); local.i++ ) {
					local.newStr = local.newStr & '&##' & Asc(Left(local.oldStr,1)) & ';';
					local.oldStr = RemoveChars(local.oldStr,1,1);
				};
			};
			return local.newStr;
		};


		// lists
		function listInCommon(List1, List2) {
			var TempList = "";
			var Delim1 = "^";
			var Delim2 = "^";
			var Delim3 = "^";
			var i = 0;
			// Handle optional arguments
			switch(ArrayLen(arguments)) {
				case 3:	{
					Delim1 = Arguments[3];
					break;
				};
				case 4: {
					Delim1 = Arguments[3];
					Delim2 = Arguments[4];
					break;
				};
				case 5:	{
					Delim1 = Arguments[3];
					Delim2 = Arguments[4]; 
					Delim3 = Arguments[5];
					break;
				};
			};
			/* Loop through the second list, checking for the values from the first list.
			* Add any elements from the second list that are found in the first list to the
			* temporary list
			*/ 
			for (i=1; i LTE ListLen(List2, Delim2); i=i+1) {
				if (ListFindNoCase(List1, ListGetAt(List2, i, Delim2), Delim1)){
					TempList = ListAppend(TempList, ListGetAt(List2, i, Delim2), Delim3);
				};
			};
			Return TempList;
		};

		// MISC
		function isCookiesEnabled() { 
			return IsBoolean(URLSessionFormat('True'));
		};

		// File + Directory
		function getRoot() {
			return ExpandPath(getDelim());
		};

		function getDelim() {
			var fileObj = CreateObject('java','java.io.File');
			return fileObj.separator;
		};

		// info on THIS template - regardless of where it's being called from.
		function getCurrentTemplate() {
			var current = {
				directory = GetDirectoryFromPath(GetCurrentTemplatePath())
				, file = GetFileFromPath(GetCurrentTemplatePath())
				, path = getCurrentTemplatePath()
			};
			return current;
		};
		
		// info on the CALLER - or the file/template that is utlimately being rendered
		function getBaseTemplate() {
			var base = {
				directory = GetDirectoryFromPath(GetBaseTemplatePath())
				, file = GetFileFromPath(GetBaseTemplatePath())
				, path = getBaseTemplatePath()			
			};
			return base;
		};

		// Name Value Pairs - quite handy!
		function formToNameValuePairs(formStruct) {
			var local = {};
			local.nameValuePairs = '';
			local.doNotProcess = '';
			local.value = '';
			local.key = '';
	
			// optional arg
			if ( StructKeyExists(arguments, 'doNotProcessList') ) {
				local.doNotProcess = ListAppend(local.doNotProcess, arguments.doNotProcessList);
			};
			
			if ( StructKeyExists(arguments, 'formStruct') and StructKeyExists(arguments.formStruct, 'fieldnames') ) {
				for ( local.key in arguments.formStruct ) {
					if ( IsSimpleValue(local.key) and ListFindNoCase(arguments.formStruct.fieldnames, local.key) and not ListFindNoCase(local.doNotProcess, local.key) ) {
						if ( len(trim(arguments.formStruct[local.key])) ) {
							local.value = URLEncodedFormat(arguments.formStruct[local.key], 'utf-8');
						} else {
							local.value = URLEncodedFormat(' ', 'utf-8');
						};
						local.nameValuePairs = local.nameValuePairs & '&' & URLEncodedFormat(LCase(local.key)) & '=' & local.value;
					};
				};
			};
			return local.nameValuePairs;
		};

	</cfscript>

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
		<cfif IsValid('url', arguments.url)>
			<cflocation url="#arguments.url#" addtoken="false" />
		<cfelse>
			<cfreturn />
		</cfif>
	</cffunction>

	<cffunction name="include">
		<cfargument name="file" required="true" />
		<cfset var str = '' />
		<cfsavecontent variable="str">
			<cfinclude template="#arguments.file#" />
		</cfsavecontent>
		<cfreturn str />
	</cffunction>

	<cffunction name="htmlHead">
		<cfargument name="str" required="false" default="" />
		<cfhtmlhead text="#str#" />
	</cffunction>

	<cffunction name="setSessionData">
		<cfargument name="sessionData" required="false" default="" type="any" />
		<cfargument name="sessionName" required="false" default="sessionData" type="string" />
		<cfset deleteSessionData(arguments.sessionName) />
		<cflock type="exclusive" scope="session" timeout="5000">
			<cfset 'session.#arguments.sessionName#' = arguments.sessionData />
		</cflock>
	</cffunction>
	
	<cffunction name="getSessionData" output="false" returntype="any">
		<cfargument name="sessionName" required="false" default="sessionData" type="string" />
		<cfif StructKeyExists(session, arguments.sessionName)>
			<cfreturn 'session.#arguments.sessionName#' />
		<cfelse>
			<cfreturn '' />
		</cfif>
	</cffunction>

	<cffunction name="deleteSessionData" output="false" returntype="void">
		<cfargument name="sessionName" required="false" default="sessionData" type="string" />
		<cfif StructKeyExists(session, arguments.sessionName)>
			<cflock type="exclusive" scope="session" timeout="1000">
				<cfset StructDelete(session, arguments.sessionName) />
			</cflock>
		</cfif>
	</cffunction>

	<cffunction name="setApplicationData">
		<cfargument name="applicationData" required="false" default="" type="any" />
		<cfargument name="applicationName" required="false" default="applicationData" type="string" />
		<cfset deleteApplicationData(arguments.applicationName) />
		<cflock type="exclusive" scope="application" timeout="5000">
			<cfset 'application.#arguments.applicationName#' = arguments.applicationData />
		</cflock>
	</cffunction>
	
	<cffunction name="getApplicationData" output="false" returntype="any">
		<cfargument name="applicationName" required="false" default="applicationData" type="string" />
		<cfif StructKeyExists(application, arguments.applicationName)>
			<cfreturn 'application.#arguments.applicationName#' />
		<cfelse>
			<cfreturn '' />
		</cfif>
	</cffunction>
	
	<cffunction name="deleteApplicationData" output="false" returntype="void">
		<cfargument name="applicationName" required="false" default="applicationData" type="string" />
		<cfif StructKeyExists(application, arguments.applicationName)>
			<cflock type="exclusive" scope="application" timeout="1000">
				<cfset StructDelete(application, arguments.applicationName) />
			</cflock>
		</cfif>
	</cffunction>

</cfcomponent>