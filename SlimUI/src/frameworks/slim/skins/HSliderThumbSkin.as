package frameworks.slim.skins
{
	import spark.skins.mobile.ButtonSkin;
	
	public class HSliderThumbSkin extends ButtonSkin
	{
		/**
		 * Up skin
		 */
		[Embed(source="images/SliderThumb.png")]
		protected var upFace:Class;
		
		/**
		 * Down skin
		 */
		[Embed(source="images/SliderThumbDown.png")]
		protected var downFace:Class;
		
		/**
		 * Constructor
		 */
		public function HSliderThumbSkin()
		{
			super();
			upBorderSkin = downFace;
			downBorderSkin = downFace;
		}
		
		/**
		 * @private
		 */
		override protected function drawBackground(unscaledWidth:Number, unscaledHeight:Number):void
		{
			// Draw nothing
		}

		/**
		 * @private
		 */
		override protected function measure():void{
			measuredWidth = 80;
			measuredHeight = 80;
		}
		
	}
}