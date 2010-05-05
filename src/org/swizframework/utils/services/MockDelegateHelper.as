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
	import flash.events.TimerEvent;
	import flash.utils.Dictionary;
	import flash.utils.Timer;
	
	import mx.core.mx_internal;
	import mx.managers.CursorManager;
	import mx.rpc.AsyncToken;
	import mx.rpc.Fault;
	import mx.rpc.IResponder;
	import mx.rpc.events.FaultEvent;
	import mx.rpc.events.ResultEvent;
	
	public class MockDelegateHelper
	{
		/**
		 * If <code>true</code>, a busy cursor is displayed while the mock service is
		 * executing. The default value is <code>false</code>.
		 */
		public var showBusyCursor:Boolean = false;
		
		
		
		public function MockDelegateHelper( showBusy:Boolean = false ) {
			showBusyCursor = showBusy;
		}
		
		// ******************************************************************************
		//  Cursor Methods
		// ******************************************************************************
		
		
		public function createMockResult( mockData:Object, delay:int = 10 ):AsyncToken {
			return buildToken(mockData, onResults_mockSend, delay);
		}
		
		public function createMockFault( fault:Fault = null, delay:int = 10 ):AsyncToken {
			return buildToken(fault, onFault_mockSend, delay);
		}
		
		// ******************************************************************************
		//  Cursor Methods
		// ******************************************************************************
		
		
		protected function onResults_mockSend( event:TimerEvent ):void
		{
			stopCursor();
			
			var token   : AsyncToken = releaseToken(event, onResults_mockSend);
			var mockData: Object     = ( token.data ) ? token.data : new Object();
			
			token.mx_internal::applyResult(ResultEvent.createEvent(mockData, token));
		}
		
		
		protected function onFault_mockSend( event:TimerEvent ):void
		{
			stopCursor();
			
			var token : AsyncToken = releaseToken(event, onFault_mockSend);
			var fault : Fault      = ( token.data ) ? token.data : null;
			
			token.mx_internal::applyFault(FaultEvent.createEvent(fault, token));
		}
		
		
		// ******************************************************************************
		//  Token Construction/Cleanup
		// ******************************************************************************
		
		
		private function buildToken(data:Object, callback:Function, delay:int=10):AsyncToken {
			startCursor();
			
			var token: AsyncToken = new AsyncToken();
			var timer: Timer      = new Timer( delay, 1 );
			
				timer.addEventListener( TimerEvent.TIMER_COMPLETE, callback );
				timer.start();
				
				token.data     = data;
				calls[ timer ] = token;
			
			return token;
		}
		
		private function releaseToken(event:TimerEvent, callBack:Function):AsyncToken {
			var token : AsyncToken = null; 
			var timer : Timer      = Timer( event.target );
			
			if (timer != null) {
				timer.removeEventListener( TimerEvent.TIMER_COMPLETE, callBack );
			
				token = calls[ timer ];
				delete calls[ timer ];
			}
			
			return token;
		}
		
		// ******************************************************************************
		//  Cursor Methods
		// ******************************************************************************
		
		private function startCursor():void {
			if( showBusyCursor ) {
				CursorManager.setBusyCursor();
			}			
		}
		
		private function stopCursor():void {
			if( showBusyCursor )
			{
				CursorManager.removeBusyCursor();
			}			
		}

		// ******************************************************************************
		//  Cache for tokens and callbacks
		// ******************************************************************************
				
		private var calls:Dictionary = new Dictionary();
	}
}