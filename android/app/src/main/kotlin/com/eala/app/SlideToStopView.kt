package com.eala.app

import android.content.Context
import android.graphics.Color
import android.graphics.Typeface
import android.graphics.drawable.GradientDrawable
import android.view.Gravity
import android.view.MotionEvent
import android.view.View
import android.widget.FrameLayout
import android.widget.TextView

/** iOS-style "slide to stop" pill: a round thumb with a white stop square. */
class SlideToStopView(
    context: Context,
    hint: String,
    private val onComplete: () -> Unit,
) : FrameLayout(context) {
    private val dp = resources.displayMetrics.density
    private val thumbSize = (64 * dp).toInt()
    private val inset = (4 * dp).toInt()
    private val thumb = FrameLayout(context)
    private var dragging = false
    private var downX = 0f
    private var startTranslation = 0f
    private var completed = false

    init {
        background = GradientDrawable().apply {
            setColor(Color.parseColor("#1C1C1E"))
            cornerRadius = 40 * dp
        }

        addView(
            TextView(context).apply {
                text = hint
                setTextColor(Color.parseColor("#8E8E93"))
                textSize = 22f
                typeface = Typeface.create("sans-serif", Typeface.NORMAL)
                gravity = Gravity.CENTER_VERTICAL
                setPadding(thumbSize + inset * 4, 0, 0, 0)
            },
            LayoutParams(LayoutParams.MATCH_PARENT, LayoutParams.MATCH_PARENT),
        )

        thumb.background = GradientDrawable().apply {
            shape = GradientDrawable.OVAL
            setColor(Color.parseColor("#2C2C2E"))
            setStroke((1 * dp).toInt(), Color.parseColor("#48484A"))
        }
        thumb.addView(
            View(context).apply {
                background = GradientDrawable().apply {
                    setColor(Color.WHITE)
                    cornerRadius = 6 * dp
                }
            },
            LayoutParams((28 * dp).toInt(), (28 * dp).toInt(), Gravity.CENTER),
        )
        addView(thumb, LayoutParams(thumbSize, thumbSize, Gravity.CENTER_VERTICAL).apply { leftMargin = inset })
    }

    private fun maxTravel(): Float = (width - thumbSize - inset * 2).toFloat().coerceAtLeast(0f)

    /** Puts the thumb back to the start so the user can slide again. */
    fun reset() {
        completed = false
        thumb.animate().translationX(0f).setDuration(150).start()
    }

    override fun onTouchEvent(event: MotionEvent): Boolean {
        if (completed) return true
        when (event.actionMasked) {
            MotionEvent.ACTION_DOWN -> {
                val left = thumb.left + thumb.translationX
                if (event.x < left || event.x > left + thumbSize) return false
                dragging = true
                downX = event.rawX
                startTranslation = thumb.translationX
                parent?.requestDisallowInterceptTouchEvent(true)
                return true
            }
            MotionEvent.ACTION_MOVE -> {
                if (!dragging) return false
                thumb.translationX = (startTranslation + event.rawX - downX).coerceIn(0f, maxTravel())
                return true
            }
            MotionEvent.ACTION_UP, MotionEvent.ACTION_CANCEL -> {
                if (!dragging) return false
                dragging = false
                if (thumb.translationX >= maxTravel() * 0.85f) {
                    completed = true
                    thumb.animate().translationX(maxTravel()).setDuration(100).withEndAction { onComplete() }.start()
                } else {
                    thumb.animate().translationX(0f).setDuration(150).start()
                }
                return true
            }
        }
        return super.onTouchEvent(event)
    }
}
