class_name ChapterCatalog
extends RefCounted
## Presentation belongs to the chapter, never to the global menu.
## Future playable entries also need their gameplay loader and save routing.
const ENTRIES := [
	{"id": "london", "presentation": "manuscript", "available": true},
	{"id": "unannounced_2", "presentation": "poster", "available": false},
	{"id": "unannounced_3", "presentation": "minimal", "available": false},
]
