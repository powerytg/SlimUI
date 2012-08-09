package frameworks.slim.components
{
	import spark.components.supportClasses.SkinnableComponent;
	import spark.core.IDisplayText;
	
	public class NumericLabel extends SkinnableComponent
	{
		/**
		 * @public
		 */
		[SkinPart]
		public var labelDisplay:IDisplayText;
		
		/**
		 * @private
		 */
		private var _text:String;

		/**
		 * @public
		 */
		[Bindable]
		public function get text():String
		{
			return _text;
		}

		/**
		 * @private
		 */
		public function set text(value:String):void
		{
			_text = value;
			if(labelDisplay){
				labelDisplay.text = value;
				invalidateDisplayList();
			}
		}

		
		/**
		 * Constructor
		 */
		public function NumericLabel()
		{
			super();
		}
		
		/**
		 * @private
		 */
		override protected function measure():void{
			super.measure();
			measuredWidth = 34;
			measuredHeight = 35;
		}
	}
}