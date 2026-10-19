# MT2CSV

AutoCAD LISP 工具：提取图中文字，并按选择顺序或 XY 坐标顺序导出为 CSV。

## 来源

- 原帖：[CAD 提取文字和选择排序 + XY 轴排序，MT2CSV-V4 版本](https://www.52pojie.cn/forum.php?mod=viewthread&tid=2014292&highlight=cad)
- 当前仓库按帖子中的 V4/V4.2 版本整理。

## 使用

1. 在 AutoCAD 中运行 `APPLOAD`，加载 `MT2CSV.lsp`。
2. 输入命令 `MT2CSV`。
3. 选择文字实体并回车。
4. 根据提示选择输出策略：选择排序或 XY 轴排序。

支持帖子所述的 AutoCAD 2000–2026（实际兼容性以本机版本测试为准）。

## FONTFIX

`plugins/fontfix/FONTFIX.LSP` 是配套的字体修复工具，提供全图处理和手动选择两种模式，将 TEXT/MTEXT 的文字样式统一为 `STANDARD`，并移除部分扩展数据。

在 AutoCAD 中使用 `APPLOAD` 加载后，输入 `FONTFIX` 执行。使用前建议备份图纸，并先在副本上验证字体替换效果。

## 仓库状态

MT2CSV 原帖附件需要登录后下载；本仓库已补充用户提供的 FONTFIX 源文件，并按插件目录整理。

## 许可

源代码版权归原作者所有。除非获得原作者授权，请勿将本仓库用于商业分发。
