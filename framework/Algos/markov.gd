extends RefCounted

class_name MarkovChainGenerator

var probabilities := {}

var starting_probabilities := {}

var ngram_size := 2
var ngram_words = false

func _init(ngram_size = 1, ngram_words = true):
	self.ngram_size = ngram_size
	self.ngram_words = ngram_words

func process_corpus(corpus: PackedStringArray) -> Dictionary:
	for string in corpus:
		string = string.strip_edges()
		var list = string
		if ngram_words:
			list = string.split(" ")

		var size = len(list)
		if size <= ngram_size:
			continue
		var c := 0
		
		var start = list[0]

		
		while c + ngram_size <= size:
			var substr := ""
			for i in ngram_size:
				if ngram_words:
					substr += " "
				substr += list[c + i]
				substr = substr.strip_edges()
			if c == 0:
				if substr in starting_probabilities:
					starting_probabilities[substr] += 1
				else:
					starting_probabilities[substr] = 1
			var next: String
			if c + ngram_size < size:
				next = list[c + ngram_size]
			else:
				next = ""
			if substr in probabilities:
				var all_nexts : Dictionary = probabilities[substr]
				if next in all_nexts:
					all_nexts[next] += 1
				else:
					all_nexts[next] = 1
			else:
				probabilities[substr] = {next: 1}
			c += 1
	return probabilities

func generate(rng: BetterRng) -> String:
	if ngram_words:
		return generate_words(rng)
	return generate_characters(rng)

func generate_words(rng: BetterRng) -> String:
	var arr = rng.weighted_choice(starting_probabilities.keys(), starting_probabilities.values()).split(" ")
	var next = get_next_word(right(arr, ngram_size), rng)
	next = next.split(" ")
	arr.append_array(next)
	while next[-1]:
		next = get_next_word(right(arr, ngram_size), rng)
		next = next.split(" ")
		arr.append_array(next)

		
	return " ".join(arr)

func generate_characters(rng: BetterRng) -> String:
	var text: String = rng.weighted_choice(starting_probabilities.keys(), starting_probabilities.values())
	var next: String = get_next(text.right(ngram_size), rng)
	text += next
	while next:
		next = get_next(text.right(ngram_size), rng)
		text += next
	return text

func right(value: Variant, size: int) -> Variant:
	var arr: Array[String] = []
	var num = min(ngram_size, value.size())
	for i in range(num):
		arr.append(value[-num + i])
	return arr

func get_next(start, rng: BetterRng) -> String:
	var dict: Dictionary = probabilities[start]
	return rng.weighted_choice(dict.keys(), dict.values())

func get_next_word(start, rng: BetterRng) -> String:
	var dict: Dictionary = probabilities[" ".join(start)]
	return rng.weighted_choice(dict.keys(), dict.values())
