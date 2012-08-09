package frameworks.slim.components
{
	import spark.components.Button;
	
	public class CircularButton extends Button
	{
		/**
		 * Constructor
		 */
		public function CircularButton()
		{
			super();
		}
		
		/**
		 * @private
		 */
		override protected function measure():void{
			measuredWidth = 86;
			measuredHeight = 86;
		}
		
	}
}