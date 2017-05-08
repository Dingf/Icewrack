package
{
	import flash.display.MovieClip;
	import flash.utils.describeType;
	
	public class ScaleformFileSave extends MovieClip
	{
		public var gameAPI:Object;
		public var globals:Object;
		public var elementName:String;
		
		private var filename:String = "";
		private var saveData:String;
		
		public function ScaleformFileSave()
		{
			// constructor code
		}
		
		public function onLoaded() : void
		{
			visible = true;
			
			gameAPI.SubscribeToGameEvent("iw_sfs_save_start", OnSaveStart);
			gameAPI.SubscribeToGameEvent("iw_sfs_save_data", OnSaveData);
			gameAPI.SubscribeToGameEvent("iw_sfs_save_end", OnSaveEnd);
			
			trace("SFS loaded");
		}
		
		private static function ParseKVString(kvString:String) : Object
		{
			var kvData : Object = {}
			var objStack = new Vector.<Object>();
			objStack.push(kvData);
			
			var kvTokens = kvString.split("\t");
			var currentObj = objStack[objStack.length-1];
			for (var i = 0; i < kvTokens.length; i++)
			{
				var s1 = kvTokens[i];
				if (s1 == "}")
				{
					objStack.pop();
					currentObj = objStack[objStack.length-1];
				}
				else
				{
					var s2 = kvTokens[++i];
					if (s2 == "{")
					{
						var newObj = {}
						currentObj[s1] = newObj
						currentObj = newObj
						objStack.push(newObj);
					}
					else if (s2 != "null")
					{
						currentObj[s1] = s2
					}
					else
					{
						currentObj[s1] = " "
					}
				}
			}
			return kvData;
		}
		
		public function OnSaveStart(args:Object) : void
		{
			trace("SFS start");
			if (args != null)
			{
				filename = args.filename;
				saveData = "";
			}
		}
		
		public function OnSaveData(args:Object) : void
		{
			if ((args != null) && (filename))
			{
				saveData = saveData + args.data;
			}
		}
		
		public function OnSaveEnd(args:Object) : void
		{
			trace("SFS end");
			trace(saveData);
			globals.GameInterface.SaveKVFile(ParseKVString(saveData), filename, "IcewrackSaveFile", "");
		}
	}
}