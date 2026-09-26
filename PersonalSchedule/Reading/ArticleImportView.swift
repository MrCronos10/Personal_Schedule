import PhotosUI
import SwiftData
import SwiftUI

/// 导入文章: paste the text, photograph it, or pick a photo already taken — name where it came from
/// if you like, save.
///
/// The title is not asked for. It is taken from the first line, so importing is one paste and one
/// button — the point is to catch Chinese the student just met, before the moment passes.
struct ArticleImportView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    @State private var text = ""
    @State private var source = ""
    @State private var errorMessage: LocalizedStringKey?
    @State private var isShowingCamera = false
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var isRecognizing = false

    @FocusState private var isTextFocused: Bool

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    SectionCaption(title: "文章")

                    captureRow
                        .padding(.top, 10)

                    TextEditor(text: $text)
                        .font(Theme.serif(17))
                        .foregroundStyle(Theme.ink)
                        .scrollContentBackground(.hidden)
                        .frame(minHeight: 260)
                        .padding(8)
                        .background(Theme.paper)
                        .overlay(
                            RoundedRectangle(cornerRadius: Theme.controlRadius).stroke(Theme.rule)
                        )
                        .padding(.top, 10)
                        .focused($isTextFocused)
                        .overlay(alignment: .topLeading) {
                            // Written for all three ways in, not only paste: a photo that recognized
                            // nothing lands back on this same empty state, and "paste it here" would
                            // read as though the photo had been forgotten rather than come back blank.
                            if text.isEmpty {
                                Text("贴上文章，或者拍照识别文字")
                                    .font(Theme.serif(17))
                                    .foregroundStyle(Theme.muted.opacity(0.6))
                                    .padding(.horizontal, 14)
                                    .padding(.top, 26)
                                    .allowsHitTesting(false)
                            }
                        }

                    Text("标题会用第一行。")
                        .font(Theme.meta)
                        .foregroundStyle(Theme.muted)
                        .padding(.top, 6)

                    SectionCaption(title: "来源")

                    TextField("微信公众号、菜单、路牌…", text: $source)
                        .font(.system(size: 15))
                        .foregroundStyle(Theme.ink)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .background(Theme.paper)
                        .overlay(
                            RoundedRectangle(cornerRadius: Theme.controlRadius).stroke(Theme.rule)
                        )
                        .padding(.top, 10)

                    if let errorMessage {
                        Text(errorMessage)
                            .font(.footnote)
                            .foregroundStyle(Theme.error)
                            .padding(.top, 8)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
            }
            .background(Theme.paper)
            .navigationTitle(Text("导入文章"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存", action: save)
                }
            }
        }
        .onAppear { isTextFocused = true }
        .sheet(isPresented: $isShowingCamera) {
            CameraCaptureView { image in
                Task { await recognizeAndFill(image) }
            }
            .ignoresSafeArea()
        }
        .onChange(of: selectedPhoto) { _, newItem in
            guard let newItem else { return }
            Task {
                defer { selectedPhoto = nil }
                guard let data = try? await newItem.loadTransferable(type: Data.self),
                      let image = UIImage(data: data)
                else {
                    errorMessage = "没能读取这张照片"
                    return
                }
                await recognizeAndFill(image)
            }
        }
    }

    /// 拍照 (if the device has a camera) and 从相册选择, side by side above the text.
    ///
    /// 从相册选择 uses `PhotosPicker`, which needs no permission entry at all: it runs out of process
    /// and only ever hands the app the one photo chosen. The camera does need permission, so it is
    /// asked for the moment it is actually wanted, never before.
    private var captureRow: some View {
        HStack(spacing: 10) {
            if CameraAccess.isHardwareAvailable {
                Button {
                    Task {
                        if await CameraAccess.requestAccess() {
                            isShowingCamera = true
                        } else {
                            errorMessage = "没有相机权限，可以在设置里打开"
                        }
                    }
                } label: {
                    Label("拍照", systemImage: "camera")
                }
                .buttonStyle(MiniButtonStyle())
            }

            PhotosPicker(selection: $selectedPhoto, matching: .images) {
                Label("从相册选择", systemImage: "photo")
            }
            .buttonStyle(MiniButtonStyle())

            if isRecognizing {
                ProgressView()
                    .padding(.leading, 2)
            }
        }
    }

    /// Recognised text always lands here, in the same field a pasted Article already goes through —
    /// never saved directly. An image with nothing recognizable on it fills the field with nothing,
    /// which is the ordinary answer, not an error: the student can still just type.
    ///
    /// Replaces whatever draft was already there rather than appending to it: one photo is one
    /// attempt at getting the text in, the same way pasting replaces a half-finished paste. That
    /// replacement must only happen on an actual answer, though — success with nothing found, which
    /// is a real empty string. A `try?` here would fold Vision failing to run at all into that same
    /// empty string, silently discarding whatever the student had already typed with no word said
    /// about it, which is a different event entirely and needs its own message.
    private func recognizeAndFill(_ image: UIImage) async {
        isRecognizing = true
        defer { isRecognizing = false }
        do {
            text = try await TextRecognizer.recognizeText(in: image)
            isTextFocused = true
        } catch {
            errorMessage = "没能识别这张照片里的文字"
        }
    }

    private func save() {
        do {
            try ArticleLibrary(context: context).add(text: text, source: source)
            dismiss()
        } catch ArticleError.emptyText {
            errorMessage = "先贴一段文章"
        } catch {
            errorMessage = "没能保存"
        }
    }
}

#Preview {
    ArticleImportView()
        .modelContainer(try! ScheduleStore.makeContainer(inMemory: true))
}
