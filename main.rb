require 'tty-prompt'

Word = Struct.new(
  :to_s,
  :is_verb?,
  :is_article?,
  :confidence_effect, # multiplier
)

DEFINITELY = Word.new("definitely", false, false, 1)
PROBABLY = Word.new("probably", false, false, 0.5)
MAYBE = Word.new("maybe", false, false, 0.25)
NOT = Word.new("not", false, false, -1)
NO = Word.new("no", false, true, -1)
AINT = Word.new("ain't", true, false, -1)
AM = Word.new("am", true, false, 1)
A = Word.new("a", false, true, 1)

WORDS = [DEFINITELY, PROBABLY, MAYBE, NOT, NO, AINT, AM, A]

class UserError < StandardError
end

def friendly_sentence(sentence)
  (["I"] + sentence.map(&:to_s) + ["hacker"]).join(" ")
end

def check_grammar(sentence)
  unless sentence.count(&:is_verb?) == 1
    raise UserError, "Sentence must contain exactly one verb"
  end

  unless sentence.last.is_article?
    raise UserError, "Sentence must end with an article"
  end

  unless sentence.count(&:is_article?) == 1
    raise UserError, "Sentence must contain exactly one article"
  end
end

def basic_confidence(sentence)
  sentence.reverse.map(&:confidence_effect).reduce(1, :*)
end

def friendly_confidence(confidence)
  descriptor =
    case
    when confidence == 1
      "definitely"
    when confidence == -1
      "definitely not"
    when confidence.negative?
      "possibly"
    else
      "probably"
    end

  percentage = ((confidence + 1) * 50).round.to_s + "%"

  "#{percentage}: #{descriptor} a hacker"
end

def basic_semantic_enforcement(sentence)
  confidence = basic_confidence sentence
  puts "Basic semantic enforcement: #{friendly_confidence confidence}"
  sleep 1

  if confidence == -1
    # Insert "not" after verb
    transformed_sentence = []

    sentence.each do |word|
      transformed_sentence << word
      if word.is_verb?
        transformed_sentence << NOT
      end
    end

    puts "Basic semantic enforcement: Rejecting claim; correcting sentence to:"
    sleep 1
    puts "  #{friendly_sentence transformed_sentence}"

    transformed_sentence
  else
    sentence
  end
end

# Replaces "ain't no" with "am no"
def advanced_semantic_validation(sentence)
  transformed_sentence = []

  sentence.each do |word|
    if word == NO && transformed_sentence.last == AINT
      puts "Advanced semantic validation: Slang double negative detected; interpreting as negative"
      transformed_sentence.pop
      transformed_sentence << AM
      sleep 1
    end

    transformed_sentence << word
  end

  basic_confidence transformed_sentence
end

def run_system(sentence)
  puts "Input: #{friendly_sentence sentence}"
  sleep 1
  check_grammar(sentence)
  puts "Grammar check: OK"
  sleep 1
  sentence = basic_semantic_enforcement sentence
  sleep 1
  confidence = advanced_semantic_validation sentence
  puts "Advanced semantic validation: #{friendly_confidence confidence}"
  sleep 1
  if confidence == -1
    puts "Access granted"
  else
    puts "Access denied"
  end
rescue UserError => e
  puts "Grammar check: #{e.message}"
end

def ask_sentence
  sentence = []
  prompt = TTY::Prompt.new

  loop do
    available_words = WORDS - sentence

    word_options = available_words
      .map { |word| [word.to_s, word] }
      .to_h

    options = word_options.merge({
      "[Finish]" => :finish,
      "[Reset]" => :reset,
    })

    action = prompt.select(
      friendly_sentence(sentence),
      options,
      per_page: options.count,
      quiet: true,
    )

    case action
    when :finish
      return sentence
    when :reset
      sentence = []
    else
      sentence << action
    end
  end
end

run_system ask_sentence
