# 设计尺寸 / Design dimensions

| 模式 / Mode | 竖屏 / Portrait | 横屏 / Landscape |
| --- | --- | --- |
| 标准 / Standard | 393 × 852 | 852 × 393 |
| 阔屏外屏 / Wide outer | 400 × 560 | 560 × 400 |
| 阔屏内屏 / Wide inner | 570 × 798 | 798 × 570 |

这些是可编辑的逻辑设计尺寸，不是任何具体机型的官方像素、点数或安全区域。阔屏使用通用参考比例，内外屏各自保存横竖布局。导出根据容器尺寸选择设计变体，开发者仍需在真实目标环境中调整适配。

These are editable logical design dimensions, not official pixels, points or safe areas for specific hardware. Wide mode uses a generic reference ratio with separate inner / outer orientation layouts. Export chooses variants from container dimensions; developers still need to adapt the UI to actual target environments.
