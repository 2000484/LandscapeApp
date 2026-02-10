using Toybox.ActivityMonitor as ActivityMonitor;
using Toybox.ActivityRecording as ActivityRecording;
using Toybox.Attention as Attention;
using Toybox.Application as App;
using Toybox.Graphics as Gfx;
using Toybox.Lang as Lang;
using Toybox.Math as Math;
using Toybox.Positioning as Positioning;
using Toybox.Timer as Timer;
using Toybox.WatchUi as WatchUi;

class LandscapingView extends WatchUi.View {
    const AUTO_PAUSE_WINDOW_SEC = 10;

    var _session;
    var _timer;
    var _autoPauseSpeed;
    var _mowerWidthMeters;
    var _defaultMowerWidth; // Store the settings value separately
    var _useImperial;
    var _showSteps;
    var _showArea;
    var _showCalories;
    var _hapticsEnabled;
    var _autoPauseEnabled;
    var _enableCostTracking;
    var _hourlyRate;
    var _belowSpeedSeconds = 0;
    var _paused = false;
    var _tasks;
    var _taskIndex = 0;
    var _activeTaskName;
    var _taskStartDistance = 0.0;
    var _taskStartElapsed = 0;
    var _dataPage = 0;
    var _taskStats; // Dictionary to track cumulative stats per task
    var _mowers;
    var _mowerWidths; // Dictionary mapping mower names to widths in meters
    var _mowerIndex = 0;
    var _selectingMower = false;
    var _activeMower = null;
    var _activeMowerWidth = 0.0;

    function initialize() {
        View.initialize();
        reloadSettings();
        _tasks = [
            "Mowing",
            "Edging/Weedwhacker",
            "Weeding",
            "Blower",
            "Trimming",
            "Pruning",
            "Mulching",
            "Raking",
            "Leaf Pickup",
            "Planting",
            "Fertilizing",
            "Irrigation",
            "Hardscape",
            "Hauling",
            "Cleanup"
        ];
        _mowers = [
            "Honda HRN216PKA",
            "John Deere E130 (42\" deck)",
            "Toro TimeCutter 42\"",
            "Craftsman T225 (42\" deck)",
            "Kubota Z725 (48\" deck)",
            "Ariens Ikon 42XL",
            "Husqvarna YTA24V48 (48\" deck)",
            "MTD Yard-Man 42\"",
            "Ryobi 38\" Mower",
            "Cub Cadet XT1 (42\" deck)",
            "Jacobsen Turfcat (48\" deck)",
            "Bobcat ZTS 48\" (48\" deck)",
            "Other Mower"
        ];
        
        // Mower widths in meters (converted from inches, 1 inch = 0.0254m)
        _mowerWidths = {
            "Honda HRN216PKA" => 0.5334,  // 21"
            "John Deere E130 (42\" deck)" => 1.0668,  // 42"
            "Toro TimeCutter 42\"" => 1.0668,  // 42"
            "Craftsman T225 (42\" deck)" => 1.0668,  // 42"
            "Kubota Z725 (48\" deck)" => 1.2192,  // 48"
            "Ariens Ikon 42XL" => 1.0668,  // 42"
            "Husqvarna YTA24V48 (48\" deck)" => 1.2192,  // 48"
            "MTD Yard-Man 42\"" => 1.0668,  // 42"
            "Ryobi 38\" Mower" => 0.9652,  // 38"
            "Cub Cadet XT1 (42\" deck)" => 1.0668,  // 42"
            "Jacobsen Turfcat (48\" deck)" => 1.2192,  // 48"
            "Bobcat ZTS 48\" (48\" deck)" => 1.2192  // 48"
        };
        
        _taskStats = {}; // Initialize empty stats dictionary
    }

    function reloadSettings() {
        var width = App.Properties.getValue("mowerWidth");
        var autoPause = App.Properties.getValue("autoPauseSpeed");
        var useImperial = App.Properties.getValue("useImperial");
        var showSteps = App.Properties.getValue("showSteps");
        var showArea = App.Properties.getValue("showArea");
        var showCalories = App.Properties.getValue("showCalories");
        var hapticsEnabled = App.Properties.getValue("hapticsEnabled");
        var autoPauseEnabled = App.Properties.getValue("autoPauseEnabled");
        var enableCostTracking = App.Properties.getValue("enableCostTracking");
        var hourlyRate = App.Properties.getValue("hourlyRate");

        _defaultMowerWidth = (width != null) ? width : 0.5;
        _mowerWidthMeters = _defaultMowerWidth;
        _autoPauseSpeed = (autoPause != null) ? autoPause : 0.5;
        _useImperial = (useImperial != null) ? useImperial : false;
        _showSteps = (showSteps != null) ? showSteps : true;
        _showArea = (showArea != null) ? showArea : true;
        _showCalories = (showCalories != null) ? showCalories : true;
        _hapticsEnabled = (hapticsEnabled != null) ? hapticsEnabled : true;
        _autoPauseEnabled = (autoPauseEnabled != null) ? autoPauseEnabled : true;
        _enableCostTracking = (enableCostTracking != null) ? enableCostTracking : false;
        _hourlyRate = (hourlyRate != null) ? hourlyRate : 50.0;
    }

    function onStart() {
        if (_session == null) {
            _session = ActivityRecording.createSession();
            _session.setActivityType(ActivityRecording.TYPE_OTHER);
            _session.start();
        }

        Positioning.enableLocationEvents(Positioning.LOCATION_CONTINUOUS, method(:onPosition));

        if (_timer == null) {
            _timer = new Timer.Timer();
        }
        _timer.start(method(:onTick), 1000, true);
    }

    function onStop() {
        if (_timer != null) {
            _timer.stop();
        }
        Positioning.disableLocationEvents();

        if (_session != null) {
            _session.stop();
            _session = null;
        }
    }

    function onKey(key) {
        if (key == WatchUi.KEY_ENTER) {
            if (_activeTaskName != null) {
                endTask();
            } else {
                endActivity();
            }
            return true;
        }

        if (_selectingMower) {
            if (key == WatchUi.KEY_UP) {
                _mowerIndex = (_mowerIndex - 1 + _mowers.size()) % _mowers.size();
                WatchUi.requestUpdate();
                return true;
            }
            if (key == WatchUi.KEY_DOWN) {
                _mowerIndex = (_mowerIndex + 1) % _mowers.size();
                WatchUi.requestUpdate();
                return true;
            }
            if (key == WatchUi.KEY_ESC) {
                _selectingMower = false;
                _activeMower = _mowers[_mowerIndex];
                startTask();
                return true;
            }
        }

        if (_activeTaskName == null && !_selectingMower) {
            if (key == WatchUi.KEY_UP) {
                _taskIndex = (_taskIndex - 1 + _tasks.size()) % _tasks.size();
                WatchUi.requestUpdate();
                return true;
            }
            if (key == WatchUi.KEY_DOWN) {
                _taskIndex = (_taskIndex + 1) % _tasks.size();
                WatchUi.requestUpdate();
                return true;
            }
            if (key == WatchUi.KEY_ESC) {
                if (_tasks[_taskIndex].equals("Mowing")) {
                    _selectingMower = true;
                    _mowerIndex = 0;
                    WatchUi.requestUpdate();
                } else {
                    startTask();
                }
                return true;
            }
        } else if (_activeTaskName != null) {
            if (key == WatchUi.KEY_UP || key == WatchUi.KEY_DOWN) {
                _dataPage = (_dataPage + 1) % 2;
                WatchUi.requestUpdate();
                return true;
            }
        }

        return false;
    }

    function onTap(evt) {
        if (_selectingMower) {
            _selectingMower = false;
            _activeMower = _mowers[_mowerIndex];
            startTask();
            return true;
        }

        if (_activeTaskName == null) {
            if (_tasks[_taskIndex].equals("Mowing")) {
                _selectingMower = true;
                _mowerIndex = 0;
                WatchUi.requestUpdate();
            } else {
                startTask();
            }
            return true;
        }

        _dataPage = (_dataPage + 1) % 2;
        WatchUi.requestUpdate();
        return true;
    }

    function onPosition(info) {
        // GPS events keep the session actively recording a route.
    }

    function onTick() {
        if (_session == null) {
            return;
        }

        var info = _session.getInfo();
        var speed = (info != null && info.currentSpeed != null) ? info.currentSpeed : 0.0;

        if (_autoPauseEnabled && speed < _autoPauseSpeed) {
            _belowSpeedSeconds += 1;
            if (!_paused && _belowSpeedSeconds >= AUTO_PAUSE_WINDOW_SEC) {
                _session.pause();
                _paused = true;
            }
        } else {
            _belowSpeedSeconds = 0;
            if (_paused) {
                _session.resume();
                _paused = false;
            }
        }

        WatchUi.requestUpdate();
    }

    function onUpdate(dc) {
        dc.clear();

        var info = (_session != null) ? _session.getInfo() : null;
        var distance = (info != null && info.totalDistance != null) ? info.totalDistance : 0.0;
        var speed = (info != null && info.currentSpeed != null) ? info.currentSpeed : 0.0;
        var elapsed = (info != null && info.elapsedTime != null) ? info.elapsedTime : 0;
        var avgSpeed = (elapsed > 0) ? (distance / elapsed) : 0.0;

        var area = distance * _mowerWidthMeters;
        var taskDistance = (distance - _taskStartDistance);
        if (taskDistance < 0) {
            taskDistance = 0;
        }
        var taskElapsed = (elapsed - _taskStartElapsed);
        if (taskElapsed < 0) {
            taskElapsed = 0;
        }

        dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_BLACK);
        dc.setFont(Gfx.FONT_XTINY);

        if (_selectingMower) {
            drawMowerPicker(dc);
            return;
        }

        if (_activeTaskName == null) {
            drawTaskPicker(dc);
            return;
        }

        dc.drawText(5, 5, Gfx.FONT_XTINY, "Landscaping - " + _activeTaskName);
        if (_dataPage == 0) {
            drawPrimaryMetrics(dc, speed, avgSpeed, distance, elapsed, area, taskElapsed, taskDistance);
        } else {
            drawSecondaryMetrics(dc, avgSpeed, distance, elapsed, taskElapsed, taskDistance);
        }
    }

    function drawMowerPicker(dc) {
        dc.drawText(5, 5, Gfx.FONT_XTINY, "Pick Mower");

        var startIndex = _mowerIndex - 2;
        if (startIndex < 0) {
            startIndex += _mowers.size();
        }

        var y = 30;
        for (var i = 0; i < 5; i += 1) {
            var idx = (startIndex + i) % _mowers.size();
            var name = _mowers[idx];
            var prefix = (idx == _mowerIndex) ? "> " : "  ";
            dc.setFont(Gfx.FONT_SMALL);
            dc.drawText(5, y, Gfx.FONT_SMALL, prefix + name);
            y += 20;
        }

        dc.setFont(Gfx.FONT_TINY);
        dc.drawText(5, 145, Gfx.FONT_TINY, "Up/Down to change");
        dc.drawText(5, 160, Gfx.FONT_TINY, "Tap or bottom to start");
    }

    function drawTaskPicker(dc) {
        dc.drawText(5, 5, Gfx.FONT_XTINY, "Pick task (top button ends)");

        var startIndex = _taskIndex - 2;
        if (startIndex < 0) {
            startIndex += _tasks.size();
        }

        var y = 30;
        for (var i = 0; i < 5; i += 1) {
            var idx = (startIndex + i) % _tasks.size();
            var name = _tasks[idx];
            var prefix = (idx == _taskIndex) ? "> " : "  ";
            // Add star indicator for tasks that have been used
            var indicator = _taskStats.hasKey(name) ? "*" : " ";
            dc.setFont(Gfx.FONT_SMALL);
            dc.drawText(5, y, Gfx.FONT_SMALL, prefix + indicator + name);
            y += 20;
        }

        // Show session summary at bottom
        dc.setFont(Gfx.FONT_XTINY);
        var summary = getTaskSummary();
        dc.drawText(5, 130, Gfx.FONT_XTINY, summary);
        
        dc.setFont(Gfx.FONT_TINY);
        dc.drawText(5, 145, Gfx.FONT_TINY, "Up/Down to change");
        dc.drawText(5, 160, Gfx.FONT_TINY, "Tap or bottom to start");
    }

    function startTask() {
        if (_session == null) {
            return;
        }

        var info = _session.getInfo();
        var baseTaskName = _tasks[_taskIndex];
        
        // If mowing task, append the mower name and set width
        if (baseTaskName.equals("Mowing") && _activeMower != null) {
            _activeTaskName = baseTaskName + " (" + _activeMower + ")";
            // Set mower width based on selected mower
            if (_mowerWidths.hasKey(_activeMower)) {
                _activeMowerWidth = _mowerWidths[_activeMower];
                _mowerWidthMeters = _activeMowerWidth;
            }
        } else {
            _activeTaskName = baseTaskName;
        }
        
        _taskStartDistance = (info != null && info.totalDistance != null) ? info.totalDistance : 0.0;
        _taskStartElapsed = (info != null && info.elapsedTime != null) ? info.elapsedTime : 0;
        vibrate([60, 60, 120]);
        WatchUi.requestUpdate();
    }

    function endTask() {
        // Record task statistics before clearing
        if (_activeTaskName != null && _session != null) {
            var info = _session.getInfo();
            var currentDistance = (info != null && info.totalDistance != null) ? info.totalDistance : 0.0;
            var currentElapsed = (info != null && info.elapsedTime != null) ? info.elapsedTime : 0;
            
            var taskDistance = currentDistance - _taskStartDistance;
            var taskElapsed = currentElapsed - _taskStartElapsed;
            
            if (taskDistance < 0) { taskDistance = 0; }
            if (taskElapsed < 0) { taskElapsed = 0; }
            
            // Store in stats dictionary
            if (_taskStats.hasKey(_activeTaskName)) {
                var existing = _taskStats[_activeTaskName];
                _taskStats[_activeTaskName] = {
                    "distance" => existing["distance"] + taskDistance,
                    "elapsed" => existing["elapsed"] + taskElapsed
                };
            } else {
                _taskStats[_activeTaskName] = {
                    "distance" => taskDistance,
                    "elapsed" => taskElapsed
                };
            }
        }
        
        _activeTaskName = null;
        _taskStartDistance = 0.0;
        _taskStartElapsed = 0;
        _activeMower = null;
        _mowerWidthMeters = _defaultMowerWidth; // Restore width to settings value
        vibrate([120, 60, 60]);
        WatchUi.requestUpdate();
    }

    function endActivity() {
        vibrate([200, 60, 200]);
        if (_session != null) {
            _session.stop();
            _session = null;
        }
        if (_timer != null) {
            _timer.stop();
        }
        Positioning.disableLocationEvents();
        App.getApp().requestStop();
    }

    function drawPrimaryMetrics(dc, speed, avgSpeed, distance, elapsed, area, taskElapsed, taskDistance) {
        var y = 28;
        dc.setFont(Gfx.FONT_SMALL);
        dc.drawText(5, y, Gfx.FONT_SMALL, "Speed: " + formatSpeed(speed));
        y += 20;
        dc.drawText(5, y, Gfx.FONT_SMALL, "Avg: " + formatSpeed(avgSpeed));
        y += 20;
        dc.drawText(5, y, Gfx.FONT_SMALL, "Dist: " + formatDistance(distance));
        y += 20;
        dc.drawText(5, y, Gfx.FONT_SMALL, "Time: " + formatTime(elapsed));
        y += 20;
        if (_showArea) {
            dc.drawText(5, y, Gfx.FONT_SMALL, "Area: " + formatArea(area));
            y += 20;
        }
        if (_showCalories) {
            var calories = estimateCalories(speed, elapsed);
            dc.drawText(5, y, Gfx.FONT_SMALL, "Cal: " + formatNumber(calories, 0));
            y += 20;
        }
        if (_enableCostTracking) {
            var earnings = estimateEarnings(elapsed);
            dc.drawText(5, y, Gfx.FONT_SMALL, "Earn: " + formatCurrency(earnings));
            y += 20;
        }
        dc.drawText(5, y, Gfx.FONT_SMALL, "Task: " + formatTime(taskElapsed) + " / " + formatDistance(taskDistance));
        y += 20;
        if (_paused) {
            dc.setFont(Gfx.FONT_TINY);
            dc.drawText(5, y, Gfx.FONT_TINY, "Paused");
        }
    }

    function drawSecondaryMetrics(dc, avgSpeed, distance, elapsed, taskElapsed, taskDistance) {
        var y = 28;
        dc.setFont(Gfx.FONT_SMALL);
        dc.drawText(5, y, Gfx.FONT_SMALL, "Task: " + _activeTaskName);
        y += 20;
        dc.drawText(5, y, Gfx.FONT_SMALL, "Task Time: " + formatTime(taskElapsed));
        y += 20;
        dc.drawText(5, y, Gfx.FONT_SMALL, "Task Dist: " + formatDistance(taskDistance));
        y += 20;
        dc.drawText(5, y, Gfx.FONT_SMALL, "Total Dist: " + formatDistance(distance));
        y += 20;
        dc.drawText(5, y, Gfx.FONT_SMALL, "Total Time: " + formatTime(elapsed));
        y += 20;
        dc.drawText(5, y, Gfx.FONT_SMALL, "Avg Speed: " + formatSpeed(avgSpeed));
        y += 20;
        if (_showSteps) {
            dc.drawText(5, y, Gfx.FONT_SMALL, "Steps: " + getStepCount());
            y += 20;
        }
        if (_showCalories) {
            var calories = estimateCalories(avgSpeed, elapsed);
            dc.drawText(5, y, Gfx.FONT_SMALL, "Cal: " + formatNumber(calories, 0));
            y += 20;
        }
        if (_enableCostTracking) {
            var earnings = estimateEarnings(elapsed);
            dc.drawText(5, y, Gfx.FONT_SMALL, "Earn: " + formatCurrency(earnings));
        }
    }

    function getStepCount() {
        var info = ActivityMonitor.getInfo();
        if (info != null && info.steps != null) {
            return info.steps.toString();
        }
        return "0";
    }

    function getTaskStats(taskName) {
        if (_taskStats.hasKey(taskName)) {
            return _taskStats[taskName];
        }
        return { "distance" => 0.0, "elapsed" => 0 };
    }

    function getTaskSummary() {
        var summary = "Tasks completed: ";
        var taskCount = 0;
        var totalDistance = 0.0;
        var totalTime = 0;
        
        var keys = _taskStats.keys();
        if (keys != null) {
            taskCount = keys.size();
            for (var i = 0; i < keys.size(); i += 1) {
                var key = keys[i];
                var stats = _taskStats[key];
                totalDistance += stats["distance"];
                totalTime += stats["elapsed"];
            }
        }
        
        summary = summary + taskCount + " | Dist: " + formatDistance(totalDistance) + " | Time: " + formatTime(totalTime);
        return summary;
    }

    function estimateCalories(speedMetersPerSecond, elapsedSeconds) {
        // Estimate calories burned based on activity intensity
        // Landscaping is moderate to high intensity (5-8 kcal/min)
        // Scale with speed: faster work = higher intensity
        var baseCaloriesPerMin = 6.0; // average for moderate landscaping
        var speedFactor = 1.0 + (speedMetersPerSecond * 0.3); // faster = more intense
        var caloriesPerMin = baseCaloriesPerMin * speedFactor;
        var totalCalories = (elapsedSeconds / 60.0) * caloriesPerMin;
        return totalCalories;
    }

    function estimateEarnings(elapsedSeconds) {
        var hours = elapsedSeconds / 3600.0;
        return hours * _hourlyRate;
    }

    function formatCurrency(value) {
        return "$" + formatNumber(value, 2);
    }

    function formatSpeed(speedMetersPerSecond) {
        var unit = _useImperial ? "mph" : "km/h";
        var value = _useImperial ? (speedMetersPerSecond * 2.236936) : (speedMetersPerSecond * 3.6);
        return formatNumber(value, 1) + " " + unit;
    }

    function formatDistance(distanceMeters) {
        var unit = _useImperial ? "mi" : "km";
        var value = _useImperial ? (distanceMeters * 0.000621371) : (distanceMeters / 1000.0);
        return formatNumber(value, 2) + " " + unit;
    }

    function formatArea(areaMeters) {
        if (_useImperial) {
            return formatNumber(areaMeters * 10.7639, 1) + " ft2";
        }
        return formatNumber(areaMeters, 1) + " m2";
    }

    function vibrate(pattern) {
        if (!_hapticsEnabled) {
            return;
        }
        Attention.vibrate(pattern);
    }

    function formatTime(seconds) {
        var mins = seconds / 60;
        var hours = mins / 60;
        mins = mins % 60;
        var secs = seconds % 60;
        return Lang.format("%02d:%02d:%02d", [hours, mins, secs]);
    }

    function formatNumber(value, decimals) {
        var factor = Math.pow(10, decimals);
        var rounded = Math.round(value * factor) / factor;
        return rounded.toString();
    }
}
