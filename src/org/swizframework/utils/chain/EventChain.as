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

package org.swizframework.utils.chain
{
	import flash.events.Event;
	import flash.events.IEventDispatcher;
	
	public class EventChain extends BaseCompositeChain
	{
		// ========================================
		// protected properties
		// ========================================

		/**
		 * Backing variable for <code>dispatcher</code> getter/setter.
		 */
		protected var _dispatcher:IEventDispatcher;
		
		// ========================================
		// public properties
		// ========================================

		/**
		 * Target Event dispatcher.
		 */
		public function get dispatcher():IEventDispatcher
		{
			return _dispatcher;
		}
		
		public function set dispatcher( value:IEventDispatcher ):void
		{
			_dispatcher = value;
		}
		
		// ========================================
		// constructor
		// ========================================

		/**
		 * Constructor.
		 */
		public function EventChain( dispatcher:IEventDispatcher, mode:String = ChainType.SEQUENCE, stopOnError:Boolean = true )
		{
			super( mode, stopOnError );
			
			this.dispatcher = dispatcher;
		}
		
		// ========================================
		// public methods
		// ========================================
		
		/**
		 * Add an EventChainStep to this EventChain.
		 */
		public function addEvent( event:EventChainStep ):EventChain
		{
			addStep( event );
			return this;
		}
		
		/**
		 * @inheritDoc
		 */
		override public function doProceed():void
		{
			if( currentStep is EventChainStep )
				EventChainStep( currentStep ).dispatcher ||= dispatcher;
			
			super.doProceed();
		}
		
		// ========================================
		// Static Builder Method
		// ========================================
		
		/**
		 * Utility method to construct an eventChain and auto-add the specified events; added to the chain in
		 * the order listed in the events[].
		 * 
		 * <p>The IChain instance has not been "started".</p>
		 *  
		 * @param events Array of Event instances
		 * @param dispatcher IEventDispatcher, typically this is the Swiz dispatcher
		 * @param mode String SEQUENCE or PARALLEL
		 * @param stopOnError 
		 * @return IChain
		 */
		static public function createEventChain(events:Array, dispatcher:IEventDispatcher, mode:String = ChainType.SEQUENCE, stopOnError:Boolean = true):IChain {
			var chain : IChain = new EventChain(dispatcher,mode,stopOnError);
				
				for each (var it:Event in events) {
					if (it == null) continue;
					chain.addStep( new EventChainStep( it ) );
				}
			
			return chain;
		}
	}
}
