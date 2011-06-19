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
	import org.swizframework.utils.async.AsynchronousChainOperation;
	import org.swizframework.utils.async.IAsynchronousOperation;

	public class CommandChain extends BaseCompositeChain
	{
		// ========================================
		// constructor
		// ========================================

		/**
		 * Constructor.
		 */
		public function CommandChain( mode:String = ChainType.SEQUENCE, stopOnError:Boolean = true )
		{
			super( mode, stopOnError );
		}
		
		// ========================================
		// public methods
		// ========================================
		
		/**
		 * Add an CommandChainStep to this EventChain.
		 */
		public function addCommand( command:CommandChainStep ):CommandChain
		{
			addStep( command );
			return this;
		}
		
		/**
		 * @inheritDoc
		 */
		override public function doProceed():void
		{
			if( currentStep is CommandChainStep )
				CommandChainStep( currentStep ).doProceed();
			else
				super.doProceed();
		}
		
		// ========================================
		// Static Builder Method
		// ========================================
		
		/**
		 * Utility method to construct an CommandChain and auto-add the specified functions or commands; added to the chain in
		 * the order listed in the commands[] or functions[].
		 * 
		 * <p>The IChain instance has not been "started".</p>
		 *  
		 * @param events Array of Command instances or Function references (may be mixed)
		 * @param mode String SEQUENCE or PARALLEL
		 * @param stopOnError 
		 * @return IChain
		 */
		static public function createChain(sequence:Array, mode:String = ChainType.SEQUENCE, stopOnError:Boolean = true):IChain {
			var chain : IChain = new CommandChain(mode,stopOnError);
			
			for each (var step:* in sequence) {
				
				step= (step is Function) 	? new AsyncCommandChainStep( step as Function ) :
					  (step is IChainStep)	? step											: null;
				
				if (step != null) 
					chain.addStep( step );
			}
			
			return chain;
		}
		
		/**
		 * Utility method to construct a CommandChain, start it, and wrap it in an AsynchronousChainOperation.
		 * 
		 * <p>The IChain instance has not been "started".</p>
		 *  
		 * @param events Array of Command instances or Function references (may be mixed)
		 * @param mode String SEQUENCE or PARALLEL
		 * @param stopOnError 
		 * @return IAsynchronousOperation
		 */
		static public function createAsyncOperation(sequence:Array, mode:String = ChainType.SEQUENCE, stopOnError:Boolean = true):IAsynchronousOperation {
			var chain : IChain = CommandChain.createChain(sequence, mode, stopOnError);
			
			return new AsynchronousChainOperation( chain.start() );
		}		
	}
}