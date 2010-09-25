/*
* Copyright 2010 Swiz Framework Contributors
*
* Licensed under the Apache License, Version 2.0 (the "License"); you may not
* use this file except in compliance with the License. You may obtain a copy of
* the License. You may obtain a copy of the License at
*
* http://www.apache.org/licenses/LICENSE-2.0
*
* Unless required by applicable law or agreed to in writing, software
* distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
* WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
* License for the specific language governing permissions and limitations under
* the License.
*/

package org.swizframework.utils.services
{
	import flash.display.Loader;
	import flash.events.ErrorEvent;
	import flash.events.Event;
	import flash.events.HTTPStatusEvent;
	import flash.events.IEventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.events.ProgressEvent;
	import flash.events.SecurityErrorEvent;
	import flash.events.TimerEvent;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.system.LoaderContext;
	import flash.utils.Timer;
	
	[ExcludeClass]
	
	/**
	 *
	 * DynamicUrlRequest can be used to wrap URLLoader calles.
	 * The faultHandler function will be used for IOErrors and SecurityErrors
	 * so you should type the argument Event and check/cast the specific type
	 * in the method body.
	 *
	 * When used implicitly from Swiz.executeUrlRequest or AbstractController.executeUrlRequest
	 * the generic fault handler will be applied if available. Otherwise in an error case
	 * the Swiz internal generic fault shows up.
	 *
	 */
	public class SwizURLRequest
	{
		public static const LOAD_TIMEOUT: String = "loadTimeout";
		
		/**
		 *
		 * @param request
		 * @param resultHandler The resultHandler function must expect the an event. event.currentTarget.data should contain the result. Signature can be extended with additional eventArgs
		 * @param faultHandler The faultHandler function will be called for IOErrors and SecurityErrors with the specific error event.
		 * @param progressHandler
		 * @param httpStatusHandler
		 * @param eventArgs The eventArgs will be applied to the signature of the resultHandler function.
		 * @param useLoader Pass true to use a Loader instead of URLLoader, for example to fetch image data.
		 * @param context Optional <code>LoaderContext</code> instance (when <code>useLoader</code> is true).
		 * @param urlLoaderDataFormat Optional <code>URLLoaderDataFormat</code> constant (when <code>useLoader</code> is false).
		 * @param timeoutSeconds After all load tries time out an <code>ErrorEvent</code> of type <code>SwizURLRequest.LOAD_TIMEOUT</code> is fired.
		 * A setting of 4-6 seconds is recommended, but 0 (no timeout) is not since your delegate may be left hanging.
		 * @param tries Total number of load tries (1 or higher). Example: <code>timeoutSeconds: 4, tries: 3</code> will time out in 12 seconds.
		 *
		 */
		public function SwizURLRequest( request:URLRequest, resultHandler:Function,
										faultHandler:Function = null, progressHandler:Function = null,
										httpStatusHandler:Function = null, eventArgs:Array = null,
										useLoader:Boolean = false, context:LoaderContext = null, urlLoaderDataFormat:String = null,
										timeoutSeconds:uint=10, tries:uint=1)
		{
			function fire(handler:Function, e:Event):void {
				if (timer)
				{
					timer.reset();
				}
				if ( handler != null ) {
					if ( eventArgs != null ) {
						handler.apply( null, new Array(e).concat(eventArgs) );
					}
					else {
						handler( e );
					}
				}
				else {
					// todo: what if there is no handler?
				}
			}
			
			function load(event:TimerEvent=null):void
			{
				if (event && ++fails == tries)
				{
					fire ( faultHandler, new ErrorEvent(LOAD_TIMEOUT, false, false, "Load timed out after " + tries + " attempt" + (tries == 1 ? "." : "s.")) );
					return;
				}
				
				try {
					
					loader.load( request, useLoader ? context : null);
					if (timer)  timer.start();
					
				} catch (error:Error) {
					//  Catches errors thrown by load call in SwizURLRequest and passes an ErrorEvent to 
					//	the fault handler.
					
					fire ( faultHandler, new ErrorEvent(ErrorEvent.ERROR, false, false, error.toString()) );
				}
			}
			
			var dispatcher:IEventDispatcher, loader:Object, fails:int = 0, timer:Timer;
			if (timeoutSeconds)
			{
				tries ||= 1;
				timer = new Timer(timeoutSeconds * 1000, 1);
				timer.addEventListener(TimerEvent.TIMER_COMPLETE, load);
			}
			
			if (useLoader)
			{
				loader = new Loader();
				dispatcher = loader.contentLoaderInfo;
			}
			else
			{
				loader = new URLLoader();
				dispatcher = loader as IEventDispatcher;
				if (urlLoaderDataFormat)
				{
					loader.dataFormat = urlLoaderDataFormat;
				}
			}
			
			dispatcher.addEventListener( Event.COMPLETE, 
										 function( e:Event ):void	{
											// applying the event itself is more flexible here since it allows the user to access
											// either the URLLoader or Loader.contentLoaderInfo depending on their useLoader input.
											
											fire( resultHandler, e );
										 } 
										);
			
			dispatcher.addEventListener( IOErrorEvent.IO_ERROR, 
										 function( e:IOErrorEvent ):void {
											fire( faultHandler, e );
										 } 
									   );
			
			dispatcher.addEventListener( SecurityErrorEvent.SECURITY_ERROR, 
										 function( e:SecurityErrorEvent ):void	{
												fire( faultHandler, e );
										 }
									   );
			
			if( progressHandler != null )
			{
				dispatcher.addEventListener( ProgressEvent.PROGRESS, function( e:ProgressEvent ):void
				{
					fire ( progressHandler, e );
				} );
			}
			
			if( httpStatusHandler != null )
			{
				dispatcher.addEventListener( HTTPStatusEvent.HTTP_STATUS, function( e:HTTPStatusEvent ):void
				{
					fire ( httpStatusHandler, e );
				} );
			}
			
			load();
		}
	}
}