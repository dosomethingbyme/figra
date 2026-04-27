# PDF 图片提取器

这是一个 macOS 原生应用工程，用于拖入 PDF 后通过内置 `pdffigures2` 提取论文中的 Figure/Table 区域。

## 目录

- `PDFImageExtractorApp/`: macOS AppKit 应用源码、资源和构建脚本。
- `PDFImageExtractorApp/Resources/pdffigures2.jar`: pdffigures2 可执行 jar，构建时会打包进 `.app`。
- `PDFImageExtractorApp/Resources/jre/`: 精简 Java runtime，应用运行时不依赖系统 Java/Python/conda。

## 构建

```bash
cd "PDFImageExtractorApp"
./build_app.sh
```

生成 DMG：

```bash
cd "PDFImageExtractorApp"
./build_dmg.sh
```

构建产物为：

```text
PDFImageExtractorApp/PDF 图片提取器.app
PDFImageExtractorApp/PDF图片提取器.dmg
```
