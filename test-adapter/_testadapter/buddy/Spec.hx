package _testadapter.buddy;

import haxe.PosInfos;

class Spec extends buddy.BuddySuite.Spec {
	public var pos:PosInfos;

	public function new(description:String, pos:PosInfos) {
		this.pos = pos;
		super(description, pos.fileName);
	}
}
