package frameworks.slim.components
{
	import flash.events.MouseEvent;
	
	import frameworks.slim.events.SwitchEvent;
	
	import mx.events.FlexEvent;
	import mx.states.State;
	
	import spark.components.supportClasses.SkinnableComponent;
	
	/**
	 * Selected state
	 */
	[SkinState("selected")]
	
	/**
	 * Normal state
	 */
	[SkinState("normal")]
	
	/**
	 * Value change event
	 */
	[Event(name="change", type="frameworks.slim.events.SwitchEvent")]
	
	public class Switch extends SkinnableComponent
	{
		/**
		 * @private
		 */
		private var _selected:Boolean;

		/**
		 * @private
		 */
		public function get selected():Boolean
		{
			return _selected;
		}

		/**
		 * @private
		 */
		public function set selected(value:Boolean):void
		{
			if(_selected != value){
				_selected = value;
				currentState = _selected ? "selected" : "normal";
				invalidateSkinState();
				
				var e:SwitchEvent = new SwitchEvent(SwitchEvent.CHANGE);
				e.newValue = value;
				dispatchEvent(e);				
			}
		}
		
		/**
		 * Constructor
		 */
		public function Switch()
		{
			super();
			addEventListener(MouseEvent.CLICK, onClick, false, 0, true);
			addEventListener(FlexEvent.CREATION_COMPLETE, onCreationComplete, false, 0, true);
		}
		
		/**
		 * @private
		 */
		private function onCreationComplete(evt:FlexEvent):void{
			removeEventListener(FlexEvent.CREATION_COMPLETE, onCreationComplete);

		}
		
		/**
		 * @public
		 */
		override public function initialize():void{
			super.initialize();
			
			states.push(new State({name: "normal"}));
			states.push(new State({name: "selected"}));
		}
		
		/**
		 * @protected
		 */
		override protected function getCurrentSkinState():String
		{
			return _selected ? "selected" : "normal";
		} 

		/**
		 * @private
		 */
		protected function onClick(evt:MouseEvent):void{
			selected = !selected;
		}
		
	}
}