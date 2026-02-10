using Toybox.Application as App;
using Toybox.WatchUi as WatchUi;

class LandscapingApp extends App.AppBase {
    var _view;

    function initialize() {
        AppBase.initialize();
    }

    function getInitialView() {
        _view = new LandscapingView();
        return [ _view ];
    }

    function onStart(state) {
        if (_view != null) {
            _view.onStart();
        }
    }

    function onStop(state) {
        if (_view != null) {
            _view.onStop();
        }
    }

    function onSettingsChanged() {
        if (_view != null) {
            _view.reloadSettings();
        }
    }
}
