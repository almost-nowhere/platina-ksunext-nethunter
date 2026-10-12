# 在 macOS 发布到 GitHub

1. 解压发布包并进入目录：

   ```sh
   tar -xzf platina-ksunext-nethunter-release-20260719.tar.gz
   cd platina-ksunext-nethunter-release
   ```

2. 再次校验二进制文件：

   ```sh
   shasum -a 256 -c SHA256SUMS
   ```

3. 在 GitHub 网页创建一个空仓库，例如 `platina-ksunext-nethunter`，不要自动生成 README 或 LICENSE。

4. 初始化并推送：

   ```sh
   git init -b main
   git add .
   git commit -m "Initial platina KSU Next NetHunter release"
   git remote add origin https://github.com/YOUR_GITHUB_USER/platina-ksunext-nethunter.git
   git push -u origin main
   ```

5. 在 GitHub 的 Releases 页面创建 `v2026.07.19`，将 `releases/` 中的三个文件作为 Release assets 上传，并复制 `SHA256SUMS` 内容到发布说明。

发布前请阅读根目录 README 的风险、许可证与免责声明。
