package frameworks.slim.activity
{
	import flash.events.MouseEvent;
	
	import frameworks.slim.activity.events.ActivityContainerEvent;
	import frameworks.slim.activity.events.ActivityDeckEvent;
	
	import spark.components.Group;
	
	/**
	 * Selected by the deck
	 */
	[Event(name="activitied", type="frameworks.slim.activity.events.ActivityContainerEvent")]
	
	/**
	 * De-selected by the deck
	 */
	[Event(name="deactivitied", type="frameworks.slim.activity.events.ActivityContainerEvent")]
	
	/**
	 * After being resized
	 */
	[Event(name="resizeComplete", type="frameworks.slim.activity.events.ActivityContainerEvent")]
	
	/**
	 * An CrescentUI Activity is based off a skinnable container, with additional capability of being embedded into an
	 * ActivityDeck.
	 * 
	 * Usually only one Activity is "active" at a time, while the rest of them fall into the inactive mode. Under this state, 
	 * child elements are hidden and deattached from the Activity's display list, leaving a fake proxy bitmap on top.
	 */
	public class Activity extends Group
	{
		/**
		 * @private
		 */
		private var _active:Boolean;

		/**
		 * @private
		 */
		[Bindable]
		public function get active():Boolean
		{
			return _active;
		}

		/**
		 * @private
		 */
		public function set active(value:Boolean):void
		{
			if(_active != value){
				_active = value;
				
				if(_active){
					dispatchEvent(new ActivityContainerEvent(ActivityContainerEvent.ACTIVITIED));
					onActivited();
				}
				else{
					dispatchEvent(new ActivityContainerEvent(ActivityContainerEvent.DEACTIVITIED));
					onDeactivited();
				}
			}
		}

		
		/**
		 * Constructor
		 */
		public function Activity()
		{
			super();
		}
		
		/**
		 * @private
		 */
		protected function close(evt:MouseEvent = null):void{
			var event:ActivityContainerEvent = new ActivityContainerEvent(ActivityContainerEvent.CLOSE_ACTIVITY, true);
			event.activity = this;
			dispatchEvent(event);
		}
		
		/**
		 * @private
		 */
		protected function onActivited():void{
		}
		
		/**
		 * @private
		 */
		protected function onDeactivited():void{
		}
		
		/**
		 * @public
		 */
		public function destroy():void{
		}
		
	}
}