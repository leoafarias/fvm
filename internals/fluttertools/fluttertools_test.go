package fluttertools

import (
	"path"
	"testing"
)

var (
	flutterHome   = GetFlutterHome()
	workspaceHome = GetWorkspaceHome()
	channelName   = "stable"
)

func TestGetFlutterHome(t *testing.T) {
	flutterHome = GetFlutterHome()
	t.Error(flutterHome)
}

func TestGetChannel(t *testing.T) {
	if err := GetChannel(workspaceHome, channelName); err != nil {
		t.Errorf("Expected to clone Flutter Channel: %v", err)
	}
}

func TestGetChannelInfo(t *testing.T) {
	info, err := GetChannelInfo(path.Join(workspaceHome, channelName))
	if err != nil {
		t.Errorf("Cannot get channel info: %v", err)
	}

	if info != channelName {
		t.Errorf("Info returned doesn't mach channel name: %v", err)
	}

}

// func TestGetVersionNumber(t *testing.T) {
// 	_, err := GetVersionNumber(flutterHome)
// }
