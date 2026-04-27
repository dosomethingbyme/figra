# PDF 图片提取器软件开发规则

- 后续本软件相关开发都在当前目录 `/Users/yangye/Library/Mobile Documents/com~apple~CloudDocs/论文/control-llm/PDF图片提取器软件` 下进行。
- macOS app 工程在 `PDFImageExtractorApp/`。
- `pdffigures2.jar` 已放在 `PDFImageExtractorApp/Resources/pdffigures2.jar`，后续打包时应复制进 `.app/Contents/Resources/`。
- 正式 app 后端只使用 `pdffigures2` 提取 Figure/Table，不提取 PDF 内嵌对象。
- `PDFImageExtractorApp/Resources/jre/` 是随 app 打包的精简 Java runtime；正式 app 不依赖系统 Java、Python 或 conda。
- 不要把论文 PDF、论文图片产物或 draw.io 复刻文件混入软件工程目录，除非它们被明确作为测试样例或资源使用。
