package frameworks.slim.components
{
	import flash.geom.Point;
	
	import frameworks.slim.components.supportClasses.HSliderHighlight;
	
	import spark.components.HSlider;
	
	public class HSlider extends spark.components.HSlider
	{
		/**
		 * @public
		 */
		[SkinPart]
		public var highlight:HSliderHighlight;
		
		/**
		 * Constructor
		 */
		public function HSlider()
		{
			super();
		}
		
		/**
		 *  @private
		 */
		override protected function updateSkinDisplayList():void
		{
			if (!thumb || !track)
				return;
			
			var thumbRange:Number = track.getLayoutBoundsWidth() - thumb.getLayoutBoundsWidth();
			var range:Number = maximum - minimum;
			
			// calculate new thumb position.
			var thumbPosTrackX:Number = (range > 0) ? ((pendingValue - minimum) / range) * thumbRange : 0;
			
			// convert to parent's coordinates.
			var thumbPos:Point = track.localToGlobal(new Point(thumbPosTrackX, 0));
			var thumbPosParentX:Number = thumb.parent.globalToLocal(thumbPos).x;
			
			thumb.setLayoutBoundsPosition(Math.round(thumbPosParentX), thumb.getLayoutBoundsY());
			
			// Margin the highlight
			highlight.setLayoutBoundsSize(thumbPosParentX, track.getPreferredBoundsHeight() - 2);
		}
	}
}