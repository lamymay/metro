package com.rakukura.metrolab.calendar

import android.content.Context
import android.graphics.Color
import android.view.Gravity
import android.view.View
import android.widget.GridLayout
import android.widget.LinearLayout
import android.widget.ScrollView
import com.rakukura.metrolab.lab.SampleData
import com.rakukura.metrolab.nav.MetroPage
import com.rakukura.metrolab.nav.PageHost
import com.rakukura.metrolab.pivot.PivotItem
import com.rakukura.metrolab.pivot.PivotView
import com.rakukura.metrolab.theme.MetroRole
import com.rakukura.metrolab.theme.MetroTheme
import com.rakukura.metrolab.widget.MetroTextView

/**
 * WP's Calendar: an "agenda" pivot of upcoming events plus a bare month grid — no
 * photos, no colour beyond the accent dots marking a day that has something on it.
 */
class MetroCalendarPage : MetroPage {

    override fun createView(context: Context, host: PageHost): View = PivotView(
        context,
        listOf(
            PivotItem("agenda") { ctx -> agendaTab(ctx) },
            PivotItem("month") { ctx -> monthTab(ctx) }
        ),
        title = "calendar"
    )

    private fun agendaTab(context: Context): View {
        val scroll = ScrollView(context)
        val column = LinearLayout(context).apply {
            orientation = LinearLayout.VERTICAL
            setPadding(0, 0, 0, MetroTheme.dpInt(32f))
        }

        val byDay = SampleData.events.groupBy { it.day }.toSortedMap()
        var first = true
        for ((day, events) in byDay) {
            column.addView(MetroTextView(context, MetroRole.GROUP_HEADER).apply {
                text = dayLabel(day)
                setPadding(
                    MetroTheme.pageMargin.toInt(), MetroTheme.dpInt(if (first) 4f else 18f),
                    MetroTheme.pageMargin.toInt(), MetroTheme.dpInt(6f)
                )
            }, LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT))
            first = false

            for (event in events) {
                val row = LinearLayout(context).apply {
                    orientation = LinearLayout.HORIZONTAL
                    setPadding(MetroTheme.pageMargin.toInt(), MetroTheme.dpInt(6f), MetroTheme.pageMargin.toInt(), MetroTheme.dpInt(6f))
                }
                val stripe = View(context).apply { setBackgroundColor(event.accent.color) }
                row.addView(stripe, LinearLayout.LayoutParams(MetroTheme.dpInt(4f), LinearLayout.LayoutParams.MATCH_PARENT).apply { rightMargin = MetroTheme.dpInt(12f) })

                val textColumn = LinearLayout(context).apply { orientation = LinearLayout.VERTICAL }
                textColumn.addView(MetroTextView(context, MetroRole.TITLE3).apply { text = event.title }, LinearLayout.LayoutParams(LinearLayout.LayoutParams.WRAP_CONTENT, LinearLayout.LayoutParams.WRAP_CONTENT))
                textColumn.addView(MetroTextView(context, MetroRole.SMALL).apply {
                    this.text = if (event.end.isEmpty()) event.start else "${event.start}–${event.end}"
                }, LinearLayout.LayoutParams(LinearLayout.LayoutParams.WRAP_CONTENT, LinearLayout.LayoutParams.WRAP_CONTENT))
                row.addView(textColumn, LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.WRAP_CONTENT, 1f))

                column.addView(row, LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, MetroTheme.dpInt(52f)))
            }
        }
        scroll.addView(column, android.view.ViewGroup.LayoutParams(android.view.ViewGroup.LayoutParams.MATCH_PARENT, android.view.ViewGroup.LayoutParams.WRAP_CONTENT))
        return scroll
    }

    private fun dayLabel(day: Int): String {
        if (day == SampleData.today) return "today"
        if (day == SampleData.today + 1) return "tomorrow"
        return "${SampleData.currentMonth} $day"
    }

    private fun monthTab(context: Context): View {
        val scroll = ScrollView(context)
        val column = LinearLayout(context).apply { orientation = LinearLayout.VERTICAL }

        column.addView(MetroTextView(context, MetroRole.TITLE1).apply {
            text = SampleData.currentMonth
            setPadding(MetroTheme.pageMargin.toInt(), MetroTheme.dpInt(4f), 0, MetroTheme.dpInt(16f))
        }, LinearLayout.LayoutParams(LinearLayout.LayoutParams.WRAP_CONTENT, LinearLayout.LayoutParams.WRAP_CONTENT))

        val eventDays = SampleData.events.map { it.day }.toSet()
        val grid = GridLayout(context).apply { columnCount = 7 }
        for (day in 1..31) {
            val isToday = day == SampleData.today
            val cell = LinearLayout(context).apply {
                orientation = LinearLayout.VERTICAL
                gravity = Gravity.CENTER_HORIZONTAL
            }
            val circleSize = MetroTheme.dpInt(30f)
            val numberView = object : android.widget.TextView(context) {
                override fun onDraw(canvas: android.graphics.Canvas) {
                    if (isToday) {
                        val paint = android.graphics.Paint(android.graphics.Paint.ANTI_ALIAS_FLAG)
                        paint.color = MetroTheme.accentColor
                        canvas.drawCircle(width / 2f, height / 2f, minOf(width, height) / 2f, paint)
                    }
                    super.onDraw(canvas)
                }
            }
            numberView.text = day.toString()
            numberView.gravity = Gravity.CENTER
            numberView.setTextColor(if (isToday) MetroTheme.onAccent else MetroTheme.foreground)
            numberView.setTextSize(android.util.TypedValue.COMPLEX_UNIT_PX, MetroTheme.textSize(MetroRole.NORMAL))
            cell.addView(numberView, LinearLayout.LayoutParams(circleSize, circleSize))

            val dot = View(context)
            dot.setBackgroundColor(if (eventDays.contains(day)) MetroTheme.accentColor else Color.TRANSPARENT)
            cell.addView(dot, LinearLayout.LayoutParams(MetroTheme.dpInt(4f), MetroTheme.dpInt(4f)).apply { topMargin = MetroTheme.dpInt(3f) })

            val lp = GridLayout.LayoutParams(GridLayout.spec(GridLayout.UNDEFINED), GridLayout.spec(GridLayout.UNDEFINED))
            lp.width = circleSize + MetroTheme.dpInt(6f)
            lp.setMargins(0, 0, 0, MetroTheme.dpInt(8f))
            grid.addView(cell, lp)
        }
        column.addView(grid, LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT).apply {
            leftMargin = MetroTheme.pageMargin.toInt()
        })

        scroll.addView(column, android.view.ViewGroup.LayoutParams(android.view.ViewGroup.LayoutParams.MATCH_PARENT, android.view.ViewGroup.LayoutParams.WRAP_CONTENT))
        return scroll
    }
}
