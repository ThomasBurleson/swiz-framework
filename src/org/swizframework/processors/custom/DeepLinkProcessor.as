package org.swizframework.processors.custom
{
	import flash.events.Event;
	
	import mx.events.BrowserChangeEvent;
	import mx.managers.BrowserManager;
	import mx.managers.IBrowserManager;
	
	import org.swizframework.core.Bean;
	import org.swizframework.core.ISwiz;
	import org.swizframework.metadata.DeepLinkMetadataTag;
	import org.swizframework.metadata.MediateMetadataTag;
	import org.swizframework.reflection.ClassConstant;
	import org.swizframework.reflection.Constant;
	import org.swizframework.reflection.IMetadataTag;
	import org.swizframework.reflection.TypeCache;
	import org.swizframework.reflection.TypeDescriptor;
	import org.swizframework.processors.BaseMetadataProcessor;
	
	/**
	 * [DeepLink] metadata processor
	 */
	public class DeepLinkProcessor extends BaseMetadataProcessor
	{
		
		// ========================================
		// protected properties
		// ========================================
		
		/**
		 * Reference to the an IBrowserManager instance.
		 * 
		 * @defaultValue Singleton instance for the Flex SDK BrowserManager
		 */
		public var browserManager:IBrowserManager;
		
		/**
		 * List of mediate event types
		 */
		protected var mediateEventTypes:Array = [];
		
		/**
		 * List of attached urll mappings
		 */
		protected var deepLinks:Array = [];
		
		/**
		 * List of url regexs to match browser urls against
		 */
		protected var regexs:Array = [];
		
		/**
		 * List of methods to call
		 */
		protected var methods:Array = [];
		
		// ========================================
		// constructor
		// ========================================
		
		/**
		 * Constructor
		 */
		public function DeepLinkProcessor( metadataNames:Array = null )
		{
			super( ( metadataNames == null ) ? [ "DeepLink" ] : metadataNames, DeepLinkMetadataTag );
		}
		
		// ========================================
		// public methods
		// ========================================
		
		/**
		 * Init
		 */
		override public function init( swiz:ISwiz ):void
		{
			super.init( swiz );
			
			if (browserManager == null) {
				// Defaults to internal reference to Flex SDK BrowserManager
				browserManager = BrowserManager.getInstance();
				browserManager.addEventListener( BrowserChangeEvent.BROWSER_URL_CHANGE, onBrowserURLChange );
			}
			
			browserManager.init();
		}
		
		/**
		 * Executed when a new [DeepLink] is found
		 */
		override public function setUpMetadataTag( metadataTag:IMetadataTag, bean:Bean ):void
		{
			var deepLink:DeepLinkMetadataTag = DeepLinkMetadataTag( metadataTag );
			var method:Function = bean.source[ metadataTag.host.name ] as Function;
			
			addURLMapping( deepLink, method );
		}
		
		/**
		 * Executed when a [DeepLink] has been removed
		 */
		override public function tearDownMetadataTag(metadataTag:IMetadataTag, bean:Bean):void
		{
			var deepLink:DeepLinkMetadataTag = DeepLinkMetadataTag( metadataTag );
			var method:Function = bean.source[ metadataTag.host.name ] as Function;
			
			removeURLMapping( deepLink, method );
		}
		
		/**
		 * Executed when the browser URL changes
		 */
		public function onBrowserURLChange( event:Event ):void {
			var url:String = event.hasOwnProperty("url") ? event["url"] : "";
			
			url = url.indexOf( "#" ) > -1 ? url.substr( url.indexOf( "#" ) + 1 ) : "";
			
			if (url != "") { 
				for ( var i:int = 0; i < regexs.length; i++ ) {
					
					var match:Array = url.match( regexs[ i ] );
					
					if ( match != null ) {
						processURLMapping( match, deepLinks[ i ] as DeepLinkMetadataTag, methods[ i ] as Function );
					}
				}
			}
		}
		
		// ========================================
		// protected methods
		// ========================================
		
		/**
		 * Add a URL mapping
		 */
		protected function addURLMapping( deepLink:DeepLinkMetadataTag, method:Function ):void
		{
			var index:int = deepLinks.length;
			var regex:RegExp = new RegExp( "^" + deepLink.url.replace( /[\\\+\?\|\[\]\(\)\^\$\.\,\#]{1}/g, "\$1" ).replace( /\*/g, ".*" ).replace( /\{.+?\}/g, "(.+?)" ) + "$" );
			
			// add mapping to arrays
			deepLinks[ index ] = deepLink;
			methods[ index ] = method;
			regexs[ index ] = regex;
			
			// check if mapping matches the current url
			var url:String = browserManager.url != null ? browserManager.url.substr( browserManager.url.indexOf( "#" ) + 1 ) : "";
			var match:Array = url.match( regex );
			
			// if a match is found, process the url change
			if ( match != null )
			{
				processURLMapping( match, deepLink, method );
			}
			
			addMediate( deepLink );
		}
		
		/**
		 * Remove a URL mapping
		 */
		protected function removeURLMapping( deepLink:DeepLinkMetadataTag, method:Function ):void
		{
			var index:int = deepLinks.indexOf( deepLink );
			
			if ( index != -1 )
			{
				// remove mapping from arrays
				deepLinks.splice( index, 1 );
				methods.splice( index, 1 );
				regexs.splice( index, 1 );
			}
			
			removeMediate( deepLink );
		}
		
		/**
		 * Add a reverse URL mapping if possible
		 */
		protected function addMediate( deepLink:DeepLinkMetadataTag ):void
		{
			if ( deepLink.host.hasMetadataTagByName( "Mediate" ) )
			{
				var mediateTag:MediateMetadataTag = new MediateMetadataTag();
				
				mediateTag.copyFrom( deepLink.host.getMetadataTagByName( "Mediate" ) );
				
				if( mediateTag.event.substr( -2 ) == ".*" )
				{
					var clazz:Class = ClassConstant.getClass(swiz.domain, mediateTag.event, swiz.config.eventPackages );
					var td:TypeDescriptor = TypeCache.getTypeDescriptor( clazz, swiz.domain );
					
					for each( var constant:Constant in td.constants )
					{
						addEventHandler( deepLink, constant.value );
					}
				}
				else
				{
					var eventType:String = parseEventTypeExpression( mediateTag.event );
					
					addEventHandler( deepLink, eventType );
				}
			}
		}
		
		/**
		 * Remove a reverse URL mapping
		 */
		protected function removeMediate( deepLink:DeepLinkMetadataTag ):void
		{
			if ( deepLink.host.hasMetadataTagByName( "Mediate" ) )
			{
				var mediateTag:MediateMetadataTag = new MediateMetadataTag();
				
				mediateTag.copyFrom( deepLink.host.getMetadataTagByName( "Mediate" ) );
				
				if( mediateTag.event.substr( -2 ) == ".*" )
				{
					var clazz:Class = ClassConstant.getClass(swiz.domain, mediateTag.event, swiz.config.eventPackages);
					var td:TypeDescriptor = TypeCache.getTypeDescriptor( clazz, swiz.domain );
					
					for each( var constant:Constant in td.constants )
					{
						removeEventHandler( deepLink, constant.value );
					}
				}
				else
				{
					var eventType:String = parseEventTypeExpression( mediateTag.event );
					
					removeEventHandler( deepLink, eventType );
				}
			}
		}
		
		/**
		 * Add mediate event handler
		 */
		protected function addEventHandler( deepLink:DeepLinkMetadataTag, eventType:String ):void
		{
			swiz.dispatcher.addEventListener( eventType, mediateEventHandler );
			mediateEventTypes[ mediateEventTypes.length ] = eventType;
		}
		
		/**
		 * Remove mediate event handler
		 */
		protected function removeEventHandler( deepLink:DeepLinkMetadataTag, eventType:String ):void
		{
			swiz.dispatcher.removeEventListener( eventType, mediateEventHandler );
			mediateEventTypes.splice( mediateEventTypes.lastIndexOf( eventType ), 1 );
		}
		
		/**
		 * Process an incoming URL change
		 */
		protected function processURLMapping( match:Array, deepLink:DeepLinkMetadataTag, method:Function ):void
		{
			var parameters:Array = [];
			var placeholders:Array = deepLink.url.match( /\{\d+\}/g );
			
			for each ( var placeholder:String in placeholders )
			{
				var index:int = int( placeholder.substr( 1, placeholder.length - 2 ) ) + 1;
				
				parameters[ parameters.length ] = unescape( match[ index ] );
			}
			
			method.apply( null, parameters );
			
			if( deepLink.title != null )
			{
				browserManager.setTitle( constructUrl( deepLink.title, parameters ) );
			}
		}
		
		/**
		 * Sets the url when ever a mediated method is called
		 */
		protected function mediateEventHandler( event:Event ):void
		{
			var deepLink:DeepLinkMetadataTag = DeepLinkMetadataTag( deepLinks[ mediateEventTypes.lastIndexOf( event.type ) ] );
			var mediate:IMetadataTag = deepLink.host.getMetadataTagByName( "Mediate" );
			var args:Array = mediate.hasArg( "properties" ) ? getEventArgs( event, mediate.getArg( "properties" ).value.split( /\s*,\s*/ ) ) : null;
			
			if( deepLink != null )
			{
				var url:String = deepLink.url;
				
				url = url.replace( /\*/g, "" );
				
				if( args != null )
				{
					for ( var i:int = 0; i < args.length; i++ )
					{
						url = url.replace( new RegExp( "\\{" + i + "\\}", "g" ), escape( args[ i ] ) );
					}
				}
				
				browserManager.setFragment( url );
				
				if( deepLink.title != null )
				{
					browserManager.setTitle( constructUrl( deepLink.title, args ) );
				}
			}
		}
		
		/**
		 *
		 */
		protected function constructUrl( url:String, params:Array ):String
		{
			for( var i:int = 0; i < params.length; i++ )
			{
				url = url.replace( new RegExp( "\\{" + i + "\\}", "g" ), params[ i ] );
			}
			
			return url;
		}
		
		/**
		 *
		 */
		protected function getEventArgs( event:Event, properties:Array ):Array
		{
			var args:Array = [];
			
			for each( var property:String in properties )
			{
				args[ args.length ] = event[ property ];
			}
			
			return args;
		}
		
		/**
		 *
		 */
		protected function parseEventTypeExpression( value:String ):String
		{
			if( swiz.config.strict && ClassConstant.isClassConstant( value ) )
			{
				var clazz : Class = ClassConstant.getClass(swiz.domain, value, swiz.config.eventPackages );
				return ClassConstant.getConstantValue(swiz.domain, clazz , ClassConstant.getConstantName( value ) );
			}
			else
			{
				return value;
			}
		}
		
	}
}