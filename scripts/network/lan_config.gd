class_name LanConfig
extends Resource
@export_range(1024,65535) var game_port:=42420
@export_range(1024,65535) var discovery_port:=42421
@export_range(2,4) var max_players:=4
@export_range(10,30) var snapshot_hz:=10
@export_range(5,20) var timeout_seconds:=10.0
@export_range(1,5) var hazard_correction_hz:=2.0
@export var content_revision:="m14-stability-2"
var protocol:="pocket-crossing-lan-1"
func content_version() -> String:return protocol+"/"+content_revision
