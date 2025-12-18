extends Node3D
class_name WeaponAmmoComponent

@export var ammo_in_clip: int = 12
@export var clip_size: int = 12


func has_rounds(count: int = 1) -> bool:
	print("[WeaponAmmoComponent] has_rounds? needed:", count, "in_clip:", ammo_in_clip)
	return ammo_in_clip >= count


func consume_rounds(count: int = 1) -> bool:
	print("[WeaponAmmoComponent] consume_rounds request:", count)
	if not has_rounds(count):
		print("[WeaponAmmoComponent] consume_rounds failed: not enough ammo")
		return false
	var before := ammo_in_clip
	ammo_in_clip = max(ammo_in_clip - count, 0)
	print("[WeaponAmmoComponent] consume_rounds success:", before, "->", ammo_in_clip)
	return true


func reload_full() -> void:
	print("[WeaponAmmoComponent] reload_full:", ammo_in_clip, "->", clip_size)
	ammo_in_clip = clip_size
