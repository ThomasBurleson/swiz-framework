package org.swizframework.processors
{
	import flash.utils.getDefinitionByName;
	
	import mx.logging.ILogger;
	import mx.logging.LogEventLevel;
	import mx.logging.targets.TraceTarget;
	
	import org.swizframework.core.Bean;
	import org.swizframework.core.ISwiz;
	import org.swizframework.processors.BaseMetadataProcessor;
	import org.swizframework.reflection.IMetadataTag;
	import org.swizframework.utils.SwizLogger;
	
	public class LogProcessor extends BaseMetadataProcessor
	{
		public function set level(value:int)			  :void	{	if (tracer != null) tracer.level = value;			}
		public function set filters(value:Array)		  :void {	if (tracer != null) tracer.filters = value;			}
		public function set includeDate(value:Boolean)	  :void {	if (tracer != null) tracer.includeDate = value;		}
		public function set includeTime(value:Boolean)	  :void	{	if (tracer != null) tracer.includeTime = value;		}
		public function set includeCategory(value:Boolean):void	{	if (tracer != null) tracer.includeCategory = value;	}
		public function set includeLevel(value:Boolean)	  :void	{	if (tracer != null) tracer.includeLevel = value;	}
		
		public function LogProcessor(level			:int = LogEventLevel.ALL, 
									 filters		:Array = null, 
									 includeDate	:Boolean = true, 
									 includeTime	:Boolean = true, 
									 includeCategory:Boolean = true, 
									 includeLevel	:Boolean = true) {
			super([LOG]);
			
			// Defer creation of shared target until Swiz is ready and calls init()
			_initCache = { 	level			:level,
							filters			:filters,
							includeDate		:includeDate, 
							includeTime		:includeTime, 
							includeCategory :includeCategory, 
							includeLevel	:includeLevel };
		}
		
		
		override public function init( swiz:ISwiz ):void {
			super.init(swiz);
			initTracer();
			logger = SwizLogger.getLogger( this );
		}
		
		
		/**
		 * Assign ILogger instance
		 */
		override public function setUpMetadataTags( metadataTags:Array, bean:Bean ):void{
			super.setUpMetadataTags( metadataTags, bean );
			
			// bean.typeDescriptor.className returns class name in packages::ClassName notation
			// that is not accepted by Log.getLogger function, returning only ClassName string 
			
			var className:String = bean.typeDescriptor.className;
			className = className.substr(className.lastIndexOf(":") + 1);
			
			for each (var metadataTag:IMetadataTag in metadataTags) {
				// Setting Logger
				bean.source[ metadataTag.host.name ] = SwizLogger.getLogger(className);
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
		
		private function initTracer() : void {
			
			// If shared is not available...
			if (LogProcessor.traceTarget == null)
			{
				// Build one and register with Swiz and shared
				var tracer : TraceTarget = new TraceTarget();
				
				tracer.level 			= _initCache.level;
				tracer.filters			= _initCache.filters;
				tracer.includeDate 		= _initCache.includeDate;
				tracer.includeTime 		= _initCache.includeTime;
				tracer.includeCategory 	= _initCache.includeCategory;
				tracer.includeLevel 	= _initCache.includeLevel;
				
				LogProcessor.traceTarget = tracer;
				SwizLogger.addLoggingTarget(tracer);
			} 			
		}
		
		private function get tracer():TraceTarget {
			return LogProcessor.traceTarget;
		}

				private    var      _initCache 	:Object      = null;
				
		static	protected  const 	LOG			:String 	 = "Log";
		static 	protected  var 		traceTarget	:TraceTarget = null;
		
				protected  var 		logger		:ILogger 	= null;
	}
}