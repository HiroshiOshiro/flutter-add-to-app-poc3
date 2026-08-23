package com.example.legacyapp;

import androidx.appcompat.app.AppCompatActivity;

// Shared base for every screen in the flow. Over time this became the place
// where cross-screen state got stashed directly, instead of behind a proper
// data layer -- the kind of implicit coupling every screen after this one
// quietly depends on.
public abstract class BaseActivity extends AppCompatActivity {

    // Flutter統合のハンドラ（com.example.legacyapp.flutter）から参照するため
    // public にしている。移行が進みこの状態の所有がFlutterへ移れば不要になる。
    public static final FormData sFormData = new FormData();
}
