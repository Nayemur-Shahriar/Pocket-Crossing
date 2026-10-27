class_name AndroidDiscoveryLock
extends RefCounted
## Godot 4.4+ built-in AndroidRuntime. Held only during discovery.
var lock: Object
var jni: Object
func acquire() -> void:
	release()
	if not OS.has_feature("android") or not Engine.has_singleton("AndroidRuntime") or not Engine.has_singleton("JavaClassWrapper"):return
	jni=Engine.get_singleton("JavaClassWrapper")
	var runtime: Object=Engine.get_singleton("AndroidRuntime")
	var context: Object=runtime.getApplicationContext()
	if failed() or context==null:return
	var wifi: Object=context.getSystemService("wifi")
	if failed() or wifi==null:return
	lock=wifi.createMulticastLock("PocketCrossingDiscovery")
	if failed() or lock==null:lock=null;return
	lock.setReferenceCounted(false)
	if failed():lock=null;return
	lock.acquire()
	if failed():lock=null
func failed() -> bool:
	return jni!=null and jni.get_exception()!=null
func release() -> void:
	if lock!=null:
		var held: bool=lock.isHeld()
		if not failed() and held:lock.release();failed()
	lock=null
