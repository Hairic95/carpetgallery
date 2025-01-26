@tool

extends Node

@export_tool_button("unwrap", "Callable")
var unwrap = _unwrap_corpora

@export var corpus_resource: CorpusResource

var corpus_markovs: Dictionary[String, MarkovChainGenerator]

@export_multiline var dialogue_unwrapped: String = ""
@export_multiline var themes_unwrapped: String = ""

func _ready():
	_wrap_corpora()

func _unwrap_corpora():
	dialogue_unwrapped = ""
	themes_unwrapped = ""
	for dialogue in corpus_resource.dialogue_corpora:
		dialogue_unwrapped += _unwrap_corpus(dialogue)
	for theme in corpus_resource.theme_corpora:
		themes_unwrapped += _unwrap_corpus(theme)

func _unwrap_corpus(corpus: DialogueCorpus) -> String:
	var string = corpus.name + "\n"
	string += corpus.dialogues.strip_edges()
	string += "\n------\n"
	return string

func _wrap_corpora():
	corpus_resource = CorpusResource.new()
	
	var dialogue_corpora: Array[DialogueCorpus] = []
	var theme_corpora: Array[DialogueCorpus] = []
	
	for corpus in dialogue_unwrapped.split("\n------\n", false):
		dialogue_corpora.append(_wrap_corpus(corpus))
	for corpus in themes_unwrapped.split("\n------\n", false):
		theme_corpora.append(_wrap_corpus(corpus))
	
	corpus_resource.dialogue_corpora = dialogue_corpora
	corpus_resource.theme_corpora = theme_corpora

func _wrap_corpus(corpus_string: String) -> DialogueCorpus:
	var corpus = DialogueCorpus.new()
	var split = corpus_string.strip_edges().split("\n")
	corpus.name = split[0]
	corpus.dialogues = "\n".join(split.slice(1)).strip_edges()
	return corpus

func random_dialogue_corpus(rng: BetterRng) -> DialogueCorpus:
	return rng.choose(corpus_resource.dialogue_corpora)

func random_theme_corpus(rng: BetterRng) -> DialogueCorpus:
	return rng.choose(corpus_resource.theme_corpora)

func process_dialogue(dialogue: String, theme_corpus: DialogueCorpus, rng: BetterRng) -> String:
	var re = RegEx.new()
	var text = dialogue
	re.compile("theme")
	
	while re.search(text):
		text = re.sub(text, rng.choose(theme_corpus.lines))
	re.compile("THEME")
	while re.search(text):
		text = re.sub(text, rng.choose(theme_corpus.lines).to_upper())
	return text

func generate_dialogue(rng: BetterRng, theme_corpus: DialogueCorpus, markov: MarkovChainGenerator) -> String:
	return process_dialogue(markov.generate(rng), theme_corpus, rng)

func generate_room_dialogues(rng: BetterRng, count: int, theme_corpus: DialogueCorpus=null, dialogue_corpus: DialogueCorpus=null) -> PackedStringArray:
	var arr = PackedStringArray()
	if theme_corpus == null:
		theme_corpus = random_theme_corpus(rng)
	if dialogue_corpus == null:
		dialogue_corpus = random_dialogue_corpus(rng)
	
	var markov = MarkovChainGenerator.new()
	
	markov.process_corpus(dialogue_corpus.lines)
	
	for i in range(count):
		arr.append(generate_dialogue(rng, theme_corpus, markov))
		pass
	return arr
