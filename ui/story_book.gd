class_name StoryBook
extends ParchmentView
## The stranger's book: a verse chronicle of the escape through Shakespeare's London, one
## leaf per act, revealed as the journey reaches it. Separate from puzzle scrolls and letters.

const ACTS := ["study", "street", "sewer", "ripper", "courtyard", "nursery", "metropolitan"]
const TITLES := {
	"study": "ACT I\nShakespeare’s Study", "street": "ACT II\nThe Borrowed Stage",
	"sewer": "ACT III\nBeneath the Verse", "ripper": "ACT IV\nThe Whitechapel Watch",
	"courtyard": "ACT V\nThe House of Empty Cradles", "nursery": "ACT VI\nThe Firmament of Lost Names",
	"metropolitan": "ACT VII\nThe First Underground"}
## What the narrator speaks as each act begins. Every stanza ends on a question.
const VOICES := {
	"study": "Wake, stranger, in a room that is not thine;\nThe quill is his, the candle, every line.\nThou art no poet, only one who reads,\nAnd every page here hides the key it needs.\nFour tales lie scattered, waiting to be told —\nCanst thou unlock the door his stories hold?",
	"street": "Step through the paint into his sunlit town,\nWhere every player waits in borrowed gown.\nThey cannot move until their scene is right,\nAnd children sing a rhyme of stone and night.\nThe bridge still stands, the river runs so fair —\nBut who hath walled a lady living there?",
	"sewer": "The bridge is fallen, as the song foretold,\nAnd thou art swallowed where the waters cold\nRun black with plague beneath the painted town,\nWhere beakèd men walk slow, and rats wear crown.\nRed crosses mark the houses doomed to die —\nWhose doors shall bleed before thou climb’st on high?",
	"ripper": "Now rise into a later, darker age,\nWhere fog is ink and every street a page.\nWhen gaslight gutters, footsteps start to fall;\nA shape in a tall hat slides along the wall.\nWatch where he stops, and trace his path again —\nWho walks the fog, and who shall give his name to men?",
	"courtyard": "Up these back stairs a colder memory waits,\nA house that took in children at its gates.\nThe cradles rock, though no one lies within;\nThe bells above them ring for what hath been.\nListen, and the room will hum its song —\nBut which bell tolls for those who stayed too long?",
	"nursery": "Behind the shelves the ceiling turns to sky,\nWhere stone-cut keepers count the stars on high.\nSome look before them, some behind their back,\nAnd one true road is written on the black.\nThe floor remembers what the heavens name —\nWhich stars will light thy road, and which put out the flame?",
	"metropolitan": "Beneath it all, the city built a train,\nThe last road out of London’s ancient pain.\nThe engine sleeps; its iron heart is cold;\nMend it, and let the wheels be swift and bold.\nThe tunnel’s dark, the whistle far away —\nWilt thou escape, or stay within his play?"}
const PAGES := {
	"study": "I woke beside a stranger’s desk and pen;\nThe name upon the pages was not mine.\nThis little book lay open in my hand,\nIts first words: “Reader, thou must find the line.”\nI am not Shakespeare. I am one who reads,\nLocked in the room where all his plays were born.\nA dial, a glass, a feast, two lovers’ lamps —\nEach holds a letter. Four, and I am gone.\nThe door asks for a word that all men cry\nWhen walls close in. I think I know it well.\nBeyond, a painting of a sunny town.\nWhat waits inside it, only paint can tell.",
	"street": "The paint gave way, and London took me in,\nA London built of his remembered plays.\nThe lovers stood with empty, reaching hands;\nThe witches stirred and sang of other days.\nI gave each player what the playbill named,\nI fed the pot the words the witches spoke,\nI set the day that Caesar should have feared —\nAnd heard, beneath the bridge, a girl who woke.\nThe masons walled her in to make it stand.\nThe song was never meant for children’s play.\nI stepped upon her stones. They would not hold.\nAnd London Bridge, like London, fell away.",
	"sewer": "I fell below the verse, into the dark,\nWhere London buries what it will not name.\nThe rats grow fat on plague; the dead lie sewn;\nThe beakèd doctors watch, and feel no shame.\nA warrant bade me mark the houses twain\nWhose feud once cursed the town from end to end.\nI painted crosses on the rose and ivy,\nAnd iron rose, and showed a ladder’s bend.\nI climbed. The air grew colder, and the years\nRan forward to a century of smoke.\nI did not choose to walk into that fog.\nI only know that something there awoke.",
	"ripper": "I rose in Whitechapel, where lamps burn low.\nA constable keeps watch but cannot see\nThe man who moves only when gaslight dies,\nAnd stops, and waits, and moves on silently.\nHis figure is the city’s fear made flesh,\nNot any man the records ever knew.\nI must follow him from post to post,\nAnd mark each stop, and learn his circuit true.\nThen on the constable’s old street plan\nI’ll draw his road and file it, stop by stop.\nIf I lose him in the fog, I wait,\nAnd watch the lamps, and pray the lamps don’t drop.",
	"courtyard": "The constable unbarred the rear court’s gate.\nA stair led up into another year,\nA house in Reading, where a woman took\nThe infants paid into her keeping here.\nI will not tell what records tell of her.\nThe room tells it: the cradles, and the cold.\nFour beds, four woven hoops, four hanging bells;\nA music box that sings what it was told.\nI must hear its tune and ring it back\nUpon the bells that hang above each bed.\nThe shelves behind them do not touch the wall.\nI think the house has hidden more than dead.",
	"nursery": "The shelves slid back. The house was larger than\nThe house could be. Its ceiling was the sky.\nSix shapes of stars, four keepers carved in stone,\nAnd laws of sight: some forward, some awry.\nI must count stars and weigh what each one sees,\nAnd turn the keepers where their gazes go,\nThen read the marks carved in their stony backs,\nAnd walk that order on the floor below.\nBeyond an iron arch I hear a sound:\nAn engine breathing somewhere underground.\nThe city has one passage left for me.\nIt runs on rails, and not by any sea.",
	"metropolitan": "Below the stars, the first of all the trains:\nThe Metropolitan, in soot and brick.\nIts feed is leaking and its union cracked,\nIts gauges dead, its brake held fast and thick.\nThe driver’s book explains the fire and steam,\nThe relief valve, and what the needles show.\nWhen both agree, I free the brake and board,\nAnd pull the green, and let the engine go.\nThe platform is not freedom. Motion is.\nThe tunnel mouth is black as any page.\nI came in as a reader, not a player.\nI mean to leave before the final stage."}

var run: StudyState
var page: int = 0


func _ready() -> void:
	style = "book"
	page = clampi(page, 0, ACTS.find(run.act()))
	title = TITLES[ACTS[page]].replace("\n", " · ")
	body = PAGES[ACTS[page]]
	if ACTS[page] == "ripper":
		var places: Array[String] = []
		for key: String in run.watch_seen:
			places.append(tr("LANDMARK_" + key))
		places.sort()
		body += "\n\nSeen so far (in no order): " + (", ".join(places) if not places.is_empty() else "none yet")
	close_label = "Close the Book"
	super._ready()
	var navigation := HBoxContainer.new()
	navigation.alignment = BoxContainer.ALIGNMENT_CENTER
	navigation.add_theme_constant_override("separation", 60)
	close_button.get_parent().add_child(navigation)
	close_button.get_parent().move_child(navigation, close_button.get_index())
	for step: int in [-1, 1]:
		var button: Button = TitlePage.entry("‹ Previous Leaf" if step < 0 else "Next Leaf ›", _turn.bind(step), 19)
		button.add_theme_color_override("font_color", Color("d9c49a"))
		for state_name: String in ["font_hover_color", "font_focus_color"]:
			button.add_theme_color_override(state_name, Color("fff1cf"))
		button.add_theme_color_override("font_disabled_color", Color("978d79"))
		button.disabled = page + step < 0 or page + step > ACTS.find(run.act())
		button.modulate.a = 0.6 if button.disabled else 1.0
		navigation.add_child(button)


func _turn(step: int) -> void:
	page += step
	for child: Node in get_children():
		remove_child(child)
		child.queue_free()
	_ready()
