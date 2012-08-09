package frameworks.slim.skins
{
	import flash.display.Bitmap;
	
	import spark.skins.mobile.supportClasses.MobileSkin;
	
	public class HSliderTrackSkin extends MobileSkin
	{
		/**
		 * @private
		 */
		[Embed('images/SliderTrack.png')]
		private var trackFace:Class;

		/**
		 * @private
		 */
		private var trackBitmap:Bitmap = new trackFace();
		
		/**
		 * Constructor
		 */
		public function HSliderTrackSkin()
		{
			super();
		}
		
		/**
		 * @private
		 */
		override protected function measure():void{
			measuredHeight = 15;
		}
		
		/**
		 *  @private 
		 */ 
		override protected function drawBackground(unscaledWidth:Number, unscaledHeight:Number):void
		{
			graphics.clear();
			graphics.beginBitmapFill(trackBitmap.bitmapData);
			graphics.drawRoundRect(40, 0, unscaledWidth - 80, unscaledHeight, 15, 15);
			graphics.endFill();
		}

	}
}