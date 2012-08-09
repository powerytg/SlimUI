package frameworks.slim.skins
{
	import spark.skins.mobile.ButtonSkin;
	
	/**
	 * The CircularButton is meant to be fixed size. The best resolution is 84 by 84
	 */
	public class CircularButtonSkin extends ButtonSkin
	{
		/**
		 * Up skin
		 */
		[Embed(source="images/CircularButton.png")]
		protected var upFace:Class;
		
		/**
		 * Down skin
		 */
		[Embed(source="images/CircularButtonDown.png")]
		protected var downFace:Class;
		
		/**
		 * Constructor
		 */
		public function CircularButtonSkin()
		{
			super();
			upBorderSkin = upFace;
			downBorderSkin = downFace;
		}
		
		/**
		 * @private
		 */
		override protected function drawBackground(unscaledWidth:Number, unscaledHeight:Number):void
		{
			// Draw nothing
		}
	}
}