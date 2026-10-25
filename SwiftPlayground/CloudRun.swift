import Foundation

// MARK: - 云端真编译（GitHub Actions，使用者自己的账号）

final class CloudRunner: ObservableObject {
    @Published var running = false

    var onLine: ((String, Bool) -> Void)?   // (文本, 是否错误)
    var onFinished: (() -> Void)?

    private var token: String {
        UserDefaults.standard.string(forKey: "gh_cloud_token") ?? ""
    }
    private var repoName: String {
        let r = UserDefaults.standard.string(forKey: "gh_cloud_repo") ?? ""
        return r.isEmpty ? "swiftplayground-cloud" : r
    }
    private var owner = ""

    private let workflowPath = ".github/workflows/swift-run.yml"
    private let codePath = "run.swift"

    private let workflowYML = """
    name: Cloud Run
    on:
      workflow_dispatch: {}
    jobs:
      run:
        runs-on: ubuntu-latest
        steps:
          - uses: actions/checkout@v4
          - name: Run Swift
            run: |
              echo "===SPG_OUTPUT_START==="
              swift run.swift 2>&1 || true
              echo "===SPG_OUTPUT_END==="
    """

    // MARK: 主流程

    func run(code: String) {
        guard !token.isEmpty else {
            onLine?("⛔ 云端编译需要 GitHub Token，请到「设置 → 云端真编译」填写你自己的 Token", true)
            onFinished?()
            return
        }
        running = true
        Task {
            defer { Task { @MainActor in self.running = false } }
            do {
                let started = Date()
                emit("☁️ 连接 GitHub…", false)
                owner = try await getUserLogin()

                emit("☁️ 准备仓库 \(owner)/\(repoName)…", false)
                try await ensureRepo()

                emit("☁️ 上传代码与编译配置…", false)
                let headSHA = try await pushFile(path: workflowPath, content: workflowYML, message: "cloud workflow")
                _ = try await pushFile(path: codePath, content: code, message: "run code")
                // pushFile 返回的是各自文件 blob sha，这里重新取 main 最新 commit
                let latest = try await latestCommitSHA()
                _ = headSHA

                emit("☁️ 触发真 Swift 编译（首次或冷启动约需 30~60 秒）…", false)
                try await dispatch(allowRetry: true)

                emit("☁️ 等待编译完成…", false)
                let runID = try await pollRun(expectedHead: latest, started: started)
                let log = try await fetchLog(runID: runID)

                let out = extractOutput(from: log)
                if out.isEmpty {
                    emit("（无输出）", false)
                } else {
                    for line in out.split(separator: "\n", omittingEmptySubsequences: false) {
                        emit(String(line), false)
                    }
                }
                emit("✅ 云端编译完成", false)
            } catch CloudError.message(let m) {
                emit("⛔ \(m)", true)
            } catch {
                emit("⛔ 云端运行失败：\(error.localizedDescription)", true)
            }
            onFinished?()
        }
    }

    private func emit(_ text: String, _ err: Bool) {
        Task { @MainActor in
            self.onLine?(text, err)
        }
    }

    // MARK: GitHub API

    private enum CloudError: Error { case message(String) }

    private func request(_ method: String, _ path: String, body: [String: Any]? = nil, raw: Bool = false) async throws -> (Data, Int) {
        let urlString = path.hasPrefix("http") ? path : "https://api.github.com/" + path
        guard let url = URL(string: urlString) else { throw CloudError.message("URL 无效") }
        var req = URLRequest(url: url, timeoutInterval: 30)
        req.httpMethod = method
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        req.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        req.setValue("SwiftPlayground-iPhone", forHTTPHeaderField: "User-Agent")
        if let body {
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
            req.httpBody = try JSONSerialization.data(withJSONObject: body)
        }
        let (data, resp) = try await URLSession.shared.data(for: req)
        let status = (resp as? HTTPURLResponse)?.statusCode ?? 0
        return (data, status)
    }

    private func getUserLogin() async throws -> String {
        let (data, status) = try await request("GET", "user")
        guard status == 200,
              let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let login = obj["login"] as? String else {
            throw CloudError.message("Token 无效或过期，请到「设置」重新填写（需要 repo 与 workflow 权限）")
        }
        return login
    }

    private func ensureRepo() async throws {
        let (_, status) = try await request("GET", "repos/\(owner)/\(repoName)")
        if status == 200 { return }
        let (_, createStatus) = try await request("POST", "user/repos", body: [
            "name": repoName, "auto_init": true, "private": false,
            "description": "SwiftPlayground 云端编译沙盒"
        ])
        guard (200...201).contains(createStatus) else {
            throw CloudError.message("创建仓库失败（HTTP \(createStatus)），检查 Token 的 repo 权限")
        }
        try await Task.sleep(nanoseconds: 2_000_000_000)
    }

    @discardableResult
    private func pushFile(path: String, content: String, message: String) async throws -> String {
        let encoded = Data(content.utf8).base64EncodedString()
        let api = "repos/\(owner)/\(repoName)/contents/\(path)"
        var body: [String: Any] = ["message": message, "content": encoded]
        let (_, status) = try await request("GET", api)
        if status == 200 {
            // 已存在：取 sha 覆盖
            let (data, _) = try await request("GET", api)
            if let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let sha = obj["sha"] as? String {
                body["sha"] = sha
            }
        } else if status != 404 {
            throw CloudError.message("读取文件失败（HTTP \(status)）")
        }
        let (_, putStatus) = try await request("PUT", api, body: body)
        guard (200...201).contains(putStatus) else {
            throw CloudError.message("上传文件失败（HTTP \(putStatus)）")
        }
        return ""
    }

    private func latestCommitSHA() async throws -> String {
        let (data, status) = try await request("GET", "repos/\(owner)/\(repoName)/commits/main")
        guard status == 200,
              let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let sha = obj["sha"] as? String else {
            throw CloudError.message("获取提交失败（HTTP \(status)）")
        }
        return sha
    }

    private func dispatch(allowRetry: Bool) async throws {
        var lastStatus = 0
        for attempt in 1...5 {
            let (_, status) = try await request(
                "POST", "repos/\(owner)/\(repoName)/actions/workflows/swift-run.yml/dispatches",
                body: ["ref": "main"])
            if status == 204 { return }
            lastStatus = status
            if !allowRetry { break }
            try await Task.sleep(nanoseconds: 3_000_000_000)
        }
        throw CloudError.message("触发编译失败（HTTP \(lastStatus)）。若 Token 没有 workflow 权限，请重新生成并勾选 workflow。")
    }

    private func pollRun(expectedHead: String, started: Date) async throws -> Int {
        for _ in 0...100 {  // 最多约 5 分钟
            let (data, status) = try await request(
                "GET", "repos/\(owner)/\(repoName)/actions/runs?per_page=5")
            if status == 200,
               let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let runs = obj["workflow_runs"] as? [[String: Any]] {
                for r in runs {
                    if r["head_sha"] as? String == expectedHead,
                       let statusStr = r["status"] as? String {
                        if statusStr == "completed" {
                            return r["id"] as? Int ?? 0
                        }
                        break
                    }
                }
            }
            try await Task.sleep(nanoseconds: 3_000_000_000)
        }
        throw CloudError.message("编译超时（超过 5 分钟），可稍后在 GitHub 网页查看运行记录")
    }

    private func fetchLog(runID: Int) async throws -> String {
        let (jobsData, _) = try await request(
            "GET", "repos/\(owner)/\(repoName)/actions/runs/\(runID)/jobs")
        guard let jobsObj = try? JSONSerialization.jsonObject(with: jobsData) as? [String: Any],
              let jobs = jobsObj["jobs"] as? [[String: Any]],
              let jobID = jobs.first?["id"] as? Int else {
            throw CloudError.message("获取任务信息失败")
        }
        let (logData, logStatus) = try await request(
            "GET", "repos/\(owner)/\(repoName)/actions/jobs/\(jobID)/logs")
        guard logStatus == 200 else {
            throw CloudError.message("获取日志失败（HTTP \(logStatus)）")
        }
        return String(data: logData, encoding: .utf8) ?? ""
    }

    private func extractOutput(from log: String) -> String {
        guard let start = log.range(of: "===SPG_OUTPUT_START===")?.upperBound,
              let end = log.range(of: "===SPG_OUTPUT_END===")?.lowerBound, start < end else {
            return ""
        }
        return String(log[start..<end])
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
