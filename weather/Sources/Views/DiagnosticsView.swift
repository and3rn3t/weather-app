//
//  DiagnosticsView.swift
//  weather
//
//  Debug view for viewing and exporting MetricKit diagnostics
//  Only available in DEBUG builds
//

#if DEBUG
import SwiftUI
import UniformTypeIdentifiers

struct DiagnosticsView: View {
    @State private var diagnosticFiles: [URL] = []
    @State private var selectedFileURL: URL?
    @State private var showingFileDetail = false
    @State private var fileContent: String = ""
    @State private var showShareSheet = false
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text("MetricKit diagnostics are saved locally in DEBUG builds and delivered daily by the system.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } header: {
                    Text("About MetricKit")
                }
                
                Section {
                    if diagnosticFiles.isEmpty {
                        ContentUnavailableView(
                            "No Diagnostics Yet",
                            systemImage: "doc.text.magnifyingglass",
                            description: Text("MetricKit delivers data once per 24 hours. Keep the app running and check back tomorrow.")
                        )
                    } else {
                        ForEach(diagnosticFiles, id: \.self) { file in
                            Button {
                                selectedFileURL = file
                                loadFileContent(file)
                                showingFileDetail = true
                            } label: {
                                HStack {
                                    Image(systemName: file.lastPathComponent.contains("diagnostic") ? "exclamationmark.triangle" : "chart.line.uptrend.xyaxis")
                                        .foregroundStyle(file.lastPathComponent.contains("diagnostic") ? .red : .blue)
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(file.lastPathComponent)
                                            .font(.subheadline)
                                        
                                        if let attributes = try? FileManager.default.attributesOfItem(atPath: file.path),
                                           let fileSize = attributes[.size] as? Int64 {
                                            Text("\(ByteCountFormatter.string(fromByteCount: fileSize, countStyle: .file))")
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundStyle(.tertiary)
                                }
                            }
                        }
                        .onDelete(perform: deleteFiles)
                    }
                } header: {
                    Text("Diagnostic Files")
                } footer: {
                    Text("\(diagnosticFiles.count) file(s)")
                }
                
                Section {
                    Button("Refresh") {
                        loadDiagnosticFiles()
                    }
                    
                    Button("Export All", systemImage: "square.and.arrow.up") {
                        showShareSheet = true
                    }
                    .disabled(diagnosticFiles.isEmpty)
                    
                    Button("Clear All", systemImage: "trash", role: .destructive) {
                        clearAllFiles()
                    }
                    .disabled(diagnosticFiles.isEmpty)
                }
            }
            .navigationTitle("Diagnostics")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        // Dismiss
                    }
                }
            }
            .sheet(isPresented: $showingFileDetail) {
                if let file = selectedFileURL {
                    NavigationStack {
                        ScrollView {
                            Text(fileContent)
                                .font(.system(.caption, design: .monospaced))
                                .textSelection(.enabled)
                                .padding()
                        }
                        .navigationTitle(file.lastPathComponent)
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .topBarTrailing) {
                                ShareLink(item: file)
                            }
                        }
                    }
                }
            }
            .sheet(isPresented: $showShareSheet) {
                if !diagnosticFiles.isEmpty {
                    ShareLink(item: diagnosticFiles[0])
                }
            }
            .onAppear {
                loadDiagnosticFiles()
            }
        }
    }
    
    // MARK: - File Operations
    
    private func loadDiagnosticFiles() {
        guard let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return
        }
        
        let diagnosticsPath = documentsPath.appendingPathComponent("Diagnostics", isDirectory: true)
        
        do {
            let files = try FileManager.default.contentsOfDirectory(at: diagnosticsPath, includingPropertiesForKeys: [.creationDateKey])
            diagnosticFiles = files.sorted { file1, file2 in
                let date1 = (try? file1.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? Date.distantPast
                let date2 = (try? file2.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? Date.distantPast
                return date1 > date2
            }
        } catch {
            diagnosticFiles = []
        }
    }
    
    private func loadFileContent(_ file: URL) {
        do {
            let data = try Data(contentsOf: file)
            if let json = try? JSONSerialization.jsonObject(with: data),
               let prettyData = try? JSONSerialization.data(withJSONObject: json, options: .prettyPrinted) {
                fileContent = String(data: prettyData, encoding: .utf8) ?? "Unable to read file"
            } else {
                fileContent = String(data: data, encoding: .utf8) ?? "Unable to read file"
            }
        } catch {
            fileContent = "Error loading file: \(error.localizedDescription)"
        }
    }
    
    private func deleteFiles(at offsets: IndexSet) {
        for index in offsets {
            let file = diagnosticFiles[index]
            try? FileManager.default.removeItem(at: file)
        }
        loadDiagnosticFiles()
    }
    
    private func clearAllFiles() {
        for file in diagnosticFiles {
            try? FileManager.default.removeItem(at: file)
        }
        loadDiagnosticFiles()
    }
}

#Preview {
    DiagnosticsView()
}
#endif
