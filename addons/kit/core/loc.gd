class_name Loc
extends RefCounted

## Every text shown to the player goes through `Loc.t`. French is the source
## language; locale/<lang>.po holds the others. `seen` remembers what was
## asked for, so a test can tell which texts a play-through really showed.

## French puts a space that never breaks before these marks.
const HIGH_MARKS: Array[String] = [":", ";", "!", "?", "»", "%%"]
const NBSP := "\u00a0"

static var seen := {}


static func t(text: String) -> String:
	if text.is_empty():
		return text
	seen[text] = true
	var shown := str(TranslationServer.translate(text))
	return french_spaces(shown) if TranslationServer.get_locale().begins_with("fr") else shown


## French typography, applied when a text is shown: the space before a colon,
## a semicolon, a question or exclamation mark and a percent sign, and the
## spaces inside « quotes », become no-break spaces, so a line never starts
## with one of those marks. The source texts keep ordinary spaces.
static func french_spaces(text: String) -> String:
	var out := text.replace("« ", "«" + NBSP)
	for mark in HIGH_MARKS:
		out = out.replace(" " + mark, NBSP + mark)
	return out


## Remembers texts that will be translated later, when they are drawn.
static func mark(texts: Array) -> void:
	for text: Variant in texts:
		if str(text) != "":
			seen[str(text)] = true


## Texts asked for so far that `locale` has no translation for.
static func missing(locale: String) -> Array[String]:
	var known := {}
	var translation := TranslationServer.get_translation_object(locale)
	if translation != null:
		for message in translation.get_message_list():
			known[message] = true
	var out: Array[String] = []
	for text: String in seen:
		if not known.has(text):
			out.append(text)
	return out
