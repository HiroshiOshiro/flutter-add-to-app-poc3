package com.example.legacyapp.flutter

import android.content.Context
import android.content.Intent
import com.example.legacyapp.CompleteActivity
import com.example.legacyapp.ConfirmActivity

/**
 * 論理的な画面名から、実際に開くネイティブ画面を決める。
 *
 * Flutter側は「完了画面へ行きたい」としか言わず、それがどのActivityかは知らない。
 */
object NativeRouter {

    const val SCREEN_CONFIRM = "confirm"
    const val SCREEN_COMPLETE = "complete"

    fun intentFor(context: Context, screen: String): Intent? = when (screen) {
        SCREEN_CONFIRM -> Intent(context, ConfirmActivity::class.java)
        SCREEN_COMPLETE -> Intent(context, CompleteActivity::class.java)
        else -> null
    }
}
