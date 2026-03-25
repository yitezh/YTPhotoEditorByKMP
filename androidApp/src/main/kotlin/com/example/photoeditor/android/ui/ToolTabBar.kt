package com.example.photoeditor.android.ui

import androidx.compose.animation.animateColorAsState
import androidx.compose.animation.core.tween
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.unit.dp
import com.example.photoeditor.ToolTab

private data class TabInfo(val tab: ToolTab, val label: String, val icon: ImageVector)

private val tabs = listOf(
    TabInfo(ToolTab.LIGHT,   "光效", Icons.Filled.WbSunny),
    TabInfo(ToolTab.COLOR,   "颜色", Icons.Filled.Palette),
    TabInfo(ToolTab.EFFECTS, "效果", Icons.Filled.AutoFixHigh),
    TabInfo(ToolTab.DETAIL,  "细节", Icons.Filled.Tune)
)

@Composable
fun ToolTabBar(
    selectedTab: ToolTab,
    onTabSelected: (ToolTab) -> Unit,
    modifier: Modifier = Modifier
) {
    Row(
        modifier = modifier
            .fillMaxWidth()
            .background(Color(0xFF1A1A1A))
            .height(56.dp),
        horizontalArrangement = Arrangement.SpaceEvenly
    ) {
        tabs.forEach { info ->
            val isSelected = info.tab == selectedTab
            val contentColor by animateColorAsState(
                targetValue = if (isSelected) MaterialTheme.colorScheme.primary else Color.Gray,
                animationSpec = tween(durationMillis = 200),
                label = "tabColor_${info.tab}"
            )
            Column(
                modifier = Modifier
                    .weight(1f)
                    .fillMaxHeight()
                    .clickable { onTabSelected(info.tab) },
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalArrangement = Arrangement.Center
            ) {
                Icon(
                    imageVector = info.icon,
                    contentDescription = info.label,
                    tint = contentColor,
                    modifier = Modifier.size(20.dp)
                )
                Spacer(Modifier.height(2.dp))
                Text(
                    text = info.label,
                    color = contentColor,
                    style = MaterialTheme.typography.labelSmall
                )
            }
        }
    }
}
