package org.swizframework.utils
{
	import mx.utils.StringUtil;

	public class PropertyUtils
	{
		/**
		 * For the targeted object, determine the value of the properyt or property chain
		 * 
		 * @param src 	Object
		 * @param chain	Object String or Array of strings representing the property or property chain
		 * @return *	value of the src[propertyChain]
		 * 
		 */
		static public function getChainValue(target:Object, chain:Object):* {
			var source : Object = getDestinationObject(target,chain);
			var key    : String = getDestinationKey(chain);
			
			return source.hasOwnProperty(key) ? source[key] : null;
		}
		
		/**
		 * For the specified target use the property chain to descend into
		 * the specified target to determine the last destination object
		 * 
		 * e.g.   chain  == "selected.data.serialNumber"
		 *        result == src.selected.data 
		 * 
		 * @param target 	Object 
		 * @param chain	String property chain
		 * 
		 * @results Object last recursed object in the property chain
		 * @throws  Error if the property or a chain part is invalid
		 *   
		 */
		static public function getDestinationObject(target:Object, chain:Object):Object {
			
			var dest:Object = target;
			var parts:Array = (chain is String) ? String(chain).split( "." ) :
				              (chain is Array)  ? (chain as Array)			 : [ ];
			
			while( parts.length > 1 ) {
				var key:String = parts.shift();
				
				if (dest.hasOwnProperty(key) != true) {
					var msg : String = StringUtil.substitute(ERROR_GETDESTINATION,[String(dest),chain,key]); 
					throw new Error(msg);
				}
				
				dest = dest[ key ];
			}
			
			return dest;			
		}
		
		
		/**
		 * Return the property key for a proper chain string;
		 * e.g.  chain == "node.data.serialNumber" 
		 *       key   == "serialNumber"
		 *  
		 * @param chain String property chain syntax 
		 * @results String key value from chain
		 */
		static public function getDestinationKey(chain:Object):String {
			return 	(chain is String)  ?	String(chain).split( "." ).pop() 	:
					(chain is Array)   ?	(chain as Array).pop()				: null;
		}
		
		
		static private const ERROR_GETDESTINATION : String = "PropertyUtils::getDestination({0},{1}) - {2} is invalid!";  
	}
}