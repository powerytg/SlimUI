package frameworks.slim.activity.events
{
	import flash.events.Event;
	
	import frameworks.slim.activity.Activity;
	
	public class ActivityDeckEvent extends Event
	{
		/**
		 * @public
		 */
		public static const TRANSITION_BEGIN:String = "transitionBegin";
		
		/**
		 * @public
		 */
		public static const TRANSITION_END:String = "transitionEnd";

		/**
		 * @public
		 */
		public static const TRANSITION_UPDATE:String = "transitionUpdate";
		
		/**
		 * @public
		 */
		public static const ACTIVITY_CHANGED:String = "activityChanged";
		
		/**
		 * @public
		 */
		public var horizontalScrollPercentage:Number;
		
		/**
		 * @public
		 */
		public var selectedActivity:Activity;
		
		/**
		 * Constructor
		 */
		public function ActivityDeckEvent(type:String, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			super(type, bubbles, cancelable);
		}
	}
}