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

package org.swizframework.metadata
{
	import flash.events.Event;
	import flash.utils.getQualifiedClassName;
	
	import mx.rpc.AsyncToken;
	
	import org.swizframework.reflection.MetadataHostMethod;
	import org.swizframework.reflection.MethodParameter;
	import org.swizframework.utils.PropertyUtils;
	import org.swizframework.utils.async.AsyncTokenOperation;
	import org.swizframework.utils.async.IAsynchronousEvent;
	import org.swizframework.utils.async.IAsynchronousOperation;
	
	/**
	 * Represents a deferred request for mediation.
	 */
	public class Mediator
	{
		// ========================================
		// protected properties
		// ========================================
		
		/**
		 * Backing variable for <code>metadata</code> property.
		 */
		protected var _metadataTag:MediateMetadataTag;
		
		/**
		 * Backing variable for <code>method</code> property.
		 */
		protected var _method:Function;
		
		/**
		 * Backing variable for <code>eventClass</code> property.
		 */
		protected var _eventClass:Class;
		
		// ========================================
		// public properties
		// ========================================
		
		/**
		 * The corresponding [Mediate] tag.
		 */
		public function get metadataTag():MediateMetadataTag
		{
			return _metadataTag;
		}
		
		/**
		 * The function decorated with the [Mediate] tag.
		 */
		public function get method():Function
		{
			return _method;
		}
		
		/**
		 * The Event class associated with the [Mediate] tag's event type expression (if applicable).
		 */
		public function get eventClass():Class
		{
			return _eventClass;
		}
		
		// ========================================
		// constructor
		// ========================================
		
		/**
		 * Constructor
		 */
		public function Mediator( metadataTag:MediateMetadataTag, method:Function, eventClass:Class )
		{
			_metadataTag = metadataTag;
			_method = method;
			_eventClass = eventClass;
		}
		
		// ========================================
		// public methods
		// ========================================
		
		/**
		 * Mediate
		 *
		 * @param event The Event to mediate.
		 */
		public function mediate( event:Event ):void
		{
			// ignore if the event types do not match
			if( ( eventClass != null ) && ! ( event is eventClass ) )
				return;
			
			var result:* = null;
			
			if( metadataTag.properties != null )
			{
				if( validateEvent( event, metadataTag.properties ) )
					result = method.apply( null, getEventArgs( event, metadataTag.properties ) );
			}
			else if( getRequiredParameterCount() <= 1 )
			{
				if( ( getParameterCount() > 0 ) && ( event is getParameterType( 0 ) ) )
					result = method.apply( null, [ event ] );
				else
					result = method.apply();
			}
			else
			{
				throw new Error( "Unable to mediate event: " + metadataTag.host.name + "() requires " + getRequiredParameterCount() + " parameters, and no properties were specified." );
			}
			
			if ( event is IAsynchronousEvent )
			{
				if( result is IAsynchronousOperation )
					IAsynchronousEvent( event ).step.addAsynchronousOperation( result as IAsynchronousOperation );
				else if( result is AsyncToken )
					IAsynchronousEvent( event ).step.addAsynchronousOperation( new AsyncTokenOperation( result as AsyncToken ) );
			}
			
			if( metadataTag.stopPropagation )
				event.stopPropagation();
			
			if( metadataTag.stopImmediatePropagation )
				event.stopImmediatePropagation();
		}
		
		// ========================================
		// protected methods
		// ========================================
		
		/**
		 * Validate Event
		 *
		 * Evalutes an Event to ensure it has all of the required properties specified in the [Mediate] tag, if applicable.
		 *
		 * @param event The Event to validate.
		 * @param properties The required properties specified in the [Mediate] tag.
		 * @returns A Boolean value indicating whether the event has all of the required properties specified in the [Mediate] tag.
		 */
		protected function validateEvent( event:Event, properties:Array ):Boolean
		{
			for each( var property:String in properties )
			{
				if( ! ( property in event ) )
					throw new Error(  "Unable to mediate event: " + property + " does not exist as a property of " + getQualifiedClassName( event ) + "." );
			}
			
			return true;
		}
		
		/**
		 * Get Event Arguments
		 *
		 * @param event
		 * @param properties
		 */
		protected function getEventArgs( event:Event, properties:Array ):Array
		{
			var args:Array = [];
			
			for each( var property:String in properties ) {
				// Caution, the property may be a chain; e.g. "node.data.serialNumber"
				
				args[ args.length ] = PropertyUtils.getChainValue(event, property);
			}
			
			return args;
		}
		
		/**
		 * Get Parameter Count
		 *
		 * @returns The number of parameters for the mediated method.
		 */
		protected function getParameterCount():int
		{
			return ( metadataTag.host as MetadataHostMethod ).parameters.length;
		}
		
		/**
		 * Get Required Parameter Count
		 *
		 * @returns The number of required parameters for the mediated method.
		 */
		protected function getRequiredParameterCount():int
		{
			var requiredParameterCount:int = 0;
			
			var parameters:Array = ( metadataTag.host as MetadataHostMethod ).parameters;
			for each( var parameter:MethodParameter in parameters )
			{
				if( parameter.optional )
					break;
				
				requiredParameterCount++;
			}
			
			return requiredParameterCount;
		}
		
		/**
		 * Get Parameter Type
		 *
		 * @param parameterIndex The index of parameter of the mediated method.
		 * @returns The type for the specified parameter.
		 */
		protected function getParameterType( parameterIndex:int ):Class
		{
			var parameters:Array = ( metadataTag.host as MetadataHostMethod ).parameters;
			
			if( parameterIndex < parameters.length )
				return ( parameters[ parameterIndex ] as MethodParameter ).type;
			
			return null;
		}
	}
}