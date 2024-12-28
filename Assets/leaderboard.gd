extends Control

func load_data(data_path: String) -> void:
	var leaderboardList = $MarginContainer/VBoxContainer/LeaderboardList
	leaderboardList.load_data(data_path)
