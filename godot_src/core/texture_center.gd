class_name texture_center extends Node

#图片中心类用于管理所有图片资源的引用，当有对象需要图片资源时，就会在这请求加载，
#然后texture_center会将该资源缓存，使用该方案可以避免图片的重复加载
#texture_center会每隔一秒检查当前图片的引用计数，如果计数为1（即只有texture_center拥有该图片），那就会考虑卸载该资源
#不过texture_center也会考虑到内存占用，如果缓存的图片数量少于设定的数量，那也不会进行资源卸载

#缓存的图像列表，键为路径，值为Texture2D
var _cached_pictures = {}

var _last_process_time = 0

const max_idle_cache_size = 120 * 1024 * 1024 #默认存储120MB的闲置数据

func _process(delta: float) -> void:
	_last_process_time += delta
	if _last_process_time < 1.0: #一秒执行一次
		return

	_last_process_time -= 1.0

	pass


#bug 需要测试
func get_picture(path : String) -> ImageTexture:
	if _cached_pictures.has(path):
		return _cached_pictures[path]

	var fpath = Utility.relative_to_full(path)
	var image = Image.new()
	var err = image.load(fpath)
	if OK != err:
		print("load picture error: ", err)
		return null

	var texture = ImageTexture.new()
	texture.set_image(image)

	_cached_pictures.set(path, texture)

	return texture
