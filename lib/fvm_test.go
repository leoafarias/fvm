package lib

import (
	"testing"
)

func TestLoadVersion(t *testing.T) {
	type args struct {
		branch string
	}
	tests := []struct {
		name    string
		args    args
		wantErr bool
	}{
		{"Stable Channel", args{branch: "stable"}, false},
		{"Beta Channel", args{branch: "beta"}, false},
		{"Dev Channel", args{branch: "dev"}, false},
		{"Master Channel", args{branch: "master"}, false},
		{"Version Number", args{branch: "v1.2.0"}, false},
		{"Version Number Wrong", args{branch: "v1.2.0"}, false},
		{"Fake Channel", args{branch: "fake"}, true},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			if _, err := LoadVersion(tt.args.branch); (err != nil) != tt.wantErr {
				t.Errorf("LoadVersion() error = %v, wantErr %v", err, tt.wantErr)
			}
		})
	}
}

func Test_CheckVersion(t *testing.T) {

	tests := []struct {
		name    string
		version string
		want    string
		wantErr bool
	}{
		{"Stable Channel", "stable", "stable", false},
		{"Beta Channel", "beta", "beta", false},
		{"Dev Channel", "dev", "dev", false},
		{"Master Channel", "master", "master", false},
		{"Version Number", "1.2.0", "v1.2.0", false},
		{"Version Number Wrong", "v1.2.0", "v1.2.0", false},
		{"Fake Channel", "fake", "", true},
		{"Fake Version", "10.2.1", "", true},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			got, err := CheckVersion(tt.version)
			if (err != nil) != tt.wantErr {
				t.Errorf("checkVersion() error = %v, wantErr %v", err, tt.wantErr)
				return
			}
			if got != tt.want {
				t.Errorf("checkVersion() = %v, want %v", got, tt.want)
			}
		})
	}
}

func TestAddVersion(t *testing.T) {
	type args struct {
		version string
	}
	tests := []struct {
		name    string
		args    args
		wantErr bool
	}{
		{"Stable Channel", args{version: "stable"}, false},
		{"Beta Channel", args{version: "beta"}, false},
		{"Dev Channel", args{version: "dev"}, false},
		{"Master Channel", args{version: "master"}, false},
		{"Version Number", args{version: "v1.2.0"}, false},
		{"Version Number Wrong", args{version: "v1.2.0"}, false},
		{"Fake Channel", args{version: "fake"}, true},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			if err := AddVersion(tt.args.version); (err != nil) != tt.wantErr {
				t.Errorf("AddVersion() error = %v, wantErr %v", err, tt.wantErr)
			}
		})
	}
}
