package frameworks.slim.events
{
	import flash.events.Event;
	
	public class SwitchEvent extends Event
	{
		/**
		 * @public
		 */
		public static const CHANGE:String = "change";
		
		/**
		 * @public
		 */
		public var newValue:Boolean;
		
		/**
		 * Constructor
		 */
		public function SwitchEvent(type:String, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			super(type, bubbles, cancelable);
		}
	}
}