extends Control

#region INITIAL VARIABLES

#Is the game running or not? (for stopwatch execution)
var game_running = false
var can_interact = true
#Current in game time
var cur_time = 0

var answer
var random = RandomNumberGenerator.new()
var question_number: int = 0

var number_correct_answers: int = 0

var can_negative: bool = false


#region Current Game variables
#For game difficulty
var difficulty: String = "easy"
#For game mode and calculation type
var game_mode : String = "add"
var number_of_questions: int = 0
var min_value: int = 0
var max_value: int = 0
var question_title: String = ""
var numbers: Array = [0]

var coinValueAnim : int = 0
#endregion

var diff_mult : float = 1.0
var mode_mult : float = 1.0

var accuracy: String

#region Enums
#For timer modes
enum timerModes {
	QUESTION,
	GAMEOVER
}
var timerMode := timerModes.QUESTION
#endregion


var questionIcon = preload("res://scenes/calculation/questionIcon.tscn")

@onready var lblQuestion = %LblQuestion
@onready var lblEquation = %LblEquation
@onready var answerLine = %AnswerLine
#endregion

func _ready():
	%QuestionScreen.visible = false
	%StartScreen.visible = true
	%StartScreen.modulate.a = 0
	%ResultsScreen.position.y = get_viewport().get_visible_rect().size.y
	transitionManager(%StartScreen, "modulate:a", 1, 0.25, "init")
	random.randomize()
	
	match difficulty:
		"easy": diff_mult = 1.0
		"normal": diff_mult = 1.5
		"hard": diff_mult = 2.0

	match game_mode:
		"add": mode_mult = 1.0
		"subtract": mode_mult = 1.05
		"multiply": mode_mult = 1.2
		"divide": mode_mult = 1.25

#Creates the icon questions for each question that was generated
func createQuestionIcons():
	for i in number_of_questions:
		var q = questionIcon.instantiate()
		%QuestionIcons.add_child(q)

func _physics_process(delta):
	#To increment the cur time ONLY when the game is running
	if game_running:
		cur_time += delta
	else:
		%LblCoins.text = str(coinValueAnim)
	
	#To update stopwatch Text
	var milliseconds = fmod(cur_time, 1) * 1000
	var seconds = fmod(cur_time, 60)
	var minutes = fmod(cur_time, 3600) / 60
	%Stopwatch.text =  "%01d:%02d:%03d" % [minutes, seconds, milliseconds]


#For inputs directly from PC
func _input(event):
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_KP_0:
				numberPressed(0)
			KEY_KP_1:
				numberPressed(1)
			KEY_KP_2:
				numberPressed(2)
			KEY_KP_3:
				numberPressed(3)
			KEY_KP_4:
				numberPressed(4)
			KEY_KP_5:
				numberPressed(5)
			KEY_KP_6:
				numberPressed(6)
			KEY_KP_7:
				numberPressed(7)
			KEY_KP_8:
				numberPressed(8)
			KEY_KP_9:
				numberPressed(9)
			KEY_MINUS:
				numberPressed("-")
			KEY_COMMA:
				numberPressed(".")
			KEY_PERIOD:
				numberPressed(".")
			KEY_BACKSPACE:
				backspacePressed()
			KEY_ENTER:
				donePressed()
			KEY_KP_ENTER:
				donePressed()

#To format numbers as string for equation generation
func formatNegativeNumber(number):
	var formattedNum: String
	#If number is negative, it will be formatted to (-x)
	if number >= 0:
		formattedNum = str(number)
	else:
		formattedNum = "(" + str(number) + ")"
	return formattedNum

#Generates everything related to the next question
func generateNextQuestion():
	#TITLE GENERATION
	lblQuestion.text = str(question_number) + ". " + question_title
	
	match (game_mode):
		#region Addition
		'add':
			var neg_0: bool = false
			var neg_1: bool = false
			var pos_0: bool = false
			
			for i in numbers.size():
				#region Generating variables
				match difficulty:
					'easy':
						numbers[i] = randi_range(min_value, max_value)
					
					'normal':
						var random_num = randf()
						
						if random_num < 0.15 and not neg_0:
							numbers[i] = randi_range(min_value, int(-1))
							neg_0 = true
						
						elif random_num < 0.66:
							numbers[i] = randi_range(int(0), int(100))
						
						else: 
							numbers[i] = randi_range(int(101), max_value)
					
					'hard':
						var random_num = randf()
						
						if random_num < 0.1 and not neg_0:
							numbers[i] = randi_range(min_value, int(-101))
							neg_0 = true
						
						elif random_num < 0.25 and not neg_1:
							numbers[i] = randi_range(int(-100), int(0))
							neg_1 = true
						
						elif random_num < 0.6 and not pos_0:
							numbers[i] = randi_range(int(1), int(100))
							pos_0 = true
						
						elif random_num < 0.85:
							numbers[i] = randi_range(int(101), int(250))
						
						else:
							numbers[i] = randi_range(int(251), max_value)
				#endregion
				
				#region Generating answer and equation
				if i == 0: 
					answer = numbers[i]
					# If number is negative, it will be formatted to (-x)
					var numberFormatted = formatNegativeNumber(numbers[i])
					lblEquation.text = numberFormatted
				else: 
					answer += numbers[i]
					# If number is negative, it will be formatted to (-x)
					var numberFormatted = formatNegativeNumber(numbers[i])
					lblEquation.text += " + " + numberFormatted
				#endregion
		#endregion
		
		#region Subtraction
		'subtract':
			var neg_0: bool = false
			var neg_1: bool = false
			var pos_0: bool = false
			var pos_1: bool = false
			
			for i in numbers.size():
				#region Generating variables
				match difficulty:
					'easy':
						if i == 0:
							numbers[0] = randi_range(min_value + 1, max_value)
						else: 
							numbers[i] = randi_range(min_value, int(numbers[0]))
					
					'normal':
						var random_num = randf()
						var aux = randf()
						
						# If first number, increased chances of being a greater value
						if i == 0 and aux < .66:
							numbers[i] = randi_range(int(101), max_value)
						
						# Else, it will generate a NORMAL variable
						elif random_num < .25 and not neg_0:
							numbers[i] = randi_range(min_value, int(0))
							neg_0 = true
						
						elif random_num < .7:
							numbers[i] = randi_range(int(1), int(100))
						
						else: 
							numbers[i] = randi_range(int(101), max_value)
					
					'hard':
						var random_num = randf()
						var aux = randf()
						
						# If first number, increased chances of being a greater value
						if i == 0 and aux < .33:
							numbers[i] = randi_range(int(251), max_value)
						
						# Else, it will generate a NORMAL variable
						elif random_num < .15 and not neg_0:
							numbers[i] = randi_range(min_value, int(-101))
							neg_0 = true
						
						elif random_num < .45 and not neg_1:
							numbers[i] = randi_range(int(-100), int(0))
							neg_1 = true
						
						elif random_num < .7 and not pos_0:
							numbers[i] = randi_range(int(1), int(100))
							pos_0 = true
						
						elif random_num < .85 or (random_num >= .85 and pos_1):
							numbers[i] = randi_range(int(101), int(250))
						
						elif random_num >= .85 and not pos_1: 
							numbers[i] = randi_range(int(251), max_value)
							pos_1 = true
				#endregion
				
				#region Generating answer and equation
				if i == 0: 
					answer = numbers[i]
					#If number is negative, it will be formatted to (-x)
					var numberFormatted = formatNegativeNumber(numbers[i])
					lblEquation.text = numberFormatted
				else: 
					answer -= numbers[i]
					#If number is negative, it will be formatted to (-x)
					var numberFormatted = formatNegativeNumber(numbers[i])
					lblEquation.text += " - " + numberFormatted
				#endregion
		#endregion
		
		#region Multiplication
		'multiply':
			var neg_0: bool = false
			var pos_0: bool = false
			var pos_1: bool = false
			var pos_2: bool = false
			
			for i in numbers.size():
				#region Generating variables
				match difficulty:
					'easy':
						numbers[i] = randi_range(min_value, max_value)
				
					'normal':
							var random_num = randf()
							
							if i == 1:
								if random_num < 0.2:
									numbers[i] = randi_range(-10, 1)
									
								else: 
									numbers[i] = randi_range(2, 9)
							
							else:
								if random_num < 0.1 and not pos_0:
									numbers[i] = randi_range(min_value, -1)
									neg_0 = true
								
								elif random_num < 0.8:
									numbers[i] = randi_range(0, 100)
								
								else: 
									numbers[i] = randi_range(101, max_value)
				#endregion
				
				#region Generating answer and equation
				if i == 0: 
					answer = numbers[i]
					lblEquation.text = str(numbers[0])
				else: 
					answer *= numbers[i]
					lblEquation.text += " × " + str(numbers[i])
				#endregion
		#endregion
		
		#region Division
		'divide':
			var neg_0: bool = false
			var pos_0: bool = false
			var pos_1: bool = false
			
			for i in numbers.size():
				#region Generating variables
				numbers[i] = randi_range(min_value, max_value)
				#endregion
				
				#region Generating answer and equation
				if i == 0: 
					answer = numbers[i]
					lblEquation.text = str(numbers[0])
				else: 
					answer /= numbers[i]
					lblEquation.text += " ÷ " + str(numbers[i])
				#endregion
		#endregion

#Generates a new question
func nextQuestion():
	question_number += 1
	cleanQuestion()
	generateNextQuestion()

#Clean the AnswerLine, question_title, and Equation
func cleanQuestion():
	lblEquation.text = ""
	lblQuestion.text = ""
	answerLine.text = ""

#Manager for timer
func timerManager(timerModeEnum, waitTime: float):
	timerMode = timerModeEnum
	%Timer.wait_time = waitTime
	%Timer.start()

#Base for transitions
func transitionManager(node, attribute: String, targetValue, time: float, callbackType = null):
	var tween = get_tree().create_tween()
	tween.tween_property(node, attribute, targetValue, time).set_trans(
		Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	
	match callbackType:
		null:
			pass
		
		"init":
			tween.tween_callback(func():
				%QuestionScreen.visible = true
				)
		
		"restart":
			tween.tween_callback(func():
				get_tree().reload_current_scene())
				
		"nextQuestion":
			tween.tween_callback(func():
				answerLine.add_theme_stylebox_override("read_only", load(
					"res://assets/themes/default/stylebox/inputLine/sbReadOnlyDefault.tres"))
			
				#Makes the headerquestion reappear
				transitionManager(%HeaderQuestion, "modulate:a", 1, 0.25)
				can_interact = true
				nextQuestion())
		
		"start":
			tween.tween_callback(func():
				game_running = true
				%StartScreen.queue_free())
		
		"mainMenu":
			tween.tween_callback(func():
				get_tree().change_scene_to_file("res://scenes/hub.tscn"))

#region BUTTON PRESSED functions
#When the user clicks a number
func numberPressed(kbNumber):
	if can_interact:
		if answerLine.text.length() < 6:
			answerLine.text = answerLine.text + str(kbNumber)

#When backspace button is pressed, the last digit will be erased
func backspacePressed():
	if can_interact:
		answerLine.text = answerLine.text.substr(0, answerLine.text.length() - 1)

#When button Done (next question) is pressed
func donePressed():
	if can_interact:
		can_interact = false
		
		if int(answerLine.text) == answer:
			answerLine.add_theme_stylebox_override("read_only", load(
				"res://assets/themes/default/stylebox/inputLine/sbReadOnlyCorrect.tres"))
			
			#To change the question icon of the last question
			%QuestionIcons.get_children()[question_number - 1].changeTexture("Correct")
			
			#Adds 1 in correct answers
			number_correct_answers += 1
			
		else:
			answerLine.add_theme_stylebox_override("read_only", load(
				"res://assets/themes/default/stylebox/inputLine/sbReadOnlyIncorrect.tres"))
			
			#To change the question icon of the last question
			%QuestionIcons.get_children()[question_number - 1].changeTexture("Incorrect")
		
		#To check if it is last question
		if question_number == number_of_questions:
			game_running = false
			resultScreenManager()
			timerManager(timerModes.GAMEOVER, 0.8)

		else:
			timerManager(timerModes.QUESTION, 0.25)

#To play again
func btnPlayAgainPressed():
	transitionManager(self, "modulate:a", 0, 0.75, "restart")

func btnMainMenuPressed():
	transitionManager(self, "modulate:a", 0, 0.75, "mainMenu")

#For the game to start
func BtnStartGamePressed():
	transitionManager(%StartScreen, "modulate:a", 0, 0.25, "start")
#endregion

#Manages the whole result screen
func resultScreenManager():
	#To calculate and show the percentage of correct questions
	accuracy = "%2d" % ((number_correct_answers * 100) / number_of_questions)
	
	%StopwatchResult.text = %Stopwatch.text
	%LblPercentage.text = accuracy + "%"
	
	var db_ref = Firebase.Database.get_database_reference(
		"history/" + LocalUser.userid, {})
	db_ref.push({'type': game_mode, 'difficulty': difficulty,
	 'time': %StopwatchResult.text, 'accuracy': accuracy})
	
	#To certify the data are right and updated
	var collection : FirestoreCollection = Firebase.Firestore.collection('users')
	var document = await collection.get_doc(LocalUser.userid).get_document
	LocalUser.userinfo = document.doc_fields
	
	var acc : float = float(accuracy) / 100.0
	
	#region Coin management
	var cur_coins : int = LocalUser.userinfo.coins
	var coin_time : float = (150.0 - ((cur_time - 20.0) / (120.0 - 20.0)) * 120.0)
	var coin_total : int = int(coin_time * diff_mult * mode_mult * acc)
	%LblECoins.text = "+ " + str(coin_total)
	
	var end_cur_coins = cur_coins + coin_total
	#endregion
	
	#region XP management
	#Current amount of XP gained
	%LblLvlValue.text = str(LocalUser.userinfo.level)
	var xp_time : float = (150.0 - ((cur_time - 20.0) / (120.0 - 20.0)) * 120.0)
	var xp_total : int = int(xp_time * diff_mult * mode_mult * acc)
	
	var cur_xp : int = LocalUser.userinfo.xp
	var level : int = LocalUser.userinfo.level
	var leveling_xp = leveling_xp_manager(level)
	
	var end_cur_xp : int = 0
	var end_level : int = level
	var end_leveling_xp : int = 0
	
	#For setting current xp and current level after gained new xp
	if (cur_xp + xp_total) < leveling_xp:
		end_cur_xp = cur_xp + xp_total
	
	elif (cur_xp + xp_total) == leveling_xp:
		end_cur_xp = 0
		end_level += 1
		end_leveling_xp = leveling_xp_manager(end_level)
	
	elif (cur_xp + xp_total) > leveling_xp:
		end_cur_xp = (cur_xp + xp_total) - leveling_xp
		end_level += 1
		end_leveling_xp = leveling_xp_manager(end_level)
		
		#For looping if cur_xp is still higher than leveling xp
		if end_cur_xp > end_leveling_xp:
			while end_cur_xp > end_leveling_xp:
				end_cur_xp = end_cur_xp - end_leveling_xp
				end_level += 1
				end_leveling_xp = leveling_xp_manager(end_level)
	#endregion
	
	#Save the new data to the database
	collection.update(LocalUser.userid, {
	'coins': end_cur_coins, 'level': end_level, 'xp': end_cur_xp})
	
	#To save the current amount of coins to the local script
	LocalUser.userinfo.coins = end_cur_coins
	LocalUser.userinfo.xp = end_cur_xp
	LocalUser.userinfo.level = end_level
	
	_coin_animation_manager(cur_coins, coin_total)
	_xp_animation_manager(xp_total, cur_xp, level)
	
	#Signals
	collection.add_document.connect(_on_doc_add)
	collection.error.connect(_on_doc_error)
	db_ref.push_successful.connect(_RTDB_push_success)
	db_ref.push_failed.connect(_RTDB_push_error)

#Manages the animation for the coin count
func _coin_animation_manager(cur_coins, coin_total):
	var in_cur_coins = cur_coins + coin_total
	coinValueAnim = cur_coins
	
	var tween = get_tree().create_tween()
	tween.tween_interval(1.25)
	tween.tween_property(self, "coinValueAnim", in_cur_coins, 2).set_trans(
		Tween.TRANS_QUART)

#Manages the animation of the visual representation for the XP
func _xp_animation_manager(xp_total, cur_xp, level):
	var in_leveling_xp = leveling_xp_manager(level)
	var in_level = level
	var in_cur_xp = cur_xp
	
	%ProgressLvl.max_value = in_leveling_xp
	%ProgressLvl.value = in_cur_xp

	if (in_cur_xp + xp_total) < in_leveling_xp:
		#Just adds the xp gained
		
		in_cur_xp += xp_total
		
		var tween = get_tree().create_tween()
		tween.tween_interval(3)
		tween.tween_property(%ProgressLvl, "value", in_cur_xp, 2).set_trans(
			Tween.TRANS_QUART)
	
	elif (in_cur_xp + xp_total) == in_leveling_xp:
		#Adds the first value just until the progressbar is maxed out
		var tween_first = get_tree().create_tween()
		tween_first.tween_interval(3)
		tween_first.tween_property(%ProgressLvl, "value", in_leveling_xp, 2).set_trans(
			Tween.TRANS_QUART)
		await tween_first.finished
		
		#When the animation ends, then...
		in_level += 1
		%LblLvlValue.text = str(in_level)
	
		#Resets the progressbar
		var tween_second = get_tree().create_tween()
		tween_second.tween_property(%ProgressLvl, "value", 0, 0.5).set_trans(
			Tween.TRANS_QUART)
		
		#Re-calculates the leveling xp
		in_leveling_xp = leveling_xp_manager(in_level)
		%ProgressLvl.max_value = in_leveling_xp
	
	elif (in_cur_xp + xp_total) > in_leveling_xp:
		var excess_xp = (in_cur_xp + xp_total) - in_leveling_xp
		var remaining_xp = xp_total
		var next_leveling_xp = leveling_xp_manager(level + 1)
		
		if excess_xp < next_leveling_xp:
			
			#Adds the first value just until the progressbar is maxed out
			var tween_first = get_tree().create_tween()
			tween_first.tween_interval(3)
			tween_first.tween_property(%ProgressLvl, "value", in_leveling_xp, 1).set_trans(
				Tween.TRANS_QUART)
			await tween_first.finished
			
			#To show the value to the user
			in_level += 1
			%LblLvlValue.text = str(in_level)
			
			#Resets the progressbar
			var tween_second = get_tree().create_tween()
			tween_second.tween_property(%ProgressLvl, "value", 0, 0.5).set_trans(
				Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
			#Sets the new max_value for the progress level bar
			await tween_second.finished
			
			remaining_xp = (in_cur_xp + remaining_xp) - in_leveling_xp
			
			#Re-calculates the leveling xp
			in_leveling_xp = leveling_xp_manager(in_level)
			#Sets the new max_value for the progress level bar
			%ProgressLvl.max_value = in_leveling_xp
			
			#Adds the remaining the value
			var tween_third = get_tree().create_tween()
			tween_third.tween_property(%ProgressLvl, "value", remaining_xp, 1).set_trans(
				Tween.TRANS_QUART)
		
		else:
			#To make sure every XP bar has been filled
			var tween = get_tree().create_tween()
			tween.tween_interval(3)
			await tween.finished
			
			while ((remaining_xp + in_cur_xp) > in_leveling_xp):
				var tween_first = get_tree().create_tween()
				tween_first.tween_property(%ProgressLvl, "value", in_leveling_xp, 1).set_trans(
					Tween.TRANS_QUART)
				await tween_first.finished
				
				#To show the new level to the user
				in_level += 1
				%LblLvlValue.text = str(in_level)
				
				#Resets the progressbar
				var tween_second = get_tree().create_tween()
				tween_second.tween_property(%ProgressLvl, "value", 0, 0.5).set_trans(
				Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
				await tween_second.finished
				
				in_cur_xp = 0
				remaining_xp -= in_leveling_xp
				
				#Re-calculates the leveling xp
				in_leveling_xp = leveling_xp_manager(in_level)
				#Sets the new max_value for the progress level bar
				%ProgressLvl.max_value = in_leveling_xp
			
			var tween_final = get_tree().create_tween()
			tween_final.tween_property(%ProgressLvl, "value", remaining_xp, 1).set_trans(
				Tween.TRANS_QUART)

#To calculate the leveling xp amount
func leveling_xp_manager(level) -> int:
	var leveling_xp = 25 + ((75 * (level - 1)) + (((level - 1) ** 2) / 2))
	return leveling_xp

#When the doc is successfully added to Firestore
func _on_doc_add(document):
	pass

#When there is an error when addinf a file
func _on_doc_error(_error, _code, message):
	print(message)

func _RTDB_push_success():
	pass

func _RTDB_push_error():
	pass

#Then the timer is over, a function will happen
func timerTimeout():
	match timerMode:
		#If it will load another question
		timerModes.QUESTION:
			transitionManager(%HeaderQuestion, "modulate:a", 0, 0.5, "nextQuestion")
		
		#If the game ended
		timerModes.GAMEOVER:
			transitionManager(self, "position:y", -get_viewport().get_visible_rect().size.y, 0.75)
