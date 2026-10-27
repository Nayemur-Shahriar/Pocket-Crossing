extends Node
var count:=0
var failed:=0
func scan(path: String) -> void:
	for file in DirAccess.get_files_at(path):
		if file.ends_with(".gd") or file.ends_with(".tres") or file.ends_with(".tscn"):
			count+=1
			if load(path+"/"+file)==null:failed+=1;push_error("FAIL resource "+path+"/"+file)
	for folder in DirAccess.get_directories_at(path):
		if not folder.begins_with("."):scan(path+"/"+folder)
func _ready() -> void:
	scan("res://")
	print("RESOURCE LOAD RESULTS: ",count-failed," passed, ",failed," failed")
	get_tree().quit(failed)
