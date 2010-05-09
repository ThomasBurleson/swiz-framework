package org.swizframework.processors
{
	import flash.utils.getDefinitionByName;
	import flash.utils.getQualifiedClassName;
	
	import mx.logging.ILogger;
	import mx.logging.ILoggingTarget;
	import mx.logging.LogEventLevel;
	import mx.logging.targets.TraceTarget;
	
	import org.swizframework.core.Bean;
	import org.swizframework.core.ISwiz;
	import org.swizframework.processors.BaseMetadataProcessor;
	import org.swizframework.reflection.IMetadataTag;
	import org.swizframework.utils.SwizLogger;
	
	/**
	 * This Metadata Tag processor supports the [Log] tag to inject a logger reference.
	 * The power of this processor is that when it attaches/injects a logger reference into a target class
	 * it also creates a custom logger for that same class. The logger is auto-configured to prepend 
	 * Class B's name in the log message. 
	 * 
	 * For example consider the target class BeadTester below:
	 * 
	 * 	 class org.test.services.BeadTester {
	 * 
	 *  	[Log]
	 *   	public var log  : ILogger = null;
	 * 
	 *   	public function startTest(testID:String):void {
	 *     		log.debug("startTest() testID =#"+testID);
	 *   	}
	 *    }
	 *
	 *  and the LogProcessor registered with the Swiz instance using: 
	 * 
	 * 		<swiz:customProcessors>
	 *			<swiz:LogProcessor>
	 *				<swiz:loggingTarget>
	 *					<mx:TraceTarget fieldSeparator=">> "
	 *							filters="{['org.test.services.*']}"
	 *							includeCategory="true"
	 *							includeTime="true"
	 *							includeLevel="true"
	 *							level="{LogEventLevel.DEBUG }" />
	 *				</swiz:loggingTarget>
	 *			</swiz:LogProcessor>
	 *		</swiz:customProcessors>
	 *   
	 *  With the above settings, a call to an instance <BeadTester>.startTest(4) would yield output of:
	 * 
	 *        10:17:04.233>> [DEBUG]>> org.test.services::BeadTester>> startTest() testID =#4  
	 *
	 * 
	 * @author thomasburleson
	 * @date   May, 2010
	 * 
	 */
	public class LogProcessor extends BaseMetadataProcessor
	{
		public function set loggingTarget(val:ILoggingTarget):void 	{   settings.loggingTarget = val;	}
		public function set level(value:int)			  	:void	{	settings.level = value;			}
		public function set filters(value:Array)		  	:void 	{	settings.filters = value;			}
		public function set includeDate(value:Boolean)	  	:void 	{	settings.includeDate = value;		}
		public function set includeTime(value:Boolean)	  	:void	{	settings.includeTime = value;		}
		public function set includeCategory(value:Boolean)	:void	{	settings.includeCategory = value;	}
		public function set includeLevel(value:Boolean)	  	:void	{	settings.includeLevel = value;	}
		
		/**
		 * Constructor to support programmatic instantiation
		 *  
		 * @param loggingTarget ILoggingTarget instance; defaults to null. If not null, then all other parameters are ignored.
		 * @param level			LogEventLevel; defaults to ALL
		 * @param filters		String[] specifies which packages are filtered (allowed).
		 * @param includeDate	Boolean indicates if Log date is included in the log output
		 * @param includeTime	Boolean indicates if Log time is included in the log output
		 * @param includeCategory	Boolean indicates if target className is included in the log output
		 * @param includeLevel	Boolean indicates if LogLevel is included in the log output
		 * 
		 */
		public function LogProcessor(loggingTarget  :ILoggingTarget = null,
									 level			:int 	 = LogEventLevel.ALL, 
									 filters		:Array 	 = null, 
									 includeDate	:Boolean = true, 
									 includeTime	:Boolean = true, 
									 includeCategory:Boolean = true, 
									 includeLevel	:Boolean = true) {
			super([LOG]);
			
			// Defer creation of shared target until Swiz is ready and calls init()
			settings = new CachedSettings(	loggingTarget,level,filters,
											includeDate,includeTime,includeCategory,includeLevel);
		}
		
		
		/**
		 * Init method to configure the processor and build default 
		 * LoggerTarget if not provided
		 *  
		 * @param swiz Swiz needed to access bean factory
		 * 
		 */
		override public function init( swiz:ISwiz ):void {
			super.init(swiz);
			
			// Allow custom override of category ID (which is used with filters
			addLogTarget();
			logger = SwizLogger.getLogger(this);
		}
		
		
		/**
		 * Assign ILogger instance; each assigned/customized for the targeted bean class
		 */
		override public function setUpMetadataTags( metadataTags:Array, bean:Bean ):void{
			super.setUpMetadataTags( metadataTags, bean );
			
			for each (var metadataTag:IMetadataTag in metadataTags) {
				
				// Setting filters and Logger instance for this bean.source class
				autotAddLogFilter(bean.source);
				bean.source[ metadataTag.host.name ] = SwizLogger.getLogger(bean.source);
				
				logger.debug( "LogProcessor set up {0} on {1}", metadataTag.toString(), bean.toString() ); 
			}
		}
		
		/**
		  * Remove ILogger instance
		 */
		override public function tearDownMetadataTag( metadataTag:IMetadataTag, bean:Bean ):void {
			bean.source[ metadataTag.host.name ] = null;
			logger.debug( "InjectProcessor tear down {0} on {1}", metadataTag.toString(), bean.toString() );
		}
		
		/**
		 * Build a default LoggingTarget if not specified in the LogProcessor instantiation. 
		 * 
		 */
		private function addLogTarget() : void {
			// Build one and register with Swiz and shared
			var logTarget : ILoggingTarget = settings.loggingTarget as ILoggingTarget;
			if (logTarget == null) {
				var target : TraceTarget = new TraceTarget();
				
				target.level 			= settings.level;
				target.filters			= settings.filters;
				target.includeDate 		= settings.includeDate;
				target.includeTime 		= settings.includeTime;
				target.includeCategory 	= settings.includeCategory;
				target.includeLevel 	= settings.includeLevel;
				
				logTarget = target;
				settings.loggingTarget  = target;
			}
			
			SwizLogger.addLoggingTarget(logTarget);
		}
		
		/**
		 * Each [Log] target will have its package path auto-added as an "allowed" filter.
		 * Use the fully-qualified classname to get its package path.
		 *  
		 * @param target Class instance with a [Log] metadata tag inserted.
		 * 
		 */
		private function autotAddLogFilter(target:Object):void {
			var logTarget : TraceTarget = settings.loggingTarget as TraceTarget;
			if (logTarget != null) {
				logTarget.filters ||= [];
				
				var clazzName   : String  = getQualifiedClassName( target );
				var packages    : String  = clazzName.substr(0,clazzName.indexOf(":")) + ".*";
				
					// Append new package to existing list of filters
					logTarget.filters = addToFilters(packages, logTarget.filters);
			}
		}
		
		private function addToFilters(category:String, filters:Array):Array {
			var results : Array   = [];
			var len     : int 	  = category.indexOf( "*" ) - 1;
			var found   : Boolean = false;
			
			for each (var it:String in filters) {
				// Remove default wildcard "match all" filter 
				if (it == "*") continue;
				
				if (category.substring(0, len) != it.substring(0, len)) {
					results.push(it);  // existing filter item to keep
				} else found ||= true;
			}
			
			// New category filter was not in list... so add it!
			if (found != true) results.push(category);
			
			return results;
		}
		
		
		
		static	protected  const 	LOG			:String 	 	= "Log";
		
				protected  var 		logger		:ILogger 		= null;
				protected  var      settings 	:CachedSettings = null;
	}
}



import flash.utils.getQualifiedClassName;

import mx.logging.ILoggingTarget;
import mx.logging.LogEventLevel;
import mx.utils.StringUtil;

/**
 * Helper class used to cache all initialization settings associated with LoggingTarget
 *  
 * @author thomasburleson
 * 
 */
class CachedSettings {

	public var loggingTarget    : ILoggingTarget 	= null;
	
	public var level 			: int 				= LogEventLevel.ALL;
	public var filters			: Array  			= [];
	
	public var includeDate  	: Boolean			= true;
	public var includeTime  	: Boolean			= true;
	public var includeCategory	: Boolean			= true;
	public var includeLevel		: Boolean			= true;
	
	public function CachedSettings (loggingTarget	:ILoggingTarget = null,
									level			:int 	 = LogEventLevel.ALL, 
									filters			:Array   = null, 
									includeDate		:Boolean = true, 
									includeTime		:Boolean = true, 
									includeCategory	:Boolean = false, 
									includeLevel	:Boolean = true) {
	
		this.loggingTarget      = loggingTarget;
		
		this.level				= level;
		this.filters			= filters;
		
		this.includeDate		= includeDate; 
		this.includeTime		= includeTime; 
		this.includeCategory 	= includeCategory; 
		this.includeLevel		= includeLevel;
	}
}