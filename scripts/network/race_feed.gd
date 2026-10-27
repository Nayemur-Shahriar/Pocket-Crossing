class_name RaceFeed
extends RefCounted
var queue: Array[Dictionary]=[]
var current:=""
var left:=0.0
func push(text: String, priority: bool=false) -> void:
	var item:={"text":text.left(100)}
	if priority:queue.push_front(item);left=0
	else:queue.append(item)
	while queue.size()>8:queue.pop_back()
func tick(delta: float) -> void:
	left=maxf(0,left-delta)
	if left<=0:
		current=""
		if not queue.is_empty():current=queue.pop_front().text;left=3.0
func clear() -> void:queue.clear();current="";left=0
