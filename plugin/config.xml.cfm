<cfoutput><plugin>
	<name>MuraPayPalSubscriber</name>
	<package>MuraPayPalSubscriber</package>
	<directoryFormat>packageOnly</directoryFormat>
	<loadPriority>5</loadPriority>
	<version>0.0.1</version>
	<provider>Steve Withington</provider>
	<providerURL>http://stephenwithington.com</providerURL>
	<category>Application</category>
	<settings>
		<setting>
			<name>useSandbox</name>
			<label>Use PayPal Sandbox mode?</label>
			<hint>If 'Yes', then all transactions will be posted to PayPal's sandbox for testing purposes only. If NO, then you must enter you real API credentials and all transactions will be LIVE.</hint>
			<type>RadioGroup</type>
			<required>true</required>
			<validation></validation>
			<regex></regex>
			<message>Please tell us if we're using the PayPal Sandbox for testing purposes.</message>
			<defaultvalue>1</defaultvalue>
			<optionlist>0^1</optionlist>
			<optionlabellist>No^Yes</optionlabellist>
		</setting>	
		<setting>
			<name>useSDKCredentials</name>
			<label>Should we use the generic SDK API credentials when we're in sandbox mode?</label>
			<hint>If you have your own sandbox/developer credentials, you can set this to false and then enter your sandbox API credentials.</hint>
			<type>RadioGroup</type>
			<required>true</required>
			<validation></validation>
			<regex></regex>
			<message>Please tell us if we're using the PayPal's generic SDK credentials when we're in sandbox mode.</message>
			<defaultvalue>1</defaultvalue>
			<optionlist>0^1</optionlist>
			<optionlabellist>No^Yes</optionlabellist>
		</setting>
		<setting>
			<name>apiAccount</name>
			<label>PayPal Business Account (primary email or merchant id)</label>
			<hint>Enter either your PayPal Business email address or PayPal Merchant ID</hint>
			<type>text</type>
			<required>false</required>
			<validation></validation>
			<regex></regex>
			<message></message>
			<defaultvalue></defaultvalue>
			<optionlist></optionlist>
			<optionlabellist></optionlabellist>
		</setting>
		<setting>
			<name>apiUsername</name>
			<label>PayPal API Username</label>
			<hint></hint>
			<type>text</type>
			<required>false</required>
			<validation></validation>
			<regex></regex>
			<message></message>
			<defaultvalue></defaultvalue>
			<optionlist></optionlist>
			<optionlabellist></optionlabellist>
		</setting>
		<setting>
			<name>apiPassword</name>
			<label>PayPal API Password</label>
			<hint></hint>
			<type>text</type>
			<required>false</required>
			<validation></validation>
			<regex></regex>
			<message></message>
			<defaultvalue></defaultvalue>
			<optionlist></optionlist>
			<optionlabellist></optionlabellist>
		</setting>
		<setting>
			<name>apiSignature</name>
			<label>PayPal API Signature</label>
			<hint></hint>
			<type>text</type>
			<required>false</required>
			<validation></validation>
			<regex></regex>
			<message></message>
			<defaultvalue></defaultvalue>
			<optionlist></optionlist>
			<optionlabellist></optionlabellist>
		</setting>
		<setting>
			<name>messageOptions</name>
			<label>Sign Up/Options Message</label>
			<hint></hint>
			<type>textarea</type>
			<required>false</required>
			<validation></validation>
			<regex></regex>
			<message>This is the text displayed to users on the 'Subscription Options' screen.</message>
			<defaultvalue>Select any of the available subscription options from the dropdown below.</defaultvalue>
			<optionlist></optionlist>
			<optionlabellist></optionlabellist>
		</setting>
		<setting>
			<name>messageReview</name>
			<label>Review Transaction Message</label>
			<hint></hint>
			<type>textarea</type>
			<required>false</required>
			<validation></validation>
			<regex></regex>
			<message>This is the text displayed to users on the 'Review Your Order' screen.</message>
			<defaultvalue>Please review your order information below.</defaultvalue>
			<optionlist></optionlist>
			<optionlabellist></optionlabellist>
		</setting>
		<setting>
			<name>messageReceipt</name>
			<label>Receipt/Confirmation Message</label>
			<hint></hint>
			<type>textarea</type>
			<required>false</required>
			<validation></validation>
			<regex></regex>
			<message>This is the text displayed to users after successful payment and registration.</message>
			<defaultvalue>Thank you for your business! A copy of your order has been emailed to you by PayPal.</defaultvalue>
			<optionlist></optionlist>
			<optionlabellist></optionlabellist>
		</setting>
		<setting>
			<name>messageRenew</name>
			<label>Cancelled and Expired Account Message</label>
			<hint></hint>
			<type>textarea</type>
			<required>false</required>
			<validation></validation>
			<regex></regex>
			<message>This is the text displayed to users whose status is either CANCELLED or EXPIRED.</message>
			<defaultvalue>Now is the time to renew and/or upgrade your subscription.</defaultvalue>
			<optionlist></optionlist>
			<optionlabellist></optionlabellist>
		</setting>
		<setting>
			<name>messageSuspend</name>
			<label>Suspended Account Message</label>
			<hint></hint>
			<type>textarea</type>
			<required>false</required>
			<validation></validation>
			<regex></regex>
			<message>This is the text displayed to users with accounts placed into a SUSPENDED status by an Administrator.</message>
			<defaultvalue>Your account has been suspended. Please contact customer service.</defaultvalue>
			<optionlist></optionlist>
			<optionlabellist></optionlabellist>
		</setting>
	</settings>
	<eventHandlers>
		<eventHandler event="onApplicationLoad" component="pluginEventHandler" persist="false" />
	</eventHandlers>
	<displayobjects location="global">
		<displayobject name="MuraPayPalSubscriber" displaymethod="renderApp" component="pluginEventHandler" persist="false" />
	</displayobjects>
</plugin></cfoutput>