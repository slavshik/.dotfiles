package main

import "testing"

func TestParsePageRef(t *testing.T) {
	tests := []struct {
		name    string
		input   string
		want    pageRef
		wantErr bool
	}{
		{
			name:  "bare numeric id",
			input: "906343997",
			want:  pageRef{pageID: "906343997"},
		},
		{
			name:  "modern spaces/pages url",
			input: "https://wiki.gosystem.io/spaces/ELA/pages/906343997/Some+Title",
			want:  pageRef{host: "https://wiki.gosystem.io", pageID: "906343997"},
		},
		{
			name:  "short pages url",
			input: "https://wiki.gosystem.io/pages/906343997",
			want:  pageRef{host: "https://wiki.gosystem.io", pageID: "906343997"},
		},
		{
			name:  "legacy viewpage.action with pageId query",
			input: "https://wiki.gosystem.io/pages/viewpage.action?pageId=906343997",
			want:  pageRef{host: "https://wiki.gosystem.io", pageID: "906343997"},
		},
		{
			name:  "legacy display url with encoded title and plus-spaces",
			input: "https://wiki.gosystem.io/display/ELA/%5BCONFIDENTIAL%5D87_FF+hold+and+win",
			want:  pageRef{host: "https://wiki.gosystem.io", space: "ELA", title: "[CONFIDENTIAL]87_FF hold and win"},
		},
		{
			name:    "unrecognized url",
			input:   "https://wiki.gosystem.io/foo/bar",
			wantErr: true,
		},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			got, err := parsePageRef(tt.input)
			if tt.wantErr {
				if err == nil {
					t.Fatalf("expected error, got nil (ref=%+v)", got)
				}
				return
			}
			if err != nil {
				t.Fatalf("unexpected error: %v", err)
			}
			if got != tt.want {
				t.Fatalf("parsePageRef(%q) = %+v, want %+v", tt.input, got, tt.want)
			}
		})
	}
}
