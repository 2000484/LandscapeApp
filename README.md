# LandscapeApp

Connect IQ activity app for a Garmin Vivoactive 5. Tracks GPS route, speed, distance, elapsed time, estimated area (distance × mower width), calories burned, and costs.

## Features

- **Multi-task tracking** - Switch between 15 different landscaping tasks
- **GPS route recording** - Track your exact path with distance measurements
- **Real-time metrics** - Speed, average speed, elapsed time, and distance
- **Area calculation** - Estimates total area covered (distance × mower width)
- **Calorie estimation** - Calculates estimated calories burned based on activity intensity
- **Cost tracking** - Calculate estimated earnings based on hourly rate
- **Task statistics** - Tracks cumulative time and distance per task type
- **Auto-pause** - Automatically pauses when moving below threshold speed
- **Multi-page display** - Swap between primary and secondary metric views
- **Haptic feedback** - Vibration alerts for task start/end

## Build and load

1. Install the Garmin Connect IQ SDK and set `CIQ_SDK_HOME`.
2. Open this folder in VS Code with the Connect IQ extension.
3. Build and run the app on a Vivoactive 5 simulator or device.

## Settings

- **Mower width (m)** - Width of your mower/equipment for area calculation
- **Auto-pause speed (m/s)** - Speed threshold for automatic pause
- **Auto-pause enabled** - Toggle automatic pausing at low speeds
- **Use imperial units** - Display in miles/mph/sq ft or km/kph/sq m
- **Show area** - Display estimated area covered
- **Show calories** - Display estimated calories burned
- **Show steps** - Display step count on secondary screen
- **Haptics enabled** - Enable/disable vibration feedback
- **Hourly rate ($)** - Set your hourly rate for earnings estimates
- **Track costs** - Toggle cost tracking display

## How to Use

1. **Select Task** - Use up/down buttons to choose a landscaping task from the list
2. **Start Task** - Tap the screen or press the bottom button
3. **View Metrics** - Press up/down during activity to switch between metric pages
4. **End Task** - Press the top button to end the current task
5. **End Activity** - When no task is active, press the top button to end the activity

Tasks marked with an asterisk (*) have been used before in this session.

## Task Types

- Mowing
- Edging/Weedwhacker
- Weeding
- Blower
- Trimming
- Pruning
- Mulching
- Raking
- Leaf Pickup
- Planting
- Fertilizing
- Irrigation
- Hardscape
- Hauling
- Cleanup